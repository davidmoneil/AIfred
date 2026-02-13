#!/bin/bash
# Script: aifred-update.sh
# Purpose: Component registry with manifest tracking for upstream AIfred updates
# Usage: ./aifred-update.sh [init|check|update|status] [options]
# Author: David Moneil
# Created: 2026-02-10
# Pattern: Capability Layering (Code -> CLI -> Prompt)
# Version: 1.0.0

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${REPO_DIR:-$(pwd)}"
MANIFEST_FILE="$REPO_DIR/.aifred.yaml"
IGNORE_FILE="$REPO_DIR/.aifred-ignore"
IGNORE_TEMPLATE="$REPO_DIR/.aifred-ignore.template"
DEFAULT_UPSTREAM="https://github.com/davidmoneil/AIfred.git"
CHECK_CACHE_FILE="$REPO_DIR/.aifred-check-result.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Logging
log_info()    { [[ "$QUIET" == true ]] && return; echo -e "${BLUE}i${NC} $1"; }
log_success() { [[ "$QUIET" == true ]] && return; echo -e "${GREEN}✓${NC} $1"; }
log_warning() { [[ "$QUIET" == true ]] && return; echo -e "${YELLOW}!${NC} $1"; }
log_error()   { echo -e "${RED}✗${NC} $1" >&2; }

# Globals
JSON_OUTPUT=false
QUIET=false
DRY_RUN=false
TMPDIR_UPSTREAM=""

# Cleanup trap
cleanup() {
    if [[ -n "$TMPDIR_UPSTREAM" && -d "$TMPDIR_UPSTREAM" ]]; then
        rm -rf "$TMPDIR_UPSTREAM"
    fi
}
trap cleanup EXIT

# --- Help ---

show_help() {
    cat << 'EOF'
Usage: aifred-update.sh <command> [options]

Commands:
    init        Initialize manifest by scanning current components
    check       Compare local components against latest upstream tag
    update      Interactive update from upstream (accept/skip/reject per component)
    status      Show local component inventory and modification status

Options:
    -h, --help      Show this help message
    -j, --json      Output in JSON format (check, status)
    -q, --quiet     Minimal output
    -n, --dry-run   Show what would change without applying (update)

Examples:
    aifred-update.sh init                    # First-time setup after cloning
    aifred-update.sh status                  # See local component inventory
    aifred-update.sh check                   # Compare against latest upstream
    aifred-update.sh check -j               # JSON output for automation
    aifred-update.sh update                  # Interactive update
    aifred-update.sh update -n              # Preview changes without applying

Exit Codes:
    0  Success (or no updates available)
    1  Invalid arguments or usage error
    2  No manifest found (run init first)
    3  Operation failed (network, git, file I/O)
EOF
}

# --- Utility Functions ---

# Portable SHA-256 computation
compute_sha() {
    local file="$1"
    if command -v sha256sum &>/dev/null; then
        sha256sum "$file" | cut -d' ' -f1
    elif command -v shasum &>/dev/null; then
        shasum -a 256 "$file" | cut -d' ' -f1
    else
        log_error "No sha256sum or shasum found"
        exit 3
    fi
}

# Get current version from VERSION file (single source of truth)
get_local_version() {
    local version_file="$REPO_DIR/VERSION"
    if [[ -f "$version_file" ]]; then
        local ver
        ver=$(tr -d '[:space:]' < "$version_file")
        if [[ -n "$ver" ]]; then
            echo "v${ver}"
            return
        fi
    fi
    # Fallback to git tag if VERSION file doesn't exist
    cd "$REPO_DIR"
    git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || echo "unknown"
}

# Get latest upstream tag
get_upstream_version() {
    local upstream_url="$1"
    git ls-remote --tags --sort=-v:refname "$upstream_url" 'refs/tags/v*' 2>/dev/null \
        | head -1 \
        | sed 's|.*refs/tags/||; s|\^{}||'
}

# Read upstream_url from manifest, or use default
get_upstream_url() {
    if [[ -f "$MANIFEST_FILE" ]]; then
        local url
        url=$(grep '^upstream_url:' "$MANIFEST_FILE" | sed 's/^upstream_url:[[:space:]]*//' | tr -d '"' | tr -d "'")
        if [[ -n "$url" ]]; then
            echo "$url"
            return
        fi
    fi
    echo "$DEFAULT_UPSTREAM"
}

# Clone upstream to temp dir (shallow, specific tag)
clone_upstream() {
    local tag="$1"
    local url="$2"
    TMPDIR_UPSTREAM=$(mktemp -d /tmp/aifred-upstream-XXXXX)
    log_info "Fetching upstream ${BOLD}$tag${NC}..."
    if ! git clone --depth 1 --branch "$tag" "$url" "$TMPDIR_UPSTREAM" 2>/dev/null; then
        log_error "Failed to clone upstream $url at tag $tag"
        exit 3
    fi
    log_success "Upstream $tag fetched"
}

