#!/usr/bin/env python3
"""team-runner.py - Multi-agent team orchestrator for AIfred Jobs.

Spawns N executor.sh processes in parallel (one per team member),
collects structured verdicts, applies consensus rules, and escalates
conflicts to Telegram HITL.

Usage:
    team-runner.py --job <name> [--param k=v] [--dry-run] [--quiet]

Part of the AIfred Jobs headless automation system.
"""

import argparse
import json
import logging
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from enum import Enum
from pathlib import Path
from typing import Optional

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = Path(os.environ.get("PROJECT_DIR", SCRIPT_DIR.parent.parent.resolve()))
REGISTRY = SCRIPT_DIR / "registry.yaml"
EXECUTOR = SCRIPT_DIR / "executor.sh"
MSGBUS = SCRIPT_DIR / "lib" / "msgbus.sh"
SEND_TELEGRAM = SCRIPT_DIR / "lib" / "send-telegram.sh"
RESULTS_DIR = PROJECT_DIR / ".claude" / "agent-output" / "results" / "teams"
LOG_DIR = PROJECT_DIR / ".claude" / "logs" / "headless"
PUSHGATEWAY_URL = os.environ.get("PUSHGATEWAY_URL", "http://localhost:9091")

logger = logging.getLogger("team-runner")


# ============================================================================
# Data Types
# ============================================================================

class VerdictValue(Enum):
    APPROVE = "approve"
    DENY = "deny"
    UNCERTAIN = "uncertain"


class Confidence(Enum):
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class ConsensusResult(Enum):
    APPROVE = "approve"
    DENY = "deny"
    CONFLICT = "conflict"
    ESCALATE = "escalate"


@dataclass
class Verdict:
    value: VerdictValue
    confidence: Confidence
    reasoning: str

    @classmethod
    def from_output(cls, text: str) -> Optional["Verdict"]:
        """Parse a structured verdict from executor output.

        Looks for the last occurrence of:
            VERDICT: approve|deny|uncertain
            CONFIDENCE: high|medium|low
            REASONING: <text>
        """
        if not text:
            return None

        # Find all verdict lines (last one wins)
        # Handles plain text and markdown bold: VERDICT:, **VERDICT**:, **VERDICT:**, etc.
        verdict_matches = re.findall(
            r"(?:^|\n)\s*\*{0,2}VERDICT\*{0,2}:\s*\*{0,2}(approve|deny|uncertain)\*{0,2}",
            text, re.IGNORECASE
        )
        confidence_matches = re.findall(
            r"(?:^|\n)\s*\*{0,2}CONFIDENCE\*{0,2}:\s*\*{0,2}(high|medium|low)\*{0,2}",
            text, re.IGNORECASE
        )
        reasoning_matches = re.findall(
            r"(?:^|\n)\s*\*{0,2}REASONING\*{0,2}:\s*(.+)",
            text, re.IGNORECASE
        )

        if not verdict_matches:
            return None

        try:
            value = VerdictValue(verdict_matches[-1].lower())
            confidence = Confidence(confidence_matches[-1].lower()) if confidence_matches else Confidence.LOW
            reasoning = reasoning_matches[-1].strip() if reasoning_matches else "No reasoning provided"
            return cls(value=value, confidence=confidence, reasoning=reasoning)
        except (ValueError, IndexError):
            return None


@dataclass
class MemberResult:
    name: str
    status: str  # "success", "timeout", "error"
    verdict: Optional[Verdict]
    cost: float
    duration: float
    output: str
    exit_code: int = 0

    def to_dict(self) -> dict:
        d = {
            "name": self.name,
            "status": self.status,
            "verdict": {
                "value": self.verdict.value.value,
                "confidence": self.verdict.confidence.value,
                "reasoning": self.verdict.reasoning,
            } if self.verdict else None,
            "cost_usd": self.cost,
            "duration_secs": self.duration,
            "exit_code": self.exit_code,
        }
        return d


