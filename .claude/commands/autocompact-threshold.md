---
description: Set the JICM auto-compact threshold (token count)
allowed-tools: Read, Edit
---

# Auto-Compact Threshold

Set the context compression threshold for JICM (AC-04). When context usage exceeds this threshold, the watcher triggers intelligent compression.

## Usage

```
/autocompact-threshold <tokens>
```

## Arguments

- `$ARGUMENTS` — Token count threshold (e.g., `130000`, `80000`, `30000`)

## Valid Ranges

| Value | Description |
|-------|-------------|
| 30000 | Testing (very frequent compression) |
| 80000 | Aggressive (40% of ~200k context) |
| 100000 | Moderate (50% of context) |
| 130000 | **Default** (65% of context) |
| 150000 | Conservative (75% of context) |

## Execution

**Step 1**: Validate the argument

```
THRESHOLD=$ARGUMENTS
```

If no argument provided or invalid (not a number between 10000-180000):
- Report current threshold from `.claude/config/autonomy-config.yaml` (line ~79)
- Ask user for a valid value

**Step 2**: Update the config file

Edit `.claude/config/autonomy-config.yaml`:
- Find the line containing `threshold_tokens:`
- Replace the value with the new threshold
- Preserve the comment if present

**Step 3**: Confirm the change

Report:
- Previous threshold
- New threshold
- When it takes effect (immediately for new sessions, watcher reads config on each check)

## Example

User: `/autocompact-threshold 100000`

Response:
1. Read current value from config
2. Edit config to set `threshold_tokens: 100000`
3. Say: "JICM threshold updated: 30000 → 100000 tokens. Takes effect on next context check."

## Notes

- Changes are immediate for the watcher (reads config on each check)
- Original default is 130000 (65% of context)
- Current value is noted in config comments

## Related

- `/context` — Check current context usage
- `/auto-compact` — Trigger compression manually
- `/intelligent-compress` — Run JICM compression directly
