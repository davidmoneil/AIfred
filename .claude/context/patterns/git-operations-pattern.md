# Git Operations Pattern

**Purpose**: Standardize git operations for session management and automation.

**Created**: 2026-01-01
**Last Updated**: 2026-01-01

---

## When to Apply

Use this pattern when:
- Ending a session with uncommitted changes
- Setting up GitHub integration
- Automating git push operations
- Managing credentials for remote operations

---

## Pattern: Branch-Aware Push

### Problem

The original end-session workflow hardcoded `git push origin main`, which:
- Fails on feature branches
- Doesn't validate authentication
- Doesn't check if push is needed
- Doesn't handle failures gracefully

### Solution

**Before pushing**, execute these checks:

```bash
# 1. Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# 2. Check if branch has remote tracking
if ! git rev-parse --abbrev-ref @{u} &>/dev/null; then
  echo "Branch has no remote tracking. Set up with:"
  echo "git push -u origin $CURRENT_BRANCH"
fi

# 3. Check if push is needed
if git status | grep -q "Your branch is ahead"; then
  # Push needed
  git push origin $CURRENT_BRANCH
elif git status | grep -q "Your branch is up to date"; then
  # No push needed
  echo "Already up to date with remote"
fi
```

### Implementation

Update end-session to use branch-aware logic:

```markdown
### 5. GitHub Push (If Applicable)

Check and push current branch:
- Detect current branch automatically
- Validate remote tracking exists
- Only push if ahead of remote
- Handle authentication failures
```

---

## Pattern: Credential Management

### Problem

GitHub authentication requires:
- Username and PAT (Personal Access Token)
- Storage for reuse
- Security (not committed to repo)
- Cross-session persistence

### Solution: Three-Tier Approach

#### Tier 1: macOS Keychain (Preferred)

Git automatically uses keychain if configured:

```bash
git config --global credential.helper osxkeychain
```

On first push, git will prompt and store in keychain.

#### Tier 2: Environment Variables (Fallback)

Store in `.env` file (gitignored):

```bash
GITHUB_USERNAME=YourUsername
GITHUB_TOKEN=ghp_xxxxxxxxxxxxx
GITHUB_PAT=ghp_xxxxxxxxxxxxx
```

Reference in git operations:

```bash
git push https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/user/repo.git
```

#### Tier 3: Git Credential Store (Not Recommended)

Stores plaintext in `~/.git-credentials`. Avoid unless necessary.

### Best Practice

1. **Setup**: Configure keychain helper
2. **Backup**: Store credentials in `.env` (gitignored)
3. **Validate**: Test push before end-session
4. **Document**: Note auth method in paths-registry.yaml

---

## Pattern: Pre-Push Validation

### Problem

Push failures discovered during end-session disrupt workflow.

### Solution: Validate Early

Add to session-start checklist:

```bash
# Check git remote connectivity
git ls-remote origin &>/dev/null && echo "✅ Git remote accessible" || echo "❌ Git authentication needed"
```

If authentication needed, configure before starting work.

---

## Pattern: .gitignore for Secrets

### Problem

Accidentally committing `.env` files with tokens.

### Solution: Proactive Gitignore

**Always** ensure `.gitignore` includes:

```gitignore
# Environment variables (contains secrets)
.env
.env.*
.env.local
.env.*.local

# Git credentials
.git-credentials

# OS keychain backups
*.keychain
```

**Validation**: Before committing .env creation:

```bash
git check-ignore -v .env
# Should output: .gitignore:X:.env    .env
```

---

## Integration with End-Session

### Updated Workflow

```markdown
### 4. Git Operations

1. **Status Check**
   ```bash
   git status
   ```

2. **Commit Changes** (if any)
   ```bash
   git add -A
   git commit -m "Session: [description]"
   ```

3. **Branch Detection**
   ```bash
   CURRENT_BRANCH=$(git branch --show-current)
   echo "Current branch: $CURRENT_BRANCH"
   ```

4. **Remote Tracking Check**
   ```bash
   if ! git rev-parse --abbrev-ref @{u} &>/dev/null; then
     git push -u origin $CURRENT_BRANCH
   fi
   ```

5. **Push (if needed)**
   ```bash
   if git status | grep -q "ahead"; then
     git push origin $CURRENT_BRANCH
   else
     echo "✅ Already synced with remote"
   fi
   ```

6. **Handle Failures**
   - If auth fails: Guide to credential setup
   - If rejected: Suggest pull/rebase
   - If no remote: Suggest adding remote
```

---

## Quick Reference

| Scenario | Command |
|----------|---------|
| First-time push | `git push -u origin $(git branch --show-current)` |
| Subsequent push | `git push` |
| Check if push needed | `git status \| grep ahead` |
| Validate credentials | `git ls-remote origin` |
| Store in keychain | `git config --global credential.helper osxkeychain` |

---

## Checklist: Setting Up Git Integration

- [ ] Configure credential helper: `git config --global credential.helper osxkeychain`
- [ ] Create `.env` with `GITHUB_USERNAME` and `GITHUB_TOKEN`
- [ ] Add `.env` to `.gitignore`
- [ ] Validate ignore: `git check-ignore -v .env`
- [ ] Test push: `git ls-remote origin`
- [ ] Document in `paths-registry.yaml` under `github` section

---

## Related Patterns

- [Session Exit Workflow](../workflows/session-exit.md)
- [Memory Storage Pattern](memory-storage-pattern.md)

---

**Last Session Issue**: 2026-01-01 - Branch not pushed (fixed with this pattern)
