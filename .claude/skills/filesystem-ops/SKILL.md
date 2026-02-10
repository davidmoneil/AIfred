---
name: filesystem-ops
model: haiku
version: 2.0.0
description: File and directory operations using built-in tools
replaces: mcp__filesystem (15 tools)
---

## Quick Reference

| Need | Tool | Example |
|------|------|---------|
| Read file | `Read` | Text, images, PDFs, notebooks |
| Write file | `Write` | Creates or overwrites |
| Edit file | `Edit` | String replacement |
| Find by name | `Glob` | `Glob("**/*.ts")` |
| Search content | `Grep` | `Grep("pattern", path)` |
| List dir | `Bash(ls -la)` | Pre-allowed |
| Dir tree | `Bash(tree -L 2)` | Pre-allowed |
| Create dir | `Bash(mkdir -p)` | Creates parents |
| Move/rename | `Bash(mv)` | Needs approval |
| File info | `Bash(stat)` | Size, dates, perms |

## Selection Rules

```
File op needed?
├── Read/Write/Edit content → Built-in tool (always)
├── Find files by name → Glob (always)
├── Search file contents → Grep (always)
└── Dir ops, move, stat → Bash (ls/mkdir/mv/stat)
```

Built-in tools work with any absolute path — no workspace restriction.
