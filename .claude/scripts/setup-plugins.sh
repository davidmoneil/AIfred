#!/bin/bash
#
# Jarvis Plugin Auto-Install Script
# PR-10.5: Setup Upgrade
#
# Installs recommended plugins for Jarvis baseline functionality.
# Run during /setup Phase 5 or manually.
#
# Usage: ./setup-plugins.sh [--check-only] [--core-only] [--all]
#
# Options:
#   --check-only   Only check current plugin status, don't install
#   --core-only    Install only core plugins (default)
#   --all          Install all evaluated ADOPT plugins
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=============================================="
echo "  Jarvis Plugin Auto-Install Script"
echo "  PR-10.5: Setup Upgrade"
echo "=============================================="
echo ""

# Parse arguments
CHECK_ONLY=false
CORE_ONLY=true
INSTALL_ALL=false

for arg in "$@"; do
    case $arg in
        --check-only)
            CHECK_ONLY=true
            ;;
        --core-only)
            CORE_ONLY=true
            INSTALL_ALL=false
            ;;
        --all)
            INSTALL_ALL=true
            CORE_ONLY=false
            ;;
    esac
done

# Function to install plugin
install_plugin() {
    local registry="$1"
    local plugin="$2"
    local full_name="$plugin@$registry"

    echo -n "Installing $full_name... "
    if claude plugin add "$registry" "$plugin" 2>/dev/null; then
        echo -e "${GREEN}[OK]${NC}"
        return 0
    else
        echo -e "${YELLOW}[SKIP/EXISTS]${NC}"
        return 0
    fi
}

# Check-only mode
if $CHECK_ONLY; then
    echo "Currently installed plugins:"
    echo "----------------------------"
    if [ -f ~/.claude/plugins/installed_plugins.json ]; then
        cat ~/.claude/plugins/installed_plugins.json | grep -o '"[^"]*@[^"]*"' | tr -d '"' | sort -u
    else
        echo "No plugins installed"
    fi
    exit 0
fi

echo "=============================================="
echo "  Installing Core Plugins"
echo "=============================================="
echo ""
echo "These are high-value plugins evaluated in PR-6."
echo ""

# Core Plugins from claude-code-plugins
echo "--- Official Plugins (claude-code-plugins) ---"
install_plugin "claude-code-plugins" "ralph-wiggum"
install_plugin "claude-code-plugins" "feature-dev"
install_plugin "claude-code-plugins" "hookify"
install_plugin "claude-code-plugins" "pr-review-toolkit"
install_plugin "claude-code-plugins" "security-guidance"

# Engineering Workflow from mhattingpete-claude-skills
echo ""
echo "--- Community Plugins (mhattingpete-claude-skills) ---"
install_plugin "mhattingpete-claude-skills" "engineering-workflow-skills"

# Document Skills from anthropic-agent-skills
echo ""
echo "--- Document Skills (anthropic-agent-skills) ---"
install_plugin "anthropic-agent-skills" "document-skills"

if $INSTALL_ALL; then
    echo ""
    echo "=============================================="
    echo "  Installing Additional Plugins"
    echo "=============================================="
    echo ""

    # Additional Official Plugins
    echo "--- Additional Official Plugins ---"
    install_plugin "claude-code-plugins" "agent-sdk-dev"
    install_plugin "claude-code-plugins" "code-review"
    install_plugin "claude-code-plugins" "frontend-design"
    install_plugin "claude-code-plugins" "plugin-dev"
    install_plugin "claude-code-plugins" "explanatory-output-style"

    # Additional Community Plugins
    echo ""
    echo "--- Additional Community Plugins ---"
    install_plugin "mhattingpete-claude-skills" "code-operations-skills"
    install_plugin "mhattingpete-claude-skills" "productivity-skills"
    install_plugin "mhattingpete-claude-skills" "visual-documentation-skills"

    # Browser Automation
    echo ""
    echo "--- Browser Automation ---"
    install_plugin "browser-tools" "browser-automation"
fi

echo ""
echo "=============================================="
echo "  Installation Complete"
echo "=============================================="
echo ""
echo "NOTE: Some plugins may require restart to activate."
echo ""
echo "To list installed plugins:"
echo "  Look in ~/.claude/plugins/installed_plugins.json"
echo ""
echo "To use a skill from a plugin:"
echo "  Just describe the task - Jarvis will select appropriate skill"
echo ""
echo "Core plugins installed:"
echo "  - ralph-wiggum: Autonomous iteration loops"
echo "  - feature-dev: 7-phase feature development"
echo "  - hookify: Create prevention hooks"
echo "  - pr-review-toolkit: Comprehensive PR reviews"
echo "  - security-guidance: Security monitoring"
echo "  - engineering-workflow-skills: Git, testing, planning"
echo "  - document-skills: Office documents (Word, PDF, Excel, PowerPoint)"
echo ""
