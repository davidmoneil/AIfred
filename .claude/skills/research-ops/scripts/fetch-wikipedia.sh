#!/usr/bin/env bash
# Wikipedia REST API — structured article access with multi-language support
# Replaces: wikipedia MCP
# Usage: ./fetch-wikipedia.sh "Article_Title" [--lang en] [--mode summary|full] [--search]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

show_help() {
    cat <<'HELP'
Usage: fetch-wikipedia.sh TITLE [OPTIONS]

Options:
  --lang LANG    Language code (default: en). Examples: es, fr, de, ja
  --mode MODE    Retrieval mode: summary (default), full
  --search       Search for articles instead of fetching by exact title
  --help         Show this help

Examples:
  fetch-wikipedia.sh "Artificial_intelligence"
  fetch-wikipedia.sh "Claude (AI)" --mode full
  fetch-wikipedia.sh "machine learning" --search --lang es
HELP
}

# Parse arguments
TITLE="" LANG="en" MODE="summary" SEARCH=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --lang) LANG="$2"; shift 2 ;;
        --mode) MODE="$2"; shift 2 ;;
        --search) SEARCH=true; shift ;;
        --help) show_help; exit 0 ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) TITLE="$1"; shift ;;
    esac
done

if [[ -z "$TITLE" ]]; then
    show_help
    exit 1
fi

require_commands curl jq || exit 1

if [[ "$SEARCH" == true ]]; then
    # Search mode — find articles matching query
    ENCODED=$(url_encode "$TITLE")
    URL="https://${LANG}.wikipedia.org/api/rest_v1/page/search/${ENCODED}"

    RESPONSE=$(http_get "$URL" 15) || handle_error "wikipedia" "Search failed"

    echo "$RESPONSE" | jq --arg q "$TITLE" --arg lang "$LANG" '{
        query: $q,
        language: $lang,
        results: [.pages[:10] | .[] | {
            title: .title,
            description: .description,
            excerpt: .excerpt
        }]
    }' 2>/dev/null || format_json "$RESPONSE"
else
    # Fetch mode — get article by title
    # Encode title (spaces → underscores for Wikipedia)
    ENCODED_TITLE="${TITLE// /_}"

    if [[ "$MODE" == "full" ]]; then
        # Full HTML extract → convert to text
        URL="https://${LANG}.wikipedia.org/api/rest_v1/page/html/${ENCODED_TITLE}"
        RESPONSE=$(http_get "$URL" 30) || handle_error "wikipedia" "Article not found: $TITLE"
        echo "$RESPONSE"
    else
        # Summary mode (default) — structured JSON
        URL="https://${LANG}.wikipedia.org/api/rest_v1/page/summary/${ENCODED_TITLE}"
        RESPONSE=$(http_get "$URL" 15) || handle_error "wikipedia" "Article not found: $TITLE"

        echo "$RESPONSE" | jq --arg lang "$LANG" '{
            title: .title,
            description: .description,
            extract: .extract,
            language: $lang,
            url: .content_urls.desktop.page,
            thumbnail: .thumbnail.source,
            last_modified: .timestamp
        }' 2>/dev/null || format_json "$RESPONSE"
    fi
fi
