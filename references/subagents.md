# Delegating to Claude Code Subagents

The root session is the senior engineer. Subagents are how it buys parallelism, context isolation, and independent verification — not how it avoids thinking.

This document covers *when* to delegate, *what* to put in an assignment, and *how* to accept the result. `model-routing.md` covers the mechanics of model, effort, permissions, tools, and depth.

## What a subagent actually gives you

Understanding the mechanism prevents most delegation mistakes.

A subagent starts with **a fresh context window**. It sees your prompt and nothing else — not your conversation, not your files, not what the user said three turns ago. It works, then returns **one final message**; its tool calls never enter your context.

That produces three genuine advantages:

1. **Context isolation.** Reading 40 files to answer one question costs the subagent's context, not yours.
2. **Parallelism.** Independent subtasks run concurrently.
3. **Independent judgment.** A reviewer that never saw the implementer's reasoning cannot inherit the implementer's blind spot.

And two costs that are easy to underestimate:

1. **Everything it needs must be in the prompt.** A vague assignment produces vague work, and you will not see the wrong turn — only the confident summary at the end.
2. **You cannot see how it got there.** The final message is all you get, so the assignment must demand checkable evidence.

Delegate when you want one of the advantages. Do not delegate a task you could finish in two tool calls; the round trip costs more than the work.

## The roles

| Role | Model | Effort | Mode | Tools | Use it for |
| --- | --- | --- | --- | --- | --- |
| `read-only-explorer` | haiku | none | plan | Read, Grep, Glob | Mapping call paths, finding every call site, learning the local conventions before you design. |
| `docs-researcher` | haiku | none | plan | Read, Grep, Glob, WebFetch, WebSearch | Verifying external library, API, or platform behavior against the version actually installed. |
| `test-triager` | sonnet | high | default | Read, Grep, Glob, Bash, Edit | Reproducing a failure and finding its root cause with proof. Runs suites; plan-mode roles cannot. |
| `isolated-worker` | sonnet | high | default | Read, Grep, Glob, Edit, Write, Bash | Implementing a bounded change whose design is already settled. |
| `senior-reviewer` | sonnet | high | plan | Read, Grep, Glob, Bash | Reviewing a real artifact for defects, regressions, and risk before acceptance. |
| `local-orchestrator` | sonnet | high | default | Agent + read/write/web | One slice that genuinely fans out into independent parallel parts. |

Each role has a fixed route: the two lookup roles run on `haiku` (which does not support `effort`), and the four judgment roles run on `sonnet` at `effort: high`. The model is pinned in the definition and also passed on the call. Every leaf role lists `disallowedTools: Agent`, which is what actually prevents a third layer of nesting. `model-routing.md` explains the split and what can override it.

Definitions live in `agents/` and install to the Claude Code home agents directory. A repository can override or add roles under `.claude/agents/`.

## When to delegate, and to whom

| Situation | Route |
| --- | --- |
| "How does this area work? Where would this change go?" | `read-only-explorer` |
| "Find every place that calls / reads / emits X." | `read-only-explorer` |
| "Does this library actually behave that way in the version we use?" | `docs-researcher` |
| "CI is red and I don't know why." | `test-triager` |
| "This test fails intermittently." | `test-triager` |
| "Make this specific, already-designed change." | `isolated-worker` |
| "Is this diff safe to accept?" | `senior-reviewer` |
| "Audit these 15 files independently, then consolidate." | `local-orchestrator` |
| "Design this system." | Nobody — that is the root's job. |

For a repository task, prefer delegating at least one bounded piece of execution when subagents are available: exploration, review, triage, research, or the implementation itself. The root stays accountable for framing, integration, validation, and the final answer.

Direct root execution is the right call when subagents are unavailable, the user asked you not to delegate, the action requires authority that must stay with the root, or the task is small enough that delegation costs more than it saves. Say which applies rather than delegating for form's sake.

## Writing an assignment that works

The subagent sees only this. Write it as if for a competent engineer who has never seen the repository.

```text
Goal:
Find where checkout tax is calculated and identify the smallest safe insertion
point for a per-customer exemption flag.

Context:
We are adding tax exemption for B2B customers. The customer record already has
an `accountType` field. No decision has been made about where exemption lives.

Scope:
Inspect the checkout, cart, customer, and tax-calculation code paths.

Non-goals:
Do not edit anything. Do not propose a new tax engine. Do not evaluate whether
exemption is the right feature.

Evidence required:
File paths, function names, the call chain from checkout entry to tax
computation, the tests that cover it, and any existing exemption-like concept.

Acceptance condition:
I can open each path you name and see the symbol you claim is there.

Stop and report if:
The tax logic turns out to live behind a third-party service, or the call chain
depends on runtime configuration you cannot resolve by reading.
```

