---
argument-hint: <name> [--type TYPE] [--lang LANG] [--github]
description: Create a new code project in ~/Code and register with AIfred
skill: project-lifecycle
allowed-tools:
  - Bash(~/Scripts/new-code-project.sh:*)
  - Edit
---

# /new-code-project

Create a new code project using the `new-code-project.sh` script.

## Usage

```
/new-code-project <name> [--type TYPE] [--lang LANG] [--github]
```

## Execution

Run the script:

```bash
~/Scripts/new-code-project.sh $ARGUMENTS
```

After running, **manually update paths-registry.yaml** with the entry shown in the output.

## Options

| Flag | Values | Description |
|------|--------|-------------|
| `-t, --type` | web-app, api, cli, library, docker, other | Project type |
| `-l, --lang` | typescript, python, go, rust, etc. | Primary language |
| `-g, --github` | (flag) | Create private GitHub repo |

## Examples

```bash
/new-code-project my-api --type api --lang python
/new-code-project frontend-app --type web-app --lang typescript --github
/new-code-project my-tool --type cli
```

## What It Creates

**In ~/Code/<name>:**
```
<name>/
├── .git/
├── .claude/
│   └── CLAUDE.md
├── README.md
├── .gitignore
└── [type-specific files]
```

**In AIfred:**
- Context file: `.claude/context/projects/<name>.md`
- Registry entry: (manual update to paths-registry.yaml)

## Script Location

`~/Scripts/new-code-project.sh`

## Related

- Script: @Scripts/new-code-project.sh
- Pattern: @.claude/context/patterns/capability-layering-pattern.md
