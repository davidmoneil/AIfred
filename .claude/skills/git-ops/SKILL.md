---
name: git-ops
version: 1.0.0
description: Git operations using Bash commands instead of git MCP server
category: infrastructure
tags: [git, version-control, commit, push, branch, built-in]
created: 2026-02-07
replaces: mcp__git (12 tools)
---

# Git Operations Skill

Maps all 12 git MCP tools to `Bash(git ...)` commands. Git operations via Bash are simpler, faster, and pre-allowed in settings.

---

## Quick Reference

| Need | Command | Pre-allowed |
|------|---------|------------|
| Check status | `Bash("git status")` | Yes |
| View log | `Bash("git log --oneline -10")` | Yes |
| View diff | `Bash("git diff")` | Yes |
| Show commit | `Bash("git show HEAD")` | Yes |
| List branches | `Bash("git branch -a")` | Yes |
| Switch branch | `Bash("git checkout branch-name")` | No — needs approval |
| Create branch | `Bash("git checkout -b new-branch")` | No — needs approval |
| Stage files | `Bash("git add file1 file2")` | No — needs approval |
| Commit | `Bash("git commit -m '...'")` | No — needs approval |
| Push | See Push Workflow below | No — needs approval |
| Fetch | `Bash("git fetch")` | Yes |
| Reset | `Bash("git reset ...")` | No — DANGEROUS |

---

## Tool Mapping (MCP → Built-in)

| MCP Tool | Built-in Replacement | Notes |
|----------|---------------------|-------|
| `git_status` | `Bash("git status")` | Pre-allowed |
| `git_log` | `Bash("git log")` | Pre-allowed |
| `git_diff` | `Bash("git diff")` | Pre-allowed, staged + unstaged |
| `git_diff_staged` | `Bash("git diff --staged")` | Pre-allowed |
| `git_diff_unstaged` | `Bash("git diff")` | Pre-allowed |
| `git_show` | `Bash("git show REF")` | Pre-allowed |
| `git_branch` | `Bash("git branch -a")` | Pre-allowed |
| `git_checkout` | `Bash("git checkout REF")` | Needs approval |
| `git_create_branch` | `Bash("git checkout -b NAME")` | Needs approval |
| `git_add` | `Bash("git add FILE...")` | Needs approval |
| `git_commit` | `Bash("git commit -m '...'")` | Needs approval |
| `git_reset` | `Bash("git reset ...")` | DANGEROUS — confirm first |

---

## Pre-Allowed Commands

These git commands are auto-approved in `~/.claude/settings.json`:

```
git status, git log, git diff, git branch,
git fetch, git remote, git rev-parse, git show, git tag
```

All other git commands (add, commit, checkout, push, reset) require user approval.

---

## Safety Patterns

### NEVER
- Force push to main/master (`git push --force origin main`)
- Use `git reset --hard` without explicit user request
- Skip hooks with `--no-verify`
- Use `-i` flag (interactive mode not supported in CLI)

### ALWAYS
- Stage specific files by name (not `git add -A` or `git add .`)
- Use HEREDOC for commit messages:
```bash
git commit -m "$(cat <<'EOF'
Commit message here.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```
- Confirm before destructive operations

---

## Push Workflow

Push requires PAT authentication. Use the credential store:

```bash
PAT=$(yq -r '.github.aifred_token' .claude/secrets/credentials.yaml | head -1 | tr -d '[:space:]')
git remote set-url origin "https://CannonCoPilot:${PAT}@github.com/davidmoneil/AIfred.git"
git push origin Project_Aion
```

**Credential store**: `.claude/secrets/credentials.yaml` (gitignored, chmod 600)
**yq gotcha**: File has `---` document separator — always pipe through `head -1`

---

## Commit Workflow

1. Check status: `git status` (see untracked + modified)
2. Check diff: `git diff` (review changes)
3. Check recent commits: `git log --oneline -5` (match style)
4. Stage specific files: `git add file1.md file2.sh`
5. Commit with HEREDOC message
6. Verify: `git status` (confirm clean)

---

*Replaces: mcp-server-git (12 tools) — Phagocytosed 2026-02-07*
