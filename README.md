<p align="center">
  <img src="./assets/coding-agent-playbook-claude-code-hero.png" alt="Coding Agent Playbook — Claude Code Edition hero banner" width="100%" />
</p>

<h1 align="center">Coding Agent Playbook — Claude Code Edition</h1>

<p align="center">
  <strong>Installable, managed global instructions, subagents, skills, and engineering workflows for Claude Code.</strong>
</p>

<p align="center">
  Configure Claude Code to behave less like a loose autocomplete engine and more like a disciplined senior engineer: understand the whole affected flow, improve what exists before rebuilding it, implement directly with the skills that apply, use bounded subagents sparingly and only where they earn their cost, test proportionately, verify honestly, and ship maintainable code.
</p>

<p align="center">
  <a href="#install-with-one-prompt">Install</a> ·
  <a href="#quick-start">Quick Start</a> ·
  <a href="#harness-editions">Harness Editions</a> ·
  <a href="#why-this-exists">Why This Exists</a> ·
  <a href="#whats-inside">What's Inside</a> ·
  <a href="#subagent-model">Subagent Model</a> ·
  <a href="#formal-task-graph-orchestration">Task Graphs</a> ·
  <a href="#feature-branch-lifecycle">Branch Lifecycle</a> ·
  <a href="#task-local-worktree-lifecycle">Worktrees</a> ·
  <a href="#evidence-based-legacy-path-retirement">Legacy Paths</a> ·
  <a href="#coordinating-parallel-claude-code-sessions">Parallel Sessions</a> ·
  <a href="#handing-off-to-a-fresh-session">Handoff</a> ·
  <a href="#end-of-work-cleanup">Cleanup</a> ·
  <a href="#repository-structure">Structure</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Claude%20Code-Edition-6E7BFF" alt="Claude Code Edition" />
  <img src="https://img.shields.io/badge/Subagents-Optional-00C2FF" alt="Subagents Optional" />
  <img src="https://img.shields.io/badge/Sessions-Coordinated-4ECDC4" alt="Sessions Coordinated" />
  <img src="https://img.shields.io/badge/Instructions-Tool--Agnostic-8A5CFF" alt="Instructions Tool Agnostic" />
  <a href="https://github.com/ArcanEdge-AI/coding-agent-playbook-codex"><img src="https://img.shields.io/badge/Codex-Edition-D97706" alt="Codex Edition" /></a>
  <img src="https://img.shields.io/badge/License-MIT-2ECC71" alt="MIT License" />
  <img src="https://img.shields.io/badge/Status-Active-2ECC71" alt="Status Active" />
</p>

<p align="center">
  <strong>Using Codex instead?</strong>
  <a href="https://github.com/ArcanEdge-AI/coding-agent-playbook-codex">Open the Codex edition</a>.
</p>

---

## Install with One Prompt

The easiest install path is to give this repository URL to your coding agent:

```text
Install this globally: https://github.com/ArcanEdge-AI/coding-agent-playbook-claude-code

Follow the repository's INSTALL.md exactly. Use full mode even when an older installation exists; do not infer support-only mode unless I explicitly request it. Preserve my existing instructions, back up anything you change, install the global instructions, the self-contained skill packages, and the custom subagents, then report the installed files and validation results.
```

That is the intended public experience: users should not need to understand the file layout before installation. The agent should read `INSTALL.md`, clone or fetch the repository, install into user-level Claude Code configuration locations under the resolved Claude Code home, validate the result, and report what changed.

Support-only is an explicit pointer-only configuration, not an update mode. Use it only when the user confirms the global instructions already live in their global `CLAUDE.md` manually:

```text
Install this in support-only mode: https://github.com/ArcanEdge-AI/coding-agent-playbook-claude-code

I already added the global custom instructions manually. Follow INSTALL.md, but do not duplicate the full instructions into CLAUDE.md. Install the skill packages and custom subagents only.
```

---

## Quick Start

### Agent install

Ask your coding agent to install the repository URL and follow `INSTALL.md`. Normal installs and updates use full mode.

### Manual install

The installer is one standard-library Python script, `install/install.py` (Python 3.8 or newer, no packages). `install/install.sh` and `install/install.ps1` are thin launchers that find Python and run it with the same arguments, so these are equivalent:

