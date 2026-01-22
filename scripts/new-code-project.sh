#!/bin/bash
# Script: new-code-project.sh
# Purpose: Create a new code project in ~/Code and register with AIProjects
# Usage: ./new-code-project.sh <name> [--type TYPE] [--lang LANG] [--github]
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
Usage: $(basename "$0") <name> [options]

Create a new code project in ~/Code and register with AIProjects.

Arguments:
    name              Project name (will be normalized to lowercase-with-dashes)

Options:
    -t, --type TYPE   Project type: web-app, api, cli, library, docker, other (default: other)
    -l, --lang LANG   Language: typescript, python, go, rust, etc.
    -g, --github      Create GitHub repository (private)
    -h, --help        Show this help message

Examples:
    $(basename "$0") my-api --type api --lang python
    $(basename "$0") frontend-app --type web-app --lang typescript --github
    $(basename "$0") my-tool --type cli

Exit Codes:
    0  Success
    1  Invalid arguments
    2  Project already exists
    3  Operation failed
EOF
}

# Logging
log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1" >&2; }

# Normalize name to lowercase-with-dashes
normalize_name() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' _' '-' | sed 's/[^a-z0-9-]//g'
}

# Parse arguments
NAME=""
TYPE="other"
LANG=""
GITHUB=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -t|--type) TYPE="$2"; shift 2 ;;
        -l|--lang) LANG="$2"; shift 2 ;;
        -g|--github) GITHUB=true; shift ;;
        -*) log_error "Unknown option: $1"; show_help; exit 1 ;;
        *)
            if [[ -z "$NAME" ]]; then
                NAME="$1"
            else
                log_error "Unexpected argument: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate name
if [[ -z "$NAME" ]]; then
    log_error "Project name required"
    show_help
    exit 1
fi

NAME=$(normalize_name "$NAME")
PROJECT_PATH="${CODE_DIR}/${NAME}"
DATE=$(date +%Y-%m-%d)

log_info "Creating project: $NAME"

# Check if exists
if [[ -d "$PROJECT_PATH" ]]; then
    log_error "Project already exists: $PROJECT_PATH"
    exit 2
fi

# Check if in registry
if grep -q "^  ${NAME}:" "$REGISTRY_FILE" 2>/dev/null; then
    log_error "Project already registered in paths-registry.yaml"
    exit 2
fi

# Create project directory
mkdir -p "$PROJECT_PATH"
cd "$PROJECT_PATH"
log_success "Created: $PROJECT_PATH"

# Initialize git
git init --quiet
log_success "Initialized git repository"

# Create base structure
mkdir -p .claude

# Create .gitignore based on language
cat > .gitignore << 'GITIGNORE'
# Dependencies
node_modules/
__pycache__/
*.pyc
.venv/
venv/
vendor/
target/

# Build
dist/
build/
*.egg-info/

# IDE
.idea/
.vscode/
*.swp
*.swo

# Environment
.env
.env.local
*.local

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Testing
coverage/
.coverage
htmlcov/
GITIGNORE

log_success "Created .gitignore"

# Create README.md
cat > README.md << README
# ${NAME}

**Type**: ${TYPE}
**Language**: ${LANG:-Not specified}
**Created**: ${DATE}

## Overview

[Project description]

## Setup