Compare with what not to send:

```text
Look into the tax stuff and figure out what to do.
```

The second one will come back with something confident and probably wrong, and you will not know which.

### The elements worth including

- **Goal** — one outcome, stated so you could verify it.
- **Context** — the request, the constraint, the current state. Only what bears on the task.
- **Scope and non-goals** — where to look, and what to leave alone. Non-goals prevent the most common failure, which is scope drift.
- **Evidence required** — name the artifacts: paths, symbols, command output, reproduction steps, citations.
- **Acceptance condition** — how you will decide the result is good.
- **Stop conditions** — the situations where stopping beats continuing.
- **Write ownership** — for any subagent that edits, the exact files it owns. Concurrent writers must never share a file.
- **Workspace** — the current one, unless the root has issued a worktree permit.
- **Model** — the role's model, explicit on the call: `haiku` for a lookup role, `sonnet` for a judgment role. The role's frontmatter supplies its effort; there is no per-call effort parameter, so use the bundled role rather than a built-in agent type.

Keep the payload small. Send paths and accepted results, not history, transcripts, or logs.

## Running several at once

Independent work runs concurrently. Dispatch multiple subagents in a single message and they run in parallel.

Sequence them only for a real dependency: the second genuinely cannot start without the first one's accepted output. Ordering that merely reflects how you listed the tasks is not a dependency and costs you the parallelism.

Before running writers in parallel, check that their file ownership is disjoint. When it is not, serialize them. A separate worktree is not the fix for overlapping writes — it converts a merge conflict into a harder merge conflict later.

Claude Code enforces a concurrent-subagent limit (20 by default) and fails a spawn beyond it. That is backpressure: let running work finish rather than queuing speculative work.

## Nesting

Claude Code allows nesting up to three layers below the main conversation by default. This playbook uses two:

```text
layer 0   root session
layer 1   direct worker, or local-orchestrator
layer 2   leaves dispatched by local-orchestrator — cannot spawn
```

`local-orchestrator` may dispatch immediately; there is no flag to verify first. The cap is enforced by the leaf definitions carrying `disallowedTools: Agent`, optionally reinforced by setting `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` to `2`. See `model-routing.md` for detail.

Use `local-orchestrator` sparingly. It earns its layer only when a slice genuinely fans out into independent parts whose intermediate output you do not want. When one worker can do the slice, dispatch that worker directly.

## Accepting the work

A returned result is a claim until you check it.

Verify:

- The acceptance condition is met, by evidence rather than assertion.
- Named paths and symbols exist and say what the result says they say. Spot-check at least the load-bearing ones.
- Nothing outside the assigned scope changed.
- Validation ran, or its absence is stated with a reason.
- Any edits are minimal and traceable to the assignment.
- The final diff — read it yourself.

When two subagents disagree, resolve it with primary evidence: the code, the tests, the schema, the logs, the runtime behavior. Do not average their conclusions or prefer the more confident one.

When a subagent fails, one retry with a sharper assignment is reasonable. A second identical failure is information — report the blocker rather than retrying again. A retry or a replacement stays on the role's route; do not rescue a failing assignment by escalating to `opus` or `fable` or by raising effort, and do not accept a substituted model as if it were the role's.

Never accept a conclusion solely because it sounds confident.

## Worktrees are not delegation units

Start in the current workspace. The auxiliary-worktree budget starts at zero and is separate from anything to do with subagents. Read-only subagents and disjoint writers share the workspace safely.

Only the root may authorize `isolation: worktree` or create an auxiliary checkout, and only after recording the required base ref — an isolated subagent branches from the repository default branch rather than the current `HEAD` unless `worktree.baseRef` says otherwise. Descendants use their assigned workspace and report isolation needs upward. See `worktrees.md`.

## Independent sessions are not subagents

A separate Claude Code session has its own history, branch, worktree, and ownership. You cannot dispatch it, and its summary is not evidence.

When independent sessions are working on related areas, use the `multi-session-coordination` skill and `multi-session-coordination.md` before adding more parallel work. More subagents will not resolve an ownership conflict between sessions.
