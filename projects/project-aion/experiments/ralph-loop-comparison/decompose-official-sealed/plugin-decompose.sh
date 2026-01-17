#!/bin/bash
# plugin-decompose.sh - Plugin analysis and decomposition tool for Jarvis
#
# Usage: ./plugin-decompose.sh <command> [options]
#
# Commands:
#   --discover <name>     Find plugin by name or path
#   --review <path>       Analyze plugin structure and components
#   --analyze <path>      Classify components for integration (ADOPT/ADAPT/DEFER/SKIP)
#   --scan-redundancy     Semantic comparison against Jarvis codebase
#   --decompose <path>    Generate file mapping and integration checklist
#   --browse              Interactive plugin browser
#   --execute <path>      Execute the integration plan (copy/merge files)
#   --rollback <file>     Rollback a previous integration using rollback file
#
# Flags:
#   --dry-run             Show what would happen without making changes (use with --execute)
#
# Examples:
#   ./plugin-decompose.sh --discover example-plugin
#   ./plugin-decompose.sh --review ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/ralph-loop
#   ./plugin-decompose.sh --browse

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Paths
PLUGIN_CACHE="$HOME/.claude/plugins/cache"
PLUGIN_MARKETPLACES="$HOME/.claude/plugins/marketplaces"
JARVIS_ROOT="/Users/aircannon/Claude/Jarvis"
JARVIS_CLAUDE="$JARVIS_ROOT/.claude"
OUTPUT_DIR="$JARVIS_ROOT/docs/reports/plugin-analysis"
ROLLBACK_DIR="$OUTPUT_DIR/rollbacks"

# Global flags
DRY_RUN=0

# Ensure output directories exist
mkdir -p "$OUTPUT_DIR"
mkdir -p "$ROLLBACK_DIR"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

print_header() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  $1${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BOLD}${YELLOW}▸ $1${NC}"
    echo -e "${YELLOW}─────────────────────────────────────────────────────────────────────────${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

usage() {
    cat << EOF
${BOLD}Plugin Decomposition Tool for Jarvis${NC}

${CYAN}Usage:${NC} $0 <command> [options]

${CYAN}Commands:${NC}
  --discover <name>       Find plugin by name or partial path
  --review <path>         Analyze plugin structure and document components
  --analyze <path>        Classify components for integration
  --scan-redundancy <path> Semantic comparison against Jarvis codebase
  --decompose <path>      Generate file mapping and integration checklist
  --browse                Interactive plugin browser
  --execute <path>        Execute the integration plan (install plugin into Jarvis)
  --rollback <file>       Rollback a previous integration

${CYAN}Options:${NC}
  -o, --output <file>     Output results to file (for --review, --analyze, --decompose)
  --dry-run               Show what would happen without making changes (use with --execute)
  -v, --verbose           Verbose output
  -h, --help              Show this help message

${CYAN}Examples:${NC}
  $0 --discover ralph-loop
  $0 --review ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/feature-dev
  $0 --analyze /path/to/plugin -o analysis.md
  $0 --decompose /path/to/plugin
  $0 --browse
  $0 --execute /path/to/plugin --dry-run
  $0 --execute /path/to/plugin
  $0 --rollback docs/reports/plugin-analysis/rollbacks/example-plugin-20260117.json

${CYAN}Plugin Locations:${NC}
  Cache:        $PLUGIN_CACHE
  Marketplaces: $PLUGIN_MARKETPLACES
EOF
    exit 0
}

# ============================================================================
# FEATURE 1: PLUGIN DISCOVERY (--discover)
# ============================================================================

discover_plugin() {
    local search_term="$1"
    local found=0

    print_header "Plugin Discovery: $search_term"

    # Search in cache directory
    print_section "Searching Plugin Cache"
    if [ -d "$PLUGIN_CACHE" ]; then
        while IFS= read -r -d '' plugin_path; do
            if [ -d "$plugin_path" ]; then
                echo -e "  ${GREEN}Found:${NC} $plugin_path"
                found=$((found + 1))
            fi
        done < <(find "$PLUGIN_CACHE" -type d -name "*$search_term*" -print0 2>/dev/null)
    else
        print_warning "Cache directory not found"
    fi

    # Search in marketplaces directory
    print_section "Searching Marketplaces"
    if [ -d "$PLUGIN_MARKETPLACES" ]; then
        while IFS= read -r -d '' plugin_path; do
            if [ -d "$plugin_path" ]; then
                # Check if it has a plugin.json or is a plugin directory
                if [ -f "$plugin_path/.claude-plugin/plugin.json" ] || [ -f "$plugin_path/plugin.json" ]; then
                    echo -e "  ${GREEN}Found:${NC} $plugin_path"
                    found=$((found + 1))
                fi
            fi
        done < <(find "$PLUGIN_MARKETPLACES" -type d -name "*$search_term*" -print0 2>/dev/null)
    else
        print_warning "Marketplaces directory not found"
    fi

    echo ""
    if [ $found -eq 0 ]; then
        print_error "No plugins found matching '$search_term'"
        echo ""
        echo "Try listing available plugins with: $0 --browse"
        return 1
    else
        print_success "Found $found plugin(s) matching '$search_term'"
    fi
}

# ============================================================================
# FEATURE 2: PLUGIN REVIEW (--review)
# ============================================================================

