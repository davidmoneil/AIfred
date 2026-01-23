# Review Criteria

**Purpose**: PR and milestone review criteria definitions.

**Layer**: Pneuma (standards)

---

## Contents

- `defaults.yaml` — Default review criteria
- `PR-*.yaml` — PR-specific criteria files

## Usage

AC-03 Milestone Review loads criteria from here:
1. Check for PR-specific file (`PR-12.3.yaml`)
2. Fall back to `defaults.yaml`
3. Evaluate deliverables against criteria

## Criteria Format

```yaml
version: 1.0.0
pr: PR-X.X
description: Description

deliverables:
  - path: path/to/file
    type: type
    validation:
      - check: true

acceptance:
  - Criterion 1
  - Criterion 2
```

---

*Jarvis — Pneuma Layer (Standards)*
