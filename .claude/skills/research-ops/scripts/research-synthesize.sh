#!/usr/bin/env bash
# Research Synthesize — multi-source aggregation, citation, narrative generation
# Usage: ./research-synthesize.sh --results-dir DIR [--format markdown|json] [--style narrative|matrix|bullets]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

show_help() {
    cat <<'HELP'
Usage: research-synthesize.sh [OPTIONS]

Aggregates research results from multiple backend queries into a coherent,
cited synthesis. Reads JSON result files from a directory or stdin.

Options:
  --results-dir DIR   Directory containing JSON result files (one per backend query)
  --plan FILE         Research plan JSON (from research-plan.sh) for structure guidance
  --format FORMAT     Output format: markdown (default), json
  --style STYLE       Synthesis style: narrative, matrix, bullets (default: narrative)
  --title TITLE       Title for the synthesis report
  --stdin             Read results from stdin (JSON array)
  --help              Show this help

Input Format:
  Each result file should be JSON with at minimum:
  {
    "source": "backend-name",
    "query": "the sub-question",
    "results": [ { "title": "...", "url": "...", "description": "..." } ]
  }

Examples:
  research-synthesize.sh --results-dir /tmp/research-results/ --title "JICM Analysis"
  research-synthesize.sh --results-dir ./results --plan plan.json --style matrix
  cat results.json | research-synthesize.sh --stdin --format json
HELP
}

# Parse arguments
RESULTS_DIR="" PLAN_FILE="" FORMAT="markdown" STYLE="narrative" TITLE="" USE_STDIN=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --results-dir) RESULTS_DIR="$2"; shift 2 ;;
        --plan) PLAN_FILE="$2"; shift 2 ;;
        --format) FORMAT="$2"; shift 2 ;;
        --style) STYLE="$2"; shift 2 ;;
        --title) TITLE="$2"; shift 2 ;;
        --stdin) USE_STDIN=true; shift ;;
        --help) show_help; exit 0 ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) echo "Unexpected argument: $1" >&2; exit 1 ;;
    esac
done

if [[ "$USE_STDIN" == false && -z "$RESULTS_DIR" ]]; then
    echo "ERROR: Either --results-dir or --stdin required" >&2
    show_help
    exit 1
fi

require_commands jq || exit 1

