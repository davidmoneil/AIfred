#!/usr/bin/env node
/**
 * Virgil Tracker — F.2 Virgil MVP
 *
 * PostToolUse + SubagentStop hook that maintains signal files for
 * the Virgil dashboard (virgil.sh v0.2).
 *
 * PostToolUse triggers:
 *   - TaskCreate → adds task to .virgil-tasks.json
 *   - TaskUpdate → updates task status in .virgil-tasks.json
 *   - Task       → adds agent to .virgil-agents.json
 *
 * SubagentStop trigger:
 *   - Marks agent as completed in .virgil-agents.json
 *
 * Signal files (dot-prefixed, gitignored):
 *   .claude/context/.virgil-tasks.json
 *   .claude/context/.virgil-agents.json
 *
 * Design: Stateless, atomic writes (tmp→rename), 15-min stale cleanup.
 */

const fs = require("fs");
const path = require("path");

const PROJECT_DIR = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const TASKS_FILE = path.join(PROJECT_DIR, ".claude/context/.virgil-tasks.json");
const AGENTS_FILE = path.join(PROJECT_DIR, ".claude/context/.virgil-agents.json");
const STALE_MS = 15 * 60 * 1000; // 15 minutes

// --- File I/O helpers ---

function readJSON(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch {
    return null;
  }
}

function writeJSON(filePath, data) {
  data.updated = new Date().toISOString();
  const tmp = filePath + ".tmp";
  fs.writeFileSync(tmp, JSON.stringify(data, null, 2) + "\n");
  fs.renameSync(tmp, filePath);
}

// --- Stale entry cleanup ---

function pruneStale(entries, timestampKey) {
  const cutoff = Date.now() - STALE_MS;
  return entries.filter((e) => {
    const ts = e[timestampKey];
    if (!ts) return false;
    return new Date(ts).getTime() > cutoff;
  });
}

// --- Task tracking ---

function handleTaskCreate(toolInput, toolOutput) {
  const data = readJSON(TASKS_FILE) || { tasks: [] };

  // Extract task ID from output (TaskCreate returns the created task)
  let taskId = "unknown";
  try {
    const out =
      typeof toolOutput === "string" ? JSON.parse(toolOutput) : toolOutput;
    taskId = String(out.id || out.taskId || "unknown");
  } catch {
    // Use subject hash as fallback ID
    taskId = String(Date.now());
  }

  data.tasks = pruneStale(data.tasks || [], "timestamp");

  data.tasks.push({
    id: taskId,
    subject: toolInput.subject || "(untitled)",
    status: "pending",
    activeForm: toolInput.activeForm || "",
    timestamp: new Date().toISOString(),
  });

  writeJSON(TASKS_FILE, data);
}

function handleTaskUpdate(toolInput) {
  const data = readJSON(TASKS_FILE);
  if (!data || !data.tasks) return;

  data.tasks = pruneStale(data.tasks, "timestamp");

  const taskId = String(toolInput.taskId || "");
  const task = data.tasks.find((t) => t.id === taskId);
  if (task) {
    if (toolInput.status) task.status = toolInput.status;
    if (toolInput.subject) task.subject = toolInput.subject;
    if (toolInput.activeForm) task.activeForm = toolInput.activeForm;
    task.timestamp = new Date().toISOString();
  }

  writeJSON(TASKS_FILE, data);
}

// --- Agent tracking ---

function handleAgentLaunch(toolInput) {
  const data = readJSON(AGENTS_FILE) || { agents: [] };
  data.agents = pruneStale(data.agents || [], "started");

  const agentId =
    (toolInput.description || "agent").replace(/\s+/g, "-").slice(0, 30) +
    "-" +
    Date.now().toString(36);

  data.agents.push({
    id: agentId,
    type: toolInput.subagent_type || "unknown",
    description: (toolInput.description || "").slice(0, 60),
    started: new Date().toISOString(),
    status: "running",
  });

  writeJSON(AGENTS_FILE, data);
}

function handleAgentStop(context) {
  const data = readJSON(AGENTS_FILE);
  if (!data || !data.agents) return;

  data.agents = pruneStale(data.agents, "started");

  // Mark the most recent running agent of matching type as completed
  const agentName = context.agent_name || "";
  for (let i = data.agents.length - 1; i >= 0; i--) {
    if (data.agents[i].status === "running") {
      // Match by type if available, otherwise mark most recent
      if (
        !agentName ||
        data.agents[i].type.toLowerCase() === agentName.toLowerCase()
      ) {
        data.agents[i].status = "completed";
        data.agents[i].finished = new Date().toISOString();
        break;
      }
    }
  }

  // Remove completed agents older than 2 minutes (keep briefly for display)
  const completedCutoff = Date.now() - 2 * 60 * 1000;
  data.agents = data.agents.filter((a) => {
    if (a.status === "completed" && a.finished) {
      return new Date(a.finished).getTime() > completedCutoff;
    }
    return true;
  });

  writeJSON(AGENTS_FILE, data);
}

// --- Main ---

let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  try {
    const hookData = JSON.parse(input);
    const toolName = hookData.tool_name || "";
    const toolInput = hookData.tool_input || {};
    const toolOutput = hookData.tool_output || "";

    if (toolName === "TaskCreate") {
      handleTaskCreate(toolInput, toolOutput);
    } else if (toolName === "TaskUpdate") {
      handleTaskUpdate(toolInput);
    } else if (toolName === "Task") {
      handleAgentLaunch(toolInput);
    } else if (hookData.agent_name !== undefined) {
      // SubagentStop event (has agent_name field)
      handleAgentStop(hookData);
    }
  } catch {
    // Non-critical — dashboard will show stale or empty data
  }

  console.log(JSON.stringify({ continue: true }));
});
