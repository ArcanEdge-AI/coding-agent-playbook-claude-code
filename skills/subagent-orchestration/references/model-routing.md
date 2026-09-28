# Routing Subagents: Model, Effort, Permissions, Tools, and Depth

This is the reference for choosing *how* to run a subagent. The companion document `subagents.md` covers *when* and *what* to delegate.

The short version:

> Decide first whether a helper is worth its cost at all. If it is, dispatch a bundled role, pass on the call the approved model the work needs, and let the role's frontmatter supply its effort. Keep the child's permissions and tools no broader than your own. Verify the result before you use it.

Everything below is detail on those five sentences.

---

## Use helpers sparingly

A helper is worth dispatching only when a bounded assignment's concrete benefit — evidence independent of your own reasoning, genuinely parallel progress on separable work, or a large bounded investigation kept out of your context — outweighs what it costs: the context you write into the prompt, the latency of the round trip, the review the result needs, and the visibility you lose into how it was done. A governing instruction that requires independent assistance is the other reason. Task size, an available role, a cheap model, and a node in a plan are not reasons, and no sequence of planner, implementer, reviewer, tester, and documentation passes is ever required.

Each bundled definition has a **Role perspective** section the root can apply directly to a concrete question. That is not a dispatch: it changes nothing about the root's model, effort, permissions, or ownership, and it is self-review rather than independent verification. This document is about actual dispatches.

## Choose the model for the work

Choose each dispatch's model — including a retry, a replacement, and a leaf a `local-orchestrator` dispatches — for the work being assigned, to minimize the total cost of a correct, accepted result: input and reasoning tokens, the context repeated into the prompt, retries, correction work, coordination, and the verification the root does afterwards. The cheapest token price does not produce the cheapest completed task. Choose sufficient capability upfront; do not require a failed cheap attempt first.

| Work | Route | Why |
| --- | --- | --- |
| Narrow lookup, extraction, file mapping, log summaries — evidence the root checks directly | `haiku`; no effort level exists for Haiku | The model's job is to search well and report honestly, not to judge. Haiku is the least expensive model in the lineup, and a wrong answer is cheap to catch because the root opens the paths anyway. |
| Clear implementation, local fixes, bounded planning, straightforward review | `opus` at the definition's `effort: medium` | This is where a weak model produces confident wrong answers that cost more to catch than the tokens saved. `medium` is Anthropic's documented default for Opus 5.5, which at that level matches or exceeds Opus 5 at `high` in Anthropic's coding evaluations while spending fewer reasoning tokens. |
| Difficult debugging, coupled changes, substantial review, conflicting evidence | `opus` at `medium`, with a sharper, narrower assignment | More effort per turn is not what usually helps here; a smaller, better-specified question is. When that still is not enough, the work belongs in the next row. |
| The hardest architecture questions and complex cross-system reasoning | The root session, on the model the user selected | Not delegated. The root's judgment must be the strongest in the task, and these are the decisions Section 8 of the skill keeps with it. |

These are the approved routes. Each definition declares the default for its typical work:

| Role | Default `model` | `effort` | Typical delegated work |
| --- | --- | --- | --- |
| `read-only-explorer` | `haiku` | none | Call paths, call sites, conventions, insertion points. |
| `docs-researcher` | `haiku` | none | Cited, version-specific facts about external behavior. |
| `test-triager` | `opus` | `medium` | Reproducing a failure and proving its cause; choosing proportionate checks. |
| `isolated-worker` | `opus` | `medium` | A bounded, already-designed change that has to fit the codebase and pass checks. |
| `senior-reviewer` | `opus` | `medium` | Independent review of a real artifact. |
| `local-orchestrator` | `opus` | `medium` | One slice with genuine fan-out, consolidated without losing findings. |

The work decides the actual dispatch, and the per-call `model` is how you choose it. An Opus role asked only to extract or summarize — `test-triager` handed a log to condense, say — can be dispatched with `model: haiku`. Judgment work is never dispatched to Haiku: a review, a diagnosis, or an implementation on a lookup model is the confident-wrong-answer case the split exists to avoid. The choice never follows the main session's model, and it does not change with nesting depth.