# Read YAML value (simple single-line key: value)
yaml_read() {
    local file="$1" key="$2"
    grep "^${key}:" "$file" 2>/dev/null | sed "s/^${key}:[[:space:]]*//" | tr -d '"' | tr -d "'"
}

# Check if a path matches .aifred-ignore patterns
is_ignored() {
    local component_key="$1"

    [[ ! -f "$IGNORE_FILE" ]] && return 1

    while IFS= read -r pattern; do
        # Skip empty lines and comments
        [[ -z "$pattern" || "$pattern" == \#* ]] && continue
        # Strip trailing whitespace
        pattern="${pattern%%[[:space:]]}"
        [[ -z "$pattern" ]] && continue

        # Convert gitignore-style glob to regex for matching
        # Simple matching: fnmatch-style
        if [[ "$component_key" == $pattern ]]; then
            return 0
        fi
        # Also try with wildcard expansion
        local regex_pattern="${pattern//\*/.*}"
        regex_pattern="${regex_pattern//\?/.}"
        if [[ "$component_key" =~ ^${regex_pattern}$ ]]; then
            return 0
        fi
    done < "$IGNORE_FILE"

    return 1
}

# --- Component Discovery ---

# Component categories: category|glob_pattern|path_prefix_in_manifest|path_prefix_on_disk
COMPONENT_CATEGORIES=(
    "hooks|.claude/hooks/*.js|hooks/|.claude/hooks/"
    "commands|.claude/commands/**/*.md|commands/|.claude/commands/"
    "skills|.claude/skills/*/SKILL.md|skills/|.claude/skills/"
    "agents|.claude/agents/*.md|agents/|.claude/agents/"
    "scripts|scripts/*.sh|scripts/|scripts/"
    "profiles|profiles/*.yaml|profiles/|profiles/"
    "patterns|.claude/context/patterns/*.md|patterns/|.claude/context/patterns/"
)

# Files to exclude from tracking
should_exclude() {
    local filepath="$1"
    local basename
    basename=$(basename "$filepath")

    # Exact name exclusions
    case "$basename" in
        _template*|README.md|_index.md|schema.yaml|config.sh|config.sh.template) return 0 ;;
    esac

    # Path-based exclusions
    case "$filepath" in
        */logs/*|*/sessions/*|*/memory/*|*/results/*|*/archive/*) return 0 ;;
    esac

    # Template agent
    case "$basename" in
        _template-agent.md) return 0 ;;
    esac

    # Template skill directory
    case "$filepath" in
        */_template/*) return 0 ;;
    esac

    return 1
}

# Discover components in a directory
# Returns lines: component_key|local_path
discover_components() {
    local root_dir="$1"
    local results=()

    for category_spec in "${COMPONENT_CATEGORIES[@]}"; do
        IFS='|' read -r category glob_pattern manifest_prefix disk_prefix <<< "$category_spec"

        # Use find + glob expansion
        while IFS= read -r filepath; do
            [[ -z "$filepath" ]] && continue

            # Make relative to root
            local relpath="${filepath#$root_dir/}"

            # Check exclusions
            if should_exclude "$relpath"; then
                continue
            fi

            # Build component key: replace disk_prefix with manifest_prefix
            local component_key="${relpath/#$disk_prefix/$manifest_prefix}"

            echo "${component_key}|${relpath}"
        done < <(find "$root_dir/$disk_prefix" -type f \( -name "*.js" -o -name "*.md" -o -name "*.sh" -o -name "*.yaml" \) 2>/dev/null | sort)
    done
}

# --- Manifest Operations ---

# Write YAML manifest from scratch
write_manifest() {
    local version="$1"
    local upstream_url="$2"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    {
        echo "# AIfred Component Manifest"
        echo "# Generated by: aifred-update.sh init"
        echo "# Do not edit manually — managed by aifred-update.sh"
        echo ""
        echo "aifred_version: \"$version\""
        echo "upstream_url: \"$upstream_url\""
        echo "last_check: \"$timestamp\""
        echo "last_update: \"$timestamp\""
        echo ""
        echo "# Set to false to disable session-start update notifications"
        echo "notify: true"
        echo ""
        echo "components:"
    } > "$MANIFEST_FILE"

    # Discover and register all components
    local count=0
    while IFS='|' read -r component_key relpath; do
        [[ -z "$component_key" ]] && continue

        local sha
        sha=$(compute_sha "$REPO_DIR/$relpath")

        {
            echo "  $component_key:"
            echo "    source_version: \"$version\""
            echo "    source_sha: \"$sha\""
            echo "    local_sha: \"$sha\""
            echo "    status: current"
        } >> "$MANIFEST_FILE"

        count=$((count + 1))
    done < <(discover_components "$REPO_DIR")

    {
        echo ""
        echo "user_components: []"
    } >> "$MANIFEST_FILE"

    echo "$count"
}

# Read component entry from manifest
# Returns: source_version|source_sha|local_sha|status|rejected_version
read_component() {
    local key="$1"
    local in_component=false
    local source_version="" source_sha="" local_sha="" status="" rejected_version=""

    while IFS= read -r line; do
        # Check if we hit our component key
        if [[ "$line" =~ ^[[:space:]]{2}${key}: ]]; then
            in_component=true
            continue
        fi

        # If we're in the component, read its fields
        if [[ "$in_component" == true ]]; then
            # New component or section starts => we're done
            if [[ "$line" =~ ^[[:space:]]{2}[a-zA-Z] && ! "$line" =~ ^[[:space:]]{4} ]]; then
                break
            fi
            if [[ "$line" =~ ^[[:space:]]*$ ]] || [[ "$line" =~ ^[a-zA-Z] ]]; then
                break
            fi

            local trimmed="${line#"${line%%[![:space:]]*}"}"
            case "$trimmed" in
                source_version:*) source_version=$(echo "$trimmed" | sed 's/source_version:[[:space:]]*//' | tr -d '"' | tr -d "'") ;;
                source_sha:*) source_sha=$(echo "$trimmed" | sed 's/source_sha:[[:space:]]*//' | tr -d '"' | tr -d "'") ;;
                local_sha:*) local_sha=$(echo "$trimmed" | sed 's/local_sha:[[:space:]]*//' | tr -d '"' | tr -d "'") ;;
                status:*) status=$(echo "$trimmed" | sed 's/status:[[:space:]]*//' | tr -d '"' | tr -d "'") ;;
                rejected_version:*) rejected_version=$(echo "$trimmed" | sed 's/rejected_version:[[:space:]]*//' | tr -d '"' | tr -d "'") ;;
            esac
        fi
    done < "$MANIFEST_FILE"

    echo "${source_version}|${source_sha}|${local_sha}|${status}|${rejected_version}"
}

