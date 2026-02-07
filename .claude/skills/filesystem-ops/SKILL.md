---
name: filesystem-ops
version: 1.0.0
description: File and directory operations using built-in tools instead of filesystem MCP
category: infrastructure
tags: [files, directories, read, write, search, built-in]
created: 2026-02-07
replaces: mcp__filesystem (15 tools)
---

# Filesystem Operations Skill

Maps all 15 filesystem MCP tools to built-in equivalents. Use built-in tools for all file operations — they are faster, lower-cost, and always available.

---

## Quick Reference

| Need | Built-in Tool | Example |
|------|--------------|---------|
| Read a file | `Read` | `Read("/path/to/file.txt")` |
| Read an image/PDF | `Read` | `Read("/path/to/image.png")` — multimodal |
| Read multiple files | Parallel `Read` calls | Multiple `Read` in one response |
| Write a file | `Write` | `Write("/path/to/file.txt", content)` |
| Edit a file | `Edit` | `Edit("/path/to/file.txt", old, new)` |
| Search by filename | `Glob` | `Glob("**/*.ts")` |
| Search file contents | `Grep` | `Grep("pattern", path)` |
| List directory | `Bash(ls -la)` | `Bash("ls -la /path/to/dir")` |
| List with sizes | `Bash(ls -lah)` | `Bash("ls -lah /path/to/dir")` |
| Directory tree | `Bash(tree)` | `Bash("tree /path -L 2")` |
| Create directory | `Bash(mkdir -p)` | `Bash("mkdir -p /path/to/dir")` |
| File info (size, dates) | `Bash(stat)` | `Bash("stat /path/to/file")` |
| Move/rename file | `Bash(mv)` | `Bash("mv /old/path /new/path")` |

---

## Tool Mapping (MCP → Built-in)

| MCP Tool | Built-in Replacement | Notes |
|----------|---------------------|-------|
| `read_file` | `Read` | Works with text, images, PDFs, notebooks |
| `read_text_file` | `Read` | Same as above |
| `read_media_file` | `Read` | Claude is multimodal — images render visually |
| `read_multiple_files` | Parallel `Read` calls | Issue multiple Read calls in one message |
| `write_file` | `Write` | Tracks changes, works with absolute paths |
| `edit_file` | `Edit` | Context-aware string replacement |
| `create_directory` | `Bash(mkdir -p)` | `-p` creates parent dirs |
| `list_directory` | `Bash(ls -la)` | Or `Glob` for pattern-based listing |
| `list_directory_with_sizes` | `Bash(ls -lah)` | Human-readable sizes |
| `directory_tree` | `Bash(tree -L N)` | Control depth with `-L` |
| `search_files` | `Glob` | Pattern-based file search |
| `get_file_info` | `Bash(stat)` | Size, permissions, timestamps |
| `move_file` | `Bash(mv)` | Move or rename |
| `list_allowed_directories` | N/A | Not needed — built-in tools work with absolute paths |

---

## Cross-Workspace Access

Built-in `Read` and `Write` work with **any absolute path** — no workspace restriction. The filesystem MCP was configured with specific allowed directories:

- `/Users/aircannon/Claude/Jarvis`
- `/Users/aircannon/Claude/Projects`
- `/Users/aircannon/Claude/AIfred`
- `/Users/aircannon/Claude/GitRepos`
- `/Users/aircannon/Claude/gptr-mcp`
- `/Users/aircannon/Claude/aion-hello-console-2026-01-18`

Built-in tools access all of these directly via absolute paths. No MCP configuration needed.

---

## Selection Rules

```
File operation needed?
├── Read file content → Read (always)
├── Write new file → Write (always)
├── Edit existing file → Edit (always)
├── Find files by name → Glob (always)
├── Search file contents → Grep (always)
├── Directory listing → Bash(ls)
├── Create directory → Bash(mkdir -p)
├── Move/rename → Bash(mv)
└── File metadata → Bash(stat)
```

**Never use the filesystem MCP when a built-in tool can do the job.** Built-in tools are faster, have zero token overhead for tool definitions, and are always available.

---

*Replaces: @modelcontextprotocol/server-filesystem (15 tools) — Phagocytosed 2026-02-07*
