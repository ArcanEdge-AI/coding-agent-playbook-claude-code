# Packaged Reference Documents

These are the durable, cross-repository references the root Claude Code session uses to route work, delegate when a helper earns its cost, review, validate, and coordinate with other sessions.

Each one ships inside the skill that owns it, under `skills/<skill>/references/` in the Claude Code home, so an installed skill never depends on a loose top-level directory. This catalog belongs to the `reference-doc-routing` skill and lists every packaged reference and template by owner. A path below that starts with `skills/` is relative to the Claude Code home; a path that starts with `references/` is inside this package.

They are deliberately generic. Repository-specific workflows, machine quirks, project names, sensitive access material, and one-off incident notes do not belong here — they belong in a repository's own `CLAUDE.md`, in a repository skill, or in local notes.

## How to use them

1. Start with the user's request and the applicable `CLAUDE.md` instructions.
2. Inspect the current code, tests, configuration, and docs.
3. Consult only the references that bear on the task, and only the relevant sections.
4. Treat every reference as supporting context, not automatic truth.
5. Do the work directly by default. Delegate a bounded piece to a subagent only when that has a concrete benefit — independent evidence, genuine parallelism, or reading you would rather keep out of your context — passing only the context that subagent needs.
6. Resolve every conflict with primary evidence.

Primary evidence: current code, tests, schemas, configuration, logs, build output, typecheck output, runtime behavior, relevant session evidence, and authoritative external documentation.

## The references

| Document | Owning skill | Read it when |
| --- | --- | --- |
| `skills/subagent-orchestration/references/model-routing.md` | `subagent-orchestration` | You are about to dispatch a subagent and need to choose the model, effort, permission mode, tools, and depth — and understand what actually overrides what. |
| `skills/subagent-orchestration/references/subagents.md` | `subagent-orchestration` | You are deciding whether a helper earns its cost, which role fits, and how to write an assignment that comes back usable. |
| `references/engineering-design.md` | `reference-doc-routing` (this package) | A design choice is non-trivial, cross-cutting, or hard to reverse; you are about to add an abstraction, layer, dependency, state, or configuration mechanism; or an implementation is accumulating workarounds. Decision questions, earned-abstraction cases, and how to record material technical debt. |
| `references/reference-doc-routing.md` | `reference-doc-routing` (this package) | You need to decide which documents matter, how much authority each has, and what to pass to a subagent. |
| `skills/worktree-lifecycle/references/worktrees.md` | `worktree-lifecycle` | Isolation is being proposed, a task already owns an auxiliary checkout, or a worktree needs integrating, preserving, or removing. |
| `skills/multi-session-coordination/references/multi-session-coordination.md` | `multi-session-coordination` | Other Claude Code sessions, branches, worktrees, or pull requests may be touching the same area. |

## The templates

| Template | Owning skill | Purpose |
| --- | --- | --- |
| `references/templates/repository-CLAUDE.md` | this package | Starting point for a repository's own `CLAUDE.md`. |
| `references/templates/architecture.md` | this package | Architecture reference. |
| `references/templates/testing.md` | this package | Testing strategy. |
| `references/templates/security.md` | this package | Safety and access-control model. |
| `references/templates/design-system.md` | this package | Design-system and UI conventions. |
| `references/templates/release.md` | this package | Release and deployment. |
| `references/templates/api-contracts.md` | this package | API contracts. |
| `references/templates/data-model.md` | this package | Data model and persistence. |
| `skills/multi-session-coordination/references/templates/active-work-record.md` | `multi-session-coordination` | Optional repository-local record of session ownership, contracts, dependencies, blockers, and validation gates. |
| `skills/task-graph-orchestration/references/templates/task-graph.md` | `task-graph-orchestration` | Optional instruction-only task graph for complex work with real dependencies, executed by the root by default. |
| `skills/worktree-lifecycle/references/templates/worktree-manifest.md` | `worktree-lifecycle` | Optional task-local ledger for auxiliary-worktree permits and dispositions. |

## Where things belong

**Packaged references** (inside the owning skill, under the Claude Code home skills directory) — durable guidance that holds across repositories. A skill that needs another skill's guidance names that skill; it does not copy the file or reach into the other package.

**Repository docs** — architecture, build and test commands, release flow, design rules, framework conventions, domain logic, project-specific subagent roles, active-work records.

**Skills** — repeatable workflows you want invoked by name, each carrying the references and templates it depends on.

**`CLAUDE.local.md` or local notes** — machine-specific or shell-specific quirks.
