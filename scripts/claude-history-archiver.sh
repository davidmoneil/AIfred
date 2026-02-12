#!/bin/bash
# Claude Code Conversation History Archiver
# Archives old/large conversation files with keyword-rich filenames
#
# Usage:
#   ./claude-history-archiver.sh [--dry-run] [--archive] [--status]
#
# AIfred history archiver

set -uo pipefail
# Note: -e removed to handle find returning no results gracefully

# Configuration
PROJECTS_DIR="$HOME/.claude/projects"
ARCHIVE_DIR="$HOME/.claude/archive/conversations"

# Optional: project-local manifest/index (set via environment or auto-detect)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MANIFEST="${MANIFEST:-$PROJECT_DIR/.claude/context/archive/conversations/manifest.yaml}"
INDEX="${INDEX:-$PROJECT_DIR/.claude/context/archive/conversations/_index.md}"

# Archive policy (can be overridden via environment)
ARCHIVE_AGE_DAYS="${ARCHIVE_AGE_DAYS:-7}"
ARCHIVE_SIZE_MB="${ARCHIVE_SIZE_MB:-5}"
MIN_AGE_DAYS="${MIN_AGE_DAYS:-1}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Parse command line
DRY_RUN=false
ACTION="status"

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            ACTION="archive"
            shift
            ;;
        --archive)
            ACTION="archive"
            shift
            ;;
        --status)
            ACTION="status"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--dry-run] [--archive] [--status]"
            echo ""
            echo "Options:"
            echo "  --status     Show current status (default)"
            echo "  --archive    Archive eligible files"
            echo "  --dry-run    Preview what would be archived"
            echo ""
            echo "Environment variables:"
            echo "  ARCHIVE_AGE_DAYS  Archive files older than N days (default: 7)"
            echo "  ARCHIVE_SIZE_MB   Archive files larger than N MB (default: 5)"
            echo "  MIN_AGE_DAYS      Never archive files younger than N days (default: 1)"
            echo "  MANIFEST          Path to manifest.yaml (default: auto-detect)"
            echo "  INDEX             Path to _index.md (default: auto-detect)"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Ensure directories exist
mkdir -p "$ARCHIVE_DIR"

# Extract project name from folder path
# Input: -home-username-Code-my-project
# Output: my-project
extract_project_name() {
    local folder="$1"
    # Remove common prefixes and extract meaningful name
    echo "$folder" | sed -E 's/^-home-[^-]+-//' | sed -E 's/^(Code|Docker)-?//' | tr '[:upper:]' '[:lower:]' | sed 's/^-//'
}

# Extract keywords from first user message in JSONL
# Returns: space-separated keywords
extract_keywords() {
    local jsonl_file="$1"

    # Get first user message content
    local first_msg=$(head -20 "$jsonl_file" 2>/dev/null | jq -r 'select(.role == "user") | .content' 2>/dev/null | head -1)

    if [[ -z "$first_msg" ]]; then
        echo "general"
        return
    fi

    # Extract meaningful words (nouns, verbs) - simple heuristic
    # Remove common words, keep 2-4 keywords
    local keywords=$(echo "$first_msg" | \
        tr '[:upper:]' '[:lower:]' | \
        tr -cs '[:alnum:]' ' ' | \
        tr ' ' '\n' | \
        grep -vE '^(the|a|an|is|are|was|were|be|been|being|have|has|had|do|does|did|will|would|could|should|may|might|must|shall|can|need|dare|ought|used|to|of|in|for|on|with|at|by|from|as|into|through|during|before|after|above|below|between|under|again|further|then|once|here|there|when|where|why|how|all|each|every|both|few|more|most|other|some|such|no|nor|not|only|own|same|so|than|too|very|just|also|now|i|you|he|she|it|we|they|what|which|who|whom|this|that|these|those|am|my|your|his|her|its|our|their|me|him|us|them|and|but|if|or|because|as|until|while|although|though|after|before|when|please|help|want|like|know|think|make|get|see|look|find|use|tell|ask|work|seem|feel|try|leave|call|keep|let|begin|show|hear|play|run|move|live|believe|hold|bring|happen|write|provide|sit|stand|lose|pay|meet|include|continue|set|learn|change|lead|understand|watch|follow|stop|create|speak|read|allow|add|spend|grow|open|walk|win|offer|remember|love|consider|appear|buy|wait|serve|die|send|expect|build|stay|fall|cut|reach|kill|remain|suggest|raise|pass|sell|require|report|decide|pull)$' | \
        head -4 | \
        tr '\n' '-' | \
        sed 's/-$//')

    if [[ -z "$keywords" ]]; then
        echo "general"
    else
        echo "$keywords"
    fi
}

