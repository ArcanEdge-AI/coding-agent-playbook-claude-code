---
name: subagent-orchestration
description: Use when planning how to delegate a coding task to Claude Code subagents — deciding whether to delegate at all, which role fits, how to write an assignment that comes back usable, how to run several safely in parallel, and how to verify results before accepting them. Use multi-session-coordination instead when other independent Claude Code sessions already own related work.
---

# Subagent Orchestration

You own the task. Subagents buy you three things — context isolation, parallelism, and independent judgment — and cost you visibility into how the work was done. Delegate when you want one of the three, and write the assignment so the missing visibility does not matter.

Full detail: `references/subagents.md` and `references/model-routing.md`.

## 1. Decide whether to delegate

Delegate when at least one is true:

- **Context isolation** — answering needs many files read, and you want the answer without the reading.
- **Parallelism** — several genuinely independent pieces can run at once.
- **Independent judgment** — a reviewer who never saw the implementer's reasoning will catch what the implementer cannot.

Do it yourself when the task is two tool calls, when it is one continuous design judgment, or when explaining the assignment would take longer than doing the work.

For a repository task with subagents available, prefer delegating at least one bounded piece — exploration, research, triage, review, or implementation. Keep framing, integration, validation, and the final answer.

## 2. Pick the role

| The question | Role |
| --- | --- |
| How does this work? Where does the change go? Where is every call site? | `read-only-explorer` |
| Does this library really behave that way in our version? | `docs-researcher` |
| Why is this failing? | `test-triager` |
| Make this specific, already-designed change. | `isolated-worker` |
| Is this diff safe to accept? | `senior-reviewer` |
| Audit these many independent items, then consolidate. | `local-orchestrator` |
| Design this. | You. Not delegable. |

One consequence of permission modes worth remembering: `senior-reviewer` runs in `plan` mode and **cannot reliably run tests, linters, type checkers, or builds** — those commands prompt or go to the classifier. When a review needs a suite executed, that is `test-triager`, which runs in `default`.

## 3. Route the model

Each role has a fixed route. `read-only-explorer` and `docs-researcher` run on `haiku`; `senior-reviewer`, `test-triager`, `isolated-worker`, and `local-orchestrator` run on `sonnet` at `effort: high`. Pass the role's model on every dispatch; the bundled role's frontmatter supplies its effort. The route is the same for a leaf a `local-orchestrator` dispatches, for a retry, and for a replacement, and it does not change with the main session's model.

Why: lookup roles return evidence you check directly, so the cheapest model is enough, and Haiku does not support `effort` anyway. Judgment roles are where a weak model produces confident wrong answers. `high` is Sonnet's recommended default; `xhigh` and `max` are not used because they remove the per-turn thinking ceiling and burn usage on work you verify regardless. Opus and Fable stay with the root session.

Effort cannot be passed on the `Agent` call — only a definition pins it, and it overrides session effort. So dispatch bundled roles, not built-in agent types, when reasoning depth matters; a `low`-effort session still gets `senior-reviewer` at `high`.

Two things can silently change what actually runs: `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` ignores every definition's model and blocks the per-call model (and on Claude Code before v2.1.251, a plain `CLAUDE_CODE_SUBAGENT_MODEL` already outranked the call), and an organization allowlist can substitute. If either is in effect or you cannot tell what ran, report it and keep the work yourself rather than accepting a substituted model as the role's. Never route a child to `opus` or `fable`, and never raise effort, to rescue a failing assignment.

## 4. Write the assignment

The subagent sees only this — not your conversation, not the user's request, not the files you have open.

```text
Goal:
[One outcome, stated so you could verify it.]

Context:
[The request, the constraint, the current state. Only what bears on this.]

Scope:
[Where to look or what to change.]

Non-goals:
[What to leave alone. This prevents the most common failure — scope drift.]

Write ownership:               (only for subagents that edit)
[Exact files this subagent owns. No concurrent sibling may own them too.]

Workspace:
[The current workspace. Do not create or request a worktree.]

Evidence required:
[Paths, symbols, command output, reproduction steps, citations.]

Acceptance condition:
[How you will decide the result is good.]

Stop and report if:
[The situations where stopping beats continuing.]
```

Keep the payload small: paths and accepted results, never transcripts or long logs.

## 5. Run them in parallel when they are independent

Dispatch independent subagents in one message so they run concurrently.

Sequence only for a real dependency — the second genuinely cannot start without the first one's accepted output. Ordering that just reflects your list is not a dependency, and enforcing it costs you the parallelism.

Before parallel writers: confirm file ownership is disjoint. If it is not, serialize them. A separate worktree does not fix overlapping writes; it defers the conflict.

Claude Code caps concurrent subagents (20 by default) and fails spawns past it. Treat that as backpressure — let running work finish instead of queuing speculative work.

## 6. Nesting, if you use `local-orchestrator`

Claude Code allows nesting three layers below the main conversation **by default**. This playbook uses two:

```text
layer 0   you
layer 1   direct worker, or local-orchestrator
layer 2   leaves — cannot spawn
```

There is no flag to verify before a `local-orchestrator` can dispatch; nesting is already on. The cap holds because every leaf role carries `disallowedTools: Agent`. An operator can additionally set `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` to `2`; that is hardening, not a precondition, and you do not change it from inside a task.

Use `local-orchestrator` only for a slice with genuine fan-out. When one worker can do the slice, dispatch that worker.

## 7. Verify before you accept

A returned result is a claim.

- Does the evidence meet the acceptance condition, or does it just sound right?
- Do the named paths and symbols exist and say what the result says? Spot-check the load-bearing ones.
- Did anything outside scope change?
- Was validation actually run, or is its absence explained?
- Did the child add machinery the assignment did not call for — an abstraction, state, configurability, or a workaround where a boundary fix was in scope?
- Have you read the final diff yourself?

When two subagents disagree, resolve it against primary evidence — code, tests, schemas, logs, runtime behavior. Do not prefer the more confident one.

One retry with a sharper assignment is reasonable. A second identical failure is information: report the blocker.

Never accept a conclusion because it sounds confident.

## 8. Keep these decisions yourself

Architecture. Security, authentication, authorization, privacy. Payments. Destructive operations. Data migrations and persisted schemas. Concurrency, locking, caching. Public API compatibility. Release and production configuration. Final acceptance.

A subagent can gather the evidence. You make the call.

## 9. Worktrees

Start in the current workspace with an auxiliary-worktree budget of zero, and expect to stay there. Only you may authorize `isolation: worktree`, and only with the base ref recorded — an isolated subagent branches from the repository default branch, not your `HEAD`, unless `worktree.baseRef` is set to `head`.

One active auxiliary needs no extra approval; two or more need the user's. Before your final response, every task-created auxiliary is either integrated and removed, or preserved with an exact blocker. See `references/worktrees.md`.

## 10. Report

State what changed or was answered, which subagents you used and what you accepted from them, what validation ran and what it produced, any workspace disposition, and anything still blocked. Lead with the outcome.
