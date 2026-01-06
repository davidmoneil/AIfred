# Phase 1: System Discovery

**Purpose**: Discover the user's system environment to inform setup decisions.

**Prerequisite**: Complete Phase 0 (Prerequisites Check) first.

---

## Pre-Discovery Validation

Before running discovery, confirm prerequisites from Phase 0:

```bash
# Quick validation
echo "=== Pre-Discovery Check ==="
echo "Git: $(git --version 2>/dev/null || echo 'NOT INSTALLED')"
echo "Docker: $(docker --version 2>/dev/null || echo 'NOT INSTALLED')"

if command -v docker &> /dev/null; then
  if docker info &> /dev/null; then
    echo "Docker Status: ✅ Running"
  else
    echo "Docker Status: ⚠️ Installed but NOT running"
    echo "  → Start Docker before continuing for full functionality"
  fi
fi
```

**If Docker should be running but isn't, help user start it before proceeding.**

---

## Automatic Discovery

Run these discovery commands and capture results:

### 1. Operating System

```bash
uname -a
cat /etc/os-release 2>/dev/null || sw_vers 2>/dev/null
```

**Capture**: OS name, version, architecture

### 2. Hardware

```bash
# CPU
nproc
cat /proc/cpuinfo | grep "model name" | head -1

# Memory
free -h | grep Mem

# Disk
df -h /
```

**Capture**: CPU cores, RAM, available disk

### 3. Docker Status

```bash
# Check if Docker is installed
which docker
docker --version

# Check if running
docker info 2>/dev/null | head -5

# List running containers
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" 2>/dev/null
```

**Capture**: Docker installed (yes/no), version, running containers

### 4. Network Configuration

```bash
# Hostname
hostname

# IP addresses
ip addr show | grep "inet " | grep -v 127.0.0.1

# DNS
cat /etc/resolv.conf | grep nameserver
```

**Capture**: Hostname, IP addresses, DNS servers

### 5. Existing Mounts

```bash
# NFS/CIFS mounts
mount | grep -E "nfs|cifs|smb"

# Check /mnt
ls -la /mnt/ 2>/dev/null
```

**Capture**: Network mounts, mount points

### 6. Existing Services

```bash
# Systemd services
systemctl list-units --type=service --state=running 2>/dev/null | head -20

# Common service ports
ss -tlnp 2>/dev/null | grep -E ":80|:443|:8080|:3000|:5000" | head -10
```

**Capture**: Running services, open ports

### 7. Development Environment

```bash
# Check for the RECOMMENDED projects location first
RECOMMENDED_ROOT="$HOME/Claude/Projects"
if [ -d "$RECOMMENDED_ROOT" ]; then
  echo "✅ Recommended: $RECOMMENDED_ROOT (exists)"
  ls -1 "$RECOMMENDED_ROOT" 2>/dev/null | head -10
else
  echo "📁 Recommended: $RECOMMENDED_ROOT (will create)"
fi

# Also check other common locations for existing projects
echo ""
echo "Other locations with projects:"
for dir in ~/Code ~/code ~/Projects ~/projects ~/src ~/dev ~/Development; do
  if [ -d "$dir" ] && [ "$dir" != "$RECOMMENDED_ROOT" ]; then
    count=$(ls -1 "$dir" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Found: $dir ($count items)"
  fi
done

# Look for existing git repositories
echo ""
echo "Git repositories found:"
find ~/ -maxdepth 3 -name ".git" -type d 2>/dev/null | head -20

# Check for common development tools
which git node npm python3 docker-compose 2>/dev/null
```

**Capture**:
- **Recommended**: `~/Claude/Projects` (default for new setups)
- Other discovered projects directories
- Existing projects/repositories
- Development tools installed

**DEFAULT**: `~/Claude/Projects` — This keeps code projects in the Claude ecosystem
alongside Jarvis and other tools, but in their own dedicated subdirectory.

**KEY CONCEPT**: Jarvis is a "hub" that tracks projects but doesn't contain them.
The user's code should stay in their projects directory, not inside Jarvis.

---

## Discovery Summary

After running discovery, create a summary:

```yaml
# Discovery Results
system:
  os: [detected]
  version: [detected]
  architecture: [detected]

hardware:
  cpu_cores: [detected]
  memory_gb: [detected]
  disk_available_gb: [detected]

docker:
  installed: [yes/no]
  version: [detected or null]
  running_containers: [count]

network:
  hostname: [detected]
  ip_addresses: [list]
  mounts: [list of mount points]

services:
  running: [count]
  key_ports: [list]

development:
  projects_root: "~/Claude/Projects"  # Default, or user-specified
  other_project_dirs: [list of other detected locations]
  existing_projects: [list of directory names]
  tools:
    git: [yes/no]
    node: [yes/no]
    python: [yes/no]
```

---

## User Questions

After discovery, ask:

**Q1**: "I've discovered your system. Would you like me to also scan your network for other devices? (This helps discover NAS, other servers, etc.)"

Options:
- Yes, scan local network
- No, just this machine
- Skip discovery entirely

**Q2** (if Docker not running but was expected):
> "Docker doesn't appear to be running. It was marked as installed in Phase 0.
> - On macOS: Open Docker.app from Applications
> - On Linux: Run `sudo systemctl start docker`
>
> Would you like to try starting it now?"

Note: Docker installation is handled in Phase 0. If Docker is not installed and
user wants it, return to Phase 0 first.

---

## Output

Store discovery results in `.claude/context/systems/this-host.md` and proceed to Phase 2.

---

*Phase 1 of 7 - System Discovery*
