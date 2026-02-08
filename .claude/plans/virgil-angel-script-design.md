# Virgil — Aion Script for Codebase Navigation Guidance

**Date**: 2026-02-07
**Status**: Design Brainstorm (14 Wiggum loop iterations, 08:44-08:53 MST)
**Author**: Jarvis (brainstorm session, user-present)

---

## 1. Literary Foundation

**Source**: Virgil from Dante's *Divina Commedia* — the Roman poet who guides Dante through Hell (Inferno) and Purgatory (Purgatorio). Virgil is the voice of reason, classical wisdom, and territorial knowledge. He knows the landscape, explains what they're seeing, and keeps Dante from getting lost.

**Parallel to Jarvis Aion Scripts**:
- **Watcher** = The sentinel on the wall. Monitors threats (context exhaustion), sounds alarms, takes defensive action. Reactive, protective.
- **Virgil** = The guide through the landscape. Extracts meaning, illuminates paths, presents what's relevant. Proactive, educational.

**Key principle**: Virgil *interprets*, not just reports. The difference between a dashboard and a guide is **interpretation** — answering questions the user hasn't asked yet.

---

## 2. Core Concept

Virgil runs as a separate tmux pane/window (like Watcher in `jarvis:1`). It watches Claude Code's activity — file accesses, tool calls, git changes — and renders a live, navigable, hyperlinked view.

**Unique value**: No existing tool shows the codebase *through the eyes of the AI working on it*. Virgil bridges the gap between what the AI is doing and what the human can see.

---

## 3. Architecture

```
DATA SOURCES                    PROCESSING                  OUTPUT
file-access.json ─┐
git status ───────┤
.watcher-status ──┼─→ virgil.sh (bash) ──→ tmux pane (jarvis:2)
.active-tasks.txt ┤   - 15s poll cycle       OSC 8 hyperlinks
plan files ───────┤   - heuristic rules      vscode:// URL scheme
CLAUDE.md ────────┘   - mode detection       ANSI color coding
```

### Design Principles
1. **Read-only** — Virgil never modifies files or sends commands
2. **No AI** — Deterministic heuristics only, no LLM calls
3. **Lightweight** — Simple bash + python3 for JSON parsing
4. **Project-agnostic** — Works with any codebase, not just Jarvis
5. **Complementary** — Does not duplicate Watcher's functionality
6. **Separable** — Can be stopped/started without affecting Jarvis or Watcher

### tmux Layout

Option A (split bottom panes):
```
┌──────────────────────────────┐
│ jarvis:0 (Claude Code)       │
├───────────────┬──────────────┤
│ jarvis:1      │ jarvis:2     │
│ (Watcher)     │ (Virgil)     │
└───────────────┴──────────────┘
```

Option B (separate windows):
```
Window 0: Claude Code (main session)
Window 1: Watcher (context monitoring)
Window 2: Virgil (codebase navigation)
```

---

## 4. Dashboard Layout (Mockup)

```
╔═══════════════════════════════════════════════════════════╗
║  VIRGIL — Codebase Guide                    Mode: WORK   ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  ┌─ ACTIVE FILES (last 5 min) ───────────────────────┐   ║
║  │  ★ .claude/reports/process-review/v5.8.1-...md    │   ║
║  │    .claude/context/session-state.md               │   ║
║  │    .claude/logs/jarvis-watcher.log                │   ║
║  │    .claude/plans/transient-tumbling-allen.md      │   ║
║  │    .claude/context/lessons/insights.md            │   ║
║  └───────────────────────────────────────────────────┘   ║
║                                                           ║
║  ┌─ CHANGES (uncommitted) ───────────────────────────┐   ║
║  │  M  session-state.md                    (+4/-4)   │   ║
║  │  A  reports/process-review/v5.8.1-...   (+380)    │   ║
║  │  ?  plans/transient-tumbling-allen.md             │   ║
║  │                                  Total: +384/-4   │   ║
║  └───────────────────────────────────────────────────┘   ║
║                                                           ║
║  ┌─ BREADCRUMBS (session journey) ───────────────────┐   ║
║  │  session-state → compressed-context → in-progress │   ║
║  │  → watcher.log → insights.md → plan.md            │   ║
║  │  → watcher.log(tail) → diagnostic.log → REPORT   │   ║
║  └───────────────────────────────────────────────────┘   ║
║                                                           ║
║  ┌─ LAYER ─────────┐  ┌─ SUGGESTIONS ───────────────┐   ║
║  │  Nous ████████░░ │  │  Review: current-priorities │   ║
║  │  Pneuma ██░░░░░░ │  │  Push: 2 commits unpushed  │   ║
║  │  Soma ░░░░░░░░░░ │  │  Clean: 48 orphaned /tmp   │   ║
║  └──────────────────┘  └────────────────────────────┘   ║
║                                                           ║
║  Time: 08:47 MST │ Session: 2h 12m │ Tokens: 75K (38%)  ║
╚═══════════════════════════════════════════════════════════╝
```

