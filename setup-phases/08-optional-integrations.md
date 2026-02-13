# Phase 8: Optional Integrations

**Purpose**: Configure optional tools that extend AIfred's capabilities. Each integration is independent — skip any you don't need.

---

## Overview

Three optional integrations are available:

| Integration | What It Adds | Requires |
|-------------|-------------|----------|
| **Ollama** | Local LLM for $0 AI processing (Fabric skill, commit messages, log analysis) | Ollama installed locally or on a remote server |
| **SSH Remote Access** | Health checks and management of remote systems | SSH keys configured for target hosts |
| **Browser Automation** | Web UI testing, visual regression, service verification | Playwright + Chromium |

---

## Integration 1: Ollama (Local LLM)

### Detection

```bash
# Check if Ollama is available locally
command -v ollama &>/dev/null && echo "✅ Ollama found locally" || echo "❌ Ollama not found locally"

# Check if Ollama is running on a remote server (common in home labs)
curl -s http://localhost:11434/api/tags &>/dev/null && echo "✅ Ollama API responding locally"
```

### Prompt

> **Would you like to enable local LLM integration via Ollama?**
>
> This enables:
> - `/fabric` command for AI text processing (log analysis, commit messages, code review)
> - `$0 cost` headless jobs using local models instead of Claude API
> - Local summarization and triage in automation scripts
>
> Options:
> 1. **Yes, Ollama is installed locally** (on this machine)
> 2. **Yes, Ollama runs on a remote server** (I'll provide the URL)
> 3. **No, skip Ollama integration**

### If Yes (Local)

```bash
# Verify Ollama is running
ollama list

# Check available models
ollama list | grep -E "llama|qwen|mistral|gemma"
```

**Configure**:
1. Set `OLLAMA_HOST` in environment (default: `http://localhost:11434`)
2. Recommend pulling a model: `ollama pull qwen2.5:32b` (or smaller: `llama3.2:3b`)
3. Enable Fabric commands and skill
4. Enable `ollama-test` job in `.claude/jobs/registry.yaml`

### If Yes (Remote)

Ask for the Ollama server URL:

> **What is the Ollama server URL?** (e.g., `http://192.168.1.100:11434`)

**Configure**:
1. Set `OLLAMA_HOST` environment variable to the remote URL
2. Verify connectivity: `curl -s $OLLAMA_HOST/api/tags`
3. Enable Fabric commands and skill
4. Enable `ollama-test` job in `.claude/jobs/registry.yaml`

### If No

- Fabric commands remain available but will show "Ollama not configured" when invoked
- Headless jobs default to `claude-code` engine (API cost applies)
- No configuration changes needed

### Configuration Actions

When enabled, update these files:

**`paths-registry.yaml`** — Add Ollama section:
```yaml
integrations:
  ollama:
    enabled: true
    host: "http://localhost:11434"  # or remote URL
    default_model: "qwen2.5:32b"
    fabric_model: "qwen2.5:32b"
```

**`.claude/jobs/registry.yaml`** — Enable ollama-test job:
```yaml
ollama-test:
  enabled: true  # Change from false to true
```

**Environment** — Add to shell profile or `.env`:
```bash
export OLLAMA_HOST="http://localhost:11434"
```

---

## Integration 2: SSH Remote Access

### Detection

```bash
# Check for SSH client
command -v ssh &>/dev/null && echo "✅ SSH client available" || echo "❌ SSH not found"

# Check for existing SSH keys
ls ~/.ssh/id_* 2>/dev/null && echo "✅ SSH keys found" || echo "⚠️ No SSH keys found"

# Check SSH config for known hosts
[ -f ~/.ssh/config ] && echo "✅ SSH config exists" || echo "⚠️ No SSH config"
```

### Prompt

> **Would you like to enable SSH remote access?**
>
> This enables:
> - `/ssh-connect` command for remote health checks
> - Remote system monitoring from AIfred
> - Cross-machine infrastructure management
>
> Options:
> 1. **Yes, I have remote systems to manage**
> 2. **No, everything runs on this machine**

### If Yes

Ask for remote hosts:

> **List the hosts you want to manage remotely.**
>
> For each host, provide:
> - **Name** (friendly label, e.g., "mediaserver")
> - **Address** (hostname or IP, e.g., "192.168.1.50")
> - **User** (SSH user, e.g., "admin")
>
> Example: `mediaserver, 192.168.1.50, admin`

**For each host, verify connectivity:**

```bash
ssh -o ConnectTimeout=5 -o BatchMode=yes user@host "echo '✅ Connected'" 2>/dev/null || echo "❌ Cannot connect"
```

### Configuration Actions

When enabled, update these files:

**`paths-registry.yaml`** — Add SSH section:
```yaml
integrations:
  ssh:
    enabled: true
    hosts:
      - name: "mediaserver"
        address: "192.168.1.50"
        user: "admin"
        checks:
          - "uptime"
          - "df -h"
          - "docker ps --format 'table {{.Names}}\t{{.Status}}'"
      # Add more hosts as needed
```

**Note**: The `/ssh-connect` command reads hosts from `paths-registry.yaml`. No hardcoded host list.

### If No

- `/ssh-connect` command remains available but will prompt for host details when invoked
- No configuration changes needed

---

## Integration 3: Browser Automation (Playwright)

### Detection

```bash
# Check for npx (required for Playwright)
command -v npx &>/dev/null && echo "✅ npx available" || echo "❌ npx not found (install Node.js first)"

# Check if Playwright is installed
npx playwright --version 2>/dev/null && echo "✅ Playwright found" || echo "❌ Playwright not installed"
```

### Prompt

> **Would you like to enable browser automation via Playwright?**
>
> This enables:
> - `/browser` command for web UI interaction
> - Visual regression testing of web services
> - Automated form testing and screenshots
> - Web service health verification
>
> **Note**: Playwright requires Chromium (~400MB download on first install).
>
> Options:
> 1. **Yes, install Playwright and Chromium**
> 2. **No, skip browser automation**

### If Yes

```bash
# Install Playwright
npx playwright install chromium

# Verify installation
npx playwright --version
```

**Configure**:
1. Verify Chromium installed successfully
2. Browser MCP will be available in Claude Code sessions
3. `/browser` command launches isolated browser sessions

### If No

- `/browser` command will show "Playwright not configured" when invoked
- No configuration changes needed
- Can be installed later: `npx playwright install chromium`

### Configuration Actions

When enabled, update:

**`paths-registry.yaml`** — Add browser section:
```yaml
integrations:
  browser:
    enabled: true
    engine: "chromium"
```

---

## Summary

After completing this phase, present the integration summary:

```
╔══════════════════════════════════════════════════════════════╗
║              Optional Integrations Summary                    ║
╠══════════════════════════════════════════════════════════════╣
║                                                               ║
║  Ollama (Local LLM):    [✅ Enabled / ❌ Skipped]           ║
║    Host: [url or N/A]                                        ║
║    Model: [model or N/A]                                     ║
║                                                               ║
║  SSH Remote Access:     [✅ Enabled / ❌ Skipped]           ║
║    Hosts: [count or N/A]                                     ║
║                                                               ║
║  Browser Automation:    [✅ Enabled / ❌ Skipped]           ║
║    Engine: [chromium or N/A]                                 ║
║                                                               ║
║  These can be configured later:                              ║
║  • Ollama: Install ollama, run /setup Phase 8                ║
║  • SSH: Add hosts to paths-registry.yaml                     ║
║  • Browser: npx playwright install chromium                  ║
║                                                               ║
╚══════════════════════════════════════════════════════════════╝
```

---

## Validation

- [ ] Each integration detected or skipped
- [ ] Enabled integrations verified working
- [ ] paths-registry.yaml updated for enabled integrations
- [ ] registry.yaml updated if Ollama enabled
- [ ] Summary presented to user

---

*Phase 8 of 8 (0-8) - Optional Integrations*