@dataclass
class TeamResult:
    job: str
    consensus: ConsensusResult
    consensus_rule: str
    members: list  # list of MemberResult
    coordinator_output: Optional[str] = None
    escalation_response: Optional[str] = None
    total_cost: float = 0.0
    total_duration: float = 0.0
    timestamp: str = ""

    def to_dict(self) -> dict:
        return {
            "job": self.job,
            "consensus": self.consensus.value,
            "consensus_rule": self.consensus_rule,
            "members": [m.to_dict() for m in self.members],
            "coordinator_output": self.coordinator_output,
            "escalation_response": self.escalation_response,
            "total_cost_usd": self.total_cost,
            "total_duration_secs": self.total_duration,
            "timestamp": self.timestamp,
        }


# ============================================================================
# Registry Reader
# ============================================================================

class RegistryReader:
    """Reads team configuration from registry.yaml via yq."""

    def __init__(self, registry_path: Path, job_name: str):
        self.registry = registry_path
        self.job = job_name
        self._yq = self._find_yq()
        self._validate()

    def _find_yq(self) -> str:
        for path in ["/usr/local/bin/yq", "/usr/bin/yq"]:
            if os.path.isfile(path):
                return path
        # Try PATH
        result = subprocess.run(["which", "yq"], capture_output=True, text=True)
        if result.returncode == 0:
            return result.stdout.strip()
        raise RuntimeError("yq not found — required for reading registry.yaml")

    def _validate(self):
        team = self._get(f".jobs.{self.job}.team")
        if not team or team == "null":
            raise ValueError(f"Job '{self.job}' has no team: section in registry")

    def _get(self, path: str) -> Optional[str]:
        try:
            result = subprocess.run(
                [self._yq, path, str(self.registry)],
                capture_output=True, text=True, timeout=10
            )
            val = result.stdout.strip()
            return val if val and val != "null" else None
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return None

    def _get_json(self, path: str) -> Optional[dict]:
        try:
            result = subprocess.run(
                [self._yq, "-o", "json", path, str(self.registry)],
                capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0 and result.stdout.strip():
                return json.loads(result.stdout)
            return None
        except (subprocess.TimeoutExpired, json.JSONDecodeError):
            return None

    def get_job_prompt(self) -> str:
        return self._get(f".jobs.{self.job}.prompt") or ""

    def get_job_budget(self) -> float:
        val = self._get(f".jobs.{self.job}.max_budget_usd")
        return float(val) if val else 5.0

    def get_job_timeout(self) -> int:
        val = self._get(f".jobs.{self.job}.timeout_minutes")
        return int(val) if val else 20

    def get_team_mode(self) -> str:
        return self._get(f".jobs.{self.job}.team.mode") or "parallel-then-synthesize"

    def get_members(self) -> list:
        members_json = self._get_json(f".jobs.{self.job}.team.members")
        if not members_json or not isinstance(members_json, list):
            raise ValueError(f"Job '{self.job}' has no team members defined")
        return members_json

    def get_coordinator(self) -> Optional[dict]:
        return self._get_json(f".jobs.{self.job}.team.coordinator")

    def get_escalation(self) -> dict:
        esc = self._get_json(f".jobs.{self.job}.team.escalation")
        return esc or {
            "on_conflict": "telegram",
            "on_all_uncertain": "telegram",
            "on_coordinator_fail": "block",
            "telegram_timeout_minutes": 60,
            "fallback_on_timeout": "block",
        }

    def get_consensus_rule(self) -> str:
        return self._get(f".jobs.{self.job}.team.consensus.rule") or "unanimous-approve"


# ============================================================================
# Executor Runner
# ============================================================================

class ExecutorRunner:
    """Spawns executor.sh for a single team member and parses results."""

    def __init__(self, job: str, member: dict, job_prompt: str, params: list):
        self.job = job
        self.member = member
        self.job_prompt = job_prompt
        self.params = params

    def run(self) -> MemberResult:
        name = self.member["name"]
        persona = self.member.get("persona", "task-investigator")
        model = self.member.get("model", "sonnet")
        max_turns = self.member.get("max_turns", 10)
        max_budget = self.member.get("max_budget_usd", 1.50)
        timeout = self.member.get("timeout_minutes", 12)
        role = self.member.get("role", "")

        cmd = [
            str(EXECUTOR),
            "--job", self.job,
            "--persona", persona,
            "--model-override", str(model),
            "--max-budget-override", str(max_budget),
            "--max-turns-override", str(max_turns),
            "--timeout-override", str(timeout),
            "--quiet",
            "--suppress-notification",
        ]

        # Add role as a param
        if role:
            cmd.extend(["--param", f"role={role.strip()}"])

        # Pass through any extra params
        for p in self.params:
            cmd.extend(["--param", p])

        logger.info(f"[{name}] Spawning: persona={persona} model={model} budget=${max_budget}")

        start = datetime.now(timezone.utc)
        try:
            timeout_secs = timeout * 60 + 30  # small buffer beyond executor's own timeout
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout_secs,
                cwd=str(PROJECT_DIR),
            )
            elapsed = (datetime.now(timezone.utc) - start).total_seconds()

            # Parse JSON output (executor --quiet prints JSON)
            output_text = result.stdout.strip()
            response = ""
            cost = 0.0

            try:
                output_json = json.loads(output_text)
                response = output_json.get("result", output_json.get("response", ""))
                cost_val = output_json.get("total_cost_usd", output_json.get("cost_usd", 0))
                cost = float(cost_val) if cost_val and cost_val != "unknown" else 0.0
            except (json.JSONDecodeError, TypeError):
                response = output_text

            verdict = Verdict.from_output(response)

            if result.returncode != 0:
                return MemberResult(
                    name=name, status="error", verdict=verdict,
                    cost=cost, duration=elapsed, output=response,
                    exit_code=result.returncode,
                )

            # If no verdict found, treat as uncertain
            if verdict is None:
                verdict = Verdict(
                    value=VerdictValue.UNCERTAIN,
                    confidence=Confidence.LOW,
                    reasoning="No structured verdict found in output",
                )

            return MemberResult(
                name=name, status="success", verdict=verdict,
                cost=cost, duration=elapsed, output=response,
                exit_code=0,
            )

        except subprocess.TimeoutExpired:
            elapsed = (datetime.now(timezone.utc) - start).total_seconds()
            logger.warning(f"[{name}] Timed out after {timeout}m")
            return MemberResult(
                name=name, status="timeout",
                verdict=Verdict(
                    value=VerdictValue.UNCERTAIN,
                    confidence=Confidence.LOW,
                    reasoning=f"Member timed out after {timeout} minutes",
                ),
                cost=0.0, duration=elapsed, output="",
                exit_code=124,
            )


