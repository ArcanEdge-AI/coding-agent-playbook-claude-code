# Prompt: Set Up Global Claude Code Support System

> This is the explicit **support-only** setup prompt, not an installer or updater. For a normal install or update, follow `INSTALL.md` in full mode. Do not choose this prompt merely because playbook files already exist.

Paste this into Claude Code **after** you have already added the global instructions from `custom-instructions/global-coding-agent-instructions.md` to your global `CLAUDE.md`.

````markdown
You are configuring my global Claude Code support system.

Important context:
I have already added my full global coding-agent instructions to my global CLAUDE.md, the user-level memory file Claude Code loads into every session. Treat that as true even if you cannot inspect it here. Do not duplicate those instructions anywhere.

This statement is the authorization for support-only behavior. Without it, stop using this prompt and follow `INSTALL.md` in full mode.

Your job is to create the supporting system only:

- global reference documents
- subagent routing documentation
- reference-document routing documentation
- subagent delegation documentation
- multi-session coordination documentation
- reusable skills
- global custom Claude Code subagent definitions
- a small pointer section in the global CLAUDE.md, only if useful and not already present

Do not modify any repository files. Work only in user-level Claude Code configuration locations.

## Path Resolution

- `CLAUDE_HOME`: use `CLAUDE_CONFIG_DIR` if set; otherwise the Claude Code home, normally `~/.claude`.
- `GLOBAL_CLAUDE_MD`: `$CLAUDE_HOME/CLAUDE.md`
- `GLOBAL_REFERENCES_HOME`: `$CLAUDE_HOME/references`
- `GLOBAL_SKILLS_HOME`: `$CLAUDE_HOME/skills`
- `GLOBAL_AGENTS_HOME`: `$CLAUDE_HOME/agents`

On Windows, resolve the equivalent user-home paths rather than hardcoding Unix paths. Never hardcode machine-specific usernames or absolute paths.

## Preflight

Before writing anything:

1. Print the resolved paths.
2. Check whether `$GLOBAL_CLAUDE_MD`, `$GLOBAL_REFERENCES_HOME`, `$GLOBAL_SKILLS_HOME`, and `$GLOBAL_AGENTS_HOME` exist.
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
  references/
    README.md
    model-routing.md
    subagents.md
    engineering-design.md
    worktrees.md
    multi-session-coordination.md
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
      active-work-record.md
      task-graph.md
      worktree-manifest.md
  skills/
    task-graph-orchestration/SKILL.md
    subagent-orchestration/SKILL.md
    worktree-lifecycle/SKILL.md
    multi-session-coordination/SKILL.md
    reference-doc-routing/SKILL.md
    senior-code-review/SKILL.md
  agents/
    local-orchestrator.md
    read-only-explorer.md
    senior-reviewer.md
    docs-researcher.md
    test-triager.md
    isolated-worker.md
```

## Agent Definitions

Each file under `$GLOBAL_AGENTS_HOME` needs YAML frontmatter with `name`, `description`, `model`, `permissionMode`, `tools`, and `disallowedTools`, plus `effort` on the four Sonnet roles, followed by the system-prompt body.

| Agent | model | effort | permissionMode | tools | disallowedTools |
| --- | --- | --- | --- | --- | --- |
| `local-orchestrator` | `sonnet` | `high` | `default` | Agent, Read, Grep, Glob, Bash, Edit, Write, WebFetch, WebSearch | EnterWorktree, ExitWorktree |
| `read-only-explorer` | `haiku` | none | `plan` | Read, Grep, Glob | Agent |
| `docs-researcher` | `haiku` | none | `plan` | Read, Grep, Glob, WebFetch, WebSearch | Agent |
| `test-triager` | `sonnet` | `high` | `default` | Read, Grep, Glob, Bash, Edit | Agent |
| `isolated-worker` | `sonnet` | `high` | `default` | Read, Grep, Glob, Edit, Write, Bash | Agent |
| `senior-reviewer` | `sonnet` | `high` | `plan` | Read, Grep, Glob, Bash | Agent |

`read-only-explorer` and `docs-researcher` use `model: haiku` with no `effort` field, because Haiku does not support effort and those roles return evidence the root checks directly. The other four use `model: sonnet` with `effort: high`. That per-role route is fixed for every nested dispatch, retry, and replacement, independent of the main session's model; `xhigh` and `max` are deliberately not used. The caller also passes the role's model on each `Agent` call so the route survives a stale or overridden definition.

Keep exactly one definition per role. Do not create model-specific copies, and do not change the model or effort of any bundled definition.

`effort` is set per role and overrides the session's effort level. There is no per-invocation effort parameter, so the definition is the only place it can be set; a low-effort session still dispatches the four Sonnet roles at `high`.

`disallowedTools: Agent` on the five leaf roles is what actually prevents a third layer of nesting. Claude Code allows nesting three layers below the main conversation by default, so prompt text alone does not stop a spawn — omitting `Agent` from `tools` and listing it in `disallowedTools` does.

Set `tools` to the minimum each role needs. Only `local-orchestrator` gets `Agent`. Its broad tool list is the ceiling its children must stay within, not permission for unassigned direct edits.

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

The pointer section is:

```markdown
## Global Reference Documents and Subagent Support

