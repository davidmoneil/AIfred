# Wiggum Loop 4 — JICM Context Monitoring & State Accuracy

**Date**: 2026-02-13
**Focus**: State file accuracy, token tracking, context growth

---

## Test Results

| Test | Description | Result | Evidence |
|------|-------------|--------|----------|
| T4.1 | State pct vs W0 | **FAIL** | JICM: 31%, W0: 41% (stale state file) |
| T4.2 | Token field fix | **PASS** | Was reading 0, now reads 61089 after field fix |
| T4.3 | State freshness | **FAIL** | Timestamp 12min old during normal WATCHING |
| T4.4 | PID consistency | **PASS** | State=30437, File=30437, process alive |
| T4.5 | Context growth | **PASS** | 41% → 42% → 43% (monotonic, 3 prompts) |

**Score**: 3/5 PASS, 2 FAIL (60%)

---

## Bugs Found & Fixed

### BUG-07: write_state() never called during WATCHING (CRITICAL)
- **Severity**: Critical (all state file consumers read stale data)
- **Location**: `.claude/scripts/jicm-watcher.sh`, WATCHING loop
- **Impact**: Ennoia, Virgil, watch-jicm.sh, and any other consumer sees stale context %
- **Root Cause**: `write_state()` only called at startup and during state transitions
- **Fix Applied**: Added `write_state` every 6 polls (~30s) in WATCHING state
- **Status**: Fixed in code, needs watcher restart to take effect

### BUG-08: watch-jicm.sh field name mismatch (MEDIUM)
- **Severity**: Medium (tokens always reads 0)
- **Location**: `.claude/scripts/dev/watch-jicm.sh:85`
- **Impact**: JSON output shows `tokens: 0` instead of actual token count
- **Root Cause**: Reads `tokens` field, state file uses `context_tokens`
- **Fix Applied**: Changed to `read_field "context_tokens" "0"`
- **Status**: Fixed, verified working

---

## Review

- Two meaningful bugs found and fixed
- Context growth tracking verified (monotonic increase)
- PID consistency confirmed
- State file staleness was the root cause of Ennoia/Virgil data inaccuracy
- Watcher restart needed to activate the write_state fix

---

*Loop 4 Complete — 3/5 PASS, 2 FAIL (both bugs fixed)*
