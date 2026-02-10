#!/usr/bin/env node
/**
 * Observation Size Tracker — B.4 Phase 3
 *
 * PostToolUse hook that tracks tool output sizes for JICM telemetry.
 * Records observation metrics to help monitor context consumption patterns.
 *
 * Does NOT modify tool output (hooks cannot intercept output).
 * Instead, tracks metrics and logs large observations for analysis.
 *
 * Triggers on: Read, Bash, Grep, Glob, WebFetch, WebSearch
 */

const fs = require("fs");
const path = require("path");

let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  try {
    const hookData = JSON.parse(input);
    main(hookData);
  } catch (e) {
    output({ continue: true });
  }
});

function main(hookData) {
  const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
  const toolName = hookData.tool_name || "unknown";
  const toolOutput = hookData.tool_output || "";

  // Estimate output size (rough token count: ~4 chars per token)
  const outputStr =
    typeof toolOutput === "string"
      ? toolOutput
      : JSON.stringify(toolOutput);
  const estimatedTokens = Math.ceil(outputStr.length / 4);

  // Thresholds from observation-masking-pattern.md
  const thresholds = {
    Read: 2000, // >500 lines ~ >2000 tokens
    Bash: 500, // >2000 chars ~ >500 tokens
    Grep: 400, // >100 lines ~ >400 tokens
    Glob: 200, // >50 files ~ >200 tokens
    WebFetch: 1000,
    WebSearch: 500
  };

  const threshold = thresholds[toolName] || 1000;
  const isLarge = estimatedTokens > threshold;

  // Write metrics to JICM session observations
  const sessionIdFile = path.join(
    projectDir,
    ".claude/context/jicm/.current-session-id"
  );
  let sessionId = null;

  try {
    sessionId = fs.readFileSync(sessionIdFile, "utf8").trim();
  } catch (e) {
    // No active session — skip observation tracking
  }

  if (sessionId) {
    const obsFile = path.join(
      projectDir,
      `.claude/context/jicm/sessions/${sessionId}/observations.yaml`
    );

    try {
      const entry = `\n- tool: "${toolName}"\n  tokens_est: ${estimatedTokens}\n  large: ${isLarge}\n  timestamp: "${new Date().toISOString()}"\n`;
      fs.appendFileSync(obsFile, entry);
    } catch (e) {
      // Session directory may not exist yet — non-critical
    }
  }

  // Log telemetry for large observations
  if (isLarge) {
    const telemetryEntry = JSON.stringify({
      component: "AC-04",
      event_type: "observation_large",
      data: {
        tool: toolName,
        estimated_tokens: estimatedTokens,
        threshold: threshold,
        ratio: (estimatedTokens / threshold).toFixed(1)
      }
    });

    const eventsFile = path.join(
      projectDir,
      `.claude/logs/telemetry/events-${new Date().toISOString().slice(0, 10)}.jsonl`
    );

    try {
      fs.appendFileSync(eventsFile, telemetryEntry + "\n");
    } catch (e) {
      // Telemetry failure is non-critical
    }
  }

  output({ continue: true });
}

function output(result) {
  console.log(JSON.stringify(result));
}
