#!/bin/bash
# Script: register-project.sh
# Purpose: Register an existing project with AIProjects
# Usage: ./register-project.sh <path-or-github-url>
# Author: David Moneil
# Created: 2026-01-20
# Pattern: Capability Layering (Code → CLI → Prompt)

set -euo pipefail

# Configuration
CODE_DIR="${HOME}/Code"
AIPROJECTS_DIR="${HOME}/AIProjects"
REGISTRY_FILE="${AIPROJECTS_DIR}/paths-registry.yaml"
CONTEXT_DIR="${AIPROJECTS_DIR}/.claude/context/projects"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Help
show_help() {
    cat << EOF
Usage: $(basename "$0") <path-or-github-url>

Register an existing project with AIProjects.

Arguments:
    path-or-url    Local path or GitHub URL
                   - ~/Code/my-project
                   - /home/user/Code/project
                   - github.com/user/repo
                   - https://github.com/user/repo

Options:
    -h, --help     Show this help

What It Does:
    Local: Validates path, detects type/lang, creates registry entry
    GitHub: Clones to ~/Code, detects type/lang, creates registry entry

Examples:
    $(basename "$0") ~/Code/existing-project
    $(basename "$0") github.com/your-username/some-repo
    $(basename "$0") https://github.com/user/repo

Exit Codes:
    0  Success
    1  Invalid arguments
    2  Project already registered
    3  Clone/access failed
EOF
}

# Logging
log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1" >&2; }

