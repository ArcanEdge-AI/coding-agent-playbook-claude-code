# Install Coding Agent Playbook — Claude Code Edition

This file is written for both humans and AI coding agents.

The intended experience is:

```text
Install this repo into my Claude Code setup:
https://github.com/ArcanEdge-AI/coding-agent-playbook-claude-code

Follow INSTALL.md. Use full install unless I explicitly ask for support-only mode.
Preserve my existing files with backups and report exactly what changed.
```

## What Gets Installed

A full install creates or updates this user-level structure:

```text
$CLAUDE_HOME/
  CLAUDE.md
  .coding-agent-playbook-claude-code-managed-files.tsv
  .coding-agent-playbook-backups/<timestamp>/   # backups of anything replaced
  agents/
    local-orchestrator.md
    read-only-explorer.md
    senior-reviewer.md
    docs-researcher.md
    test-triager.md
    isolated-worker.md
  skills/
    feature-branch-lifecycle/
      SKILL.md
      references/
        branching-rule.md
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
      references/
        context-contract.md
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
      references/
        post-session-cleanup-methodology.md
```

Every skill is a self-contained package: its `SKILL.md` and every reference or template it depends on install together under the skill's own directory, and a path written inside a skill resolves against that skill's package root. There is no top-level `references/` directory in the Claude Code home; the `reference-doc-routing` skill packages the catalog that lists every reference and template by owning skill.

Path resolution:

- `CLAUDE_HOME`: use `$CLAUDE_CONFIG_DIR` if set, otherwise `~/.claude`. This is the same resolution Claude Code uses for its home directory.
- On Windows, `~/.claude` means `%USERPROFILE%\.claude`; the installer resolves it itself.

## Install Modes

### Full install

Use this for normal installs and every normal update. It is the default when no mode flag is provided.

Full install:

- installs the global coding-agent instructions into `$CLAUDE_HOME/CLAUDE.md`
- copies the custom Claude Code subagent definitions into `$CLAUDE_HOME/agents/`
- copies every complete skill package, references and templates included, into `$CLAUDE_HOME/skills/`

The global instruction body is always installed inside one clearly marked Coding Agent Playbook — Claude Code Edition section. Content outside the markers is preserved. The installer adds the marked section when both markers are absent, or replaces exactly one well-ordered marked section after a timestamped backup. If only one marker exists, either marker is duplicated, or the end appears before the start, it stops without writing the file. A legacy `claude-code-agent-playbook` marker pair is migrated in place.

Any file the installer replaces is first copied to `$CLAUDE_HOME/.coding-agent-playbook-backups/<timestamp>/`, mirroring its relative path. Backups are deliberately kept out of `agents/` and `skills/` so those trees contain only managed files.

A skill directory that already exists under the same name as a playbook skill, but was never installed by the playbook — a standalone skill you added yourself — is adopted: each file the package ships replaces the existing file of that name, which is backed up first when it differs; files the package does not ship are left where they are; and from then on the manifest manages the package's files. Skills the playbook does not ship are never touched.

After a successful run, the installer writes `$CLAUDE_HOME/.coding-agent-playbook-claude-code-managed-files.tsv` with every managed support-file path and source SHA-256. On later runs, files removed from the repository are backed up and retired only when they still match the previously installed hash. Customized formerly managed files are preserved and reported. Files that were never recorded as playbook-managed are never removed. An existing `.claude-code-agent-playbook-managed-files.tsv` is migrated automatically after a successful update.

Earlier releases installed a loose `$CLAUDE_HOME/references/` tree. An update from one of those releases retires each of those files the same way: backed up and removed when it still matches the hash recorded at install time, preserved with a warning when it was customized. The installer never creates a top-level `references/` directory.

The first manifest-aware update has no previous ownership record, so it safely preserves existing unlisted files. Subsequent updates can distinguish unchanged retired files from user customizations.

The installer validates its sources before it writes anything, so a missing or policy-violating source file leaves the Claude Code home untouched. It does not roll back, though: if the filesystem itself fails partway through copying — a permission error, a full disk — the run exits non-zero with some managed files already updated and others not. No content is lost, because every replaced file is backed up first, and re-running a successful install completes the update.

