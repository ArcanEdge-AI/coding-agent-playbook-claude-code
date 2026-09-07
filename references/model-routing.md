# Routing Subagents: Model, Effort, Permissions, Tools, and Depth

This is the reference for choosing *how* to run a subagent. The companion document `subagents.md` covers *when* and *what* to delegate.

The short version:

> Dispatch a bundled role. Pass that role's model on the call. The role's frontmatter supplies its effort. Keep the child's permissions and tools no broader than your own. Verify the result before you use it.

Everything below is detail on those five sentences.

---

## The fixed route per role

| Role | `model` | `effort` | Why |
| --- | --- | --- | --- |
| `read-only-explorer` | `haiku` | none | Returns paths and symbols the root opens and checks. Cheapest model is enough, and Haiku does not support `effort`. |
| `docs-researcher` | `haiku` | none | Returns quoted, cited facts the root can follow. Same reasoning. |
| `test-triager` | `sonnet` | `high` | Diagnosis with a search space; needs judgment about causation. |
| `isolated-worker` | `sonnet` | `high` | Writes code that has to fit the codebase and pass checks. |
| `senior-reviewer` | `sonnet` | `high` | Judgment and risk assessment; the role that catches what the implementer missed. |
| `local-orchestrator` | `sonnet` | `high` | Coordinates leaves and consolidates without losing findings. |

The route belongs to the role. It does not vary with the main session's model, with nesting depth, or across a retry or replacement: the user picks the root model, and the supporting routes are independent of that choice in both directions.

Why the lines fall where they do:

- **Haiku for lookup.** The two read-only roles produce evidence the root verifies directly, so the model's job is to search well and report honestly, not to judge. Haiku is the least expensive model in the lineup. It does not support the `effort` field, so the two definitions set none; Claude Code would ignore it.
- **Sonnet at `high` for judgment.** Review, diagnosis, implementation, and coordination are where a weak model produces confident wrong answers that cost more to catch than the tokens saved. `high` is Anthropic's recommended default for Sonnet and pins the role above a lower session effort.
- **Not `xhigh` or `max`.** Those levels remove the ceiling on how much a subagent thinks per turn. On delegated work that the root verifies anyway, that spend buys little and consumes usage quickly, especially on a subscription plan. If a repository has measured that a specific role needs more, that is a repository-level decision to record in its `CLAUDE.md`, not something to vary per dispatch.
- **Not Opus or Fable.** They belong to the root session, whose judgment must be strongest. Delegated work never needs them when the root verifies.

Both the pricing and the effort-support facts were checked against Anthropic's model overview and effort documentation in September 2026. Re-verify them before relying on a specific ratio; both change with each model generation.

## How Claude Code actually resolves a subagent's model

This matters because several mechanisms compete, and the losing ones are silent.

Precedence, strongest first (Claude Code v2.1.251 and later):

| Level | Source | Notes |
| --- | --- | --- |
| 1 | Per-invocation `model` on the `Agent` call | What this playbook passes on every dispatch. Also applies when the subagent is resumed or sent a follow-up. |
| 2 | The agent definition's `model` frontmatter | The profile default. `inherit` here selects the main conversation's model. |
| 3 | `CLAUDE_CODE_SUBAGENT_MODEL` environment variable | Only reached when neither the call nor the definition names a model — built-in agent types such as Explore and Plan, for example. |
| 4 | The main conversation's model | The fallback when nothing else applies. |

Two things reorder this, and both are outside the task's control:

- **`CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1`.** While it is set, Claude Code ignores the `model` field of every subagent definition and does not let Claude pass a model on the call; every subagent runs on `CLAUDE_CODE_SUBAGENT_MODEL` if that is set, otherwise on the main conversation's model. If it is set, this playbook's per-role route cannot be honored.
- **The organization's `availableModels` allowlist.** For a blocked value, Claude Code substitutes: a family alias such as `sonnet` becomes the newest version of that family the allowlist permits, and any other blocked value falls back to the inherited model.

Before v2.1.251, `CLAUDE_CODE_SUBAGENT_MODEL` sat at the top of this order and overrode both the call and the frontmatter. Older copies of this playbook describe that behavior; it is no longer current, but an older install still behaves that way.

Consequences:

- **The frontmatter `model` is the route, not a safety net.** Earlier versions of this playbook pinned `haiku` on every role so that a forgotten model would "fail closed." That reasoning is retired: each definition now states its intended route directly, and the explicit call repeats it.
- **Passing the model on the call is still required.** It protects against a stale or locally overridden definition, and it is the only thing that survives a follow-up message to the same subagent.
- **You cannot always know what ran.** With `_FORCE` or an allowlist substitution in effect, the model that answered may not be the one the route names. If attribution matters and you cannot confirm it, say so.

## Effort

`effort` is set in the agent definition's frontmatter and accepts `low`, `medium`, `high`, `xhigh`, `max` (availability depends on the model — Sonnet supports all five, Haiku supports none). It **overrides the session effort level** while the subagent runs. A definition that omits it inherits the session's level.

Three facts follow, and they shape how you delegate:

1. **There is no effort parameter on the `Agent` call.** The only way to choose a subagent's effort is to choose a definition that pins it. That is why the four Sonnet roles carry `effort: high`, and why you dispatch bundled roles rather than built-in agent types when reasoning depth matters — a built-in type runs at whatever effort the session happens to have.
2. **Effort is a property of the role, not a ceiling inherited from the caller.** A session running at `low` or `medium` still dispatches `senior-reviewer` at `high`. Do not refuse to delegate because the role's effort is higher than yours; that reading is not how the field works.
3. **The two Haiku roles have no `effort` line on purpose.** Haiku is not in the list of models that support effort, so a value there would be ignored and would misstate what the role actually does.

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

