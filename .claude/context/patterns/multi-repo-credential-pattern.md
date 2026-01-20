# Multi-Repository Credential Management Pattern

**Created**: 2026-01-20
**Purpose**: Manage git credentials across multiple repositories with different owners and access levels

---

## Overview

Jarvis operates across multiple git repositories with different authentication requirements:

| Repository | Owner | Access Level | Branch Rules |
|------------|-------|--------------|--------------|
| AIfred (baseline) | davidmoneil | Read/Write via CannonCoPilot PAT | main=read-only, Project_Aion=read/write |
| aion-hello-console-* | CannonCoPilot | Full access | All branches writable |
| Future project repos | CannonCoPilot | Full access | Per-project rules |

---

## Credential Storage Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CREDENTIAL HIERARCHY                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. Repository-Embedded Credentials (highest priority)              │
│     └── PAT in remote URL: https://user:PAT@github.com/...         │
│     └── Used for: Ephemeral project repos                           │
│                                                                      │
│  2. Git Credential Contexts (per-path)                              │
│     └── credential.https://github.com/davidmoneil.helper            │
│     └── Used for: Multi-owner scenarios                             │
│                                                                      │
│  3. Global Credential Helper (lowest priority)                      │
│     └── osxkeychain (macOS) / credential-manager (Windows)          │
│     └── Used for: Default fallback                                  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## PAT Requirements

### CannonCoPilot PAT for AIfred Access

The PAT stored in osxkeychain must have these scopes:
- `repo` (Full control of private repositories)
- Access to `davidmoneil/AIfred` as a collaborator

**Verification**:
```bash
# Test read access
git ls-remote https://github.com/davidmoneil/AIfred.git

# Test write access (dry-run)
git push --dry-run origin Project_Aion
```

### PAT for CannonCoPilot Repos

Same PAT can be used, or a separate one with:
- `repo` scope for CannonCoPilot-owned repos

---

## Configuration Methods

### Method 1: File-Based Credentials (Recommended for Jarvis)

Store credentials in `.claude/secrets/credentials.yaml` (gitignored):

```yaml
# .claude/secrets/credentials.yaml
github:
  cannoncopilot_pat: "github_pat_..."  # For CannonCoPilot repos
  aifred_pat: "ghp_..."                 # For davidmoneil/AIfred
```

**Configure git remote with embedded PAT**:
```bash
# Read PAT from credentials file
PAT=$(yq '.github.aifred_pat' .claude/secrets/credentials.yaml)

# Set remote URL with embedded credentials
git remote set-url origin "https://CannonCoPilot:${PAT}@github.com/davidmoneil/AIfred.git"
```

**Advantages**:
- No OS-level keychain dependency
- Credentials tracked in one location
- Easy to switch between repos

### Method 2: Single PAT with Multi-Repo Access (Alternative)

Store one PAT in osxkeychain that has access to all needed repos:

```bash
# Clear existing credential
git credential-osxkeychain erase <<EOF
protocol=https
host=github.com
EOF

# Store new credential (will prompt for PAT)
git credential-osxkeychain store <<EOF
protocol=https
host=github.com
username=CannonCoPilot
password=ghp_YOUR_PAT_HERE
EOF
```

**PAT Requirements**:
- Must be granted collaborator access to davidmoneil/AIfred
- Must have `repo` scope

### Method 2: Credential Contexts (Per-Owner)

Configure different credentials per GitHub path:

```bash
# For davidmoneil repos
git config --global credential.https://github.com/davidmoneil.helper osxkeychain
git config --global credential.https://github.com/davidmoneil.username CannonCoPilot

# For CannonCoPilot repos
git config --global credential.https://github.com/CannonCoPilot.helper osxkeychain
git config --global credential.https://github.com/CannonCoPilot.username CannonCoPilot
```

### Method 3: Repository-Specific Credentials (Not Recommended)

Embed PAT in remote URL (security risk - PAT visible in configs):

```bash
# Only for ephemeral/temporary repos
git remote set-url origin https://CannonCoPilot:PAT@github.com/owner/repo.git
```

---

## Branch Protection Rules

### AIfred Repository

| Branch | Rule | Enforcement |
|--------|------|-------------|
| `main` | READ-ONLY | Never push directly; Jarvis must refuse |
| `Project_Aion` | Read/Write | Normal push allowed |
| Other branches | Read/Write | Create as needed |

### Implementation (Pre-Push Check)

```bash
# .claude/hooks/git-safety-check.sh
BRANCH=$(git rev-parse --abbrev-ref HEAD)
REMOTE_URL=$(git config --get remote.origin.url)

if [[ "$REMOTE_URL" == *"davidmoneil/AIfred"* ]] && [[ "$BRANCH" == "main" ]]; then
    echo "ERROR: Direct push to AIfred main branch is blocked"
    exit 1
fi
```

---

## Credential Verification Commands

```bash
# Check what credential will be used for a repo
git credential fill <<EOF
protocol=https
host=github.com
path=davidmoneil/AIfred.git
EOF

# List keychain entries for GitHub
security find-internet-password -s github.com

# Test push access (dry-run)
git push --dry-run origin HEAD

# Check collaborator access on GitHub
gh api repos/davidmoneil/AIfred/collaborators/CannonCoPilot
```

---

## Troubleshooting

### Error: "Write access to repository not granted"

**Cause**: PAT in keychain lacks write access to the target repo.

**Fix**:
1. Verify collaborator status: `gh api repos/davidmoneil/AIfred/collaborators`
2. Regenerate PAT with `repo` scope
3. Update keychain with new PAT

### Error: Wrong credentials being used

**Cause**: Credential context mismatch or stale cache.

**Fix**:
```bash
# Clear credential cache
git credential reject <<EOF
protocol=https
host=github.com
EOF

# Re-authenticate on next operation
git fetch origin
```

### Switching between repos mid-session

When Jarvis needs to switch between repos:
1. Complete and commit current work
2. Change directory to target repo
3. Verify credential access: `git ls-remote origin`
4. Proceed with operations

---

## Secrets Storage Location

| Secret Type | Storage | Access Method |
|-------------|---------|---------------|
| GitHub PAT (primary) | macOS Keychain | osxkeychain helper |
| Repo-specific PAT | Git remote URL | Embedded (ephemeral only) |
| SSH keys | ~/.ssh/ | ssh-agent |

**Security Rules**:
- Never commit PATs to git
- Never log PATs in session outputs
- Use environment variables for temporary PAT exposure
- Prefer keychain over embedded credentials

---

## Related Patterns

- @.claude/context/lessons/corrections.md — AIfred baseline rules
- @.claude/context/patterns/session-completion-pattern.md — Push on session end

---

*Multi-Repo Credential Pattern — Created 2026-01-20*
