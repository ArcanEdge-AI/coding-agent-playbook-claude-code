The primary global coding-agent behavior may already be configured in this CLAUDE.md file.

Supporting reference documents ship inside the skill that owns them, under the Claude Code home skills directory, so an installed skill never depends on a loose top-level directory:

- `skills/reference-doc-routing/references/README.md` — catalog of every packaged reference and template, by owning skill
- `skills/reference-doc-routing/references/engineering-design.md` — decision questions for non-trivial design choices, when an abstraction has earned its place, and how to record material technical debt
- `skills/reference-doc-routing/references/reference-doc-routing.md` — choosing documents, judging their authority, and passing them on
- `skills/reference-doc-routing/references/templates/` — starter files for a repository CLAUDE.md and for architecture, testing, access-control, design-system, release, API-contract, and data-model docs
- `skills/subagent-orchestration/references/model-routing.md` — when a helper is worth its cost, the approved routes chosen by the work (Haiku for lookup and extraction, Opus at medium for judgment, the root itself for the hardest reasoning), how Claude Code resolves a subagent model and what overrides it, effort semantics, permission modes, tool boundaries, and nesting depth
- `skills/subagent-orchestration/references/subagents.md` — role perspectives versus helper assignments, when to delegate, which role fits, how to write an assignment, and how to verify a result before accepting it
- `skills/task-graph-orchestration/references/templates/task-graph.md` — the task-graph template
- `skills/feature-branch-lifecycle/references/branching-rule.md` — branch-model detection, the development to feature-integration to integration to production sequence, complete-feature validation, temporary-branch cleanup gates, and the authority each step needs
- `skills/worktree-lifecycle/references/worktrees.md` — task-local worktree budgeting, the base-ref trap, integration, cleanup, and preservation
- `skills/worktree-lifecycle/references/templates/worktree-manifest.md` — the worktree-manifest template
- `skills/multi-session-coordination/references/multi-session-coordination.md` — discovering, coordinating, sequencing, and integrating independent Claude Code sessions
- `skills/multi-session-coordination/references/templates/active-work-record.md` — the active-work-record template
- `skills/handoff/references/context-contract.md` — what a handoff package carries into a fresh session: evidence labels, the material-context inventory, repository rules, a seed-prompt skeleton, and the completeness check
- `skills/session-cleanup/references/post-session-cleanup-methodology.md` — the end-of-work cleanup and integrity procedure: the baseline and full work delta, the seventeen checks, and the completion report

Reusable Claude Code skills live under the Claude Code home skills directory:

- `skills/subagent-orchestration/SKILL.md`
- `skills/task-graph-orchestration/SKILL.md`
- `skills/feature-branch-lifecycle/SKILL.md`
- `skills/worktree-lifecycle/SKILL.md`
- `skills/multi-session-coordination/SKILL.md`
- `skills/handoff/SKILL.md`
- `skills/reference-doc-routing/SKILL.md`
- `skills/legacy-path-retirement/SKILL.md`
- `skills/senior-code-review/SKILL.md`
- `skills/session-cleanup/SKILL.md`

Custom Claude Code subagents live under the Claude Code home agents directory:

- `agents/local-orchestrator.md`
- `agents/read-only-explorer.md`
- `agents/senior-reviewer.md`
- `agents/docs-researcher.md`
- `agents/test-triager.md`
- `agents/isolated-worker.md`

Reference documents are supporting context, not automatic truth. The root session does repository work directly by default, including substantial multi-file work, applying the skills whose triggers match, and keeps task framing, integration, validation, acceptance, and the final response. It understands the whole affected flow before choosing a fix, improves the existing implementation by default, replaces a substantial part of a flow only on evidence of a significant benefit that justifies the migration, verification, and maintenance cost, and treats unnecessary abstractions, invented compatibility, and redundant tests as maintainability defects. Direct execution waives none of the skill, reference, graph-planning, or verification requirements.

Each bundled role definition carries a **Role perspective** the root may apply directly to a concrete question without launching a subagent; doing so changes nothing about the root's model, effort, permissions, or ownership, requires no role sequence or separate report, and is self-review rather than independent verification. The root uses subagents sparingly: it delegates a bounded piece only when the concrete benefit — independent evidence, genuinely parallel progress, or reading it would rather keep out of its context — outweighs the context, coordination, latency, and review the helper costs, or a governing instruction requires independent assistance, and always under a finite launch and retry allowance set before the first dispatch.