review_plugin() {
    local plugin_path="$1"
    local output_file="$2"

    # Resolve path
    if [ ! -d "$plugin_path" ]; then
        print_error "Plugin directory not found: $plugin_path"
        return 1
    fi

    plugin_path=$(cd "$plugin_path" && pwd)
    local plugin_name=$(basename "$plugin_path")

    print_header "Plugin Review: $plugin_name"

    # Start building report
    local report=""
    report+="# Plugin Review: $plugin_name\n\n"
    report+="**Path:** \`$plugin_path\`\n"
    report+="**Generated:** $(date '+%Y-%m-%d %H:%M:%S')\n\n"

    # Check for manifest
    print_section "Plugin Metadata"
    if [ -f "$plugin_path/.claude-plugin/plugin.json" ]; then
        echo "  Manifest: .claude-plugin/plugin.json"
        local manifest=$(cat "$plugin_path/.claude-plugin/plugin.json")
        local name=$(echo "$manifest" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
        local desc=$(echo "$manifest" | grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
        local author=$(echo "$manifest" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | tail -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
        echo "  Name: $name"
        echo "  Description: $desc"
        echo "  Author: $author"
        report+="## Metadata\n\n"
        report+="- **Name:** $name\n"
        report+="- **Description:** $desc\n"
        report+="- **Author:** $author\n\n"
    else
        print_warning "No plugin.json manifest found"
        report+="## Metadata\n\n*No manifest found*\n\n"
    fi

    # Analyze structure
    report+="## Structure\n\n\`\`\`\n"
    report+=$(find "$plugin_path" -type f | sed "s|$plugin_path/||" | sort)
    report+="\n\`\`\`\n\n"

    # Commands
    print_section "Commands"
    report+="## Commands\n\n"
    if [ -d "$plugin_path/commands" ]; then
        local cmd_count=0
        for cmd_file in "$plugin_path/commands"/*.md; do
            if [ -f "$cmd_file" ]; then
                local cmd_name=$(basename "$cmd_file" .md)
                local cmd_desc=$(grep -m1 "^description:" "$cmd_file" 2>/dev/null | sed 's/description: *//' | tr -d '"' || echo "No description")
                echo "  /$cmd_name - $cmd_desc"
                report+="### /$cmd_name\n\n"
                report+="- **File:** \`commands/$cmd_name.md\`\n"
                report+="- **Description:** $cmd_desc\n\n"
                cmd_count=$((cmd_count + 1))
            fi
        done
        if [ $cmd_count -eq 0 ]; then
            echo "  (no commands found)"
            report+="*No commands found*\n\n"
        fi
    else
        echo "  (no commands directory)"
        report+="*No commands directory*\n\n"
    fi

    # Hooks
    print_section "Hooks"
    report+="## Hooks\n\n"
    if [ -d "$plugin_path/hooks" ]; then
        local hook_count=0
        # Check for hooks.json
        if [ -f "$plugin_path/hooks/hooks.json" ]; then
            echo "  hooks.json found - parsing hook definitions"
            report+="### hooks.json\n\n"
            report+="\`\`\`json\n"
            report+=$(cat "$plugin_path/hooks/hooks.json")
            report+="\n\`\`\`\n\n"
        fi
        # List hook scripts
        for hook_file in "$plugin_path/hooks"/*.sh; do
            if [ -f "$hook_file" ]; then
                local hook_name=$(basename "$hook_file")
                echo "  $hook_name"
                report+="### $hook_name\n\n"
                # Extract first comment block as description
                local hook_desc=$(head -20 "$hook_file" | grep "^#" | grep -v "^#!/" | head -5 | sed 's/^# *//')
                report+="$hook_desc\n\n"
                hook_count=$((hook_count + 1))
            fi
        done
        if [ $hook_count -eq 0 ] && [ ! -f "$plugin_path/hooks/hooks.json" ]; then
            echo "  (no hooks found)"
            report+="*No hooks found*\n\n"
        fi
    else
        echo "  (no hooks directory)"
        report+="*No hooks directory*\n\n"
    fi

    # Scripts
    print_section "Scripts"
    report+="## Scripts\n\n"
    if [ -d "$plugin_path/scripts" ]; then
        local script_count=0
        for script_file in "$plugin_path/scripts"/*; do
            if [ -f "$script_file" ]; then
                local script_name=$(basename "$script_file")
                echo "  $script_name"
                report+="### $script_name\n\n"
                # Extract first comment block as description
                local script_desc=$(head -20 "$script_file" | grep "^#" | grep -v "^#!/" | head -5 | sed 's/^# *//')
                report+="$script_desc\n\n"
                script_count=$((script_count + 1))
            fi
        done
        if [ $script_count -eq 0 ]; then
            echo "  (no scripts found)"
            report+="*No scripts found*\n\n"
        fi
    else
        echo "  (no scripts directory)"
        report+="*No scripts directory*\n\n"
    fi

    # Skills
    print_section "Skills"
    report+="## Skills\n\n"
    if [ -d "$plugin_path/skills" ]; then
        local skill_count=0
        for skill_dir in "$plugin_path/skills"/*/; do
            if [ -d "$skill_dir" ]; then
                local skill_name=$(basename "$skill_dir")
                if [ -f "$skill_dir/SKILL.md" ]; then
                    local skill_desc=$(grep -m1 "^description:" "$skill_dir/SKILL.md" 2>/dev/null | sed 's/description: *//' | tr -d '"' || echo "No description")
                    echo "  $skill_name - $skill_desc"
                    report+="### $skill_name\n\n"
                    report+="- **Description:** $skill_desc\n\n"
                    skill_count=$((skill_count + 1))
                fi
            fi
        done
        if [ $skill_count -eq 0 ]; then
            echo "  (no skills found)"
            report+="*No skills found*\n\n"
        fi
    else
        echo "  (no skills directory)"
        report+="*No skills directory*\n\n"
    fi

    # Agents
    print_section "Agents"
    report+="## Agents\n\n"
    if [ -d "$plugin_path/agents" ]; then
        local agent_count=0
        for agent_file in "$plugin_path/agents"/*.md; do
            if [ -f "$agent_file" ]; then
                local agent_name=$(basename "$agent_file" .md)
                echo "  $agent_name"
                report+="### $agent_name\n\n"
                agent_count=$((agent_count + 1))
            fi
        done
        if [ $agent_count -eq 0 ]; then
            echo "  (no agents found)"
            report+="*No agents found*\n\n"
        fi
    else
        echo "  (no agents directory)"
        report+="*No agents directory*\n\n"
    fi

    # MCP Configuration
    print_section "MCP Configuration"
    report+="## MCP Configuration\n\n"
    if [ -f "$plugin_path/.mcp.json" ]; then
        echo "  .mcp.json found"
        report+="\`\`\`json\n"
        report+=$(cat "$plugin_path/.mcp.json")
        report+="\n\`\`\`\n\n"
    else
        echo "  (no MCP configuration)"
        report+="*No MCP configuration*\n\n"
    fi

    # Token estimate
    print_section "Size Analysis"
    local total_chars=$(find "$plugin_path" -name "*.md" -exec cat {} + 2>/dev/null | wc -c)
    local tokens=$((total_chars / 4))
    local file_count=$(find "$plugin_path" -type f | wc -l | tr -d ' ')
    echo "  Total files: $file_count"
    echo "  Estimated tokens (markdown): ~$tokens"

    report+="## Size Analysis\n\n"
    report+="- **Total files:** $file_count\n"
    report+="- **Estimated tokens (markdown):** ~$tokens\n\n"

    # Output report
    if [ -n "$output_file" ]; then
        echo -e "$report" > "$output_file"
        echo ""
        print_success "Report saved to: $output_file"
    else
        local default_output="$OUTPUT_DIR/${plugin_name}-review.md"
        echo -e "$report" > "$default_output"
        echo ""
        print_success "Report saved to: $default_output"
    fi
}

# ============================================================================
# FEATURE 3: INTEGRATION ANALYSIS (--analyze)
# ============================================================================

analyze_plugin() {
    local plugin_path="$1"
    local output_file="$2"

    if [ ! -d "$plugin_path" ]; then
        print_error "Plugin directory not found: $plugin_path"
        return 1
    fi

    plugin_path=$(cd "$plugin_path" && pwd)
    local plugin_name=$(basename "$plugin_path")

    print_header "Integration Analysis: $plugin_name"

    local report=""
    report+="# Integration Analysis: $plugin_name\n\n"
    report+="**Generated:** $(date '+%Y-%m-%d %H:%M:%S')\n\n"
    report+="## Classification Key\n\n"
    report+="- **ADOPT**: Use as-is or with minimal changes\n"
    report+="- **ADAPT**: Modify to fit Jarvis patterns\n"
    report+="- **DEFER**: Useful but not immediate priority\n"
    report+="- **SKIP**: Not needed or redundant\n\n"
    report+="## Component Analysis\n\n"

    # Analyze Commands
    print_section "Commands Analysis"
    report+="### Commands\n\n"
    if [ -d "$plugin_path/commands" ]; then
        report+="| Command | Classification | Reason |\n"
        report+="|---------|---------------|--------|\n"
        for cmd_file in "$plugin_path/commands"/*.md; do
            if [ -f "$cmd_file" ]; then
                local cmd_name=$(basename "$cmd_file" .md)

                # Check if Jarvis already has this command
                local jarvis_cmd="$JARVIS_CLAUDE/commands/$cmd_name.md"
                local classification="ADOPT"
                local reason="New capability"

                if [ -f "$jarvis_cmd" ]; then
                    classification="SKIP"
                    reason="Already exists in Jarvis"
                elif grep -q "$cmd_name" "$JARVIS_CLAUDE/skills/"*/SKILL.md 2>/dev/null; then
                    classification="ADAPT"
                    reason="Similar skill exists, may need merge"
                fi

                echo -e "  /$cmd_name: ${MAGENTA}$classification${NC} - $reason"
                report+="| /$cmd_name | $classification | $reason |\n"
            fi
        done
    else
        report+="*No commands to analyze*\n"
    fi
    report+="\n"

    # Analyze Hooks
    print_section "Hooks Analysis"
    report+="### Hooks\n\n"
    if [ -d "$plugin_path/hooks" ]; then
        report+="| Hook | Classification | Reason |\n"
        report+="|------|---------------|--------|\n"
        for hook_file in "$plugin_path/hooks"/*.sh; do
            if [ -f "$hook_file" ]; then
                local hook_name=$(basename "$hook_file")

                # Check Jarvis hooks
                local classification="ADOPT"
                local reason="New hook type"

                if [ -f "$JARVIS_CLAUDE/hooks/$hook_name" ]; then
                    classification="ADAPT"
                    reason="Similar hook exists, merge functionality"
                fi

                echo -e "  $hook_name: ${MAGENTA}$classification${NC} - $reason"
                report+="| $hook_name | $classification | $reason |\n"
            fi
        done
    else
        report+="*No hooks to analyze*\n"
    fi
    report+="\n"

    # Analyze Scripts
    print_section "Scripts Analysis"
    report+="### Scripts\n\n"
    if [ -d "$plugin_path/scripts" ]; then
        report+="| Script | Classification | Reason |\n"
        report+="|--------|---------------|--------|\n"
        for script_file in "$plugin_path/scripts"/*; do
            if [ -f "$script_file" ]; then
                local script_name=$(basename "$script_file")

                # Check Jarvis scripts
                local classification="ADOPT"
                local reason="New utility"

                if [ -f "$JARVIS_CLAUDE/scripts/$script_name" ]; then
                    classification="SKIP"
                    reason="Already exists"
                fi

                echo -e "  $script_name: ${MAGENTA}$classification${NC} - $reason"
                report+="| $script_name | $classification | $reason |\n"
            fi
        done
    else
        report+="*No scripts to analyze*\n"
    fi
    report+="\n"

    # Analyze Skills
    print_section "Skills Analysis"
    report+="### Skills\n\n"
    if [ -d "$plugin_path/skills" ]; then
        report+="| Skill | Classification | Reason |\n"
        report+="|-------|---------------|--------|\n"
        for skill_dir in "$plugin_path/skills"/*/; do
            if [ -d "$skill_dir" ]; then
                local skill_name=$(basename "$skill_dir")

                # Check Jarvis skills
                local classification="ADOPT"
                local reason="New skill"

                if [ -d "$JARVIS_CLAUDE/skills/$skill_name" ]; then
                    classification="ADAPT"
                    reason="Skill exists, compare and merge"
                fi

                echo -e "  $skill_name: ${MAGENTA}$classification${NC} - $reason"
                report+="| $skill_name | $classification | $reason |\n"
            fi
        done
    else
        report+="*No skills to analyze*\n"
    fi
    report+="\n"

    # Summary
    print_section "Integration Summary"
    report+="## Integration Summary\n\n"

    local adopt_count=$(echo -e "$report" | grep -c "| ADOPT |" || true)
    local adapt_count=$(echo -e "$report" | grep -c "| ADAPT |" || true)
    local defer_count=$(echo -e "$report" | grep -c "| DEFER |" || true)
    local skip_count=$(echo -e "$report" | grep -c "| SKIP |" || true)

    echo "  ADOPT: $adopt_count components"
    echo "  ADAPT: $adapt_count components"
    echo "  DEFER: $defer_count components"
    echo "  SKIP:  $skip_count components"

    report+="- **ADOPT:** $adopt_count components\n"
    report+="- **ADAPT:** $adapt_count components\n"
    report+="- **DEFER:** $defer_count components\n"
    report+="- **SKIP:** $skip_count components\n\n"

    # Output report
    if [ -n "$output_file" ]; then
        echo -e "$report" > "$output_file"
        echo ""
        print_success "Analysis saved to: $output_file"
    else
        local default_output="$OUTPUT_DIR/${plugin_name}-analysis.md"
        echo -e "$report" > "$default_output"
        echo ""
        print_success "Analysis saved to: $default_output"
    fi
}

# ============================================================================
# FEATURE 4: REDUNDANCY SCAN (--scan-redundancy)
# ============================================================================

scan_redundancy() {
    local plugin_path="$1"

    if [ ! -d "$plugin_path" ]; then
        print_error "Plugin directory not found: $plugin_path"
        return 1
    fi

    plugin_path=$(cd "$plugin_path" && pwd)
    local plugin_name=$(basename "$plugin_path")

    print_header "Redundancy Scan: $plugin_name"

    print_info "This feature spawns the code-analyzer agent for semantic comparison."
    print_info "The agent will compare plugin functions against Jarvis codebase."
    echo ""

    # Generate analysis request for code-analyzer
    local analysis_request="$OUTPUT_DIR/${plugin_name}-redundancy-request.md"

    cat > "$analysis_request" << EOF
# Redundancy Analysis Request

## Plugin: $plugin_name
## Path: $plugin_path

## Instructions for code-analyzer agent:

1. **Reverse-engineer plugin functions:**
   - Read all scripts and hooks in the plugin
   - Document the purpose and functionality of each
   - Identify key operations performed

2. **Compare against Jarvis codebase:**
   - Search .claude/scripts/ for similar functionality
   - Search .claude/hooks/ for similar patterns
   - Search .claude/skills/ for overlapping capabilities

3. **Generate overlap report:**
   - List each plugin function
   - Note any Jarvis equivalent
   - Rate overlap: FULL (same function), PARTIAL (similar), NONE (unique)

## Plugin Components to Analyze:

EOF

    # List components for analysis
    if [ -d "$plugin_path/scripts" ]; then
        echo "### Scripts" >> "$analysis_request"
        for f in "$plugin_path/scripts"/*; do
            [ -f "$f" ] && echo "- $(basename "$f")" >> "$analysis_request"
        done
        echo "" >> "$analysis_request"
    fi

    if [ -d "$plugin_path/hooks" ]; then
        echo "### Hooks" >> "$analysis_request"
        for f in "$plugin_path/hooks"/*.sh; do
            [ -f "$f" ] && echo "- $(basename "$f")" >> "$analysis_request"
        done
        echo "" >> "$analysis_request"
    fi

    echo ""
    print_success "Analysis request generated: $analysis_request"
    echo ""
    echo -e "${CYAN}To run semantic analysis, invoke the code-analyzer agent:${NC}"
    echo ""
    echo "  claude \"/agent code-analyzer $analysis_request\""
    echo ""
    echo "Or use the Task tool with subagent_type=code-analyzer"
}

# ============================================================================
# FEATURE 5: DECOMPOSITION PLAN (--decompose)
# ============================================================================

decompose_plugin() {
    local plugin_path="$1"
    local output_file="$2"

    if [ ! -d "$plugin_path" ]; then
        print_error "Plugin directory not found: $plugin_path"
        return 1
    fi

    plugin_path=$(cd "$plugin_path" && pwd)
    local plugin_name=$(basename "$plugin_path")

    print_header "Decomposition Plan: $plugin_name"

    local report=""
    report+="# Decomposition Plan: $plugin_name\n\n"
    report+="**Source:** \`$plugin_path\`\n"
    report+="**Target:** \`$JARVIS_CLAUDE\`\n"
    report+="**Generated:** $(date '+%Y-%m-%d %H:%M:%S')\n\n"

    report+="## File Mapping\n\n"
    report+="| Source | Target | Action |\n"
    report+="|--------|--------|--------|\n"

    print_section "File Mapping"

    # Map commands
    if [ -d "$plugin_path/commands" ]; then
        for f in "$plugin_path/commands"/*.md; do
            if [ -f "$f" ]; then
                local fname=$(basename "$f")
                local target="$JARVIS_CLAUDE/commands/$fname"
                local action="COPY"
                [ -f "$target" ] && action="MERGE"
                echo "  commands/$fname → .claude/commands/$fname ($action)"
                report+="| commands/$fname | .claude/commands/$fname | $action |\n"
            fi
        done
    fi

    # Map hooks
    if [ -d "$plugin_path/hooks" ]; then
        for f in "$plugin_path/hooks"/*; do
            if [ -f "$f" ]; then
                local fname=$(basename "$f")
                local target="$JARVIS_CLAUDE/hooks/$fname"
                local action="COPY"
                [ -f "$target" ] && action="MERGE"
                echo "  hooks/$fname → .claude/hooks/$fname ($action)"
                report+="| hooks/$fname | .claude/hooks/$fname | $action |\n"
            fi
        done
    fi

    # Map scripts
    if [ -d "$plugin_path/scripts" ]; then
        for f in "$plugin_path/scripts"/*; do
            if [ -f "$f" ]; then
                local fname=$(basename "$f")
                local target="$JARVIS_CLAUDE/scripts/$fname"
                local action="COPY"
                [ -f "$target" ] && action="MERGE"
                echo "  scripts/$fname → .claude/scripts/$fname ($action)"
                report+="| scripts/$fname | .claude/scripts/$fname | $action |\n"
            fi
        done
    fi

    # Map skills
    if [ -d "$plugin_path/skills" ]; then
        for d in "$plugin_path/skills"/*/; do
            if [ -d "$d" ]; then
                local dname=$(basename "$d")
                local target="$JARVIS_CLAUDE/skills/$dname/"
                local action="COPY"
                [ -d "$target" ] && action="MERGE"
                echo "  skills/$dname/ → .claude/skills/$dname/ ($action)"
                report+="| skills/$dname/ | .claude/skills/$dname/ | $action |\n"
            fi
        done
    fi

    # Map agents
    if [ -d "$plugin_path/agents" ]; then
        for f in "$plugin_path/agents"/*.md; do
            if [ -f "$f" ]; then
                local fname=$(basename "$f")
                local target="$JARVIS_CLAUDE/agents/$fname"
                local action="COPY"
                [ -f "$target" ] && action="MERGE"
                echo "  agents/$fname → .claude/agents/$fname ($action)"
                report+="| agents/$fname | .claude/agents/$fname | $action |\n"
            fi
        done
    fi

    report+="\n"

    # Integration checklist
    print_section "Integration Checklist"
    report+="## Integration Checklist\n\n"

    local checklist=(
        "[ ] Review plugin README.md for usage notes"
        "[ ] Copy files marked COPY"
        "[ ] Merge files marked MERGE (manual review required)"
        "[ ] Update paths-registry.yaml if adding new paths"
        "[ ] Register any new hooks in settings.json"
        "[ ] Test commands work: /command-name --help"
        "[ ] Test hooks trigger correctly"
        "[ ] Update capability-matrix.md"
        "[ ] Commit changes with descriptive message"
    )

    for item in "${checklist[@]}"; do
        echo "  $item"
        report+="$item\n"
    done

    report+="\n## Notes\n\n"
    report+="- COPY: File doesn't exist in Jarvis, safe to copy\n"
    report+="- MERGE: File exists, requires manual review and merge\n"

    # Output report
    if [ -n "$output_file" ]; then
        echo -e "$report" > "$output_file"
        echo ""
        print_success "Decomposition plan saved to: $output_file"
    else
        local default_output="$OUTPUT_DIR/${plugin_name}-decompose.md"
        echo -e "$report" > "$default_output"
        echo ""
        print_success "Decomposition plan saved to: $default_output"
    fi
}

# ============================================================================
# FEATURE 6: INTERACTIVE BROWSER (--browse)
# ============================================================================

browse_plugins() {
    print_header "Plugin Browser"

    local plugins=()
    local plugin_paths=()
    local index=1

    # Collect plugins from marketplaces
    print_section "Available Plugins"

    for marketplace_dir in "$PLUGIN_MARKETPLACES"/*/; do
        if [ -d "$marketplace_dir" ]; then
            local marketplace=$(basename "$marketplace_dir")

            # Check for plugins subdirectory (claude-plugins-official style)
            if [ -d "$marketplace_dir/plugins" ]; then
                for plugin_dir in "$marketplace_dir/plugins"/*/; do
                    if [ -d "$plugin_dir" ]; then
                        local plugin_name=$(basename "$plugin_dir")
                        plugins+=("$marketplace/$plugin_name")
                        plugin_paths+=("$plugin_dir")
                        printf "  ${CYAN}%3d.${NC} %-20s (marketplace: %s)\n" "$index" "$plugin_name" "$marketplace"
                        index=$((index + 1))
                    fi
                done
            else
                # Direct plugin directories
                for plugin_dir in "$marketplace_dir"/*/; do
                    if [ -d "$plugin_dir/.claude-plugin" ] || [ -f "$plugin_dir/plugin.json" ]; then
                        local plugin_name=$(basename "$plugin_dir")
                        plugins+=("$marketplace/$plugin_name")
                        plugin_paths+=("$plugin_dir")
                        printf "  ${CYAN}%3d.${NC} %-20s (marketplace: %s)\n" "$index" "$plugin_name" "$marketplace"
                        index=$((index + 1))
                    fi
                done
            fi
        fi
    done

    echo ""
    echo -e "${BOLD}Total: $((index - 1)) plugins found${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  Enter a number to select a plugin, then choose an action:"
    echo "  - review   : Analyze plugin structure"
    echo "  - analyze  : Classify for integration"
    echo "  - decompose: Generate integration plan"
    echo ""
    echo -e "${CYAN}Example:${NC} To review plugin #5, run:"
    echo "  $0 --review \"${plugin_paths[4]:-/path/to/plugin}\""
    echo ""

    # If running interactively, allow selection
    if [ -t 0 ]; then
        echo -n "Select plugin number (or 'q' to quit): "
        read -r selection

        if [ "$selection" = "q" ] || [ "$selection" = "Q" ]; then
            echo "Exiting."
            exit 0
        fi

        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -lt "$index" ]; then
            local selected_path="${plugin_paths[$((selection - 1))]}"
            local selected_name="${plugins[$((selection - 1))]}"

            echo ""
            echo -e "Selected: ${GREEN}$selected_name${NC}"
            echo "Path: $selected_path"
            echo ""
            echo "Actions:"
            echo "  1. Review"
            echo "  2. Analyze"
            echo "  3. Decompose"
            echo "  4. Redundancy scan"
            echo ""
            echo -n "Select action (1-4): "
            read -r action

            case "$action" in
                1) review_plugin "$selected_path" ;;
                2) analyze_plugin "$selected_path" ;;
                3) decompose_plugin "$selected_path" ;;
                4) scan_redundancy "$selected_path" ;;
                *) echo "Invalid action"; exit 1 ;;
            esac
        else
            echo "Invalid selection"
            exit 1
        fi
    fi
}

