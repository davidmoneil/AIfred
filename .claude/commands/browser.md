---
description: Run browser automation in isolated Claude session (saves ~15k context tokens)
argument-hint: <task-description>
standalone: true
note: Requires Playwright MCP setup (optional integration - configure in Phase 8 of /setup)
allowed-tools:
  - Task
---

# Browser Automation Task

**Task**: $ARGUMENTS

**Note**: This command requires Playwright MCP to be configured. If not set up, run `/setup` and enable browser automation in the Optional Integrations phase.

## Execute

Run this command to spawn an isolated browser session:

```bash
claude \
  --mcp-config ~/.claude/mcp-profiles/browser.json \
  --settings ~/.claude/mcp-profiles/browser-settings.json \
  -p "You are a browser automation specialist with Playwright MCP tools.

TASK: $ARGUMENTS

INSTRUCTIONS:
1. Use browser_navigate to go to URLs
2. Use browser_snapshot to see page structure (preferred over screenshots for interaction)
3. Use browser_take_screenshot to capture visual state
4. Save screenshots to /tmp/ with descriptive names
5. Use browser_close when done

OUTPUT FORMAT:
- What you did (step by step)
- Results/findings
- Any screenshots saved (with paths)
- Errors encountered (if any)" \
  --output-format text 2>&1 | tee /tmp/browser-task-result.txt
```

After running, the results are in `/tmp/browser-task-result.txt`.

## Why Isolated?

Playwright MCP tools consume ~15k tokens. This approach:
- Keeps main session lean
- Browser agent gets dedicated context
- Results return as text summary

## Examples

- `Take a screenshot of https://example.com`
- `Check if the login form at localhost:3000 works`
- `Extract all links from https://news.ycombinator.com`
- `Verify the mobile responsive layout of my site`
