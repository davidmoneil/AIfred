---
name: weather
model: haiku
version: 2.0.0
description: Weather via wttr.in API — no key required
replaces: Inline curl in session-start.sh
---

## Quick Reference

| Need | Command |
|------|---------|
| Current weather | `curl -s 'wttr.in/Salt+Lake+City?format=j1'` |
| Quick one-liner | `curl -s 'wttr.in/Salt+Lake+City?format=%t+%C+%h'` |
| Custom location | `curl -s 'wttr.in/CITY?format=j1'` |
| Parse JSON | `echo "$JSON" \| jq -r '.current_condition[0].temp_F'` |

## Config

| Variable | Default | Purpose |
|----------|---------|---------|
| `JARVIS_WEATHER_LOCATION` | `Salt+Lake+City` | Default location |
| `JARVIS_DISABLE_WEATHER` | `false` | Skip at startup |

Always use `--max-time 3` to avoid blocking. Auto-fetched at session start.
