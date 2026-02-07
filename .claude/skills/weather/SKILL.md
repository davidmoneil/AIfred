---
name: weather
version: 1.0.0
description: Weather information using wttr.in API - on-demand or at session start
category: infrastructure
tags: [weather, wttr, temperature, conditions, startup]
created: 2026-02-07
replaces: Inline curl in session-start.sh
---

# Weather Skill

Retrieve current weather conditions using the wttr.in API. No API key required.

---

## Quick Reference

| Need | Action |
|------|--------|
| Current weather | `Bash("curl -s 'wttr.in/Salt+Lake+City?format=j1'" \| jq)` |
| Weather for location | `Bash("curl -s 'wttr.in/CITY?format=j1'")` |
| Simple one-liner | `Bash("curl -s 'wttr.in/Salt+Lake+City?format=%t+%C+%h'")` |
| Disable at startup | Set `JARVIS_DISABLE_WEATHER=true` |

---

## Usage

### Full Weather Data (JSON)

```bash
WEATHER_JSON=$(curl -s --max-time 3 "wttr.in/Salt+Lake+City?format=j1")

# Parse fields
TEMP_F=$(echo "$WEATHER_JSON" | jq -r '.current_condition[0].temp_F')
FEELS_LIKE=$(echo "$WEATHER_JSON" | jq -r '.current_condition[0].FeelsLikeF')
DESCRIPTION=$(echo "$WEATHER_JSON" | jq -r '.current_condition[0].weatherDesc[0].value')
HUMIDITY=$(echo "$WEATHER_JSON" | jq -r '.current_condition[0].humidity')

echo "${TEMP_F}F (feels like ${FEELS_LIKE}F), ${DESCRIPTION}, ${HUMIDITY}% humidity"
```

### Quick Format

```bash
# One-line summary
curl -s "wttr.in/Salt+Lake+City?format=%t+%C+%h"
# Output: +45°F Partly cloudy 55%
```

### Custom Location

```bash
# By city name
curl -s "wttr.in/New+York?format=j1"

# By coordinates
curl -s "wttr.in/40.7,-111.9?format=j1"

# By airport code
curl -s "wttr.in/SLC?format=j1"
```

---

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `JARVIS_WEATHER_LOCATION` | `Salt+Lake+City` | Default location for weather queries |
| `JARVIS_DISABLE_WEATHER` | `false` | Set to `true` to skip weather at startup |

These are read by `session-start.sh` during Phase A (greeting).

---

## Session Start Integration

Weather is automatically fetched during session startup (source=startup only) and included in the greeting context. The hook at `.claude/hooks/session-start.sh` handles this:

1. Checks `JARVIS_DISABLE_WEATHER` env var
2. Calls `wttr.in` with 3-second timeout
3. Parses temperature, feels-like, description, humidity
4. Injects into greeting context

For on-demand weather during a session, use the curl commands above directly.

---

## API Notes

- **No API key required** — wttr.in is free and open
- **Rate limiting**: Be respectful, don't poll repeatedly
- **Timeout**: Always use `--max-time 3` to avoid blocking
- **Failure**: Silently ignored if fetch fails (non-critical)
- **Format options**: `j1` for JSON, `?format=` for custom format strings

---

*Extracted from session-start.sh inline curl — Skill-ified 2026-02-07*