# Update a single component in manifest (in-place)
update_manifest_component() {
    local key="$1"
    local field="$2"
    local value="$3"

    # Use a temp file for safe in-place editing
    local tmpfile
    tmpfile=$(mktemp)

    local in_component=false
    local field_updated=false

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]{2}${key}: ]]; then
            in_component=true
            echo "$line" >> "$tmpfile"
            continue
        fi

        if [[ "$in_component" == true ]]; then
            if [[ "$line" =~ ^[[:space:]]{2}[a-zA-Z] && ! "$line" =~ ^[[:space:]]{4} ]] || [[ "$line" =~ ^[[:space:]]*$ && "$field_updated" == true ]] || [[ "$line" =~ ^[a-zA-Z] ]]; then
                # Exiting component block
                if [[ "$field_updated" == false ]]; then
                    # Field didn't exist, add it before exiting
                    echo "    ${field}: \"${value}\"" >> "$tmpfile"
                    field_updated=true
                fi
                in_component=false
                echo "$line" >> "$tmpfile"
                continue
            fi

            local trimmed="${line#"${line%%[![:space:]]*}"}"
            if [[ "$trimmed" == ${field}:* ]]; then
                echo "    ${field}: \"${value}\"" >> "$tmpfile"
                field_updated=true
                continue
            fi
        fi

        echo "$line" >> "$tmpfile"
    done < "$MANIFEST_FILE"

    mv "$tmpfile" "$MANIFEST_FILE"
}

# Add a new component to manifest
add_manifest_component() {
    local key="$1"
    local source_version="$2"
    local source_sha="$3"
    local local_sha="$4"
    local status="$5"

    # Insert before "user_components:" line
    local tmpfile
    tmpfile=$(mktemp)

    local inserted=false
    while IFS= read -r line; do
        if [[ "$line" == "user_components:"* && "$inserted" == false ]]; then
            echo "  $key:" >> "$tmpfile"
            echo "    source_version: \"$source_version\"" >> "$tmpfile"
            echo "    source_sha: \"$source_sha\"" >> "$tmpfile"
            echo "    local_sha: \"$local_sha\"" >> "$tmpfile"
            echo "    status: $status" >> "$tmpfile"
            echo "" >> "$tmpfile"
            inserted=true
        fi
        echo "$line" >> "$tmpfile"
    done < "$MANIFEST_FILE"

    mv "$tmpfile" "$MANIFEST_FILE"
}

# Update manifest timestamp
update_manifest_timestamp() {
    local field="$1"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local tmpfile
    tmpfile=$(mktemp)
    while IFS= read -r line; do
        if [[ "$line" == ${field}:* ]]; then
            echo "${field}: \"${timestamp}\"" >> "$tmpfile"
        else
            echo "$line" >> "$tmpfile"
        fi
    done < "$MANIFEST_FILE"
    mv "$tmpfile" "$MANIFEST_FILE"
}

# --- Subcommands ---

