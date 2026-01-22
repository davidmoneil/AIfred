#!/bin/bash
# Script: link-external.sh
# Purpose: Create symlink in external-sources with documentation
# Usage: ./link-external.sh <source-path> <category/link-name>
# Author: David Moneil
# Created: 2026-01-20
# Pattern: Capability Layering (Code → CLI → Prompt)

set -euo pipefail

# Configuration
AIPROJECTS_DIR="${HOME}/AIProjects"
EXTERNAL_DIR="${AIPROJECTS_DIR}/external-sources"
REGISTRY_FILE="${AIPROJECTS_DIR}/paths-registry.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Help
show_help() {
    cat << EOF
Usage: $(basename "$0") <source-path> <category/link-name>

Create a symlink in external-sources directory.

Arguments:
    source-path       Absolute path to the source file/directory
    category/name     Destination path under external-sources/
                      Categories: docker, logs, nas, configs

Options:
    -h, --help        Show this help
    -n, --dry-run     Show what would be done
    -f, --force       Overwrite existing symlink

Examples:
    $(basename "$0") /opt/docker/n8n/docker-compose.yml docker/n8n-compose.yml
    $(basename "$0") /var/log/nginx logs/nginx
    $(basename "$0") /mnt/synology/obsidian nas/obsidian-vault

Valid Categories:
    docker    - Docker compose files, configs
    logs      - Log directories
    nas       - NAS mounts and shares
    configs   - Configuration files

Exit Codes:
    0  Success
    1  Invalid arguments
    2  Source not found
    3  Symlink creation failed
EOF
}

# Logging
log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1" >&2; }

# Parse arguments
SOURCE=""
DEST=""
DRY_RUN=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
        -f|--force) FORCE=true; shift ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$SOURCE" ]]; then
                SOURCE="$1"
            elif [[ -z "$DEST" ]]; then
                DEST="$1"
            else
                log_error "Too many arguments"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [[ -z "$SOURCE" ]] || [[ -z "$DEST" ]]; then
    log_error "Both source and destination required"
    show_help
    exit 1
fi

# Expand source path
SOURCE="${SOURCE/#\~/$HOME}"

# Get absolute path if relative
if [[ ! "$SOURCE" = /* ]]; then
    SOURCE="$(pwd)/$SOURCE"
fi

# Verify source exists
if [[ ! -e "$SOURCE" ]]; then
    log_error "Source not found: $SOURCE"
    exit 2
fi

log_info "Source: $SOURCE"

# Parse category and name
CATEGORY=$(echo "$DEST" | cut -d'/' -f1)
LINK_NAME=$(echo "$DEST" | cut -d'/' -f2-)

# Validate category
case "$CATEGORY" in
    docker|logs|nas|configs)
        log_info "Category: $CATEGORY"
        ;;
    *)
        log_warning "Non-standard category: $CATEGORY"
        log_info "Standard categories: docker, logs, nas, configs"
        ;;
esac

# Full destination path
DEST_DIR="${EXTERNAL_DIR}/${CATEGORY}"
DEST_PATH="${EXTERNAL_DIR}/${DEST}"

log_info "Destination: $DEST_PATH"

# Dry run
if [[ "$DRY_RUN" == true ]]; then
    echo ""
    echo "=== DRY RUN ==="
    echo "Would create:"
    echo "  mkdir -p $DEST_DIR"
    echo "  ln -s $SOURCE $DEST_PATH"
    echo ""
    echo "Would add to paths-registry.yaml:"
    echo "  ${CATEGORY}:"
    echo "    ${LINK_NAME}: $SOURCE"
    exit 0
fi

# Create category directory if needed
if [[ ! -d "$DEST_DIR" ]]; then
    mkdir -p "$DEST_DIR"
    log_success "Created directory: $DEST_DIR"
fi

# Check if destination exists
if [[ -e "$DEST_PATH" ]] || [[ -L "$DEST_PATH" ]]; then
    if [[ "$FORCE" == true ]]; then
        rm -f "$DEST_PATH"
        log_warning "Removed existing: $DEST_PATH"
    else
        log_error "Destination already exists: $DEST_PATH"
        log_info "Use --force to overwrite"
        exit 3
    fi
fi

# Create symlink
if ln -s "$SOURCE" "$DEST_PATH"; then
    log_success "Created symlink: $DEST_PATH → $SOURCE"
else
    log_error "Failed to create symlink"
    exit 3
fi

# Verify symlink works
if [[ -e "$DEST_PATH" ]]; then
    log_success "Symlink verified"
else
    log_warning "Symlink created but target not accessible"
fi

# Output registry entry suggestion
echo ""
echo "═══════════════════════════════════════════════════"
echo -e "${YELLOW}Add to paths-registry.yaml:${NC}"
echo "═══════════════════════════════════════════════════"
echo ""
echo "external:"
echo "  ${CATEGORY}:"
echo "    ${LINK_NAME}:"
echo "      source: ${SOURCE}"
echo "      link: external-sources/${DEST}"
echo "      added: $(date +%Y-%m-%d)"
echo ""
echo "═══════════════════════════════════════════════════"

# Summary
echo ""
echo -e "${GREEN}✓ External link created${NC}"
echo ""
echo "  📁 Source: $SOURCE"
echo "  🔗 Link:   external-sources/$DEST"
echo "  📋 Category: $CATEGORY"
echo ""

exit 0