# ============================================================================
# Consensus Engine
# ============================================================================

class ConsensusEngine:
    """Applies consensus rules to collected member verdicts."""

    RULES = {"unanimous-approve", "majority", "any-deny-blocks"}

    @staticmethod
    def evaluate(verdicts: list[Verdict], rule: str) -> ConsensusResult:
        if rule not in ConsensusEngine.RULES:
            raise ValueError(f"Unknown consensus rule: {rule}")

        if not verdicts:
            return ConsensusResult.ESCALATE

        values = [v.value for v in verdicts]
        approves = values.count(VerdictValue.APPROVE)
        denies = values.count(VerdictValue.DENY)
        uncertains = values.count(VerdictValue.UNCERTAIN)
        total = len(values)

        # All uncertain -> escalate regardless of rule
        if uncertains == total:
            return ConsensusResult.ESCALATE

        if rule == "unanimous-approve":
            if approves == total:
                return ConsensusResult.APPROVE
            elif denies == total:
                return ConsensusResult.DENY
            else:
                return ConsensusResult.CONFLICT

        elif rule == "majority":
            if approves > total / 2:
                return ConsensusResult.APPROVE
            elif denies > total / 2:
                return ConsensusResult.DENY
            else:
                return ConsensusResult.CONFLICT

        elif rule == "any-deny-blocks":
            if denies > 0:
                return ConsensusResult.DENY
            elif approves == total:
                return ConsensusResult.APPROVE
            else:
                # Mix of approve and uncertain (no denies)
                return ConsensusResult.CONFLICT

        return ConsensusResult.ESCALATE


