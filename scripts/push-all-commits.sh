#!/bin/bash
# Script: push-all-commits.sh
# Purpose: Push all unpushed commits across tracked projects
# Usage: ./push-all-commits.sh [options]
# Author: David Moneil
# Created: 2026-01-20
# Pattern: Capability Layering (Code → CLI → Prompt)

set -uo pipefail

# Configuration
CODE_DIR="${HOME}/Code"
AIPROJECTS_DIR="${HOME}/AIProjects"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Help
show_help() {
    cat << EOF
Usage: $(basename "$0") [options]

Push all unpushed commits across tracked projects.

Options:
    -n, --dry-run     Show what would be pushed without pushing
    -q, --quiet       Minimal output
    -j, --json        JSON output
    -h, --help        Show this help

Projects Checked:
    - AIProjects (${AIPROJECTS_DIR})
    - All projects in ~/Code/

Examples:
    $(basename "$0")              # Push all unpushed commits
    $(basename "$0") --dry-run    # Preview what would be pushed
    $(basename "$0") --json       # JSON output for automation

Exit Codes:
    0  All pushes successful (or nothing to push)
    1  Some pushes failed
EOF
}

# Logging
log_info() { [[ "$QUIET" == false ]] && echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { [[ "$QUIET" == false ]] && echo -e "${GREEN}✓${NC} $1"; }
log_warning() { [[ "$QUIET" == false ]] && echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { [[ "$QUIET" == false ]] && echo -e "${RED}✗${NC} $1"; }

# Parse arguments
DRY_RUN=false
QUIET=false
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
        -q|--quiet) QUIET=true; shift ;;
        -j|--json) JSON_OUTPUT=true; QUIET=true; shift ;;
        -*) log_error "Unknown option: $1"; show_help; exit 1 ;;
        *) shift ;;
    esac
done

# Collect projects
PROJECTS=()

# Add AIProjects
if [[ -d "$AIPROJECTS_DIR/.git" ]]; then
    PROJECTS+=("$AIPROJECTS_DIR")
fi

# Add Code projects
if [[ -d "$CODE_DIR" ]]; then
    for dir in "$CODE_DIR"/*/; do
        if [[ -d "${dir}.git" ]]; then
            PROJECTS+=("${dir%/}")
        fi
    done
fi

# Track results
PUSHED=0
SKIPPED=0
FAILED=0
RESULTS=()

# Header
if [[ "$QUIET" == false ]] && [[ "$JSON_OUTPUT" == false ]]; then
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}           PUSH ALL UNPUSHED COMMITS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo ""
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}DRY RUN - No changes will be made${NC}"
        echo ""
    fi
fi

# Process each project
for project in "${PROJECTS[@]}"; do
    name=$(basename "$project")
    cd "$project" || continue

    # Check if remote exists
    if ! git remote get-url origin &>/dev/null; then
        log_info "$name: No remote configured, skipping"
        ((SKIPPED++))
        RESULTS+=("{\"project\":\"$name\",\"status\":\"no_remote\",\"commits\":0}")
        continue
    fi

    # Get current branch
    branch=$(git branch --show-current 2>/dev/null)
    if [[ -z "$branch" ]]; then
        log_warning "$name: Not on a branch, skipping"
        ((SKIPPED++))
        RESULTS+=("{\"project\":\"$name\",\"status\":\"detached\",\"commits\":0}")
        continue
    fi

    # Check for unpushed commits
    # Fetch to ensure we have latest remote info (quiet)
    git fetch origin "$branch" --quiet 2>/dev/null || true

    # Count unpushed commits
    unpushed=$(git rev-list --count "origin/$branch..$branch" 2>/dev/null || echo "0")

    if [[ "$unpushed" == "0" ]]; then
        [[ "$QUIET" == false ]] && [[ "$JSON_OUTPUT" == false ]] && echo -e "  ${GREEN}✓${NC} $name: Up to date"
        ((SKIPPED++))
        RESULTS+=("{\"project\":\"$name\",\"status\":\"up_to_date\",\"commits\":0}")
        continue
    fi

    # Has unpushed commits
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${YELLOW}→${NC} $name: Would push $unpushed commit(s) to $branch"
        RESULTS+=("{\"project\":\"$name\",\"status\":\"would_push\",\"commits\":$unpushed}")
        ((PUSHED++))
    else
        # Actually push
        if git push origin "$branch" 2>/dev/null; then
            log_success "$name: Pushed $unpushed commit(s) to $branch"
            RESULTS+=("{\"project\":\"$name\",\"status\":\"pushed\",\"commits\":$unpushed}")
            ((PUSHED++))
        else
            log_error "$name: Push failed"
            RESULTS+=("{\"project\":\"$name\",\"status\":\"failed\",\"commits\":$unpushed}")
            ((FAILED++))
        fi
    fi
done

# JSON output
if [[ "$JSON_OUTPUT" == true ]]; then
    echo "{"
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"dry_run\": $DRY_RUN,"
    echo "  \"summary\": {"
    echo "    \"total\": ${#PROJECTS[@]},"
    echo "    \"pushed\": $PUSHED,"
    echo "    \"skipped\": $SKIPPED,"
    echo "    \"failed\": $FAILED"
    echo "  },"
    echo "  \"projects\": ["
    for i in "${!RESULTS[@]}"; do
        if [[ $i -lt $((${#RESULTS[@]} - 1)) ]]; then
            echo "    ${RESULTS[$i]},"
        else
            echo "    ${RESULTS[$i]}"
        fi
    done
    echo "  ]"
    echo "}"
    exit $([[ $FAILED -gt 0 ]] && echo 1 || echo 0)
fi

# Summary
if [[ "$QUIET" == false ]]; then
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "                    ${CYAN}SUMMARY${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo "  Total projects:  ${#PROJECTS[@]}"
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${YELLOW}Would push:${NC}      $PUSHED"
    else
        echo -e "  ${GREEN}Pushed:${NC}          $PUSHED"
    fi
    echo "  Skipped:         $SKIPPED"
    if [[ $FAILED -gt 0 ]]; then
        echo -e "  ${RED}Failed:${NC}          $FAILED"
    fi
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo ""
fi

# Exit code
if [[ $FAILED -gt 0 ]]; then
    exit 1
fi

exit 0
