---
name: git-ops
version: 2.0.0
description: Git operations using Bash commands instead of git MCP server
replaces: mcp__git (12 tools)
---

## Quick Reference

| Need | Command | Pre-allowed |
|------|---------|------------|
| Status | `git status` | Yes |
| Log | `git log --oneline -10` | Yes |
| Diff | `git diff` | Yes |
| Show | `git show HEAD` | Yes |
| Branches | `git branch -a` | Yes |
| Fetch | `git fetch` | Yes |
| Checkout | `git checkout <ref>` | No |
| Stage | `git add <files>` | No |
| Commit | HEREDOC pattern below | No |
| Push | PAT workflow below | No |

## Commit Pattern

```bash
git commit -m "$(cat <<'EOF'
Message here.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

## Push Workflow

```bash
PAT=$(yq -r '.github.aifred_token' .claude/secrets/credentials.yaml | head -1 | tr -d '[:space:]')
git remote set-url origin "https://CannonCoPilot:${PAT}@github.com/davidmoneil/AIfred.git"
git push origin Project_Aion
```

Safety rules: see CLAUDE.md guardrails. Stage specific files, never force-push main.
