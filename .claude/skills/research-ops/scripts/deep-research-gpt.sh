#!/usr/bin/env bash
# GPT Researcher — autonomous multi-source research agent
# Replaces: gptresearcher MCP
# Status: BLOCKED — API key not yet provisioned
# Usage: ./deep-research-gpt.sh "research question" [--type research|outline|resource]
set -euo pipefail

show_help() {
    cat <<'HELP'
Usage: deep-research-gpt.sh QUESTION [OPTIONS]

GPT Researcher provides autonomous multi-source research with
source validation and report generation.

Status: BLOCKED — API key not yet provisioned.

Alternative: Use the deep-research agent via Task tool:
  Task(subagent_type="deep-research", prompt="your question")

Options:
  --type TYPE    Report type: research (default), outline, resource
  --help         Show this help

When API key is provisioned:
  1. Add key to .claude/secrets/credentials.yaml at .research.gptresearcher
  2. Update this script with actual API endpoint
  3. Test with: ./deep-research-gpt.sh "test query"
HELP
}

QUESTION="${1:-}" REPORT_TYPE="research_report"

if [[ "$QUESTION" == "--help" || -z "$QUESTION" ]]; then
    show_help
    exit 0
fi

while [[ $# -gt 1 ]]; do
    case "$2" in
        --type)
            case "${3:-research}" in
                research) REPORT_TYPE="research_report" ;;
                outline) REPORT_TYPE="outline_report" ;;
                resource) REPORT_TYPE="resource_report" ;;
                *) REPORT_TYPE="$3" ;;
            esac
            shift 2 ;;
        *) shift ;;
    esac
done

# Output workflow instructions as structured JSON
ESCAPED_Q="${QUESTION//\"/\\\"}"
cat <<JSON
{
    "backend": "gptresearcher",
    "status": "blocked",
    "blocker": "API key not provisioned",
    "question": "$ESCAPED_Q",
    "report_type": "$REPORT_TYPE",
    "alternative": {
        "method": "Task tool with deep-research agent",
        "invocation": "Task(subagent_type='deep-research', prompt='$ESCAPED_Q')"
    },
    "when_ready": {
        "step1": "Provision API key at .research.gptresearcher in credentials.yaml",
        "step2": "Update this script with GPT Researcher API endpoint",
        "step3": "Implement actual API call replacing this JSON output"
    },
    "credential_path": ".research.gptresearcher (TBD)"
}
JSON
