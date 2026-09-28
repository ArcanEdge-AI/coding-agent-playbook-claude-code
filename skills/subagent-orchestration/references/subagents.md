# Delegating to Claude Code Subagents

The root session is the senior engineer and the primary implementer. Subagents are how it buys parallelism, context isolation, and independent verification — not how it avoids thinking — and it uses them sparingly, only when a bounded assignment's concrete benefit outweighs the context, coordination, latency, and review it costs, or a governing instruction requires independent assistance.

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

Delegate a bounded piece when one of the advantages is a concrete benefit for it and outweighs the costs. Do not delegate a task you could finish in two tool calls; the round trip costs more than the work. Doing the work yourself is the default, including substantial multi-file work.

## Role perspectives and helper assignments

Each bundled definition separates its reusable **Role perspective** — what that role looks for and how it works — from the **Delegated use** rules that apply only to an actual subagent. The root may read a role's perspective and apply it directly to a concrete question: a reviewer's eye on its own diff, a triager's discipline about which checks mean something, an explorer's habit of mapping the whole affected flow. That changes nothing about the root's model, effort, permissions, approval gates, or ownership; it does not pick up the definition's launch settings or helper-only rules; it needs no separate report and no tour through the other roles. It is self-review, so it never satisfies a separately required independent-verification gate.

A useful perspective is not a reason to launch a helper. Dispatch a role only when the bounded assignment itself is worth a separate agent.

| Role | Default model | Effort | Mode | Tools | Typical delegated work |
| --- | --- | --- | --- | --- | --- |
| `read-only-explorer` | haiku | none | plan | Read, Grep, Glob | Mapping call paths, finding every call site, learning the local conventions before you design. |
| `docs-researcher` | haiku | none | plan | Read, Grep, Glob, WebFetch, WebSearch | Verifying external library, API, or platform behavior against the version actually installed. |
| `test-triager` | opus | medium | default | Read, Grep, Glob, Bash, Edit | Reproducing a failure and finding its root cause with proof; choosing proportionate checks. Runs suites; plan-mode roles cannot. |
| `isolated-worker` | opus | medium | default | Read, Grep, Glob, Edit, Write, Bash | Implementing a bounded change whose design is already settled. |
| `senior-reviewer` | opus | medium | plan | Read, Grep, Glob, Bash | Reviewing a real artifact for defects, regressions, and risk before acceptance. |
| `local-orchestrator` | opus | medium | default | Agent + read/write/web | One slice that genuinely fans out into independent parallel parts. |

The model column is each definition's default for its typical work; the actual model is chosen per dispatch for the work assigned and passed on the call, within the approved routes — `haiku` for lookup and extraction, `opus` for judgment. Effort is set only in the definition, which is why there is exactly one definition per role rather than copies per effort level. Every leaf role lists `disallowedTools: Agent`, which is what actually prevents a third layer of nesting. `model-routing.md` explains the choice and what can override it.

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

Direct root execution is the default for a repository task. A helper has to earn its cost with independent evidence, genuinely parallel progress, or reading the root would rather keep out of its context — and that benefit has to outweigh the context written into the assignment, the round trip, and the checking the result needs. Availability, a low price, task size, an unused role, a useful perspective, or a graph node are not reasons, and tightly coupled work or work already done is not delegated. No sequence of planner, implementer, reviewer, tester, and documentation passes is ever required. Before the first dispatch the root sets a finite allowance of launches and retries within its actual authority, and for each helper notes what it returns, how it will be verified, and the benefit — without inventing savings figures. The root stays accountable for framing, integration, validation, and the final answer, and direct work waives none of the skill, reference, graph, or verification requirements.

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
- **Skills** — the applicable skills, each with its entrypoint path, to read before the covered work. The bundled roles' `tools` allowlists omit `Skill`, so a helper cannot discover or invoke a skill itself.
- **Write ownership** — for any subagent that edits, the exact files it owns. Concurrent writers must never share a file.
- **Workspace** — the current one, unless the root has issued a worktree permit.
- **Model** — chosen for the work and explicit on the call: `haiku` for lookup, extraction, or a summary you will check directly; `opus` for anything needing judgment. The role's frontmatter supplies its effort; there is no per-call effort parameter, so use the bundled role rather than a built-in agent type.