# Detect conversation type from content
detect_type() {
    local jsonl_file="$1"
    local content=$(head -50 "$jsonl_file" 2>/dev/null | tr '[:upper:]' '[:lower:]')

    if echo "$content" | grep -qE '(error|fix|bug|issue|broken|failed|not working|debug)'; then
        echo "troubleshooting"
    elif echo "$content" | grep -qE '(plan|design|architect|structure|approach|strategy)'; then
        echo "planning"
    elif echo "$content" | grep -qE '(build|create|implement|add|write|develop)'; then
        echo "implementation"
    elif echo "$content" | grep -qE '(research|analyze|investigate|understand|explore|find)'; then
        echo "analysis"
    else
        echo "exploration"
    fi
}

# Generate archive filename
# Format: {date}_{project}_{keywords}_{type}.jsonl
generate_filename() {
    local original_file="$1"
    local folder_name="$2"

    # Get file date
    local file_date=$(date -r "$original_file" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)

    # Extract project
    local project=$(extract_project_name "$folder_name")
    [[ -z "$project" ]] && project="unknown"

    # Extract keywords
    local keywords=$(extract_keywords "$original_file")

    # Detect type
    local conv_type=$(detect_type "$original_file")

    # Build filename
    echo "${file_date}_${project}_${keywords}_${conv_type}.jsonl"
}

# Show status
show_status() {
    log_info "Claude Code Conversation History Status"
    echo ""

    # Current projects folder
    local projects_size=$(du -sh "$PROJECTS_DIR" 2>/dev/null | awk '{print $1}')
    local projects_count=$(find "$PROJECTS_DIR" -maxdepth 1 -type d 2>/dev/null | wc -l)
    ((projects_count--)) # Subtract parent dir

    echo "Active Projects: $PROJECTS_DIR"
    echo "  Size: $projects_size"
    echo "  Folders: $projects_count"
    echo ""

    # Archive folder
    local archive_size=$(du -sh "$ARCHIVE_DIR" 2>/dev/null | awk '{print $1}' || echo "0")
    local archive_count=$(find "$ARCHIVE_DIR" -name "*.jsonl" 2>/dev/null | wc -l)

    echo "Archive: $ARCHIVE_DIR"
    echo "  Size: $archive_size"
    echo "  Files: $archive_count"
    echo ""

    # Policy
    echo "Archive Policy:"
    echo "  Age threshold: $ARCHIVE_AGE_DAYS days"
    echo "  Size threshold: $ARCHIVE_SIZE_MB MB"
    echo "  Minimum age: $MIN_AGE_DAYS days"
    echo ""

    # Find eligible files
    log_info "Scanning for eligible files..."
    local eligible=0
    local eligible_size=0

    while IFS= read -r -d '' folder; do
        local folder_name=$(basename "$folder")

        # Find JSONL files
        while IFS= read -r -d '' jsonl; do
            local file_age_days=$(( ($(date +%s) - $(stat -c %Y "$jsonl" 2>/dev/null || echo 0)) / 86400 ))
            local file_size_mb=$(( $(stat -c %s "$jsonl" 2>/dev/null || echo 0) / 1048576 ))

            # Skip files younger than MIN_AGE_DAYS
            if [[ $file_age_days -lt $MIN_AGE_DAYS ]]; then
                continue
            fi

            # Check if eligible
            if [[ $file_age_days -ge $ARCHIVE_AGE_DAYS ]] || [[ $file_size_mb -ge $ARCHIVE_SIZE_MB ]]; then
                ((eligible++)) || true
                ((eligible_size += file_size_mb)) || true
            fi
        done < <(find "$folder" -maxdepth 1 -name "*.jsonl" -type f -print0 2>/dev/null || true)
    done < <(find "$PROJECTS_DIR" -maxdepth 1 -type d -print0 2>/dev/null || true)

    echo "Eligible for archive: $eligible files (~${eligible_size}MB)"

    if [[ $eligible -gt 0 ]]; then
        echo ""
        log_info "Run with --archive to archive eligible files"
        log_info "Run with --dry-run to preview without changes"
    fi
}