All file paths are OSC 8 hyperlinks opening in VS Code via `vscode://file/path`.

---

## 5. Three Modes (Auto-Detected)

| Mode | Literary | Trigger | Display Focus |
|------|----------|---------|---------------|
| **Inferno** | Debugging/investigation | Error files, debug.log growth, troubleshooting patterns | Stack traces, error chains, related corrections, "you've been here before" |
| **Purgatorio** | Active implementation | Normal file I/O, git changes, task progress | Active files, changes, breadcrumbs, plan progress |
| **Paradiso** | Review/planning | Plan files accessed, report generation, reflection | Session summary, accomplishments, roadmap position, recommendations |

Mode detection heuristics:
- **Inferno**: Recent files include `debug.log`, `*.log`, error-related files; or git status shows no progress
- **Purgatorio**: Recent writes to source files; git status changing; tasks being completed
- **Paradiso**: Recent reads of plan files, reports, session-state; or no file writes for >5 min

---

## 6. "Virgil Says" — Heuristic Recommendations

Rule-based one-liner shown at bottom of dashboard:

| Priority | Condition | Message |
|----------|-----------|---------|
| 1 (critical) | Context > 70% | "Context at N%. Compression imminent." |
| 2 (high) | Unpushed commits > 0 | "N commits unpushed to remote." |
| 3 (medium) | session-state.md age > 1h | "Session state stale (Nh ago)." |
| 4 (medium) | New files uncommitted | "N new files not yet staged." |
| 5 (low) | No file activity > 5m | "Session quiet for 5 minutes." |
| 6 (info) | Plan with open items | "N plan items remaining." |
| 7 (info) | Watcher failures > 2 | "Watcher has N failures." |

Only the highest-priority applicable rule shows at a time.

---

## 7. Data Sources

| Source | Location | Update Frequency | What It Provides |
|--------|----------|-----------------|-----------------|
| `file-access.json` | `.claude/logs/file-access.json` | Per-tool-call (hook) | File paths, read counts, timestamps |
| `git status` | `git status --short` | On demand | Uncommitted changes |
| `git log` | `git log --oneline origin/..HEAD` | On demand | Unpushed commits |
| `.watcher-status` | `.claude/context/.watcher-status` | Every 10s (watcher) | Tokens, percentage, state |
| `.active-tasks.txt` | `.claude/context/.active-tasks.txt` | Per TodoWrite | Current task list |
| Plan files | `.claude/plans/*.md` | Per session | Session plan and progress |
| CLAUDE.md | `CLAUDE.md` | Stable | Key file map for annotations |

---

## 8. OSC 8 Hyperlink Implementation

```bash
# Core hyperlink function
hyperlink() {
    local url="$1"
    local text="$2"
    printf '\e]8;;%s\e\\%s\e]8;;\e\\' "$url" "$text"
}

# File path to clickable link
file_link() {
    local abs_path="$1"
    local display="$2"
    local url="vscode://file${abs_path}"
    hyperlink "$url" "$display"
}

# Example:
file_link "/Users/aircannon/Claude/Jarvis/.claude/context/session-state.md" "session-state.md"
# Renders: session-state.md (clickable, opens in VS Code)
```

### tmux Configuration Required
```bash
# .tmux.conf additions:
set -g allow-passthrough on
set -as terminal-features ',xterm-256color:hyperlinks'
```

### iTerm2 Requirements
- OSC 8 supported natively (no configuration needed)
- vscode:// URL scheme registered by VS Code installation

