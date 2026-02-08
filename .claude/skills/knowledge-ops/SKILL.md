---
name: knowledge-ops
version: 1.0.0
description: >
  Knowledge graph, memory, reflection, and vector search.
  Use when: memory, remember, knowledge graph, reflect, lotus, obsidian, RAG.
replaces: memory MCP (shadow), lotus-wisdom MCP
---

## Quick Reference

| Backend | Method | Notes |
|---------|--------|-------|
| Memory graph (read) | `Read ~/.claude/memory/memory.json` then `jq` | Entities, relations, observations |
| Memory graph (write) | `Bash(jq)` + `Write` on memory.json | Add/update/delete entities |
| Memory search | `Grep "pattern" ~/.claude/memory/memory.json` | Fast text search |
| Memory MCP (fallback) | `ToolSearch "+memory"` then use tools | 9 tools, deferred |
| Local RAG query | `ToolSearch "+local-rag"` then query_documents | Vector similarity search |
| Local RAG ingest | `ToolSearch "+local-rag"` then ingest_file | Add docs to vector DB |

## Memory JSON Operations

```bash
# List all entities
jq '.entities[].name' ~/.claude/memory/memory.json

# Find entity by name
jq '.entities[] | select(.name == "NAME")' ~/.claude/memory/memory.json

# Add observation (use Write after jq transform)
jq '.entities[] |= if .name == "NAME" then .observations += ["new fact"] else . end' \
  ~/.claude/memory/memory.json > /tmp/mem.json && mv /tmp/mem.json ~/.claude/memory/memory.json
```

## Lotus Wisdom Patterns (AC-05/06)

Contemplative reflection for self-improvement cycles:

| Pattern | Use When |
|---------|----------|
| `examine` | Analyzing a decision or outcome |
| `reflect` | End-of-session self-assessment |
| `verify` | Validating assumptions or approaches |
| `transform` | Changing behavior based on learning |
| `integrate` | Combining insights across sessions |

Invoke via `/reflect` or `/self-improve` commands (self-improvement skill).

## Selection Rules

```
Knowledge needed?
├── Store/recall facts → Memory JSON (direct jq)
├── Semantic search → local-rag (ToolSearch)
├── Self-reflection → Lotus patterns via /reflect
├── Session lessons → self-correction-capture hook (auto)
└── Obsidian vault → Read/Glob on vault path (future)
```
