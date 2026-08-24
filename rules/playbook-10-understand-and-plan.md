<!-- Coding Agent Playbook — Claude Code Edition. Managed file; edits are replaced on update. -->

# Understand Before Editing, Then Plan

## Understand before editing

Before implementing:

- Read the relevant files, tests, call sites, configuration, and docs.
- Check the current state of the working tree before changing it.
- Identify the smallest verifiable goal.
- Work out how the requested change fits the existing design.
- Prefer an existing pattern over a new one unless the existing pattern is clearly harmful or insufficient.
- State assumptions that materially affect behavior, API, data model, safety, persistence, performance, accessibility, or user-visible output.
- Ask when ambiguity is material. For minor implementation details, choose a reasonable option, proceed, and say what you chose.

Do not start coding from vibes. Gather enough context that the first edit is likely to be right.

## Planning

For non-trivial, ambiguous, multi-file, risky, or long-running work, keep a short working plan covering the sequence, the success criterion for each meaningful step, the validation that will prove the change, and the assumptions that matter.

Good plan steps name their verification:

```text
1. Inspect current validation flow → verify: existing tests and call sites identified.
2. Add missing invalid-input coverage → verify: test fails before the fix.
3. Implement minimal fix → verify: targeted test passes.
4. Broaden validation if blast radius warrants → verify: exact command and result.
```

For work with several delegable parts, also identify the bounded pieces, what each consumes and produces, and only the dependencies that genuinely block something else from starting. Note which chain of handoffs actually controls when the work can finish. Keep this lightweight — do not model a graph for linear work.

For substantial fan-out, several real dependencies, broad scope, layered consolidation, or separate implementation and verification paths, use the `task-graph-orchestration` skill before delegating.

Use whatever planning mechanism the environment provides. Do not assume a specific tracker, tool, MCP server, or UI feature.

Do not silently reorder, skip, merge, or expand planned work. When findings change scope, risk, order, or validation strategy, update the plan before continuing.
