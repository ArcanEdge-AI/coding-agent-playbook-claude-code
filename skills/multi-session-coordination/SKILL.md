---
name: multi-session-coordination
description: Use when several independent Claude Code sessions are working on related areas of the same project and someone has to hold the whole picture — discovering what is in flight, detecting incompatibilities beyond merge conflicts, assigning ownership of shared contracts, sequencing the work, and planning integration. Not for ordinary subagent delegation within one session.
---

# Multi-Session Coordination

Subagents report to you. **Independent sessions do not.** Each has its own history, branch, assumptions, and sense of ownership, and nobody is holding the whole picture until you do.

The failure this skill exists to prevent is not a merge conflict. It is two sessions each doing correct work against different assumptions about a shared contract, both passing their own tests, and Git merging them cleanly into something broken.

Detailed rules: `references/multi-session-coordination.md`. Worktree rules: `references/worktrees.md`.

## Use this when

- Multiple Claude Code sessions are active on the same project or repository.
- Several features are being implemented concurrently.
- Branches or worktrees may overlap.
- Shared APIs, schemas, types, components, dependencies, or user flows are changing.
- One session's work could invalidate another's assumptions.
- The user asks you to coordinate, reconcile, integrate, or review parallel work.

**Do not** use it when only one implementation session is active, the task is ordinary subagent delegation, the work spans unrelated repositories, the user wants a review of one finished change, or the evidence is too thin to compare anything meaningfully.

## Ask the other sessions before inferring

Where cross-session messaging is enabled, this beats reconstruction from artifacts:

- **`ListAgents`** enumerates the sessions and agents you can reach, labeled by kind.
- **`SendMessage`** sends to one by name — so you can ask what a session owns and what it assumed, instead of guessing from its commits.

Two caveats: `crossSessionInbound` can restrict delivery, and some session kinds receive without being able to reply. Check what a row supports rather than assuming a round trip. When messaging is unavailable, use artifact-based discovery and label the evidence accordingly.

## Session naming

```text
Project - Three-to-Four-Word Description
```

Detect the project from the directory or repository; derive the description from the primary objective. No literal square brackets. Do not ask the user for a name when the project and task are clear, and do not rename existing sessions unless asked for cleanup.

```bash
claude -n "Project - Three-to-Four-Word Description"   # at launch
/rename Project - Three-to-Four-Word Description        # mid-session
```

If you cannot rename the session yourself, return the exact name and command rather than claiming it happened.

## Workflow

### 1. Resolve the operating context

Identify the project directory, repository, default branch, active branch, worktree, the applicable `CLAUDE.md` and authoritative docs, and the Claude Code home if session-history inspection is needed and permitted.

Do not ask the user for anything you can detect reliably.

Classify every relevant checkout as **host-managed primary**, **user-managed existing**, or **task-created auxiliary**, and record ownership and permits where known. Never infer cleanup authority from age, inactivity, or a clean status.

### 2. Discover what is in flight

Start with reachable sessions via `ListAgents` where messaging is enabled, then sessions active in the previous 72 hours where history is accessible.

Then inspect: sessions for this project directory, sessions in other worktrees of the same repository, active branches, worktrees, open pull requests, unmerged commits, and any active-work records under `.claude/coordination/active-work/`.

**Repository state outranks session recency.** Include older work when evidence shows it is still unmerged, incomplete, blocked, contract-relevant, or otherwise active. Exclude work that is unrelated, fully merged and no longer decision-relevant, abandoned, or exploratory and never adopted.

Ask for a specific session name only when discovery is materially incomplete *and* the gap affects a safe integration decision.

### 3. Label every piece of evidence

- **Directly reviewed session** — you inspected the session or transcript.
- **Direct session report** — you asked it and it answered.
- **Session-metadata inference** — identified from name, activity, branch, or worktree metadata only.
- **Repository-inferred work** — identified from branches, commits, diffs, PRs, tests, files.
- **User-supplied** — the user told you.
- **Potentially missing** — evidence suggests work you cannot reach.

Never claim you reviewed a session when you inspected only its branch, PR, or diff. Coordination advice built on unlabeled inference is how two sessions get told they are compatible when nobody checked.

### 4. Build the shared change map

Per work item: session name and identifier, evidence label, objective, status, last activity, project directory, branch or worktree, worktree class and permit, files and modules affected, APIs/events/routes/interfaces affected, schemas and migrations affected, dependencies changed, upstream artifacts or decisions it needs, tests affected, verification gates, assumptions, unmet dependencies and blockers, open decisions, integration status.

Keep confirmed facts visibly separate from inference.

### 5. Detect conflicts — all seven kinds

Merge conflicts are the easiest to find and the least dangerous.

- **File and ownership** — two sessions editing one file; two owning a module; a refactor reaching into another's area.
- **Architecture** — competing abstractions for one responsibility; incompatible state management; independent redesigns of a shared subsystem.
- **Contract** — incompatible request/response shapes; conflicting shared types; disagreeing event payloads; one session on an outdated contract.
- **Data** — incompatible migrations; conflicting schema assumptions; duplicate persistence models; an unexpected destructive change.
- **Dependency** — incompatible versions; two libraries for one job; changed build or runtime requirements.
- **Behavioral** — one feature changes a flow another relies on; auth behavior disagrees; two features work alone and fail together.
- **Validation** — tests encoding incompatible assumptions; invalidated fixtures or snapshots; nothing covering the combined workflow.

### 6. Assign ownership and sequence

State explicitly: one owner per shared file, contract, schema, or coupled area; who continues independently; who pauses; what must finish first; who rebases or moves to a separate worktree; which contract is settled before implementation continues; who adapts to an established interface; the integration checkpoints; and the remaining chain of blocking work.

Prefer the smallest safe coordination change. Never allow independent redesigns of the same shared subsystem. Never say only "coordinate with the other session."

### 7. Resolve disagreements with primary evidence

1. Current `CLAUDE.md` and authoritative project docs
2. Current code, tests, schemas, configuration, runtime behavior
3. Explicit user decisions
4. Established shared contracts already in use
5. The smallest safe compatible change

Ask the user only when the remaining decision materially affects architecture, behavior, data, safety, release timing, or user-visible output.

### 8. Write copy-ready instructions per session

What may continue; what must pause; owned paths; prohibited paths; required contracts; upstream dependencies; compatibility changes; validation to run; evidence to return; the condition for integration-ready.

Include the resume target when useful: `claude --resume "Session Name"`.

### 9. Define integration verification

Match the combined blast radius: targeted tests per feature, contract tests, schema and migration checks, typechecking, build validation, integration tests, end-to-end flow checks, and a final combined diff review.

**Inspect the combined result yourself** before declaring the work compatible.

Reconcile every task-created auxiliary worktree before the final response — removed after verified gates, or preserved with exact ownership and blocker. Do not defer to scheduled automation, and never remove a host-managed, user-managed, or other session's worktree.

## Output

- Executive summary
- Discovery coverage
- Active session and work summary
- Shared change map
- Conflict and overlap matrix
- Ranked risks: Critical / High / Medium / Low
- Recommended implementation order
- Copy-ready instructions per session
- Integration verification checklist
- Open decisions requiring user approval

## Stop conditions

Stop and report the limitation when the project directory or repository cannot be identified safely, relevant sessions are inaccessible and repository evidence cannot compensate, a destructive or production-affecting change needs approval, or two plausible resolutions materially differ and primary evidence does not settle it.

**Do not implement code unless the user explicitly asks.** This skill's default role is coordination, conflict detection, sequencing, and integration planning.