Keep the payload small. Send paths and accepted results, not history, transcripts, or logs.

## Running several at once

Independent work runs concurrently. Dispatch multiple subagents in a single message and they run in parallel.

Sequence them only for a real dependency: the second genuinely cannot start without the first one's accepted output. Ordering that merely reflects how you listed the tasks is not a dependency and costs you the parallelism.

Before running writers in parallel, check that their file ownership is disjoint. When it is not, serialize them. A separate worktree is not the fix for overlapping writes — it converts a merge conflict into a harder merge conflict later.

Claude Code enforces a concurrent-subagent limit (20 by default) and fails a spawn beyond it. That is backpressure: let running work finish rather than queuing speculative work. Every launch counts against the allowance; expand it only for a newly discovered dependency, an invalidated gate, or a changed user scope, and record why — a node count is not a billing cap, and nothing enforces the accounting for you.

## Nesting

Claude Code allows nesting up to three layers below the main conversation by default. This playbook uses two:

```text
layer 0   root session
layer 1   direct worker, or local-orchestrator
layer 2   leaves dispatched by local-orchestrator — cannot spawn
```

`local-orchestrator` may dispatch immediately; there is no flag to verify first. The cap is enforced by the leaf definitions carrying `disallowedTools: Agent`, optionally reinforced by setting `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` to `2`. See `model-routing.md` for detail.

Assistance is flat by default — a helper does its bounded work without spawning. `local-orchestrator` is the one authorized nesting workflow, and the root chooses it explicitly. It earns its layer only when a slice genuinely fans out into independent parts whose intermediate output you do not want. When one worker can do the slice, dispatch that worker directly.

## Accepting the work

A returned result is a claim until you check it.

Verify:

- The acceptance condition is met, by evidence rather than assertion.
- Named paths and symbols exist and say what the result says they say. Spot-check at least the load-bearing ones.
- Nothing outside the assigned scope changed.
- Validation ran, or its absence is stated with a reason. A reason for omitting a check is not a passing check.
- The skills the assignment named were applied — their required outputs are present, not just a mention.
- Any edits are minimal and traceable to the assignment.
- The final diff — read it yourself.

When two subagents disagree, resolve it with primary evidence: the code, the tests, the schema, the logs, the runtime behavior. Do not average their conclusions or prefer the more confident one.

When a subagent fails, one retry with a sharper assignment is reasonable — after stating the failure evidence and what will change, and counting it against the allowance. A second identical failure is information — report the blocker rather than retrying again. Prefer a bounded correction or finishing the piece yourself over a chain of reviewers. A retry or a replacement stays within the approved routes, chosen by the root for the work; do not rescue a failing assignment by escalating to `fable` or by raising effort, and do not accept a substituted model as if it were the one you chose. A helper that finds its route unsuitable returns evidence and the blocker; it never changes its own settings or anyone else's.

Never accept a conclusion solely because it sounds confident.

## Worktrees are not delegation units

Start in the current workspace. The auxiliary-worktree budget starts at zero and is separate from anything to do with subagents. Read-only subagents and disjoint writers share the workspace safely.

Only the root may authorize `isolation: worktree` or create an auxiliary checkout, and only after recording the required base ref — an isolated subagent branches from the repository default branch rather than the current `HEAD` unless `worktree.baseRef` says otherwise. Descendants use their assigned workspace and report isolation needs upward. The `worktree-lifecycle` skill holds the full rules.

## Independent sessions are not subagents

A separate Claude Code session has its own history, branch, worktree, and ownership. You cannot dispatch it, and its summary is not evidence.

When independent sessions are working on related areas, use the `multi-session-coordination` skill before adding more parallel work. More subagents will not resolve an ownership conflict between sessions.
