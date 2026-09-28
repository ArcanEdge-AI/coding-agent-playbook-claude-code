# Prompt: Set Up Global Claude Code Support System

> This is the explicit **support-only** setup prompt, not an installer or updater. For a normal install or update, follow `INSTALL.md` in full mode. Do not choose this prompt merely because playbook files already exist.

Paste this into Claude Code **after** you have already added the global instructions from `custom-instructions/global-coding-agent-instructions.md` to your global `CLAUDE.md`.

````markdown
You are configuring my global Claude Code support system.

Important context:
I have already added my full global coding-agent instructions to my global CLAUDE.md, the user-level memory file Claude Code loads into every session. Treat that as true even if you cannot inspect it here. Do not duplicate those instructions anywhere.

This statement is the authorization for support-only behavior. Without it, stop using this prompt and follow `INSTALL.md` in full mode.

Your job is to create the supporting system only:

- every self-contained skill package, each with the references and templates it depends on
- the six global custom Claude Code subagent definitions
- a small pointer section in the global CLAUDE.md, only if useful and not already present

Do not modify any repository files. Work only in user-level Claude Code configuration locations.

## Path Resolution

- `CLAUDE_HOME`: use `CLAUDE_CONFIG_DIR` if set; otherwise the Claude Code home, normally `~/.claude`.
- `GLOBAL_CLAUDE_MD`: `$CLAUDE_HOME/CLAUDE.md`
- `GLOBAL_SKILLS_HOME`: `$CLAUDE_HOME/skills`
- `GLOBAL_AGENTS_HOME`: `$CLAUDE_HOME/agents`

On Windows, resolve the equivalent user-home paths rather than hardcoding Unix paths. Never hardcode machine-specific usernames or absolute paths.

## Preflight

Before writing anything:

1. Print the resolved paths.
2. Check whether `$GLOBAL_CLAUDE_MD`, `$GLOBAL_SKILLS_HOME`, and `$GLOBAL_AGENTS_HOME` exist.
3. Do not delete existing content.
4. Do not overwrite anything without a timestamped backup.
5. Prefer a careful update over a replacement when a file already exists.
6. Write backups under `$CLAUDE_HOME/.coding-agent-playbook-backups/<timestamp>/`, mirroring the relative path — not beside the original, which would leave stray files inside directories Claude Code scans.
7. Do not store sensitive access material, private local paths, full session transcripts, or long incident logs.
8. Keep everything tool-agnostic except where it is explicitly Claude Code specific.
9. Use only Claude Code file names, configuration paths, subagent frontmatter fields, model aliases, effort levels, permission modes, tool names, and session commands.
10. Do not ask me questions unless you are blocked. Make reasonable assumptions and report them.

## Desired Structure

```text
$CLAUDE_HOME/
  CLAUDE.md
  skills/
    feature-branch-lifecycle/
      SKILL.md
      references/branching-rule.md
    subagent-orchestration/
      SKILL.md
      references/
        model-routing.md
        subagents.md
    task-graph-orchestration/
      SKILL.md
      references/templates/task-graph.md
    worktree-lifecycle/
      SKILL.md
      references/
        worktrees.md
        templates/worktree-manifest.md
    multi-session-coordination/
      SKILL.md
      references/
        multi-session-coordination.md
        templates/active-work-record.md
    handoff/
      SKILL.md
      references/context-contract.md
    reference-doc-routing/
      SKILL.md
      references/
        README.md
        engineering-design.md
        reference-doc-routing.md
        templates/
          repository-CLAUDE.md
          architecture.md
          testing.md
          security.md
          design-system.md
          release.md
          api-contracts.md
          data-model.md
    legacy-path-retirement/
      SKILL.md
    senior-code-review/
      SKILL.md
    session-cleanup/
      SKILL.md
      references/post-session-cleanup-methodology.md
  agents/
    local-orchestrator.md
    read-only-explorer.md
    senior-reviewer.md
    docs-researcher.md
    test-triager.md
    isolated-worker.md
```