The primary global coding-agent behavior may already be configured in this CLAUDE.md file.

Supporting global reference documents live under the Claude Code home references directory:

- `references/README.md` — map of the available global reference docs
- `references/model-routing.md` — the fixed per-role route (Haiku for lookup roles, Sonnet at high for judgment roles), how Claude Code resolves a subagent model and what overrides it, effort semantics, permission modes, tool boundaries, and nesting depth
- `references/subagents.md` — when to delegate, which role fits, how to write an assignment, and how to verify a result before accepting it
- `references/engineering-design.md` — decision questions for non-trivial design choices, when an abstraction has earned its place, and how to record material technical debt
- `references/worktrees.md` — task-local worktree budgeting, the base-ref trap, integration, cleanup, and preservation
- `references/multi-session-coordination.md` — discovering, coordinating, sequencing, and integrating independent Claude Code sessions
- `references/reference-doc-routing.md` — choosing documents, judging their authority, and passing them on
- `references/templates/` — templates for repository CLAUDE.md, architecture, testing, access control, design system, release, API contracts, data model, active work, task graphs, and worktree manifests

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

Reference documents are supporting context, not automatic truth. For repository tasks, delegate at least one bounded piece of execution to a subagent when subagents are available, and keep task framing, integration, validation, acceptance, and the final response with the root session. Direct root execution is right when subagents are unavailable, the user forbids delegation, the action needs authority that must stay with the root, or the task is too small to be worth delegating.

Each bundled subagent has a fixed route that does not follow the model selected for the main session: `read-only-explorer` and `docs-researcher` run on `haiku` (Haiku does not support `effort`, so those definitions set none); `senior-reviewer`, `test-triager`, `isolated-worker`, and `local-orchestrator` run on `sonnet` at `effort: high`. Pass the role model explicitly on every `Agent` dispatch and use the bundled roles; there is no per-call effort parameter, and a definition that omits effort inherits the session level. The same route applies to nested dispatches, retries, and replacements. Claude Code resolves a subagent model as the per-invocation `model`, then the definition `model`, then `CLAUDE_CODE_SUBAGENT_MODEL`, then the main conversation model (before Claude Code v2.1.251 the environment variable came first); `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` overrides both the definition and the call, and an organization allowlist can substitute. When either applies, or the effective model cannot be determined, report it and keep the work with the root rather than accepting a substitute. Never route a child to `opus` or `fable`, and never raise a role to `xhigh` or `max`. `effort` in a definition overrides session effort; it is a property of the role, not a ceiling inherited from the caller.

Claude Code allows nested subagents by default, up to three layers below the main conversation. This playbook uses two: the root session, one layer of direct workers or `local-orchestrator`, and a layer of leaves that cannot spawn. `local-orchestrator` may dispatch immediately — there is no capability flag to verify first. The cap holds because every leaf role omits `Agent` from `tools` and lists it in `disallowedTools`. Setting `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` to `2` tightens the runtime default from 3 to 2 and is optional hardening, not a precondition; do not change it from inside a task. Keep every child at or below its parent in permissions, tools, scope, workspace, and authority; model and effort stay fixed per role at every layer.

