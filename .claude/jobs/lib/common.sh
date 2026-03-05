#!/usr/bin/env bash
# common.sh — Shared utilities for the headless job engine
#
# Source this at the top of any script that needs registry access,
# colored logging, or yq. Expects JOBS_DIR to be set by the caller.
#
# Provides:
#   Colors: RED, GREEN, YELLOW, BLUE, CYAN, NC (auto-disabled when not a tty)
#   Logging: log(), log_info(), log_success(), log_warning(), log_error()
#   Registry: require_yq(), reg_get()
#   Variables: YQ (set after require_yq), REGISTRY (set from JOBS_DIR)

# Guard against double-sourcing
[ -n "${_COMMON_SH_LOADED:-}" ] && return 0
_COMMON_SH_LOADED=1

# Auto-detect project root (two levels up from lib/)
PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# ============================================================================
# Colors (auto-disable when piped)
# ============================================================================

if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi

# ============================================================================
# Logging
# ============================================================================

# Base log — callers can override for tee-to-file behavior
log() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_info()    { log "${BLUE}INFO${NC}: $1"; }
log_success() { log "${GREEN}OK${NC}: $1"; }
log_warning() { log "${YELLOW}WARN${NC}: $1"; }
log_error()   { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${RED}ERROR${NC}: $1" >&2; }

# ============================================================================
# yq dependency
# ============================================================================

require_yq() {
    for yq_path in "yq" "$HOME/.local/bin/yq" "/usr/local/bin/yq" "/snap/bin/yq"; do
        if command -v "$yq_path" &>/dev/null 2>&1 || [ -x "$yq_path" ]; then
            echo "$yq_path"
            return 0
        fi
    done
    log_error "yq is required. Install: wget -qO ~/.local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && chmod +x ~/.local/bin/yq"
    exit 1
}

# ============================================================================
# Registry access
# ============================================================================

# Read a value from registry.yaml for a given job, with fallback to defaults.
# Uses explicit null check instead of yq's // operator because // treats
# 'false' as falsy and skips it.
reg_get() {
    local job="$1" key="$2" default="${3:-}"
    local val
    val=$("$YQ" ".jobs.${job}.${key}" "$REGISTRY" 2>/dev/null)
    if [ -z "$val" ] || [ "$val" = "null" ]; then
        val=$("$YQ" ".defaults.${key}" "$REGISTRY" 2>/dev/null)
    fi
    if [ -z "$val" ] || [ "$val" = "null" ]; then
        echo "$default"
    else
        echo "$val"
    fi
}
