# Copilot Instructions for autoresearch

## What This Repository Is

This repository contains **two Markdown-only plugins** — a Markdown-only skill and slash-command set. There is no compiled code, no backend, no test runner. The "application" is Markdown instructions that Claude Code or Copilot CLI reads and executes. Changes take effect immediately upon editing; there is no build step.

| Plugin | Target | Directory |
|--------|--------|-----------|
| Claude Code plugin | Claude Code | `claude-plugin/` |
| Copilot CLI plugin | GitHub Copilot CLI | `copilot-plugin/` |

## Development Workflow

### Claude Code Setup (symlink for live editing)
```bash
ln -s $(pwd)/claude-plugin/skills/autoresearch ~/.claude/skills/autoresearch
ln -s $(pwd)/claude-plugin/commands/autoresearch ~/.claude/commands/autoresearch
ln -s $(pwd)/claude-plugin/commands/autoresearch.md ~/.claude/commands/autoresearch.md
```

### Copilot CLI Setup (symlink for live editing)
```bash
ln -s $(pwd)/copilot-plugin/skills/autoresearch ~/.copilot/skills/autoresearch
ln -s $(pwd)/copilot-plugin/commands/autoresearch ~/.copilot/commands/autoresearch
ln -s $(pwd)/copilot-plugin/commands/autoresearch.md ~/.copilot/commands/autoresearch.md
```

**Testing:** Manual — invoke the modified skill in the respective CLI and observe behavior. There is no automated test suite.

**Release:**
```bash
./scripts/release.sh <version> [--title "Release title"]
# Example: ./scripts/release.sh 1.9.0 --title "New subcommand: refactor"
# Versioning: patch (1.8.X) = bugfixes; minor (1.X.0) = new features; major (2.0.0) = reserved
```
The release script bumps versions in both `claude-plugin/` and `copilot-plugin/` plugin.json files, `marketplace.json`, `SKILL.md`, and `README.md`, then creates a PR.

## Repository Architecture

```
claude-plugin/              ← Claude Code distribution (install via /plugin install)
  .claude-plugin/
    plugin.json             ← Claude Code plugin metadata
  commands/
    autoresearch.md         ← Main /autoresearch command registration
    autoresearch/           ← 8 sub-command registrations (thin wrappers)
  skills/autoresearch/
    SKILL.md                ← Main skill entry point — loaded by ALL commands
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

copilot-plugin/             ← Copilot CLI distribution (install via /plugin install)
  .claude-plugin/
    plugin.json             ← Copilot CLI plugin metadata
  commands/                 ← Same structure as claude-plugin/commands/
    autoresearch.md         ← Uses .copilot/skills/ paths (not .claude/skills/)
    autoresearch/
  skills/autoresearch/
    SKILL.md                ← Includes Copilot CLI Mode Integration section
    references/
      autonomous-loop-protocol.md  ← Includes Copilot CLI Launch Gate
      plan-workflow.md              ← Includes exit_plan_mode at Phase 7
      ... (same reference files as claude-plugin)

.claude/                    ← LOCAL development copies (gitignored; populated by symlink/copy)
guide/                      ← User-facing docs (one .md per command + advanced patterns)
scripts/
  release.sh                ← Automated release (version bump + PR + tag)
  release.md                ← Release process documentation
```

**Key architectural rule:** `SKILL.md` is always loaded. Reference files under `references/` are loaded only when their specific sub-command is invoked. This minimizes context window usage — do not move shared logic into reference files unnecessarily.

**Path convention:**
- `claude-plugin/` command files reference `.claude/skills/autoresearch/references/`
- `copilot-plugin/` command files reference `.copilot/skills/autoresearch/references/`

**Development source of truth:**
- For the **Claude plugin**: edit files in `.claude/skills/autoresearch/` and `.claude/commands/autoresearch/`. The `claude-plugin/` directory is a **derived distribution** — the release script syncs from `.claude/` into `claude-plugin/` automatically. Do not edit `claude-plugin/` directly.
- For the **Copilot plugin**: `copilot-plugin/` is both the dev source and the distribution. Edit it directly.

## What to Edit and When

When editing behavior, **update the file in BOTH plugins** (or make the change in `claude-plugin/` and copy to `copilot-plugin/`):

