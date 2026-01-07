---
name: commits:push-all
description: Push all unpushed commits across tracked projects
usage: /commits:push-all [--dry-run] [--project <name>]
category: workflow
created: 2026-01-06
---

# Push All Unpushed Commits

Checks all tracked projects for unpushed commits and pushes them to their remotes.

## Usage

```
/commits:push-all              # Push all unpushed across all projects
/commits:push-all --dry-run    # Show what would be pushed (no action)
/commits:push-all --project my-project  # Push only specific project
```

## Output Example

```
┌─────────────────────────────────────────────────────────────┐
│ PUSH ALL UNPUSHED COMMITS                                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│ Checking tracked projects...                                │
│                                                              │
│ ✅ MainProject                                               │
│    └─ 2 commits pushed to origin/main                       │
│                                                              │
│ ✅ api-service                                               │
│    └─ 4 commits pushed to origin/main                       │
│                                                              │
│ ⏭️  Docker                                                   │
│    └─ Already up to date                                    │
│                                                              │
│ ⏭️  frontend-app                                             │
│    └─ Already up to date                                    │
│                                                              │
│ ❌ new-project                                               │
│    └─ Error: No upstream configured                         │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│ Summary: 6 pushed, 2 up-to-date, 1 error                    │
└─────────────────────────────────────────────────────────────┘
```

## Execution Steps

1. **Get tracked projects** from tracking file:
   ```bash
   cat .claude/logs/cross-project-commits.json | jq -r '.sessions[].projects | keys[]' | sort -u
   ```

2. **For each project, check unpushed commits**:
   ```bash
   git -C <project-path> log --oneline @{u}..HEAD 2>/dev/null
   ```

3. **If commits exist and not --dry-run, push**:
   ```bash
   git -C <project-path> push origin $(git -C <project-path> branch --show-current)
   ```

4. **Report results**:
   - ✅ Pushed successfully
   - ⏭️ Already up to date
   - ❌ Error (no upstream, auth failure, etc.)

## Safety Features

- **--dry-run**: Shows what would be pushed without pushing
- **Branch check**: Only pushes current branch
- **Remote check**: Skips if no upstream configured
- **Error handling**: Reports failures without stopping

## Quick Check (Manual)

```bash
# Check unpushed across tracked projects
for repo in ~/Projects ~/Docker ~/Code/*; do
  if [ -d "$repo/.git" ]; then
    echo "=== $repo ==="
    git -C "$repo" log --oneline @{u}..HEAD 2>/dev/null || echo "(no upstream)"
  fi
done
```

## Integration

**Use at session end**:
1. Run `/commits:status` to review
2. Run `/commits:push-all --dry-run` to verify
3. Run `/commits:push-all` to push

**Related Commands**:
- `/commits:status` - View commits before pushing
- `/commits:summary` - Generate summary after pushing
