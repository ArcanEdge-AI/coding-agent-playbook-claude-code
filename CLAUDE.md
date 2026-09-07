# Repository Coding Agent Instructions

This repository is a public playbook of Claude Code global instructions, reference documents, skills, and custom subagent definitions. It is almost entirely Markdown, plus two installers and a small amount of YAML frontmatter.

Repository-specific guidance here overrides the global instructions where it is more specific.

## What This Repository Is For

- Keep the playbook useful across many teams and codebases.
- Keep global guidance tool-agnostic and durable.
- Keep repository-specific, machine-specific, and workflow-specific detail out of global instructions.
- Prefer concise, practical guidance over theory — but do not sacrifice necessary detail for brevity. These files are read by agents that need the specifics.
- Keep the root session accountable for framing, delegation, coordination, integration, validation, and the final report.
- Keep the subagent lineup at `local-orchestrator`, `read-only-explorer`, `senior-reviewer`, `docs-researcher`, `test-triager`, and `isolated-worker`.

## Facts About Claude Code That This Playbook Depends On

These are load-bearing. If you change guidance that touches them, verify against the current Claude Code documentation first — an earlier version of this playbook had the nesting rule backwards, and it propagated to eleven files.

- **Subagent frontmatter** supports `name`, `description`, `tools`, `disallowedTools`, `model`, `permissionMode`, `effort`, `isolation`, and others. All of the fields used here are documented.
- **Model precedence** (Claude Code v2.1.251 and later): per-invocation `model` > frontmatter `model` (including `inherit`) > `CLAUDE_CODE_SUBAGENT_MODEL` > the main conversation's model. `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` reverses this — it ignores every definition's `model` and blocks the per-call parameter — and an organization `availableModels` allowlist can substitute. Before v2.1.251 the environment variable came first; do not reintroduce that ordering.
- **The route is fixed per role**, independent of the main session's model, nesting depth, retries, and replacements: `read-only-explorer` and `docs-researcher` on `haiku` with no `effort` field (**Haiku does not support `effort`**), and `senior-reviewer`, `test-triager`, `isolated-worker`, and `local-orchestrator` on `sonnet` at `effort: high`. `xhigh` and `max` are deliberately not used because they remove the per-turn thinking ceiling and consume usage quickly on work the root verifies anyway. Do not reintroduce a "child at or below the main session's tier" rule, and do not put the four judgment roles on Haiku.
- **There is no per-invocation `effort` parameter** on the `Agent` call. A definition's `effort` is the only way to set a subagent's effort; a definition that omits it inherits the session level. The `effortLevel` settings key accepts `low` through `xhigh` but not `max`.
- **Nesting is enabled by default**, up to three layers below the main conversation. `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=2` **tightens** that to two; `1` turns nesting off. It is not a switch that enables nesting, and it must never be documented as a precondition for delegation.
- **What actually prevents a spawn** is omitting `Agent` from `tools` and listing it in `disallowedTools`. Prompt text does not.
- **`effort` overrides the session effort level.** It is a property of the role, not a ceiling inherited from the caller. Do not reintroduce a rule that a child's effort must be at or below the caller's session effort — it makes the `high`-effort roles unreachable from ordinary sessions.
- **Plan mode gates shell commands.** Commands outside the built-in read-only set are classifier-reviewed or prompt for approval, so a `plan`-mode subagent cannot reliably run tests, linters, type checkers, or builds. Suite execution belongs to `test-triager` (`default` mode), not `senior-reviewer` (`plan` mode).
- **`isolation: worktree` branches from the repository default branch**, not the parent session's `HEAD`, unless `worktree.baseRef` is `"head"`. This is why isolation is root-authorized with the base ref recorded.
- **Agent teams** are experimental and off by default (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` enables them). While on, a named subagent spawn in an interactive session becomes a teammate that runs in the main session's working directory and inherits the lead's effort rather than the definition's; frontmatter `isolation` does not prevent it.
- **Background subagents** keep only a subset of built-in tools, so one definition can resolve to different tools in the foreground and the background.

## Content Rules

- No sensitive access material, private local paths, internal-only URLs, session transcripts, or long incident logs.
- No hardcoded project names, organization workflows, or local machine quirks in global guidance.
- No instructions tied to a specific issue tracker, review tool, package manager, shell, or hosting provider unless the file is explicitly an example or template.
- Use Claude Code terminology in Claude-specific files: `CLAUDE.md`, the resolved Claude Code home, Markdown agent definitions with YAML frontmatter, model aliases, effort levels, permission modes, real tool names, and real session commands.
- Never copy configuration paths, file names, agent formats, model identifiers, or command vocabulary from another coding-agent environment into this repository.
- Prefer "safety", "access control", and "sensitive access material" over product-specific security terminology.
- Keep templates reusable and clearly marked as templates.
- Keep generic behavioral policy aligned with the companion Codex playbook. Where a difference is intentional, name the concrete Claude Code capability that requires it rather than leaving unexplained drift.

## Writing Style for Agent-Facing Files

The `agents/`, `references/`, `skills/`, and `custom-instructions/` files are read by models, and how they are written changes how well they are followed.

- **Put a rule where its actor can act on it.** Routing rules belong in the caller's documentation, not duplicated into every leaf agent's system prompt — a leaf cannot choose its own model.
- **Lead with the decision**, then the rule, then the exception.
- **Prefer concrete examples over abstract constraint lists.** One worked assignment teaches more than twenty required fields.
- **Explain the mechanism when it changes behavior.** "Plan mode cannot run your test suite" is followed; "respect permission boundaries" is not.
- **Use tables for lookups and numbered steps for procedures.**
- **State positive defaults**, then a bounded list of what not to do.
- **Avoid invented vocabulary.** Say what Claude Code says: subagent, `Agent` tool, `subagent_type`, `model`, `effort`, `permissionMode`, `tools`, `disallowedTools`, nesting depth, plan mode.
- **Do not compress away necessary detail.** These files are reference material; length is fine when every paragraph earns its place.

## Validation

Run the full check suite locally before finalizing meaningful changes:

```bash
bash scripts/validate.sh
```

CI runs exactly this script (`.github/workflows/validate.yml`), plus a PowerShell job that parses `install.ps1` and exercises it end to end — the Linux runners used for development have no `pwsh`, so that job is the only place `install.ps1` is actually executed.

Automated checks (CI enforces all of these):

- Every `SKILL.md` has YAML frontmatter with `name` and `description`.
- Every `agents/*.md` has `name`, `description`, `model`, `permissionMode`, `tools`, and `disallowedTools`. `read-only-explorer` and `docs-researcher` use `model: haiku` and no `effort`; the other four use `model: sonnet` and `effort: high`.
- `read-only-explorer`, `docs-researcher`, and `senior-reviewer` use `permissionMode: plan` and list neither `Edit` nor `Write`.
- `test-triager`, `isolated-worker`, and `local-orchestrator` use `permissionMode: default`.
- Only `agents/local-orchestrator.md` lists `Agent` in `tools`; the other five list `Agent` in `disallowedTools`.
- No bundled agent sets `isolation: worktree`.
- Fenced code blocks are balanced, and every repository path referenced in Markdown exists.
- Both installers pass a real full-mode install into a temporary home, including a body containing backslashes, and exit non-zero when a managed file is missing.
- `install.sh` and `install.ps1` produce a byte-identical Claude Code home in both full and support-only mode. They have drifted before — a trailing-newline difference and a case-insensitive manifest sort made each installer rewrite the other's files.
- `install.sh` passes `bash -n`.

Manual review:

- Guidance touching any item in **Facts About Claude Code** matches current documentation.
- `README.md`'s repository-structure block matches the actual tree.
- Design-principle wording in `custom-instructions/`, `agents/`, and `skills/` stays consistent with `references/engineering-design.md`: smallest complete solution, earned abstractions rather than a blanket ban on single-use ones, root-cause fixes within scope, and material technical debt recorded with scope, rationale, and follow-up condition.
- Install docs and scripts reference the current file set.
- Installers default to full mode, maintain the managed-file manifest, retire only unchanged formerly managed files, write backups outside the managed trees, and preserve customized or unrelated files.
- Generic policy changes were compared with the companion Codex playbook.
- The final diff contains no paths, schemas, model names, or commands belonging to another coding-agent environment.

## License

MIT (see `LICENSE`). Do not change the license without an explicit maintainer decision.
