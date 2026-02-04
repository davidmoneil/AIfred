# JICM v5 Implementation Plan

**Date**: 2026-02-03
**Status**: ✅ IMPLEMENTATION COMPLETE — Ready for Testing
**Authority**: Based on `jicm-v5-design-addendum.md` (v1.3)
**Completed**: 2026-02-03

---

## Executive Summary

This plan covers the end-to-end implementation of JICM v5, transforming the v4 prototype into the production v5 system with:
- Single 50% threshold
- Two-mechanism resume (Hook injection + Idle-hands monitor)
- Mode-based idle-hands system
- 10k-30k token compression target
- Combined data sources (transcript + foundation docs + session state)

---

## Phase 0: Preparation ✅ COMPLETE

### 0.1 Empirical Testing

Test script created: `.claude/scripts/test-submission-methods.sh`

**Test Methods**:
1. `send-keys C-m` — Standard Enter
2. `send-keys -l $'\r'` — Literal CR
3. `send-keys -l $'\n'` — Literal LF
4. `send-keys -l $'\r\n'` — Literal CRLF
5. `send-keys Enter` — tmux Enter key
6. `send-keys Escape C-m` — Escape + Enter
7. `send-keys C-m C-m` — Double Enter

**To run**: `.claude/scripts/test-submission-methods.sh`

### 0.2 Backup Current Implementation

Backup recommended before testing:
```bash
git checkout -b jicm-v4-backup
git checkout Project_Aion
```

---

## Phase 1: Hook Changes ✅ COMPLETE

### 1.1 Update session-start.sh

**File**: `.claude/hooks/session-start.sh` — **UPDATED**

**Changes Made**:

1. ✅ **JICM v5 signal detection** — V5_* variables and detection logic
2. ✅ **Context injection** — Reads both context files, returns via additionalContext
3. ✅ **`.idle-hands-active` flag creation** — Mode: jicm_resume, with metadata
4. ✅ **No greeting for JICM restarts** — Immediate resume instructions

**Implementation Checklist**:
- [x] V5 signal detection integrated
- [x] Context file reading and injection
- [x] `.idle-hands-active` flag creation with YAML format
- [x] Debounce updated to v5
- [x] Syntax validated

### 1.2 jicm-continuation-verifier.js

Not needed — bash implementation is sufficient.

---

## Phase 2: Watcher Changes ✅ COMPLETE

### 2.1 Update jarvis-watcher.sh

**File**: `.claude/scripts/jarvis-watcher.sh` — **UPDATED**

**Changes Made**:

1. ✅ **Single 50% threshold** — `JICM_THRESHOLD` variable
2. ✅ **Idle-hands monitoring** — `check_idle_hands()` function added
3. ✅ **Idle state detection** — `detect_idle_state()` function
4. ✅ **7 submission methods** — SUBMISSION_METHODS array with all variants
5. ✅ **4 prompt types** — RESUME, SIMPLE, MINIMAL, EMPTY
6. ✅ **Success detection** — `detect_submission_success()` function
7. ✅ **Cleanup logic** — `cleanup_jicm_files()` function

**Implementation Checklist**:
- [x] Single 50% threshold
- [x] `check_idle_hands()` function
- [x] `idle_hands_jicm_resume()` mode handler
- [x] `detect_idle_state()` function
- [x] `submit_with_variant()` function (cycles through 28 combinations)
- [x] `detect_submission_success()` function
- [x] `cleanup_jicm_files()` function
- [x] Integrated into main loop (section 1.1)
- [x] Syntax validated

### 2.2 Update Compression Trigger ✅

- Triggers `/intelligent-compress` at 50%
- No fallback to /compact

---

## Phase 3: Compression Agent Updates ✅ COMPLETE

### 3.1 Update compression-agent.md

**File**: `.claude/agents/compression-agent.md` — **UPDATED**

**Changes Made**:

1. ✅ **Data sources** — Transcript + Foundation + Session State (READ-ONLY)
2. ✅ **Compression target** — 10,000-30,000 tokens
3. ✅ **Agent instructions** — Consolidate, organize, clarify, simplify
4. ✅ **Output files** — `.compressed-context-ready.md` + `.compression-done.signal`
5. ✅ **Quality checklist** — Verification before output

**Implementation Checklist**:
- [x] Data source file list updated
- [x] Compression target (10k-30k) specified
- [x] Processing instructions updated
- [x] Signal file creation documented

### 3.2 Update intelligent-compress.md

**File**: `.claude/commands/intelligent-compress.md` — **UPDATED**

**Changes Made**:
- [x] v5 parameters in agent spawn
- [x] `run_in_background: true` specified
- [x] File references updated to v5 names
- [x] JICM v5 flow diagram added

---

## Phase 4: Integration Testing ⏳ READY FOR TESTING

### 4.1 Test Submission Methods

