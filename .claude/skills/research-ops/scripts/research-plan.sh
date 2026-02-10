#!/usr/bin/env bash
# Research Plan — query decomposition, question type detection, backend selection
# Usage: ./research-plan.sh "complex query" [--depth quick|standard|thorough] [--output json|text]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

show_help() {
    cat <<'HELP'
Usage: research-plan.sh QUERY [OPTIONS]

Decomposes a complex research query into sub-questions and maps each
to optimal backend(s) from the research-ops toolkit.

Options:
  --depth LEVEL    Decomposition depth: quick (1-2 subs), standard (3-5), thorough (5-8)
  --output FORMAT  Output format: json (default), text
  --help           Show this help

Examples:
  research-plan.sh "How does JICM compare to other context management approaches?"
  research-plan.sh "What are the best MCP servers for code analysis?" --depth thorough
  research-plan.sh "Latest advances in prompt engineering" --output text
HELP
}

# Parse arguments
QUERY="" DEPTH="standard" OUTPUT="json"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --depth) DEPTH="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --help) show_help; exit 0 ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) QUERY="$1"; shift ;;
    esac
done

if [[ -z "$QUERY" ]]; then
    show_help
    exit 1
fi

require_commands jq || exit 1

# Detect question type from query keywords
detect_question_type() {
    local q
    q=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    if echo "$q" | grep -qE '(compare|vs|versus|difference|better|worse|tradeoff)'; then
        echo "comparison"
    elif echo "$q" | grep -qE '(trend|latest|recent|new|emerging|2025|2026|state of)'; then
        echo "trend"
    elif echo "$q" | grep -qE '(how to|implement|build|create|setup|configure|tutorial)'; then
        echo "technical"
    elif echo "$q" | grep -qE '(what is|define|explain|overview|introduction)'; then
        echo "factual"
    elif echo "$q" | grep -qE '(best|recommend|should|opinion|review)'; then
        echo "evaluative"
    elif echo "$q" | grep -qE '(paper|research|study|academic|arxiv|pubmed)'; then
        echo "academic"
    elif echo "$q" | grep -qE '(price|stock|market|financial|revenue|valuation)'; then
        echo "financial"
    else
        echo "general"
    fi
}

# Map question type to recommended backends
map_backends() {
    local qtype="$1"
    case "$qtype" in
        comparison)  echo '["WebSearch","search-brave.sh","search-perplexity.sh"]' ;;
        trend)       echo '["WebSearch","search-brave.sh --freshness week","search-perplexity.sh"]' ;;
        technical)   echo '["WebSearch","search-perplexity.sh","fetch-context7.sh","search-arxiv.sh"]' ;;
        factual)     echo '["fetch-wikipedia.sh","WebSearch"]' ;;
        evaluative)  echo '["WebSearch","search-brave.sh","search-perplexity.sh"]' ;;
        academic)    echo '["search-arxiv.sh","search-perplexity.sh --model sonar-pro","WebSearch"]' ;;
        financial)   echo '["WebSearch","search-brave.sh --type news"]' ;;
        *)           echo '["WebSearch","search-brave.sh"]' ;;
    esac
}

# Determine sub-question count from depth
case "$DEPTH" in
    quick)    MAX_SUBS=2 ;;
    standard) MAX_SUBS=5 ;;
    thorough) MAX_SUBS=8 ;;
    *) echo "Invalid depth: $DEPTH" >&2; exit 1 ;;
esac

QUESTION_TYPE=$(detect_question_type "$QUERY")
BACKENDS=$(map_backends "$QUESTION_TYPE")

