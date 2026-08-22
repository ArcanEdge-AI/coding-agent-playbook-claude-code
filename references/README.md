# Global Claude Code Reference Documents

These are the durable, cross-repository references the root Claude Code session uses to orchestrate work, route subagents, review, validate, and coordinate with other sessions.

They are deliberately generic. Repository-specific workflows, machine quirks, project names, sensitive access material, and one-off incident notes do not belong here — they belong in a repository's own `CLAUDE.md`, in a skill, or in local notes.

## How to use them

1. Start with the user's request and the applicable `CLAUDE.md` instructions.
2. Inspect the current code, tests, configuration, and docs.
3. Consult only the references that bear on the task, and only the relevant sections.
4. Treat every reference as supporting context, not automatic truth.
5. Delegate at least one bounded piece of execution to a subagent for repository work when subagents are available, passing only the context that subagent needs.
6. Resolve every conflict with primary evidence.

Primary evidence: current code, tests, schemas, configuration, logs, build output, typecheck output, runtime behavior, relevant session evidence, and authoritative external documentation.

## The references

| Document | Read it when |
| --- | --- |
| `model-routing.md` | You are about to dispatch a subagent and need to choose the model, effort, permission mode, tools, and depth — and understand what actually overrides what. |
| `subagents.md` | You are deciding whether to delegate, which role fits, and how to write an assignment that comes back usable. |
| `worktrees.md` | Isolation is being proposed, a task already owns an auxiliary checkout, or a worktree needs integrating, preserving, or removing. |
| `multi-session-coordination.md` | Other Claude Code sessions, branches, worktrees, or pull requests may be touching the same area. |
| `reference-doc-routing.md` | You need to decide which documents matter, how much authority each has, and what to pass to a subagent. |

## The templates

| Template | Purpose |
| --- | --- |
| `templates/repository-CLAUDE.md` | Starting point for a repository's own `CLAUDE.md`. |
| `templates/architecture.md` | Architecture reference. |
| `templates/testing.md` | Testing strategy. |
| `templates/security.md` | Safety and access-control model. |
| `templates/design-system.md` | Design-system and UI conventions. |
| `templates/release.md` | Release and deployment. |
| `templates/api-contracts.md` | API contracts. |
| `templates/data-model.md` | Data model and persistence. |
| `templates/active-work-record.md` | Optional repository-local record of session ownership, contracts, dependencies, blockers, and validation gates. |
| `templates/task-graph.md` | Optional instruction-only task graph for complex work with real dependencies. |
| `templates/worktree-manifest.md` | Optional task-local ledger for auxiliary-worktree permits and dispositions. |

## Where things belong

**Global references** (here, under the Claude Code home) — durable guidance that holds across repositories.

**Repository docs** — architecture, build and test commands, release flow, design rules, framework conventions, domain logic, project-specific subagent roles, active-work records.

**Skills** — repeatable workflows you want invoked by name.

**`CLAUDE.local.md` or local notes** — machine-specific or shell-specific quirks.