Every skill is a complete package: copy each skill directory whole, references and templates included, so that every `references/...` path written inside a skill resolves inside that skill's own directory. Do not create a top-level `references/` directory; the `reference-doc-routing` skill packages the catalog that lists every reference and template by owning skill. If an earlier setup left `$CLAUDE_HOME/references/`, leave it in place and report it; the repository installer retires those files safely when they are unchanged, and you must not delete them here.

## Agent Definitions

Each file under `$GLOBAL_AGENTS_HOME` needs YAML frontmatter with `name`, `description`, `model`, `permissionMode`, `tools`, and `disallowedTools`, plus `effort` on the four Opus roles, followed by the system-prompt body. Each body separates a **Role perspective** the root may apply directly, an **Applying this perspective directly** section, and **Delegated use** rules that apply only to an actual subagent.

| Agent | default model | effort | permissionMode | tools | disallowedTools |
| --- | --- | --- | --- | --- | --- |
| `local-orchestrator` | `opus` | `medium` | `default` | Agent, Read, Grep, Glob, Bash, Edit, Write, WebFetch, WebSearch | EnterWorktree, ExitWorktree |
| `read-only-explorer` | `haiku` | none | `plan` | Read, Grep, Glob | Agent |
| `docs-researcher` | `haiku` | none | `plan` | Read, Grep, Glob, WebFetch, WebSearch | Agent |
| `test-triager` | `opus` | `medium` | `default` | Read, Grep, Glob, Bash, Edit | Agent |
| `isolated-worker` | `opus` | `medium` | `default` | Read, Grep, Glob, Edit, Write, Bash | Agent |
| `senior-reviewer` | `opus` | `medium` | `plan` | Read, Grep, Glob, Bash | Agent |

`read-only-explorer` and `docs-researcher` default to `model: haiku` with no `effort` field, because Haiku does not support effort and those roles return evidence the root checks directly. The other four default to `model: opus` with `effort: medium`. Those are the approved helper routes: the caller chooses the model for each dispatch's work — `haiku` for lookup and extraction, `opus` for judgment — and passes it on the `Agent` call, for nested dispatches, retries, and replacements alike, independent of the main session's model. `sonnet`, `fable`, `high`, `xhigh`, `max`, and fast mode are not helper routes, and the hardest reasoning stays with the root.

Keep exactly one definition per role. Do not create model-specific or effort-specific copies, and do not change the model or effort of any bundled definition.

`effort` is set per role and overrides the session's effort level. There is no per-invocation effort parameter, so the definition is the only place it can be set; a low-effort session still dispatches the four Opus roles at `medium`.

`disallowedTools: Agent` on the five leaf roles is what actually prevents a third layer of nesting. Claude Code allows nesting three layers below the main conversation by default, so prompt text alone does not stop a spawn — omitting `Agent` from `tools` and listing it in `disallowedTools` does. Ordinary assistance is flat; `local-orchestrator` is the one authorized nesting workflow.

Set `tools` to the minimum each role needs. Only `local-orchestrator` gets `Agent`. Its broad tool list is the ceiling its children must stay within, not permission for unassigned direct edits. No bundled role lists `Skill`, so a helper applies a skill only when the assignment names it and its entrypoint path.

Do not enable `acceptEdits`, `auto`, `dontAsk`, or `bypassPermissions` without an explicit maintainer-approved use case and risk note.

Do not set `isolation: worktree` in any bundled definition. An isolated subagent's worktree branches from the repository default branch rather than the current `HEAD` unless `worktree.baseRef` is `"head"`, so isolation is a per-task root decision with the base ref recorded and verified.

Do not create agents whose names shadow Claude Code's built-in agent types. Use the names above.

## Handle the Global CLAUDE.md Safely

