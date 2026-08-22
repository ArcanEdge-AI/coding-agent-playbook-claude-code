# Routing Subagents: Model, Effort, Permissions, Tools, and Depth

This is the reference for choosing *how* to run a subagent. The companion document `subagents.md` covers *when* and *what* to delegate.

The short version:

> Pick the role that matches the work. Pass an explicit `model`. Keep the child's permissions and tools no broader than your own. Verify the result before you use it.

Everything below is detail on those four sentences.

---

## How Claude Code actually resolves a subagent's model

This matters because several mechanisms compete, and the losing ones are silent.

Precedence, strongest first:

| Level | Source | Notes |
| --- | --- | --- |
| 1 | `CLAUDE_CODE_SUBAGENT_MODEL` environment variable | Overrides **everything**, including a per-invocation `model`. If set, every subagent runs on that model regardless of what you pass. |
| 2 | Per-invocation `model` on the `Agent` call | What this playbook uses. Set it on every dispatch. |
| 3 | The agent definition's `model` frontmatter | The fallback when no model is passed. |
| 4 | `inherit` / omitted | Runs on the main conversation's model. |

Two consequences worth internalizing:

- **Passing `model` explicitly is not a guarantee.** `CLAUDE_CODE_SUBAGENT_MODEL` silently outranks it, and organization model allowlists may substitute a different model. If you need certainty about what actually ran, check rather than assume.
- **Every bundled definition pins `model: haiku`** so that an omitted-model dispatch fails *closed* — cheap and weak — instead of silently running everything on the main session's model. The frontmatter is a safety net, not the routing decision.

## Model tiers

```text
opus    strongest
sonnet
haiku    cheapest
```

Choose the cheapest tier that will reliably complete the subtask, and keep the child at or below the tier the main session is running. Delegating deeper never *requires* stepping down a tier — an equal-tier child is fine when the work needs it.

Record the model the user actually selected for the main session before you delegate. Do not assume it is Opus because the account has Opus; a Haiku session delegating Opus children is the failure this rule exists to prevent.

| Main session | Normal children | Notes |
| --- | --- | --- |
| Opus | Sonnet for substantial work, Haiku for cheap objective work | An Opus child should be exceptional and worth naming a reason for. |
| Sonnet | Sonnet or Haiku | |
| Haiku | Haiku | |

`fable` and full model IDs exist and are valid values for `model`. This playbook does not rank them; if you use one, you own verifying it is within the main session's tier.

If a requested model is unavailable, blocked by an allowlist, or you cannot determine what actually ran: do not silently accept a substitute. Either re-dispatch at a model you can verify, keep the work in the calling session, or report the limitation.

## Effort

`effort` is set in the agent definition's frontmatter and takes values `low`, `medium`, `high`, `xhigh`, `max` (availability depends on the model). Claude Code does not expose an effort argument on the `Agent` call, so **the way you choose effort is by choosing the role definition.**

Per the subagent frontmatter contract, a definition's `effort` *overrides* the session effort level. That is deliberate and it is why the roles are pinned:

> **Effort is a property of the role, not a ceiling inherited from the caller.**

A main session running at `low` effort can still dispatch `senior-reviewer` at `high`. That is the point of a review role — the review deserves more thought than the errand that triggered it. Do not refuse to delegate a role because its fixed effort is higher than the current session's effort setting; that reading makes the review and orchestration roles unreachable from ordinary sessions and is not how the field works.

What you *should* do is pick the role whose effort matches the work:

| Effort | Roles | Fits |
| --- | --- | --- |
| `low` | `read-only-explorer`, `docs-researcher` | Objective lookup with a checkable answer. |
| `medium` | `isolated-worker`, `test-triager` | Bounded implementation, diagnosis with a search space. |
| `high` | `senior-reviewer`, `local-orchestrator` | Judgment, risk assessment, coordination. |

## Permission modes

A permission mode is a capability contract, not a number on a scale.

| Mode | Used by | Behavior |
| --- | --- | --- |
| `plan` | `read-only-explorer`, `docs-researcher`, `senior-reviewer` | Read-only. Edits are blocked. Shell commands outside the built-in read-only set are reviewed by the auto-mode classifier or prompt for approval. |
| `default` | `test-triager`, `isolated-worker`, `local-orchestrator` | Normal approval flow. Edits are possible; prompts still apply. |

The plan-mode detail has a practical consequence people get wrong: **a plan-mode subagent cannot reliably run a test suite, linter, type checker, or build.** Those commands sit outside the read-only set, so they are classifier-reviewed or they prompt — and a prompt inside a subagent can stall or be refused rather than quietly succeeding.

So: `git diff`, `git log`, `git blame`, `git show`, and file reads are dependable in plan mode. `npm test`, `pytest`, `eslint`, `tsc`, and `make` are not. When a review needs a suite executed, route that to `test-triager`, which runs in `default` mode. This is exactly why `senior-reviewer` is told to identify the command that would settle a finding rather than run it.

Do not use `acceptEdits`, `auto`, `dontAsk`, or `bypassPermissions` in a bundled definition without a maintainer-approved use case and a written risk note.

