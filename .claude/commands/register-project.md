---
argument-hint: <path-or-github-url>
description: Register an existing project with AIfred
skill: project-lifecycle
allowed-tools:
  - Bash(~/Scripts/register-project.sh:*)
  - Edit
---

# /register-project

Register an existing project using `register-project.sh`.

## Usage

```
/register-project <path-or-github-url>
```

## Execution

Run the script:

```bash
~/Scripts/register-project.sh $ARGUMENTS
```

After running, **manually update paths-registry.yaml** with the entry shown in the output.

## Examples

```bash
/register-project ~/Code/existing-project
/register-project github.com/user/some-repo
/register-project https://github.com/user/repo
```

## What It Does

### For Local Projects
1. Verifies path exists
2. Auto-detects language (package.json → TS, requirements.txt → Python, etc.)
3. Auto-detects type (docker-compose → docker, next.config → web-app, etc.)
4. Creates context file in `.claude/context/projects/`
5. Outputs registry entry for manual addition

### For GitHub URLs
1. Parses repo name from URL
2. Clones to `~/Code/<repo-name>`
3. Auto-detects language and type
4. Creates context file
5. Outputs registry entry

## Auto-Detection

| File | Language |
|------|----------|
| `package.json` + `tsconfig.json` | TypeScript |
| `package.json` | JavaScript |
| `requirements.txt` / `pyproject.toml` | Python |
| `go.mod` | Go |
| `Cargo.toml` | Rust |

| File | Type |
|------|------|
| `docker-compose.yml` | docker |
| `next.config.*` / `vite.config.*` | web-app |
| `setup.py` / `pyproject.toml` | library |
| `bin/` directory | cli |

## Script Location

`~/Scripts/register-project.sh`

## Related

- Script: @Scripts/register-project.sh
- `/new-code-project` - Create new project from scratch
- Pattern: @.claude/context/patterns/capability-layering-pattern.md
