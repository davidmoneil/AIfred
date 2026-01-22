#!/bin/bash
# Script: sync-git.sh
# Purpose: Sync repository to GitHub with automatic commit
# Usage: ./sync-git.sh [commit-message]
# Author: David Moneil
# Created: 2026-01-20
# Pattern: Capability Layering (Code → CLI → Prompt)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${REPO_DIR:-$(pwd)}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Help
show_help() {
    cat << EOF
Usage: $(basename "$0") [options] [commit-message]

Sync a git repository to its remote with automatic commit.

Options:
    -h, --help      Show this help message
    -d, --dir DIR   Repository directory (default: current directory)
    -n, --dry-run   Show what would be done without doing it
    -q, --quiet     Minimal output (just success/fail)

Arguments:
    commit-message  Optional commit message. If not provided, generates one
                    based on changed files.

Examples:
    $(basename "$0")                           # Auto-generate commit message
    $(basename "$0") "Add new feature"         # Use provided message
    $(basename "$0") -d ~/Code/myproject       # Sync specific directory
    $(basename "$0") -n                        # Dry run

Exit Codes:
    0  Success
    1  No git repository found
    2  No changes to commit
    3  Git operation failed
EOF
}

# Logging functions
log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1" >&2; }

# Parse arguments
DRY_RUN=false
QUIET=false
COMMIT_MSG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -d|--dir) REPO_DIR="$2"; shift 2 ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
        -q|--quiet) QUIET=true; shift ;;
        -*) log_error "Unknown option: $1"; show_help; exit 1 ;;
        *) COMMIT_MSG="$1"; shift ;;
    esac
done

# Verify git repository
cd "$REPO_DIR" || { log_error "Cannot access directory: $REPO_DIR"; exit 1; }

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Not a git repository: $REPO_DIR"
    exit 1
fi

# Get repository info
REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
BRANCH=$(git branch --show-current)
REMOTE=$(git remote get-url origin 2>/dev/null || echo "no remote")

[[ "$QUIET" == false ]] && log_info "Repository: $REPO_NAME ($BRANCH)"

# Check for changes
CHANGES=$(git status --porcelain)
if [[ -z "$CHANGES" ]]; then
    if [[ "$QUIET" == false ]]; then
        log_info "No changes to sync"
        echo "Repository is up to date with last commit."
    fi
    exit 2
fi

# Count changes
MODIFIED=$(echo "$CHANGES" | grep -c "^ M\|^M " || true)
ADDED=$(echo "$CHANGES" | grep -c "^A \|^??" || true)
DELETED=$(echo "$CHANGES" | grep -c "^ D\|^D " || true)
TOTAL=$((MODIFIED + ADDED + DELETED))

[[ "$QUIET" == false ]] && log_info "Changes: $MODIFIED modified, $ADDED added, $DELETED deleted ($TOTAL total)"

# Generate commit message if not provided
if [[ -z "$COMMIT_MSG" ]]; then
    # Analyze changes to generate message
    CHANGED_DIRS=$(echo "$CHANGES" | awk '{print $2}' | xargs -I{} dirname {} | sort -u | head -3 | tr '\n' ', ' | sed 's/,$//')

    # Determine category based on changed paths
    if echo "$CHANGES" | grep -q "\.claude/commands/"; then
        CATEGORY="Commands"
    elif echo "$CHANGES" | grep -q "\.claude/skills/"; then
        CATEGORY="Skills"
    elif echo "$CHANGES" | grep -q "\.claude/agents/"; then
        CATEGORY="Agents"
    elif echo "$CHANGES" | grep -q "\.claude/context/"; then
        CATEGORY="Documentation"
    elif echo "$CHANGES" | grep -q "Scripts/"; then
        CATEGORY="Scripts"
    elif echo "$CHANGES" | grep -q "\.claude/hooks/"; then
        CATEGORY="Hooks"
    else
        CATEGORY="Updates"
    fi

    DATE=$(date +%Y-%m-%d)
    COMMIT_MSG="${CATEGORY}: Sync changes

Changed areas: ${CHANGED_DIRS}
Files: ${TOTAL}
Date: ${DATE}"
fi

# Check for potential secrets
if echo "$CHANGES" | xargs -I{} git diff --cached -- {} 2>/dev/null | grep -qiE "password|secret|api_key|token|credential"; then
    log_warning "Potential secrets detected in changes!"
    log_warning "Review carefully before pushing."
fi

# Dry run output
if [[ "$DRY_RUN" == true ]]; then
    echo ""
    echo "=== DRY RUN ==="
    echo "Would execute:"
    echo "  git add ."
    echo "  git commit -m \"$COMMIT_MSG\""
    echo "  git push origin $BRANCH"
    echo ""
    echo "Changes to be committed:"
    echo "$CHANGES"
    exit 0
fi

# Stage all changes
git add . || { log_error "Failed to stage changes"; exit 3; }
[[ "$QUIET" == false ]] && log_success "Staged all changes"

# Commit
git commit -m "$COMMIT_MSG" || { log_error "Failed to commit"; exit 3; }
COMMIT_HASH=$(git rev-parse --short HEAD)
[[ "$QUIET" == false ]] && log_success "Committed: $COMMIT_HASH"

# Push
if [[ "$REMOTE" != "no remote" ]]; then
    if git push origin "$BRANCH" 2>&1; then
        [[ "$QUIET" == false ]] && log_success "Pushed to origin/$BRANCH"
    else
        # Try with upstream set
        if git push -u origin "$BRANCH" 2>&1; then
            [[ "$QUIET" == false ]] && log_success "Pushed to origin/$BRANCH (upstream set)"
        else
            log_error "Failed to push. You may need to pull first."
            log_info "Try: git pull --rebase origin $BRANCH"
            exit 3
        fi
    fi
else
    log_warning "No remote configured, skipping push"
fi

# Summary
if [[ "$QUIET" == false ]]; then
    echo ""
    echo "═══════════════════════════════════════"
    echo -e "${GREEN}✓ Successfully synced to GitHub${NC}"
    echo "═══════════════════════════════════════"
    echo "  Commit:  $COMMIT_HASH"
    echo "  Branch:  $BRANCH"
    echo "  Files:   $TOTAL changed"
    echo "  Remote:  $REMOTE"
    echo "═══════════════════════════════════════"
fi

# Output for script consumption (JSON-like)
if [[ "$QUIET" == true ]]; then
    echo "{\"status\":\"success\",\"commit\":\"$COMMIT_HASH\",\"files\":$TOTAL,\"branch\":\"$BRANCH\"}"
fi

exit 0