### Support-only install

Use this only when the user explicitly requests support-only mode and confirms that the full global instructions already live in their global `CLAUDE.md` manually. Do not infer support-only mode merely because an older installation or an existing `CLAUDE.md` is present.

Support-only install:

- does not duplicate the full global instructions into `$CLAUDE_HOME/CLAUDE.md`
- adds only the short pointer section from `install/support-only-pointer.md`
- still copies the skill packages and custom Claude Code subagent definitions
- still updates the managed-file manifest and safely retires unchanged files removed from later playbook releases

Support-only reruns use the same marker validation and replacement rules, so installed pointers update without duplicating user-authored content.

### Dry run

`--dry-run` (or `-DryRun`) runs every step, reports what it would do with `Would install`, `Would back up`, and `Would retire` wording, creates or changes nothing — not even the Claude Code home — and ends with `Dry run complete. No files were changed.`

## Human Install

The installer is one standard-library Python script, `install/install.py`, and needs Python 3.8 or newer with no third-party packages. `install/install.sh` and `install/install.ps1` are thin launchers that find Python and run the same file with the same arguments, so use whichever entry point is convenient.

### macOS / Linux / WSL

```bash
git clone https://github.com/ArcanEdge-AI/coding-agent-playbook-claude-code.git
cd coding-agent-playbook-claude-code
python3 install/install.py --full
```

The launcher form is equivalent:

```bash
bash install/install.sh --full
```

Support-only mode:

```bash
python3 install/install.py --support-only
```

Dry run:

```bash
python3 install/install.py --full --dry-run
```

### Windows

```powershell
git clone https://github.com/ArcanEdge-AI/coding-agent-playbook-claude-code.git
cd coding-agent-playbook-claude-code
py -3 install/install.py --full
```

The launcher form is equivalent:

```powershell
pwsh -ExecutionPolicy Bypass -File install/install.ps1 -Full
```

Support-only mode:

```powershell
pwsh -ExecutionPolicy Bypass -File install/install.ps1 -SupportOnly
```

Dry run:

```powershell
pwsh -ExecutionPolicy Bypass -File install/install.ps1 -Full -DryRun
```

## Agent Install Instructions

When an AI coding agent is asked to install this repository, it should:

1. Clone or fetch the repository from the provided URL.
2. Read this `INSTALL.md` file first.
3. Resolve `CLAUDE_HOME`.
4. Inspect existing target files before writing.
5. Back up any existing file before changing it.
6. Use full install for both installation and update unless the user explicitly asks for support-only mode. Existing global instructions, markers, or support files are not permission to change modes.
7. Run `install/install.py` (directly, or through a launcher) so the complete skill packages and custom Claude Code subagent definitions land in the expected user-level locations.
8. Validate the installed files and Claude Code YAML frontmatter. The installer does this and exits non-zero on failure — check the exit code, do not just read the output.
9. Report exactly what changed, what was skipped, and where backups were written.

Do not modify arbitrary repositories during installation. Only use a temporary clone of this repository and user-level Claude Code configuration locations.

## Validation Checklist

The installer runs these itself and **exits non-zero if any check fails**, so an agent following this file can trust the exit code rather than parsing output.

Files that must exist:

- `$CLAUDE_HOME/CLAUDE.md` — present, or intentionally left as a pointer-only file
- `$CLAUDE_HOME/.coding-agent-playbook-claude-code-managed-files.tsv` — lists every current managed support file exactly once
- `$CLAUDE_HOME/agents/` — `local-orchestrator.md`, `read-only-explorer.md`, `senior-reviewer.md`, `docs-researcher.md`, `test-triager.md`, `isolated-worker.md`
- `$CLAUDE_HOME/skills/` — `subagent-orchestration`, `task-graph-orchestration`, `worktree-lifecycle`, `feature-branch-lifecycle`, `multi-session-coordination`, `handoff`, `reference-doc-routing`, `legacy-path-retirement`, `senior-code-review`, `session-cleanup`, each with `SKILL.md`
- `$CLAUDE_HOME/skills/feature-branch-lifecycle/references/branching-rule.md`
- `$CLAUDE_HOME/skills/handoff/references/context-contract.md`
- `$CLAUDE_HOME/skills/session-cleanup/references/post-session-cleanup-methodology.md`
- `$CLAUDE_HOME/skills/subagent-orchestration/references/` — `model-routing.md`, `subagents.md`
- `$CLAUDE_HOME/skills/task-graph-orchestration/references/templates/task-graph.md`
- `$CLAUDE_HOME/skills/worktree-lifecycle/references/` — `worktrees.md`, `templates/worktree-manifest.md`
- `$CLAUDE_HOME/skills/multi-session-coordination/references/` — `multi-session-coordination.md`, `templates/active-work-record.md`
- `$CLAUDE_HOME/skills/reference-doc-routing/references/` — `README.md`, `engineering-design.md`, `reference-doc-routing.md`, and `templates/` with the eight repository-documentation starters

