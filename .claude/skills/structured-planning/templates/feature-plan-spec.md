---
name: "{{FEATURE_NAME}}"
mode: feature_planning
created: {{DATE}}
status: draft
orchestration: .claude/orchestration/{{DATE}}-{{SLUG}}.yaml
project: "{{PROJECT_NAME}}"
planning_session: "{{SESSION_ID}}"
---

# {{FEATURE_NAME}} - Feature Specification

## Summary

{{SUMMARY}}

---

## Feature Definition

### What We're Building

{{FEATURE_DESCRIPTION}}

### Problem Being Solved

{{PROBLEM}}

### Target Users

{{USERS}}

---

## Scope

### In Scope

{{IN_SCOPE}}

### Out of Scope

{{OUT_OF_SCOPE}}

---

## Technical Approach

### Integration Points

{{INTEGRATION_POINTS}}

### Files to Modify/Create

{{FILES}}

### Dependencies

{{DEPENDENCIES}}

---

## Acceptance Criteria

{{ACCEPTANCE_CRITERIA}}

---

## Planning Session Record

### Questions & Answers

{{QA_RECORD}}

### Decisions

{{DECISIONS}}

---

## Checklist

- [ ] Scope is clear and bounded
- [ ] Integration approach validated
- [ ] Acceptance criteria are testable
- [ ] Ready for implementation

---

**Next Steps**: Run `/orchestration:status` to see implementation tasks.
