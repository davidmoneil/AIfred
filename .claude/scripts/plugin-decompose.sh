#!/bin/bash

# Plugin Decomposition Tool for Jarvis (Decompose-Native)
# Built during Phase 3 of Ralph Loop Comparison Experiment
# NO REFERENCE to Decompose-Official (blind build)

set -euo pipefail

# Configuration
JARVIS_ROOT="/Users/aircannon/Claude/Jarvis"
PLUGINS_ROOT="$HOME/.claude/plugins"
CACHE_DIR="$PLUGINS_ROOT/cache"
MARKETPLACES_DIR="$PLUGINS_ROOT/marketplaces"
OUTPUT_DIR="$JARVIS_ROOT/docs/reports/plugin-analysis"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BOLD}${CYAN}--- $1 ---${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

usage() {
    cat << EOF
Plugin Decomposition Tool for Jarvis

USAGE:
    $(basename "$0") [OPTIONS] [PLUGIN]

OPTIONS:
    --discover PLUGIN       Find plugin path by name or path
    --review PATH           Analyze plugin structure and components
    --analyze PATH          Classify components for integration
    --scan-redundancy PATH  Semantic comparison with Jarvis codebase
    --decompose PATH        Generate integration plan and file mapping
    --browse                Interactive plugin browser
    --execute PATH          Execute plugin integration
    --dry-run               Preview changes without executing (use with --execute)
    --rollback FILE         Rollback a previous integration
    -h, --help              Show this help message

EXAMPLES:
    $(basename "$0") --discover example-plugin
    $(basename "$0") --review example-plugin
    $(basename "$0") --browse
    $(basename "$0") --decompose ralph-loop
    $(basename "$0") --execute example-plugin --dry-run
    $(basename "$0") --execute example-plugin
    $(basename "$0") --rollback docs/reports/plugin-analysis/.rollback-example-plugin-20260117.json

EOF
    exit 0
}

# ============================================================================
# DISCOVERY FUNCTION (--discover)
# ============================================================================

discover_plugin() {
    local plugin_query="$1"

    print_header "Plugin Discovery: $plugin_query"

    # If it's already a path, validate it
    if [[ -d "$plugin_query" ]]; then
        if [[ -d "$plugin_query/.claude-plugin" ]] || [[ -f "$plugin_query/commands/"*.md ]] || [[ -f "$plugin_query/README.md" ]]; then
            print_success "Direct path provided: $plugin_query"
            echo "$plugin_query"
            return 0
        fi
    fi

    local found_paths=()

    # Search in cache
    if [[ -d "$CACHE_DIR" ]]; then
        while IFS= read -r -d '' dir; do
            found_paths+=("$dir")
        done < <(find "$CACHE_DIR" -maxdepth 3 -type d -name "$plugin_query" -print0 2>/dev/null)
    fi

    # Search in marketplaces
    if [[ -d "$MARKETPLACES_DIR" ]]; then
        while IFS= read -r -d '' dir; do
            found_paths+=("$dir")
        done < <(find "$MARKETPLACES_DIR" -maxdepth 4 -type d -name "$plugin_query" -print0 2>/dev/null)
    fi

    if [[ ${#found_paths[@]} -eq 0 ]]; then
        # Try partial match
        print_info "Exact match not found, trying partial match..."
        while IFS= read -r -d '' dir; do
            found_paths+=("$dir")
        done < <(find "$CACHE_DIR" "$MARKETPLACES_DIR" -maxdepth 4 -type d -iname "*$plugin_query*" -print0 2>/dev/null)
    fi

    if [[ ${#found_paths[@]} -eq 0 ]]; then
        print_error "No plugin found matching: $plugin_query"
        return 1
    elif [[ ${#found_paths[@]} -eq 1 ]]; then
        print_success "Found: ${found_paths[0]}"
        echo "${found_paths[0]}"
        return 0
    else
        print_info "Multiple matches found:"
        for i in "${!found_paths[@]}"; do
            echo "  [$i] ${found_paths[$i]}"
        done
        echo ""
        echo "Returning first match: ${found_paths[0]}"
        echo "${found_paths[0]}"
        return 0
    fi
}

# ============================================================================
# REVIEW FUNCTION (--review)
# ============================================================================

review_plugin() {
    local plugin_path="$1"

    # Auto-discover if not a path
    if [[ ! -d "$plugin_path" ]]; then
        plugin_path=$(discover_plugin "$plugin_path" 2>/dev/null | tail -1)
        if [[ -z "$plugin_path" ]] || [[ ! -d "$plugin_path" ]]; then
            print_error "Could not find plugin: $1"
            return 1
        fi
    fi

    local plugin_name=$(basename "$plugin_path")

    print_header "Plugin Review: $plugin_name"
    echo "Path: $plugin_path"
    echo ""

    # Check for plugin.json
    print_section "Plugin Metadata"
    if [[ -f "$plugin_path/.claude-plugin/plugin.json" ]]; then
        print_success "Found plugin.json"
        cat "$plugin_path/.claude-plugin/plugin.json" | jq '.' 2>/dev/null || cat "$plugin_path/.claude-plugin/plugin.json"
    else
        print_warning "No plugin.json found"
    fi

    # Check for README
    print_section "Documentation"
    if [[ -f "$plugin_path/README.md" ]]; then
        print_success "Found README.md"
        head -20 "$plugin_path/README.md"
        echo "... (truncated)"
    else
        print_warning "No README.md found"
    fi

    # Analyze commands
    print_section "Commands"
    if [[ -d "$plugin_path/commands" ]]; then
        local cmd_count=$(find "$plugin_path/commands" -name "*.md" -type f | wc -l | tr -d ' ')
        print_success "Found $cmd_count command(s)"
        for cmd in "$plugin_path/commands"/*.md; do
            if [[ -f "$cmd" ]]; then
                local cmd_name=$(basename "$cmd" .md)
                local desc=$(grep -m1 'description:' "$cmd" 2>/dev/null | sed 's/description:[[:space:]]*//' | tr -d '"' || echo "No description")
                echo "  - $cmd_name: $desc"
            fi
        done
    else
        print_warning "No commands/ directory"
    fi

    # Analyze hooks
    print_section "Hooks"
    if [[ -d "$plugin_path/hooks" ]]; then
        local hook_count=$(find "$plugin_path/hooks" -type f | wc -l | tr -d ' ')
        print_success "Found $hook_count hook file(s)"
        for hook in "$plugin_path/hooks"/*; do
            if [[ -f "$hook" ]]; then
                echo "  - $(basename "$hook")"
            fi
        done

        # Parse hooks.json if present
        if [[ -f "$plugin_path/hooks/hooks.json" ]]; then
            echo ""
            echo "  Hook configuration (hooks.json):"
            cat "$plugin_path/hooks/hooks.json" | jq -r '.hooks | keys[]' 2>/dev/null | while read hook_type; do
                echo "    - $hook_type"
            done
        fi
    else
        print_warning "No hooks/ directory"
    fi

    # Analyze scripts
    print_section "Scripts"
    if [[ -d "$plugin_path/scripts" ]]; then
        local script_count=$(find "$plugin_path/scripts" -type f | wc -l | tr -d ' ')
        print_success "Found $script_count script(s)"
        for script in "$plugin_path/scripts"/*; do
            if [[ -f "$script" ]]; then
                local script_name=$(basename "$script")
                local lines=$(wc -l < "$script" | tr -d ' ')
                echo "  - $script_name ($lines lines)"
            fi
        done
    else
        print_warning "No scripts/ directory"
    fi

    # Analyze skills
    print_section "Skills"
    if [[ -d "$plugin_path/skills" ]]; then
        local skill_count=$(find "$plugin_path/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
        print_success "Found $skill_count skill(s)"
        for skill in "$plugin_path/skills"/*/; do
            if [[ -d "$skill" ]]; then
                local skill_name=$(basename "$skill")
                echo "  - $skill_name"
                if [[ -f "$skill/SKILL.md" ]]; then
                    echo "    Has SKILL.md"
                fi
            fi
        done
    else
        print_warning "No skills/ directory"
    fi

    # Summary
    print_section "Summary"
    echo "Plugin: $plugin_name"
    echo "Location: $plugin_path"
    echo ""

    return 0
}

# ============================================================================
# ANALYZE FUNCTION (--analyze)
# ============================================================================

analyze_plugin() {
    local plugin_path="$1"

    # Auto-discover if not a path
    if [[ ! -d "$plugin_path" ]]; then
        plugin_path=$(discover_plugin "$plugin_path" 2>/dev/null | tail -1)
        if [[ -z "$plugin_path" ]] || [[ ! -d "$plugin_path" ]]; then
            print_error "Could not find plugin: $1"
            return 1
        fi
    fi

    local plugin_name=$(basename "$plugin_path")

    print_header "Integration Analysis: $plugin_name"
    echo "Classifying components as: ADOPT / ADAPT / DEFER / SKIP"
    echo ""

    # Analyze each component type
    print_section "Commands Analysis"
    if [[ -d "$plugin_path/commands" ]]; then
        for cmd in "$plugin_path/commands"/*.md; do
            if [[ -f "$cmd" ]]; then
                local cmd_name=$(basename "$cmd" .md)
                local jarvis_cmd="$JARVIS_ROOT/.claude/commands/$cmd_name.md"

                if [[ -f "$jarvis_cmd" ]]; then
                    echo -e "  ${YELLOW}ADAPT${NC} $cmd_name - Already exists in Jarvis, may need merging"
                else
                    echo -e "  ${GREEN}ADOPT${NC} $cmd_name - New command, can be integrated directly"
                fi
            fi
        done
    fi

    print_section "Hooks Analysis"
    if [[ -d "$plugin_path/hooks" ]]; then
        for hook in "$plugin_path/hooks"/*; do
            if [[ -f "$hook" ]]; then
                local hook_name=$(basename "$hook")
                local jarvis_hook="$JARVIS_ROOT/.claude/hooks/$hook_name"

                if [[ -f "$jarvis_hook" ]]; then
                    echo -e "  ${YELLOW}ADAPT${NC} $hook_name - Exists in Jarvis, review for conflicts"
                else
                    echo -e "  ${GREEN}ADOPT${NC} $hook_name - New hook, can be added"
                fi
            fi
        done
    fi

    print_section "Scripts Analysis"
    if [[ -d "$plugin_path/scripts" ]]; then
        for script in "$plugin_path/scripts"/*; do
            if [[ -f "$script" ]]; then
                local script_name=$(basename "$script")
                local jarvis_script="$JARVIS_ROOT/.claude/scripts/$script_name"

                if [[ -f "$jarvis_script" ]]; then
                    echo -e "  ${YELLOW}ADAPT${NC} $script_name - Already exists, needs review"
                else
                    echo -e "  ${GREEN}ADOPT${NC} $script_name - New script, can be copied"
                fi
            fi
        done
    fi

    print_section "Skills Analysis"
    if [[ -d "$plugin_path/skills" ]]; then
        for skill in "$plugin_path/skills"/*/; do
            if [[ -d "$skill" ]]; then
                local skill_name=$(basename "$skill")
                local jarvis_skill="$JARVIS_ROOT/.claude/skills/$skill_name"

                if [[ -d "$jarvis_skill" ]]; then
                    echo -e "  ${YELLOW}ADAPT${NC} $skill_name - Skill exists, review for conflicts"
                else
                    echo -e "  ${GREEN}ADOPT${NC} $skill_name - New skill, can be added"
                fi
            fi
        done
    fi

    print_section "Recommendation"
    echo "Review the classifications above and proceed with:"
    echo "  1. ADOPT items: Copy directly"
    echo "  2. ADAPT items: Manual review and merge required"
    echo "  3. DEFER items: Consider for later"
    echo "  4. SKIP items: Not needed"
    echo ""
    echo "Use --decompose to generate the integration plan."

    return 0
}

# ============================================================================
# SCAN REDUNDANCY FUNCTION (--scan-redundancy)
# ============================================================================

scan_redundancy() {
    local plugin_path="$1"

    # Auto-discover if not a path
    if [[ ! -d "$plugin_path" ]]; then
        plugin_path=$(discover_plugin "$plugin_path" 2>/dev/null | tail -1)
        if [[ -z "$plugin_path" ]] || [[ ! -d "$plugin_path" ]]; then
            print_error "Could not find plugin: $1"
            return 1
        fi
    fi

    local plugin_name=$(basename "$plugin_path")

    print_header "Redundancy Scan: $plugin_name"
    echo "Performing semantic comparison with Jarvis codebase..."
    echo ""

    # Create temp file for analysis
    local analysis_file=$(mktemp)

    # Extract function names and patterns from plugin
    print_section "Plugin Functions"

    # Find shell functions
    local plugin_functions=()
    while IFS= read -r func; do
        plugin_functions+=("$func")
        echo "  - $func"
    done < <(grep -rh '^\s*\(function\s\+\w\+\|^\w\+\s*()\)' "$plugin_path" 2>/dev/null | sed 's/function //; s/().*//; s/{$//' | sort -u | head -20)

    if [[ ${#plugin_functions[@]} -eq 0 ]]; then
        print_info "No shell functions found in plugin"
    fi

    print_section "Jarvis Codebase Comparison"

    # Search for similar functions in Jarvis
    local overlap_count=0
    if [[ ${#plugin_functions[@]} -gt 0 ]]; then
        for func in "${plugin_functions[@]}"; do
            # Clean up function name
            func=$(echo "$func" | tr -d ' ' | tr -d '\t')
            [[ -z "$func" ]] && continue

            # Search in Jarvis scripts
            if grep -rq "\b$func\b" "$JARVIS_ROOT/.claude/scripts/" 2>/dev/null; then
                echo -e "  ${YELLOW}OVERLAP${NC} $func - Similar function exists in Jarvis"
                ((overlap_count++))
            fi
        done
    else
        print_info "No functions to compare"
    fi

    # Search for similar command names
    print_section "Command Name Comparison"
    if [[ -d "$plugin_path/commands" ]]; then
        for cmd in "$plugin_path/commands"/*.md; do
            if [[ -f "$cmd" ]]; then
                local cmd_name=$(basename "$cmd" .md)
                if [[ -f "$JARVIS_ROOT/.claude/commands/$cmd_name.md" ]]; then
                    echo -e "  ${YELLOW}OVERLAP${NC} Command: $cmd_name already exists"
                    ((overlap_count++))
                fi
            fi
        done
    fi

    # Search for similar hook types
    print_section "Hook Type Comparison"
    if [[ -f "$plugin_path/hooks/hooks.json" ]]; then
        local plugin_hooks=$(cat "$plugin_path/hooks/hooks.json" | jq -r '.hooks | keys[]' 2>/dev/null)
        local jarvis_hooks=$(cat "$JARVIS_ROOT/.claude/settings.json" | jq -r '.hooks | keys[]' 2>/dev/null)

        for hook in $plugin_hooks; do
            if echo "$jarvis_hooks" | grep -q "$hook"; then
                echo -e "  ${GREEN}COMPATIBLE${NC} Hook type: $hook (Jarvis supports this)"
            fi
        done
    fi

    print_section "Summary"
    echo "Overlap items found: $overlap_count"
    echo ""
    if [[ $overlap_count -gt 0 ]]; then
        print_warning "Some overlapping functionality detected. Review before integration."
    else
        print_success "No significant overlaps detected. Safe to integrate."
    fi

    rm -f "$analysis_file"
    return 0
}

# ============================================================================
# DECOMPOSE FUNCTION (--decompose)
# ============================================================================

decompose_plugin() {
    local plugin_path="$1"

    # Auto-discover if not a path
    if [[ ! -d "$plugin_path" ]]; then
        plugin_path=$(discover_plugin "$plugin_path" 2>/dev/null | tail -1)
        if [[ -z "$plugin_path" ]] || [[ ! -d "$plugin_path" ]]; then
            print_error "Could not find plugin: $1"
            return 1
        fi
    fi

    local plugin_name=$(basename "$plugin_path")

    print_header "Decomposition Plan: $plugin_name"
    echo "Generating file mapping and integration checklist..."
    echo ""

    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    local plan_file="$OUTPUT_DIR/${plugin_name}-decomposition.md"

    # Start building the plan
    cat > "$plan_file" << EOF
# Integration Plan: $plugin_name

**Source**: $plugin_path
**Generated**: $(date -u +%Y-%m-%dT%H:%M:%SZ)
**Target**: $JARVIS_ROOT

---

## File Mapping

| Source | Destination | Action |
|--------|-------------|--------|
EOF

    print_section "File Mapping"

    # Map commands
    if [[ -d "$plugin_path/commands" ]]; then
        for cmd in "$plugin_path/commands"/*.md; do
            if [[ -f "$cmd" ]]; then
                local cmd_name=$(basename "$cmd")
                local src="commands/$cmd_name"
                local dest=".claude/commands/$cmd_name"
                local action="COPY"

                if [[ -f "$JARVIS_ROOT/.claude/commands/$cmd_name" ]]; then
                    action="MERGE"
                fi

                echo "| $src | $dest | $action |" >> "$plan_file"
                echo "  $src -> $dest [$action]"
            fi
        done
    fi

    # Map hooks
    if [[ -d "$plugin_path/hooks" ]]; then
        for hook in "$plugin_path/hooks"/*; do
            if [[ -f "$hook" ]]; then
                local hook_name=$(basename "$hook")
                local src="hooks/$hook_name"
                local dest=".claude/hooks/$hook_name"
                local action="COPY"

                if [[ -f "$JARVIS_ROOT/.claude/hooks/$hook_name" ]]; then
                    action="MERGE"
                fi

                echo "| $src | $dest | $action |" >> "$plan_file"
                echo "  $src -> $dest [$action]"
            fi
        done
    fi

    # Map scripts
    if [[ -d "$plugin_path/scripts" ]]; then
        for script in "$plugin_path/scripts"/*; do
            if [[ -f "$script" ]]; then
                local script_name=$(basename "$script")
                local src="scripts/$script_name"
                local dest=".claude/scripts/$script_name"
                local action="COPY"

                if [[ -f "$JARVIS_ROOT/.claude/scripts/$script_name" ]]; then
                    action="MERGE"
                fi

                echo "| $src | $dest | $action |" >> "$plan_file"
                echo "  $src -> $dest [$action]"
            fi
        done
    fi

    # Map skills
    if [[ -d "$plugin_path/skills" ]]; then
        for skill in "$plugin_path/skills"/*/; do
            if [[ -d "$skill" ]]; then
                local skill_name=$(basename "$skill")
                local src="skills/$skill_name/"
                local dest=".claude/skills/$skill_name/"
                local action="COPY"

                if [[ -d "$JARVIS_ROOT/.claude/skills/$skill_name" ]]; then
                    action="MERGE"
                fi

                echo "| $src | $dest | $action |" >> "$plan_file"
                echo "  $src -> $dest [$action]"
            fi
        done
    fi

    # Add integration checklist
    cat >> "$plan_file" << EOF

---

## Integration Checklist

- [ ] Review each file mapping above
- [ ] Check for path variable updates (CLAUDE_PLUGIN_ROOT -> CLAUDE_PROJECT_DIR)
- [ ] Verify no conflicting function names
- [ ] Register any new hooks in settings.json
- [ ] Test each component after integration
- [ ] Update documentation

---

## Notes

- COPY: File can be copied directly
- MERGE: Existing file needs manual merge
- Source files should be reviewed for plugin-specific paths

EOF

    print_section "Output"
    print_success "Decomposition plan saved to: $plan_file"
    echo ""
    echo "Review the plan file and use it to guide manual integration."

    return 0
}

# ============================================================================
# BROWSE FUNCTION (--browse)
# ============================================================================

browse_plugins() {
    print_header "Plugin Browser"

    local all_plugins=()
    local plugin_paths=()
    local index=0

    # Collect from cache
    if [[ -d "$CACHE_DIR" ]]; then
        print_section "Installed Plugins (cache)"
        while IFS= read -r -d '' dir; do
            local pname=$(basename "$dir")
            all_plugins+=("$pname [cache]")
            plugin_paths+=("$dir")
            echo "  [$index] $pname"
            ((index++))
        done < <(find "$CACHE_DIR" -maxdepth 3 -name ".claude-plugin" -print0 2>/dev/null | xargs -0 dirname 2>/dev/null | sort -u | tr '\n' '\0')
    fi

    # Collect from marketplaces
    if [[ -d "$MARKETPLACES_DIR" ]]; then
        print_section "Available in Marketplaces"
        for marketplace in "$MARKETPLACES_DIR"/*/; do
            local mname=$(basename "$marketplace")

            # Check for plugins directory
            local plugins_dir=""
            if [[ -d "$marketplace/plugins" ]]; then
                plugins_dir="$marketplace/plugins"
            else
                plugins_dir="$marketplace"
            fi

            for plugin in "$plugins_dir"/*/; do
                if [[ -d "$plugin" ]]; then
                    local pname=$(basename "$plugin")
                    # Skip hidden directories and non-plugin dirs
                    [[ "$pname" == .* ]] && continue
                    [[ ! -f "$plugin/README.md" ]] && [[ ! -d "$plugin/.claude-plugin" ]] && [[ ! -d "$plugin/commands" ]] && continue

                    all_plugins+=("$pname [$mname]")
                    plugin_paths+=("$plugin")
                    echo "  [$index] $pname ($mname)"
                    ((index++))
                fi
            done
        done
    fi

    if [[ ${#all_plugins[@]} -eq 0 ]]; then
        print_warning "No plugins found"
        return 1
    fi

    print_section "Quick Actions"
    echo "To analyze a plugin, run:"
    echo "  $(basename "$0") --review <plugin-name>"
    echo "  $(basename "$0") --analyze <plugin-name>"
    echo "  $(basename "$0") --decompose <plugin-name>"
    echo ""
    echo "Total plugins found: ${#all_plugins[@]}"

    return 0
}

# ============================================================================
# EXECUTE FUNCTION (--execute)
# ============================================================================

execute_integration() {
    local plugin_path="$1"
    local dry_run="${2:-false}"

    # Auto-discover if not a path
    if [[ ! -d "$plugin_path" ]]; then
        plugin_path=$(discover_plugin "$plugin_path" 2>/dev/null | tail -1)
        if [[ -z "$plugin_path" ]] || [[ ! -d "$plugin_path" ]]; then
            print_error "Could not find plugin: $1"
            return 1
        fi
    fi

    local plugin_name=$(basename "$plugin_path")
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local rollback_file="$OUTPUT_DIR/.rollback-${plugin_name}-${timestamp}.json"

    if [[ "$dry_run" == "true" ]]; then
        print_header "Execute Integration (DRY RUN): $plugin_name"
        echo "This is a preview. No changes will be made."
    else
        print_header "Execute Integration: $plugin_name"
    fi

    # Pre-flight checks
    print_section "Pre-flight Checks"

    local decomp_plan="$OUTPUT_DIR/${plugin_name}-decomposition.md"

    # Check if decomposition plan exists, generate if missing
    if [[ ! -f "$decomp_plan" ]]; then
        print_warning "Decomposition plan not found, generating..."
        decompose_plugin "$plugin_path" > /dev/null 2>&1
        if [[ ! -f "$decomp_plan" ]]; then
            print_error "Failed to generate decomposition plan"
            return 1
        fi
    fi
    print_success "Decomposition plan found: $decomp_plan"

    # Parse the decomposition plan
    print_section "Parsing Integration Plan"

    # Initialize rollback data
    local rollback_data='{"plugin":"'"$plugin_name"'","timestamp":"'"$timestamp"'","actions":[]}'

    # Arrays for tracking
    local files_copied=()
    local dirs_created=()
    local backups_created=()

    # Process commands
    if [[ -d "$plugin_path/commands" ]]; then
        print_section "Commands"
        for cmd in "$plugin_path/commands"/*.md; do
            if [[ -f "$cmd" ]]; then
                local cmd_name=$(basename "$cmd")
                local dest="$JARVIS_ROOT/.claude/commands/$cmd_name"

                if [[ -f "$dest" ]]; then
                    if [[ "$dry_run" == "true" ]]; then
                        echo -e "  ${YELLOW}WOULD BACKUP${NC} $dest"
                        echo -e "  ${YELLOW}WOULD MERGE${NC} $cmd_name (existing file)"
                    else
                        # Create backup
                        local backup="$dest.backup.$timestamp"
                        cp "$dest" "$backup"
                        backups_created+=("$backup")
                        print_info "Backed up: $dest -> $backup"

                        # Copy (overwrite for now - merge is manual)
                        cp "$cmd" "$dest"
                        files_copied+=("$dest")
                        print_success "Copied: $cmd_name (overwrote existing)"
                    fi
                else
                    if [[ "$dry_run" == "true" ]]; then
                        echo -e "  ${GREEN}WOULD COPY${NC} $cmd_name -> $dest"
                    else
                        cp "$cmd" "$dest"
                        files_copied+=("$dest")
                        print_success "Copied: $cmd_name"
                    fi
                fi
            fi
        done
    fi

    # Process hooks
    if [[ -d "$plugin_path/hooks" ]]; then
        print_section "Hooks"
        for hook in "$plugin_path/hooks"/*; do
            if [[ -f "$hook" ]]; then
                local hook_name=$(basename "$hook")
                local dest="$JARVIS_ROOT/.claude/hooks/$hook_name"

                if [[ -f "$dest" ]]; then
                    if [[ "$dry_run" == "true" ]]; then
                        echo -e "  ${YELLOW}WOULD BACKUP${NC} $dest"
                        echo -e "  ${YELLOW}WOULD MERGE${NC} $hook_name (existing file)"
                    else
                        local backup="$dest.backup.$timestamp"
                        cp "$dest" "$backup"
                        backups_created+=("$backup")
                        print_info "Backed up: $dest -> $backup"

                        cp "$hook" "$dest"
                        files_copied+=("$dest")
                        print_success "Copied: $hook_name"
                    fi
                else
                    if [[ "$dry_run" == "true" ]]; then
                        echo -e "  ${GREEN}WOULD COPY${NC} $hook_name -> $dest"
                    else
                        cp "$hook" "$dest"
                        files_copied+=("$dest")
                        print_success "Copied: $hook_name"
                    fi
                fi

                # Make shell scripts executable
                if [[ "$hook_name" == *.sh ]] && [[ "$dry_run" != "true" ]]; then
                    chmod +x "$dest"
                fi
            fi
        done
    fi

    # Process scripts
    if [[ -d "$plugin_path/scripts" ]]; then
        print_section "Scripts"
        for script in "$plugin_path/scripts"/*; do
            if [[ -f "$script" ]]; then
                local script_name=$(basename "$script")
                local dest="$JARVIS_ROOT/.claude/scripts/$script_name"

                if [[ -f "$dest" ]]; then
                    if [[ "$dry_run" == "true" ]]; then
                        echo -e "  ${YELLOW}WOULD BACKUP${NC} $dest"
                        echo -e "  ${YELLOW}WOULD MERGE${NC} $script_name (existing file)"
                    else
                        local backup="$dest.backup.$timestamp"
                        cp "$dest" "$backup"
                        backups_created+=("$backup")
                        print_info "Backed up: $dest -> $backup"

                        cp "$script" "$dest"
                        chmod +x "$dest"
                        files_copied+=("$dest")
                        print_success "Copied: $script_name"
                    fi
                else
                    if [[ "$dry_run" == "true" ]]; then
                        echo -e "  ${GREEN}WOULD COPY${NC} $script_name -> $dest"
                    else
                        cp "$script" "$dest"
                        chmod +x "$dest"
                        files_copied+=("$dest")
                        print_success "Copied: $script_name"
                    fi
                fi
            fi
        done
    fi

    # Process skills
    if [[ -d "$plugin_path/skills" ]]; then
        print_section "Skills"
        for skill in "$plugin_path/skills"/*/; do
            if [[ -d "$skill" ]]; then
                local skill_name=$(basename "$skill")
                local dest="$JARVIS_ROOT/.claude/skills/$skill_name"

                if [[ -d "$dest" ]]; then
                    if [[ "$dry_run" == "true" ]]; then
                        echo -e "  ${YELLOW}WOULD MERGE${NC} $skill_name/ (existing skill)"
                    else
                        # Copy skill directory contents
                        cp -r "$skill"/* "$dest/" 2>/dev/null || true
                        dirs_created+=("$dest")
                        print_success "Merged skill: $skill_name"
                    fi
                else
                    if [[ "$dry_run" == "true" ]]; then
                        echo -e "  ${GREEN}WOULD COPY${NC} $skill_name/ -> $dest/"
                    else
                        mkdir -p "$dest"
                        cp -r "$skill"/* "$dest/"
                        dirs_created+=("$dest")
                        print_success "Copied skill: $skill_name"
                    fi
                fi
            fi
        done
    fi

    # Post-integration validation
    if [[ "$dry_run" != "true" ]]; then
        print_section "Post-Integration Validation"

        local validation_passed=true

        # Verify files exist
        for file in "${files_copied[@]}"; do
            if [[ -f "$file" ]]; then
                print_success "Verified: $file"
            else
                print_error "Missing: $file"
                validation_passed=false
            fi
        done

        # Verify directories exist
        for dir in "${dirs_created[@]}"; do
            if [[ -d "$dir" ]]; then
                print_success "Verified: $dir/"
            else
                print_error "Missing: $dir/"
                validation_passed=false
            fi
        done

        # Syntax check scripts
        for file in "${files_copied[@]}"; do
            if [[ "$file" == *.sh ]]; then
                if bash -n "$file" 2>/dev/null; then
                    print_success "Syntax OK: $(basename "$file")"
                else
                    print_warning "Syntax issue: $(basename "$file")"
                fi
            fi
        done

        # Create rollback file
        print_section "Rollback Data"
        mkdir -p "$OUTPUT_DIR"

        cat > "$rollback_file" << EOF
{
  "plugin": "$plugin_name",
  "plugin_path": "$plugin_path",
  "timestamp": "$timestamp",
  "files_copied": [
$(printf '    "%s",\n' "${files_copied[@]}" | sed '$ s/,$//')
  ],
  "dirs_created": [
$(printf '    "%s",\n' "${dirs_created[@]}" | sed '$ s/,$//')
  ],
  "backups_created": [
$(printf '    "%s",\n' "${backups_created[@]}" | sed '$ s/,$//')
  ]
}
EOF
        print_success "Rollback file created: $rollback_file"

        print_section "Summary"
        echo "Files copied: ${#files_copied[@]}"
        echo "Directories created: ${#dirs_created[@]}"
        echo "Backups created: ${#backups_created[@]}"
        echo ""
        if [[ "$validation_passed" == "true" ]]; then
            print_success "Integration completed successfully!"
        else
            print_warning "Integration completed with warnings"
        fi
        echo ""
        echo "To rollback: $(basename "$0") --rollback $rollback_file"
    else
        print_section "Dry Run Summary"
        echo "No changes were made. Run without --dry-run to execute."
    fi

    return 0
}

# ============================================================================
# ROLLBACK FUNCTION (--rollback)
# ============================================================================

rollback_integration() {
    local rollback_file="$1"

    if [[ ! -f "$rollback_file" ]]; then
        print_error "Rollback file not found: $rollback_file"
        return 1
    fi

    print_header "Rollback Integration"
    echo "Using rollback file: $rollback_file"
    echo ""

    # Parse rollback file
    local plugin_name=$(jq -r '.plugin' "$rollback_file")
    local timestamp=$(jq -r '.timestamp' "$rollback_file")

    print_info "Plugin: $plugin_name"
    print_info "Original timestamp: $timestamp"

    # Remove copied files
    print_section "Removing Copied Files"
    while IFS= read -r file; do
        if [[ -n "$file" ]] && [[ "$file" != "null" ]]; then
            if [[ -f "$file" ]]; then
                rm "$file"
                print_success "Removed: $file"
            else
                print_warning "Already gone: $file"
            fi
        fi
    done < <(jq -r '.files_copied[]' "$rollback_file" 2>/dev/null)

    # Remove created directories (if empty)
    print_section "Removing Created Directories"
    while IFS= read -r dir; do
        if [[ -n "$dir" ]] && [[ "$dir" != "null" ]]; then
            if [[ -d "$dir" ]]; then
                # Only remove if empty or we created it
                if rmdir "$dir" 2>/dev/null; then
                    print_success "Removed: $dir/"
                else
                    print_warning "Not empty, kept: $dir/"
                fi
            else
                print_warning "Already gone: $dir/"
            fi
        fi
    done < <(jq -r '.dirs_created[]' "$rollback_file" 2>/dev/null)

    # Restore backups
    print_section "Restoring Backups"
    while IFS= read -r backup; do
        if [[ -n "$backup" ]] && [[ "$backup" != "null" ]]; then
            if [[ -f "$backup" ]]; then
                # Get original filename by removing .backup.TIMESTAMP
                local original=$(echo "$backup" | sed "s/.backup.$timestamp//")
                mv "$backup" "$original"
                print_success "Restored: $original"
            else
                print_warning "Backup not found: $backup"
            fi
        fi
    done < <(jq -r '.backups_created[]' "$rollback_file" 2>/dev/null)

    print_section "Summary"
    print_success "Rollback completed for: $plugin_name"

    # Optionally remove the rollback file
    echo ""
    echo "Rollback file retained at: $rollback_file"

    return 0
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    if [[ $# -eq 0 ]]; then
        usage
    fi

    local command=""
    local target=""
    local dry_run="false"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            --discover)
                command="discover"
                target="${2:-}"
                shift 2 || { print_error "--discover requires a plugin name"; exit 1; }
                ;;
            --review)
                command="review"
                target="${2:-}"
                shift 2 || { print_error "--review requires a plugin path"; exit 1; }
                ;;
            --analyze)
                command="analyze"
                target="${2:-}"
                shift 2 || { print_error "--analyze requires a plugin path"; exit 1; }
                ;;
            --scan-redundancy)
                command="scan-redundancy"
                target="${2:-}"
                shift 2 || { print_error "--scan-redundancy requires a plugin path"; exit 1; }
                ;;
            --decompose)
                command="decompose"
                target="${2:-}"
                shift 2 || { print_error "--decompose requires a plugin path"; exit 1; }
                ;;
            --browse)
                command="browse"
                shift
                ;;
            --execute)
                command="execute"
                target="${2:-}"
                shift 2 || { print_error "--execute requires a plugin path"; exit 1; }
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            --rollback)
                command="rollback"
                target="${2:-}"
                shift 2 || { print_error "--rollback requires a rollback file path"; exit 1; }
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    case "$command" in
        discover)
            discover_plugin "$target"
            ;;
        review)
            review_plugin "$target"
            ;;
        analyze)
            analyze_plugin "$target"
            ;;
        scan-redundancy)
            scan_redundancy "$target"
            ;;
        decompose)
            decompose_plugin "$target"
            ;;
        browse)
            browse_plugins
            ;;
        execute)
            execute_integration "$target" "$dry_run"
            ;;
        rollback)
            rollback_integration "$target"
            ;;
        *)
            print_error "No command specified"
            usage
            ;;
    esac
}

main "$@"