Background subagents keep only a fixed subset of built-in tools regardless of what `tools` lists, so the same definition can resolve to different tools in the foreground and the background. Do not assume a background dispatch has everything its `tools` line names.

## Nesting depth

**Claude Code allows nested subagents by default — up to three layers below the main conversation.** At the depth limit, Claude Code withholds the `Agent` tool from subagents so the deepest layer does its own work and returns a summary.

This playbook uses two layers, not three:

```text
layer 0   root session (main conversation)   — owns the task and the final answer
layer 1   direct worker, or local-orchestrator
layer 2   leaf subagents dispatched by local-orchestrator — must not spawn
```

Getting this right in your head matters, because an earlier version of this document had it backwards:

- Nesting is **on** by default. There is no capability flag to verify before a `local-orchestrator` may dispatch, and nothing to wait for.
- `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=2` is a **tightening** of the default from 3 to 2, not an enablement. Setting `1` turns nesting off entirely.
- Because the default is 3, the runtime by itself permits exactly the third layer this playbook forbids. The thing that actually enforces the cap is the leaf definitions carrying `disallowedTools: Agent`.

A nested dispatch uses the same per-role route as a direct one: `local-orchestrator` passes each leaf its role's model, and the leaf's frontmatter supplies its effort. Depth controls authority and spawning; it never changes the route.

## Recommended operator settings

A user-settings entry for an operator who wants the cap, the fallback model, and the teammate behavior pinned at runtime as well:

```json
{
  "env": {
    "CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH": "2",
    "CLAUDE_CODE_SUBAGENT_MODEL": "haiku",
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "0"
  }
}
```

What each line does:

- `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH: "2"` tightens the runtime nesting default from 3 to 2.
- `CLAUDE_CODE_SUBAGENT_MODEL: "haiku"` is the fallback for any subagent that names no model — built-in agent types such as Explore and Plan. On Claude Code v2.1.251 and later it sits below the frontmatter and the per-call model, so the six bundled roles are unaffected. **On an older install the variable outranks both**, which would push the four Sonnet roles onto Haiku; on such an install, omit this line or update Claude Code first. Do **not** add `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`; it would block the per-call model for no benefit.
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "0"` keeps a named subagent from launching as a teammate, which would make it inherit the lead's effort instead of the definition's. Teams are off by default; this pins them off against a stray shell export. Project, `--settings`, and managed settings still win over the user file.

All three are optional hardening. Do not change them from inside a task without authorization, and do not treat their absence as a reason to refuse to delegate.

## Two runtime behaviors that change the shape of delegation

**Agent teams.** Agent teams are experimental and off by default; an operator enables them with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. While they are on, in an interactive session, a subagent spawned from the main conversation *with a `name`* launches as a teammate rather than a plain subagent, runs in the main session's working directory, and inherits the lead's effort level rather than the definition's. A teammate's model still follows the definition when the spawn prompt names none. An `isolation` value in the definition's frontmatter does not prevent this. If your ownership, isolation, or effort reasoning depends on a child being a conventional subagent, verify which one you actually got.

**Background subagents.** A subagent running in the background keeps only a fixed subset of built-in tools; others are stripped whether inherited or explicitly listed. Do not assume a background dispatch has the tools its `tools` line names.

## Worktree isolation

Shared execution is the default and the auxiliary-worktree budget starts at zero. No bundled agent sets `isolation: worktree`.

The reason is specific and worth stating plainly: **a subagent with `isolation: worktree` gets a worktree branched by default from your repository's default branch, not from the parent session's `HEAD`.** An isolated worker can therefore start without the changes the current session just made, and produce work against the wrong base. The `worktree.baseRef` setting controls this — `"head"` branches from the current `HEAD` instead.

So isolation is a root decision, made with the base ref recorded and verified. `isolation` can also be passed on an `Agent` call directly, which is exactly why descendants are told never to do that. See `worktrees.md` for the full lifecycle.

## What to record before dispatching

Not a form to fill in — the set of things that should be true and stated somewhere:

```text
Role and subagent_type:
Model on the call: [haiku for a lookup role, sonnet for a judgment role]
Role's fixed effort: [none for Haiku roles, high for Sonnet roles]
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
- The dispatch named a bundled role and passed that role's model; nothing indicates a forced or allowlist-substituted model.
- Any edits are minimal and traceable to the assignment, and did not add machinery the assignment did not call for.
- Validation was actually run, or its absence is stated with a reason.
- For anything security-, migration-, concurrency-, or contract-related, the judgment came back to you rather than being made by the child.
- You have looked at the final diff yourself.

Never accept a subagent's conclusion because it sounds confident. Confidence is the cheapest thing a model produces.

## When the route cannot be honored

A subagent must stop and report, and the root must not paper over it, when:

- the task exceeds its bounded assignment or requires a decision reserved for the root
- the conclusion cannot be independently verified
- the work becomes security-sensitive, destructive, or production-impacting
- the route cannot be honored — the role's model is blocked by an allowlist, `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` pins something else, or the effective model cannot be determined

In that last case the options are to report the constraint and keep the work in the root session, or to re-dispatch only in a way whose effective model you can verify. Do not quietly accept a substituted answer as if it came from the role's model, do not raise a role to `xhigh` or `max`, and do not escalate a failing child to `opus` or `fable`; a bounded task a role cannot finish on its route needs a sharper assignment or the root's own judgment, not a bigger model.

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