**Goal**: Verify which submission method wakes Jarvis after /clear

**Run**: `.claude/scripts/test-submission-methods.sh`

**Test Procedure**:
1. Put Claude Code at idle prompt
2. Run test script
3. Record which method(s) work

### 4.2 Test Hook Injection ✅ Syntax Validated

**Goal**: Verify context injection works via additionalContext

**Validation**: Hook syntax verified. Full test requires JICM cycle.

### 4.3 Test Idle Detection ✅ Code Validated

**Goal**: Verify idle state detection accuracy

**Validation**: Detection functions implemented and syntax-checked.

### 4.4 Full Cycle Test ⏳ PENDING

**Goal**: Verify complete JICM v5 flow

**Test Procedure**:
1. Work until context reaches ~50%
2. Observe: watcher triggers /intelligent-compress
3. Observe: compression agent runs
4. Observe: watcher sends /clear
5. Observe: hook injects context + creates idle-hands flag
6. Observe: idle-hands wakes Jarvis
7. Observe: Jarvis resumes work
8. Observe: cleanup occurs

**Success Criteria**:
- [ ] Compression completes in <5 minutes
- [ ] Context injection includes both files
- [ ] Jarvis wakes within 60 seconds
- [ ] Jarvis immediately resumes work (no greeting)
- [ ] All signal/context files cleaned up

---

## Phase 5: Documentation & Cleanup ✅ COMPLETE

### 5.1 Update Implementation Status

- [x] AC-04-jicm.json updated — status: "implemented"
- [x] Implementation plan updated with completion markers

### 5.2 Document Working Configuration

- [ ] Document which submission method works (after testing)
- [ ] Document any edge cases discovered (after testing)
- [ ] Update troubleshooting guide (after testing)

### 5.3 Code Status

- v5 implementation complete
- v4 code paths retained for backward compatibility during testing
- Will remove deprecated paths after v5 validation

---

## Implementation Order

Recommended sequence for minimal disruption:

1. **Phase 0**: Test submission methods (critical path discovery)
2. **Phase 3**: Update compression agent (can test independently)
3. **Phase 1**: Update hooks (enables context injection)
4. **Phase 2**: Update watcher (enables full cycle)
5. **Phase 4**: Integration testing
6. **Phase 5**: Documentation & cleanup

---

## Risk Mitigation

### Risk: Submission Method Doesn't Work

**Mitigation**: Test all 7 variants before implementing. If none work:
- Investigate pexpect/expect alternatives
- Check Claude Code for input configuration options
- Consider alternative prompt injection methods (MCP tool call?)

### Risk: Context Injection Fails

**Mitigation**:
- Keep v4 injection code as fallback
- Test hook output format carefully
- Verify additionalContext JSON structure

### Risk: Idle Detection False Positives

**Mitigation**:
- Use conservative detection (multiple indicators)
- Add debounce timer
- Gate on `.idle-hands-active` flag

### Risk: Compression Agent Timeout

**Mitigation**:
- Set reasonable timeout (5 min)
- Log progress indicators
- Surface problem to user if truly stuck (don't silently fail)

---

## Estimated Total Time

| Phase | Time Estimate |
|-------|---------------|
| Phase 0: Preparation | 1-2 hours |
| Phase 1: Hook Changes | 2-3 hours |
| Phase 2: Watcher Changes | 3-4 hours |
| Phase 3: Agent Updates | 2-3 hours |
| Phase 4: Testing | 2-3 hours |
| Phase 5: Documentation | 1 hour |
| **Total** | **11-16 hours** |

---

## Success Metrics

1. **Functional**: Complete JICM cycle works end-to-end
2. **Reliable**: >95% success rate on resume
3. **Efficient**: Compression completes in <5 minutes
4. **Compact**: Output is 10k-30k tokens
5. **Seamless**: User experiences no interruption in work flow

---

## Implementation Complete

**All phases implemented**: 2026-02-03

### Files Modified

| File | Status |
|------|--------|
| `.claude/hooks/session-start.sh` | ✅ v5 implemented |
| `.claude/scripts/jarvis-watcher.sh` | ✅ v5 implemented |
| `.claude/agents/compression-agent.md` | ✅ v5 implemented |
| `.claude/commands/intelligent-compress.md` | ✅ v5 implemented |
| `.claude/scripts/test-submission-methods.sh` | ✅ Created |
| `.claude/state/components/AC-04-jicm.json` | ✅ Updated |

### Next Steps

1. **Run submission test**: `.claude/scripts/test-submission-methods.sh`
2. **Document results**: Update resume-mechanisms doc with working method
3. **Full cycle test**: Let context reach 50%, observe complete flow
4. **Validate**: Confirm Jarvis resumes seamlessly after /clear

---

*JICM v5 Implementation Plan — Created 2026-02-03 | Implemented 2026-02-03*
