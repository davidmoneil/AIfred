#!/bin/bash
#
# bump-version.sh - Version bump utility for Project Aion Archons
#
# Usage:
#   ./scripts/bump-version.sh patch   # 1.0.0 -> 1.0.1
#   ./scripts/bump-version.sh minor   # 1.0.0 -> 1.1.0
#   ./scripts/bump-version.sh major   # 1.0.0 -> 2.0.0
#   ./scripts/bump-version.sh show    # Display current version
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VERSION_FILE="$PROJECT_ROOT/VERSION"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 {patch|minor|major|show}"
    echo ""
    echo "Commands:"
    echo "  patch  - Bump patch version (x.x.+1) for benchmarks, docs, fixes"
    echo "  minor  - Bump minor version (x.+1.0) for new features"
    echo "  major  - Bump major version (+1.0.0) for breaking changes"
    echo "  show   - Display current version"
    echo ""
    echo "Examples:"
    echo "  $0 patch   # 1.0.0 -> 1.0.1"
    echo "  $0 minor   # 1.0.0 -> 1.1.0"
    echo "  $0 major   # 1.0.0 -> 2.0.0"
    exit 1
}

get_current_version() {
    if [[ ! -f "$VERSION_FILE" ]]; then
        echo -e "${RED}Error: VERSION file not found at $VERSION_FILE${NC}" >&2
        exit 1
    fi
    cat "$VERSION_FILE" | tr -d '\n'
}

bump_version() {
    local current_version="$1"
    local bump_type="$2"

    # Parse version components
    IFS='.' read -r major minor patch <<< "$current_version"

    case "$bump_type" in
        patch)
            patch=$((patch + 1))
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        *)
            echo -e "${RED}Error: Unknown bump type '$bump_type'${NC}" >&2
            exit 1
            ;;
    esac

    echo "${major}.${minor}.${patch}"
}

write_version() {
    local new_version="$1"
    echo -n "$new_version" > "$VERSION_FILE"
}

# Main
if [[ $# -ne 1 ]]; then
    usage
fi

COMMAND="$1"

case "$COMMAND" in
    show)
        echo "$(get_current_version)"
        ;;
    patch|minor|major)
        CURRENT=$(get_current_version)
        NEW=$(bump_version "$CURRENT" "$COMMAND")

        echo -e "${YELLOW}Bumping version:${NC}"
        echo -e "  Current: ${RED}$CURRENT${NC}"
        echo -e "  New:     ${GREEN}$NEW${NC}"
        echo ""

        write_version "$NEW"

        echo -e "${GREEN}Version updated to $NEW${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Update CHANGELOG.md with changes"
        echo "  2. Update version references in documentation"
        echo "  3. Commit: git commit -am \"Release v$NEW\""
        echo "  4. Tag: git tag v$NEW"
        ;;
    *)
        usage
        ;;
esac