| You want to… | Edit in claude-plugin/ | Edit in copilot-plugin/ |
|---|---|---|
| Change the core loop (phases, rules, git memory) | `references/autonomous-loop-protocol.md` | Same |
| Change the planning wizard | `references/plan-workflow.md` | Same |
| Change Copilot CLI plan/autopilot mode wiring | n/a | `references/plan-workflow.md` Phase 7 + `autonomous-loop-protocol.md` Launch Gate |
| Change security audit behavior | `references/security-workflow.md` | `copilot-plugin/` directly (copilot-unique) |
| Change shipping checklist or ship types | `references/ship-workflow.md` | Same |
| Change debug investigation techniques | `references/debug-workflow.md` | Same |
| Change how errors are fixed | `references/fix-workflow.md` | Same |
| Change scenario dimensions or domains | `references/scenario-workflow.md` | Same |
| Change prediction personas or confidence model | `references/predict-workflow.md` | Same |
| Change documentation generation behavior | `references/learn-workflow.md` | Same |
| Change TSV log format or summary output | `references/results-logging.md` | Same |
| Add a new sub-command | Create `commands/autoresearch/<name>.md` + reference file + SKILL.md routing | Mirror in copilot-plugin/ |
| Bump version | Use `./scripts/release.sh` — do not hand-edit version numbers | Handled automatically |
| Update user-facing docs | `guide/` — one file per command | |

**When adding a new sub-command**, update ALL of these:
1. `.claude/skills/autoresearch/references/<name>-workflow.md` — full protocol
2. `.claude/commands/autoresearch/<name>.md` — thin registration wrapper
3. `.claude/skills/autoresearch/SKILL.md` — subcommands table + routing + setup gate table
4. `copilot-plugin/` — mirror all three of the above
5. `README.md` — commands table, Quick Decision Guide, dedicated section, repo structure, FAQ
6. `guide/autoresearch-<name>.md` — user-facing guide
7. `guide/chains-and-combinations.md`, `guide/examples-by-domain.md`, `guide/advanced-patterns.md`
8. `CONTRIBUTING.md` — repo structure tree, "What Each File Does" table
9. `COMPARISON.md` — subcommand count + feature table

## Key Conventions

**Commit messages** use [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` — new feature or sub-command
- `fix:` — bug fix in existing behavior
- `docs:` — documentation-only changes
- `refactor:` — restructuring without behavior change
- `chore:` — maintenance (dependency bumps, CI)

**Sub-command registration files** (e.g., `commands/autoresearch/plan.md`) are thin wrappers — they load `SKILL.md` and the relevant reference file, then execute. All substantive logic lives in `SKILL.md` or a reference file.

**Interactive Setup Gate:** Every command must collect full context via `AskUserQuestion` batches before executing. This is enforced in `SKILL.md` — do not bypass it when adding new commands.

**Copilot CLI Mode Integration:** The `copilot-plugin/` uses `exit_plan_mode` at two points:
1. `plan-workflow.md` Phase 7 — presents the autoresearch config as a plan, `autopilot` recommended
2. `autonomous-loop-protocol.md` Launch Gate — transitions to autopilot before the loop starts

**Shared vs. copilot-unique reference files:** 8 reference files are intended to stay identical between both plugins, but they are **not** auto-synced by the release script. When you change a shared reference file, update `claude-plugin/` and mirror the same change into `copilot-plugin/`. 3 files are copilot-unique and must be edited directly in `copilot-plugin/`:

| File | Status | Notes |
|------|--------|-------|
| `autonomous-loop-protocol.md` | ❌ Copilot-unique | Has Copilot CLI Launch Gate |
| `plan-workflow.md` | ❌ Copilot-unique | Has `exit_plan_mode` at Phase 7 |
| `security-workflow.md` | ❌ Copilot-unique | Has Copilot-specific differences |
| All other `references/*.md` | ✅ Shared | Keep `claude-plugin/` and `copilot-plugin/` copies identical; copy changes manually |

**Mechanical metrics only:** The loop only accepts metrics extractable as a float via a shell command (`grep`, `awk`, `jq`). Subjective assessments are not valid metrics. This constraint applies to all sub-commands that produce a measurable output.

**Git as loop memory:** The autonomous loop reads `git log --oneline -20` and `git diff HEAD~1` at the start of every iteration. Commits use the `experiment:` prefix. Discarded iterations are reverted with `git reset --hard HEAD~1`.

**TSV logging:** Results are appended to `autoresearch-results.tsv` in the user's project (not this repo). Format: `iteration | commit | metric | delta | guard_status | result_status | description`.