What is deliberately not a helper route:

- **Sonnet.** Not because it is weak, but because effort lives in the definition: a per-call `sonnet` on a definition pinned to `medium` would run Sonnet below its own documented `high` default. One judgment route, on one model, keeps the effective settings honest.
- **`high`, `xhigh`, and `max` on a helper.** Opus 5.5 is priced at twice Sonnet per token; `medium` is what makes it the cheaper completed task. The higher levels remove the ceiling on how much a subagent thinks per turn and, on delegated work the root verifies anyway, that spend buys little and consumes usage quickly, especially on a subscription plan. If a repository has measured that a specific role needs more, that is a repository-level decision to record in its `CLAUDE.md`, not something to vary per dispatch.
- **Fable.** It belongs to the root session. Work that genuinely needs it is the fourth row: it stays with the root.
- **Fast mode.** It is a main-session speed setting the user controls, not a helper route. Do not toggle it from inside a task.

These are policy choices, not a measured ranking that holds for every repository. Change them through an explicit maintainer decision, not because a newer model appeared. The effort-support and default-effort facts were checked against Anthropic's Claude Code model documentation in September 2026; re-verify them before relying on a specific claim, because they change with each model generation.

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

- **`CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1`.** While it is set, Claude Code ignores the `model` field of every subagent definition and does not let Claude pass a model on the call; every subagent runs on `CLAUDE_CODE_SUBAGENT_MODEL` if that is set, otherwise on the main conversation's model. If it is set, this playbook's per-dispatch model choice cannot be honored.
- **The organization's `availableModels` allowlist.** For a blocked value, Claude Code substitutes: a family alias such as `sonnet` becomes the newest version of that family the allowlist permits, and any other blocked value falls back to the inherited model.

Before v2.1.251, `CLAUDE_CODE_SUBAGENT_MODEL` sat at the top of this order and overrode both the call and the frontmatter. Older copies of this playbook describe that behavior; it is no longer current, but an older install still behaves that way.

Consequences:

- **The frontmatter `model` is the role's default, not a safety net.** Earlier versions of this playbook pinned `haiku` on every role so that a forgotten model would "fail closed." That reasoning is retired: each definition states the default for its typical work, and the call chooses the actual model.
- **Passing the model on the call is required.** It is how the work's route is selected, it protects against a stale or locally overridden definition, and it is the only thing that survives a follow-up message to the same subagent.
- **You cannot always know what ran.** With `_FORCE` or an allowlist substitution in effect, the model that answered may not be the one the route names. If attribution matters and you cannot confirm it, say so.

## Effort

`effort` is set in the agent definition's frontmatter and accepts `low`, `medium`, `high`, `xhigh`, `max` (availability depends on the model — Opus 5.5 supports all five, Haiku supports none). It **overrides the session effort level** while the subagent runs. A definition that omits it inherits the session's level.

Three facts follow, and they shape how you delegate:

1. **There is no effort parameter on the `Agent` call.** The only way to choose a subagent's effort is to choose a definition that pins it, so effort belongs to the role while the model can be chosen per dispatch. That is why the four Opus roles carry `effort: medium`, and why you dispatch bundled roles rather than built-in agent types when reasoning depth matters — a built-in type runs at whatever effort the session happens to have. It is also why this playbook does not ship a second copy of each role at another effort level: that would be duplicated definitions, not task-based selection.
2. **Effort is a property of the role, not a ceiling inherited from the caller.** A session running at `low` still dispatches `senior-reviewer` at `medium`, and a session running at `high` or above still dispatches it at `medium`. Do not refuse to delegate because the role's effort differs from yours in either direction; that reading is not how the field works.
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

A nested dispatch chooses its model the same way a direct one does: `local-orchestrator` passes each leaf the approved model its work needs, and the leaf's frontmatter supplies its effort. Depth controls authority and spawning; it never changes the approved routes.

