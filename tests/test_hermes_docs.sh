#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

failures=0

assert_contains() {
  local file="$1"
  local needle="$2"
  if ! grep -Fq "$needle" "$file"; then
    echo "FAIL: expected $file to contain: $needle"
    failures=1
  fi
}

assert_not_contains() {
  local file="$1"
  local needle="$2"
  if grep -Fq "$needle" "$file"; then
    echo "FAIL: expected $file to NOT contain: $needle"
    failures=1
  fi
}

# Comment 1 + 2: broken URLs in Hermes SKILL.md.
assert_contains "hermes-plugin/skills/autoresearch/SKILL.md" "https://github.com/karpathy/autoresearch"
assert_contains "hermes-plugin/skills/autoresearch/SKILL.md" "/user/starred/uditgoenka/autoresearch"

# Comments 4, 5, 10: results logging examples should match the TSV schema in every maintained copy.
RESULTS_FILES=(
  ".claude/skills/autoresearch/references/results-logging.md"
  "claude-plugin/skills/autoresearch/references/results-logging.md"
  "copilot-plugin/skills/autoresearch/references/results-logging.md"
  "hermes-plugin/skills/autoresearch/references/results-logging.md"
)
for file in "${RESULTS_FILES[@]}"; do
  assert_contains "$file" 'echo -e "0\t${COMMIT}\t${BASELINE}\t0.0\tpass\t-\tbaseline\tinitial state — coverage ${BASELINE}%" >> autoresearch-results.tsv'
  assert_contains "$file" "LAST_5=\$(grep -v '^#' autoresearch-results.tsv | awk -F'\\t' '\$1 != \"iteration\" {print \$7}' | tail -5)"
  assert_contains "$file" "grep 'keep' autoresearch-results.tsv | awk -F'\\t' '{print \$8}'"
  assert_contains "$file" '# 4. Agent appends: "1  b2c3d4e  74.5  +2.5  pass  -  keep  add auth middleware tests"'
done

# Comment 3: keep the Copilot distribution target, but fix broken slashes and temp path.
assert_contains "hermes-plugin/skills/autoresearch/references/security-workflow.md" "git clone https://github.com/uditgoenka/autoresearch.git /tmp/autoresearch"
assert_contains "hermes-plugin/skills/autoresearch/references/security-workflow.md" "cp -r /tmp/autoresearch/copilot-plugin/skills/autoresearch ~/.copilot/skills/autoresearch"
assert_contains "hermes-plugin/skills/autoresearch/references/security-workflow.md" "cp -r /tmp/autoresearch/copilot-plugin/commands/autoresearch ~/.copilot/commands/autoresearch"
assert_contains "hermes-plugin/skills/autoresearch/references/security-workflow.md" "cp /tmp/autoresearch/copilot-plugin/commands/autoresearch.md ~/.copilot/commands/autoresearch.md"

# Comments 6 + 7: Hermes docs must use the real Hermes clarify tool instead of placeholder pseudo-calls.
assert_not_contains "hermes-plugin/skills/autoresearch/SKILL.md" "config confirmation"
assert_not_contains "hermes-plugin/skills/autoresearch/references/plan-workflow.md" "presenting the config summary to the user"
assert_not_contains "hermes-plugin/skills/autoresearch/references/autonomous-loop-protocol.md" "presenting the config summary to the user"
assert_contains "hermes-plugin/skills/autoresearch/SKILL.md" '| "autoresearch plan" — Phase 7 (Confirm & Launch) | Config validated, baseline confirmed | `clarify` | `autopilot` |'
assert_contains "hermes-plugin/skills/autoresearch/SKILL.md" 'Use `clarify` with the formatted config block and choices `["autopilot", "interactive", "exit_only"]`'
assert_contains "hermes-plugin/skills/autoresearch/references/plan-workflow.md" 'clarify(question=<the formatted configuration block above + launch prompt>, choices=["autopilot", "interactive", "exit_only"])'
assert_contains "hermes-plugin/skills/autoresearch/references/autonomous-loop-protocol.md" 'clarify(question=<the formatted block above + launch prompt>, choices=["autopilot", "interactive", "exit_only"])'

# Comment 8: install-hermes must refuse unsafe target directories before any rm -rf.
assert_contains "scripts/install-hermes.sh" 'if [[ -z "$HERMES_HOME" || "$HERMES_HOME" == "/" ]]; then'
assert_contains "scripts/install-hermes.sh" 'SAFE_SKILLS_PREFIX="$HERMES_HOME/skills/"'
assert_contains "scripts/install-hermes.sh" 'case "$TARGET_DIR" in'
assert_contains "scripts/install-hermes.sh" 'Refusing to modify unsafe target directory'

# Comment 9: release automation must not overwrite Hermes-specific refs from .claude.
assert_not_contains "scripts/release.sh" "cp .claude/skills/autoresearch/references/*.md hermes-plugin/skills/autoresearch/references/"
assert_contains "scripts/release.sh" 'Skipped hermes-plugin/skills/autoresearch/references/ auto-sync'
assert_contains "scripts/release.md" "Hermes reference files are distribution-specific"
assert_contains "CONTRIBUTING.md" "hermes-plugin"
assert_contains "CONTRIBUTING.md" "Hermes reference files are distribution-specific"

if (( failures )); then
  exit 1
fi

echo "PASS: Hermes docs regression checks"