Frontmatter and policy:

- Each `SKILL.md` has `name` and `description`.
- Each `agents/*.md` has `name`, `description`, `model`, `permissionMode`, `tools`, and `disallowedTools`.
- Every bundled definition declares an approved route as its default: `read-only-explorer` and `docs-researcher` use `model: haiku` with no `effort` field (Haiku does not support effort); `senior-reviewer`, `test-triager`, `isolated-worker`, and `local-orchestrator` use `model: opus` and `effort: medium`. The actual model is chosen per dispatch for the work, within those routes; effort can only be set in the definition, so this is what makes `medium` the effective level for delegated judgment work. No bundled definition uses `sonnet`, `fable`, `inherit`, `high`, `xhigh`, or `max`.
- Every bundled definition separates its **Role perspective**, which the root may apply directly, from its **Delegated use** rules, which apply only to an actual subagent, with an **Applying this perspective directly** section between them.
- Validation covers the six playbook-managed definitions by name. Other agent definitions the user keeps under the same directory are outside its scope and are neither checked nor changed.
- `read-only-explorer`, `docs-researcher`, and `senior-reviewer` use `permissionMode: plan` and list neither `Edit` nor `Write`.
- `test-triager`, `isolated-worker`, and `local-orchestrator` use `permissionMode: default`. No bundled role uses `acceptEdits`, `auto`, `dontAsk`, or `bypassPermissions`.
- Only `local-orchestrator.md` lists `Agent` in `tools`. The other five list `Agent` in `disallowedTools`, which is what actually prevents a third nesting layer — Claude Code allows nesting by default, so prompt text alone does not stop a spawn.
- No bundled agent sets `isolation: worktree`.
- Exactly one definition per role; the model is chosen per invocation instead of through model-specific or effort-specific copies, and effort stays in the definition.

Package integrity:

- Every `references/...` path written inside a skill resolves inside that skill's installed package.
- Every directory under `skills/` is installed as a complete package. The installer discovers packages from the source tree rather than from a list, so a new skill needs no installer change; a directory without a `SKILL.md`, or a loose file directly under `skills/`, fails the run.
- No installed skill depends on a top-level `references/` directory, and the installer does not create one.
- Every reference and template appears once, under one owning skill.

Content:

- Delegation guidance states that the root session implements directly by default, uses subagents sparingly — only when a bounded piece's concrete benefit outweighs its context, coordination, latency, and review cost, or independent assistance is required — under a finite launch and retry allowance, that helper assignments are flat by default, that a role's perspective can be applied directly without a dispatch and without changing the root's configuration, that self-review never satisfies an independent-verification gate, and that direct execution waives no skill, reference, graph-planning, or verification requirement.
- Routing guidance states the approved routes chosen by the work (Haiku for lookup and extraction, Opus at `medium` for judgment, the root itself for the hardest reasoning), that each definition's model is its default for its typical work, that the choice never follows the main session's model and applies to nested dispatches, retries, and replacements; that the main session's model, effort, and speed stay as the user configured them; that Claude Code resolves the model as per-invocation `model`, then frontmatter, then `CLAUDE_CODE_SUBAGENT_MODEL`, then the main model; and that `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` and organization allowlists can override that and must be reported rather than silently accepted.
- Routing guidance states that nesting is enabled by default at three layers, that this playbook caps at two, and that `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=2` is optional hardening rather than a precondition.
- Routing guidance states that `effort` is a role property that overrides session effort, not a ceiling inherited from the caller, that there is no per-invocation effort parameter, and that Haiku does not support `effort`.
- Task-graph guidance treats nodes as work outcomes with dependencies; a node never implies a helper, and the helper launch allowance, graph dependencies, approval gates, and worktree permits are distinct controls.
- Branch guidance routes feature work that may use one or more development branches to `feature-branch-lifecycle`, keeps the detailed procedure in that skill's packaged reference rather than the global instructions, and states that the sequence grants no authority to open or merge pull requests, delete branches, or promote production.
- Design guidance asks for the whole affected flow to be understood first, for existing components, dialogs, hooks, validators, and utilities to be reused, composed, extended, or improved before new code is written, for a substantial replacement to be justified by evidence of a significant benefit over improving the existing implementation, and accepts shared code only for a current need, a real boundary or invariant, an established convention, or meaningful duplication removed.
- Testing guidance favors the smallest meaningful checks and lasting tests for intended final behavior and realistic regression risks, updates or removes tests that only preserve an abandoned approach, and preserves still-required assertions and explicit coverage gates.
- Legacy-path guidance routes superseded code, duplicate writers, old contracts, and fallbacks to `legacy-path-retirement`, which requires dependency evidence or an explicit retention requirement, treats a search that finds nothing as an evidence gap rather than proof, treats hypothetical users and obsolete test accounts as no support commitment, decides data retention separately, and preserves correctness safeguards.
- Handoff guidance names only session actions Claude Code supports, never offers a resume, fork, branch, or cross-session message as a fresh continuation, and authorizes preparing the continuation rather than continuing the work.
- Session-cleanup guidance derives its surface from the repository against a verified baseline, preserves unrelated work, and routes branch deletion and worktree removal to their own lifecycle skills.
- `skills/reference-doc-routing/references/engineering-design.md` is installed and the global instructions point to it for non-trivial design decisions.
- Worktree guidance states that an isolated subagent branches from the repository default branch rather than the parent's `HEAD` unless `worktree.baseRef` is `"head"`.
- No non-Claude configuration paths, subagent schemas, or command vocabulary were introduced.

Manifest integrity:

- Every current manifest entry matches its repository source SHA-256.
- Every formerly managed path was absent, backed up and retired unchanged, or preserved with an explicit customization warning.
- A second identical install reports every file unchanged and writes no backups.

## Uninstall

This project does not currently ship an automatic uninstall command.

To remove it manually, delete:

```text
$CLAUDE_HOME/.coding-agent-playbook-claude-code-managed-files.tsv
$CLAUDE_HOME/.coding-agent-playbook-backups/
$CLAUDE_HOME/agents/local-orchestrator.md
$CLAUDE_HOME/agents/read-only-explorer.md
$CLAUDE_HOME/agents/senior-reviewer.md
$CLAUDE_HOME/agents/docs-researcher.md
$CLAUDE_HOME/agents/test-triager.md
$CLAUDE_HOME/agents/isolated-worker.md
$CLAUDE_HOME/skills/subagent-orchestration/
$CLAUDE_HOME/skills/task-graph-orchestration/
$CLAUDE_HOME/skills/worktree-lifecycle/
$CLAUDE_HOME/skills/feature-branch-lifecycle/
$CLAUDE_HOME/skills/multi-session-coordination/
$CLAUDE_HOME/skills/handoff/
$CLAUDE_HOME/skills/reference-doc-routing/
$CLAUDE_HOME/skills/legacy-path-retirement/
$CLAUDE_HOME/skills/senior-code-review/
$CLAUDE_HOME/skills/session-cleanup/
```

If an install adopted a skill directory you had created yourself under the same name, your original files are in that run's backup folder; restore them rather than deleting the directory.

If an earlier release left a `$CLAUDE_HOME/references/` directory that an update preserved because you had customized files there, review and remove it yourself.

If you used full install and want to remove the global instructions, edit `$CLAUDE_HOME/CLAUDE.md` and remove the section between the Coding Agent Playbook — Claude Code Edition start/end markers.