\`\`\`bash
# Setup commands
\`\`\`

## Usage

\`\`\`bash
# Usage commands
\`\`\`

## Development

[Development notes]

---

*Managed via [AIProjects](${AIPROJECTS_DIR})*
README

log_success "Created README.md"

# Create .claude/CLAUDE.md
cat > .claude/CLAUDE.md << CLAUDE
# ${NAME}

**Type**: ${TYPE}
**Language**: ${LANG:-Not specified}
**Created**: ${DATE}
**Hub**: ${AIPROJECTS_DIR}

## Purpose

[Describe what this project does]

## Development

### Setup

\`\`\`bash
# Setup commands here
\`\`\`

### Run

\`\`\`bash
# Run commands here
\`\`\`

## Architecture

[Key architectural decisions]

## Notes

[Project-specific notes]
CLAUDE

log_success "Created .claude/CLAUDE.md"

# Type-specific initialization
case "$TYPE" in
    web-app)
        mkdir -p src public
        if [[ "$LANG" == "typescript" ]]; then
            echo '{"name":"'"$NAME"'","version":"0.1.0","private":true}' > package.json
        fi
        log_success "Created web-app structure"
        ;;
    api)
        mkdir -p src tests
        if [[ "$LANG" == "python" ]]; then
            touch requirements.txt
            echo "# ${NAME} API" > src/__init__.py
        elif [[ "$LANG" == "typescript" ]]; then
            echo '{"name":"'"$NAME"'","version":"0.1.0","private":true}' > package.json
        fi
        log_success "Created api structure"
        ;;
    cli)
        mkdir -p src bin
        log_success "Created cli structure"
        ;;
    library)
        mkdir -p src tests
        log_success "Created library structure"
        ;;
    docker)
        cat > docker-compose.yml << COMPOSE
services:
  ${NAME}:
    image: # TODO: specify image
    container_name: ${NAME}
    restart: unless-stopped
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
      - "com.centurylinklabs.watchtower.scope=prod"
    # ports:
    #   - "8080:8080"
    # volumes:
    #   - ./data:/app/data
    # environment:
    #   - TZ=America/Denver

networks:
  caddy-network:
    external: true
COMPOSE
        touch Dockerfile
        log_success "Created docker structure"
        ;;
    *)
        mkdir -p src
        log_success "Created basic structure"
        ;;
esac

# Register with AIProjects - Update paths-registry.yaml
cd "$AIPROJECTS_DIR"

# Add to paths-registry.yaml under coding.projects
# Using a simple append approach - assumes coding.projects section exists
REGISTRY_ENTRY="  ${NAME}:
    path: ${PROJECT_PATH}
    type: ${TYPE}
    language: ${LANG:-unknown}
    status: active
    created: ${DATE}"

# Find the line with "coding:" and its "projects:" subsection, then append
if grep -q "^coding:" "$REGISTRY_FILE"; then
    # File has coding section, append to it
    # This is a simple approach - for complex YAML, use yq
    log_info "Updating paths-registry.yaml..."
    # For now, just inform - complex YAML editing is better done by AI
    log_warning "Manual step: Add to paths-registry.yaml under coding.projects:"
    echo "$REGISTRY_ENTRY"
else
    log_warning "coding section not found in paths-registry.yaml"
fi

log_success "Registry entry prepared"

# Create context file in AIProjects
mkdir -p "$CONTEXT_DIR"
cat > "${CONTEXT_DIR}/${NAME}.md" << CONTEXT
# ${NAME}

**Path**: ~/Code/${NAME}
**Type**: ${TYPE}
**Language**: ${LANG:-Not specified}
**Status**: active
**Created**: ${DATE}

## Overview

[To be documented as project develops]

## Key Decisions

| Date | Decision | Rationale |
|------|----------|-----------|

## Current State

**Last worked on**: ${DATE}
**Current focus**: Initial setup

## Links

- Code: \`~/Code/${NAME}\`
- README: \`~/Code/${NAME}/README.md\`
CONTEXT

log_success "Created context file: ${CONTEXT_DIR}/${NAME}.md"

# Optional GitHub
if [[ "$GITHUB" == true ]]; then
    cd "$PROJECT_PATH"
    if command -v gh &> /dev/null; then
        log_info "Creating GitHub repository..."
        if gh repo create "$NAME" --private --source=. --push 2>/dev/null; then
            log_success "Created GitHub repo: github.com/davidmoneil/${NAME}"
        else
            log_warning "GitHub repo creation failed - may already exist or auth issue"
        fi
    else
        log_warning "gh CLI not installed, skipping GitHub creation"
    fi
fi

# Initial commit
cd "$PROJECT_PATH"
git add .
git commit --quiet -m "Initial project setup

Type: ${TYPE}
Language: ${LANG:-Not specified}
Hub: AIProjects

Co-Authored-By: Claude Code <noreply@anthropic.com>"

COMMIT_HASH=$(git rev-parse --short HEAD)
log_success "Initial commit: $COMMIT_HASH"

# Summary
echo ""
echo "═══════════════════════════════════════════════════"
echo -e "${GREEN}✓ Code project created: ${NAME}${NC}"
echo "═══════════════════════════════════════════════════"
echo "  📁 Code:     ~/Code/${NAME}"
echo "  📋 Type:     ${TYPE}"
echo "  🔧 Language: ${LANG:-Not specified}"
echo "  📝 Context:  .claude/context/projects/${NAME}.md"
echo "  📊 Registry: paths-registry.yaml (update needed)"
if [[ "$GITHUB" == true ]]; then
echo "  🐙 GitHub:   github.com/davidmoneil/${NAME}"
fi
echo "═══════════════════════════════════════════════════"
echo ""
echo "To start working:"
echo "  cd ~/Code/${NAME}"
echo "  claude"
echo ""

exit 0