---

## 9. Evolution Roadmap

| Version | Timeline | Features | Lines |
|---------|----------|----------|-------|
| **v0.1** | Day 1 | File list with OSC 8 links + git status + watcher status + 1 "Virgil Says" rule | ~100 |
| **v0.2** | Week 1 | Breadcrumbs, full "Virgil Says" engine, color coding by layer | ~200 |
| **v0.3** | Week 2 | Three modes (auto-detect), session narrative, file annotations from CLAUDE.md | ~350 |
| **v1.0** | Month 1 | Cross-session memory, State-of-Mind viewer, project-agnostic config, Canto system | ~500 |

---

## 10. Integration with Existing Infrastructure

| Component | Integration Point |
|-----------|-------------------|
| `launch-jarvis-tmux.sh` | Creates jarvis:2 window, starts virgil.sh |
| `session-start.sh` | No changes needed (Virgil reads existing data) |
| `file-access-tracker` hook | Primary data source (already running) |
| `orchestration-detector` hook | Future: skill/tool orchestration context |
| `CLAUDE.md` | Documents Virgil's role; provides key file map for annotations |
| Watcher | Virgil reads `.watcher-status`; no bidirectional communication |
| State-of-Mind (AC-10) | Future: Virgil displays SoM archives |

---

## 11. Comparison to Watcher

| Aspect | Watcher | Virgil |
|--------|---------|--------|
| Purpose | Defensive — prevent context lockout | Informational — guide understanding |
| Audience | Jarvis (automated) | User (human-readable) |
| Actions | Sends commands (tmux send-keys) | Displays information (renders to pane) |
| Trigger | Context threshold | File access events, periodic poll |
| Output | Log entries, signal files | Visual dashboard with hyperlinks |
| Criticality | System-critical (prevents lockout) | QoL (enhances visibility) |
| Failure mode | Context lockout | Dashboard goes stale (benign) |

---

## 12. The "Canto" System (v1.0 Feature)

Session segmentation inspired by Dante's Cantos:

```
CANTOS (this session)
I.   Context restoration (3 files read, 2 min)
II.  Process review mining (15 artifacts, 48 min)
III. Report writing (1 file created, 380 lines)
IV.  Brainstorming Virgil (current, 12 min)
```

Canto boundaries detected by:
- Time gaps > 5 minutes between file accesses
- File type/directory changes (e.g., logs → reports → plans)
- Git commit events

---

## 13. The Unique Value Proposition

**What Virgil does that nothing else does**: Shows the codebase *through the eyes of the AI working on it*.

When you look at Virgil and see the breadcrumb trail:
```
session-state → watcher.log → diagnostic.log → plan.md → REPORT
```

You can reconstruct the AI's thought process: "Checked state, investigated logs, cross-referenced diagnostics, read the plan, wrote a report." This is a thought process rendered as a file access trail — the visible trace of invisible reasoning.

This is the connection to State-of-Mind: Virgil provides real-time visibility into Jarvis's cognitive activity, while SoM provides historical archives of that activity.

---

## 14. Open Questions for User

1. **Editor**: VS Code, Cursor, or other? (Determines URL scheme: `vscode://`, `cursor://`, etc.)
2. **Layout**: Split pane with Watcher, or separate tmux window?
3. **Start mode**: Automatic with Watcher, or opt-in via flag?
4. **Scope**: Jarvis-only first, or project-agnostic from v0.1?

---

## 15. Related: Option A — Absolute Paths Rule

Complementary to Virgil. A CLAUDE.md behavioral rule ensuring all file paths in Claude's response text are absolute (not relative), making them clickable via iTerm2 Semantic History.

**Proposed CLAUDE.md addition**:
```markdown
## File Path Output Convention
When referencing files in response text:
- ALWAYS use absolute paths starting with /Users/ (never relative ./foo)
- When line-specific: /path/to/file.ext:42
- At end of responses that create/modify files, include:
  **Files touched this response:**
  /absolute/path/to/file1.ext (created)
  /absolute/path/to/file2.ext (modified)
```

**iTerm2 setting**: Profiles → Advanced → Semantic History → Run command: `code --goto \1:\2`

---

## 16. Aion Script Naming Convention

