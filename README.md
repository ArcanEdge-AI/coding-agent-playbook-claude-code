<p align="center">
  <img src="./assets/coding-agent-playbook-claude-code-hero.png" alt="Coding Agent Playbook — Claude Code Edition hero banner" width="100%" />
</p>

<h1 align="center">Coding Agent Playbook — Claude Code Edition</h1>

<p align="center">
  <strong>Installable, managed global instructions, subagents, skills, and engineering workflows for Claude Code.</strong>
</p>

<p align="center">
  Configure Claude Code to behave less like a loose autocomplete engine and more like a disciplined senior engineer: orchestrate bounded subagent execution, plan clearly, coordinate parallel work, verify honestly, and ship maintainable code.
</p>

<p align="center">
  <a href="#install-with-one-prompt">Install</a> ·
  <a href="#quick-start">Quick Start</a> ·
  <a href="#harness-editions">Harness Editions</a> ·
  <a href="#why-this-exists">Why This Exists</a> ·
  <a href="#whats-inside">What's Inside</a> ·
  <a href="#subagent-model">Subagent Model</a> ·
  <a href="#formal-task-graph-orchestration">Task Graphs</a> ·
  <a href="#task-local-worktree-lifecycle">Worktrees</a> ·
  <a href="#coordinating-parallel-claude-code-sessions">Parallel Sessions</a> ·
  <a href="#repository-structure">Structure</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Claude%20Code-Edition-6E7BFF" alt="Claude Code Edition" />
  <img src="https://img.shields.io/badge/Subagents-Orchestrated-00C2FF" alt="Subagents Orchestrated" />
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

Follow the repository's INSTALL.md exactly. Use full mode even when an older installation exists; do not infer support-only mode unless I explicitly request it. Preserve my existing instructions, back up anything you change, install the global instructions, references, skills, and custom subagents, then report the installed files and validation results.
```

That is the intended public experience: users should not need to understand the file layout before installation. The agent should read `INSTALL.md`, clone or fetch the repository, install into user-level Claude Code configuration locations under the resolved Claude Code home, validate the result, and report what changed.

Support-only is an explicit pointer-only configuration, not an update mode. Use it only when the user confirms the global instructions already live in their global `CLAUDE.md` manually:

```text
Install this in support-only mode: https://github.com/ArcanEdge-AI/coding-agent-playbook-claude-code

