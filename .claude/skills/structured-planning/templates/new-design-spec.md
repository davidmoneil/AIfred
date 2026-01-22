---
name: "{{PROJECT_NAME}}"
mode: new_design
created: {{DATE}}
status: draft
orchestration: .claude/orchestration/{{DATE}}-{{SLUG}}.yaml
planning_session: "{{SESSION_ID}}"
---

# {{PROJECT_NAME}} - Design Specification

## Executive Summary

{{SUMMARY}}

---

## Vision & Goals

### Problem Statement

{{PROBLEM_STATEMENT}}

### Target Users

{{TARGET_USERS}}

### Success Criteria

{{SUCCESS_CRITERIA}}

---

## Features & Scope

### MVP Features (Must-Have)

{{MVP_FEATURES}}

### Phase 2 Features (Nice-to-Have)

{{PHASE2_FEATURES}}

### Out of Scope

{{OUT_OF_SCOPE}}

---

## Technical Design

### Architecture Overview

{{ARCHITECTURE}}

### Technology Stack

{{TECH_STACK}}

### Integrations

{{INTEGRATIONS}}

### Data Model

{{DATA_MODEL}}

---

## Constraints & Requirements

### Timeline

{{TIMELINE}}

### Performance Requirements

{{PERFORMANCE}}

### Security Requirements

{{SECURITY}}

### Other Constraints

{{OTHER_CONSTRAINTS}}

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
{{RISKS_TABLE}}

---

## Planning Session Record

### Questions & Answers

{{QA_RECORD}}

### Key Decisions Made

{{DECISIONS}}

### Open Questions

{{OPEN_QUESTIONS}}

---

## Approval Checklist

- [ ] Problem statement is clear and validated
- [ ] Target users are well-defined
- [ ] MVP scope is achievable and valuable
- [ ] Technical approach is sound
- [ ] Risks are identified with mitigations
- [ ] Ready for orchestration breakdown

---

**Next Steps**: Run `/orchestration:status` to see the implementation plan.