# Generate sub-questions based on question type
# These are heuristic decompositions — the calling agent refines them
generate_sub_questions() {
    local qtype="$1" query="$2" max="$3"
    local subs='[]'

    # Always include the core question
    subs=$(echo "$subs" | jq --arg q "$query" --arg b "$(map_backends "$qtype")" \
        '. + [{"question": $q, "type": "core", "backends": ($b | fromjson)}]')

    if [[ "$max" -ge 2 ]]; then
        # Add a definition/background sub-question
        subs=$(echo "$subs" | jq --arg q "Background and definitions for: $query" \
            '. + [{"question": $q, "type": "background", "backends": ["fetch-wikipedia.sh","WebSearch"]}]')
    fi

    if [[ "$max" -ge 3 && ("$qtype" == "comparison" || "$qtype" == "evaluative") ]]; then
        subs=$(echo "$subs" | jq --arg q "Alternatives and competing approaches for: $query" \
            '. + [{"question": $q, "type": "alternatives", "backends": ["WebSearch","search-brave.sh"]}]')
    fi

    if [[ "$max" -ge 4 && ("$qtype" == "technical" || "$qtype" == "academic") ]]; then
        subs=$(echo "$subs" | jq --arg q "Academic papers and research on: $query" \
            '. + [{"question": $q, "type": "academic", "backends": ["search-arxiv.sh","search-perplexity.sh --model sonar-pro"]}]')
    fi

    if [[ "$max" -ge 5 ]]; then
        subs=$(echo "$subs" | jq --arg q "Recent developments and current state of: $query" \
            '. + [{"question": $q, "type": "recent", "backends": ["search-brave.sh --freshness month","WebSearch"]}]')
    fi

    if [[ "$max" -ge 6 ]]; then
        subs=$(echo "$subs" | jq --arg q "Practical examples and implementations of: $query" \
            '. + [{"question": $q, "type": "practical", "backends": ["WebSearch","fetch-context7.sh"]}]')
    fi

    if [[ "$max" -ge 7 ]]; then
        subs=$(echo "$subs" | jq --arg q "Criticisms and limitations of: $query" \
            '. + [{"question": $q, "type": "critical", "backends": ["WebSearch","search-perplexity.sh"]}]')
    fi

    if [[ "$max" -ge 8 ]]; then
        subs=$(echo "$subs" | jq --arg q "Future outlook and predictions for: $query" \
            '. + [{"question": $q, "type": "forecast", "backends": ["search-perplexity.sh --model sonar-reasoning","WebSearch"]}]')
    fi

    echo "$subs"
}

SUB_QUESTIONS=$(generate_sub_questions "$QUESTION_TYPE" "$QUERY" "$MAX_SUBS")

# Build the plan
PLAN=$(jq -n \
    --arg query "$QUERY" \
    --arg qtype "$QUESTION_TYPE" \
    --arg depth "$DEPTH" \
    --argjson max_subs "$MAX_SUBS" \
    --argjson primary_backends "$BACKENDS" \
    --argjson sub_questions "$SUB_QUESTIONS" \
    '{
        plan: {
            query: $query,
            question_type: $qtype,
            depth: $depth,
            sub_question_count: ($sub_questions | length),
            max_sub_questions: $max_subs,
            primary_backends: $primary_backends,
            sub_questions: $sub_questions,
            execution_order: "parallel where possible, sequential for dependent questions",
            synthesis_strategy: (
                if $qtype == "comparison" then "side-by-side matrix"
                elif $qtype == "academic" then "literature review format"
                elif $qtype == "trend" then "timeline narrative"
                elif $qtype == "technical" then "tutorial with code examples"
                else "structured narrative with citations"
                end
            )
        }
    }')

# Output
if [[ "$OUTPUT" == "text" ]]; then
    echo "Research Plan: $QUERY"
    echo "Type: $QUESTION_TYPE | Depth: $DEPTH | Sub-questions: $(echo "$SUB_QUESTIONS" | jq length)"
    echo "---"
    echo "$SUB_QUESTIONS" | jq -r '.[] | "[\(.type)] \(.question)\n  Backends: \(.backends | join(", "))\n"'
    echo "Synthesis: $(echo "$PLAN" | jq -r '.plan.synthesis_strategy')"
else
    echo "$PLAN" | jq '.'
fi
