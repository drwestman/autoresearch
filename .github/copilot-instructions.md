# Copilot Instructions for autoresearch

## What This Repository Is

This is a **Claude Code plugin** — a Markdown-only skill and slash-command set. There is no compiled code, no backend, no test runner. The "application" is Markdown instructions that Claude Code reads and executes. Changes take effect immediately upon editing; there is no build step.

## Development Workflow

**Setup (symlink for live editing):**
```bash
ln -s $(pwd)/claude-plugin/skills/autoresearch ~/.claude/skills/autoresearch
ln -s $(pwd)/claude-plugin/commands/autoresearch ~/.claude/commands/autoresearch
ln -s $(pwd)/claude-plugin/commands/autoresearch.md ~/.claude/commands/autoresearch.md
```

**Testing:** Manual — invoke the modified skill in Claude Code and observe behavior. There is no automated test suite.

**Release:**
```bash
./scripts/release.sh <version> [--title "Release title"]
# Example: ./scripts/release.sh 1.9.0 --title "New subcommand: refactor"
# Versioning: patch (1.8.X) = bugfixes; minor (1.X.0) = new features; major (2.0.0) = reserved
```
The release script bumps versions in `plugin.json`, `marketplace.json`, `SKILL.md`, and `README.md`, then creates a PR.

## Repository Architecture

```
claude-plugin/              ← DISTRIBUTION (what users install via /plugin install)
  commands/
    autoresearch.md         ← Main /autoresearch command registration
    autoresearch/           ← 8 sub-command registrations (thin wrappers)
  skills/autoresearch/
    SKILL.md                ← Main skill entry point (597 lines) — loaded by ALL commands
    references/             ← Protocol files — loaded lazily per sub-command
      autonomous-loop-protocol.md
      core-principles.md
      plan-workflow.md
      security-workflow.md
      ship-workflow.md
      debug-workflow.md
      fix-workflow.md
      scenario-workflow.md
      predict-workflow.md
      learn-workflow.md
      results-logging.md

.claude/                    ← LOCAL development copies (gitignored; populated by symlink/copy)
guide/                      ← User-facing docs (one .md per command + advanced patterns)
scripts/
  release.sh                ← Automated release (version bump + PR + tag)
  release.md                ← Release process documentation
```

**Key architectural rule:** `SKILL.md` is always loaded. Reference files under `references/` are loaded only when their specific sub-command is invoked. This minimizes context window usage — do not move shared logic into reference files unnecessarily.

## What to Edit and When

| You want to… | Edit this file |
|---|---|
| Change the core loop (phases, rules, git memory) | `references/autonomous-loop-protocol.md` |
| Change the planning wizard | `references/plan-workflow.md` |
| Change security audit behavior | `references/security-workflow.md` |
| Change shipping checklist or ship types | `references/ship-workflow.md` |
| Change debug investigation techniques | `references/debug-workflow.md` |
| Change how errors are fixed | `references/fix-workflow.md` |
| Change scenario dimensions or domains | `references/scenario-workflow.md` |
| Change prediction personas or confidence model | `references/predict-workflow.md` |
| Change documentation generation behavior | `references/learn-workflow.md` |
| Change TSV log format or summary output | `references/results-logging.md` |
| Add a new sub-command | Create `claude-plugin/commands/autoresearch/<name>.md` + corresponding reference file + entry in `SKILL.md` routing table |
| Bump version | Use `./scripts/release.sh` — do not hand-edit version numbers |
| Update user-facing docs | `guide/` — one file per command |

## Key Conventions

**Commit messages** use [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` — new feature or sub-command
- `fix:` — bug fix in existing behavior
- `docs:` — documentation-only changes
- `refactor:` — restructuring without behavior change
- `chore:` — maintenance (dependency bumps, CI)

**Sub-command registration files** (e.g., `commands/autoresearch/plan.md`) are thin wrappers — they load `SKILL.md` and the relevant reference file, then execute. All substantive logic lives in `SKILL.md` or a reference file.

**Interactive Setup Gate:** Every command must collect full context via `AskUserQuestion` batches before executing. This is enforced in `SKILL.md` — do not bypass it when adding new commands.

**Mechanical metrics only:** The loop only accepts metrics extractable as a float via a shell command (`grep`, `awk`, `jq`). Subjective assessments are not valid metrics. This constraint applies to all sub-commands that produce a measurable output.

**Git as loop memory:** The autonomous loop reads `git log --oneline -20` and `git diff HEAD~1` at the start of every iteration. Commits use the `experiment:` prefix. Discarded iterations are reverted with `git reset --hard HEAD~1`.

**TSV logging:** Results are appended to `autoresearch-results.tsv` in the user's project (not this repo). Format: `iteration | commit | metric | delta | guard_status | result_status | description`.
