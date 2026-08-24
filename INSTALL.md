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
  .coding-agent-playbook-claude-code-managed-files.tsv
  .coding-agent-playbook-backups/<timestamp>/   # backups of anything replaced
  rules/
    playbook-00-role-and-hierarchy.md
    playbook-10-understand-and-plan.md
    playbook-20-delegation.md
    playbook-30-code-quality.md
    playbook-40-verification.md
    playbook-50-completion.md
  commands/
    coordinate-work.md
  references/
    README.md
    model-routing.md
    subagents.md
    worktrees.md
    multi-session-coordination.md
    reference-doc-routing.md
    templates/
      active-work-record.md
      task-graph.md
      worktree-manifest.md
      *.md
  agents/
    local-orchestrator.md
    read-only-explorer.md
    senior-reviewer.md
    docs-researcher.md
    test-triager.md
    isolated-worker.md
  skills/
    task-graph-orchestration/SKILL.md
    subagent-orchestration/SKILL.md
    worktree-lifecycle/SKILL.md
    multi-session-coordination/SKILL.md
    reference-doc-routing/SKILL.md
    senior-code-review/SKILL.md
```

**The installer never edits your `CLAUDE.md`.** Behavior rules install as discrete files under `rules/`, which Claude Code loads into every session the same way. Nothing is spliced into a file you also own, so uninstalling a rule is deleting a file.

Path resolution:

- `CLAUDE_HOME`: use `$CLAUDE_CONFIG_DIR` if set, otherwise `~/.claude`.
- On Windows, resolve equivalent user-home paths safely.

## Install Modes

### Full install

Use this for normal installs and every normal update. It is the default when no mode flag is provided.

Full install copies five trees into `$CLAUDE_HOME`: `rules/`, `references/`, `agents/`, `skills/`, and `commands/`.

Any file the installer replaces is first copied to `$CLAUDE_HOME/.coding-agent-playbook-backups/<timestamp>/`, mirroring its relative path. Backups are deliberately kept out of the managed trees so those directories contain only managed files.

After a successful run, the installer writes `$CLAUDE_HOME/.coding-agent-playbook-claude-code-managed-files.tsv` with every managed file path and source SHA-256. On later runs, files removed from the repository are backed up and retired only when they still match the previously installed hash. Customized formerly managed files are preserved and reported. Files that were never recorded as playbook-managed are never removed. An existing `.claude-code-agent-playbook-managed-files.tsv` is migrated automatically after a successful update.

The first manifest-aware update has no previous ownership record, so it safely preserves existing unlisted files. Subsequent updates can distinguish unchanged retired files from user customizations.

### Support-only install

Use this only when the user explicitly requests support-only mode and confirms they manage their own behavior instructions. Do not infer support-only mode merely because an older installation is present.

Support-only install skips `rules/` entirely and installs `references/`, `agents/`, `skills/`, and `commands/`. It neither writes nor retires anything under `$CLAUDE_HOME/rules/`, so a previously installed rule set is left untouched rather than removed.

## Install as a Plugin

The repository is also a Claude Code marketplace, so `agents/`, `skills/`, and `commands/` can be installed and updated through the plugin system instead:

```bash
claude plugin marketplace add ArcanEdge-AI/coding-agent-playbook-claude-code
```

```bash
claude plugin install coding-agent-playbook@coding-agent-playbook-claude-code
```

Two things to know before choosing this path:

- **Plugins cannot contribute instruction rules or `references/`.** A plugin ships commands, agents, skills, hooks, and MCP/LSP servers. You still need the installer, or a manual copy, for `rules/` and `references/`.
- **Because the two halves update through different channels, they can drift.** The bundled installer does everything in one step and is the recommended path; the plugin is for people who specifically want `claude plugin update` to manage the component half.

## Human Install

Clone the repository and run the installer for your shell.

### macOS / Linux / WSL

```bash
git clone https://github.com/ArcanEdge-AI/coding-agent-playbook-claude-code.git
cd coding-agent-playbook-claude-code
bash install/install.sh --full
```

Support-only mode:

```bash
bash install/install.sh --support-only
```

Dry run:

```bash
bash install/install.sh --full --dry-run
```

### Windows PowerShell

```powershell
git clone https://github.com/ArcanEdge-AI/coding-agent-playbook-claude-code.git
cd coding-agent-playbook-claude-code
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
6. Use full install for both installation and update unless the user explicitly asks for support-only mode. Existing instructions or support files are not permission to change modes.
7. Copy instruction rules, reference docs, skills, commands, and custom Claude Code subagent definitions to the expected user-level locations.
8. Validate the installed files and Claude Code YAML frontmatter. The bundled installers do this and exit non-zero on failure — check the exit code, do not just read the output.
9. Report exactly what changed, what was skipped, and where backups were written.

