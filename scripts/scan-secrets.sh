#!/bin/bash
# scan-secrets.sh - Lightweight secret scanner for staged files
#
# Checks staged files for common secret patterns. Designed to be
# chained with the bd pre-commit hook or run standalone.
#
# Usage:
#   scan-secrets.sh              # Scan staged files
#   scan-secrets.sh --all        # Scan all tracked files
#   scan-secrets.sh <file>...    # Scan specific files
#
# Exit 0 = clean, Exit 1 = secrets found

set -euo pipefail

# Patterns that indicate secrets (high confidence only, minimize false positives)
SECRET_PATTERNS=(
    # API keys and tokens
    'AKIA[0-9A-Z]{16}'                         # AWS Access Key
    'sk-[a-zA-Z0-9]{20,}'                      # OpenAI / Anthropic API key
    'ghp_[a-zA-Z0-9]{36}'                      # GitHub Personal Access Token
    'ghs_[a-zA-Z0-9]{36}'                      # GitHub Server Token
    '[0-9]{8,10}:[A-Za-z0-9_-]{35}'            # Telegram Bot Token
    'xoxb-[0-9]{10,}-[0-9]{10,}-[a-zA-Z0-9]{24}'  # Slack Bot Token
    'SG\.[a-zA-Z0-9_-]{22}\.[a-zA-Z0-9_-]{43}'    # SendGrid API Key
    # Private keys
    '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'
    # Passwords in config
    'password\s*[:=]\s*["\x27][^\s"'\'']{8,}'
)

# Files to exclude from scanning
EXCLUDE_PATTERNS='\.env$|\.env\.|secrets/|\.secret|node_modules/|\.git/|\.gitleaks\.toml$|scan-secrets\.sh$'

# Gather files to scan
FILES=()
if [ "${1:-}" = "--all" ]; then
    while IFS= read -r f; do
        FILES+=("$f")
    done < <(git ls-files 2>/dev/null)
elif [ $# -gt 0 ]; then
    FILES=("$@")
else
    while IFS= read -r f; do
        FILES+=("$f")
    done < <(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)
fi

if [ ${#FILES[@]} -eq 0 ]; then
    exit 0
fi

FOUND=0

for file in "${FILES[@]}"; do
    # Skip excluded paths
    if echo "$file" | grep -qE "$EXCLUDE_PATTERNS"; then
        continue
    fi

    # Skip binary files
    if file --mime "$file" 2>/dev/null | grep -q "binary"; then
        continue
    fi

    # Only scan code files
    case "$file" in
        *.py|*.js|*.ts|*.sh|*.yaml|*.yml|*.json|*.toml|*.cfg|*.conf|*.ini|*.md|*.txt)
            ;;
        *)
            continue
            ;;
    esac

    for pattern in "${SECRET_PATTERNS[@]}"; do
        MATCHES=$(grep -nE "$pattern" "$file" 2>/dev/null || true)
        if [ -n "$MATCHES" ]; then
            echo "SECRET FOUND in $file:"
            echo "$MATCHES" | head -3
            echo ""
            FOUND=$((FOUND + 1))
        fi
    done
done

if [ "$FOUND" -gt 0 ]; then
    echo "Found $FOUND potential secret(s). Review before committing."
    echo "If false positive, add to .gitleaks.toml allowlist."
    exit 1
fi

exit 0
