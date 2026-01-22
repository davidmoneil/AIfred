#!/bin/bash
# consolidate-project.sh - Data gathering for project/infrastructure consolidation
# Part of the Capability Layering Pattern - deterministic operations only
#
# Usage:
#   consolidate-project.sh --list-projects           # List active projects
#   consolidate-project.sh --project <name>          # Gather project stats
#   consolidate-project.sh --analyze                 # Gather infrastructure stats
#   consolidate-project.sh --infra-files             # List infrastructure file sizes
#
# Output: JSON for structured consumption by Claude
#
# Created: 2026-01-21

set -euo pipefail

# Configuration
AIPROJECTS_ROOT="${AIPROJECTS_ROOT:-$HOME/AIProjects}"
PROJECTS_DIR="$AIPROJECTS_ROOT/.claude/projects"
CONTEXT_DIR="$AIPROJECTS_ROOT/.claude/context"
AGENTS_DIR="$AIPROJECTS_ROOT/.claude/agents"
COMMANDS_DIR="$AIPROJECTS_ROOT/.claude/commands"
SKILLS_DIR="$AIPROJECTS_ROOT/.claude/skills"

# Colors (only for non-JSON output)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags
JSON_OUTPUT=false
QUIET=false

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] COMMAND

Commands:
  --list-projects          List all active projects with status
  --project <name>         Gather stats for a specific project
  --analyze                Gather infrastructure context stats
  --infra-files            List infrastructure file sizes (sorted)
  --check-stale [days]     Find stale projects (default: 30 days)

Options:
  -j, --json               Output as JSON (default for most commands)
  -q, --quiet              Minimal output
  -h, --help               Show this help

Examples:
  $(basename "$0") --list-projects
  $(basename "$0") --project ciso-blog-writing
  $(basename "$0") --analyze --json
  $(basename "$0") --check-stale 14

EOF
    exit 0
}

# Helper: Output JSON or text
output_json() {
    echo "$1"
}

