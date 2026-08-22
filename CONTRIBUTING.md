# Contributing

Thanks for helping improve Coding Agent Playbook — Claude Code Edition.

This repository is intentionally public and reusable. Contributions should make the playbook clearer, more durable, and less tool-specific.

## What Belongs Here

Good contributions include:

- clearer global coding-agent instructions
- better subagent delegation guidance
- reusable reference document templates
- improved skill definitions
- corrected custom-agent examples
- examples that stay generic and easy to adapt

## What Does Not Belong Here

Avoid adding:

- organization-specific workflows
- private project names
- local machine quirks
- internal URLs
- sensitive access material
- full session transcripts
- long incident logs
- instructions tied to one tool unless the file is explicitly an example

## Style

- Prefer concise, direct language — but do not compress away detail an agent needs. These files are reference material.
- Keep guidance tool-agnostic unless the file is explicitly tool-specific.
- Prefer behavior and decision rules over rigid command sequences.
- Keep examples generic and safe for public reuse.

For files agents read directly (`agents/`, `references/`, `skills/`, `custom-instructions/`), also:

- Put a rule where its actor can act on it. Routing rules belong in the caller's documentation, not in every leaf agent's system prompt.
- Lead with the decision, then the rule, then the exception.
- Prefer a worked example over an abstract list of required fields.
- Explain the mechanism when it changes behavior.
- Use Claude Code's own vocabulary — `Agent`, `subagent_type`, `model`, `effort`, `permissionMode`, `tools`, `disallowedTools`, plan mode — rather than invented terms.

Keep intact: root-session ownership, the main session's model as the ceiling, the two-layer subagent bound, capability boundaries, and the task-local worktree lifecycle.

Compare generic policy changes with the companion Codex playbook. Align them, or name the concrete Claude Code capability that requires the difference.

## Verify Claude Code Facts Before Changing Them

Several rules here depend on documented Claude Code behavior. An earlier revision of this playbook had the nesting rule backwards and it propagated to eleven files, so check current documentation before changing guidance that touches:

- model precedence (`CLAUDE_CODE_SUBAGENT_MODEL` outranks the per-invocation `model`)
- nesting (enabled by default at three layers; `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=2` **tightens** it and is not a precondition)
- what prevents a spawn (`disallowedTools`, not prompt text)
- effort semantics (a role property that overrides session effort, not an inherited ceiling)
- plan-mode command gating (a `plan`-mode subagent cannot reliably run test suites)
- `isolation: worktree` base ref (default branch, not the parent's `HEAD`)

`CLAUDE.md` keeps the current statement of each. Update it in the same change.

## Pull Request Checklist

CI runs the automated checks. Run them locally first with `bash scripts/validate.sh`.

- `bash -n install/install.sh` passes, and a full-mode install into a temporary `CLAUDE_CONFIG_DIR` succeeds and exits 0.
- Markdown fenced code blocks are balanced, and every repository path referenced in Markdown exists.
- `SKILL.md` files include `name` and `description` frontmatter.
- `agents/*.md` include `name`, `description`, `model`, `effort`, `permissionMode`, `tools`, and `disallowedTools`; every `model` is `haiku`.
- Read-only roles use `permissionMode: plan` and list neither `Edit` nor `Write`; only `local-orchestrator` lists `Agent` in `tools`; the other five list `Agent` in `disallowedTools`; no bundled agent sets `isolation: worktree`.
- `README.md`'s repository-structure block matches the actual tree.
- Unix shell scripts remain LF-only.
- Any change to the facts listed above was verified against current Claude Code documentation and reflected in `CLAUDE.md`.
- Generic policy changes were compared with the companion Codex playbook, and any intentional divergence names its reason.
- No sensitive or private material was added.

## License Note

By contributing to this repository, you agree that your contribution will be licensed under the MIT License. See `LICENSE`. Do not change the license without an explicit maintainer decision.
