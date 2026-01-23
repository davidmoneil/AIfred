# Standards Index

Project-wide standards for naming, classification, and terminology.

**Layer**: Mind (rules that MUST be followed)

---

## Active Standards

| Standard | Purpose | Status |
|----------|---------|--------|
| [README Standard](readme-standard.md) | Every directory needs a README; Jarvis MUST check them | ✅ Active |
| [Severity/Status System](severity-status-system.md) | Universal severity levels, status values, check results | ✅ Active |
| [Model Selection](model-selection.md) | When to use Opus vs Sonnet vs Haiku | ✅ Active |
| [Gate Pattern Standard](gate-pattern-standard.md) | Approval checkpoints and risk levels | ✅ Active |
| [Metrics Collection Standard](metrics-collection-standard.md) | Common metrics all components must emit | ✅ Active |

---

## Hierarchy

Standards sit at the TOP of the behavioral hierarchy:

```
Standards (MUST follow) ← YOU ARE HERE
    ↓
Patterns (SHOULD follow)
    ↓
Workflows (Large task procedures)
    ↓
Designs (Architecture philosophy)
    ↓
Plans (Session-level work)
```

## Usage

Standards ensure consistency across:
- Directory organization (README Standard)
- Slash commands and output
- Scripts and automation
- Documentation and reports
- Hooks and logging

**When creating new commands or documentation, reference these standards.**

---

**Last Updated**: 2026-01-22