Do not modify arbitrary repositories during installation. Only use a temporary clone of this repository and user-level Claude Code configuration locations.

## Validation Checklist

The installers run these themselves and **exit non-zero if any check fails**, so an agent following this file can trust the exit code rather than parsing output.

Files that must exist:

- `$CLAUDE_HOME/rules/` — the six `playbook-*.md` instruction rules (full mode only)
- `$CLAUDE_HOME/commands/coordinate-work.md`
- `$CLAUDE_HOME/.coding-agent-playbook-claude-code-managed-files.tsv` — lists every current managed file exactly once
- `$CLAUDE_HOME/references/` — `model-routing.md`, `subagents.md`, `worktrees.md`, `multi-session-coordination.md`, `reference-doc-routing.md`
- `$CLAUDE_HOME/references/templates/` — `active-work-record.md`, `task-graph.md`, `worktree-manifest.md`
- `$CLAUDE_HOME/agents/` — `local-orchestrator.md`, `read-only-explorer.md`, `senior-reviewer.md`, `docs-researcher.md`, `test-triager.md`, `isolated-worker.md`
- `$CLAUDE_HOME/skills/` — `subagent-orchestration`, `task-graph-orchestration`, `worktree-lifecycle`, `multi-session-coordination`, `reference-doc-routing`, `senior-code-review`, each with `SKILL.md`

Frontmatter and policy:

- Each `SKILL.md` has `name` and `description`.
- Each `agents/*.md` has `name`, `description`, `model`, `effort`, `permissionMode`, `tools`, and `disallowedTools`.
- Every managed agent `model` is the fail-closed `haiku` alias, so a dispatch that omits the model fails closed rather than inheriting the main session's tier.
- `read-only-explorer`, `docs-researcher`, and `senior-reviewer` use `permissionMode: plan` and list neither `Edit` nor `Write`.
- `test-triager`, `isolated-worker`, and `local-orchestrator` use `permissionMode: default`. No bundled role uses `acceptEdits`, `auto`, `dontAsk`, or `bypassPermissions`.
- Only `local-orchestrator.md` lists `Agent` in `tools`. The other five list `Agent` in `disallowedTools`, which is what actually prevents a third nesting layer — Claude Code allows nesting by default, so prompt text alone does not stop a spawn.
- No bundled agent sets `isolation: worktree`.
- Exactly one definition per role; per-invocation model routing is used instead of model-specific copies, and effort stays fixed in the definition.

Content:

- Routing guidance states that the main session's actual model is the ceiling, that equal-tier children are valid, that descendants do not upgrade themselves, that only the root routes a replacement, and that `CLAUDE_CODE_SUBAGENT_MODEL` outranks the per-invocation model.
- Routing guidance states that nesting is enabled by default at three layers, that this playbook caps at two, and that `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=2` is optional hardening rather than a precondition.
- Routing guidance states that `effort` is a role property that overrides session effort, not a ceiling inherited from the caller.
- Worktree guidance states that an isolated subagent branches from the repository default branch rather than the parent's `HEAD` unless `worktree.baseRef` is `"head"`.
- No non-Claude configuration paths, subagent schemas, or command vocabulary were introduced.

Manifest integrity:

- Every current manifest entry matches its repository source SHA-256.
- Every formerly managed path was absent, backed up and retired unchanged, or preserved with an explicit customization warning.

## Uninstall

This project does not currently ship an automatic uninstall command.

To remove it manually, delete:

```text
$CLAUDE_HOME/rules/playbook-*.md
$CLAUDE_HOME/commands/coordinate-work.md
$CLAUDE_HOME/references/
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
$CLAUDE_HOME/skills/multi-session-coordination/
$CLAUDE_HOME/skills/reference-doc-routing/
$CLAUDE_HOME/skills/senior-code-review/
```

Nothing needs to be edited out of `CLAUDE.md` — the installer never wrote there.

If you installed the plugin as well:

```bash
claude plugin uninstall coding-agent-playbook
```