# ============================================================================
# FEATURE 7: EXECUTE INTEGRATION (--execute)
# ============================================================================

execute_plugin() {
    local plugin_path="$1"

    if [ ! -d "$plugin_path" ]; then
        print_error "Plugin directory not found: $plugin_path"
        return 1
    fi

    plugin_path=$(cd "$plugin_path" && pwd)
    local plugin_name=$(basename "$plugin_path")
    local timestamp=$(date '+%Y%m%d-%H%M%S')

    if [ "$DRY_RUN" -eq 1 ]; then
        print_header "Execute Integration (DRY RUN): $plugin_name"
        print_warning "DRY RUN MODE - No changes will be made"
    else
        print_header "Execute Integration: $plugin_name"
    fi

    # Pre-flight checks
    print_section "Pre-flight Checks"

    local review_file="$OUTPUT_DIR/${plugin_name}-review.md"
    local analyze_file="$OUTPUT_DIR/${plugin_name}-analysis.md"
    local decompose_file="$OUTPUT_DIR/${plugin_name}-decompose.md"

    local preflight_ok=1

    if [ -f "$review_file" ]; then
        print_success "Review report exists: $review_file"
    else
        print_warning "Review report missing - generating..."
        if [ "$DRY_RUN" -eq 0 ]; then
            review_plugin "$plugin_path" "$review_file" > /dev/null 2>&1
        fi
    fi

    if [ -f "$analyze_file" ]; then
        print_success "Analysis report exists: $analyze_file"
    else
        print_warning "Analysis report missing - generating..."
        if [ "$DRY_RUN" -eq 0 ]; then
            analyze_plugin "$plugin_path" "$analyze_file" > /dev/null 2>&1
        fi
    fi

    if [ -f "$decompose_file" ]; then
        print_success "Decomposition plan exists: $decompose_file"
    else
        print_warning "Decomposition plan missing - generating..."
        if [ "$DRY_RUN" -eq 0 ]; then
            decompose_plugin "$plugin_path" "$decompose_file" > /dev/null 2>&1
        fi
    fi

    # Initialize rollback data
    local rollback_file="$ROLLBACK_DIR/${plugin_name}-${timestamp}.json"
    local rollback_data="{\"plugin\": \"$plugin_name\", \"source\": \"$plugin_path\", \"timestamp\": \"$timestamp\", \"operations\": ["
    local first_op=1

    # Track what we're doing
    local copied_files=()
    local created_dirs=()
    local backed_up_files=()

    # Execute file operations
    print_section "Executing File Operations"

    # Process commands
    if [ -d "$plugin_path/commands" ]; then
        for cmd_file in "$plugin_path/commands"/*.md; do
            if [ -f "$cmd_file" ]; then
                local fname=$(basename "$cmd_file")
                local target="$JARVIS_CLAUDE/commands/$fname"
                local action="COPY"

                if [ -f "$target" ]; then
                    action="MERGE"
                    # Backup existing file
                    local backup="$target.backup-$timestamp"
                    if [ "$DRY_RUN" -eq 1 ]; then
                        echo -e "  ${YELLOW}[DRY RUN]${NC} Would backup: $target → $backup"
                        echo -e "  ${YELLOW}[DRY RUN]${NC} Would MERGE: commands/$fname (manual review needed)"
                    else
                        cp "$target" "$backup"
                        backed_up_files+=("$backup")
                        print_warning "MERGE needed: commands/$fname (backed up existing)"
                        # For MERGE, we still copy but flag for manual review
                        cp "$cmd_file" "$target"
                        copied_files+=("$target")
                    fi
                else
                    if [ "$DRY_RUN" -eq 1 ]; then
                        echo -e "  ${YELLOW}[DRY RUN]${NC} Would COPY: commands/$fname → .claude/commands/$fname"
                    else
                        cp "$cmd_file" "$target"
                        copied_files+=("$target")
                        print_success "COPIED: commands/$fname"
                    fi
                fi

                # Add to rollback data
                if [ $first_op -eq 0 ]; then
                    rollback_data+=","
                fi
                first_op=0
                rollback_data+="{\"type\": \"file\", \"action\": \"$action\", \"source\": \"$cmd_file\", \"target\": \"$target\"}"
            fi
        done
    fi

    # Process hooks
    if [ -d "$plugin_path/hooks" ]; then
        # Create hooks directory if needed
        if [ ! -d "$JARVIS_CLAUDE/hooks" ]; then
            if [ "$DRY_RUN" -eq 1 ]; then
                echo -e "  ${YELLOW}[DRY RUN]${NC} Would create directory: .claude/hooks/"
            else
                mkdir -p "$JARVIS_CLAUDE/hooks"
                created_dirs+=("$JARVIS_CLAUDE/hooks")
            fi
        fi

        for hook_file in "$plugin_path/hooks"/*; do
            if [ -f "$hook_file" ]; then
                local fname=$(basename "$hook_file")
                local target="$JARVIS_CLAUDE/hooks/$fname"
                local action="COPY"

                if [ -f "$target" ]; then
                    action="MERGE"
                    local backup="$target.backup-$timestamp"
                    if [ "$DRY_RUN" -eq 1 ]; then
                        echo -e "  ${YELLOW}[DRY RUN]${NC} Would backup: $target → $backup"
                        echo -e "  ${YELLOW}[DRY RUN]${NC} Would MERGE: hooks/$fname"
                    else
                        cp "$target" "$backup"
                        backed_up_files+=("$backup")
                        cp "$hook_file" "$target"
                        copied_files+=("$target")
                        # Make executable if it's a shell script
                        [[ "$fname" == *.sh ]] && chmod +x "$target"
                        print_warning "MERGED: hooks/$fname (backed up existing)"
                    fi
                else
                    if [ "$DRY_RUN" -eq 1 ]; then
                        echo -e "  ${YELLOW}[DRY RUN]${NC} Would COPY: hooks/$fname → .claude/hooks/$fname"
                    else
                        cp "$hook_file" "$target"
                        copied_files+=("$target")
                        [[ "$fname" == *.sh ]] && chmod +x "$target"
                        print_success "COPIED: hooks/$fname"
                    fi
                fi

                if [ $first_op -eq 0 ]; then
                    rollback_data+=","
                fi
                first_op=0
                rollback_data+="{\"type\": \"file\", \"action\": \"$action\", \"source\": \"$hook_file\", \"target\": \"$target\"}"
            fi
        done
    fi

    # Process scripts
    if [ -d "$plugin_path/scripts" ]; then
        for script_file in "$plugin_path/scripts"/*; do
            if [ -f "$script_file" ]; then
                local fname=$(basename "$script_file")
                local target="$JARVIS_CLAUDE/scripts/$fname"
                local action="COPY"

                if [ -f "$target" ]; then
                    action="MERGE"
                    local backup="$target.backup-$timestamp"
                    if [ "$DRY_RUN" -eq 1 ]; then
                        echo -e "  ${YELLOW}[DRY RUN]${NC} Would backup and MERGE: scripts/$fname"
                    else
                        cp "$target" "$backup"
                        backed_up_files+=("$backup")
                        cp "$script_file" "$target"
                        copied_files+=("$target")
                        chmod +x "$target"
                        print_warning "MERGED: scripts/$fname (backed up existing)"
                    fi
                else
                    if [ "$DRY_RUN" -eq 1 ]; then
                        echo -e "  ${YELLOW}[DRY RUN]${NC} Would COPY: scripts/$fname"
                    else
                        cp "$script_file" "$target"
                        copied_files+=("$target")
                        chmod +x "$target"
                        print_success "COPIED: scripts/$fname"
                    fi
                fi

                if [ $first_op -eq 0 ]; then
                    rollback_data+=","
                fi
                first_op=0
                rollback_data+="{\"type\": \"file\", \"action\": \"$action\", \"source\": \"$script_file\", \"target\": \"$target\"}"
            fi
        done
    fi

    # Process skills (directories)
    if [ -d "$plugin_path/skills" ]; then
        for skill_dir in "$plugin_path/skills"/*/; do
            if [ -d "$skill_dir" ]; then
                local dname=$(basename "$skill_dir")
                local target="$JARVIS_CLAUDE/skills/$dname"
                local action="COPY"

                if [ -d "$target" ]; then
                    action="MERGE"
                    local backup="$target.backup-$timestamp"
                    if [ "$DRY_RUN" -eq 1 ]; then
                        echo -e "  ${YELLOW}[DRY RUN]${NC} Would backup and MERGE: skills/$dname/"
                    else
                        mv "$target" "$backup"
                        backed_up_files+=("$backup")
                        cp -r "$skill_dir" "$target"
                        created_dirs+=("$target")
                        print_warning "MERGED: skills/$dname/ (backed up existing)"
                    fi
                else
                    if [ "$DRY_RUN" -eq 1 ]; then
                        echo -e "  ${YELLOW}[DRY RUN]${NC} Would COPY: skills/$dname/"
                    else
                        cp -r "$skill_dir" "$target"
                        created_dirs+=("$target")
                        print_success "COPIED: skills/$dname/"
                    fi
                fi

                if [ $first_op -eq 0 ]; then
                    rollback_data+=","
                fi
                first_op=0
                rollback_data+="{\"type\": \"directory\", \"action\": \"$action\", \"source\": \"$skill_dir\", \"target\": \"$target\"}"
            fi
        done
    fi

    # Process agents
    if [ -d "$plugin_path/agents" ]; then
        # Create agents directory if needed
        if [ ! -d "$JARVIS_CLAUDE/agents" ]; then
            if [ "$DRY_RUN" -eq 1 ]; then
                echo -e "  ${YELLOW}[DRY RUN]${NC} Would create directory: .claude/agents/"
            else
                mkdir -p "$JARVIS_CLAUDE/agents"
                created_dirs+=("$JARVIS_CLAUDE/agents")
            fi
        fi

        for agent_file in "$plugin_path/agents"/*.md; do
            if [ -f "$agent_file" ]; then
                local fname=$(basename "$agent_file")
                local target="$JARVIS_CLAUDE/agents/$fname"
                local action="COPY"

                if [ -f "$target" ]; then
                    action="MERGE"
                    local backup="$target.backup-$timestamp"
                    if [ "$DRY_RUN" -eq 1 ]; then
                        echo -e "  ${YELLOW}[DRY RUN]${NC} Would backup and MERGE: agents/$fname"
                    else
                        cp "$target" "$backup"
                        backed_up_files+=("$backup")
                        cp "$agent_file" "$target"
                        copied_files+=("$target")
                        print_warning "MERGED: agents/$fname (backed up existing)"
                    fi
                else
                    if [ "$DRY_RUN" -eq 1 ]; then
                        echo -e "  ${YELLOW}[DRY RUN]${NC} Would COPY: agents/$fname"
                    else
                        cp "$agent_file" "$target"
                        copied_files+=("$target")
                        print_success "COPIED: agents/$fname"
                    fi
                fi

                if [ $first_op -eq 0 ]; then
                    rollback_data+=","
                fi
                first_op=0
                rollback_data+="{\"type\": \"file\", \"action\": \"$action\", \"source\": \"$agent_file\", \"target\": \"$target\"}"
            fi
        done
    fi

    # Close rollback JSON
    rollback_data+="]}"

    # Post-integration validation
    print_section "Post-Integration Validation"

    if [ "$DRY_RUN" -eq 1 ]; then
        echo -e "  ${YELLOW}[DRY RUN]${NC} Would validate all copied files exist"
        echo -e "  ${YELLOW}[DRY RUN]${NC} Would run syntax checks on scripts"
        echo -e "  ${YELLOW}[DRY RUN]${NC} Would save rollback file to: $rollback_file"
    else
        local validation_ok=1

        # Verify copied files exist
        for f in "${copied_files[@]}"; do
            if [ -f "$f" ]; then
                print_success "Verified: $f"
            else
                print_error "Missing: $f"
                validation_ok=0
            fi
        done

        # Verify created directories exist
        for d in "${created_dirs[@]}"; do
            if [ -d "$d" ]; then
                print_success "Verified directory: $d"
            else
                print_error "Missing directory: $d"
                validation_ok=0
            fi
        done

        # Syntax check shell scripts
        for f in "${copied_files[@]}"; do
            if [[ "$f" == *.sh ]]; then
                if bash -n "$f" 2>/dev/null; then
                    print_success "Syntax OK: $(basename "$f")"
                else
                    print_warning "Syntax issues: $(basename "$f")"
                fi
            fi
        done

        # Save rollback file
        echo "$rollback_data" > "$rollback_file"
        print_success "Rollback file saved: $rollback_file"
    fi

    # Summary
    print_section "Integration Summary"

    local total_files=${#copied_files[@]}
    local total_dirs=${#created_dirs[@]}
    local total_backups=${#backed_up_files[@]}

    if [ "$DRY_RUN" -eq 1 ]; then
        echo -e "  ${YELLOW}DRY RUN COMPLETE - No changes were made${NC}"
        echo ""
        echo "  To execute for real, run without --dry-run:"
        echo "  $0 --execute $plugin_path"
    else
        echo "  Files copied/merged: $total_files"
        echo "  Directories created: $total_dirs"
        echo "  Backups created: $total_backups"
        echo ""
        print_success "Integration complete for: $plugin_name"
        echo ""
        echo "  To rollback this integration:"
        echo "  $0 --rollback $rollback_file"
    fi
}

# ============================================================================
# FEATURE 8: ROLLBACK INTEGRATION (--rollback)
# ============================================================================

rollback_plugin() {
    local rollback_file="$1"

    if [ ! -f "$rollback_file" ]; then
        print_error "Rollback file not found: $rollback_file"
        return 1
    fi

    print_header "Rollback Integration"

    # Parse rollback file
    local plugin_name=$(grep -o '"plugin"[[:space:]]*:[[:space:]]*"[^"]*"' "$rollback_file" | sed 's/.*: *"\([^"]*\)".*/\1/')
    local timestamp=$(grep -o '"timestamp"[[:space:]]*:[[:space:]]*"[^"]*"' "$rollback_file" | sed 's/.*: *"\([^"]*\)".*/\1/')

    print_info "Plugin: $plugin_name"
    print_info "Integration timestamp: $timestamp"
    echo ""

    print_section "Rolling Back Operations"

    local rolled_back=0
    local errors=0

    # Extract targets from the JSON and process them
    # This is a simple parser - for complex JSON, would use jq
    local targets=$(grep -o '"target"[[:space:]]*:[[:space:]]*"[^"]*"' "$rollback_file" | sed 's/.*: *"\([^"]*\)".*/\1/')

    while IFS= read -r target; do
        if [ -z "$target" ]; then
            continue
        fi

        local backup="$target.backup-$timestamp"

        if [ -f "$target" ] || [ -d "$target" ]; then
            # Check if there's a backup to restore
            if [ -f "$backup" ]; then
                # Restore from backup
                rm -rf "$target"
                mv "$backup" "$target"
                print_success "Restored from backup: $target"
                rolled_back=$((rolled_back + 1))
            elif [ -d "$backup" ]; then
                # Restore directory from backup
                rm -rf "$target"
                mv "$backup" "$target"
                print_success "Restored directory from backup: $target"
                rolled_back=$((rolled_back + 1))
            else
                # No backup means this was a new file - remove it
                rm -rf "$target"
                print_success "Removed: $target"
                rolled_back=$((rolled_back + 1))
            fi
        else
            print_warning "Target not found (may have been manually removed): $target"
        fi
    done <<< "$targets"

    # Clean up any remaining backup files
    print_section "Cleaning Up Backups"
    local backup_pattern="*.backup-$timestamp"
    local found_backups=$(find "$JARVIS_CLAUDE" -name "$backup_pattern" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$found_backups" -gt 0 ]; then
        find "$JARVIS_CLAUDE" -name "$backup_pattern" -exec rm -rf {} \; 2>/dev/null
        print_success "Cleaned up $found_backups remaining backup files"
    else
        print_info "No remaining backup files to clean"
    fi

    # Summary
    print_section "Rollback Summary"
    echo "  Operations rolled back: $rolled_back"

    if [ $errors -eq 0 ]; then
        print_success "Rollback complete for: $plugin_name"

        # Optionally remove the rollback file
        echo ""
        echo "  Rollback file can be removed:"
        echo "  rm $rollback_file"
    else
        print_error "Rollback completed with $errors errors"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    local command=""
    local plugin_path=""
    local output_file=""
    local rollback_file=""
    local verbose=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --discover)
                command="discover"
                shift
                plugin_path="$1"
                shift
                ;;
            --review)
                command="review"
                shift
                plugin_path="$1"
                shift
                ;;
            --analyze)
                command="analyze"
                shift
                plugin_path="$1"
                shift
                ;;
            --scan-redundancy)
                command="scan-redundancy"
                shift
                plugin_path="$1"
                shift
                ;;
            --decompose)
                command="decompose"
                shift
                plugin_path="$1"
                shift
                ;;
            --browse)
                command="browse"
                shift
                ;;
            --execute)
                command="execute"
                shift
                plugin_path="$1"
                shift
                ;;
            --rollback)
                command="rollback"
                shift
                rollback_file="$1"
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            -o|--output)
                shift
                output_file="$1"
                shift
                ;;
            -v|--verbose)
                verbose=1
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done

    if [ -z "$command" ]; then
        usage
    fi

    case "$command" in
        discover)
            [ -z "$plugin_path" ] && { echo "Error: --discover requires a plugin name"; exit 1; }
            discover_plugin "$plugin_path"
            ;;
        review)
            [ -z "$plugin_path" ] && { echo "Error: --review requires a plugin path"; exit 1; }
            review_plugin "$plugin_path" "$output_file"
            ;;
        analyze)
            [ -z "$plugin_path" ] && { echo "Error: --analyze requires a plugin path"; exit 1; }
            analyze_plugin "$plugin_path" "$output_file"
            ;;
        scan-redundancy)
            [ -z "$plugin_path" ] && { echo "Error: --scan-redundancy requires a plugin path"; exit 1; }
            scan_redundancy "$plugin_path"
            ;;
        decompose)
            [ -z "$plugin_path" ] && { echo "Error: --decompose requires a plugin path"; exit 1; }
            decompose_plugin "$plugin_path" "$output_file"
            ;;
        browse)
            browse_plugins
            ;;
        execute)
            [ -z "$plugin_path" ] && { echo "Error: --execute requires a plugin path"; exit 1; }
            execute_plugin "$plugin_path"
            ;;
        rollback)
            [ -z "$rollback_file" ] && { echo "Error: --rollback requires a rollback file path"; exit 1; }
            rollback_plugin "$rollback_file"
            ;;
    esac
}

main "$@"