cmd_init() {
    log_info "Initializing AIfred component manifest..."

    # Check we're in a git repo
    cd "$REPO_DIR"
    if ! git rev-parse --git-dir &>/dev/null; then
        log_error "Not a git repository: $REPO_DIR"
        exit 3
    fi

    # Get current version
    local version
    version=$(get_local_version)

    if [[ "$version" == "unknown" ]]; then
        log_warning "No version tag found, using 'untagged'"
        version="untagged"
    fi

    # Determine upstream URL
    local upstream_url
    upstream_url=$(git remote get-url origin 2>/dev/null || echo "$DEFAULT_UPSTREAM")

    # Check for existing manifest
    if [[ -f "$MANIFEST_FILE" ]]; then
        log_warning "Manifest already exists at $MANIFEST_FILE"
        if [[ "$DRY_RUN" == true ]]; then
            log_info "[dry-run] Would overwrite existing manifest"
            return
        fi
        read -rp "Overwrite? [y/N] " confirm
        if [[ "$confirm" != [yY] ]]; then
            log_info "Cancelled"
            return
        fi
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[dry-run] Would create manifest with version $version"
        local count=0
        while IFS='|' read -r component_key _relpath; do
            [[ -z "$component_key" ]] && continue
            count=$((count + 1))
        done < <(discover_components "$REPO_DIR")
        log_info "[dry-run] Would register $count components"
        return
    fi

    # Write manifest
    local count
    count=$(write_manifest "$version" "$upstream_url")

    # Create .aifred-ignore from template if it doesn't exist
    if [[ ! -f "$IGNORE_FILE" && -f "$IGNORE_TEMPLATE" ]]; then
        cp "$IGNORE_TEMPLATE" "$IGNORE_FILE"
        log_success "Created $IGNORE_FILE from template"
    fi

    log_success "Manifest created: ${BOLD}$count${NC} components registered at version ${BOLD}$version${NC}"

    if [[ "$JSON_OUTPUT" == true ]]; then
        echo "{\"action\":\"init\",\"version\":\"$version\",\"components\":$count}"
    fi
}

