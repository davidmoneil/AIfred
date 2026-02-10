#!/usr/bin/env bash
# virgil-web.sh — Serve Virgil task diagram UI on localhost:8377
# Serves .claude/virgil-ui/ with python3 http.server
# Symlinks .virgil-tasks.json into the served directory for fetch access

set -euo pipefail

PROJECT_DIR="${JARVIS_PROJECT_DIR:-/Users/aircannon/Claude/Jarvis}"
UI_DIR="$PROJECT_DIR/.claude/virgil-ui"
TASKS_SOURCE="$PROJECT_DIR/.claude/context/.virgil-tasks.json"
TASKS_LINK="$UI_DIR/.virgil-tasks.json"
PORT=8377

trap 'echo "Virgil Web: shutting down."; rm -f "$TASKS_LINK"; exit 0' SIGTERM SIGINT

# Create empty tasks file if it doesn't exist
if [[ ! -f "$TASKS_SOURCE" ]]; then
    echo '{"tasks":[]}' > "$TASKS_SOURCE"
fi

# Symlink tasks JSON into served directory
ln -sf "$TASKS_SOURCE" "$TASKS_LINK"

echo "Virgil Web UI: http://localhost:${PORT}"
echo "Task data: ${TASKS_SOURCE}"
echo "Press Ctrl+C to stop."

cd "$UI_DIR"
python3 -m http.server "$PORT" --bind 127.0.0.1 2>/dev/null
