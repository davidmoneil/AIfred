#!/bin/bash
# fabric-review-code.sh - AI-powered code review
# Part of CLI capability layer
#
# Provides quick code review feedback using fabric's review_code pattern.
# Identifies issues, suggests improvements, and prioritizes recommendations.
#
# Usage:
#   fabric-review-code.sh <file>              # Review a file
#   fabric-review-code.sh --staged            # Review staged changes
#   cat src/main.ts | fabric-review-code.sh --stdin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER="${SCRIPT_DIR}/fabric-wrapper.sh"

show_help() {
    cat << 'EOF'
Usage: fabric-review-code.sh [file|--staged|--stdin] [options]

AI-powered code review with prioritized recommendations.

Arguments:
  <file>          File to review

Options:
  --staged        Review staged git changes
  --stdin         Read code from stdin
  --diff          Review as diff (shows what changed)
  --model <m>     Force model (7b recommended for speed)
  --output <file> Save review to file
  --quiet         Suppress status messages
  --help          Show this help

Examples:
  fabric-review-code.sh src/server.ts         # Single file
  fabric-review-code.sh --staged              # Staged changes
  git diff HEAD~1 | fabric-review-code.sh --stdin --diff
  fabric-review-code.sh src/*.ts              # Multiple files (sequentially)

Output Sections:
  - Overall Assessment
  - Prioritized Recommendations
  - Detailed Feedback (per issue)
EOF
    exit 0
}

main() {
    local files=()
    local use_stdin=false
    local use_staged=false
    local is_diff=false
    local model_arg="--model-only 7b"  # Default to fast model
    local output_file=""
    local quiet=""
    local code_content=""

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h) show_help ;;
            --stdin) use_stdin=true; shift ;;
            --staged) use_staged=true; shift ;;
            --diff) is_diff=true; shift ;;
            --model) model_arg="--model-only $2"; shift 2 ;;
            --output) output_file="$2"; shift 2 ;;
            --quiet|-q) quiet="--quiet"; shift ;;
            -*)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
            *)
                files+=("$1")
                shift
                ;;
        esac
    done

    # Get code content
    if $use_stdin; then
        code_content=$(cat)
        [ -z "$code_content" ] && { echo "No input from stdin" >&2; exit 1; }

    elif $use_staged; then
        code_content=$(git diff --staged 2>/dev/null)
        [ -z "$code_content" ] && { echo "No staged changes" >&2; exit 1; }
        is_diff=true

    elif [ ${#files[@]} -gt 0 ]; then
        # Review each file
        for file in "${files[@]}"; do
            [ ! -f "$file" ] && { echo "File not found: $file" >&2; continue; }

            echo "=== Reviewing: $file ===" >&2
            local file_content
            file_content=$(cat "$file")

            # Add filename context
            code_content="// File: $file"$'\n'"$file_content"

            local result
            result=$(echo "$code_content" | "$WRAPPER" review_code $quiet $model_arg)

            if [ -n "$output_file" ]; then
                echo -e "\n=== $file ===\n$result" >> "$output_file"
            else
                echo "$result"
            fi

            # Add separator between files
            [ ${#files[@]} -gt 1 ] && echo -e "\n---\n"
        done
        exit 0

    else
        echo "Error: Specify a file, --staged, or --stdin" >&2
        echo "Use --help for usage information" >&2
        exit 1
    fi

    # Single content review (stdin or staged)
    local result
    result=$(echo "$code_content" | "$WRAPPER" review_code $quiet $model_arg)

    if [ -n "$output_file" ]; then
        echo "$result" > "$output_file"
        echo "Review saved to: $output_file" >&2
    else
        echo "$result"
    fi
}

main "$@"
