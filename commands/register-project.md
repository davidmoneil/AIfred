# /register-project

Register an existing project with Jarvis so it can track and assist with it.

## Usage

```
/register-project <path-or-url> [--type <type>] [--language <lang>]
```

**Examples**:
```
/register-project ~/Code/my-app
/register-project /Users/aircannon/Claude/SomeProject
/register-project https://github.com/user/repo
/register-project ~/Code/api --type api --language python
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `path-or-url` | Yes | Path to existing project OR GitHub URL to clone |
| `--type` | No | Project type: web-app, api, library, cli, docker, other |
| `--language` | No | Primary language (auto-detected if not specified) |

---

## Workflow

### If Path Provided

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Validate path exists                                         │
│ 2. Auto-detect project properties                               │
│ 3. Gather missing info from user                                │
│ 4. Update paths-registry.yaml                                   │
│ 5. Create project summary in Jarvis/projects/                   │
│ 6. Optionally create detailed context file                      │
└─────────────────────────────────────────────────────────────────┘
```

### If GitHub URL Provided

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Parse GitHub URL for repo name                               │
│ 2. Clone to: /Users/aircannon/Claude/<repo-name>/               │
│ 3. Auto-detect project properties                               │
│ 4. Update paths-registry.yaml                                   │
│ 5. Create project summary in Jarvis/projects/                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## What It Does

### 1. Validates Project

For paths:
```bash
[ -d "$path" ] || error "Directory not found"
```

For GitHub URLs:
```bash
# Clone to projects_root per workspace-path-policy
git clone https://github.com/user/repo /Users/aircannon/Claude/repo
```

### 2. Auto-Detects Project Properties

**Language detection**:
```bash
[ -f "package.json" ] && language="javascript/typescript"
[ -f "requirements.txt" ] && language="python"
[ -f "go.mod" ] && language="go"
[ -f "Cargo.toml" ] && language="rust"
```

**Type detection**:
```bash
[ -f "docker-compose.yml" ] && type="docker"
[ -d "src" ] && [ -f "package.json" ] && type="web-app"
```

### 3. Updates paths-registry.yaml

```yaml
development:
  projects:
    my-app:
      path: "/Users/aircannon/Claude/my-app"
      type: "web-app"
      language: "typescript"
      repo: "github.com/user/my-app"
      status: "active"
      registered: "2026-01-05"
      summary_file: "projects/my-app.md"
```

### 4. Creates Project Summary

Creates `/Users/aircannon/Claude/Jarvis/projects/<name>.md` using the template from `knowledge/templates/project-summary.md`.

This summary:
- Lives in Jarvis (not the project)
- Provides quick reference info
- Tracks session notes and decisions
- Links to the actual project location

### 5. Optionally Creates Context File

If detailed documentation is needed, also creates `.claude/context/projects/<name>.md` for in-depth notes.

---

## Path Policy (PR-1.E)

Per the workspace-path-policy:

| What | Where |
|------|-------|
| Project code | `/Users/aircannon/Claude/<project-name>/` |
| Project summary | `/Users/aircannon/Claude/Jarvis/projects/<project-name>.md` |
| Detailed context | `.claude/context/projects/<project-name>.md` (optional) |
| Registry | `paths-registry.yaml` → `development.projects` |

**Key principle**: Jarvis is a hub that orchestrates projects stored elsewhere. It does NOT contain project code within itself.

---

## Special Cases

### Registering AIfred Baseline

The AIfred baseline at `/Users/aircannon/Claude/AIfred` should NOT be registered as a normal project. It's tracked separately in `paths-registry.yaml` under `aifred_baseline` as a read-only reference.

### Registering Jarvis Itself

Jarvis (Project Aion) documentation lives at:
- `projects/project-aion/` — All evolution documentation (roadmap, plans, ideas)
- `.claude/context/` — Behavioral patterns and standards

This is already configured and doesn't need /register-project.

---

## Validation

After registration, verify:
1. Project appears in `paths-registry.yaml`
2. Summary exists at `Jarvis/projects/<name>.md`
3. Project path is accessible

```bash
# Quick validation
cat paths-registry.yaml | grep -A5 "my-app"
ls projects/my-app.md
```

---

## Related Commands

- `/create-project` — Create a new project from scratch
- `/list-projects` — Show all registered projects
- `/unregister-project` — Remove project from Jarvis tracking

---

*Jarvis Project Registration — Per workspace-path-policy (PR-1.E)*
