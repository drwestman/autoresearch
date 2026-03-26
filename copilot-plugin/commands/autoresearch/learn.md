---
name: autoresearch:learn
description: Autonomous codebase documentation engine — scout, learn, generate/update docs with validation-fix loop
argument-hint: "[goal/focus] [--mode init|update|check|summarize] [--scope <glob>] [--depth quick|standard|deep] [--file <name>] [--scan] [--topics <list>] [--no-fix] [--format markdown|html|json|rst] [--iterations N]"
---

EXECUTE IMMEDIATELY — do not deliberate, do not ask clarifying questions before reading the protocol.

## Argument Parsing (do this FIRST)

Extract these from $ARGUMENTS — the user may provide extensive context alongside flags. Ignore prose and extract ONLY flags/config:

- `--mode <mode>` or `Mode:` — init, update, check, summarize
- `--scope <glob>` or `Scope:` — limit codebase learning to specific dirs
- `--depth <level>` or `Depth:` — quick, standard, deep
- `--file <name>` — selective update targeting one doc file
- `--scan` — force fresh scout in summarize mode
- `--topics <list>` — focus summarize on specific topics
- `--no-fix` — skip validation-fix loop
- `--format <fmt>` — output format: markdown (default); html, json, rst are planned
- `Iterations:` or `--iterations N` — integer for bounded mode (CRITICAL: run exactly N iterations then stop)

If `Iterations: N` or `--iterations N` is found, set `max_iterations = N`. Track `current_iteration` starting at 0. After iteration N, print final summary and STOP.

The first non-flag token in `$ARGUMENTS` is the **goal/focus** (e.g., `"document the API layer"`). Any subsequent text is additional context. Use the goal to scope the learn workflow; pass additional context as supplementary instructions.

## Execution

1. Read the learn workflow: `.copilot/skills/autoresearch/references/learn-workflow.md`
2. If scope or goal is missing — use `AskUserQuestion` with batched questions per learn-workflow.md
3. Execute the learn workflow
4. If bounded: after each iteration, check `current_iteration < max_iterations`. If not, STOP and print summary.

Stream all output live — never run in background.
