#!/bin/bash
# platform.sh - Cross-platform compatibility library for AIfred
#
# Provides portable wrappers for commands that differ between GNU/Linux and macOS (BSD).
# Source this file at the top of any script that uses stat, date -d, sed -i, find -printf,
# timeout, or xargs -r.
#
# Usage:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/platform.sh"
#   # or, if AIFRED_HOME is set:
#   source "${AIFRED_HOME}/scripts/lib/platform.sh"
#
# Guard: safe to source multiple times.

# Prevent double-sourcing
[[ -n "${AIFRED_PLATFORM:-}" ]] && return 0

# Detect platform
case "$(uname -s)" in
    Linux*)
        if grep -qi microsoft /proc/version 2>/dev/null; then
            AIFRED_PLATFORM="wsl"
        else
            AIFRED_PLATFORM="linux"
        fi
        ;;
    Darwin*)
        AIFRED_PLATFORM="macos"
        ;;
    *)
        AIFRED_PLATFORM="unknown"
        ;;
esac
export AIFRED_PLATFORM

# ============================================================================
# compat_stat_mtime <file>
#   Print file modification time as epoch seconds.
#   Replaces: stat -c %Y (GNU) / stat -f %m (BSD)
# ============================================================================
compat_stat_mtime() {
    local file="$1"
    if [[ "$AIFRED_PLATFORM" == "macos" ]]; then
        stat -f %m "$file"
    else
        stat -c %Y "$file"
    fi
}

# ============================================================================
# compat_stat_size <file>
#   Print file size in bytes.
#   Replaces: stat -c %s (GNU) / stat -f %z (BSD)
# ============================================================================
compat_stat_size() {
    local file="$1"
    if [[ "$AIFRED_PLATFORM" == "macos" ]]; then
        stat -f %z "$file"
    else
        stat -c %s "$file"
    fi
}

# ============================================================================
# compat_date_epoch <epoch> [format]
#   Format an epoch timestamp. Default format: +%Y-%m-%d %H:%M
#   Replaces: date -d @epoch (GNU) / date -r epoch (BSD)
# ============================================================================
compat_date_epoch() {
    local epoch="$1"
    local fmt="${2:-+%Y-%m-%d %H:%M}"
    if [[ "$AIFRED_PLATFORM" == "macos" ]]; then
        date -r "$epoch" "$fmt"
    else
        date -d "@$epoch" "$fmt"
    fi
}

# ============================================================================
# compat_date_relative <offset> [format]
#   Compute a date relative to now. Default format: +%Y-%m-%d
#
#   Supported offset formats:
#     "-N days"  / "N days ago"   → N days in the past
#     "-N hours" / "N hours ago"  → N hours in the past
#     "+N seconds"                → N seconds in the future (for resolve_time)
#
#   Replaces: date -d "7 days ago" (GNU) / date -v-7d (BSD)
# ============================================================================
compat_date_relative() {
    local offset="$1"
    local fmt="${2:-+%Y-%m-%d}"

    # Normalize: "7 days ago" → "-7 days", "N hours ago" → "-N hours"
    if [[ "$offset" =~ ^([0-9]+)[[:space:]]+(day|days|hour|hours|minute|minutes|second|seconds)[[:space:]]+ago$ ]]; then
        offset="-${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    fi

    # Parse: "-N unit" or "+N unit"
    if [[ "$offset" =~ ^([+-]?)([0-9]+)[[:space:]]*(day|days|hour|hours|minute|minutes|second|seconds)$ ]]; then
        local sign="${BASH_REMATCH[1]:-+}"
        local num="${BASH_REMATCH[2]}"
        local unit="${BASH_REMATCH[3]}"

        if [[ "$AIFRED_PLATFORM" == "macos" ]]; then
            local flag
            case "$unit" in
                day|days)       flag="-v${sign}${num}d" ;;
                hour|hours)     flag="-v${sign}${num}H" ;;
                minute|minutes) flag="-v${sign}${num}M" ;;
                second|seconds) flag="-v${sign}${num}S" ;;
            esac
            date "$flag" "$fmt"
        else
            date -d "${sign}${num} ${unit}" "$fmt"
        fi
    else
        # Fallback: pass directly to GNU date (Linux only)
        date -d "$offset" "$fmt" 2>/dev/null || echo "unknown"
    fi
}

# ============================================================================
# compat_sed_inplace <expression> <file>
#   Portable in-place sed. Uses temp file + mv (works on all platforms).
#   Replaces: sed -i 'expr' file (GNU) / sed -i '' 'expr' file (BSD)
# ============================================================================
compat_sed_inplace() {
    local expr="$1"
    local file="$2"
    local tmp
    tmp=$(mktemp)
    sed "$expr" "$file" > "$tmp" && mv "$tmp" "$file"
}

# ============================================================================
# compat_find_printf_mtime <dir> <name_pattern>
#   Print modification times (epoch) of matching files, one per line.
#   Replaces: find <dir> -name <pattern> -printf '%T@\n'
# ============================================================================
compat_find_printf_mtime() {
    local dir="$1"
    local pattern="$2"
    if [[ "$AIFRED_PLATFORM" == "macos" ]]; then
        find "$dir" -type f -name "$pattern" -exec stat -f '%m' {} \;
    else
        find "$dir" -type f -name "$pattern" -printf '%T@\n'
    fi
}

# ============================================================================
# compat_timeout <seconds> <command...>
#   Run a command with a timeout. Falls back to perl on macOS.
#   Replaces: timeout (GNU coreutils)
# ============================================================================
compat_timeout() {
    local secs="$1"
    shift
    if command -v timeout &>/dev/null; then
        timeout "$secs" "$@"
    else
        # perl fallback (available on macOS by default)
        perl -e '
            use POSIX ":sys_wait_h";
            alarm shift @ARGV;
            $SIG{ALRM} = sub { kill 9, $pid if $pid; exit 124 };
            $pid = fork // die "fork: $!";
            if ($pid == 0) { exec @ARGV; die "exec: $!" }
            waitpid($pid, 0);
            exit ($? >> 8);
        ' "$secs" "$@"
    fi
}

# ============================================================================
# compat_xargs_nonempty <args...>
#   Portable xargs that does nothing on empty input.
#   Replaces: xargs -r (GNU, no-run-if-empty)
# ============================================================================
compat_xargs_nonempty() {
    if [[ "$AIFRED_PLATFORM" == "macos" ]]; then
        # BSD xargs already does nothing on empty input by default
        xargs "$@"
    else
        xargs -r "$@"
    fi
}