# ============================================================================
# Escalation Manager
# ============================================================================

class EscalationManager:
    """Sends Telegram HITL questions and polls for answers."""

    @staticmethod
    def _extract_task_context(job_prompt: str) -> str:
        """Extract task ID and title from the job prompt (e.g., from bd list output)."""
        if not job_prompt:
            return ""
        # Match Beads task IDs like "<project>-xxxx" followed by title text
        matches = re.findall(
            r"(\w+-\w+)\s+(.+?)(?:\s{2,}|\t|\n|$)", job_prompt
        )
        if matches:
            task_id, title = matches[0]
            return f'{task_id} — "{title.strip()}"'
        return ""

    @staticmethod
    def escalate(job: str, reason: str, members: list, config: dict,
                 job_prompt: str = "") -> Optional[str]:
        """Send a Telegram question and poll msgbus for the answer."""
        timeout_minutes = config.get("telegram_timeout_minutes", 60)
        fallback = config.get("fallback_on_timeout", "block")

        # Extract task context from job prompt
        task_context = EscalationManager._extract_task_context(job_prompt)

        # Build the question with enriched context
        member_summaries = []
        for m in members:
            if m.verdict:
                v = m.verdict
                member_summaries.append(
                    f"  {m.name}: {v.value.value.upper()} ({v.confidence.value}) — {v.reasoning}"
                )
            else:
                member_summaries.append(f"  {m.name}: no verdict ({m.status})")

        # Count verdicts for conflict summary
        approves = sum(1 for m in members if m.verdict and m.verdict.value == VerdictValue.APPROVE)
        denies = sum(1 for m in members if m.verdict and m.verdict.value == VerdictValue.DENY)
        uncertains = sum(1 for m in members if m.verdict and m.verdict.value == VerdictValue.UNCERTAIN)
        verdict_parts = []
        if approves:
            verdict_parts.append(f"{approves} approve")
        if denies:
            verdict_parts.append(f"{denies} deny")
        if uncertains:
            verdict_parts.append(f"{uncertains} uncertain")
        conflict_line = ", ".join(verdict_parts)

        # Build structured question
        lines = [f"Approval Required: {job}"]
        if task_context:
            lines.append(f"\nTask: {task_context}")
        lines.append(f"\nMember Assessments:")
        lines.extend(member_summaries)
        lines.append(f"\nConflict: {conflict_line} ({reason})")
        lines.append(f"\nIf APPROVE -> Task promoted to auto:ready, executes next cycle")
        lines.append(f"If DENY -> Task stays blocked, needs manual review")

        question = "\n".join(lines)
        options = "Approve|Deny|Skip"

        # Write question to msgbus
        if not (MSGBUS.is_file() and os.access(str(MSGBUS), os.X_OK)):
            logger.warning(f"msgbus not available, falling back to '{fallback}'")
            return fallback

        try:
            data = json.dumps({
                "job": job,
                "question": question,
                "options": options.split("|"),
            })
            result = subprocess.run(
                [str(MSGBUS), "send",
                 "--type", "question_asked",
                 "--source", f"headless:team:{job}",
                 "--severity", "question",
                 "--data", data],
                capture_output=True, text=True, timeout=30,
            )
            if result.returncode != 0:
                logger.warning(f"msgbus send failed (exit {result.returncode}), falling back to '{fallback}'")
                return fallback
            logger.info(f"Escalation question sent to Telegram for {job}")
        except (subprocess.TimeoutExpired, OSError) as e:
            logger.error(f"Failed to send escalation: {e}")
            return fallback

        # Poll for answer (check every 30s up to timeout)
        import time
        deadline = time.time() + (timeout_minutes * 60)
        while time.time() < deadline:
            try:
                result = subprocess.run(
                    [str(MSGBUS), "query",
                     "--type", "question_answered",
                     "--job", job,
                     "--status", "pending"],
                    capture_output=True, text=True, timeout=10,
                )
                if result.returncode == 0 and result.stdout.strip():
                    answer_data = json.loads(result.stdout.strip())
                    answer = None
                    if isinstance(answer_data, dict):
                        answer = answer_data.get("data", {}).get("answer")
                    elif isinstance(answer_data, list) and answer_data:
                        answer = answer_data[0].get("data", {}).get("answer")
                    if answer:
                        logger.info(f"Received HITL answer: {answer}")
                        return answer.lower()
            except (subprocess.TimeoutExpired, json.JSONDecodeError, OSError):
                pass
            time.sleep(30)

        logger.warning(f"Telegram HITL timed out after {timeout_minutes}m, falling back to '{fallback}'")
        return fallback


