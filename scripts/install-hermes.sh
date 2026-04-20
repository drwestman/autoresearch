#!/usr/bin/env bash
# Install autoresearch as a Hermes Agent skill.
#
# Usage:
#   ./scripts/install-hermes.sh              # Copy skill files
#   ./scripts/install-hermes.sh --link       # Symlink (for development)
#   ./scripts/install-hermes.sh --uninstall  # Remove the skill
#
# Environment:
#   HERMES_HOME    Override Hermes home directory (default: ~/.hermes)

set -euo pipefail

# --- Configuration ---
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
CATEGORY="productivity"
SKILL_NAME="autoresearch"
TARGET_DIR="$HERMES_HOME/skills/$CATEGORY/$SKILL_NAME"

# Resolve script location → repo root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$REPO_ROOT/hermes-plugin/skills/autoresearch"

# --- Parse arguments ---
ACTION="install"
LINK=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --link)      LINK=true; shift ;;
    --uninstall) ACTION="uninstall"; shift ;;
    --help|-h)
      echo "Usage: ./scripts/install-hermes.sh [--link] [--uninstall]"
      echo ""
      echo "  --link       Symlink instead of copy (for development)"
      echo "  --uninstall  Remove the autoresearch skill"
      echo ""
      echo "Environment:"
      echo "  HERMES_HOME  Override Hermes home (default: ~/.hermes)"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Preflight checks ---
if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: Source directory not found: $SOURCE_DIR"
  echo "Run this script from the autoresearch repository root."
  exit 1
fi

if [[ ! -f "$SOURCE_DIR/SKILL.md" ]]; then
  echo "Error: SKILL.md not found in $SOURCE_DIR"
  exit 1
fi

# --- Uninstall ---
if [[ "$ACTION" == "uninstall" ]]; then
  if [[ -d "$TARGET_DIR" || -L "$TARGET_DIR" ]]; then
    rm -rf "$TARGET_DIR"
    echo ""
    echo "=== autoresearch uninstalled ==="
    echo "  Removed: $TARGET_DIR"
    echo ""
    echo "  The skill will no longer appear in 'hermes skills list'."
    echo "  Start a new session (/reset) for changes to take effect."
  else
    echo "autoresearch is not installed at $TARGET_DIR"
  fi
  exit 0
fi

# --- Install ---
echo ""
echo "=== Installing autoresearch for Hermes Agent ==="
echo "  Source:  $SOURCE_DIR"
echo "  Target:  $TARGET_DIR"
echo "  Mode:    $(if $LINK; then echo "symlink"; else echo "copy"; fi)"
echo ""

# Remove existing installation
if [[ -d "$TARGET_DIR" || -L "$TARGET_DIR" ]]; then
  echo "  Removing existing installation..."
  rm -rf "$TARGET_DIR"
fi

if $LINK; then
  # Symlink mode — create parent dirs, then symlink the whole skill directory
  mkdir -p "$(dirname "$TARGET_DIR")"
  ln -s "$SOURCE_DIR" "$TARGET_DIR"
  echo "  Symlinked: $TARGET_DIR -> $SOURCE_DIR"
else
  # Copy mode
  mkdir -p "$TARGET_DIR/references"
  cp "$SOURCE_DIR/SKILL.md" "$TARGET_DIR/SKILL.md"
  cp "$SOURCE_DIR/references/"*.md "$TARGET_DIR/references/"
  echo "  Copied SKILL.md + $(ls "$SOURCE_DIR/references/"*.md | wc -l | tr -d ' ') reference files"
fi

echo ""
echo "=== Installed successfully ==="
echo ""
echo "  Usage:"
echo "    hermes -s autoresearch           # Preload at launch"
echo "    /skill autoresearch              # Load mid-session"
echo ""
echo "  Then tell the agent what to do:"
echo "    autoresearch                     # Autonomous loop"
echo "    autoresearch plan                # Planning wizard"
echo "    autoresearch debug               # Bug hunting"
echo "    autoresearch fix                 # Error repair"
echo "    autoresearch security            # Security audit"
echo "    autoresearch ship                # Ship workflow"
echo "    autoresearch scenario            # Scenario explorer"
echo "    autoresearch predict             # Multi-persona analysis"
echo "    autoresearch learn               # Documentation engine"
echo "    autoresearch reason              # Adversarial refinement"
echo ""
echo "  Start a new session (/reset) if already in a Hermes session."