Depth is also not the default. Ordinary assistance is flat: the root dispatches a helper, which does its bounded work without spawning. `local-orchestrator` is the one authorized nesting workflow, and the root chooses it explicitly for a slice with genuine fan-out.

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
- `CLAUDE_CODE_SUBAGENT_MODEL: "haiku"` is the fallback for any subagent that names no model — built-in agent types such as Explore and Plan. On Claude Code v2.1.251 and later it sits below the frontmatter and the per-call model, so the six bundled roles are unaffected. **On an older install the variable outranks both**, which would push the four Opus roles onto Haiku; on such an install, omit this line or update Claude Code first. Do **not** add `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`; it would block the per-call model, which is how the work's route is chosen.
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "0"` keeps a named subagent from launching as a teammate, which would make it inherit the lead's effort instead of the definition's. Teams are off by default; this pins them off against a stray shell export. Project, `--settings`, and managed settings still win over the user file.

All three are optional hardening. Do not change them from inside a task without authorization, and do not treat their absence as a reason to refuse to delegate.

## Two runtime behaviors that change the shape of delegation

**Agent teams.** Agent teams are experimental and off by default; an operator enables them with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. While they are on, in an interactive session, a subagent spawned from the main conversation *with a `name`* launches as a teammate rather than a plain subagent, runs in the main session's working directory, and inherits the lead's effort level rather than the definition's. A teammate's model still follows the definition when the spawn prompt names none. An `isolation` value in the definition's frontmatter does not prevent this. If your ownership, isolation, or effort reasoning depends on a child being a conventional subagent, verify which one you actually got.

**Background subagents.** A subagent running in the background keeps only a fixed subset of built-in tools; others are stripped whether inherited or explicitly listed. Do not assume a background dispatch has the tools its `tools` line names.

## Worktree isolation

Shared execution is the default and the auxiliary-worktree budget starts at zero. No bundled agent sets `isolation: worktree`.

The reason is specific and worth stating plainly: **a subagent with `isolation: worktree` gets a worktree branched by default from your repository's default branch, not from the parent session's `HEAD`.** An isolated worker can therefore start without the changes the current session just made, and produce work against the wrong base. The `worktree.baseRef` setting controls this — `"head"` branches from the current `HEAD` instead.

So isolation is a root decision, made with the base ref recorded and verified. `isolation` can also be passed on an `Agent` call directly, which is exactly why descendants are told never to do that. The `worktree-lifecycle` skill holds the full lifecycle.

## What to record before dispatching

Not a form to fill in — the set of things that should be true and stated somewhere:

```text
Why a helper is worth it here: [independent evidence / parallel progress / context kept out — and what it costs]
Role and subagent_type:
Model on the call: [haiku for lookup or extraction, opus for judgment — chosen for this work]
Role's effort (from its definition): [none on the Haiku roles, medium on the Opus roles]
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
- The dispatch named a bundled role and passed an approved model chosen for the work; nothing indicates a forced or allowlist-substituted model.
- The helper earned its cost: the benefit recorded before dispatch actually arrived, and the result is not something the root already had.
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
- the route cannot be honored — the chosen model is blocked by an allowlist, `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` pins something else, or the effective model cannot be determined
- the route is mismatched to the work — a lookup model was handed judgment work, or the assignment turned out to need reasoning the approved routes do not cover

A helper returns evidence and the blocker. It never changes its own model or effort, falls back silently to an inherited setting, or changes the root's or a peer's settings through a report. The root then decides: report the constraint and keep the work itself, correct the assignment, or re-dispatch on another approved route whose effective model it can verify, within the existing allowance and with the user's approval before any material cost expansion. Do not quietly accept a substituted answer as if it came from the chosen model, do not raise a role above `medium`, and do not escalate a failing child to `fable`; a bounded task a helper cannot finish on an approved route needs a sharper assignment or the root's own judgment, not a bigger model.

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
