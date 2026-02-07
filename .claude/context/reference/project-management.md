# Project Management Reference

**Version**: 1.0
**Status**: Active (on-demand reference)

---

## Core Principle

**Jarvis is a hub that orchestrates code projects stored elsewhere.**

Code lives in `projects_root` (typically `/Users/aircannon/Claude/Jarvis/projects`), not scattered through Jarvis.

---

## Automatic Project Detection

The `project-detector.js` hook automatically triggers when users mention:
- GitHub URLs
- "New project" phrases
- Clone requests

### Auto-Registration Flow

When an unregistered project is detected:

1. Clone to `projects_root` (from `paths-registry.yaml`)
2. Auto-detect language/type
3. Add to `paths-registry.yaml` under `development.projects`
4. Create context file at `.claude/context/projects/<name>.md`
5. Continue with user's original request

---

## Project Locations

| What | Where |
|------|-------|
| Code | `projects_root/<project>/` |
| Context/notes | `.claude/context/projects/<project>.md` |
| Registration | `paths-registry.yaml` → `development.projects` |

---

## Manual Registration

### New Project
```
/create-project <name>
```
Creates in `projects_root` with proper initialization (git, README, `CLAUDE.md`).

### Existing Project
```
/register-project <path-or-url>
```
Registers existing project, creates context file.

---

## Workspace Path Policy

Full details: @.claude/context/patterns/workspace-path-policy.md

Key rules:
- Code projects → `projects_root/`
- Context files → `.claude/context/projects/`
- External data → `external-sources/` (symlinked)

---

*Reference document — load on demand*
