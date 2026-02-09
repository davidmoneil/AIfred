#!/usr/bin/env bash
# arXiv API — academic paper search with category and author filters
# Replaces: arxiv MCP
# Usage: ./search-arxiv.sh "query" [--max N] [--category CAT] [--author NAME] [--sort date|relevance]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

show_help() {
    cat <<'HELP'
Usage: search-arxiv.sh QUERY [OPTIONS]

Options:
  --max N           Max results (default: 5, max: 50)
  --category CAT    Filter by category (e.g., cs.AI, cs.LG, cs.CL, math.CO)
  --author NAME     Filter by author name
  --sort MODE       Sort by: date (default), relevance
  --help            Show this help

Examples:
  search-arxiv.sh "transformer architecture"
  search-arxiv.sh "attention mechanism" --category cs.LG --max 10
  search-arxiv.sh "language models" --author "Vaswani" --sort relevance
HELP
}

# Parse arguments
QUERY="" MAX=5 CATEGORY="" AUTHOR="" SORT="submittedDate"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max) MAX="$2"; shift 2 ;;
        --category) CATEGORY="$2"; shift 2 ;;
        --author) AUTHOR="$2"; shift 2 ;;
        --sort)
            case "$2" in
                date) SORT="submittedDate" ;;
                relevance) SORT="relevance" ;;
                *) SORT="$2" ;;
            esac
            shift 2 ;;
        --help) show_help; exit 0 ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) QUERY="$1"; shift ;;
    esac
done

if [[ -z "$QUERY" ]]; then
    show_help
    exit 1
fi

require_commands curl || exit 1

# Build search query
SEARCH="all:$(url_encode "$QUERY")"
if [[ -n "$CATEGORY" ]]; then
    SEARCH+="+AND+cat:${CATEGORY}"
fi
if [[ -n "$AUTHOR" ]]; then
    SEARCH+="+AND+au:$(url_encode "$AUTHOR")"
fi

URL="https://export.arxiv.org/api/query?search_query=${SEARCH}&max_results=${MAX}&sortBy=${SORT}&sortOrder=descending"

# Make request (arXiv returns XML/Atom)
RESPONSE=$(http_get "$URL" 30) || handle_error "arxiv" "API request failed"

# Parse XML to structured text output
# Check if xmllint is available for proper parsing
if command -v xmllint &>/dev/null; then
    echo "=== arXiv Search Results ==="
    echo "Query: $QUERY"
    if [[ -n "$CATEGORY" ]]; then echo "Category: $CATEGORY"; fi
    if [[ -n "$AUTHOR" ]]; then echo "Author filter: $AUTHOR"; fi
    echo ""

    # Extract total results
    TOTAL=$(echo "$RESPONSE" | xmllint --xpath '//*[local-name()="totalResults"]/text()' - 2>/dev/null || echo "unknown")
    echo "Total matches: $TOTAL (showing up to $MAX)"
    echo "---"

    # Extract entries using xmllint
    ENTRY_COUNT=$(echo "$RESPONSE" | xmllint --xpath 'count(//*[local-name()="entry"])' - 2>/dev/null || echo "0")

    for (( i=1; i<=ENTRY_COUNT; i++ )); do
        TITLE=$(echo "$RESPONSE" | xmllint --xpath '//*[local-name()="entry"]['"$i"']/*[local-name()="title"]/text()' - 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g; s/^ //; s/ $//')
        SUMMARY=$(echo "$RESPONSE" | xmllint --xpath '//*[local-name()="entry"]['"$i"']/*[local-name()="summary"]/text()' - 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g; s/^ //; s/ $//')
        ID=$(echo "$RESPONSE" | xmllint --xpath '//*[local-name()="entry"]['"$i"']/*[local-name()="id"]/text()' - 2>/dev/null)
        PUBLISHED=$(echo "$RESPONSE" | xmllint --xpath '//*[local-name()="entry"]['"$i"']/*[local-name()="published"]/text()' - 2>/dev/null)

        echo ""
        echo "[$i] $TITLE"
        echo "    Published: $PUBLISHED"
        echo "    URL: $ID"
        echo "    Abstract: ${SUMMARY:0:300}..."
    done
else
    # Fallback: output raw XML if xmllint unavailable
    echo "$RESPONSE"
fi
