# Secret Management Pattern

**Purpose**: Encrypt secrets at rest in git, decrypt only during deployment.
**Tool**: SOPS + age encryption
**Location**: `~/Docker/mydocker/.sops.yaml` (configuration)

---

## Overview

Secrets (API keys, passwords, tokens) are:
1. **Encrypted** as `.env.enc` files using SOPS + age
2. **Committed** to git (encrypted form only)
3. **Decrypted** only at deploy time to `.env`
4. **Cleaned up** after deployment (plaintext removed)

This allows version control of secrets without exposing them.

---

## Decision Matrix

| Scenario | Solution |
|----------|----------|
| New service needs secrets | Create `.env`, encrypt with `/secrets:encrypt` |
| Deploying service | Use `/secrets:deploy` (auto-decrypts) |
| Editing existing secrets | Use `/secrets:edit` (in-place SOPS edit) |
| Viewing encrypted values | Use `/secrets:decrypt` (creates temp `.env`) |
| Rotating keys | Re-encrypt all services after key change |

---

## Workflow

### Initial Setup (One-time)

```bash
# 1. Install tools (~/bin/)
age --version   # v1.2.0
sops --version  # v3.8.1

# 2. Key location
~/.config/sops/age/keys.txt  # Private key (chmod 600)

# 3. Backup locations
/mnt/synology_nas/main/backups/credentials/sops-age-key.txt
# Also in password manager
```

### Encrypting a Service

```bash
# 1. Create or edit plaintext .env
vim ~/Docker/mydocker/caddy/.env

# 2. Encrypt
/secrets:encrypt caddy
# Creates: ~/Docker/mydocker/caddy/.env.enc
# Removes: ~/Docker/mydocker/caddy/.env (plaintext)

# 3. Commit encrypted file
cd ~/Docker/mydocker && git add caddy/.env.enc && git commit
```

### Deploying a Service

```bash
# Option A: Full deploy (decrypt + compose up)
/secrets:deploy caddy

# Option B: Dry run first
/secrets:deploy caddy --dry-run
```

### Editing Secrets

```bash
# Opens encrypted file in $EDITOR
/secrets:edit caddy
# Decrypts in memory, re-encrypts on save
```

---

## File Structure

```
~/Docker/mydocker/
├── .sops.yaml           # SOPS configuration (public key)
├── .gitignore           # Ignores .env, allows .env.enc
└── <service>/
    ├── docker-compose.yml
    ├── .env.enc         # Encrypted (committed to git)
    └── .env             # Plaintext (gitignored, temporary)
```

---

## Docker Compose Integration

Services use environment variable substitution:

```yaml
# docker-compose.yml
services:
  app:
    image: myapp
    env_file:
      - .env
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - API_KEY=${API_KEY}
```

Deploy script:
1. Decrypts `.env.enc` → `.env`
2. Runs `docker compose up -d`
3. Optionally removes `.env` after deployment

---

## Security Considerations

### Key Management

| Asset | Location | Protection |
|-------|----------|------------|
| Private key | `~/.config/sops/age/keys.txt` | chmod 600, user only |
| Key backup | NAS + password manager | Encrypted storage |
| Public key | `.sops.yaml` (committed) | Public, safe to share |

### Access Control

- Private key exists only on your primary host
- Backups in secure locations (NAS, password manager)
- Never commit plaintext `.env` files (gitignored by default)

### Key Rotation

```bash
# 1. Generate new key
age-keygen -o ~/.config/sops/age/keys-new.txt

# 2. Update .sops.yaml with new public key

# 3. Re-encrypt all services
for service in caddy n8n authentik; do
  /secrets:decrypt $service
  /secrets:encrypt $service  # Uses new key from .sops.yaml
done

# 4. Backup new key, retire old key
```

---

## Related Files

- **Configuration**: `~/Docker/mydocker/.sops.yaml`
- **Skill**: `.claude/skills/secrets-management/SKILL.md`
- **Commands**: `.claude/commands/secrets/*.md`
- **Scripts**: `Scripts/secrets-*.sh`

---

## Troubleshooting

### "no key found"
```bash
# Check SOPS_AGE_KEY_FILE
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
```

### "could not decrypt"
```bash
# Verify key matches
cat ~/.config/sops/age/keys.txt | head -2  # Check public key
cat ~/Docker/mydocker/.sops.yaml          # Compare public key
```

### "mac mismatch"
File was modified after encryption. Re-encrypt from plaintext.

---

*Created: 2026-01-26*
