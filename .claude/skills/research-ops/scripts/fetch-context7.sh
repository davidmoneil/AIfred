#!/usr/bin/env bash
# Context7 — version-pinned library docs via local-rag MCP
# Replaces: context7 MCP
# Status: PARTIAL — requires local-rag MCP (retained, server-dependent)
# Usage: ./fetch-context7.sh "library" "topic"
set -euo pipefail

show_help() {
    cat <<'HELP'
Usage: fetch-context7.sh LIBRARY TOPIC

Context7 provides version-pinned library documentation optimized for LLMs.
This backend requires the local-rag MCP (retained, server-dependent).

Integration workflow (execute in Claude Code):
  1. ToolSearch("+local-rag")
  2. mcp__local-rag__query_documents("LIBRARY: TOPIC")

Direct API alternative (if local-rag unavailable):
  curl -s "https://api.context7.com/v1/search" \
    -H "Authorization: Bearer $KEY" \
    -d '{"library":"LIBRARY","query":"TOPIC"}'

Options:
  --help    Show this help

Examples:
  fetch-context7.sh "react" "hooks useState"
  fetch-context7.sh "typescript@5.0" "generics"
HELP
}

LIBRARY="${1:-}" TOPIC="${2:-}"

if [[ "$LIBRARY" == "--help" || -z "$LIBRARY" || -z "$TOPIC" ]]; then
    show_help
    exit 0
fi

# Output workflow instructions as structured JSON
cat <<JSON
{
    "backend": "context7",
    "status": "partial",
    "library": "$LIBRARY",
    "topic": "$TOPIC",
    "message": "Context7 requires local-rag MCP for semantic search. Use the workflow below in Claude Code.",
    "workflow": {
        "step1": "ToolSearch(\"+local-rag\") — Load local-rag MCP tools",
        "step2": "mcp__local-rag__query_documents(\"$LIBRARY: $TOPIC\") — Query indexed docs",
        "step3": "If not indexed: mcp__local-rag__ingest_file(path) — Ingest library docs first"
    },
    "credential_path": ".rag.context7",
    "note": "Full reconstruction requires either local-rag MCP or direct Context7 API with provisioned key"
}
JSON
