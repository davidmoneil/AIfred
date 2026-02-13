#!/bin/bash
# fabric-commit-msg.sh - Generate conventional commit messages from git diffs
# Part of CLI capability layer
#
# Uses fabric's summarize_git_diff pattern to create clean commit messages
# from staged changes or provided diff content.
#
# Usage:
#   fabric-commit-msg.sh              # From staged changes
#   fabric-commit-msg.sh --all        # From all changes (staged + unstaged)
#   git diff HEAD~1 | fabric-commit-msg.sh --stdin
#
# Output: Conventional commit message ready for use
#
# Integration:
#   - Can be used with git commit: git commit -m "$(fabric-commit-msg.sh)"
#   - Or interactively to review before committing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER="${SCRIPT_DIR}/fabric-wrapper.sh"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_help() {
    cat << 'EOF'
Usage: fabric-commit-msg.sh [options]

Generate conventional commit messages using AI analysis of git diffs.

Options:
  --staged      Use staged changes only (default)
  --all         Use all changes (staged + unstaged)
  --stdin       Read diff from stdin instead of git
  --model <m>   Force specific model (32b or 7b)
  --copy        Copy result to clipboard
  --help        Show this help

Examples:
  fabric-commit-msg.sh                    # Staged changes
  fabric-commit-msg.sh --all              # All changes
  git diff HEAD~3 | fabric-commit-msg.sh --stdin  # Custom diff
  git commit -m "$(fabric-commit-msg.sh)" # Direct use

Output Format:
  <type>: <description>

  ### CHANGES
  - change 1
  - change 2
EOF
    exit 0
}

main() {
    local source="staged"
    local model_arg=""
    local copy=false
    local diff_content=""

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h) show_help ;;
            --staged) source="staged"; shift ;;
            --all) source="all"; shift ;;
            --stdin) source="stdin"; shift ;;
            --model) model_arg="--model-only $2"; shift 2 ;;
            --copy) copy=true; shift ;;
            *) echo "Unknown option: $1" >&2; exit 1 ;;
        esac
    done

    # Get diff content
    case "$source" in
        staged)
            diff_content=$(git diff --staged 2>/dev/null)
            if [ -z "$diff_content" ]; then
                echo -e "${YELLOW}No staged changes found.${NC}" >&2
                echo "Stage changes with 'git add' first, or use --all for all changes." >&2
                exit 1
            fi
            ;;
        all)
            diff_content=$(git diff HEAD 2>/dev/null)
            if [ -z "$diff_content" ]; then
                echo -e "${YELLOW}No changes found.${NC}" >&2
                exit 1
            fi
            ;;
        stdin)
            diff_content=$(cat)
            if [ -z "$diff_content" ]; then
                echo "No input received from stdin." >&2
                exit 1
            fi
            ;;
    esac

    # Generate commit message
    # Use 7b model by default for speed (commit messages don't need deep analysis)
    local result
    result=$(echo "$diff_content" | "$WRAPPER" summarize_git_diff --model-only 7b --quiet $model_arg)

    # Output result
    echo "$result"

    # Copy to clipboard if requested
    if $copy; then
        if command -v xclip &>/dev/null; then
            echo "$result" | xclip -selection clipboard
            echo -e "${GREEN}Copied to clipboard${NC}" >&2
        elif command -v pbcopy &>/dev/null; then
            echo "$result" | pbcopy
            echo -e "${GREEN}Copied to clipboard${NC}" >&2
        fi
    fi
}

main "$@"