The full instructions are already in `$GLOBAL_CLAUDE_MD`. Do not duplicate them.

If it does not exist: create it with the pointer section below, and tell me to add the full instructions from `custom-instructions/global-coding-agent-instructions.md`. Do not fabricate them.

If it exists:

- Preserve everything outside the `<!-- coding-agent-playbook-claude-code:start -->` and `<!-- coding-agent-playbook-claude-code:end -->` markers.
- Migrate one valid legacy `claude-code-agent-playbook` marker pair rather than appending a duplicate section.
- If exactly one well-ordered marked section exists, back it up and replace only that inclusive block.
- If neither marker exists, append the marked section.
- If only one marker exists, either is duplicated, or the end precedes the start: stop and report the malformed state without writing.
- If the pointer already appears to be present, report the possible duplication and delete nothing.

The pointer section is the same text the repository installer writes from `install/support-only-pointer.md`:

```markdown
## Global Reference Documents and Subagent Support

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
```

## Create Supporting Files

Use this repository's contents as the canonical source for `skills/` and `agents/`. Copy each skill directory whole — `SKILL.md` plus its `references/` tree — and preserve the intent, names, descriptions, each definition's default model and effort, its perspective and delegated-use structure, permission modes, tools, and instructions.

If the installed Claude Code version uses a different supported frontmatter schema, adapt only as necessary and report the exact adjustment. Do not substitute an unknown model or invent model-specific agent copies.

## Validation

1. Print the resulting tree for `$CLAUDE_HOME`, `$GLOBAL_SKILLS_HOME`, and `$GLOBAL_AGENTS_HOME`.
2. Confirm no repository files were modified.
3. Confirm each agent file has valid YAML frontmatter with `name`, `description`, `model`, `permissionMode`, `tools`, and `disallowedTools`; that `read-only-explorer` and `docs-researcher` use `model: haiku` with no `effort` field; that the other four use `model: opus` with `effort: medium`; and that each body carries the **Role perspective**, **Applying this perspective directly**, and **Delegated use** sections. Check only these six files; leave any other agent definitions in the directory alone.
4. Confirm `read-only-explorer`, `docs-researcher`, and `senior-reviewer` use `permissionMode: plan` and list neither `Edit` nor `Write`.
5. Confirm `test-triager`, `isolated-worker`, and `local-orchestrator` use `permissionMode: default`.
6. Confirm each `SKILL.md` has YAML frontmatter with `name` and `description`.
7. Confirm all six agents exist, that only `local-orchestrator` lists `Agent` in `tools`, that the other five list `Agent` in `disallowedTools`, that no model-specific copies were created, and that no definition sets `isolation: worktree`.
8. Confirm every skill package, reference, and template listed above exists, and that every `references/...` path written inside a skill resolves inside that skill's own directory. Confirm no new top-level `references/` directory was created.
9. Confirm the routing docs state that a helper's model is chosen for its work within the approved routes (Haiku for lookup and extraction, Opus at `medium` for judgment, the root itself for the hardest reasoning), independent of the main session's model, that the main session's configuration is never changed, that nesting is enabled by default at three layers, that this playbook caps at two and is flat by default, that `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=2` is optional hardening rather than a precondition, that the per-invocation `model` outranks frontmatter and `CLAUDE_CODE_SUBAGENT_MODEL` unless `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` is set, and that effort is a role property with no per-invocation parameter.
10. Confirm only Claude Code paths, commands, model aliases, effort levels, permission modes, tool names, and frontmatter fields were installed.
11. Report files backed up, files skipped and why, assumptions made, and whether the pointer section was created, updated, already present, or skipped.

Final response format:

```text
Summary:
- Created or updated the skill packages and subagent definitions.
- Left the existing global CLAUDE.md instruction section untouched.

Files:
- [created or updated]

Verification:
- [checks performed and results]

Notes:
- [backups, skipped files, assumptions, risks]
```
````
