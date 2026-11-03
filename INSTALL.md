# Install Coding Agent Playbook — Claude Code Edition

This file is written for both humans and AI coding agents.

The intended experience is:

```text
Install this repo into my Claude Code setup:
https://github.com/ArcanEdge-AI/coding-agent-playbook-claude-code

Follow INSTALL.md. Use full install unless I explicitly ask for support-only mode.
Preserve my existing files with backups and report exactly what changed.
Then install or update the companion plugins INSTALL.md lists to their latest
versions from their official sources.
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
    local-ci-preflight/
      SKILL.md
      assets/
        LOCAL_VALIDATION.template.md
        claude-md-local-validation.md
    aws-local-preflight/
      SKILL.md
      assets/
        LOCAL_VALIDATION.aws.template.md
      references/
        moto-boundaries.md
    multi-role-repo-review/
    technical-debt-auditor/
    platform-documentation/
    production-pass-orchestrator/
    production-readiness-report/
    production-api-integration/          # and the ten other production-* specialist lanes
```

The last group is shown by directory only. The repository's `README.md` shows each package's layout, and the repository's `skills/` directory is the complete file list. Third-party and separately maintained skills are not bundled: download them separately, at their latest versions, as [companion plugins](#companion-plugins).

Every skill is a self-contained package: its `SKILL.md` and every reference or template it depends on install together under the skill's own directory, and a path written inside a skill resolves against that skill's package root. There is no top-level `references/` directory in the Claude Code home; the `reference-doc-routing` skill packages the catalog of the workflow skills' references and templates by owning skill, and each domain skill names its own resources in its `SKILL.md`.

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

A skill directory that already exists under the same name as a playbook skill, but was never installed by the playbook — a standalone skill you added yourself — is adopted: each file the package ships replaces the existing file of that name, which is backed up first when it differs; files the package does not ship are left where they are; and from then on the manifest manages the package's files. Skills the playbook does not ship are never touched. If you installed a standalone copy of a skill that a later release ships under the same name, the update adopts that directory this way. Check the run's backup folder if you had customized it.

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

### What installing does not run

The installer copies files. It runs no bundled script, downloads nothing, installs no plugin, and configures no hooks. Download these separately:

- **Companion plugins.** They are part of the full setup, but this repository does not include them. Install each one from its official source, and update it on every playbook install or update so it always runs its latest version. See [Companion Plugins](#companion-plugins).
- **Python for helper scripts.** `platform-documentation`, `technical-debt-auditor`, and `production-readiness-report` ship standard-library Python helpers that need Python 3.9 or later. A skill runs one only when its workflow calls for it, under that session's permissions.
- **Local AWS emulation.** `aws-local-preflight` expects the project to supply Moto. The skill does not install it, start shared services, or call AWS.
- **A code-knowledge-graph tool, optionally.** `technical-debt-auditor` uses one, such as GitNexus, when the session already has it, and works without it.

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
9. Install or update the companion plugins, because the installer never downloads them. Do this when the user's request includes them, as the install prompt above does; otherwise list them and ask first. For each companion in [Companion Plugins](#companion-plugins), check `claude plugin list`: install a missing one, and update an installed one after refreshing its marketplace, so every companion ends on its latest version. If `claude plugin list` or the user shows that a companion was enabled from the Anthropic Directory, do not add a marketplace copy or run the marketplace update for it; report it, and point the user to its Directory listing for its latest version. Never pin a version, and never copy a plugin into `$CLAUDE_HOME/skills/`. Tell the user to restart Claude Code so updated plugins load.
10. Report exactly what changed, what was skipped, and where backups were written, with each companion's result reported separately from the playbook install.

Do not modify arbitrary repositories during installation. Only use a temporary clone of this repository and user-level Claude Code configuration locations.

## Companion Plugins

The full setup includes four companion plugins, but this repository does not bundle them, so you need to download each one separately from its official Claude distribution. That way each keeps its own license, notices, and updates. Always take a companion's latest version: install its current release, then update it on every playbook install or update. Never pin a version, and never keep a copied older release. Availability below was checked on 2026-11-03; each project's own listing is the source of truth. [THIRD_PARTY.md](THIRD_PARTY.md) credits each one.

| Companion | What it adds | Official Claude distribution |
| --- | --- | --- |
| Intuitive Software Design (ArcanEdge AI, Apache-2.0) | Design, review, and evaluation skills for screens, workflows, navigation, forms, and product behavior | The `arcanedge-plugins` marketplace in [ArcanEdge-AI/intuitive-software-design](https://github.com/ArcanEdge-AI/intuitive-software-design); also listed in the Anthropic Directory |
| Impeccable (Paul Bakaus, Apache-2.0) | Frontend design commands, design critique and audit, and anti-pattern detection | The `impeccable` marketplace in [pbakaus/impeccable](https://github.com/pbakaus/impeccable) |
| Taste (Leonxlnx, MIT) | Art direction for websites, product pages, dashboards, and app screens, checked in a real browser; provides the `design-taste-frontend` skill | The `taste-skill` marketplace in [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) |
| Humanizer (blader, MIT) | Editing AI-sounding prose without changing what it says | The `humanizer` marketplace in [blader/humanizer](https://github.com/blader/humanizer); also listed in the Anthropic Directory |

### Install the latest version

In the Claude Code CLI, add the publisher's marketplace, then install the plugin from it. If a marketplace is already configured, refresh it with `claude plugin marketplace update <marketplace>` before installing, so the install reads the publisher's current catalog rather than an old copy.

```bash
claude plugin marketplace add ArcanEdge-AI/intuitive-software-design
claude plugin install intuitive-software-design@arcanedge-plugins
```

```bash
claude plugin marketplace add pbakaus/impeccable
claude plugin install impeccable@impeccable
```

```bash
claude plugin marketplace add Leonxlnx/taste-skill
claude plugin install taste-skill@taste-skill
```

```bash
claude plugin marketplace add blader/humanizer
claude plugin install humanizer@humanizer
```

### Update to the latest version

Run this on every playbook install or update. `claude plugin marketplace update` with no name refreshes every configured marketplace, and `claude plugin update` then moves each installed companion to its latest version. Run the update line for each companion that `claude plugin list` shows, and install any missing companion with the commands under [Install the latest version](#install-the-latest-version). Restart Claude Code to load the updated plugins.

```bash
claude plugin marketplace update
claude plugin update intuitive-software-design@arcanedge-plugins
claude plugin update impeccable@impeccable
claude plugin update taste-skill@taste-skill
claude plugin update humanizer@humanizer
```

These are Claude Code's own plugin commands, as `claude plugin --help` describes them in Claude Code 2.1.281, applied to each project's published `.claude-plugin/marketplace.json`; the install and update commands were not exercised against these four plugins for this release. Inside a session, the `/plugin` command does the same. Confirm each result with `claude plugin list`, which lists installed plugins (in Claude Code 2.1.281 each entry shows its version, scope, and status); a cached directory alone does not prove an installation.

### From the Anthropic Directory

Intuitive Software Design and Humanizer are also listed in the Anthropic Directory, the plugin catalog in Claude, where you can enable them instead. The update commands above apply to marketplace installs. This guide did not verify how the Directory delivers updates, so check a Directory companion's listing for its current version. The Anthropic Directory is separate from the `claude-plugins-official` Claude Code marketplace, which did not list any of these four companions on 2026-11-03.

### Using companions with this playbook

- The playbook's global instructions still apply inside a companion's workflow: downloads, package installs, network or paid calls, and hook changes need the user's approval; retained tests are E2E; and helpers stay optional and bounded.
- Impeccable's own README notes that in Claude Code, installed command hooks run even when you deny the model's own commands, so a first edit can download its engine. Review any hooks a plugin installs before unattended runs.
- A copy of a companion kept directly under `$CLAUDE_HOME/skills/`, such as an older `intuitive-software-design` or `design-taste-frontend`, is a separate installation that loads alongside the plugin and never updates. The playbook installer never touches it; remove it yourself once the plugin is installed, so only the latest version is active.

## Validation Checklist

The installer runs these itself and **exits non-zero if any check fails**, so an agent following this file can trust the exit code rather than parsing output.

Files that must exist:

- `$CLAUDE_HOME/CLAUDE.md` — present, or intentionally left as a pointer-only file
- `$CLAUDE_HOME/.coding-agent-playbook-claude-code-managed-files.tsv` — lists every current managed support file exactly once
- `$CLAUDE_HOME/agents/` — `local-orchestrator.md`, `read-only-explorer.md`, `senior-reviewer.md`, `docs-researcher.md`, `test-triager.md`, `isolated-worker.md`
- `$CLAUDE_HOME/skills/` — every package under the repository's `skills/` directory, 28 in this release, each with `SKILL.md` and every file it ships, byte-identical to the source
- `$CLAUDE_HOME/skills/local-ci-preflight/` — `SKILL.md`, and in `assets/` both `LOCAL_VALIDATION.template.md` and `claude-md-local-validation.md`
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

- Every `references/`, `scripts/`, or `assets/` path written inside a skill — bare, or written from the stated base directory as `<skill-base-dir>/...` (or `<skill-dir>/...`) — resolves inside that skill's installed package.
- Every directory under `skills/` is installed as a complete package. The installer discovers packages from the source tree rather than from a list, so a new skill needs no installer change; a directory without a `SKILL.md`, or a loose file directly under `skills/`, fails the run.
- No installed skill depends on a top-level `references/` directory, and the installer does not create one.
- Every reference and template appears once, under one owning skill.

Separately from the installer, the repository's own validator, `scripts/validate.sh`, rejects any skill package that ships a `LICENSE` or `NOTICE` file, because companions install from their official sources rather than being bundled.

Content:

- Delegation guidance states that the root session implements directly by default, uses subagents sparingly — only when a bounded piece's concrete benefit outweighs its context, coordination, latency, and review cost, or independent assistance is required — under a finite launch and retry allowance, that helper assignments are flat by default, that a role's perspective can be applied directly without a dispatch and without changing the root's configuration, that self-review never satisfies an independent-verification gate, and that direct execution waives no skill, reference, graph-planning, or verification requirement.
- Routing guidance states the approved routes chosen by the work (Haiku for lookup and extraction, Opus at `medium` for judgment, the root itself for the hardest reasoning), that each definition's model is its default for its typical work, that the choice never follows the main session's model and applies to nested dispatches, retries, and replacements; that the main session's model, effort, and speed stay as the user configured them; that Claude Code resolves the model as per-invocation `model`, then frontmatter, then `CLAUDE_CODE_SUBAGENT_MODEL`, then the main model; and that `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` and organization allowlists can override that and must be reported rather than silently accepted.
- Routing guidance states that nesting is enabled by default at three layers, that this playbook caps at two, and that `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=2` is optional hardening rather than a precondition.
- Routing guidance states that `effort` is a role property that overrides session effort, not a ceiling inherited from the caller, that there is no per-invocation effort parameter, and that Haiku does not support `effort`.
- Task-graph guidance treats nodes as work outcomes with dependencies; a node never implies a helper, and the helper launch allowance, graph dependencies, approval gates, and worktree permits are distinct controls.
- Branch guidance routes feature work that may use one or more development branches to `feature-branch-lifecycle`, keeps the detailed procedure in that skill's packaged reference rather than the global instructions, and states that the sequence grants no authority to open or merge pull requests, delete branches, or promote production.
- Design guidance asks for the whole affected flow to be understood first, for existing components, dialogs, hooks, validators, and utilities to be reused, composed, extended, or improved before new code is written, for a substantial replacement to be justified by evidence of a significant benefit over improving the existing implementation, and accepts shared code only for a current need, a real boundary or invariant, an established convention, or meaningful duplication removed.
- Testing guidance retains only E2E behavioral tests of complete supported UI, API, or CLI flows; treats every created unit test as temporary, removed with its exclusive support code only after passing E2E coverage carries its still-required assertions; keeps build, lint, type checking, and static validation as valid evidence; preserves required repository gates; and migrates existing non-E2E suites only within authorized scope.
- Runtime guidance recovers and reuses the established environment in dependency order before creating another, bounds recovery at two cycles unless a project runbook sets another finite limit, starts browser tests with one worker when safe capacity is unverified or heavy jobs overlap, and tears down only task-owned resources.
- Local preflight guidance runs cheap checks before builds and dependent E2E checks, keeps local evidence separate from remote acceptance, and grants no authority to push, deploy, call cloud services, start shared services, or dispatch remote CI.
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

To remove the playbook manually:

1. Resolve the actual `$CLAUDE_HOME` the install used. Keep the managed-file manifest, `$CLAUDE_HOME/.coding-agent-playbook-claude-code-managed-files.tsv`, until you have identified the files the playbook owns.
2. Read the manifest entries and the marked section in `$CLAUDE_HOME/CLAUDE.md`. Do not infer ownership of a whole `agents/` file set or `skills/<name>/` directory from its name: an adopted directory can still hold files you added yourself.
3. Back up the files you select for removal. Keep unrelated files, `$CLAUDE_HOME/.coding-agent-playbook-backups/`, and customized copies unless you decide to remove them yourself. A file whose hash no longer matches the manifest needs review, not automatic deletion.
4. Remove only the verified playbook-owned files. Remove a package directory only after confirming that it holds no remaining files of yours, and never recursively delete the whole `skills/` or `agents/` directory.
5. To remove the global instructions, delete only the section between the Coding Agent Playbook — Claude Code Edition start and end markers in `$CLAUDE_HOME/CLAUDE.md`, and keep everything outside it.
6. Remove the manifest only when no managed files remain. If you keep customized files, keep the manifest as the record of what the playbook installed.

The playbook installs these subagent definitions and skill package directories. Use the list to identify candidates, not as a delete list:

```text
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
$CLAUDE_HOME/skills/local-ci-preflight/
$CLAUDE_HOME/skills/aws-local-preflight/
$CLAUDE_HOME/skills/multi-role-repo-review/
$CLAUDE_HOME/skills/technical-debt-auditor/
$CLAUDE_HOME/skills/platform-documentation/
$CLAUDE_HOME/skills/production-pass-orchestrator/
$CLAUDE_HOME/skills/production-readiness-report/
$CLAUDE_HOME/skills/production-api-integration/
$CLAUDE_HOME/skills/production-architecture-review/
$CLAUDE_HOME/skills/production-code-quality/
$CLAUDE_HOME/skills/production-database-integrity/
$CLAUDE_HOME/skills/production-devops-release/
$CLAUDE_HOME/skills/production-documentation-onboarding/
$CLAUDE_HOME/skills/production-performance-review/
$CLAUDE_HOME/skills/production-reliability-observability/
$CLAUDE_HOME/skills/production-security-review/
$CLAUDE_HOME/skills/production-testing-qa/
$CLAUDE_HOME/skills/production-ux-accessibility/
```

Companion plugins are not part of the playbook install. Remove one through Claude's plugin manager, or the catalog you installed it from, and follow its own documentation for anything it stores outside the plugin, such as a downloaded engine.

If an install adopted a skill directory you had created yourself under the same name, your original files are in that run's backup folder; restore them rather than deleting the directory.

If an earlier release left a `$CLAUDE_HOME/references/` directory that an update preserved because you had customized files there, review and remove it yourself.
