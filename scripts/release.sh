#!/usr/bin/env bash
# Release script — bumps plugin.json version, commits, tags, and creates GitHub release.
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 1.7.0

set -euo pipefail

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "Usage: ./scripts/release.sh <version>"
  echo "Example: ./scripts/release.sh 1.7.0"
  exit 1
fi

# Strip leading 'v' if provided (e.g. v1.7.0 → 1.7.0)
VERSION="${VERSION#v}"
TAG="v${VERSION}"

PLUGIN_JSON=".claude-plugin/plugin.json"

# Verify plugin.json exists
if [[ ! -f "$PLUGIN_JSON" ]]; then
  echo "Error: $PLUGIN_JSON not found"
  exit 1
fi

# Check for clean working tree
if [[ -n "$(git status --porcelain -- "$PLUGIN_JSON")" ]]; then
  echo "Error: $PLUGIN_JSON has uncommitted changes. Commit or stash first."
  exit 1
fi

# Read current version
CURRENT=$(grep -o '"version": "[^"]*"' "$PLUGIN_JSON" | cut -d'"' -f4)
if [[ "$CURRENT" == "$VERSION" ]]; then
  echo "plugin.json already at version $VERSION — skipping bump."
else
  echo "Bumping plugin.json: $CURRENT → $VERSION"

  # Update version in plugin.json using portable sed
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$VERSION\"/" "$PLUGIN_JSON"
  else
    sed -i "s/\"version\": \"$CURRENT\"/\"version\": \"$VERSION\"/" "$PLUGIN_JSON"
  fi

  git add "$PLUGIN_JSON"
  git commit -m "chore: bump plugin.json version to $VERSION"
fi

# Tag and push
echo "Creating tag $TAG..."
git tag -a "$TAG" -m "Release $TAG"
git push origin master --tags

# Create GitHub release (prompts for release notes via editor)
echo "Creating GitHub release..."
gh release create "$TAG" --title "$TAG" --generate-notes

echo "Done! Released $TAG"