Note that a subagent's permission mode does not always survive the parent session's own mode. If you cannot confirm the child ran under the mode you intended, report that rather than claiming the boundary held.

## Tools

`tools` is an allowlist. When present, the subagent gets exactly that list. `disallowedTools` subtracts from whatever the agent would otherwise have, and it wins.

The rule that matters: **a child's tools must be a subset of the caller's.** A subagent that can do more than the thing that dispatched it is a boundary failure, whatever the prompt says.

Two tools are handled specially in this playbook:

- **`Agent`** — only `local-orchestrator` has it. Every leaf role omits it from `tools` *and* lists it in `disallowedTools`, which is the mechanism the Claude Code docs name for keeping a subagent from spawning. Belt and braces, because prompt text alone does not prevent a spawn.
- **`EnterWorktree` / `ExitWorktree`** — no bundled role has these. Worktree lifecycle belongs to the root session. `local-orchestrator` lists them in `disallowedTools` because its broad tool ceiling would otherwise inherit them.

## Nesting depth

**Claude Code allows nested subagents by default — up to three layers below the main conversation.** At the depth limit, Claude Code withholds the `Agent` tool from subagents so the deepest layer does its own work and returns a summary.

This playbook uses two layers, not three:

```text
layer 0   root session (main conversation)   — owns the task and the final answer
layer 1   direct worker, or local-orchestrator
layer 2   leaf subagents dispatched by local-orchestrator — must not spawn
```

Getting this right in your head matters, because the earlier version of this document had it backwards:

- Nesting is **on** by default. There is no capability flag to verify before a `local-orchestrator` may dispatch, and nothing to wait for.
- `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=2` is a **tightening** of the default from 3 to 2, not an enablement. Setting `1` turns nesting off entirely.
- Because the default is 3, the runtime by itself permits exactly the third layer this playbook forbids. The thing that actually enforces the cap is the leaf definitions carrying `disallowedTools: Agent`.

Recommended settings entry for an operator who wants the cap enforced at runtime as well:

```json
{
  "env": {
    "CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH": "2"
  }
}
```

That is optional hardening. Do not change it from inside a task without authorization, and do not treat its absence as a reason to refuse to delegate.

Historical note, since it explains the old confusion: in Claude Code v2.1.217 through v2.1.218 the default was `1`, so a subagent could not spawn unless the limit was raised. v2.1.219 raised the default to `3`.

## Two runtime behaviors that change the shape of delegation

**Agent teams.** In an interactive session with agent teams enabled, a subagent spawned from the main conversation *with a `name`* launches as a teammate rather than a plain subagent, and runs in the main session's working directory. An `isolation` value in the definition's frontmatter does not prevent this. If your ownership or isolation reasoning depends on a child being a conventional subagent, verify which one you actually got.

**Background subagents.** A subagent running in the background keeps only a fixed subset of built-in tools; others are stripped whether inherited or explicitly listed. The same definition can therefore resolve to different tools in the foreground and the background. Do not assume a background dispatch has the tools its `tools` line names.

## Worktree isolation

Shared execution is the default and the auxiliary-worktree budget starts at zero. No bundled agent sets `isolation: worktree`.

The reason is specific and worth stating plainly: **a subagent with `isolation: worktree` gets a worktree branched by default from your repository's default branch, not from the parent session's `HEAD`.** An isolated worker can therefore start without the changes the current session just made, and produce work against the wrong base. The `worktree.baseRef` setting controls this — `"head"` branches from the current `HEAD` instead.

So isolation is a root decision, made with the base ref recorded and verified. `isolation` can also be passed on an `Agent` call directly, which is exactly why descendants are told never to do that. See `worktrees.md` for the full lifecycle.

## What to record before dispatching

Not a form to fill in — the set of things that should be true and stated somewhere:

```text
Role and subagent_type:
Explicit model (and the main session's model, for comparison):
Role's fixed effort:
Permission mode and tool boundary (and proof both are ⊆ yours):
Goal, stated as a verifiable outcome:
Context, scope, and non-goals:
Read scope, or exact write ownership if the child edits:
Workspace (and worktree permit, if an auxiliary is genuinely in play):
Acceptance condition and required evidence:
Stop conditions:
```

## Before you accept the result

- The stated acceptance condition is met, with evidence you can check rather than a confident summary.
- Claimed file paths and symbols exist and say what the result claims they say.
- The child stayed inside its scope; no unrelated files changed.
- No unexplained model substitution occurred.
- Any edits are minimal and traceable to the assignment.
- Validation was actually run, or its absence is stated with a reason.
- For anything security-, migration-, concurrency-, or contract-related, the judgment came back to you rather than being made by the child.
- You have looked at the final diff yourself.

Never accept a subagent's conclusion because it sounds confident. Confidence is the cheapest thing a model produces.

## What never gets delegated

The decision stays with the root session, even when a subagent gathers the evidence:

- architecture and system design
- security, access control, authentication, authorization, privacy
- payments and billing
- destructive operations
- data migrations and persisted-schema strategy
- concurrency, locking, queues, caching, background jobs
- public API compatibility
- release and production-affecting configuration
- large or high-impact refactors
- final acceptance