```bash
git clone https://github.com/ArcanEdge-AI/coding-agent-playbook-claude-code.git
cd coding-agent-playbook-claude-code
python3 install/install.py --full
```

```bash
bash install/install.sh --full
```

```powershell
pwsh -ExecutionPolicy Bypass -File install/install.ps1 -Full
```

Support-only mode is `--support-only` (`-SupportOnly` for the PowerShell launcher). A dry run reports every step with `Would ...` wording and creates nothing:

```bash
python3 install/install.py --full --dry-run
```

### Repository-specific guidance

Copy this template into individual projects as a starting point:

```text
skills/reference-doc-routing/references/templates/repository-CLAUDE.md
```

Save it as `CLAUDE.md` at the project root, then fill in the actual build commands, test commands, architecture rules, generated-file rules, and release expectations for that repository.

---

## Harness Editions

Coding Agent Playbook ships as separate harness-native editions. This repository is the Claude Code edition.

| Edition | Repository | Use when |
| --- | --- | --- |
| Claude Code | `ArcanEdge-AI/coding-agent-playbook-claude-code` | You want global Claude Code instructions, self-contained skill packages, and subagent definitions. |
| Codex | [`ArcanEdge-AI/coding-agent-playbook-codex`](https://github.com/ArcanEdge-AI/coding-agent-playbook-codex) | You want the harness-native edition tuned for Codex. |

The philosophy is shared across both: the root agent acts as the senior engineer and primary implementer, bounded helpers provide evidence-backed assistance only where it has a concrete benefit, independent project sessions are coordinated explicitly, and final decisions stay with the root agent.

---

## Why This Exists

AI coding agents are powerful, but they often fail in predictable ways:

- They start coding before understanding the codebase.
- They over-engineer simple requests, or patch symptoms and call the smaller diff simpler.
- They rebuild a working flow because another design was possible, instead of improving the one that exists.
- They write a new component or helper when the codebase already has one that fits.
- They keep a fallback "to be safe", or delete one because a search came back empty.
- They invent compatibility requirements for hypothetical users or obsolete test accounts.
- They accumulate tests for abandoned partial fixes instead of maintaining tests for the intended final behavior.
- They refactor unrelated code.
- They trust editor diagnostics over real builds.
- They skip the skill that covers the task because the task looks familiar.
- They claim tests passed when they did not run them.
- They delegate poorly or blindly accept subagent output.
- They allow parallel sessions to develop incompatible contracts or ownership.
- They turn every task into a context dump instead of a focused engineering loop.

This playbook gives Claude Code a durable operating model:

```text
Understand → Plan → Implement → Verify → Review → Report
```

The intent is not to make the agent slower for its own sake. The intent is to make it **less wrong**, especially on real repositories with existing conventions, local changes, and concurrent work.

---

## What's Inside

| Area | Path | Purpose |
| --- | --- | --- |
| Install guide | `INSTALL.md` | Agent-readable install contract for one-prompt installation. |
| Installer | `install/` | One standard-library Python installer, thin Bash and PowerShell launchers, and the support-only pointer text. |
| Global instructions | `custom-instructions/` | Tool-agnostic behavior rules for elegant, maintainable code. Paste into your global `CLAUDE.md`. |
| Prompts | `claude-prompts/` | Setup and active-project coordination prompts. |
| Skills | `skills/` | Ten self-contained packages — task-graph, subagent, worktree, and feature-branch orchestration, session coordination, handoff to a fresh session, end-of-work cleanup, legacy-path retirement, document routing, and senior review — each shipping the references and templates it depends on: the approved helper routes, delegation rules, the engineering-design decision aid, worktree lifecycle, the branching rule, session coordination, the handoff context contract, the cleanup methodology, and the repository documentation templates. |
| Role definitions | `agents/` | Six Claude Code definitions — exploration, documentation, triage, implementation, review, and fan-out coordination — each usable as a perspective the root applies directly or as a bounded subagent assignment. |
| Repository guidance | `CLAUDE.md` | Instructions for maintaining this public playbook repository. |

---

## Install Modes

### Full install

Use this for normal installs and updates. Full mode is the default and safely replaces the playbook-owned marked section and current managed files.

Full install writes the global instructions into the user's global `CLAUDE.md`, installs the skill packages and the custom subagents, and records their paths and hashes in a managed-file manifest. Later updates can back up and retire unchanged files removed upstream while preserving customized or unrelated files.

### Support-only install

Use this only when the user explicitly says the global instructions already live in their global `CLAUDE.md`.

Support-only mode avoids duplicating the full instruction file and installs only the skill packages and custom subagents, plus a short pointer section.

---

## Core Philosophy

Understand the whole affected flow — entry points, shared behavior, business rules, data changes, consumers, success and failure outcomes — and improve the existing implementation by default. A substantial replacement needs evidence of a significant benefit that justifies its implementation, migration, verification, and maintenance costs; another possible design, or an alpha label, is not that evidence. Unnecessary abstractions, speculative compatibility, and redundant tests are maintainability defects.

Test proportionately. Use the smallest meaningful checks, keep lasting tests for important behavior and realistic regression risks — a focused unit test for a lasting business rule is exactly right — and, as the approach changes, update or remove the tests that only preserved an abandoned partial fix. Required checks, supported contracts, data preservation, and correctness safeguards still apply in full.

The root Claude Code session is the senior engineer and the primary implementer.

It owns:

- understanding the task
- the working plan
- architecture and design judgment
- the implementation, by default
- whether any work is delegated at all, and if so to which role at which model
- coordination with other sessions
- integration and final acceptance
- the final diff
- validation strategy
- the final response

Subagents are optional bounded assistance, used sparingly. They buy three things — context isolation, parallelism, and independent judgment — and cost you the context you write into the assignment, the round trip, the checking the result needs, and visibility into how the work was done. Delegate a bounded piece only when one of the three benefits outweighs those costs for it, or a governing requirement calls for independent assistance, and write the assignment so the missing visibility does not matter.

> The root session does the work directly by default, including substantial multi-file work, with the skills that apply. It can read any of the six role definitions and apply that perspective itself — a reviewer's eye on its own diff, a triager's discipline about which checks matter — without launching anything and without changing its own model, effort, or authority. It delegates a bounded piece only when a helper has a concrete benefit worth its cost, under a finite launch and retry allowance set before the first dispatch. No sequence of planner, implementer, reviewer, tester, and documentation passes is ever required, and self-review never counts as independent verification. Direct execution waives none of the skill, reference, graph-planning, or verification requirements.

Subagents share the current workspace by default. The auxiliary-worktree budget is separate and starts at zero. Only the root may authorize worktree isolation, and every task-created auxiliary is either integrated and removed inside the task or preserved with an exact blocker.

---

## Subagent Model

The six definitions in `agents/` are role perspectives first and subagents second. Each is Markdown with YAML frontmatter declaring a default model, the role's effort, `permissionMode`, `tools`, and `disallowedTools`, followed by a body in three parts: a **Role perspective** the root can read and apply to its own work, an **Applying this perspective directly** note that says doing so changes nothing about the root's model, effort, permissions, or ownership, and **Delegated use** rules that apply only when the role actually runs as a subagent. Definitions install to the Claude Code home agents directory; repositories can override them under `.claude/agents/`.

| Role | Default model | Effort | Delegated mode | Tools | Perspective, and typical delegated work |
| --- | --- | --- | --- | --- | --- |
| `read-only-explorer` | haiku | none | plan | Read, Grep, Glob | Mapping the whole affected flow, call sites, conventions, reusable pieces, and insertion points. |
| `docs-researcher` | haiku | none | plan | Read, Grep, Glob, WebFetch, WebSearch | Replacing recalled library, API, or platform behavior with cited facts for the installed version. |
| `test-triager` | opus | medium | default | Read, Grep, Glob, Bash, Edit | Choosing checks that mean something, telling meaningful tests from redundant ones, and proving a failure's root cause. Runs suites. |
| `isolated-worker` | opus | medium | default | Read, Grep, Glob, Edit, Write, Bash | Making one bounded, already-designed change the way the surrounding code would, and proving it works. |
| `senior-reviewer` | opus | medium | plan | Read, Grep, Glob, Bash | Judging an artifact against its acceptance criteria: correctness, completeness, scope, unearned abstractions, invented compatibility, redundant tests, risk. |
| `local-orchestrator` | opus | medium | default | Agent + read/write/web | Deciding whether a slice really fans out, and consolidating independent results without losing findings. |

To use a perspective directly, read the role's **Role perspective** and apply the parts that help the concrete question. That is self-review: a required independent-verification gate still needs a separate agent or the user. There is no required sequence through the roles and no expectation to use all six.

### The model follows the work

When a helper is worth dispatching, its model is chosen for the work being assigned — including on a retry, a replacement, and a leaf a `local-orchestrator` dispatches — to minimize the total cost of a correct, accepted result: tokens, the context repeated into the prompt, retries, corrections, and the root's own verification afterwards. The cheapest token price does not produce the cheapest completed task, and a cheap failed attempt is not a prerequisite for using a capable model.

| Work | Route |
| --- | --- |
| Narrow lookup, extraction, file mapping, log summaries — evidence the root checks directly | `haiku`, which has no effort level |
| Clear implementation, local fixes, bounded planning, straightforward review | `opus` at the definition's `medium` |
| Difficult debugging, coupled changes, substantial review, conflicting evidence | `opus` at `medium`, with a sharper, narrower assignment |
| The hardest architecture questions and complex cross-system reasoning | The root session, on the model the user selected. Not delegated |

Each definition's `model` is the default for its typical work; the model passed on the `Agent` call selects the actual route, so an Opus role handed only extraction can run on `haiku`, and judgment work never runs on Haiku. `medium` is Anthropic's documented default for Opus 5.5, and Anthropic reports it matches or exceeds Opus 5 at `high` there. `high`, `xhigh`, and `max` on a helper are deliberately not routes — they remove the per-turn thinking ceiling and consume usage quickly on work the root verifies anyway — and neither are `sonnet`, `fable`, or fast mode. The user picks the root session's model, effort, and speed, and nothing in a task changes them; only the root reassigns a helper's route, and a helper never changes its own. These are approved policy choices, not a measured ranking, and they change only by an explicit maintainer decision.

How Claude Code resolves a subagent's model (v2.1.251 and later), strongest first:

```text
per-invocation `model`        ← the model chosen for the work, passed on every call
frontmatter `model`           ← the definition's default for its typical work
CLAUDE_CODE_SUBAGENT_MODEL    ← only reached if neither of the above names a model
main conversation's model     ← last resort
```

Two things can still change what runs: `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` makes Claude Code ignore every definition's model and refuse the per-call parameter, and an organization `availableModels` allowlist can substitute. When either applies, the playbook reports the constraint and keeps the work in the root session rather than accepting a substitute.

### Effort can only be set in the definition

`effort` is set in frontmatter and, per the Claude Code subagent contract, **overrides the session effort level**. There is no per-invocation effort argument, and a definition that omits it inherits the session's level — so dispatching a bundled Opus role is what makes `medium` the effective level, and dispatching a built-in agent type instead silently drops back to session effort. This is also why the model can follow the work while effort belongs to the role, and why there is exactly one definition per role rather than a copy per effort level.

Effort is a property of the role, not a ceiling inherited from the caller. A session running at `low` still gets `senior-reviewer` at `medium`, and a session running at `high` still gets it at `medium`: the helper's effort is the role's economy, not the caller's setting.

### Plan mode cannot run your test suite

`read-only-explorer`, `docs-researcher`, and `senior-reviewer` run in `plan` mode. In plan mode, shell commands outside the built-in read-only set are reviewed by the auto-mode classifier or prompt for approval — and a prompt inside a subagent can stall rather than quietly succeeding.

So `git diff`, `git log`, `git blame`, and file reads are dependable there. `npm test`, `pytest`, `eslint`, `tsc`, and `make` are not. When a review needs a suite executed, that work goes to `test-triager`, which runs in `default` mode.

### Nesting: two layers, enforced by tools

Claude Code allows subagents to spawn their own subagents **by default**, up to three layers below the main conversation. This playbook uses at most two, and ordinary assistance uses one — a helper does its bounded work without spawning, and `local-orchestrator` is the explicitly chosen exception for a slice with genuine fan-out:

```text
layer 0   root session
layer 1   direct worker, or local-orchestrator
layer 2   leaves dispatched by local-orchestrator — cannot spawn
```

`local-orchestrator` may dispatch immediately; there is no capability flag to verify first. What actually holds the cap is the leaf definitions: each of the five leaf roles omits `Agent` from `tools` **and** lists it in `disallowedTools`, which is the mechanism Claude Code documents for keeping a subagent from spawning. Prompt text alone does not prevent a spawn.

An operator who wants the cap enforced at runtime as well can tighten the default from 3 to 2:

```json
{
  "env": {
    "CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH": "2"
  }
}
```

That is optional hardening, not a precondition, and the playbook does not change it from inside a task.

### Worktree isolation is off by default for a specific reason

No bundled agent sets `isolation: worktree`, because a subagent with isolation gets a worktree branched **from your repository's default branch, not from the parent session's `HEAD`** — unless `worktree.baseRef` is set to `"head"`. An isolated worker can therefore start without the changes the current session just made and produce work against the wrong base.

Only the root may authorize isolation, and only with the base ref recorded and the resulting checkout verified.

See:

```text
skills/subagent-orchestration/SKILL.md
skills/subagent-orchestration/references/model-routing.md
skills/subagent-orchestration/references/subagents.md
```

A good assignment names the role and the model chosen for its work, the goal as a verifiable outcome, the context, the scope and non-goals, write ownership for anything that edits, the exact workspace, the required evidence, the acceptance condition, and the stop conditions.

---

## Formal Task-Graph Orchestration

For work with substantial fan-out, genuine dependencies, broad scope, layered consolidation, or separate implementation and verification paths, the playbook compiles an instruction-only task graph before organizing and executing the dependent work — whether the root session executes every node itself or hands bounded nodes to helpers.

The root session owns the graph: the bounded nodes, what each consumes and produces, the dependency edges that are actually real, write ownership, the skills that govern each node, the model for any helper dispatch, permission and tool boundaries, workspaces, verification gates, and approval gates. Only nodes whose inputs are ready run, and a failure invalidates only the downstream nodes that consumed its output. A node is not a reason to launch a helper.

Every proposed edge has to survive one question — *can the downstream node begin correctly without an accepted output from the upstream node?* If it can, the edge is narrative order rather than a dependency, and keeping it costs parallelism.

This is a prompt-level coordination contract. It does not add a graph database, scheduler, runner, schema package, or orchestration framework. Keep medium graphs in the working plan. For long-running work, use `.claude/coordination/task-graphs/<task-slug>.md` when repository policy permits a local artifact.

See:

```text
skills/task-graph-orchestration/SKILL.md
skills/task-graph-orchestration/references/templates/task-graph.md
```

Run the multi-session coordination workflow first when other Claude Code sessions, branches, worktrees, pull requests, or active-work records may affect the graph's ownership or contracts.

---

## Feature Branch Lifecycle

Where a repository runs long-lived integration and production branches, feature work that uses one or more development branches has to be assembled and validated somewhere before it is promoted. The failure this prevents is assembling it on the long-lived integration branch, or promoting half of it.

```text
development branches
        ↓
feature integration branch
        ↓
long-lived integration branch, for example staging
        ↓
long-lived production branch, for example main
```

Development branches merge only into the feature integration branch. The complete feature is validated there, then promoted to the integration branch through one pull request. Production is promoted only from the integration branch, and only under separate authority.

The branch names above are examples. The skill resolves the repository's real integration and production branches, their protections, and any more specific repository instructions first, and it does not create a missing long-lived branch or displace an incompatible workflow because it happens to be installed.

Cleanup is gated rather than assumed. Before any temporary branch is deleted, the lifecycle verifies incorporation into the exact integration branch, required checks against the accepted result, the absence of unique unpreserved work and of any remaining dependency, worktree disposition, the exact local and remote targets, and authority for each deletion. A clean working tree, an old date, or a merged-looking name is not evidence. A branch whose gates fail is preserved and reported with its exact blocker. Permanent branches are never deleted.

A branch is not a worktree, a branch is not a session, and a feature integration branch is not automatically a task-graph node. The three lifecycles stay separate.

Supporting files:

```text
skills/feature-branch-lifecycle/SKILL.md
skills/feature-branch-lifecycle/references/branching-rule.md
```

---

## Task-Local Worktree Lifecycle

The worktree policy prevents subagent fan-out from becoming checkout fan-out:

```text
Current shared workspace + auxiliary budget 0
    ↓
Concrete isolation need verified
    ↓
Root issues one separate worktree permit
    ↓
Assigned work reuses that exact checkout
    ↓
Root integrates and validates the result
    ↓
Remove safely, or preserve with an exact blocker
```

The reason isolation is gated rather than default: a subagent with `isolation: worktree` gets a worktree branched **from the repository default branch, not from the parent session's `HEAD`**, unless `worktree.baseRef` is set to `"head"`. An isolated worker can therefore start without the changes the current session just made.

Only the root may authorize `isolation: worktree`, invoke root worktree controls, create or adopt an auxiliary, change its purpose, move it, or remove it. One active auxiliary needs no added approval; two or more require user approval for the exact count and reasons. Descendants use their assigned workspace and report isolation needs upward. Retries reuse compatible worktrees.

Before the final response, the root reconciles every task-created auxiliary. It either verifies safe non-force removal inside the task or reports the exact path, owner, branch or HEAD, blocker, and next action. Task-local cleanup does not depend on scheduled automation. The active host-managed worktree remains under the host's supported lifecycle.

Supporting files:

```text
skills/worktree-lifecycle/SKILL.md
skills/worktree-lifecycle/references/worktrees.md
skills/worktree-lifecycle/references/templates/worktree-manifest.md
```

---

## Evidence-Based Legacy Path Retirement

When an authorized change leaves superseded code, a duplicate writer, an old contract, or a compatibility fallback behind, two opposite mistakes are common: keeping it forever "to be safe", or deleting it because a search came back empty.

The `legacy-path-retirement` skill prefers one authoritative implementation within the affected scope. It keeps a compatibility path only for a demonstrated current dependency or an explicit retention requirement, and it treats a search that finds no caller as an evidence gap rather than proof of non-use — dynamic dispatch, configuration, stored data, and external clients do not show up in a symbol search.

Three decisions stay separate: what happens to the old code (retain, migrate, remove, or defer, on the evidence); what happens to existing data and configuration (preserved or migrated deliberately, and reset only with authority for the exact data); and the correctness safeguards the old path provided — stable references, authorization, validation, persistence integrity, cleanup — which move into the authoritative path instead of keeping the old one alive.

Hypothetical users, obsolete test accounts, fixtures, and earlier implementation attempts create no support commitment. The skill establishes who actually consumes the old behavior and what data actually needs retaining, uses the project's existing migration or reset tooling where that is appropriate and authorized, and never invents a second permanent flow to keep an earlier development version alive.

The skill is self-contained in:

```text
skills/legacy-path-retirement/SKILL.md
```

---

## Coordinating Parallel Claude Code Sessions

Subagents are delegated from one root session. Independent Claude Code sessions may already have separate conversation history, branches, worktrees, assumptions, and implementation ownership.

Use the multi-session coordination workflow when related project work is happening in parallel:

```text
Current project directory
    ↓
Sessions active within the previous 72 hours
    ↓
Other worktrees, branches, pull requests, and unmerged changes
    ↓
Shared change map and conflict detection
    ↓
Ownership, sequencing, and integration verification
```

Repository state takes precedence over recency. Older work still matters when it remains unmerged, incomplete, blocked, contract-relevant, or otherwise active.

New project sessions should use this naming format:

```text
Project - Three-to-Four-Word Description
```

Examples:

```text
ArcLedger - Validate Billing Evidence
LoreBound - Implement Campaign Imports
```

Use Claude Code's native session naming controls:

```text
claude -n "Project - Three-to-Four-Word Description"
/rename Project - Three-to-Four-Word Description
```

The project name should be detected automatically, and the description should be derived from the primary objective. If the current environment cannot rename the session directly, it should return the exact recommended name and `/rename` command rather than claiming the rename occurred.

Start the workflow with:

```text
claude-prompts/coordinate-active-project-work.md
```

Supporting files:

```text
skills/multi-session-coordination/SKILL.md
skills/multi-session-coordination/references/multi-session-coordination.md
skills/multi-session-coordination/references/templates/active-work-record.md
skills/worktree-lifecycle/SKILL.md
```

The optional active-work record gives repositories a local fallback when complete session-history discovery is unavailable. It is advisory and must be verified against current session and repository evidence.

---

## Handing Off to a Fresh Session

When a conversation has run long, compacted several times, or simply needs a clean start, the `handoff` skill carries the material context into a new Claude Code session: the objective and verdict, work and findings, validation and what it does and does not prove, user decisions and who handles git, workspace and workflow state, and the exact next gate. Every material claim is labelled verified current, user-reported, historical, or unverified.

The deliverable is a self-contained seed prompt, plus a durable file when warranted. Starting the new session uses only actions Claude Code supports for a *fresh* continuation:

```text
claude -n "<title>"    then paste the prompt — the default, in the same checkout
/clear                 then paste the prompt — this conversation stays resumable with /resume
```

Resuming, `/branch`, `--fork-session`, and `/fork` all carry the old history, so none of them is a handoff. A background session (`claude --bg`) is used only when the user asks for one: before it edits, it moves into its own worktree branched from the default branch, so uncommitted work does not come along, and it commits and pushes its changes unless it is told who handles git.

Supporting files:

```text
skills/handoff/SKILL.md
skills/handoff/references/context-contract.md
```

---

## End-of-Work Cleanup

Long work leaves debris that nobody remembers after a few compactions: a debug log, an abandoned helper, a compatibility shim for an interface that never shipped. The `session-cleanup` skill runs a deliberate pass at the end of substantial work, over the whole work delta rather than the parts the conversation remembers:

```text
Verified integration baseline
    ↓
Merge base to HEAD, plus staged, unstaged, and untracked work
    ↓
Debris, abandoned approaches, speculative compatibility, unnecessary complexity
    ↓
The project's own validation pipeline
    ↓
Cleaned Up · Validation · Problems Found · Remaining Issues · Final State
```

Compatibility code needs evidence. Code introduced and superseded within an unmerged branch never shipped, so it goes; compatibility code older than the work goes through `legacy-path-retirement` first. Unrelated changes, including another session's, are preserved. The pass uses no destructive git commands, commits nothing on its own initiative, and routes branch deletion and worktree removal to their own lifecycle skills.

Supporting files:

```text
skills/session-cleanup/SKILL.md
skills/session-cleanup/references/post-session-cleanup-methodology.md
```

---

## Reference Docs Without Context Soup

Large documents are useful only when routed correctly.

The root session should:

1. Identify which docs matter for the task.
2. Read only relevant sections when possible.
3. Classify docs as authoritative, advisory, or historical.
4. Pass only relevant context to subagents or active project sessions.
5. Resolve conflicts using primary evidence.

Primary evidence includes current code, tests, schemas, configuration, logs, build output, typecheck output, runtime behavior, relevant session evidence, and authoritative external documentation.

See:

```text
skills/reference-doc-routing/SKILL.md
skills/reference-doc-routing/references/reference-doc-routing.md
skills/reference-doc-routing/references/README.md
```

---

## Repository Structure

```text
.
├── .editorconfig
├── .gitattributes
├── .gitignore
├── CLAUDE.md
├── CONTRIBUTING.md
├── INSTALL.md
├── LICENSE
├── README.md
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── config.yml
│   │   └── improvement.md
│   ├── pull_request_template.md
│   └── workflows/
│       └── validate.yml
├── agents/
│   ├── docs-researcher.md
│   ├── isolated-worker.md
│   ├── local-orchestrator.md
│   ├── read-only-explorer.md
│   ├── senior-reviewer.md
│   └── test-triager.md
├── assets/
│   └── coding-agent-playbook-claude-code-hero.png
├── claude-prompts/
│   ├── coordinate-active-project-work.md
│   └── setup-global-claude-support-system.md
├── custom-instructions/
│   └── global-coding-agent-instructions.md
├── install/
│   ├── install.ps1
│   ├── install.py
│   ├── install.sh
│   └── support-only-pointer.md
├── scripts/
│   └── validate.sh
└── skills/
    ├── feature-branch-lifecycle/
    │   ├── SKILL.md
    │   └── references/
    │       └── branching-rule.md
    ├── handoff/
    │   ├── SKILL.md
    │   └── references/
    │       └── context-contract.md
    ├── legacy-path-retirement/
    │   └── SKILL.md
    ├── multi-session-coordination/
    │   ├── SKILL.md
    │   └── references/
    │       ├── multi-session-coordination.md
    │       └── templates/
    │           └── active-work-record.md
    ├── reference-doc-routing/
    │   ├── SKILL.md
    │   └── references/
    │       ├── README.md
    │       ├── engineering-design.md
    │       ├── reference-doc-routing.md
    │       └── templates/
    │           ├── api-contracts.md
    │           ├── architecture.md
    │           ├── data-model.md
    │           ├── design-system.md
    │           ├── release.md
    │           ├── repository-CLAUDE.md
    │           ├── security.md
    │           └── testing.md
    ├── senior-code-review/
    │   └── SKILL.md
    ├── session-cleanup/
    │   ├── SKILL.md
    │   └── references/
    │       └── post-session-cleanup-methodology.md
    ├── subagent-orchestration/
    │   ├── SKILL.md
    │   └── references/
    │       ├── model-routing.md
    │       └── subagents.md
    ├── task-graph-orchestration/
    │   ├── SKILL.md
    │   └── references/
    │       └── templates/
    │           └── task-graph.md
    └── worktree-lifecycle/
        ├── SKILL.md
        └── references/
            ├── templates/
            │   └── worktree-manifest.md
            └── worktrees.md
```

---

## Example: Direct Perspective and Bounded Delegation

Most of the time the root applies a perspective itself:

```text
Apply the senior-reviewer perspective to this diff: incomplete behavior,
compatibility paths without a consumer, tests that only describe the approach
we abandoned. Stay in this session, do not launch a subagent, and fix in-scope
findings under the existing task authority.
```

When a separate helper has a concrete benefit worth its cost, it gets a bounded assignment.

Bad:

```text
Look into this and fix it.
```

This comes back confident and probably wrong, and you will not be able to tell which.

Better:

```text
Role:
You are the read-only-explorer subagent for this task.

Goal:
Find where checkout tax is calculated and identify the smallest safe insertion
point for a per-customer exemption flag.

Context:
We are adding tax exemption for B2B customers. The customer record already has
an `accountType` field. Where exemption should live has not been decided.

Scope:
Inspect the checkout, cart, customer, and tax-calculation code paths.

Non-goals:
Do not edit anything. Do not refactor. Do not propose a new tax engine.
Do not evaluate whether exemption is the right feature.

Evidence required:
File paths, function names, the call chain from checkout entry to tax
computation, the tests that cover it, and any existing exemption-like concept.

Acceptance condition:
I can open each path you name and see the symbol you claim is there.

Workspace:
The current workspace. Do not create or request a worktree.

Stop and report if:
Tax logic turns out to live behind a third-party service, or the call chain
depends on runtime configuration you cannot resolve by reading.
```

Dispatched with `model: haiku` on the call, because this is lookup work whose evidence the root will open and check. Judgment work — a review, a diagnosis, an implementation — is dispatched with `model: opus`, and the role's definition supplies `effort: medium`.

The root session still decides the design, accepts or rejects the recommendation, and reviews the final diff itself.

---

## Recommended Workflow

```text
1. Ask your coding agent to install this repository URL.
2. Let the installer configure global instructions, skill packages, and subagents.
3. Add repository-specific CLAUDE.md guidance to each project.
4. Let the root session frame the task, understand the whole affected flow, select
   the skills that apply, and do the work directly by default, consulting a role's
   perspective when that helps; improve what exists before replacing it.
5. Use a helper sparingly, only when its concrete benefit is worth its cost. Pass
   the model chosen for the work on every dispatch — haiku for lookup and
   extraction, opus for judgment — and use the bundled roles so their
   definition's effort applies. The choice never follows the root model, and the
   root's own model, effort, and speed stay as the user set them.
6. Run independent subagents in parallel; sequence only for real dependencies,
   and confirm write ownership is disjoint before running writers concurrently.
7. Keep the auxiliary-worktree budget at zero unless a real isolation need is
   verified. Reconcile every task-created auxiliary before finishing.
8. Use the multi-session coordination skill when other sessions own related work,
   and the feature-branch lifecycle skill when feature work uses development
   branches that have to be integrated, promoted, or cleaned up.
9. At the end of substantial work, run the session-cleanup pass over the whole
   work delta, then verify the final combined diff and integrated behavior
   before accepting.
10. When the work has to continue in a fresh session, use the handoff skill
    rather than resuming or forking the old conversation.
```

---

## Public Repository Notes

This repository is public so others can star it, fork it, adapt it, and propose improvements.

Please keep contributions generic, reusable, and safe for public use. Do not add private project details, internal URLs, sensitive access material, local machine quirks, full session transcripts, or one-off incident logs.

See `CONTRIBUTING.md` for contribution guidance.

---

## License

MIT — see [`LICENSE`](./LICENSE).

---

## Status

This is a living playbook. Treat it as a strong baseline, not a universal law.

The best setup is:

```text
Global behavior + local repository truth + evidence-backed validation
```
