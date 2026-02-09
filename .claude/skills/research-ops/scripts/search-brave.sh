#!/usr/bin/env bash
# Brave Search API — web/news/video search with freshness filters
# Replaces: brave-search MCP
# Usage: ./search-brave.sh "query" [--type web|news|videos|images] [--freshness day|week|month|year] [--count N]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

show_help() {
    cat <<'HELP'
Usage: search-brave.sh QUERY [OPTIONS]

Options:
  --type TYPE        Search type: web (default), news, videos, images
  --freshness PERIOD Filter by: day, week, month, year
  --count N          Number of results (default: 5, max: 20)
  --help             Show this help

Examples:
  search-brave.sh "Claude AI"
  search-brave.sh "tech news" --type news --freshness day --count 10
HELP
}

# Parse arguments
QUERY="" TYPE="web" FRESHNESS="" COUNT=5
while [[ $# -gt 0 ]]; do
    case "$1" in
        --type) TYPE="$2"; shift 2 ;;
        --freshness) FRESHNESS="$2"; shift 2 ;;
        --count) COUNT="$2"; shift 2 ;;
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

KEY=$(get_credential ".search.brave") || exit 1

# Build URL
ENCODED_QUERY=$(url_encode "$QUERY")
URL="https://api.search.brave.com/res/v1/${TYPE}/search?q=${ENCODED_QUERY}&count=${COUNT}"
if [[ -n "$FRESHNESS" ]]; then
    URL+="&freshness=${FRESHNESS}"
fi

# Make request
RESPONSE=$(curl -s --compressed -w "\n%{http_code}" --max-time 15 \
    -H "Accept: application/json" \
    -H "X-Subscription-Token: $KEY" \
    "$URL" 2>/dev/null) || handle_error "brave" "Connection failed"

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ge 400 ]] 2>/dev/null; then
    handle_error "brave" "API request failed" "$HTTP_CODE"
fi

# Format output
echo "$BODY" | jq '{
    query: .query.original,
    type: "'"$TYPE"'",
    result_count: (.web.results // .news.results // .videos.results // [] | length),
    results: [(.web.results // .news.results // .videos.results // [])[:'"$COUNT"'] | .[] | {
        title: .title,
        url: .url,
        description: .description,
        age: .age
    }]
}' 2>/dev/null || format_json "$BODY"