cmd_status() {
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        log_error "No manifest found. Run 'aifred-update.sh init' first."
        exit 2
    fi

    local version
    version=$(yaml_read "$MANIFEST_FILE" "aifred_version")
    local last_check
    last_check=$(yaml_read "$MANIFEST_FILE" "last_check")
    local last_update
    last_update=$(yaml_read "$MANIFEST_FILE" "last_update")

    # Scan current components and compare SHAs
    local total=0 current=0 modified=0 missing=0 new_local=0
    local -A component_status
    local -A component_categories

    # Track known components from manifest
    local -A manifest_components
    local in_components=false
    local current_key=""
    while IFS= read -r line; do
        if [[ "$line" == "components:" ]]; then
            in_components=true
            continue
        fi
        if [[ "$in_components" == true ]]; then
            if [[ "$line" =~ ^[a-zA-Z] ]]; then
                break
            fi
            if [[ "$line" =~ ^[[:space:]]{2}([a-zA-Z][^:]+): ]]; then
                current_key="${BASH_REMATCH[1]}"
                manifest_components["$current_key"]=1
            fi
        fi
    done < "$MANIFEST_FILE"

    # Check each manifest component against disk
    for key in "${!manifest_components[@]}"; do
        total=$((total + 1))

        # Determine category from key prefix
        local category="${key%%/*}"
        component_categories["$category"]=1

        # Find the disk path for this component
        local disk_path=""
        for category_spec in "${COMPONENT_CATEGORIES[@]}"; do
            IFS='|' read -r _cat _glob manifest_prefix disk_prefix <<< "$category_spec"
            if [[ "$key" == ${manifest_prefix}* ]]; then
                disk_path="$REPO_DIR/${key/#$manifest_prefix/$disk_prefix}"
                break
            fi
        done

        if [[ -z "$disk_path" || ! -f "$disk_path" ]]; then
            component_status["$key"]="missing"
            missing=$((missing + 1))
            continue
        fi

        # Read manifest entry
        IFS='|' read -r _sv source_sha _ls status _rv <<< "$(read_component "$key")"

        # Compute current SHA
        local current_sha
        current_sha=$(compute_sha "$disk_path")

        if [[ "$current_sha" == "$source_sha" ]]; then
            component_status["$key"]="current"
            current=$((current + 1))
        else
            component_status["$key"]="modified"
            modified=$((modified + 1))
        fi
    done

    # Check for untracked local components
    local -a untracked=()
    while IFS='|' read -r component_key _relpath; do
        [[ -z "$component_key" ]] && continue
        if [[ -z "${manifest_components[$component_key]+x}" ]]; then
            untracked+=("$component_key")
            new_local=$((new_local + 1))
        fi
    done < <(discover_components "$REPO_DIR")

    if [[ "$JSON_OUTPUT" == true ]]; then
        # JSON output
        echo "{"
        echo "  \"version\": \"$version\","
        echo "  \"last_check\": \"$last_check\","
        echo "  \"last_update\": \"$last_update\","
        echo "  \"total\": $total,"
        echo "  \"current\": $current,"
        echo "  \"modified\": $modified,"
        echo "  \"missing\": $missing,"
        echo "  \"untracked\": $new_local,"
        echo "  \"components\": {"

        local first=true
        for key in $(echo "${!component_status[@]}" | tr ' ' '\n' | sort); do
            [[ "$first" == true ]] && first=false || echo ","
            printf '    "%s": "%s"' "$key" "${component_status[$key]}"
        done
        echo ""

        echo "  },"
        echo "  \"untracked_components\": ["
        first=true
        for key in "${untracked[@]}"; do
            [[ "$first" == true ]] && first=false || echo ","
            printf '    "%s"' "$key"
        done
        echo ""
        echo "  ]"
        echo "}"
        return
    fi

    # Human-readable output
    echo ""
    echo -e "${BOLD}AIfred Component Status${NC}"
    echo -e "${DIM}Version: $version | Last check: $last_check${NC}"
    echo ""

    # Group by category
    for cat_name in hooks commands skills agents scripts profiles patterns; do
        local cat_items=()
        for key in $(echo "${!component_status[@]}" | tr ' ' '\n' | sort); do
            if [[ "$key" == ${cat_name}/* ]]; then
                cat_items+=("$key")
            fi
        done

        if [[ ${#cat_items[@]} -eq 0 ]]; then
            continue
        fi

        echo -e "  ${CYAN}${cat_name}/${NC} (${#cat_items[@]})"
        for key in "${cat_items[@]}"; do
            local st="${component_status[$key]}"
            local short="${key#*/}"
            case "$st" in
                current)  echo -e "    ${GREEN}✓${NC} $short" ;;
                modified) echo -e "    ${YELLOW}~${NC} $short ${DIM}(modified locally)${NC}" ;;
                missing)  echo -e "    ${RED}✗${NC} $short ${DIM}(file missing)${NC}" ;;
            esac
        done
        echo ""
    done

    # Untracked
    if [[ ${#untracked[@]} -gt 0 ]]; then
        echo -e "  ${YELLOW}Untracked${NC} (${#untracked[@]})"
        for key in "${untracked[@]}"; do
            echo -e "    ${DIM}+${NC} $key"
        done
        echo ""
    fi

    # Summary line
    echo -e "${BOLD}Summary:${NC} $total tracked | ${GREEN}$current current${NC} | ${YELLOW}$modified modified${NC} | ${RED}$missing missing${NC} | $new_local untracked"
}

cmd_check() {
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        log_error "No manifest found. Run 'aifred-update.sh init' first."
        exit 2
    fi

    local upstream_url
    upstream_url=$(get_upstream_url)

    log_info "Checking upstream at ${BOLD}$upstream_url${NC}..."

    # Get latest upstream version
    local latest_tag
    latest_tag=$(get_upstream_version "$upstream_url")

    if [[ -z "$latest_tag" ]]; then
        log_error "Could not determine latest upstream version"
        exit 3
    fi

    local local_version
    local_version=$(yaml_read "$MANIFEST_FILE" "aifred_version")

    log_info "Local: ${BOLD}$local_version${NC} | Upstream: ${BOLD}$latest_tag${NC}"

    if [[ "$local_version" == "$latest_tag" ]]; then
        # Even if version matches, check for component-level changes
        log_info "Version tags match. Checking individual components..."
    fi

    # Clone upstream to compare
    clone_upstream "$latest_tag" "$upstream_url"

    # Compare components
    local -a outdated=()
    local -a new_upstream=()
    local -a removed_upstream=()
    local total_checked=0 up_to_date=0

    # Check all manifest components against upstream
    local -A manifest_components
    local in_components=false
    local current_key=""
    while IFS= read -r line; do
        if [[ "$line" == "components:" ]]; then
            in_components=true
            continue
        fi
        if [[ "$in_components" == true ]]; then
            if [[ "$line" =~ ^[a-zA-Z] ]]; then
                break
            fi
            if [[ "$line" =~ ^[[:space:]]{2}([a-zA-Z][^:]+): ]]; then
                current_key="${BASH_REMATCH[1]}"
                manifest_components["$current_key"]=1
            fi
        fi
    done < "$MANIFEST_FILE"

    for key in "${!manifest_components[@]}"; do
        total_checked=$((total_checked + 1))

        # Skip ignored
        if is_ignored "$key"; then
            continue
        fi

        # Read manifest entry
        IFS='|' read -r source_version source_sha local_sha status rejected_version <<< "$(read_component "$key")"

        # Find upstream file path
        local upstream_path=""
        for category_spec in "${COMPONENT_CATEGORIES[@]}"; do
            IFS='|' read -r _cat _glob manifest_prefix disk_prefix <<< "$category_spec"
            if [[ "$key" == ${manifest_prefix}* ]]; then
                upstream_path="$TMPDIR_UPSTREAM/${key/#$manifest_prefix/$disk_prefix}"
                break
            fi
        done

        if [[ -z "$upstream_path" || ! -f "$upstream_path" ]]; then
            removed_upstream+=("$key")
            continue
        fi

        local upstream_sha
        upstream_sha=$(compute_sha "$upstream_path")

        if [[ "$upstream_sha" == "$source_sha" ]]; then
            up_to_date=$((up_to_date + 1))
            continue
        fi

        # Component changed upstream
        # Check if this version was rejected
        if [[ "$status" == "rejected" && "$rejected_version" == "$latest_tag" ]]; then
            continue
        fi

        # Check local modifications
        local local_modified="no"
        if [[ "$local_sha" != "$source_sha" ]]; then
            local_modified="yes"
        fi

        outdated+=("${key}|${source_version}|${latest_tag}|${local_modified}|${upstream_sha}")
    done

    # Check for new components in upstream
    while IFS='|' read -r component_key _relpath; do
        [[ -z "$component_key" ]] && continue
        if [[ -z "${manifest_components[$component_key]+x}" ]]; then
            # Check if the file exists locally already (user might have it untracked)
            new_upstream+=("$component_key")
        fi
    done < <(discover_components "$TMPDIR_UPSTREAM")

    # Update last_check timestamp
    update_manifest_timestamp "last_check"

    # Write cache file for session-start notification
    local update_count=$(( ${#outdated[@]} + ${#new_upstream[@]} ))
    local check_timestamp
    check_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    cat > "$CHECK_CACHE_FILE" << CACHE_EOF
{
  "checked_at": "$check_timestamp",
  "local_version": "$local_version",
  "upstream_version": "$latest_tag",
  "outdated_count": ${#outdated[@]},
  "new_count": ${#new_upstream[@]},
  "update_count": $update_count
}
CACHE_EOF

    if [[ "$JSON_OUTPUT" == true ]]; then
        echo "{"
        echo "  \"local_version\": \"$local_version\","
        echo "  \"upstream_version\": \"$latest_tag\","
        echo "  \"total_checked\": $total_checked,"
        echo "  \"up_to_date\": $up_to_date,"
        echo "  \"outdated\": ["

        local first=true
        for entry in "${outdated[@]}"; do
            IFS='|' read -r key sv uv lm us <<< "$entry"
            [[ "$first" == true ]] && first=false || echo ","
            printf '    {"component": "%s", "from": "%s", "to": "%s", "local_modified": %s}' \
                "$key" "$sv" "$uv" "$([ "$lm" == "yes" ] && echo "true" || echo "false")"
        done
        echo ""
        echo "  ],"

        echo "  \"new_upstream\": ["
        first=true
        for key in "${new_upstream[@]}"; do
            [[ "$first" == true ]] && first=false || echo ","
            printf '    "%s"' "$key"
        done
        echo ""
        echo "  ],"

        echo "  \"removed_upstream\": ["
        first=true
        for key in "${removed_upstream[@]}"; do
            [[ "$first" == true ]] && first=false || echo ","
            printf '    "%s"' "$key"
        done
        echo ""
        echo "  ]"
        echo "}"
        return
    fi

    # Human-readable output
    echo ""

    if [[ ${#outdated[@]} -eq 0 && ${#new_upstream[@]} -eq 0 ]]; then
        echo -e "${GREEN}All components up to date!${NC} ($total_checked checked)"
        if [[ ${#removed_upstream[@]} -gt 0 ]]; then
            echo -e "\n${DIM}${#removed_upstream[@]} component(s) no longer in upstream (may have been moved or removed)${NC}"
        fi
        return
    fi

    echo -e "${BOLD}Updates Available${NC} (${local_version} -> ${latest_tag})"
    echo ""

    if [[ ${#outdated[@]} -gt 0 ]]; then
        echo -e "  ${YELLOW}Changed${NC} (${#outdated[@]})"
        for entry in "${outdated[@]}"; do
            IFS='|' read -r key sv uv lm _us <<< "$entry"
            local mod_note=""
            [[ "$lm" == "yes" ]] && mod_note=" ${RED}(local modifications)${NC}"
            echo -e "    ${YELLOW}↑${NC} ${key} ${DIM}($sv -> $uv)${NC}${mod_note}"
        done
        echo ""
    fi

    if [[ ${#new_upstream[@]} -gt 0 ]]; then
        echo -e "  ${GREEN}New${NC} (${#new_upstream[@]})"
        for key in "${new_upstream[@]}"; do
            echo -e "    ${GREEN}+${NC} ${key}"
        done
        echo ""
    fi

    local update_count=$(( ${#outdated[@]} + ${#new_upstream[@]} ))
    echo -e "${BOLD}Summary:${NC} $update_count update(s) available. Run ${CYAN}aifred-update.sh update${NC} to apply."
}

cmd_update() {
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        log_error "No manifest found. Run 'aifred-update.sh init' first."
        exit 2
    fi

    local upstream_url
    upstream_url=$(get_upstream_url)

    log_info "Fetching upstream for update..."

    # Get latest upstream version
    local latest_tag
    latest_tag=$(get_upstream_version "$upstream_url")

    if [[ -z "$latest_tag" ]]; then
        log_error "Could not determine latest upstream version"
        exit 3
    fi

    local local_version
    local_version=$(yaml_read "$MANIFEST_FILE" "aifred_version")

    # Clone upstream
    clone_upstream "$latest_tag" "$upstream_url"

    # Collect updatable components
    local -a update_entries=()

    # Read manifest components
    local -A manifest_components
    local in_components=false
    while IFS= read -r line; do
        if [[ "$line" == "components:" ]]; then
            in_components=true
            continue
        fi
        if [[ "$in_components" == true ]]; then
            if [[ "$line" =~ ^[a-zA-Z] ]]; then break; fi
            if [[ "$line" =~ ^[[:space:]]{2}([a-zA-Z][^:]+): ]]; then
                manifest_components["${BASH_REMATCH[1]}"]=1
            fi
        fi
    done < "$MANIFEST_FILE"

    # Check existing components for updates
    for key in $(echo "${!manifest_components[@]}" | tr ' ' '\n' | sort); do
        if is_ignored "$key"; then
            continue
        fi

        IFS='|' read -r source_version source_sha local_sha status rejected_version <<< "$(read_component "$key")"

        local upstream_path=""
        for category_spec in "${COMPONENT_CATEGORIES[@]}"; do
            IFS='|' read -r _cat _glob manifest_prefix disk_prefix <<< "$category_spec"
            if [[ "$key" == ${manifest_prefix}* ]]; then
                upstream_path="$TMPDIR_UPSTREAM/${key/#$manifest_prefix/$disk_prefix}"
                break
            fi
        done

        [[ -z "$upstream_path" || ! -f "$upstream_path" ]] && continue

        local upstream_sha
        upstream_sha=$(compute_sha "$upstream_path")

        [[ "$upstream_sha" == "$source_sha" ]] && continue

        # Skip if rejected at this version
        [[ "$status" == "rejected" && "$rejected_version" == "$latest_tag" ]] && continue

        local local_modified="no"
        [[ "$local_sha" != "$source_sha" ]] && local_modified="yes"

        update_entries+=("update|${key}|${source_version}|${latest_tag}|${local_modified}|${upstream_sha}|${upstream_path}")
    done

    # Check for new upstream components
    while IFS='|' read -r component_key relpath; do
        [[ -z "$component_key" ]] && continue
        if [[ -z "${manifest_components[$component_key]+x}" ]]; then
            if is_ignored "$component_key"; then
                continue
            fi
            local upstream_sha
            upstream_sha=$(compute_sha "$TMPDIR_UPSTREAM/$relpath")
            update_entries+=("new|${component_key}||${latest_tag}||${upstream_sha}|${TMPDIR_UPSTREAM}/${relpath}")
        fi
    done < <(discover_components "$TMPDIR_UPSTREAM")

    if [[ ${#update_entries[@]} -eq 0 ]]; then
        log_success "All components up to date!"
        update_manifest_timestamp "last_check"
        return
    fi

    echo ""
    echo -e "${BOLD}AIfred Update${NC} (${local_version} -> ${latest_tag})"
    echo -e "${DIM}${#update_entries[@]} component(s) to review${NC}"
    echo ""

    local accepted=0 skipped=0 rejected=0

    for entry in "${update_entries[@]}"; do
        IFS='|' read -r action key sv uv lm upstream_sha upstream_path <<< "$entry"

        # Determine local disk path
        local disk_path=""
        for category_spec in "${COMPONENT_CATEGORIES[@]}"; do
            IFS='|' read -r _cat _glob manifest_prefix disk_prefix <<< "$category_spec"
            if [[ "$key" == ${manifest_prefix}* ]]; then
                disk_path="$REPO_DIR/${key/#$manifest_prefix/$disk_prefix}"
                break
            fi
        done

        # Display component info
        echo -e "  ${BOLD}$key${NC}"
        if [[ "$action" == "new" ]]; then
            echo -e "  Status: ${GREEN}new component${NC} (in $uv)"
        else
            echo -e "  Status: ${YELLOW}outdated${NC} ($sv -> $uv) | Local modifications: $lm"
        fi
        echo ""

        if [[ "$DRY_RUN" == true ]]; then
            echo -e "  ${DIM}[dry-run] Would prompt for action${NC}"
            echo ""
            continue
        fi

        # Interactive prompt
        while true; do
            echo -ne "  [${GREEN}a${NC}]ccept  [${YELLOW}s${NC}]kip  [${RED}r${NC}]eject  [${CYAN}d${NC}]iff  [?]help > "
            read -rn1 choice
            echo ""

            case "$choice" in
                a|A)
                    # Accept: copy upstream file to local
                    local parent_dir
                    parent_dir=$(dirname "$disk_path")
                    mkdir -p "$parent_dir"
                    cp "$upstream_path" "$disk_path"

                    local new_local_sha
                    new_local_sha=$(compute_sha "$disk_path")

                    if [[ "$action" == "new" ]]; then
                        add_manifest_component "$key" "$uv" "$upstream_sha" "$new_local_sha" "current"
                    else
                        update_manifest_component "$key" "source_version" "$uv"
                        update_manifest_component "$key" "source_sha" "$upstream_sha"
                        update_manifest_component "$key" "local_sha" "$new_local_sha"
                        update_manifest_component "$key" "status" "current"
                    fi

                    echo -e "  ${GREEN}✓ Accepted${NC}"
                    accepted=$((accepted + 1))
                    break
                    ;;
                s|S)
                    echo -e "  ${YELLOW}— Skipped${NC} (will ask again next time)"
                    skipped=$((skipped + 1))
                    break
                    ;;
                r|R)
                    if [[ "$action" == "new" ]]; then
                        # For new components, just note in user_components or skip
                        echo -e "  ${RED}✗ Rejected${NC} (won't ask until newer version)"
                        # Add as rejected
                        add_manifest_component "$key" "$uv" "$upstream_sha" "" "rejected"
                        update_manifest_component "$key" "rejected_version" "$uv"
                    else
                        update_manifest_component "$key" "status" "rejected"
                        update_manifest_component "$key" "rejected_version" "$uv"
                        echo -e "  ${RED}✗ Rejected${NC} (won't ask until newer version)"
                    fi
                    rejected=$((rejected + 1))
                    break
                    ;;
                d|D)
                    # Show diff
                    echo ""
                    if [[ -f "$disk_path" ]]; then
                        diff --color=always -u "$disk_path" "$upstream_path" 2>/dev/null | head -60 || true
                    else
                        echo -e "  ${DIM}(new file — showing first 30 lines)${NC}"
                        head -30 "$upstream_path"
                    fi
                    echo ""
                    ;;
                '?')
                    echo ""
                    echo "  a/accept  - Copy upstream version to local, update manifest"
                    echo "  s/skip    - Leave as-is, will be offered again next check"
                    echo "  r/reject  - Permanently skip this version (offered when newer arrives)"
                    echo "  d/diff    - Show differences between local and upstream"
                    echo ""
                    ;;
                *)
                    echo -e "  ${DIM}Unknown option. Press ? for help.${NC}"
                    ;;
            esac
        done
        echo ""
    done

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${BOLD}[dry-run] Summary:${NC} ${#update_entries[@]} component(s) would be reviewed"
        return
    fi

    # Update timestamps
    update_manifest_timestamp "last_check"
    if [[ $accepted -gt 0 ]]; then
        update_manifest_timestamp "last_update"
        # Update aifred_version if all components are now current
        local tmpfile
        tmpfile=$(mktemp)
        while IFS= read -r line; do
            if [[ "$line" == aifred_version:* ]]; then
                echo "aifred_version: \"$latest_tag\"" >> "$tmpfile"
            else
                echo "$line" >> "$tmpfile"
            fi
        done < "$MANIFEST_FILE"
        mv "$tmpfile" "$MANIFEST_FILE"
    fi

    # Refresh cache file to reflect post-update state
    local remaining=$(( ${#update_entries[@]} - accepted - rejected ))
    local update_timestamp
    update_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    cat > "$CHECK_CACHE_FILE" << CACHE_EOF
{
  "checked_at": "$update_timestamp",
  "local_version": "$latest_tag",
  "upstream_version": "$latest_tag",
  "outdated_count": 0,
  "new_count": 0,
  "update_count": $remaining
}
CACHE_EOF

    echo -e "${BOLD}Update Complete:${NC} ${GREEN}$accepted accepted${NC} | ${YELLOW}$skipped skipped${NC} | ${RED}$rejected rejected${NC}"
}

# --- Main ---

COMMAND=""

# Parse global options first, then command
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -j|--json) JSON_OUTPUT=true; shift ;;
        -q|--quiet) QUIET=true; shift ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
        init|check|update|status)
            COMMAND="$1"; shift ;;
        -*)
            log_error "Unknown option: $1"
            echo "Run 'aifred-update.sh --help' for usage."
            exit 1
            ;;
        *)
            log_error "Unknown command: $1"
            echo "Run 'aifred-update.sh --help' for usage."
            exit 1
            ;;
    esac
done

if [[ -z "$COMMAND" ]]; then
    log_error "No command specified"
    echo "Run 'aifred-update.sh --help' for usage."
    exit 1
fi

case "$COMMAND" in
    init)   cmd_init   ;;
    check)  cmd_check  ;;
    update) cmd_update ;;
    status) cmd_status ;;
esac