I already added the global custom instructions manually. Follow INSTALL.md, but do not duplicate the full instructions into CLAUDE.md. Install references, skills, and custom subagents only.
```

---

## Quick Start

### Agent install

Ask your coding agent to install the repository URL and follow `INSTALL.md`. Normal installs and updates use full mode.

### Manual install: macOS / Linux / WSL

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

### Manual install: Windows PowerShell

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

### Repository-specific guidance

Copy this template into individual projects as a starting point:

```text
references/templates/repository-CLAUDE.md
```

Save it as `CLAUDE.md` at the project root, then fill in the actual build commands, test commands, architecture rules, generated-file rules, and release expectations for that repository.

---

## Harness Editions

Coding Agent Playbook ships as separate harness-native editions. This repository is the Claude Code edition.

| Edition | Repository | Use when |
| --- | --- | --- |
| Claude Code | `ArcanEdge-AI/coding-agent-playbook-claude-code` | You want global Claude Code instructions, reference docs, skills, and subagent definitions. |
| Codex | [`ArcanEdge-AI/coding-agent-playbook-codex`](https://github.com/ArcanEdge-AI/coding-agent-playbook-codex) | You want the harness-native edition tuned for Codex. |

The philosophy is shared across both: the root agent acts as the senior engineer and orchestrator, subagents perform bounded evidence-backed execution, independent project sessions are coordinated explicitly, and final decisions stay with the root agent.

---

## Why This Exists

AI coding agents are powerful, but they often fail in predictable ways:

- They start coding before understanding the codebase.
- They over-engineer simple requests.
- They refactor unrelated code.
- They trust editor diagnostics over real builds.
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
| Install scripts | `install/` | Manual installers for Unix-like shells and PowerShell. |
| Global instructions | `custom-instructions/` | Tool-agnostic behavior rules for elegant, maintainable code. Paste into your global `CLAUDE.md`. |
| Prompts | `claude-prompts/` | Setup and active-project coordination prompts. |
| Reference docs | `references/` | Claude model and capability routing; finite subagent delegation; task-local worktrees; multi-session coordination; and reusable templates. |
| Skills | `skills/` | Reusable workflows for task-graph, subagent, and worktree orchestration, session coordination, document routing, and senior review. |
| Custom agents | `agents/` | Claude Code definitions for a bounded local orchestrator, direct workers, and non-spawning execution leaves. |
| Repository guidance | `CLAUDE.md` | Instructions for maintaining this public playbook repository. |

---

## Install Modes

### Full install

Use this for normal installs and updates. Full mode is the default and safely replaces the playbook-owned marked section and current managed files.

Full install writes the global instructions into the user's global `CLAUDE.md`, installs references, skills, and custom subagents, and records their paths and hashes in a managed-file manifest. Later updates can back up and retire unchanged files removed upstream while preserving customized or unrelated files.

### Support-only install

Use this only when the user explicitly says the global instructions already live in their global `CLAUDE.md`.

Support-only mode avoids duplicating the full instruction file and installs only the supporting reference docs, skills, and custom subagents.

---

## Core Philosophy

The root Claude Code session is the senior engineer.

It owns:

- understanding the task
- the working plan
- architecture and design judgment
- which work is delegated, to which role, at which model
- coordination with other sessions
- integration and final acceptance
- the final diff
- validation strategy
- the final response

Subagents perform bounded execution. They buy three things — context isolation, parallelism, and independent judgment — and cost you visibility into how the work was done. Delegate for one of the three, and write the assignment so the missing visibility does not matter.

> For repository tasks, delegate at least one bounded piece of execution when subagents are available. Direct root execution is the right call when subagents are unavailable, the user forbids delegation, the action needs authority that must stay with the root, or the task is small enough that delegating costs more than it saves — say which applies.

Subagents share the current workspace by default. The auxiliary-worktree budget is separate and starts at zero. Only the root may authorize worktree isolation, and every task-created auxiliary is either integrated and removed inside the task or preserved with an exact blocker.

---

## Subagent Model

Subagents are focused engineering assistants, not autonomous owners. Definitions live in `agents/` and install to the Claude Code home agents directory; repositories can override them under `.claude/agents/`. Each is Markdown with YAML frontmatter pinning a fail-closed model, a role effort level, `permissionMode`, `tools`, and `disallowedTools`.

| Subagent | Fail-closed model | Normal explicit model | Effort | Permission | Tools | Best for |
| --- | --- | --- | --- | --- | --- | --- |
| `read-only-explorer` | haiku | haiku | low | plan | Read, Grep, Glob | Mapping call paths, call sites, conventions, and insertion points. |
| `docs-researcher` | haiku | haiku | low | plan | Read, Grep, Glob, WebFetch, WebSearch | Verifying library, API, or platform behavior against the installed version. |
| `test-triager` | haiku | sonnet | medium | default | Read, Grep, Glob, Bash, Edit | Reproducing a failure and proving its root cause. Runs suites. |
| `isolated-worker` | haiku | sonnet | medium | default | Read, Grep, Glob, Edit, Write, Bash | Implementing a bounded change whose design is settled. |
| `senior-reviewer` | haiku | sonnet | high | plan | Read, Grep, Glob, Bash | Reviewing a real artifact for defects and risk before acceptance. |
| `local-orchestrator` | haiku | sonnet | high | default | Agent + read/write/web | One slice that genuinely fans out into independent parts. |

### Why every model is `haiku`

Claude Code resolves a subagent's model through a precedence chain, and the losing links are silent:

```text
CLAUDE_CODE_SUBAGENT_MODEL   ← outranks everything, including the call
per-invocation `model`       ← what this playbook uses
frontmatter `model`          ← the fallback
inherit / omitted            ← the main conversation's model
```

Pinning `haiku` in frontmatter means a dispatch that forgets to pass a model fails **closed** — cheap and weak — instead of quietly running everything at the main session's tier. It is a safety net, not the routing decision. The caller passes the model it actually wants on every `Agent` call.

Keep each child at or below the main session's tier (`opus` > `sonnet` > `haiku`), and record what the main session actually is rather than assuming Opus. Equal-tier routing is valid — delegating deeper does not require stepping down.

### Effort is a role property, not an inherited ceiling

`effort` is set in frontmatter and, per the Claude Code subagent contract, **overrides the session effort level**. There is no per-invocation effort argument, so you choose effort by choosing the role.

This matters: a session running at low effort can still dispatch `senior-reviewer` at high effort. That is the point of a review role — the review deserves more thought than the errand that triggered it. Treating effort as a ceiling inherited from the caller would make the review and orchestration roles unreachable from ordinary sessions, which is not how the field works.

### Plan mode cannot run your test suite

`read-only-explorer`, `docs-researcher`, and `senior-reviewer` run in `plan` mode. In plan mode, shell commands outside the built-in read-only set are reviewed by the auto-mode classifier or prompt for approval — and a prompt inside a subagent can stall rather than quietly succeeding.

So `git diff`, `git log`, `git blame`, and file reads are dependable there. `npm test`, `pytest`, `eslint`, `tsc`, and `make` are not. When a review needs a suite executed, that work goes to `test-triager`, which runs in `default` mode.

### Nesting: two layers, enforced by tools

Claude Code allows subagents to spawn their own subagents **by default**, up to three layers below the main conversation. This playbook uses two:

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
references/model-routing.md
references/subagents.md
skills/subagent-orchestration/SKILL.md
```

