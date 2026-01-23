# Config

**Purpose**: Runtime configuration files.

**Layer**: Pneuma (configuration)

---

## Contents

| File | Purpose |
|------|---------|
| `autonomy-config.yaml` | Autonomy settings and thresholds |
| `workspace-allowlist.yaml` | Allowed workspace paths |
| `credentials.local.yaml` | Local credentials (gitignored) |

## What Belongs Here

- Configuration files that affect runtime behavior
- Settings that persist across sessions
- Allowlists and deny lists

## What Does NOT Belong Here

- Secrets → `secrets/`
- State files → `state/`
- Operational logs → `logs/`

## Security Note

`credentials.local.yaml` and similar files should be gitignored.
Never commit actual credentials.

---

*Jarvis — Pneuma Layer (Configuration)*
