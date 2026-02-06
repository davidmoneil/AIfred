#!/bin/bash
# =============================================================================
# Claude Code Environment Configuration
# =============================================================================
# Source this from your ~/.zshrc or ~/.bashrc:
#   source ~/Claude/Jarvis/.claude/scripts/claude-code-env.sh
#
# These settings optimize Claude Code's context management to prevent
# "lockout" scenarios where context usage exceeds internal limits.
#
# Last updated: 2026-02-05 (post-lockout-analysis)
# =============================================================================

# -----------------------------------------------------------------------------
# CONTEXT MANAGEMENT SETTINGS
# -----------------------------------------------------------------------------

# Auto-compact trigger percentage (default: ~95%)
# Set lower to ensure compaction runs BEFORE the internal lockout ceiling.
#
# Lockout occurs at approximately:
#   (CONTEXT_WINDOW - MAX_OUTPUT_TOKENS - ~28K compact_buffer) / CONTEXT_WINDOW
#   = (200K - 15K - 28K) / 200K = 78.5%
#
# Setting to 70% gives 8.5% headroom before lockout.
# Can only be set LOWER than default; higher values have no effect.
export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=70

# Maximum output tokens per response (default: 32000, max: 64000)
# Lower values increase usable context before lockout.
# 15000 is a good balance - high enough for substantial responses,
# low enough to maximize context utilization.
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=15000

# -----------------------------------------------------------------------------
# JICM INTEGRATION (for jarvis-watcher.sh)
# -----------------------------------------------------------------------------

# These can override the .jicm-config file if set in environment
# Uncomment to use environment variables instead of config file:

# export JICM_THRESHOLD=65      # /intelligent-compress trigger
# export JICM_CRITICAL_PCT=75   # Emergency threshold

# -----------------------------------------------------------------------------
# NOTES ON THRESHOLDS
# -----------------------------------------------------------------------------
#
# With current settings (15K output reserve), the thresholds are:
#
#   55% (110K)  - JICM "approaching" warning
#   65% (130K)  - JICM compression trigger
#   70% (140K)  - Claude Code auto-compact (if enabled)
#   75% (150K)  - JICM critical/emergency
#   78.5% (157K) - Claude Code LOCKOUT (can't even run /compact)
#
# The 8.5% gap between auto-compact (70%) and lockout (78.5%) provides
# approximately 17K tokens of safety margin for the compaction operation.
#
# =============================================================================