A helper's model is chosen for its work, within the approved routes, and passed explicitly on every `Agent` dispatch, including nested dispatches, retries, and replacements: `haiku` for narrow lookup, extraction, file mapping, or a log summary the root checks directly; `opus` for implementation, diagnosis, planning, and review; the root itself, on the model the user selected, for the hardest architecture and cross-system reasoning. Each definition's `model` is the default for its typical work — `haiku` on `read-only-explorer` and `docs-researcher` (Haiku does not support `effort`, so those definitions set none); `opus` with `effort: medium` on `senior-reviewer`, `test-triager`, `isolated-worker`, and `local-orchestrator`. Judgment work is never dispatched to Haiku, and `sonnet`, `fable`, `high`, `xhigh`, `max`, and fast mode are not helper routes. There is no per-call effort parameter, so effort belongs to the definition and there is one definition per role; a definition that omits effort inherits the session level, and `effort` in a definition overrides session effort as a property of the role, not a ceiling inherited from the caller. Claude Code resolves a subagent model as the per-invocation `model`, then the definition `model`, then `CLAUDE_CODE_SUBAGENT_MODEL`, then the main conversation model (before Claude Code v2.1.251 the environment variable came first); `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` overrides both the definition and the call, and an organization allowlist can substitute. When either applies, or the effective model cannot be determined, report it and keep the work with the root rather than accepting a substitute. The main session's model, effort, and speed stay as the user configured them; only the root reassigns a helper's route, within the approved routes and the allowance, and a helper never changes its own settings or anyone else's.

Claude Code allows nested subagents by default, up to three layers below the main conversation. This playbook uses at most two, and ordinary assistance is flat: a helper does its bounded work without spawning, and `local-orchestrator` is the one authorized nesting workflow, chosen explicitly by the root for a slice with genuine fan-out. `local-orchestrator` may dispatch immediately — there is no capability flag to verify first. The cap holds because every leaf role omits `Agent` from `tools` and lists it in `disallowedTools`. Setting `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` to `2` tightens the runtime default from 3 to 2 and is optional hardening, not a precondition; do not change it from inside a task. Keep every child at or below its parent in permissions, tools, scope, workspace, and authority; the approved routes are the same at every layer.

Read-only roles run in `plan` mode, which means they cannot reliably run tests, linters, type checkers, or builds — those commands prompt or go to the classifier. Route suite execution to `test-triager`, which runs in `default` mode.

Before feature work that may use one or more development branches, load the `feature-branch-lifecycle` skill and resolve the repository's real integration and production branch names before creating the branch structure. Development branches merge into a feature integration branch, the complete validated feature promotes from there to the integration branch through one pull request, and production promotes only from the integration branch under separate authority. Do not assemble an unfinished feature on a long-lived integration branch, skip a promotion layer, or invent a missing long-lived branch. Verify every cleanup gate immediately before deleting a temporary branch, preserve and report any branch whose gates do not pass, and never delete a permanent integration or production branch.

Before writing new code, look for components, dialogs, hooks, validators, utilities, and interaction patterns the project already has, and reuse, compose, or extend them when they fit; create shared code only for a current need, a real boundary or invariant, an established convention, or meaningful duplication removed. Keep or add a compatibility path only for a demonstrated current dependency or an explicit retention requirement, and apply the `legacy-path-retirement` skill when superseded code, a duplicate writer, an old contract, or a fallback is in question. A search that finds no caller is not proof that removal is safe, and code retirement and data retention are separate decisions.

The auxiliary-worktree budget starts at zero and is separate from anything about subagent counts or the helper launch allowance. Only the root may authorize `isolation: worktree`, create or adopt an auxiliary, change its purpose, move it, or remove it. One active auxiliary needs no added approval; two or more require user approval for the exact count and reasons. An isolated subagent's worktree branches from the repository default branch rather than the current `HEAD` unless `worktree.baseRef` is `"head"`, so record and verify the base ref before dispatching. Before the final response, remove each task-created auxiliary under verified gates or preserve it with exact path, owner, branch or HEAD, blocker, and next action. Task-local cleanup does not depend on scheduled automation, and the active host-managed workspace stays under the host lifecycle.

Verify implementation-relevant claims against primary evidence: current code, tests, schemas, configuration, logs, build output, typecheck output, runtime behavior, relevant session evidence, and authoritative external documentation.

When delegating to subagents or coordinating independent sessions, pass only the relevant document names, paths, or sections. Do not dump large documents or full session transcripts into prompts.

The root session remains accountable for the final plan, final diff, validation, and final response.
