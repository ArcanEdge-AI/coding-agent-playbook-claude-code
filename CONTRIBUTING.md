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
- anything for another coding-agent environment: its configuration, files, commands, model names, metadata, or links to editions for it. This repository is Claude Code only.
- copies of third-party skills. Link a third-party skill or plugin to its official Claude distribution as a companion instead.

## Style

- Prefer concise, direct language — but do not compress away detail an agent needs. These files are reference material.
- Use STE-inspired clarity, not formal ASD-STE100 compliance: one main instruction per sentence where practical, active voice, explicit actors, and consistent terms.
- Put conditions before the actions they control. Separate required actions, exceptions, and rationale when that makes the decision clearer.
- Keep every consequential qualifier, including "only", "before", "unless", and approval or verification requirements. Do not shorten a rule by weakening it.
- Keep exact commands, paths, schemas, configuration values, and historical evidence exact. Do not impose a restricted dictionary or a sentence-length limit on technical content.
- Keep guidance tool-agnostic unless the file is explicitly tool-specific.
- Prefer behavior and decision rules over rigid command sequences.
- Keep examples generic and safe for public reuse.

For files agents read directly (`agents/`, `skills/` including each skill's packaged references and templates, `custom-instructions/`), also:

- Put a rule where its actor can act on it. Routing rules belong in the caller's documentation, not in every leaf agent's system prompt.
- Lead with the decision, then the rule, then the exception.
- Prefer a worked example over an abstract list of required fields.
- Explain the mechanism when it changes behavior.
- Use Claude Code's own vocabulary — `Agent`, `subagent_type`, `model`, `effort`, `permissionMode`, `tools`, `disallowedTools`, plan mode — rather than invented terms.

Keep intact: root-session ownership and direct-first execution (subagents used sparingly, bounded, and flat by default; role perspectives applicable directly without a dispatch), the separation of the branch, worktree, session, and dependency lifecycles, the approved helper routes chosen by the work (Haiku for lookup and extraction, Opus at `medium` for judgment, the root itself for the hardest reasoning; no `sonnet`, `fable`, `high`, `xhigh`, `max`, or fast mode for helpers; the main session's configuration untouched), one definition per role with its **Role perspective** separated from its **Delegated use** rules, the two-layer subagent bound, capability boundaries, the task-local worktree lifecycle, the engineering-design standard (whole affected flow first, smallest complete solution, improve before replace, reuse before new code, earned abstractions, recorded material debt), the testing standard (retained tests are E2E tests of complete supported flows; every created unit test is temporary and removed with its exclusive support code once passing E2E coverage carries its still-required assertions; build, lint, type checks, and static validation remain valid evidence; required gates preserved; existing non-E2E suites migrated only within authorized scope), the runtime-resource rules (recover and reuse before replacing, two recovery cycles by default, one browser-test worker when capacity is unverified or heavy jobs overlap, task-owned teardown), and evidence-based legacy-path retirement (dependency evidence before a path is kept or removed, no invented support commitments, with data retention decided separately).

## Verify Claude Code Facts Before Changing Them

Several rules here depend on documented Claude Code behavior. An earlier revision of this playbook had the nesting rule backwards and it propagated to eleven files, so check current documentation before changing guidance that touches:

- model precedence (per-invocation `model` > frontmatter > `CLAUDE_CODE_SUBAGENT_MODEL` > main model, reversed only by `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`)
- which models support `effort` (Haiku does not), and that there is no per-invocation effort parameter
- nesting (enabled by default at three layers; `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=2` **tightens** it and is not a precondition)
- what prevents a spawn (`disallowedTools`, not prompt text)
- effort semantics (a role property that overrides session effort, not an inherited ceiling)
- plan-mode command gating (a `plan`-mode subagent cannot reliably run test suites)
- `isolation: worktree` base ref (default branch, not the parent's `HEAD`)
- session actions the `handoff` skill relies on: which ones start a fresh session, which carry the old history, how a background session isolates and preserves its edits, and the commands that list, inspect, and attach to it
- skill loading (Claude Code states a skill's base directory, so packaged `references/`, `scripts/`, and `assets/` paths resolve against it)
- plugin marketplace commands, and the separation between the Anthropic Directory and `claude-plugins-official`, which the companion guidance relies on

`CLAUDE.md` keeps the current statement of each. Update it in the same change.

## Pull Request Checklist

CI runs the automated checks. Run them locally first with `bash scripts/validate.sh`.

- `install/install.py` compiles, and a full-mode install into a temporary `CLAUDE_CONFIG_DIR` succeeds and exits 0; a repeat install is a no-op and a dry run creates nothing.
- `install.sh` and `install.ps1` stay thin launchers for `install.py`. With `pwsh` available they produce a byte-identical Claude Code home in both modes; CI checks this, and `scripts/validate.sh` skips it when `pwsh` is absent.
- Markdown fenced code blocks are balanced, every repository path referenced in Markdown exists, and every `references/`, `scripts/`, or `assets/` path written inside a skill — bare or as `<skill-base-dir>/...` (or `<skill-dir>/...`) — resolves inside that skill's package. A project's own path is written with a leading `./`. Nothing outside `skills/` refers to a top-level `references/` path.
- `SKILL.md` files include `name` and `description` frontmatter.
- `agents/*.md` include `name`, `description`, `model`, `permissionMode`, `tools`, and `disallowedTools`; each declares an approved route as its default — the two lookup roles `model: haiku` with no `effort`, the four judgment roles `model: opus` with `effort: medium` — and each carries the **Role perspective**, **Applying this perspective directly**, and **Delegated use** sections.
- Read-only roles use `permissionMode: plan` and list neither `Edit` nor `Write`; only `local-orchestrator` lists `Agent` in `tools`; the other five list `Agent` in `disallowedTools`; no bundled agent sets `isolation: worktree`.
- `README.md`'s repository-structure block matches the actual tree.
- Unix shell scripts remain LF-only.
- Testing guidance retains E2E tests only and treats every created unit test as temporary, whatever its purpose: no created unit test remains in a completed change, and removal waits until passing replacement E2E coverage carries its still-required assertions. Static checks, required assertions, and repository gates are preserved.
- No third-party skill is vendored. A companion links to its official Claude distribution, has a `THIRD_PARTY.md` row, and states availability, versions, and install commands only as far as they were verified, with the date.
- Any change to the facts listed above was verified against current Claude Code documentation and reflected in `CLAUDE.md`.
- The change adds nothing for another coding-agent environment.
- No sensitive or private material was added.

## License Note

By contributing to this repository, you agree that your contribution will be licensed under the MIT License. See `LICENSE`. Do not add third-party skill code; credit a companion and link its official source in [THIRD_PARTY.md](THIRD_PARTY.md). Do not change the license without an explicit maintainer decision.