| Script | Literary Source | Realm | Role |
|--------|---------------|-------|------|
| `jarvis-watcher.sh` | Original | — | Context guardian (defensive) |
| `virgil.sh` | *Divina Commedia* | Inferno/Purgatorio | Codebase guide (informational) |
| (future) `beatrice.sh` | *Paradiso* | Paradiso | Higher-order insight/review |

---

## 17. Additional Discoveries (Iterations 10-14)

### OSC 8 Does NOT Work Inside Claude Code TUI
Confirmed by direct test: `printf '\e]8;;url\e\\text\e]8;;\e\\'` renders as raw escape text inside Claude's Ink-based TUI. OSC 8 hyperlinks ONLY work in a separate tmux pane (Virgil's pane). This validates the design decision for Virgil as a separate process.

### file-access.json Validation
- 84 files tracked, 29 KB, 1,039 lines
- Top file: session-state.md (26 reads)
- Python3 parses in milliseconds
- Perfect data source for v0.1

### Debug Log as Archaeological Record
The 35.6 MB debug.log contains every tool call (Read, Write, Edit, Bash, Task) with timestamps. Virgil v1.0 could extract: tool call frequency, file access heatmaps, command patterns, agent usage, time-between-actions. This is "thought archaeology" — reconstructing the AI's reasoning from its behavioral traces.

### "Trail Markers" Feature (v0.2+)
User or Jarvis can drop manual markers: `echo "description" > /tmp/virgil-marker`
Virgil displays these alongside automatic breadcrumbs for explicit session segmentation.

### The Trinity: Watcher, Virgil, Beatrice
- **Watcher**: System guardian (defensive, monitors threats)
- **Virgil**: Activity guide (informational, shows codebase navigation)
- **Beatrice**: Session sage (interpretive, assesses identity alignment — future concept)
- **State-of-Mind** (AC-10): Shared archive layer feeding all three

### Brainstorm Evolution Summary
- Iterations 1-3: Core concept, architecture, integration
- Iterations 4-5: Key insight — "guided navigation" vs "display". Virgil interprets.
- Iterations 6-8: Speculative features (Cantos, identity alignment), self-review
- Iteration 9: Deepest insight — Virgil shows codebase "through AI's eyes"
- Iterations 10-11: Practical validation (file-access.json, OSC 8 test, debug.log mining)
- Iterations 12-13: v0.1 implementation sketch, long-term trinity vision
- Iteration 14: Final critical review, gap analysis
- Iterations 15-17: (Pre-compression) tmux 3.4 hyperlink passthrough verification, deep technical validation
- Iteration 18: file-access.json schema validation (read_count, first_read, last_read, sessions, daily_history)
- Iteration 19: v0.1 implementation skeleton (~100 lines bash+python3), tmux configuration checklist
- Iteration 20: Final consolidation, summary update, exit gate check

---

## 18. v0.1 Implementation Skeleton

Concrete pseudocode for the minimum viable Virgil:

