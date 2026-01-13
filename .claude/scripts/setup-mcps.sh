#!/bin/bash
#
# Jarvis MCP Auto-Install Script
# PR-10.5: Setup Upgrade
#
# Installs Stage 1 (Tier 1) MCPs for Jarvis baseline functionality.
# Run during /setup Phase 4 or manually.
#
# Usage: ./setup-mcps.sh [--check-only] [--tier1-only] [--all]
#
# Options:
#   --check-only   Only check current MCP status, don't install
#   --tier1-only   Install only Tier 1 (Always-On) MCPs (default)
#   --all          Install Tier 1 + Tier 2 MCPs
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

JARVIS_ROOT="/Users/aircannon/Claude/Jarvis"
CLAUDE_ROOT="/Users/aircannon/Claude"

echo "=============================================="
echo "  Jarvis MCP Auto-Install Script"
echo "  PR-10.5: Setup Upgrade"
echo "=============================================="
echo ""

# Parse arguments
CHECK_ONLY=false
TIER1_ONLY=true
INSTALL_ALL=false

for arg in "$@"; do
    case $arg in
        --check-only)
            CHECK_ONLY=true
            ;;
        --tier1-only)
            TIER1_ONLY=true
            INSTALL_ALL=false
            ;;
        --all)
            INSTALL_ALL=true
            TIER1_ONLY=false
            ;;
    esac
done

# Function to check if MCP is installed
check_mcp() {
    local name="$1"
    if claude mcp list 2>/dev/null | grep -q "^$name"; then
        return 0
    else
        return 1
    fi
}

# Function to install MCP with retry
install_mcp() {
    local name="$1"
    local command="$2"

    if check_mcp "$name"; then
        echo -e "${GREEN}[OK]${NC} $name already installed"
        return 0
    fi

    echo -e "${YELLOW}[INSTALLING]${NC} $name..."
    if eval "claude mcp add $name -- $command" 2>/dev/null; then
        echo -e "${GREEN}[OK]${NC} $name installed successfully"
        return 0
    else
        echo -e "${RED}[FAIL]${NC} $name installation failed"
        return 1
    fi
}

# Check prerequisites
echo "Checking prerequisites..."

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}[FAIL]${NC} Node.js not found. Please install Node.js 18+."
    exit 1
fi
echo -e "${GREEN}[OK]${NC} Node.js $(node --version)"

# Check for npx
if ! command -v npx &> /dev/null; then
    echo -e "${RED}[FAIL]${NC} npx not found. Please install npm."
    exit 1
fi
echo -e "${GREEN}[OK]${NC} npx available"

# Check for uv (optional, for Python MCPs)
if command -v uvx &> /dev/null; then
    echo -e "${GREEN}[OK]${NC} uv/uvx available"
    HAS_UVX=true
else
    echo -e "${YELLOW}[WARN]${NC} uvx not found. Some MCPs (fetch, git) require uvx."
    echo "       Install with: pip install uv"
    HAS_UVX=false
fi

echo ""

# Check-only mode
if $CHECK_ONLY; then
    echo "Current MCP Status:"
    echo "-------------------"
    claude mcp list 2>/dev/null || echo "No MCPs installed or claude not available"
    exit 0
fi

echo "=============================================="
echo "  Installing Tier 1 MCPs (Always-On)"
echo "=============================================="
echo ""

# Tier 1 MCPs - Always-On
TIER1_INSTALLED=0
TIER1_FAILED=0

# Memory - Knowledge graph persistence
if install_mcp "memory" "npx -y @modelcontextprotocol/server-memory"; then
    ((TIER1_INSTALLED++))
else
    ((TIER1_FAILED++))
fi

# Filesystem - Secure file operations
if install_mcp "filesystem" "npx -y @modelcontextprotocol/server-filesystem $JARVIS_ROOT $CLAUDE_ROOT"; then
    ((TIER1_INSTALLED++))
else
    ((TIER1_FAILED++))
fi

# Fetch - Web content (requires uvx)
if $HAS_UVX; then
    if install_mcp "fetch" "uvx mcp-server-fetch"; then
        ((TIER1_INSTALLED++))
    else
        ((TIER1_FAILED++))
    fi
else
    echo -e "${YELLOW}[SKIP]${NC} fetch (requires uvx)"
fi

# Git - Repository operations (requires uvx)
if $HAS_UVX; then
    if install_mcp "git" "uvx mcp-server-git --repository $JARVIS_ROOT"; then
        ((TIER1_INSTALLED++))
    else
        ((TIER1_FAILED++))
    fi
else
    echo -e "${YELLOW}[SKIP]${NC} git (requires uvx)"
fi

echo ""
echo "Tier 1 Summary: $TIER1_INSTALLED installed, $TIER1_FAILED failed"

# Tier 2 MCPs - Task-Scoped (if --all)
if $INSTALL_ALL; then
    echo ""
    echo "=============================================="
    echo "  Installing Tier 2 MCPs (Task-Scoped)"
    echo "=============================================="
    echo ""

    TIER2_INSTALLED=0
    TIER2_FAILED=0

    # DateTime
    if $HAS_UVX; then
        if install_mcp "datetime" "uvx datetime-mcp"; then
            ((TIER2_INSTALLED++))
        else
            ((TIER2_FAILED++))
        fi
    fi

    # Sequential Thinking
    if install_mcp "sequential-thinking" "npx -y @modelcontextprotocol/server-sequential-thinking"; then
        ((TIER2_INSTALLED++))
    else
        ((TIER2_FAILED++))
    fi

    # Desktop Commander
    if install_mcp "desktop-commander" "npx -y @anthropic-ai/desktop-commander"; then
        ((TIER2_INSTALLED++))
    else
        ((TIER2_FAILED++))
    fi

    echo ""
    echo "Tier 2 Summary: $TIER2_INSTALLED installed, $TIER2_FAILED failed"
fi

echo ""
echo "=============================================="
echo "  Installation Complete"
echo "=============================================="
echo ""
echo "NOTE: Restart Claude Code to activate new MCPs."
echo ""
echo "To verify installation:"
echo "  claude mcp list"
echo ""
echo "For GitHub MCP (requires PAT):"
echo "  export GITHUB_PERSONAL_ACCESS_TOKEN='your_token'"
echo "  claude mcp add github -- npx -y @modelcontextprotocol/server-github"
echo ""
