# Secret Management Pattern

**Purpose**: Encrypt secrets at rest in git, decrypt only during deployment.
**Tool**: SOPS + age encryption

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
| New service needs secrets | Create `.env`, encrypt with SOPS |
| Deploying service | Decrypt `.env.enc`, run `docker compose up` |
| Editing existing secrets | Use `sops` in-place edit |
| Viewing encrypted values | Decrypt to temp `.env` |
| Rotating keys | Re-encrypt all services after key change |

---

## Workflow

### Initial Setup (One-time)

```bash
# 1. Install tools
# On Ubuntu/Debian:
sudo apt install age
# Or download from https://github.com/FiloSottile/age/releases

# Install SOPS:
# https://github.com/getsops/sops/releases
# Place binary in ~/bin/ or /usr/local/bin/

# 2. Generate encryption key
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# 3. Note the public key (starts with "age1...")
grep "public key" ~/.config/sops/age/keys.txt

# 4. Create SOPS config in your Docker directory
cat > ${DOCKER_ROOT:-.}/.sops.yaml << 'EOF'
creation_rules:
  - path_regex: \.env\.enc$
    age: >-
      YOUR_PUBLIC_KEY_HERE
EOF

# 5. Backup your private key securely!
# - Password manager
# - Encrypted backup drive
# - Never commit keys.txt to git
```

### Encrypting a Service

```bash
# 1. Create or edit plaintext .env
vim myservice/.env

# 2. Encrypt with SOPS
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
sops --encrypt myservice/.env > myservice/.env.enc

# 3. Remove plaintext, keep encrypted
rm myservice/.env

# 4. Commit encrypted file
git add myservice/.env.enc && git commit -m "Add encrypted secrets for myservice"
```

### Deploying a Service

```bash
# 1. Decrypt
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
sops --decrypt myservice/.env.enc > myservice/.env

# 2. Deploy
cd myservice && docker compose up -d

# 3. Optional: remove plaintext after deploy
rm myservice/.env
```

### Editing Secrets

```bash
# Opens encrypted file in $EDITOR, re-encrypts on save
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
sops myservice/.env.enc
```

---

## File Structure

```
<docker-root>/
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

Deploy workflow:
1. Decrypts `.env.enc` -> `.env`
2. Runs `docker compose up -d`
3. Optionally removes `.env` after deployment

---

## Security Considerations

### Key Management

| Asset | Location | Protection |
|-------|----------|------------|
| Private key | `~/.config/sops/age/keys.txt` | chmod 600, user only |
| Key backup | Password manager + encrypted backup | Secure storage |
| Public key | `.sops.yaml` (committed) | Public, safe to share |

### Access Control

- Private key should exist only on deployment machines
- Backups in secure locations (password manager, encrypted drive)
- Never commit plaintext `.env` files (gitignored by default)

### Key Rotation

```bash
# 1. Generate new key
age-keygen -o ~/.config/sops/age/keys-new.txt

# 2. Update .sops.yaml with new public key

# 3. Re-encrypt all services
for service in service1 service2; do
  sops --decrypt $service/.env.enc > $service/.env
  sops --encrypt $service/.env > $service/.env.enc
  rm $service/.env
done

# 4. Backup new key, retire old key
```

---

## .gitignore Setup

Add to your Docker directory's `.gitignore`:

```gitignore
# Secret management
.env
!.env.enc
*.key
*.pem
```

---

## Troubleshooting

### "no key found"
```bash
# Ensure SOPS_AGE_KEY_FILE is set
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
```

### "could not decrypt"
```bash
# Verify key matches
grep "public key" ~/.config/sops/age/keys.txt  # Your public key
cat .sops.yaml                                   # Key in config
# They should match
```

### "mac mismatch"
File was modified after encryption. Re-encrypt from plaintext.

---

*Synced from AIProjects: 2026-02-05*
