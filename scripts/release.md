# Release Process

## Versioning Scheme

| Type | Pattern | When to use | Example |
|------|---------|-------------|---------|
| **Patch** | `v1.6.X` | Bugfixes, typos, small updates, dependency bumps | `v1.6.2` |
| **Minor** | `v1.X.0` | New features, new commands, significant changes | `v1.7.0` |
| **Major** | `vX.0.0` | Reserved for v2+ (breaking changes, full rewrites) | `v2.0.0` |

## Quick Reference

```bash
# Patch release (bugfix)
./scripts/release.sh 1.6.2 --title "Fix scenario timeout handling"

# Minor release (new feature)
./scripts/release.sh 1.7.0 --title "New Feature Name"
```

## What the Script Does

```
[1/7] Create release branch (release/X.Y.Z)
[2/7] Bump versions:
      → claude-plugin/.claude-plugin/plugin.json  (version field)
      → copilot-plugin/.claude-plugin/plugin.json (version field)
      → .claude-plugin/marketplace.json           (version fields — top-level + plugins array)
      → .claude/skills/autoresearch/SKILL.md      (version frontmatter)
      → claude-plugin/skills/autoresearch/SKILL.md
      → copilot-plugin/skills/autoresearch/SKILL.md
      → README.md                                 (version badge)
      → guide/README.md                           (version badge)
[3/7] Sync distribution files:
      → claude-plugin/: copies .claude/commands/ and .claude/skills/ (full sync)
      → copilot-plugin/: copies 8 shared reference files from claude-plugin/
        (autonomous-loop-protocol, plan-workflow, and security-workflow are
         copilot-unique — they are NOT overwritten)
[4/7] Pause for doc review:
      → Shows changelog since last tag
      → Prompts you to review README.md, guide/, CONTRIBUTING.md
      → You can edit in another terminal, then continue
[5/7] Commit all release changes
[6/7] Push branch + create PR against master
[7/7] Wait for your "merge" confirmation:
      → Merges PR
      → Tags the merge commit
      → Creates GitHub release with auto-generated notes
```

## Pre-Release Checklist

Before running the script, verify:

- [ ] All tests pass
- [ ] No uncommitted changes in working tree
- [ ] You're on the `master` branch
- [ ] `gh` CLI is authenticated
- [ ] If editing copilot-unique reference files (`autonomous-loop-protocol.md`, `plan-workflow.md`, `security-workflow.md`), edits are in `copilot-plugin/` directly
- [ ] If editing shared reference files, edits are in `.claude/skills/autoresearch/references/` (not in `copilot-plugin/` directly)

## Doc Review Guide

At step [4/7], the script pauses and shows the changelog. Review these files:

### README.md
- **Version badge** (auto-updated by script)
- **Commands table** — any new commands added?
- **Quick Decision Guide** — new use cases?
- **Repository Structure** — new files in the tree?
- **FAQ** — new questions from issues/discussions?

### guide/
- **guide/README.md** — version badge (auto-updated by script)
- **Individual command guides** — any new commands or flags?
- **guide/examples-by-domain.md** — new domain examples to add?
- **guide/chains-and-combinations.md** — new chain patterns possible?
- **guide/advanced-patterns.md** — new verify commands, MCP patterns, FAQ?

### guide/scenario/
- **guide/scenario/README.md** — scenario guide chain suggestions updated?
- **Domain-specific guides** — new scenario domains or patterns?

### CONTRIBUTING.md
- **Repository Structure** — does the tree reflect new files?
- **What Each File Does** — any new files to document?
- **Adding a New Sub-Command** — steps still accurate?
- **High-Value Contributions** — new contribution types?

### COMPARISON.md
- **Subcommand count** — does it match the current number?
- **Feature comparison table** — any new capabilities to add?

### Tips
- Edit docs in another terminal while the script is paused
- Type `skip` at the prompt to continue without doc changes
- The script stages any doc changes automatically (README.md, guide/, CONTRIBUTING.md, COMPARISON.md)

## Distribution Sync

### Claude Plugin

The `claude-plugin/` directory is the **distribution package** for Claude Code. The `.claude/` versions are the development source of truth.