Read-only roles run in `plan` mode, which means they cannot reliably run tests, linters, type checkers, or builds — those commands prompt or go to the classifier. Route suite execution to `test-triager`, which runs in `default` mode.

The auxiliary-worktree budget starts at zero and is separate from anything about subagent counts. Only the root may authorize `isolation: worktree`, create or adopt an auxiliary, change its purpose, move it, or remove it. One active auxiliary needs no added approval; two or more require user approval for the exact count and reasons. An isolated subagent's worktree branches from the repository default branch rather than the current `HEAD` unless `worktree.baseRef` is `"head"`, so record and verify the base ref before dispatching. Before the final response, remove each task-created auxiliary under verified gates or preserve it with exact path, owner, branch or HEAD, blocker, and next action. Task-local cleanup does not depend on scheduled automation, and the active host-managed workspace stays under the host lifecycle.

Verify implementation-relevant claims against primary evidence: current code, tests, schemas, configuration, logs, build output, typecheck output, runtime behavior, relevant session evidence, and authoritative external documentation.

When delegating to subagents or coordinating independent sessions, pass only the relevant document names, paths, or sections. Do not dump large documents or full session transcripts into prompts.

The root session remains accountable for the final plan, final diff, validation, and final response.
```

## Create Supporting Files

Use this repository's contents as the canonical source for `references/`, `skills/`, and `agents/`. Preserve the intent, names, descriptions, the per-role model and effort route, permission modes, tools, and instructions.

If the installed Claude Code version uses a different supported frontmatter schema, adapt only as necessary and report the exact adjustment. Do not substitute an unknown model or invent model-specific agent copies.

## Validation

1. Print the resulting tree for `$CLAUDE_HOME`, `$GLOBAL_REFERENCES_HOME`, `$GLOBAL_SKILLS_HOME`, and `$GLOBAL_AGENTS_HOME`.
2. Confirm no repository files were modified.
3. Confirm each agent file has valid YAML frontmatter with `name`, `description`, `model`, `permissionMode`, `tools`, and `disallowedTools`; that `read-only-explorer` and `docs-researcher` use `model: haiku` with no `effort` field; and that the other four use `model: sonnet` with `effort: high`.
4. Confirm `read-only-explorer`, `docs-researcher`, and `senior-reviewer` use `permissionMode: plan` and list neither `Edit` nor `Write`.
5. Confirm `test-triager`, `isolated-worker`, and `local-orchestrator` use `permissionMode: default`.
6. Confirm each `SKILL.md` has YAML frontmatter with `name` and `description`.
7. Confirm all six agents exist, that only `local-orchestrator` lists `Agent` in `tools`, that the other five list `Agent` in `disallowedTools`, that no model-specific copies were created, and that no definition sets `isolation: worktree`.
8. Confirm every reference document, template, and skill listed above exists.
9. Confirm the routing docs state that the per-role route (Haiku for the two lookup roles, Sonnet at `high` for the four judgment roles) is independent of the main session's model, that nesting is enabled by default at three layers, that this playbook caps at two, that `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=2` is optional hardening rather than a precondition, that the per-invocation `model` outranks frontmatter and `CLAUDE_CODE_SUBAGENT_MODEL` unless `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` is set, and that effort is a role property with no per-invocation parameter.
10. Confirm only Claude Code paths, commands, model aliases, effort levels, permission modes, tool names, and frontmatter fields were installed.
11. Report files backed up, files skipped and why, assumptions made, and whether the pointer section was created, updated, already present, or skipped.

Final response format:

```text
Summary:
- Created or updated the global reference structure, skills, and subagent definitions.
- Left the existing global CLAUDE.md instruction section untouched.

Files:
- [created or updated]

Verification:
- [checks performed and results]

Notes:
- [backups, skipped files, assumptions, risks]
```
````
