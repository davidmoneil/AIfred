# Phase 0: Prerequisites Check

**Purpose**: Verify and install required dependencies before starting AIfred setup.

**Run this phase FIRST before any other setup steps.**

---

## Prerequisite Categories

| Dependency | Required | Purpose |
|------------|----------|---------|
| Git | **Yes** | Version control, syncing |
| Docker | Recommended | MCP servers, container management |
| Homebrew (macOS only) | Optional | Package management (NOT required for Docker) |

---

## Step 1: Detect Operating System

```bash
# macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "DETECTED: macOS"
  OS_TYPE="macos"

# Linux
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  echo "DETECTED: Linux"
  OS_TYPE="linux"

# WSL
elif grep -qi microsoft /proc/version 2>/dev/null; then
  echo "DETECTED: Windows (WSL)"
  OS_TYPE="wsl"
fi
```

**Store OS_TYPE for use in later steps.**

---

## Step 2: Check Required Dependencies

### Git (Required)

```bash
if command -v git &> /dev/null; then
  echo "✅ Git installed: $(git --version)"
else
  echo "❌ Git NOT installed"
  GIT_MISSING=true
fi
```

**If Git is missing:**

| OS | Installation Command |
|----|---------------------|
| macOS | `xcode-select --install` (includes Git) |
| Ubuntu/Debian | `sudo apt update && sudo apt install git` |
| Fedora/RHEL | `sudo dnf install git` |
| WSL | Follow Linux instructions |

---

## Step 3: Check Docker

### Detection

```bash
# Check if docker command exists
if command -v docker &> /dev/null; then
  echo "Docker command found"

  # Check if Docker daemon is running
  if docker info &> /dev/null; then
    echo "✅ Docker installed and running: $(docker --version)"
    DOCKER_STATUS="running"
  else
    echo "⚠️ Docker installed but NOT running"
    DOCKER_STATUS="installed_not_running"
  fi
else
  echo "❌ Docker NOT installed"
  DOCKER_STATUS="not_installed"
fi
```

### If Docker Not Installed

**Ask user:**
> "Docker is not installed. Docker enables MCP servers (Memory, Browser automation) and container management.
>
> Would you like to install Docker?"
> - Yes, install Docker now
> - No, skip Docker features
> - I'll install it manually later

### Installation Instructions by OS

#### macOS - Docker Desktop (Recommended)

**IMPORTANT: Homebrew is NOT required for Docker on macOS.**

```
OPTION A: Download directly (Recommended)
-----------------------------------------
1. Open: https://www.docker.com/products/docker-desktop/
2. Click "Download for Mac" (Apple Silicon or Intel)
3. Open the downloaded .dmg file
4. Drag Docker.app to Applications folder
5. Open Docker from Applications
6. Wait for "Docker Desktop is running" in menu bar
7. Run: docker --version (to verify)

OPTION B: Via Homebrew (if you have it)
---------------------------------------
brew install --cask docker
open /Applications/Docker.app
```

**After installation, wait 30-60 seconds for Docker to fully start.**

#### Linux (Ubuntu/Debian)

```bash
# Remove old versions
sudo apt remove docker docker-engine docker.io containerd runc 2>/dev/null

# Install prerequisites
sudo apt update
sudo apt install -y ca-certificates curl gnupg

# Add Docker's GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group (avoids sudo)
sudo usermod -aG docker $USER
echo "⚠️ Log out and back in for group changes to take effect"

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker
```

#### Linux (Fedora/RHEL)

```bash
# Install Docker
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker
```

#### WSL (Windows Subsystem for Linux)

```
1. Install Docker Desktop for Windows from:
   https://www.docker.com/products/docker-desktop/

2. In Docker Desktop settings:
   - Enable "Use WSL 2 based engine"
   - Under Resources > WSL Integration, enable your distro

3. Restart WSL:
   wsl --shutdown

4. Open new WSL terminal and verify:
   docker --version
```

---

## Step 4: Validate Docker Installation

**IMPORTANT: Always re-check Docker status after installation attempt.**

```bash
echo "Validating Docker installation..."

# Give Docker time to start (especially on Mac)
sleep 5

# Check again
if command -v docker &> /dev/null && docker info &> /dev/null; then
  echo "✅ Docker is installed and running"
  docker --version
  DOCKER_STATUS="running"
else
  if command -v docker &> /dev/null; then
    echo "⚠️ Docker is installed but not running"
    echo ""
    echo "Try starting Docker:"
    echo "  - macOS: Open Docker.app from Applications"
    echo "  - Linux: sudo systemctl start docker"
    DOCKER_STATUS="installed_not_running"
  else
    echo "❌ Docker installation not detected"
    DOCKER_STATUS="not_installed"
  fi
fi
```

**Do NOT proceed to Phase 1 until Docker status is confirmed if user chose to install.**

---

## Step 5: Check Optional Dependencies

### Homebrew (macOS only - Optional)

```bash
if [[ "$OS_TYPE" == "macos" ]]; then
  if command -v brew &> /dev/null; then
    echo "✅ Homebrew installed: $(brew --version | head -1)"
  else
    echo "ℹ️ Homebrew not installed (optional)"
    echo "   Install later if needed: https://brew.sh"
  fi
fi
```

### Node.js (Optional - for some MCP servers)

```bash
if command -v node &> /dev/null; then
  echo "✅ Node.js installed: $(node --version)"
else
  echo "ℹ️ Node.js not installed (optional - some MCP servers need it)"
fi
```

### Python (Optional - for some MCP servers)

```bash
if command -v python3 &> /dev/null; then
  echo "✅ Python installed: $(python3 --version)"
else
  echo "ℹ️ Python not installed (optional - some MCP servers need it)"
fi
```

---

## Prerequisites Summary

After checking, display summary:

```
╔══════════════════════════════════════════════════╗
║            AIfred Prerequisites Check            ║
╠══════════════════════════════════════════════════╣
║ OS: [macOS/Linux/WSL]                            ║
╠══════════════════════════════════════════════════╣
║ REQUIRED                                         ║
║   Git:     ✅ Installed / ❌ Missing             ║
╠══════════════════════════════════════════════════╣
║ RECOMMENDED                                      ║
║   Docker:  ✅ Running / ⚠️ Not Running / ❌ N/A  ║
╠══════════════════════════════════════════════════╣
║ OPTIONAL                                         ║
║   Node.js: ✅ / ℹ️ Not installed                 ║
║   Python:  ✅ / ℹ️ Not installed                 ║
║   Homebrew: ✅ / ℹ️ Not installed (macOS)        ║
╚══════════════════════════════════════════════════╝
```

---

## Proceed Checklist

Before moving to Phase 1:

- [ ] Git is installed
- [ ] Docker decision made (installed + running, or explicitly skipped)
- [ ] If Docker was installed, status re-validated

---

*Phase 0 of 7 - Prerequisites Check*