# Archive eligible files
do_archive() {
    log_info "Archiving eligible conversation files..."
    [[ "$DRY_RUN" == "true" ]] && log_warn "DRY RUN - no changes will be made"
    echo ""

    local archived=0
    local archived_size=0
    local skipped=0

    while IFS= read -r -d '' folder; do
        local folder_name=$(basename "$folder")

        # Skip the projects dir itself
        [[ "$folder" == "$PROJECTS_DIR" ]] && continue

        # Find JSONL files in this project folder
        while IFS= read -r -d '' jsonl; do
            local file_age_days=$(( ($(date +%s) - $(stat -c %Y "$jsonl" 2>/dev/null || echo 0)) / 86400 ))
            local file_size_bytes=$(stat -c %s "$jsonl" 2>/dev/null || echo 0)
            local file_size_mb=$(( file_size_bytes / 1048576 ))
            local file_size_kb=$(( file_size_bytes / 1024 ))

            # Skip files younger than MIN_AGE_DAYS
            if [[ $file_age_days -lt $MIN_AGE_DAYS ]]; then
                continue
            fi

            # Check if eligible (age OR size)
            if [[ $file_age_days -ge $ARCHIVE_AGE_DAYS ]] || [[ $file_size_mb -ge $ARCHIVE_SIZE_MB ]]; then
                # Generate new filename
                local new_name=$(generate_filename "$jsonl" "$folder_name")
                local dest="$ARCHIVE_DIR/$new_name"

                # Handle duplicates
                local counter=1
                while [[ -f "$dest" ]]; do
                    new_name="${new_name%.jsonl}-${counter}.jsonl"
                    dest="$ARCHIVE_DIR/$new_name"
                    ((counter++))
                done

                if [[ "$DRY_RUN" == "true" ]]; then
                    echo "Would archive: $(basename "$jsonl") → $new_name (${file_size_kb}KB, ${file_age_days}d old)"
                else
                    mv "$jsonl" "$dest"
                    log_success "Archived: $new_name (${file_size_kb}KB)"
                fi

                ((archived++)) || true
                ((archived_size += file_size_kb)) || true
            fi
        done < <(find "$folder" -maxdepth 1 -name "*.jsonl" -type f -print0 2>/dev/null || true)
    done < <(find "$PROJECTS_DIR" -maxdepth 1 -type d -print0 2>/dev/null || true)

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would archive: $archived files (~$((archived_size / 1024))MB)"
    else
        log_success "Archived: $archived files (~$((archived_size / 1024))MB)"

        # Update manifest if we archived anything and manifest exists
        if [[ $archived -gt 0 ]] && [[ -f "$MANIFEST" ]]; then
            log_info "Updating manifest..."
            update_manifest
        fi
    fi
}

# Update manifest.yaml with current archive contents
update_manifest() {
    local count=$(find "$ARCHIVE_DIR" -name "*.jsonl" 2>/dev/null | wc -l)
    local size_mb=$(du -sm "$ARCHIVE_DIR" 2>/dev/null | awk '{print $1}')
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Update the header values in manifest
    sed -i "s/^last_updated:.*/last_updated: \"$timestamp\"/" "$MANIFEST"
    sed -i "s/^total_conversations:.*/total_conversations: $count/" "$MANIFEST"
    sed -i "s/^total_size_mb:.*/total_size_mb: $size_mb/" "$MANIFEST"

    log_success "Manifest updated: $count conversations, ${size_mb}MB"
}

# Main
case "$ACTION" in
    status)
        show_status
        ;;
    archive)
        do_archive
        ;;
esac
