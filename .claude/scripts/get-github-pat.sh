#!/bin/bash
#
# get-github-pat.sh - Retrieve GitHub PAT with file-based priority
#
# Priority Order:
#   1. Environment variable (GITHUB_PAT)
#   2. File-based credentials (.claude/secrets/credentials.yaml)
#   3. macOS Keychain fallback (osxkeychain)
#
# Usage:
#   source get-github-pat.sh   # Sets GH_PAT variable
#   ./get-github-pat.sh        # Outputs PAT to stdout
#
# Created: 2026-01-20
# Reference: .claude/context/patterns/multi-repo-credential-pattern.md
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
CREDENTIALS_FILE="$PROJECT_ROOT/.claude/secrets/credentials.yaml"
KEYCHAIN_ACCOUNT="${GITHUB_USER:-CannonCoPilot}"

# Function to get PAT from file
get_pat_from_file() {
    if [[ -f "$CREDENTIALS_FILE" ]]; then
        # Try yq first (preferred)
        if command -v yq &> /dev/null; then
            local pat=$(yq -r '.github.pat // .github.cannoncopilot_pat // .github.aifred_pat // empty' "$CREDENTIALS_FILE" 2>/dev/null)
            if [[ -n "$pat" && "$pat" != "null" ]]; then
                echo "$pat"
                return 0
            fi
        fi

        # Fallback to grep/sed for simple YAML
        local pat=$(grep -E '^\s*(pat|cannoncopilot_pat|aifred_pat):' "$CREDENTIALS_FILE" 2>/dev/null | head -1 | sed 's/.*: *//' | tr -d '"' | tr -d "'")
        if [[ -n "$pat" ]]; then
            echo "$pat"
            return 0
        fi
    fi
    return 1
}

# Function to get PAT from macOS Keychain
get_pat_from_keychain() {
    if [[ "$(uname)" == "Darwin" ]]; then
        local pat=$(security find-internet-password -s github.com -a "$KEYCHAIN_ACCOUNT" -w 2>/dev/null)
        if [[ -n "$pat" ]]; then
            echo "$pat"
            return 0
        fi
    fi
    return 1
}

# Main logic
get_github_pat() {
    local pat=""
    local source=""

    # Priority 1: Environment variable
    if [[ -n "${GITHUB_PAT:-}" ]]; then
        pat="$GITHUB_PAT"
        source="environment"
    fi

    # Priority 2: File-based credentials
    if [[ -z "$pat" ]]; then
        pat=$(get_pat_from_file) && source="file" || true
    fi

    # Priority 3: macOS Keychain
    if [[ -z "$pat" ]]; then
        pat=$(get_pat_from_keychain) && source="keychain" || true
    fi

    # Output result
    if [[ -n "$pat" ]]; then
        # If sourced, set variable; if run, output
        if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
            export GH_PAT="$pat"
            export GH_PAT_SOURCE="$source"
        else
            echo "$pat"
        fi
        return 0
    else
        echo "ERROR: No GitHub PAT found in environment, file, or keychain" >&2
        return 1
    fi
}

# Validation function (optional - checks PAT works)
validate_pat() {
    local pat="$1"
    local response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token $pat" \
        https://api.github.com/user 2>/dev/null)

    if [[ "$response" == "200" ]]; then
        return 0
    else
        return 1
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Parse arguments
    case "${1:-}" in
        --validate)
            pat=$(get_github_pat)
            if validate_pat "$pat"; then
                echo "PAT is valid"
                exit 0
            else
                echo "PAT validation failed" >&2
                exit 1
            fi
            ;;
        --source)
            # Show which source would be used
            if [[ -n "${GITHUB_PAT:-}" ]]; then
                echo "environment"
            elif get_pat_from_file > /dev/null 2>&1; then
                echo "file"
            elif get_pat_from_keychain > /dev/null 2>&1; then
                echo "keychain"
            else
                echo "none"
            fi
            ;;
        --help)
            echo "Usage: get-github-pat.sh [--validate|--source|--help]"
            echo ""
            echo "Options:"
            echo "  --validate  Check if PAT is valid with GitHub API"
            echo "  --source    Show which credential source would be used"
            echo "  --help      Show this help"
            echo ""
            echo "Priority: GITHUB_PAT env > credentials.yaml > osxkeychain"
            ;;
        *)
            get_github_pat
            ;;
    esac
fi