# ============================================================================
# Team Runner (Main Orchestrator)
# ============================================================================

class TeamRunner:
    """Main orchestrator: load config -> spawn -> collect -> consensus -> report."""

    def __init__(self, job: str, params: list, dry_run: bool = False, quiet: bool = False):
        self.job = job
        self.params = params
        self.dry_run = dry_run
        self.quiet = quiet
        self.registry = RegistryReader(REGISTRY, job)

    def _log(self, msg: str):
        if not self.quiet:
            logger.info(msg)

    def run(self) -> int:
        """Execute the full team workflow. Returns exit code."""
        start = datetime.now(timezone.utc)

        # Load config
        members_config = self.registry.get_members()
        coordinator_config = self.registry.get_coordinator()
        escalation_config = self.registry.get_escalation()
        consensus_rule = self.registry.get_consensus_rule()
        job_prompt = self.registry.get_job_prompt()
        job_budget = self.registry.get_job_budget()
        team_mode = self.registry.get_team_mode()

        self._log(f"Team job: {self.job}")
        self._log(f"Mode: {team_mode}, Members: {len(members_config)}, Rule: {consensus_rule}")

        # Budget guard
        member_budget_sum = sum(m.get("max_budget_usd", 1.50) for m in members_config)
        coordinator_budget = coordinator_config.get("max_budget_usd", 1.50) if coordinator_config else 0
        total_budget_needed = member_budget_sum + coordinator_budget

        if total_budget_needed > job_budget:
            msg = (f"Budget guard: member+coordinator budgets (${total_budget_needed:.2f}) "
                   f"exceed job budget (${job_budget:.2f})")
            logger.error(msg)
            self._write_error_report(msg)
            return 1

        # Dry run
        if self.dry_run:
            print(f"\n=== DRY RUN: Team Job {self.job} ===")
            print(f"Mode: {team_mode}")
            print(f"Consensus rule: {consensus_rule}")
            print(f"Job budget: ${job_budget:.2f}")
            print(f"Total member budgets: ${total_budget_needed:.2f}")
            print(f"\nMembers ({len(members_config)}):")
            for m in members_config:
                print(f"  - {m['name']}: persona={m.get('persona', 'task-investigator')} "
                      f"model={m.get('model', 'sonnet')} budget=${m.get('max_budget_usd', 1.50)}")
            if coordinator_config:
                print(f"\nCoordinator: model={coordinator_config.get('model', 'sonnet')} "
                      f"budget=${coordinator_config.get('max_budget_usd', 1.50)}")
            print(f"\nEscalation: {escalation_config}")
            print(f"\nWould execute {len(members_config)} parallel executor.sh invocations")
            return 0

        # Spawn all members in parallel
        self._log("Spawning team members...")
        member_results = self._run_members(members_config, job_prompt)

        # Collect verdicts
        verdicts = [m.verdict for m in member_results if m.verdict is not None]
        self._log(f"Collected {len(verdicts)} verdicts from {len(member_results)} members")

        for m in member_results:
            v = m.verdict
            if v:
                self._log(f"  [{m.name}] {v.value.value} ({v.confidence.value}): {v.reasoning}")
            else:
                self._log(f"  [{m.name}] no verdict (status={m.status})")

        # Apply consensus
        consensus = ConsensusEngine.evaluate(verdicts, consensus_rule)
        self._log(f"Consensus result: {consensus.value} (rule: {consensus_rule})")

        # Short-circuit: if all members errored, don't escalate — just fail
        all_errored = all(m.status == "error" for m in member_results)
        if all_errored:
            self._log("All members errored — skipping escalation, failing job")
            consensus = ConsensusResult.DENY

        # Handle conflict/escalation
        coordinator_output = None
        escalation_response = None

        # Calculate totals so far (before escalation/coordinator)
        elapsed = (datetime.now(timezone.utc) - start).total_seconds()
        total_cost = sum(m.cost for m in member_results)

        # Write preliminary report BEFORE escalation (so we always have evidence)
        prelim_result = TeamResult(
            job=self.job,
            consensus=consensus,
            consensus_rule=consensus_rule,
            members=member_results,
            total_cost=total_cost,
            total_duration=elapsed,
            timestamp=datetime.now(timezone.utc).isoformat(),
        )
        self._write_report(prelim_result)

        # Escalation (may block waiting for Telegram HITL)
        if consensus == ConsensusResult.CONFLICT and not all_errored:
            on_conflict = escalation_config.get("on_conflict", "telegram")
            self._log(f"Conflict detected, escalation: {on_conflict}")
            if on_conflict == "telegram":
                escalation_response = EscalationManager.escalate(
                    self.job, "Member verdicts conflict", member_results, escalation_config,
                    job_prompt=job_prompt,
                )
            elif on_conflict == "block":
                self._log("Conflict resolution: block (no escalation)")
        elif consensus == ConsensusResult.ESCALATE and not all_errored:
            on_uncertain = escalation_config.get("on_all_uncertain", "telegram")
            self._log(f"All uncertain, escalation: {on_uncertain}")
            if on_uncertain == "telegram":
                escalation_response = EscalationManager.escalate(
                    self.job, "All members uncertain", member_results, escalation_config,
                    job_prompt=job_prompt,
                )
            elif on_uncertain == "block":
                self._log("Uncertainty resolution: block (no escalation)")

        # Run coordinator if mode is parallel-then-synthesize
        if team_mode == "parallel-then-synthesize" and coordinator_config:
            if consensus not in (ConsensusResult.CONFLICT, ConsensusResult.ESCALATE):
                self._log("Running coordinator synthesis...")
                coordinator_output = self._run_coordinator(
                    coordinator_config, member_results, job_prompt
                )
                if coordinator_output is None:
                    on_fail = escalation_config.get("on_coordinator_fail", "block")
                    self._log(f"Coordinator failed, action: {on_fail}")
            else:
                self._log("Skipping coordinator — consensus requires escalation")

        # Update totals
        elapsed = (datetime.now(timezone.utc) - start).total_seconds()
        total_cost = sum(m.cost for m in member_results)

        # Build final result
        team_result = TeamResult(
            job=self.job,
            consensus=consensus,
            consensus_rule=consensus_rule,
            members=member_results,
            coordinator_output=coordinator_output,
            escalation_response=escalation_response,
            total_cost=total_cost,
            total_duration=elapsed,
            timestamp=datetime.now(timezone.utc).isoformat(),
        )

        # Overwrite with final report (includes escalation/coordinator)
        self._write_report(team_result)

        # Write msgbus notification
        self._write_notification(team_result)

        # Push metrics
        self._push_metrics(team_result, len(member_results))

        # Quiet mode: output JSON
        if self.quiet:
            print(json.dumps(team_result.to_dict()))

        self._log(f"Team job complete: consensus={consensus.value} cost=${total_cost:.2f} duration={elapsed:.0f}s")
        return 0

    def _run_members(self, members_config: list, job_prompt: str) -> list:
        """Run all members in parallel, return list of MemberResult."""
        results = []
        with ThreadPoolExecutor(max_workers=len(members_config)) as pool:
            futures = {}
            for member in members_config:
                runner = ExecutorRunner(self.job, member, job_prompt, self.params)
                future = pool.submit(runner.run)
                futures[future] = member["name"]

            for future in as_completed(futures):
                name = futures[future]
                try:
                    result = future.result()
                    results.append(result)
                except Exception as e:
                    logger.error(f"[{name}] Exception: {e}")
                    results.append(MemberResult(
                        name=name, status="error", verdict=None,
                        cost=0.0, duration=0.0, output=str(e),
                        exit_code=1,
                    ))
        return results

    def _run_coordinator(self, config: dict, members: list, job_prompt: str) -> Optional[str]:
        """Run the coordinator with all member outputs as context."""
        persona = config.get("persona", "task-investigator")
        model = config.get("model", "sonnet")
        max_turns = config.get("max_turns", 10)
        max_budget = config.get("max_budget_usd", 1.50)
        timeout = config.get("timeout_minutes", 10)

        # Build coordinator context from member outputs
        member_context = []
        for m in members:
            v_str = ""
            if m.verdict:
                v_str = f"VERDICT: {m.verdict.value.value}, CONFIDENCE: {m.verdict.confidence.value}"
            member_context.append(
                f"--- {m.name} ({m.status}) ---\n{v_str}\n{m.output[:2000]}\n"
            )

        coord_role = (
            "You are the COORDINATOR. Synthesize the following team member outputs "
            "into a final assessment. The team has already evaluated the tasks. "
            "Your job is to produce a unified summary and take any recommended actions "
            "(label updates, notes, etc).\n\n"
            "MEMBER OUTPUTS:\n" + "\n".join(member_context)
        )

        cmd = [
            str(EXECUTOR),
            "--job", self.job,
            "--persona", persona,
            "--model-override", str(model),
            "--max-budget-override", str(max_budget),
            "--max-turns-override", str(max_turns),
            "--timeout-override", str(timeout),
            "--param", f"role={coord_role}",
            "--quiet",
            "--suppress-notification",
        ]

        try:
            timeout_secs = timeout * 60 + 30
            result = subprocess.run(
                cmd, capture_output=True, text=True,
                timeout=timeout_secs, cwd=str(PROJECT_DIR),
            )
            output = result.stdout.strip()
            try:
                output_json = json.loads(output)
                return output_json.get("result", output_json.get("response", output))
            except (json.JSONDecodeError, TypeError):
                return output
        except (subprocess.TimeoutExpired, OSError) as e:
            logger.error(f"Coordinator failed: {e}")
            return None

    def _write_report(self, result: TeamResult):
        """Write JSON report to results/teams/."""
        RESULTS_DIR.mkdir(parents=True, exist_ok=True)
        ts = datetime.now().strftime("%Y%m%d-%H%M%S")
        report_file = RESULTS_DIR / f"{self.job}-{ts}.json"
        report_file.write_text(json.dumps(result.to_dict(), indent=2))
        self._log(f"Report saved: {report_file}")

    def _write_error_report(self, error_msg: str):
        """Write error report for early failures."""
        RESULTS_DIR.mkdir(parents=True, exist_ok=True)
        ts = datetime.now().strftime("%Y%m%d-%H%M%S")
        report_file = RESULTS_DIR / f"{self.job}-{ts}-error.json"
        report_file.write_text(json.dumps({
            "job": self.job,
            "error": error_msg,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }, indent=2))

    def _write_notification(self, result: TeamResult):
        """Send notification to message bus."""
        if not (MSGBUS.is_file() and os.access(str(MSGBUS), os.X_OK)):
            return

        severity = "info"
        if result.consensus in (ConsensusResult.CONFLICT, ConsensusResult.ESCALATE):
            severity = "warning"

        title = f"Team {self.job}: {result.consensus.value}"
        summary = (
            f"{len(result.members)} members, consensus={result.consensus.value}, "
            f"cost=${result.total_cost:.2f}"
        )

        data = json.dumps({
            "job": self.job,
            "title": title,
            "summary": summary,
            "exit_code": 0,
            "cost_usd": f"{result.total_cost:.2f}",
            "duration_secs": int(result.total_duration),
            "engine": "team-runner",
            "model_usage": {},
            "consensus": result.consensus.value,
            "member_count": len(result.members),
        })

        try:
            subprocess.run(
                [str(MSGBUS), "send",
                 "--type", "job_completed",
                 "--source", f"headless:team:{self.job}",
                 "--severity", severity,
                 "--data", data],
                capture_output=True, text=True, timeout=10,
            )
        except (subprocess.TimeoutExpired, OSError):
            pass

    def _push_metrics(self, result: TeamResult, member_count: int):
        """Push team metrics to Prometheus Pushgateway."""
        try:
            import urllib.request
            health_url = f"{PUSHGATEWAY_URL}/-/healthy"
            req = urllib.request.Request(health_url, method="GET")
            urllib.request.urlopen(req, timeout=2)
        except Exception:
            return  # Pushgateway not reachable, skip silently

        metrics = []
        metrics.append(
            f'headless_team_member_count{{job="{self.job}"}} {member_count}'
        )
        metrics.append(
            f'headless_team_consensus{{job="{self.job}",result="{result.consensus.value}"}} 1'
        )
        escalation_count = 1 if result.escalation_response else 0
        metrics.append(
            f'headless_team_escalation_count{{job="{self.job}"}} {escalation_count}'
        )
        for m in result.members:
            metrics.append(
                f'headless_team_member_duration_seconds{{job="{self.job}",member="{m.name}"}} {m.duration:.1f}'
            )
            metrics.append(
                f'headless_team_member_cost_usd{{job="{self.job}",member="{m.name}"}} {m.cost:.4f}'
            )

        payload = "\n".join(metrics) + "\n"
        try:
            import urllib.request
            push_url = f"{PUSHGATEWAY_URL}/metrics/job/headless_team/instance/{self.job}"
            req = urllib.request.Request(push_url, data=payload.encode(), method="POST")
            req.add_header("Content-Type", "text/plain")
            urllib.request.urlopen(req, timeout=5)
        except Exception:
            pass


# ============================================================================
# CLI
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="AIfred Jobs Team Runner")
    parser.add_argument("--job", required=True, help="Job name from registry.yaml")
    parser.add_argument("--param", action="append", default=[], help="k=v params (repeatable)")
    parser.add_argument("--dry-run", action="store_true", help="Show what would execute")
    parser.add_argument("--quiet", action="store_true", help="JSON output only")
    args = parser.parse_args()

    # Setup logging
    level = logging.WARNING if args.quiet else logging.INFO
    logging.basicConfig(
        level=level,
        format="[%(asctime)s] %(levelname)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    try:
        runner = TeamRunner(
            job=args.job,
            params=args.param,
            dry_run=args.dry_run,
            quiet=args.quiet,
        )
        exit_code = runner.run()
        sys.exit(exit_code)
    except (ValueError, RuntimeError) as e:
        logger.error(str(e))
        if args.quiet:
            print(json.dumps({"error": str(e)}))
        sys.exit(1)


if __name__ == "__main__":
    main()
