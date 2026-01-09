#!/bin/bash
# extract-skill.sh - Extract a skill from an installed plugin to Jarvis local skills
#
# Usage: ./extract-skill.sh <marketplace> <plugin> <skill>
# Example: ./extract-skill.sh anthropic-agent-skills document-skills docx
#
# This script:
# 1. Locates the skill in the plugin cache
# 2. Copies it to .claude/skills/
# 3. Reports token estimate for the extracted skill

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PLUGIN_CACHE="$HOME/.claude/plugins/cache"
JARVIS_SKILLS="/Users/aircannon/Claude/Jarvis/.claude/skills"

usage() {
    echo "Usage: $0 <marketplace> <plugin> <skill>"
    echo ""
    echo "Arguments:"
    echo "  marketplace  Plugin marketplace (e.g., anthropic-agent-skills, claude-code-plugins)"
    echo "  plugin       Plugin name (e.g., document-skills)"
    echo "  skill        Skill name to extract (e.g., docx, pdf, xlsx)"
    echo ""
    echo "Available marketplaces:"
    ls -1 "$PLUGIN_CACHE" 2>/dev/null || echo "  (none found)"
    exit 1
}

list_skills() {
    local marketplace="$1"
    local plugin="$2"
    local plugin_path="$PLUGIN_CACHE/$marketplace/$plugin"

    if [ ! -d "$plugin_path" ]; then
        echo -e "${RED}Plugin not found: $plugin_path${NC}"
        return 1
    fi

    # Find the version directory (hash or version number)
    local version_dir=$(ls -1 "$plugin_path" | head -1)
    local skills_path="$plugin_path/$version_dir/skills"

    if [ ! -d "$skills_path" ]; then
        echo -e "${RED}No skills directory found in $plugin${NC}"
        return 1
    fi

    echo -e "${CYAN}Available skills in $marketplace/$plugin:${NC}"
    for skill_dir in "$skills_path"/*/; do
        if [ -d "$skill_dir" ]; then
            local skill_name=$(basename "$skill_dir")
            local skill_md="$skill_dir/SKILL.md"
            if [ -f "$skill_md" ]; then
                # Extract description from YAML frontmatter
                local desc=$(sed -n '/^description:/p' "$skill_md" | head -1 | sed 's/description: *"\?\([^"]*\)"\?/\1/' | cut -c1-60)
                # Estimate tokens
                local total_chars=$(find "$skill_dir" -name "*.md" -exec cat {} + 2>/dev/null | wc -c)
                local tokens=$((total_chars / 4))
                printf "  %-25s %6d tokens  %s\n" "$skill_name" "$tokens" "$desc..."
            fi
        fi
    done
}

extract_skill() {
    local marketplace="$1"
    local plugin="$2"
    local skill="$3"

    local plugin_path="$PLUGIN_CACHE/$marketplace/$plugin"

    if [ ! -d "$plugin_path" ]; then
        echo -e "${RED}Plugin not found: $plugin_path${NC}"
        exit 1
    fi

    # Find the version directory
    local version_dir=$(ls -1 "$plugin_path" | head -1)
    local skill_source="$plugin_path/$version_dir/skills/$skill"
    local skill_dest="$JARVIS_SKILLS/$skill"

    if [ ! -d "$skill_source" ]; then
        echo -e "${RED}Skill not found: $skill_source${NC}"
        echo ""
        list_skills "$marketplace" "$plugin"
        exit 1
    fi

    if [ -d "$skill_dest" ]; then
        echo -e "${YELLOW}Warning: Skill already exists at $skill_dest${NC}"
        read -p "Overwrite? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 1
        fi
        rm -rf "$skill_dest"
    fi

    # Create skills directory if needed
    mkdir -p "$JARVIS_SKILLS"

    # Copy the skill
    echo -e "${CYAN}Extracting skill...${NC}"
    cp -r "$skill_source" "$skill_dest"

    # Calculate token estimate
    local total_chars=$(find "$skill_dest" -name "*.md" -exec cat {} + 2>/dev/null | wc -c)
    local tokens=$((total_chars / 4))

    # Count files
    local md_count=$(find "$skill_dest" -name "*.md" | wc -l | tr -d ' ')
    local template_count=$(find "$skill_dest" -type f ! -name "*.md" ! -name "*.txt" | wc -l | tr -d ' ')

    echo ""
    echo -e "${GREEN}✓ Skill extracted successfully${NC}"
    echo ""
    echo "  Source:      $skill_source"
    echo "  Destination: $skill_dest"
    echo ""
    echo "  Token estimate: ~$tokens tokens"
    echo "  Markdown files: $md_count"
    echo "  Template files: $template_count"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Review and customize SKILL.md if needed"
    echo "  2. Test with: claude (start new session)"
    echo "  3. Verify skill appears in /skills list"
    echo "  4. Update skills-selection-guide.md if needed"
}

# Main
if [ "$#" -eq 0 ]; then
    usage
fi

if [ "$1" = "--list" ] || [ "$1" = "-l" ]; then
    if [ "$#" -lt 3 ]; then
        echo "Usage: $0 --list <marketplace> <plugin>"
        exit 1
    fi
    list_skills "$2" "$3"
    exit 0
fi

if [ "$#" -ne 3 ]; then
    usage
fi

extract_skill "$1" "$2" "$3"