# Detect language from project files
detect_language() {
    local path="$1"

    if [[ -f "$path/package.json" ]]; then
        if [[ -f "$path/tsconfig.json" ]]; then
            echo "typescript"
        else
            echo "javascript"
        fi
    elif [[ -f "$path/requirements.txt" ]] || [[ -f "$path/pyproject.toml" ]] || [[ -f "$path/setup.py" ]]; then
        echo "python"
    elif [[ -f "$path/go.mod" ]]; then
        echo "go"
    elif [[ -f "$path/Cargo.toml" ]]; then
        echo "rust"
    elif ls "$path"/*.csproj 2>/dev/null | head -1 > /dev/null; then
        echo "csharp"
    elif [[ -f "$path/Gemfile" ]]; then
        echo "ruby"
    else
        echo "unknown"
    fi
}

# Detect project type from structure
detect_type() {
    local path="$1"

    if [[ -f "$path/docker-compose.yml" ]] || [[ -f "$path/docker-compose.yaml" ]]; then
        echo "docker"
    elif [[ -f "$path/next.config.js" ]] || [[ -f "$path/next.config.mjs" ]] || [[ -f "$path/vite.config.ts" ]] || [[ -f "$path/vite.config.js" ]]; then
        echo "web-app"
    elif [[ -f "$path/setup.py" ]] || [[ -f "$path/pyproject.toml" ]]; then
        echo "library"
    elif [[ -d "$path/bin" ]] || grep -q '"bin"' "$path/package.json" 2>/dev/null; then
        echo "cli"
    elif [[ -d "$path/src" ]] && [[ -d "$path/tests" ]]; then
        echo "api"
    else
        echo "other"
    fi
}

# Extract repo name from GitHub URL
parse_github_url() {
    local url="$1"
    # Handle various GitHub URL formats
    echo "$url" | sed -E 's|^(https?://)?github\.com/||' | sed -E 's|\.git$||' | cut -d'/' -f2
}

# Check if GitHub URL
is_github_url() {
    [[ "$1" =~ github\.com ]]
}

# Parse argument
if [[ $# -lt 1 ]]; then
    log_error "Argument required"
    show_help
    exit 1
fi

case "$1" in
    -h|--help) show_help; exit 0 ;;
esac

INPUT="$1"
DATE=$(date +%Y-%m-%d)
GITHUB_URL=""

# Determine if local path or GitHub URL
if is_github_url "$INPUT"; then
    # GitHub URL - need to clone
    REPO_NAME=$(parse_github_url "$INPUT")
    PROJECT_PATH="${CODE_DIR}/${REPO_NAME}"
    GITHUB_URL="github.com/$(echo "$INPUT" | sed -E 's|^(https?://)?github\.com/||' | sed 's|\.git$||')"

    log_info "GitHub repository: $GITHUB_URL"

    if [[ -d "$PROJECT_PATH" ]]; then
        log_warning "Directory already exists: $PROJECT_PATH"
        log_info "Using existing directory"
    else
        log_info "Cloning to $PROJECT_PATH..."
        if git clone "https://${GITHUB_URL}.git" "$PROJECT_PATH" 2>/dev/null; then
            log_success "Cloned successfully"
        else
            log_error "Failed to clone repository"
            exit 3
        fi
    fi
else
    # Local path
    # Expand ~ if present
    PROJECT_PATH="${INPUT/#\~/$HOME}"

    if [[ ! -d "$PROJECT_PATH" ]]; then
        log_error "Directory not found: $PROJECT_PATH"
        exit 3
    fi

    # Get absolute path
    PROJECT_PATH=$(cd "$PROJECT_PATH" && pwd)
fi

# Get project name from path
NAME=$(basename "$PROJECT_PATH")
log_info "Registering project: $NAME"

# Check if already registered
if grep -q "^  ${NAME}:" "$REGISTRY_FILE" 2>/dev/null; then
    log_warning "Project already in paths-registry.yaml"
    log_info "Updating context file only..."
fi

# Detect language and type
LANG=$(detect_language "$PROJECT_PATH")
TYPE=$(detect_type "$PROJECT_PATH")

log_info "Detected language: $LANG"
log_info "Detected type: $TYPE"

# Get description from README if available
DESCRIPTION=""
if [[ -f "$PROJECT_PATH/README.md" ]]; then
    # Get first non-empty, non-heading line as description
    DESCRIPTION=$(grep -v "^#" "$PROJECT_PATH/README.md" | grep -v "^$" | head -1 | cut -c1-100)
fi

# Create context file
mkdir -p "$CONTEXT_DIR"
CONTEXT_FILE="${CONTEXT_DIR}/${NAME}.md"

cat > "$CONTEXT_FILE" << CONTEXT
# ${NAME}

**Path**: ${PROJECT_PATH}
**Type**: ${TYPE}
**Language**: ${LANG}
**Status**: active
**Registered**: ${DATE}
$(if [[ -n "$GITHUB_URL" ]]; then echo "**GitHub**: https://${GITHUB_URL}"; fi)

## Overview

${DESCRIPTION:-[To be documented]}

## Key Decisions

| Date | Decision | Rationale |
|------|----------|-----------|

## Current State

**Last worked on**: ${DATE}
**Current focus**: Recently registered

## Links

- Code: \`${PROJECT_PATH}\`
$(if [[ -n "$GITHUB_URL" ]]; then echo "- GitHub: https://${GITHUB_URL}"; fi)
- Context: \`.claude/context/projects/${NAME}.md\`
CONTEXT

log_success "Created context file: ${CONTEXT_FILE}"

# Prepare registry entry (output for manual addition)
echo ""
echo "═══════════════════════════════════════════════════"
echo -e "${YELLOW}Add to paths-registry.yaml under coding.projects:${NC}"
echo "═══════════════════════════════════════════════════"
echo ""
echo "  ${NAME}:"
echo "    path: ${PROJECT_PATH}"
echo "    type: ${TYPE}"
echo "    language: ${LANG}"
if [[ -n "$GITHUB_URL" ]]; then
echo "    github: ${GITHUB_URL}"
fi
echo "    status: active"
echo "    registered: ${DATE}"
echo ""
echo "═══════════════════════════════════════════════════"

# Summary
echo ""
echo -e "${GREEN}✓ Project registered: ${NAME}${NC}"
echo ""
echo "  📁 Path:     ${PROJECT_PATH}"
echo "  📋 Type:     ${TYPE}"
echo "  🔧 Language: ${LANG}"
echo "  📝 Context:  .claude/context/projects/${NAME}.md"
if [[ -n "$GITHUB_URL" ]]; then
echo "  🐙 GitHub:   https://${GITHUB_URL}"
fi
echo ""

exit 0
