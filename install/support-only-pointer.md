The primary global coding-agent behavior may already be configured in this CLAUDE.md file.

Supporting reference documents ship inside the skill that owns them, under the Claude Code home skills directory, so an installed skill never depends on a loose top-level directory:

- `skills/reference-doc-routing/references/README.md` — catalog of every packaged reference and template, by owning skill
- `skills/reference-doc-routing/references/engineering-design.md` — decision questions for non-trivial design choices, when an abstraction has earned its place, and how to record material technical debt
- `skills/reference-doc-routing/references/reference-doc-routing.md` — choosing documents, judging their authority, and passing them on
- `skills/reference-doc-routing/references/templates/` — starter files for a repository CLAUDE.md and for architecture, testing, access-control, design-system, release, API-contract, and data-model docs
- `skills/subagent-orchestration/references/model-routing.md` — the fixed per-role route (Haiku for lookup roles, Sonnet at high for judgment roles), how Claude Code resolves a subagent model and what overrides it, effort semantics, permission modes, tool boundaries, and nesting depth
- `skills/subagent-orchestration/references/subagents.md` — when to delegate, which role fits, how to write an assignment, and how to verify a result before accepting it
- `skills/task-graph-orchestration/references/templates/task-graph.md` — the task-graph template
- `skills/worktree-lifecycle/references/worktrees.md` — task-local worktree budgeting, the base-ref trap, integration, cleanup, and preservation
- `skills/worktree-lifecycle/references/templates/worktree-manifest.md` — the worktree-manifest template
- `skills/multi-session-coordination/references/multi-session-coordination.md` — discovering, coordinating, sequencing, and integrating independent Claude Code sessions
- `skills/multi-session-coordination/references/templates/active-work-record.md` — the active-work-record template

Reusable Claude Code skills live under the Claude Code home skills directory:

- `skills/subagent-orchestration/SKILL.md`
- `skills/task-graph-orchestration/SKILL.md`
- `skills/worktree-lifecycle/SKILL.md`
- `skills/multi-session-coordination/SKILL.md`
- `skills/reference-doc-routing/SKILL.md`
- `skills/senior-code-review/SKILL.md`

Custom Claude Code subagents live under the Claude Code home agents directory:

- `agents/local-orchestrator.md`
- `agents/read-only-explorer.md`
- `agents/senior-reviewer.md`
- `agents/docs-researcher.md`
- `agents/test-triager.md`
- `agents/isolated-worker.md`

Reference documents are supporting context, not automatic truth. The root session does repository work directly by default, including substantial multi-file work, applying the skills whose triggers match, and keeps task framing, integration, validation, acceptance, and the final response. It delegates a bounded piece to a subagent only when that has a concrete benefit — independent evidence, genuinely parallel progress, or reading it would rather keep out of its context — under a finite launch and retry allowance set before the first dispatch. Direct execution waives none of the skill, reference, graph-planning, or verification requirements.

Each bundled subagent has a fixed route that does not follow the model selected for the main session: `read-only-explorer` and `docs-researcher` run on `haiku` (Haiku does not support `effort`, so those definitions set none); `senior-reviewer`, `test-triager`, `isolated-worker`, and `local-orchestrator` run on `sonnet` at `effort: high`. Pass the role model explicitly on every `Agent` dispatch and use the bundled roles; there is no per-call effort parameter, and a definition that omits effort inherits the session level. The same route applies to nested dispatches, retries, and replacements. Claude Code resolves a subagent model as the per-invocation `model`, then the definition `model`, then `CLAUDE_CODE_SUBAGENT_MODEL`, then the main conversation model (before Claude Code v2.1.251 the environment variable came first); `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` overrides both the definition and the call, and an organization allowlist can substitute. When either applies, or the effective model cannot be determined, report it and keep the work with the root rather than accepting a substitute. Never route a child to `opus` or `fable`, and never raise a role to `xhigh` or `max`. `effort` in a definition overrides session effort; it is a property of the role, not a ceiling inherited from the caller.

Claude Code allows nested subagents by default, up to three layers below the main conversation. This playbook uses at most two, and ordinary assistance is flat: a helper does its bounded work without spawning, and `local-orchestrator` is the one authorized nesting workflow, chosen explicitly by the root for a slice with genuine fan-out. `local-orchestrator` may dispatch immediately — there is no capability flag to verify first. The cap holds because every leaf role omits `Agent` from `tools` and lists it in `disallowedTools`. Setting `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` to `2` tightens the runtime default from 3 to 2 and is optional hardening, not a precondition; do not change it from inside a task. Keep every child at or below its parent in permissions, tools, scope, workspace, and authority; model and effort stay fixed per role at every layer.

Read-only roles run in `plan` mode, which means they cannot reliably run tests, linters, type checkers, or builds — those commands prompt or go to the classifier. Route suite execution to `test-triager`, which runs in `default` mode.

The auxiliary-worktree budget starts at zero and is separate from anything about subagent counts or the helper launch allowance. Only the root may authorize `isolation: worktree`, create or adopt an auxiliary, change its purpose, move it, or remove it. One active auxiliary needs no added approval; two or more require user approval for the exact count and reasons. An isolated subagent's worktree branches from the repository default branch rather than the current `HEAD` unless `worktree.baseRef` is `"head"`, so record and verify the base ref before dispatching. Before the final response, remove each task-created auxiliary under verified gates or preserve it with exact path, owner, branch or HEAD, blocker, and next action. Task-local cleanup does not depend on scheduled automation, and the active host-managed workspace stays under the host lifecycle.

Verify implementation-relevant claims against primary evidence: current code, tests, schemas, configuration, logs, build output, typecheck output, runtime behavior, relevant session evidence, and authoritative external documentation.

When delegating to subagents or coordinating independent sessions, pass only the relevant document names, paths, or sections. Do not dump large documents or full session transcripts into prompts.

The root session remains accountable for the final plan, final diff, validation, and final response.