# List all projects from _index.md
list_projects() {
    local index_file="$PROJECTS_DIR/_index.md"

    if [[ ! -f "$index_file" ]]; then
        echo '{"error": "Projects index not found", "path": "'"$index_file"'"}'
        exit 1
    fi

    local projects=()
    local current_section=""

    # Parse _index.md for project entries
    while IFS= read -r line; do
        # Detect section headers
        if [[ "$line" =~ ^##[[:space:]]+(Active|Paused|Completed|Archived) ]]; then
            current_section="${BASH_REMATCH[1]}"
        fi

        # Detect project entries (format: ### Project Name or - **Path**: ...)
        if [[ "$line" =~ ^###[[:space:]]+(.+) ]]; then
            local project_name="${BASH_REMATCH[1]}"
            # Get the directory name from the next line with Path
            continue
        fi

        if [[ "$line" =~ \*\*Path\*\*:[[:space:]]*\`?\.claude/projects/([^/\`]+) ]]; then
            local dir_name="${BASH_REMATCH[1]}"
            local project_path="$PROJECTS_DIR/$dir_name"

            if [[ -d "$project_path" ]]; then
                # Get last modified time
                local last_modified
                last_modified=$(find "$project_path" -type f -name "*.md" -printf '%T@\n' 2>/dev/null | sort -rn | head -1)
                local last_modified_date=""
                if [[ -n "$last_modified" ]]; then
                    last_modified_date=$(date -d "@${last_modified%.*}" "+%Y-%m-%d" 2>/dev/null || echo "unknown")
                fi

                # Count files
                local file_count
                file_count=$(find "$project_path" -type f | wc -l)

                projects+=("{\"name\": \"$dir_name\", \"status\": \"${current_section:-unknown}\", \"last_modified\": \"$last_modified_date\", \"file_count\": $file_count}")
            fi
        fi
    done < "$index_file"

    # Also scan directory for any projects not in index
    for dir in "$PROJECTS_DIR"/*/; do
        if [[ -d "$dir" ]]; then
            local dir_name
            dir_name=$(basename "$dir")

            # Skip if already found or if it's a special directory
            if [[ "$dir_name" == "_"* ]] || [[ " ${projects[*]} " =~ "\"$dir_name\"" ]]; then
                continue
            fi

            local last_modified
            last_modified=$(find "$dir" -type f -name "*.md" -printf '%T@\n' 2>/dev/null | sort -rn | head -1)
            local last_modified_date=""
            if [[ -n "$last_modified" ]]; then
                last_modified_date=$(date -d "@${last_modified%.*}" "+%Y-%m-%d" 2>/dev/null || echo "unknown")
            fi

            local file_count
            file_count=$(find "$dir" -type f | wc -l)

            projects+=("{\"name\": \"$dir_name\", \"status\": \"unlisted\", \"last_modified\": \"$last_modified_date\", \"file_count\": $file_count}")
        fi
    done

    # Output JSON array
    echo "{"
    echo "  \"projects\": ["
    local first=true
    for proj in "${projects[@]}"; do
        if $first; then
            first=false
        else
            echo ","
        fi
        echo -n "    $proj"
    done
    echo ""
    echo "  ],"
    echo "  \"total\": ${#projects[@]},"
    echo "  \"timestamp\": \"$(date -Iseconds)\""
    echo "}"
}

# Gather stats for a specific project
project_stats() {
    local project_name="$1"
    local project_path="$PROJECTS_DIR/$project_name"

    if [[ ! -d "$project_path" ]]; then
        echo '{"error": "Project not found", "name": "'"$project_name"'", "path": "'"$project_path"'"}'
        exit 1
    fi

    # Basic info
    local readme_exists=false
    local config_exists=false
    local todo_exists=false
    local progress_exists=false
    local patterns_exists=false

    [[ -f "$project_path/README.md" ]] && readme_exists=true
    [[ -f "$project_path/config.yaml" ]] && config_exists=true
    [[ -f "$project_path/todo.md" ]] && todo_exists=true
    [[ -f "$project_path/progress.md" ]] && progress_exists=true
    [[ -f "$project_path/learned-patterns.md" ]] && patterns_exists=true

    # Count patterns (sections starting with ##)
    local pattern_count=0
    if [[ -f "$project_path/learned-patterns.md" ]]; then
        pattern_count=$(grep -c "^## " "$project_path/learned-patterns.md" 2>/dev/null || echo "0")
    fi

    # Count examples
    local example_count=0
    if [[ -d "$project_path/examples" ]]; then
        example_count=$(find "$project_path/examples" -type f 2>/dev/null | wc -l)
    fi

    # Recent changes (last 7 days)
    local recent_changes
    recent_changes=$(find "$project_path" -type f -mtime -7 -name "*.md" 2>/dev/null | wc -l)

    # Last activity
    local last_modified
    last_modified=$(find "$project_path" -type f -printf '%T@\n' 2>/dev/null | sort -rn | head -1)
    local last_modified_date=""
    local days_since_activity=0
    if [[ -n "$last_modified" ]]; then
        last_modified_date=$(date -d "@${last_modified%.*}" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "unknown")
        local now
        now=$(date +%s)
        days_since_activity=$(( (now - ${last_modified%.*}) / 86400 ))
    fi

    # Total files
    local total_files
    total_files=$(find "$project_path" -type f | wc -l)

    # List of files modified in last 7 days
    local recent_files=()
    while IFS= read -r file; do
        if [[ -n "$file" ]]; then
            recent_files+=("\"${file#$project_path/}\"")
        fi
    done < <(find "$project_path" -type f -mtime -7 -name "*.md" 2>/dev/null | head -10)

    # Knowledge files status
    local knowledge_files=()
    for kfile in style-guide.md preferences.md troubleshooting.md tools.md; do
        if [[ -f "$project_path/knowledge/$kfile" ]]; then
            local lines
            lines=$(wc -l < "$project_path/knowledge/$kfile")
            knowledge_files+=("{\"name\": \"$kfile\", \"exists\": true, \"lines\": $lines}")
        else
            knowledge_files+=("{\"name\": \"$kfile\", \"exists\": false, \"lines\": 0}")
        fi
    done

    # Output JSON
    cat << EOF
{
  "name": "$project_name",
  "path": "$project_path",
  "exists": true,
  "files": {
    "readme": $readme_exists,
    "config": $config_exists,
    "todo": $todo_exists,
    "progress": $progress_exists,
    "patterns": $patterns_exists
  },
  "stats": {
    "pattern_count": $pattern_count,
    "example_count": $example_count,
    "total_files": $total_files,
    "recent_changes_7d": $recent_changes,
    "days_since_activity": $days_since_activity
  },
  "last_modified": "$last_modified_date",
  "recent_files": [$(IFS=,; echo "${recent_files[*]}")],
  "knowledge_files": [$(IFS=,; echo "${knowledge_files[*]}")],
  "health": {
    "is_stale": $([ $days_since_activity -gt 30 ] && echo "true" || echo "false"),
    "needs_consolidation": $([ $recent_changes -gt 5 ] && echo "true" || echo "false"),
    "has_examples": $([ $example_count -gt 0 ] && echo "true" || echo "false"),
    "has_patterns": $([ $pattern_count -gt 0 ] && echo "true" || echo "false")
  },
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Gather infrastructure stats
analyze_infrastructure() {
    # Context files
    local context_files=()
    while IFS= read -r line; do
        local file lines
        lines=$(echo "$line" | awk '{print $1}')
        file=$(echo "$line" | awk '{print $2}')
        if [[ -n "$file" && -n "$lines" ]]; then
            local rel_path="${file#$AIPROJECTS_ROOT/}"
            context_files+=("{\"path\": \"$rel_path\", \"lines\": $lines}")
        fi
    done < <(find "$CONTEXT_DIR" -name "*.md" -exec wc -l {} \; 2>/dev/null | sort -rn | head -20)

    # Agent files
    local agent_files=()
    while IFS= read -r line; do
        local file lines
        lines=$(echo "$line" | awk '{print $1}')
        file=$(echo "$line" | awk '{print $2}')
        if [[ -n "$file" && -n "$lines" ]]; then
            local name
            name=$(basename "$file" .md)
            agent_files+=("{\"name\": \"$name\", \"lines\": $lines}")
        fi
    done < <(find "$AGENTS_DIR" -maxdepth 1 -name "*.md" -exec wc -l {} \; 2>/dev/null | sort -rn | head -10)

    # Command files
    local command_files=()
    while IFS= read -r line; do
        local file lines
        lines=$(echo "$line" | awk '{print $1}')
        file=$(echo "$line" | awk '{print $2}')
        if [[ -n "$file" && -n "$lines" ]]; then
            local name
            name=$(basename "$file" .md)
            command_files+=("{\"name\": \"$name\", \"lines\": $lines}")
        fi
    done < <(find "$COMMANDS_DIR" -maxdepth 1 -name "*.md" -exec wc -l {} \; 2>/dev/null | sort -rn | head -15)

    # Skill files
    local skill_files=()
    for skill_dir in "$SKILLS_DIR"/*/; do
        if [[ -d "$skill_dir" ]]; then
            local skill_name
            skill_name=$(basename "$skill_dir")
            local skill_md="$skill_dir/SKILL.md"
            local lines=0
            [[ -f "$skill_md" ]] && lines=$(wc -l < "$skill_md")
            local has_tools=false
            [[ -d "$skill_dir/tools" ]] && has_tools=true
            skill_files+=("{\"name\": \"$skill_name\", \"lines\": $lines, \"has_tools\": $has_tools}")
        fi
    done

    # Old files (>90 days)
    local old_files
    old_files=$(find "$CONTEXT_DIR" -name "*.md" -mtime +90 2>/dev/null | wc -l)

    # Total stats
    local total_context_lines
    total_context_lines=$(find "$CONTEXT_DIR" -name "*.md" -exec wc -l {} \; 2>/dev/null | awk '{sum+=$1} END {print sum}')

    local total_agent_lines
    total_agent_lines=$(find "$AGENTS_DIR" -maxdepth 1 -name "*.md" -exec wc -l {} \; 2>/dev/null | awk '{sum+=$1} END {print sum}')

    local total_command_lines
    total_command_lines=$(find "$COMMANDS_DIR" -maxdepth 1 -name "*.md" -exec wc -l {} \; 2>/dev/null | awk '{sum+=$1} END {print sum}')

    # Output JSON
    cat << EOF
{
  "context_files": [$(IFS=,; echo "${context_files[*]}")],
  "agent_files": [$(IFS=,; echo "${agent_files[*]}")],
  "command_files": [$(IFS=,; echo "${command_files[*]}")],
  "skill_files": [$(IFS=,; echo "${skill_files[*]}")],
  "totals": {
    "context_lines": ${total_context_lines:-0},
    "agent_lines": ${total_agent_lines:-0},
    "command_lines": ${total_command_lines:-0},
    "old_files_90d": $old_files
  },
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Find stale projects
check_stale() {
    local days="${1:-30}"
    local stale_projects=()

    for dir in "$PROJECTS_DIR"/*/; do
        if [[ -d "$dir" ]]; then
            local dir_name
            dir_name=$(basename "$dir")

            # Skip special directories
            [[ "$dir_name" == "_"* ]] && continue

            local last_modified
            last_modified=$(find "$dir" -type f -printf '%T@\n' 2>/dev/null | sort -rn | head -1)

            if [[ -n "$last_modified" ]]; then
                local now
                now=$(date +%s)
                local days_since=$(( (now - ${last_modified%.*}) / 86400 ))

                if [[ $days_since -gt $days ]]; then
                    local last_date
                    last_date=$(date -d "@${last_modified%.*}" "+%Y-%m-%d" 2>/dev/null || echo "unknown")
                    stale_projects+=("{\"name\": \"$dir_name\", \"days_inactive\": $days_since, \"last_modified\": \"$last_date\"}")
                fi
            fi
        fi
    done

    cat << EOF
{
  "threshold_days": $days,
  "stale_projects": [$(IFS=,; echo "${stale_projects[*]}")],
  "count": ${#stale_projects[@]},
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Main
main() {
    local command=""
    local project_name=""
    local stale_days=30

    while [[ $# -gt 0 ]]; do
        case $1 in
            --list-projects)
                command="list"
                shift
                ;;
            --project)
                command="project"
                project_name="$2"
                shift 2
                ;;
            --analyze)
                command="analyze"
                shift
                ;;
            --infra-files)
                command="infra-files"
                shift
                ;;
            --check-stale)
                command="stale"
                if [[ "${2:-}" =~ ^[0-9]+$ ]]; then
                    stale_days="$2"
                    shift
                fi
                shift
                ;;
            -j|--json)
                JSON_OUTPUT=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage
                ;;
        esac
    done

    case "$command" in
        list)
            list_projects
            ;;
        project)
            if [[ -z "$project_name" ]]; then
                echo '{"error": "Project name required"}'
                exit 1
            fi
            project_stats "$project_name"
            ;;
        analyze)
            analyze_infrastructure
            ;;
        infra-files)
            analyze_infrastructure
            ;;
        stale)
            check_stale "$stale_days"
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
