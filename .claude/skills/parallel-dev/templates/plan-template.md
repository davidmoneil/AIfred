---
name: "{PLAN_NAME}"
version: "1.0"
created: "{TIMESTAMP}"
status: draft
project_type: "{PROJECT_TYPE}"
---

# Development Plan: {PLAN_NAME}

## 1. Vision & Goals

### Core Purpose
> What is the main problem this solves?

{CORE_PURPOSE}

### Target Users
> Who will use this? What do they need?

{TARGET_USERS}

### Success Criteria
> How do we know when this is "done"?

- [ ] {SUCCESS_CRITERION_1}
- [ ] {SUCCESS_CRITERION_2}
- [ ] {SUCCESS_CRITERION_3}

---

## 2. Features & Scope

### Must-Have Features (MVP)
> Essential for first release

1. **{FEATURE_1}**
   - Description: {DESCRIPTION}
   - Acceptance: {ACCEPTANCE_CRITERIA}

2. **{FEATURE_2}**
   - Description: {DESCRIPTION}
   - Acceptance: {ACCEPTANCE_CRITERIA}

### Nice-to-Have Features
> Can be added later

- {NICE_TO_HAVE_1}
- {NICE_TO_HAVE_2}

### Explicitly Out of Scope
> What we are NOT building

- {OUT_OF_SCOPE_1}
- {OUT_OF_SCOPE_2}

---

## 3. Technical Decisions

### Stack
> Technologies and frameworks

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Frontend | {FRONTEND} | {WHY} |
| Backend | {BACKEND} | {WHY} |
| Database | {DATABASE} | {WHY} |
| Infrastructure | {INFRA} | {WHY} |

### Architecture Patterns
> Key design decisions

- **Pattern**: {PATTERN_NAME}
  - Why: {RATIONALE}

### Integrations
> External services/APIs

- {INTEGRATION_1}: {PURPOSE}
- {INTEGRATION_2}: {PURPOSE}

---

## 4. Constraints & Requirements

### Performance
- {PERFORMANCE_REQ}

### Security
- {SECURITY_REQ}

### Compatibility
- {COMPATIBILITY_REQ}

### Timeline
- Target: {TARGET_DATE_OR_MILESTONE}
- Flexibility: {HARD_DEADLINE_OR_FLEXIBLE}

---

## 5. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| {RISK_1} | {HIGH/MED/LOW} | {MITIGATION} |
| {RISK_2} | {HIGH/MED/LOW} | {MITIGATION} |

---

## 6. Questions Answered

> Record of clarifying questions and decisions made during planning

| Question | Answer | Decided |
|----------|--------|---------|
| {QUESTION} | {ANSWER} | {DATE} |

---

## Approval

- [ ] Plan reviewed by user
- [ ] Technical approach approved
- [ ] Ready for decomposition

**Approved**: {DATE}
**By**: User confirmation

---

## Next Steps

After approval:
1. Run `/parallel-dev:decompose {PLAN_NAME}` to break into tasks
2. Review generated tasks
3. Run `/parallel-dev:start {PLAN_NAME}` to begin execution