```bash
#!/usr/bin/env bash
# virgil.sh — Codebase Guide Aion Script v0.1
# Runs in tmux jarvis:2, 15s refresh cycle
# Read-only, no LLM calls, deterministic heuristics

set -euo pipefail

PROJECT_DIR="${JARVIS_PROJECT_DIR:-/Users/aircannon/Claude/Jarvis}"
FILE_ACCESS="$PROJECT_DIR/.claude/logs/file-access.json"
WATCHER_STATUS="$PROJECT_DIR/.claude/context/.watcher-status"
REFRESH=15  # seconds

# --- OSC 8 Hyperlink Helpers ---
hyperlink() { printf '\e]8;;%s\e\\%s\e]8;;\e\\' "$1" "$2"; }
file_link() {
    local abs="$PROJECT_DIR/$1" display="${2:-$1}"
    hyperlink "vscode://file${abs}" "$display"
}

# --- Data Extraction ---
get_recent_files() {
    # Top 8 files by last_read, using python3 for JSON
    python3 -c "
import json, sys
from datetime import datetime, timedelta, timezone
d = json.load(open('$FILE_ACCESS'))
cutoff = datetime.now(timezone.utc) - timedelta(minutes=10)
recent = []
for path, info in d.get('files', {}).items():
    lr = datetime.fromisoformat(info['last_read'].replace('Z','+00:00'))
    if lr > cutoff:
        recent.append((lr, path, info['read_count']))
recent.sort(reverse=True)
for lr, path, count in recent[:8]:
    print(f'{count}\t{path}')
" 2>/dev/null
}

get_git_changes() { git -C "$PROJECT_DIR" status --short 2>/dev/null; }
get_unpushed()    { git -C "$PROJECT_DIR" log --oneline origin/Project_Aion..HEAD 2>/dev/null | wc -l | tr -d ' '; }
get_watcher()     { cat "$WATCHER_STATUS" 2>/dev/null; }

# --- Virgil Says (highest priority rule wins) ---
virgil_says() {
    local pct unpushed
    pct=$(awk '/^percentage:/{gsub(/%/,""); print $2}' "$WATCHER_STATUS" 2>/dev/null)
    unpushed=$(get_unpushed)
    if [[ "${pct:-0}" -ge 70 ]]; then
        echo "Context at ${pct}%. Compression imminent."
    elif [[ "${unpushed:-0}" -gt 0 ]]; then
        echo "${unpushed} commit(s) unpushed to remote."
    else
        echo "All systems nominal."
    fi
}

# --- Render ---
render() {
    clear
    local cols=$(tput cols 2>/dev/null || echo 60)
    printf '\e[1;36m VIRGIL\e[0m — Codebase Guide'
    printf '%*s' $((cols - 30)) "$(date '+%H:%M %Z')"
    echo; printf '%.0s─' $(seq 1 "$cols"); echo

    echo -e "\n\e[1m RECENT FILES (last 10 min)\e[0m"
    local files
    files=$(get_recent_files)
    if [[ -n "$files" ]]; then
        while IFS=$'\t' read -r count path; do
            printf '  %3dx  ' "$count"
            file_link "$path" "$path"
            echo
        done <<< "$files"
    else
        echo "  (no recent file activity)"
    fi

    echo -e "\n\e[1m CHANGES (uncommitted)\e[0m"
    local changes
    changes=$(get_git_changes)
    if [[ -n "$changes" ]]; then
        echo "$changes" | head -10 | while read -r line; do
            echo "  $line"
        done
    else
        echo "  (clean working tree)"
    fi

    echo -e "\n\e[1m CONTEXT\e[0m"
    local tokens pct state
    tokens=$(awk '/^tokens:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
    pct=$(awk '/^percentage:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
    state=$(awk '/^state:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
    echo "  Tokens: ${tokens:-?} (${pct:-?}) | State: ${state:-?}"

    printf '\n%.0s─' $(seq 1 "$cols"); echo
    printf '\e[33m ☞ Virgil says:\e[0m %s\n' "$(virgil_says)"
}

# --- Main Loop ---
while true; do
    render
    sleep "$REFRESH"
done
```

**v0.1 acceptance criteria**:
1. Renders in tmux pane without errors
2. Shows recent files as OSC 8 hyperlinks (clickable → VS Code)
3. Shows git status summary
4. Shows watcher context status
5. One "Virgil Says" heuristic recommendation
6. Refreshes every 15 seconds
7. Exits cleanly on SIGTERM/SIGINT

**Estimated**: ~85 lines of bash + ~15 lines of python3 helper = ~100 lines total.

---

## 19. tmux Configuration Checklist (v0.1)

```bash
# Required in .tmux.conf or session setup:
set -g allow-passthrough on
set -as terminal-features ',xterm-256color:hyperlinks'

# launch-jarvis-tmux.sh additions:
tmux new-window -t jarvis:2 -n virgil
tmux send-keys -t jarvis:2 "$PROJECT_DIR/.claude/scripts/virgil.sh" C-m
```

**Verification commands**:
```bash
# Test OSC 8 in tmux pane:
printf '\e]8;;https://example.com\e\\Click me\e]8;;\e\\'
# Should render "Click me" as clickable link in iTerm2

# Test vscode:// scheme:
open 'vscode://file/Users/aircannon/Claude/Jarvis/CLAUDE.md'
# Should open CLAUDE.md in VS Code
```

---

*Brainstorm produced over 19 Wiggum loop iterations, 2026-02-07 08:44-09:00 MST.*