**Why `claude-plugin/` and not root?** Claude Code's plugin caching downloads the `source` directory. If `source` is `"./"` (the entire repo), the cached plugin contains its own `.claude-plugin/marketplace.json`, causing Claude Code to recursively cache the plugin inside itself — hitting macOS's 1024-char path limit (`ENAMETOOLONG`). Pointing `source` to `./claude-plugin` (an isolated distribution directory without `marketplace.json`) breaks this recursion.

**Before every release**, the script syncs `claude-plugin/` from `.claude/`:
```bash
# What the claude sync step does:
cp .claude/commands/autoresearch.md claude-plugin/commands/autoresearch.md
cp .claude/commands/autoresearch/*.md claude-plugin/commands/autoresearch/
cp .claude/skills/autoresearch/SKILL.md claude-plugin/skills/autoresearch/SKILL.md
cp .claude/skills/autoresearch/references/*.md claude-plugin/skills/autoresearch/references/
```

If you add a new subcommand during development, it goes into `.claude/` first. The release script ensures `claude-plugin/` stays in sync.

### Copilot Plugin

The `copilot-plugin/` directory is **both the development source and the distribution package**. There is no separate source directory (unlike `claude-plugin/` which is derived from `.claude/`).

For local development, symlink `copilot-plugin/` into your Copilot CLI config directory:
```bash
ln -s $(pwd)/copilot-plugin/skills/autoresearch ~/.copilot/skills/autoresearch
ln -s $(pwd)/copilot-plugin/commands/autoresearch ~/.copilot/commands/autoresearch
ln -s $(pwd)/copilot-plugin/commands/autoresearch.md ~/.copilot/commands/autoresearch.md
```

**Shared vs. copilot-unique reference files:**

| File | Shared? | Notes |
|------|---------|-------|
| `core-principles.md` | ✅ Shared | Auto-synced from `claude-plugin/` at release |
| `debug-workflow.md` | ✅ Shared | Auto-synced from `claude-plugin/` at release |
| `fix-workflow.md` | ✅ Shared | Auto-synced from `claude-plugin/` at release |
| `learn-workflow.md` | ✅ Shared | Auto-synced from `claude-plugin/` at release |
| `predict-workflow.md` | ✅ Shared | Auto-synced from `claude-plugin/` at release |
| `results-logging.md` | ✅ Shared | Auto-synced from `claude-plugin/` at release |
| `scenario-workflow.md` | ✅ Shared | Auto-synced from `claude-plugin/` at release |
| `ship-workflow.md` | ✅ Shared | Auto-synced from `claude-plugin/` at release |
| `autonomous-loop-protocol.md` | ❌ Unique | Has Copilot CLI Launch Gate — edit in `copilot-plugin/` |
| `plan-workflow.md` | ❌ Unique | Has `exit_plan_mode` at Phase 7 — edit in `copilot-plugin/` |
| `security-workflow.md` | ❌ Unique | Copilot-specific differences — edit in `copilot-plugin/` |

**Rule:** When editing shared reference files, edit them in `.claude/skills/autoresearch/references/`. The release script propagates the change to both `claude-plugin/` and `copilot-plugin/` automatically. When editing copilot-unique files, edit them directly in `copilot-plugin/`.

## Abort and Resume

If you type `abort` at the merge prompt:
```bash
# The PR stays open. Merge later with:
gh pr merge <PR_URL> --merge --delete-branch

# Or clean up:
git checkout master && git branch -D release/X.Y.Z
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Working tree is dirty" | Commit or stash changes first |
| "Must be on master branch" | `git checkout master` |
| "gh CLI not found" | Install from https://cli.github.com |
| PR merge conflicts | Resolve on the PR, then re-run merge step manually |
| Forgot to update docs | Edit on the PR branch, push, then merge |
| "Tag already exists" | Choose a different version number |
| ENAMETOOLONG on install | Ensure `marketplace.json` has `"source": "./claude-plugin"` (not `"./"`) |
| Shared ref edit lost in copilot-plugin | Edits to shared refs must go in `.claude/`, not `copilot-plugin/` — the script overwrites them |
| Copilot-unique file accidentally overwritten | Those 3 files are not in `SHARED_REFS` — if overwritten, restore from git: `git checkout HEAD -- copilot-plugin/skills/autoresearch/references/<file>` |
