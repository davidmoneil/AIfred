# /create-project

Create a new project with proper structure and register it with Jarvis.

## Usage

```
/create-project <name> [--type <type>] [--language <lang>] [--github]
```

**Examples**:
```
/create-project my-new-api
/create-project dashboard --type web-app --language typescript
/create-project backup-scripts --type cli --language python
/create-project cool-tool --github  # Also create GitHub repo
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `name` | Yes | Project name (normalized to lowercase-with-dashes) |
| `--type` | No | Project type: web-app, api, library, cli, docker, other |
| `--language` | No | Primary language: typescript, python, go, rust, etc. |
| `--github` | No | Also create GitHub repository under CannonCoPilot |

---

## Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Validate name (normalize to lowercase-with-dashes)          │
│ 2. Create project at /Users/aircannon/Claude/<name>/           │
│ 3. Initialize project structure                                 │
│ 4. Create project's own CLAUDE.md (project root)                │
│ 5. Update paths-registry.yaml                                   │
│ 6. Create project summary in Jarvis/projects/                   │
│ 7. Optionally create GitHub repo and push                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## What It Does

### 1. Creates Project Directory

Per workspace-path-policy (PR-1.E), project code goes in the projects root:

```bash
# NOT in Jarvis!
mkdir -p /Users/aircannon/Claude/my-new-project
cd /Users/aircannon/Claude/my-new-project
```

### 2. Initializes Project Structure

**Default structure (any type)**:
```
my-new-project/
├── .git/                    # git init
├── .claude/
│   └── CLAUDE.md            # Project-specific instructions
├── README.md                # Basic readme
└── .gitignore               # Language-appropriate ignores
```

**Type-specific additions**:

| Type | Additional Files |
|------|------------------|
| `web-app` | package.json, src/, public/, vite.config.js |
| `api` | package.json or requirements.txt, src/, tests/ |
| `cli` | src/, bin/, setup.py or package.json |
| `library` | src/, tests/, docs/ |
| `docker` | docker-compose.yml, Dockerfile |

### 3. Creates Project's CLAUDE.md

In the new project (not Jarvis):

```markdown
# [Project Name]

**Type**: [type]
**Language**: [language]
**Created**: [date]
**Managed By**: Jarvis (Project Aion)

## Purpose

[To be filled in]

## Quick Commands

[Based on type]

## Notes

[To be filled in]
```

### 4. Updates paths-registry.yaml

```yaml
development:
  projects:
    my-new-project:
      path: "/Users/aircannon/Claude/my-new-project"
      type: "api"
      language: "typescript"
      status: "active"
      created: "2026-01-05"
      summary_file: "projects/my-new-project.md"
```

### 5. Creates Project Summary in Jarvis

Creates `/Users/aircannon/Claude/Jarvis/projects/<name>.md` using the template from `knowledge/templates/project-summary.md`.

### 6. Optional GitHub Setup

If `--github` flag or user confirms:

```bash
# Create repo under CannonCoPilot
gh repo create CannonCoPilot/my-new-project --public --source=. --push
```

---

## Path Policy (PR-1.E)

Per the workspace-path-policy:

| What | Where |
|------|-------|
| Project code | `/Users/aircannon/Claude/<project-name>/` |
| Project's CLAUDE.md | `/Users/aircannon/Claude/<project-name>/CLAUDE.md` |
| Project summary (in Jarvis) | `/Users/aircannon/Claude/Jarvis/projects/<project-name>.md` |
| Registry | `paths-registry.yaml` → `development.projects` |

**Key principle**: Jarvis creates and orchestrates projects stored elsewhere. Project code lives at the projects root, NOT inside Jarvis.

---

## Naming Conventions

Project names are normalized:
- Lowercase
- Spaces become dashes
- Special characters removed
- Maximum 50 characters

```
"My New Project" → "my-new-project"
"API_Service_v2" → "api-service-v2"
```

---

## Validation

After creation, verify:
1. Project directory exists at `/Users/aircannon/Claude/<name>/`
2. Project has `.git/` initialized
3. Project has `CLAUDE.md` (project root)
4. Project appears in `paths-registry.yaml`
5. Summary exists at `Jarvis/projects/<name>.md`

```bash
# Quick validation
ls -la /Users/aircannon/Claude/my-new-project/
cat /Users/aircannon/Claude/my-new-project/CLAUDE.md
cat paths-registry.yaml | grep -A5 "my-new-project"
ls projects/my-new-project.md
```

---

## Related Commands

- `/register-project` — Register an existing project with Jarvis
- `/list-projects` — Show all registered projects
- `/project-status` — Show status of a specific project

---

*Jarvis Project Creation — Per workspace-path-policy (PR-1.E)*
