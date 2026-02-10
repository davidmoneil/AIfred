#!/bin/bash
# =============================================================================
# Claude Code Environment Configuration
# =============================================================================
# Source this from your ~/.zshrc or ~/.bashrc:
#   source ~/Claude/Jarvis/.claude/scripts/claude-code-env.sh
#
# These settings optimize Claude Code's context management.
#
# Last updated: 2026-02-06 (threshold analysis + forensic reconstruction)
# =============================================================================

# -----------------------------------------------------------------------------
# CONTEXT MANAGEMENT SETTINGS
# -----------------------------------------------------------------------------

# Maximum output tokens per response (default: 32000, max: 64000)
# Lower values increase usable context before lockout.
# 15000 is a good balance - high enough for substantial responses,
# low enough to maximize context utilization.
# export CLAUDE_CODE_MAX_OUTPUT_TOKENS=15000

# CLAUDE_AUTOCOMPACT_PCT_OVERRIDE
#
# Controls when auto-compaction triggers (1-100). Default: ~95%.
# Only LOWER values have effect; higher values are ignored.
# Effective trigger is ~10% below set value due to internal reserves
# (output buffer + compact operation buffer).
#
# With default 95%:
#   Effective trigger: ~85% of context window (~170K tokens)
#
# We intentionally leave this at DEFAULT (unset) to keep auto-compact
# as high as possible. JICM triggers compression at 55%, giving 30%
# headroom (60K tokens) for current work to complete + compression to run.
#
# Uncomment only if you need to lower the auto-compact trigger:
# export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=70

# -----------------------------------------------------------------------------
# NOTES ON THRESHOLDS (v5.7.0)
# -----------------------------------------------------------------------------
#
# Threshold cascade (200K context window, 15K output reserve):
#
#   45% (90K)   - JICM "approaching" warning
#   55% (110K)  - JICM compression trigger (/intelligent-compress)
#   ~85% (170K) - Claude Code auto-compact (default, effective)
#   ~95% (190K) - Claude Code auto-compact (configured, pre-reserves)
#
# Why 55% for JICM? Forensic analysis (2026-02-06) showed:
#   - /intelligent-compress gets QUEUED behind current work
#   - A multi-step turn (file read + analysis + edits) can add 40K tokens
#   - The compression skill itself only adds ~2K tokens
#   - Need headroom: 55% + 20% (queuing) + 1% (skill) + 5% (agent) = 81%
#   - 81% < 85% auto-compact = safe
#
# =============================================================================
