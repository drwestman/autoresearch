#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

failures=0

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL: $label expected exit $expected, got $actual"
    failures=1
  fi
}

assert_output_contains() {
  local output="$1"
  local needle="$2"
  local label="$3"
  if [[ "$output" != *"$needle"* ]]; then
    echo "FAIL: $label expected output to contain: $needle"
    failures=1
  fi
}

# Unsafe root target must be rejected even if nothing is currently installed.
set +e
unsafe_output="$(HERMES_HOME=/ bash scripts/install-hermes.sh --uninstall 2>&1)"
unsafe_status=$?
set -e
assert_exit_code 1 "$unsafe_status" "unsafe-root"
assert_output_contains "$unsafe_output" "Refusing to modify unsafe target directory" "unsafe-root"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# Traversal segments that collapse to / must also be rejected before any rm -rf path is considered safe.
set +e
traversal_output="$(HERMES_HOME=/tmp/hermes-home/../.. bash scripts/install-hermes.sh --uninstall 2>&1)"
traversal_status=$?
set -e
assert_exit_code 1 "$traversal_status" "unsafe-traversal"
assert_output_contains "$traversal_output" "Refusing to modify unsafe target directory" "unsafe-traversal"

# Safe custom home should still work for uninstall.
safe_home="$tmpdir/hermes-home"
target_dir="$safe_home/skills/productivity/autoresearch"
mkdir -p "$target_dir"
printf 'marker\n' > "$target_dir/SKILL.md"

set +e
safe_output="$(HERMES_HOME="$safe_home" bash scripts/install-hermes.sh --uninstall 2>&1)"
safe_status=$?
set -e
assert_exit_code 0 "$safe_status" "safe-uninstall"
assert_output_contains "$safe_output" "Removed: $target_dir" "safe-uninstall"
if [[ -e "$target_dir" ]]; then
  echo "FAIL: safe-uninstall expected target to be removed"
  failures=1
fi

if (( failures )); then
  exit 1
fi

echo "PASS: install-hermes safety checks"
