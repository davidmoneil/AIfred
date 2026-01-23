# State

**Purpose**: Operational state files — component states and task queues.

**Layer**: Pneuma (operational state)

---

## Structure

| Directory | Contents |
|-----------|----------|
| `components/` | Autonomic component state files (JSON) |
| `queues/` | Task queues (YAML) |

## Component States

Each AC component has a state file:
- `AC-01-launch.json` — Self-launch state
- `AC-02-wiggum.json` — Wiggum loop state
- `AC-03-review.json` — Review state
- etc.

## Queues

- `evolution-queue.yaml` — Pending evolution proposals
- `research-agenda.yaml` — R&D topics (linked from context/research/)

## What Belongs Here

- Runtime state files
- Task queues
- Component status

## What Does NOT Belong Here

- Configuration → `config/`
- Logs → `logs/`
- Metrics → `metrics/`

---

*Jarvis — Pneuma Layer (Operational State)*
