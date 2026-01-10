# Shared Skill Resources

**Purpose**: Common resources used by multiple skills

---

## Contents

### ooxml/
OOXML (Office Open XML) schemas and scripts shared by:
- `docx` skill (Word documents)
- `pptx` skill (PowerPoint presentations)
- `xlsx` skill (Excel spreadsheets)

Contains:
- `schemas/` — ISO/IEC 29500 standard schemas
- `scripts/` — Validation and utility scripts

---

## Why Shared?

These resources were previously duplicated across skills (~47 files × 2 = 94 files).
Consolidating to `_shared/` reduces:
- Disk usage
- Maintenance burden
- Sync conflicts

---

## Usage

Skills should reference via relative path:
```
../_shared/ooxml/schemas/
```

---

*Created PR-10 — Organization cleanup*
