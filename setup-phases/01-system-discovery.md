# Phase 1: System Discovery

**Purpose**: Discover the user's system environment to inform setup decisions.

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
# Common code directory locations
for dir in ~/Code ~/code ~/Projects ~/projects ~/src ~/dev ~/Development; do
  if [ -d "$dir" ]; then
    echo "Found: $dir"
    ls -1 "$dir" 2>/dev/null | head -10
  fi
done

# Look for existing git repositories
find ~/ -maxdepth 3 -name ".git" -type d 2>/dev/null | head -20

# Check for common development tools
which git node npm python3 docker-compose 2>/dev/null
```

**Capture**:
- Projects root directory (e.g., ~/Code)
- Existing projects/repositories
- Development tools installed

**KEY CONCEPT**: AIfred is a "hub" that tracks projects but doesn't contain them.
The user's code should stay in their projects directory (e.g., ~/Code), not inside AIfred.

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
  projects_root: [detected path, e.g., ~/Code]
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

**Q2** (if Docker not installed): "Docker isn't installed. Would you like me to install it? This enables MCP servers and container management."

Options:
- Yes, install Docker
- No, skip Docker features
- I'll install it manually later

---

## Output

Store discovery results in `.claude/context/systems/this-host.md` and proceed to Phase 2.

---

*Phase 1 of 7 - System Discovery*
