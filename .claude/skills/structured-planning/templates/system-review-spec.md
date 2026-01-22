---
name: "{{SYSTEM_NAME}} Review"
mode: system_review
created: {{DATE}}
status: draft
orchestration: .claude/orchestration/{{DATE}}-{{SLUG}}-improvements.yaml
planning_session: "{{SESSION_ID}}"
---

# {{SYSTEM_NAME}} - Review & Improvement Plan

## Executive Summary

{{SUMMARY}}

---

## Current State Assessment

### System Overview

{{SYSTEM_OVERVIEW}}

### What's Working Well

{{WORKING_WELL}}

### Architecture Analysis

{{ARCHITECTURE_ANALYSIS}}

---

## Identified Issues

### Critical Issues

{{CRITICAL_ISSUES}}

### High Priority Issues

{{HIGH_ISSUES}}

### Medium Priority Issues

{{MEDIUM_ISSUES}}

### Low Priority / Technical Debt

{{LOW_ISSUES}}

---

## Desired State

### Target Capabilities

{{TARGET_CAPABILITIES}}

### Target Architecture

{{TARGET_ARCHITECTURE}}

### Success Criteria

{{SUCCESS_CRITERIA}}

---

## Gap Analysis

| Current State | Desired State | Gap | Effort |
|---------------|---------------|-----|--------|
{{GAP_TABLE}}

---

## Improvement Plan

### Phase 1: Quick Wins

{{QUICK_WINS}}

**Estimated Effort**: {{PHASE1_EFFORT}}

### Phase 2: Core Improvements

{{CORE_IMPROVEMENTS}}

**Estimated Effort**: {{PHASE2_EFFORT}}

### Phase 3: Strategic Changes

{{STRATEGIC_CHANGES}}

**Estimated Effort**: {{PHASE3_EFFORT}}

---

## Review Session Record

### Questions & Answers

{{QA_RECORD}}

### Key Findings

{{KEY_FINDINGS}}

### Recommendations

{{RECOMMENDATIONS}}

---

## Approval Checklist

- [ ] Current state accurately captured
- [ ] Issues prioritized correctly
- [ ] Desired state aligns with goals
- [ ] Improvement plan is feasible
- [ ] Ready for orchestration breakdown

---

**Next Steps**: Run `/orchestration:status` to see the improvement implementation plan.
