<!-- Coding Agent Playbook — Claude Code Edition. Managed file; edits are replaced on update. -->

# Delegating to Subagents

A subagent starts with a **fresh context window**, sees only the prompt you write, and returns **one final message**. Its tool calls never enter your context.

That buys context isolation, parallelism, and independent judgment. It costs you visibility into how the work was done — so everything the subagent needs must be in the prompt, and the assignment must demand checkable evidence.

For a repository task, delegate at least one bounded piece of execution when subagents are available. Keep framing, integration, validation, and the final answer yourself. Direct execution is right when subagents are unavailable, the user asked you not to delegate, the action needs authority that must stay with you, or the task is small enough that delegating costs more than it saves. Say which applies.

## The roles

- `read-only-explorer` — maps call paths, call sites, conventions, and insertion points.
- `docs-researcher` — verifies external library, API, or platform behavior against the installed version.
- `test-triager` — reproduces a failure and finds its root cause with proof. Runs suites.
- `isolated-worker` — implements a bounded change whose design is already settled.
- `senior-reviewer` — reviews a real artifact for defects and risk before acceptance.
- `local-orchestrator` — runs one slice that genuinely fans out into independent parts.

Prefer read-only subagents for exploration, review, research, and diagnosis. Before running writers in parallel, confirm their file ownership is disjoint; serialize them when it is not.

## Non-negotiables

- **Never delegate with "Look into this and fix it."** Give role, goal, context, scope, non-goals, required evidence, acceptance condition, and stop conditions — plus exact write ownership for anything that edits.
- **Pass `model` explicitly on every dispatch.** Keep the child at or below the main session's tier (`opus` > `sonnet` > `haiku`), and record what the main session actually is rather than assuming Opus. Equal tier is valid.
- **`effort` comes from the agent definition and overrides the session's effort level.** It is a property of the role, not a ceiling inherited from you — a low-effort session can still dispatch `senior-reviewer` at high effort. Choose the role whose effort fits the work.
- **Keep every child at or below its parent** in model, permissions, tools, scope, data access, and authority. A child may be narrower; never broader.
- **A returned result is a claim until you check it.** Verify the acceptance condition against evidence, spot-check that named paths and symbols exist and say what the result claims, confirm nothing outside scope changed, and read the final diff yourself. When subagents disagree, resolve it against primary evidence. One retry with a sharper assignment is reasonable; a second identical failure is information — report the blocker.
- **Never accept a conclusion because it sounds confident.** Confidence is the cheapest thing a model produces.
- **Worktrees are not delegation units.** Start in the current workspace with an auxiliary-worktree budget of zero. Only you may authorize `isolation: worktree`, and only with the base ref recorded — an isolated subagent branches from the repository default branch, not your `HEAD`, unless `worktree.baseRef` is `"head"`. Reconcile every task-created auxiliary before your final response.

For assignment templates, model and permission routing, nesting depth, and worktree lifecycle, use the `subagent-orchestration` and `worktree-lifecycle` skills.
