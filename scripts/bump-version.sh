#!/usr/bin/env bash
#
# bump-version.sh — Bump AIfred version (Major.Minor.Patch)
#
# Usage: scripts/bump-version.sh [major|minor|patch]
#
# Reads VERSION file, calculates new version, updates file, creates git tag.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_FILE="$REPO_DIR/VERSION"

if [[ ! -f "$VERSION_FILE" ]]; then
    echo "ERROR: VERSION file not found at $VERSION_FILE"
    exit 1
fi

CURRENT=$(tr -d '[:space:]' < "$VERSION_FILE")

if [[ ! "$CURRENT" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: VERSION file contains invalid version: '$CURRENT'"
    echo "Expected format: MAJOR.MINOR.PATCH (e.g., 1.1.0)"
    exit 1
fi

BUMP_TYPE="${1:-}"

if [[ -z "$BUMP_TYPE" ]]; then
    echo "AIfred Version Manager"
    echo ""
    echo "Current version: $CURRENT"
    echo ""
    echo "Usage: $0 [major|minor|patch]"
    echo ""
    echo "  major  — Breaking changes      ($(echo "$CURRENT" | awk -F. '{print $1+1}').0.0)"
    echo "  minor  — New features           ($(echo "$CURRENT" | awk -F. '{printf "%s.%s.0", $1, $2+1}'))"
    echo "  patch  — Bug fixes/tweaks       ($(echo "$CURRENT" | awk -F. '{printf "%s.%s.%s", $1, $2, $3+1}'))"
    exit 0
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "ERROR: Unknown bump type '$BUMP_TYPE'"
        echo "Use: major, minor, or patch"
        exit 1
        ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
TAG="v${NEW_VERSION}"

# Check if tag already exists
if git -C "$REPO_DIR" rev-parse "$TAG" >/dev/null 2>&1; then
    echo "ERROR: Tag $TAG already exists"
    exit 1
fi

# Update VERSION file
echo "$NEW_VERSION" > "$VERSION_FILE"

echo "$CURRENT → $NEW_VERSION"
echo ""
echo "Updated: VERSION"
echo "Tag:     $TAG"
echo ""
echo "Next steps:"
echo "  git add VERSION"
echo "  git commit -m \"release: $TAG\""
echo "  git tag $TAG"