A good assignment names the role and explicit model, the goal as a verifiable outcome, the context, the scope and non-goals, write ownership for anything that edits, the exact workspace, the required evidence, the acceptance condition, and the stop conditions.

---

## Formal Task-Graph Orchestration

For work with substantial fan-out, genuine dependencies, broad scope, layered consolidation, or separate implementation and verification paths, the playbook can compile an instruction-only task graph before delegation.

The root session owns the graph: the bounded nodes, what each consumes and produces, the dependency edges that are actually real, write ownership, the model for each dispatch, permission and tool boundaries, workspaces, verification gates, and approval gates. Only nodes whose inputs are ready run, and a failure invalidates only the downstream nodes that consumed its output.

Every proposed edge has to survive one question — *can the downstream node begin correctly without an accepted output from the upstream node?* If it can, the edge is narrative order rather than a dependency, and keeping it costs parallelism.

This is a prompt-level coordination contract. It does not add a graph database, scheduler, runner, schema package, or orchestration framework. Keep medium graphs in the working plan. For long-running work, use `.claude/coordination/task-graphs/<task-slug>.md` when repository policy permits a local artifact.

See:

```text
skills/task-graph-orchestration/SKILL.md
references/templates/task-graph.md
```

Run the multi-session coordination workflow first when other Claude Code sessions, branches, worktrees, pull requests, or active-work records may affect the graph's ownership or contracts.

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
references/worktrees.md
references/templates/worktree-manifest.md
skills/worktree-lifecycle/SKILL.md
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
references/multi-session-coordination.md
references/templates/active-work-record.md
references/worktrees.md
skills/multi-session-coordination/SKILL.md
```

The optional active-work record gives repositories a local fallback when complete session-history discovery is unavailable. It is advisory and must be verified against current session and repository evidence.

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
references/model-routing.md
references/reference-doc-routing.md
references/subagents.md
references/multi-session-coordination.md
references/worktrees.md
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
│   └── install.sh
├── references/
│   ├── README.md
│   ├── model-routing.md
│   ├── multi-session-coordination.md
│   ├── reference-doc-routing.md
│   ├── subagents.md
│   ├── worktrees.md
│   └── templates/
│       ├── active-work-record.md
│       ├── api-contracts.md
│       ├── architecture.md
│       ├── data-model.md
│       ├── design-system.md
│       ├── release.md
│       ├── repository-CLAUDE.md
│       ├── security.md
│       ├── task-graph.md
│       ├── testing.md
│       └── worktree-manifest.md
├── scripts/
│   └── validate.sh
└── skills/
    ├── multi-session-coordination/
    │   └── SKILL.md
    ├── reference-doc-routing/
    │   └── SKILL.md
    ├── senior-code-review/
    │   └── SKILL.md
    ├── subagent-orchestration/
    │   └── SKILL.md
    ├── task-graph-orchestration/
    │   └── SKILL.md
    └── worktree-lifecycle/
        └── SKILL.md
```

---

## Example: Better Delegation

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

Dispatched with an explicit `model` — never left to default — and at or below the main session's tier.

The root session still decides the design, accepts or rejects the recommendation, and reviews the final diff itself.

---

## Recommended Workflow

```text
1. Ask your coding agent to install this repository URL.
2. Let the installer configure global instructions, references, skills, and subagents.
3. Add repository-specific CLAUDE.md guidance to each project.
4. Let the root session frame the task, choose what to delegate, and coordinate.
5. Pass an explicit model on every dispatch, at or below the main session's tier.
   Choose the role whose effort fits the work — effort comes from the definition.
6. Run independent subagents in parallel; sequence only for real dependencies,
   and confirm write ownership is disjoint before running writers concurrently.
7. Keep the auxiliary-worktree budget at zero unless a real isolation need is
   verified. Reconcile every task-created auxiliary before finishing.
8. Use the multi-session coordination skill when other sessions own related work.
9. Verify the final combined diff and integrated behavior before accepting.
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