# Collect all results into a single JSON array
collect_results() {
    if [[ "$USE_STDIN" == true ]]; then
        cat
    else
        if [[ ! -d "$RESULTS_DIR" ]]; then
            echo "ERROR: Results directory not found: $RESULTS_DIR" >&2
            return 1
        fi
        local combined='[]'
        for f in "$RESULTS_DIR"/*.json; do
            [[ -f "$f" ]] || continue
            local content
            content=$(cat "$f")
            combined=$(echo "$combined" | jq --argjson r "$content" '. + [$r]')
        done
        echo "$combined"
    fi
}

# Extract unique sources for citation
extract_citations() {
    local results="$1"
    echo "$results" | jq '[
        .[] |
        .results[]? |
        select(.url != null and .url != "") |
        {title: (.title // "Untitled"), url: .url, source: (.source // "unknown")}
    ] | unique_by(.url) | sort_by(.title)'
}

# Count total results across all sources
count_results() {
    local results="$1"
    echo "$results" | jq '[.[] | (.results // []) | length] | add // 0'
}

# Count unique sources
count_sources() {
    local results="$1"
    echo "$results" | jq '[.[].source // "unknown"] | unique | length'
}

# Extract key findings (titles + descriptions, deduped by URL)
extract_findings() {
    local results="$1"
    echo "$results" | jq '[
        .[] |
        .source as $src |
        (.results // [])[] |
        {
            title: (.title // "Untitled"),
            description: (.description // .snippet // .abstract // ""),
            url: (.url // ""),
            source_backend: $src,
            query_context: (.query // "")
        }
    ] | unique_by(.url) | sort_by(.title)'
}

# Generate markdown synthesis
generate_markdown() {
    local results="$1" title="$2" style="$3"
    local findings citations total_results source_count

    findings=$(extract_findings "$results")
    citations=$(extract_citations "$results")
    total_results=$(count_results "$results")
    source_count=$(count_sources "$results")

    # Header
    echo "# ${title:-Research Synthesis}"
    echo ""
    echo "**Sources**: $source_count backends | **Results**: $total_results total | **Unique findings**: $(echo "$findings" | jq length)"
    echo "**Generated**: $(date +%Y-%m-%d' '%H:%M)"
    echo ""

    # Load plan context if available
    if [[ -n "$PLAN_FILE" && -f "$PLAN_FILE" ]]; then
        local qtype
        qtype=$(jq -r '.plan.question_type // "general"' "$PLAN_FILE")
        echo "**Query type**: $qtype | **Strategy**: $(jq -r '.plan.synthesis_strategy // "narrative"' "$PLAN_FILE")"
        echo ""
    fi

    echo "---"
    echo ""

    case "$style" in
        matrix)
            echo "## Comparison Matrix"
            echo ""
            echo "| Finding | Source | URL |"
            echo "|---------|--------|-----|"
            echo "$findings" | jq -r '.[] | "| \(.title | gsub("\\|"; "/")) | \(.source_backend) | [\(.url | split("/")[2] // "link")](\(.url)) |"'
            ;;

        bullets)
            echo "## Key Findings"
            echo ""
            echo "$findings" | jq -r '.[] |
                "- **\(.title)**\(.description | if . != "" then " — " + (.[0:200]) else "" end)\(if .url != "" then " [[source]](\(.url))" else "" end)"'
            ;;

        narrative|*)
            # Group by query context
            echo "## Findings"
            echo ""

            # Get unique query contexts
            local queries
            queries=$(echo "$findings" | jq -r '[.[].query_context] | unique | .[]')

            if [[ -n "$queries" ]]; then
                while IFS= read -r q; do
                    [[ -z "$q" ]] && continue
                    echo "### $q"
                    echo ""
                    echo "$findings" | jq -r --arg q "$q" '
                        [.[] | select(.query_context == $q)] |
                        .[] |
                        "- **\(.title)**\(.description | if . != "" then ": " + (.[0:300]) else "" end)\(if .url != "" then " [[source]](\(.url))" else "" end)"'
                    echo ""
                done <<< "$queries"
            else
                echo "$findings" | jq -r '.[] |
                    "- **\(.title)**\(.description | if . != "" then ": " + (.[0:300]) else "" end)\(if .url != "" then " [[source]](\(.url))" else "" end)"'
            fi
            ;;
    esac

    echo ""
    echo "---"
    echo ""
    echo "## Sources"
    echo ""
    echo "$citations" | jq -r '.[] | "- [\(.title)](\(.url)) (via \(.source))"'
    echo ""
    echo "---"
    echo "*Synthesized by research-ops v2.2.0*"
}

# Generate JSON synthesis
generate_json() {
    local results="$1" title="$2" style="$3"

    local findings citations total_results source_count
    findings=$(extract_findings "$results")
    citations=$(extract_citations "$results")
    total_results=$(count_results "$results")
    source_count=$(count_sources "$results")

    jq -n \
        --arg title "${title:-Research Synthesis}" \
        --arg style "$style" \
        --arg date "$(date +%Y-%m-%d)" \
        --argjson total "$total_results" \
        --argjson sources "$source_count" \
        --argjson finding_count "$(echo "$findings" | jq length)" \
        --argjson findings "$findings" \
        --argjson citations "$citations" \
        '{
            synthesis: {
                title: $title,
                style: $style,
                date: $date,
                stats: {
                    total_results: $total,
                    source_count: $sources,
                    unique_findings: $finding_count,
                    citation_count: ($citations | length)
                },
                findings: $findings,
                citations: $citations
            }
        }'
}

# Main
RESULTS=$(collect_results)

if [[ "$(echo "$RESULTS" | jq length)" == "0" ]]; then
    echo "ERROR: No results found to synthesize" >&2
    exit 1
fi

case "$FORMAT" in
    markdown) generate_markdown "$RESULTS" "$TITLE" "$STYLE" ;;
    json)     generate_json "$RESULTS" "$TITLE" "$STYLE" ;;
    *)        echo "Invalid format: $FORMAT" >&2; exit 1 ;;
esac
