#!/usr/bin/env bash
# Perplexity AI Search — AI-augmented search with citations and 4 sonar models
# Replaces: perplexity MCP
# Usage: ./search-perplexity.sh "query" [--model sonar|sonar-pro|sonar-reasoning|sonar-deep-research]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

show_help() {
    cat <<'HELP'
Usage: search-perplexity.sh QUERY [OPTIONS]

Options:
  --model MODEL    Sonar model to use (default: sonar)
                   sonar              — Quick factual search with citations
                   sonar-pro          — Complex multi-step research
                   sonar-reasoning    — Analysis with chain-of-thought
                   sonar-deep-research — Autonomous deep investigation (30-40s)
  --help           Show this help

Examples:
  search-perplexity.sh "What is Claude AI?"
  search-perplexity.sh "Compare React vs Vue in 2026" --model sonar-pro
  search-perplexity.sh "AI safety alignment research" --model sonar-deep-research
HELP
}

# Parse arguments
QUERY="" MODEL="sonar"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --model) MODEL="$2"; shift 2 ;;
        --help) show_help; exit 0 ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) QUERY="$1"; shift ;;
    esac
done

if [[ -z "$QUERY" ]]; then
    show_help
    exit 1
fi

require_commands curl jq yq || exit 1

KEY=$(get_credential ".llm.perplexity") || exit 1

# Validate model
case "$MODEL" in
    sonar|sonar-pro|sonar-reasoning|sonar-deep-research) ;;
    *) handle_error "perplexity" "Unknown model: $MODEL. Use: sonar, sonar-pro, sonar-reasoning, sonar-deep-research" ;;
esac

# Set timeout based on model (deep-research takes much longer)
TIMEOUT=15
if [[ "$MODEL" == "sonar-deep-research" ]]; then
    TIMEOUT=120
elif [[ "$MODEL" == "sonar-reasoning" ]]; then
    TIMEOUT=45
elif [[ "$MODEL" == "sonar-pro" ]]; then
    TIMEOUT=30
fi

# Build JSON payload (escape query for JSON)
ESCAPED_QUERY=$(echo "$QUERY" | jq -Rs '.')
PAYLOAD=$(cat <<JSON
{
    "model": "$MODEL",
    "messages": [
        {"role": "user", "content": $ESCAPED_QUERY}
    ]
}
JSON
)

# Make request
RESPONSE=$(http_post \
    "https://api.perplexity.ai/chat/completions" \
    "$PAYLOAD" \
    "Authorization: Bearer $KEY" \
    "$TIMEOUT") || handle_error "perplexity" "API request failed"

# Format output — extract content and citations
echo "$RESPONSE" | jq '{
    model: .model,
    query: '"$ESCAPED_QUERY"',
    content: .choices[0].message.content,
    citations: .citations,
    usage: {
        prompt_tokens: .usage.prompt_tokens,
        completion_tokens: .usage.completion_tokens
    }
}' 2>/dev/null || format_json "$RESPONSE"
