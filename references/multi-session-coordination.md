# Coordinating Independent Claude Code Sessions

Subagents are dispatched from one session and report back to it. **Independent sessions are different**: each has its own conversation history, its own branch or worktree, its own assumptions, and its own sense of what it owns. Nobody dispatched them, and nobody is holding the whole picture.

This document is for the session that has to hold the whole picture.

## Subagent delegation vs. session coordination

| | Subagent delegation | Session coordination |
| --- | --- | --- |
| Relationship | One root dispatches and verifies | Peers with independent histories |
| Control | You wrote the assignment | You did not |
| Evidence | You set the acceptance condition | You reconstruct what happened |
| Failure mode | A bad result you can reject | Two correct implementations that are incompatible |

The dangerous failure is the second one. Two sessions each do good work against different assumptions about a shared contract, both pass their own tests, and the combination is broken. Git will merge it cleanly.

## When to use this

Use it when:

- Multiple Claude Code sessions are active on the same project or repository.
- Several features are being implemented concurrently.
- Active branches or worktrees may overlap.
- One feature may invalidate another's assumptions.
- Shared APIs, schemas, types, components, dependencies, or user flows are changing.
- The user asks you to coordinate, reconcile, integrate, or review parallel work.

Do not use it when only one implementation session is active, the work spans unrelated repositories, a normal bounded subagent assignment would do, the user wants a review of one finished change, or the available evidence is too thin to compare anything meaningfully.

## Principles

1. **Repository state outranks session recency.** What is committed, branched, and open beats what somebody was doing recently.
2. **Recent activity finds candidates; it does not prove relevance.**
3. **A reviewed transcript beats an inferred work item.** Say which you have.
4. **Avoid write-heavy parallel work in the same files or tightly coupled areas.**
5. **Every shared contract gets exactly one owner.**
6. **Resolve conflicts with primary evidence, not with the more confident summary.**
7. **Never claim you reviewed a session when you only looked at its branch or diff.**
8. **The goal is behavioral compatibility, not a clean merge.**
9. **A worktree is not disposable until its owner and lifecycle are verified.**

## Talking to other sessions directly

Where cross-session messaging is enabled, this is far better evidence than inference from artifacts:

- **`ListAgents`** enumerates the sessions and agents you can reach — local sessions on this machine, teammates, and cloud sessions, each labeled by kind.
- **`SendMessage`** sends to one by name, so you can ask a session what it owns and what it assumed instead of reconstructing it from its commits.

Prefer asking over inferring when the channel exists. Two caveats: the `crossSessionInbound` setting can restrict delivery, and some session kinds receive a message without being able to reply — check what a row actually supports rather than assuming a round trip.

When messaging is unavailable, fall back to the artifact-based discovery below and label the evidence accordingly.

## Session naming

Name new project sessions:

```text
Project - Three-to-Four-Word Description
```

Examples:

```text
ArcLedger - Validate Billing Evidence
LoreBound - Implement Campaign Imports
United Tradesmen - Coordinate Scheduler Changes
```

Rules:

- Detect the project name from the current directory or repository.
- Derive the description from the session's primary objective.
- Use wording that distinguishes this session from the other active work.
- No literal square brackets.
- Do not ask the user for a name when the project and objective are already clear.
- Do not rename existing sessions unless the user asks for cleanup.

Claude Code's native controls:

```bash
claude -n "Project - Three-to-Four-Word Description"   # at launch
/rename Project - Three-to-Four-Word Description        # mid-session
```

`--name` also sets the terminal title and makes the session resumable by name with `claude --resume "<name>"`. If another live session on the machine already uses the name, Claude Code applies a variant.

If you cannot rename the current session yourself, return the exact recommended name and the `/rename` command rather than claiming the rename happened.

## Discovery

Work outward from what you can verify:

```text
Current project directory
    ↓
Current repository and worktree
    ↓
Reachable sessions via ListAgents, where cross-session messaging is enabled
    ↓
Sessions active in the previous 72 hours
    ↓
Sessions in other worktrees of the same repository
    ↓
Active branches, pull requests, and unmerged commits
    ↓
Older sessions referenced by active work
    ↓
Specific session names or identifiers, only when you must ask
```

72 hours is the default initial window. Do not make the user configure it.

Session evidence may come from the current conversation, session metadata and transcripts under the Claude Code home project-history directory, the `/resume` picker or an equivalent desktop/web/IDE history, session names and last-activity times, branches and worktrees, pull requests and diffs, and optional active-work records under `.claude/coordination/active-work/`.

Read only the metadata and transcript portions you need for coordination. Do not copy unrelated conversation content into a report.

**Include older work** when evidence shows it still has an active branch or worktree, unmerged commits, an open pull request, an incomplete implementation, an unresolved architectural decision, a shared contract in current use, or a dependency affecting current work.

**Exclude work** that is unrelated to this repository, fully merged and no longer decision-relevant, abandoned with no remaining contract impact, or exploratory and never adopted.

Do not include a session merely because it was recently active.

## Classify every piece of evidence

State which of these applies to each work item, every time:

- **Directly reviewed session** — you inspected the session or its transcript.
- **Direct session report** — you asked the session via `SendMessage` and it answered.
- **Session-metadata inference** — you identified it from name, activity, project, branch, or worktree metadata, without reviewing enough content to verify its plan.
- **Repository-inferred work** — you identified it from branches, worktrees, commits, diffs, pull requests, tests, or project files.
- **User-supplied** — the user told you.
- **Potentially missing** — evidence suggests related work you cannot reach.

Coordination advice built on unlabeled inference is how two sessions get told they are compatible when nobody checked.

## The shared change map

For each relevant work item, record:

- session name and identifier, when available
- evidence classification
- stated objective
- last known activity
- project directory and repository
- branch or worktree
- worktree class and task-local permit, where applicable
- current status
- files and modules affected
- APIs, events, routes, or shared interfaces affected
- schemas, migrations, or persistence affected
- dependencies added or changed
- upstream artifacts or decisions required before it can start or integrate
- tests added, changed, or invalidated
- integration verification gates
- assumptions
- unmet dependencies and other blockers
- open decisions
- merge or integration status

Keep confirmed facts visibly separate from inference.

When a task proposes or owns an auxiliary worktree, consult `worktrees.md`. A coordinating session may clean only auxiliaries its own task created or explicitly adopted. Host-managed, user-managed, and other-session worktrees stay preserved unless ownership transfers on primary evidence.

## Conflict categories

Overlapping file edits are the easiest kind to find and the least dangerous. Check all seven.

**File and ownership** — two sessions editing one file; two sessions owning a module; a broad refactor reaching into another session's area.

**Architecture** — competing abstractions for one responsibility; incompatible state-management approaches; independent redesigns of a shared subsystem; changes that bypass an established boundary.

**Contract** — incompatible request or response shapes; conflicting shared types; event names or payloads that disagree; one session building against an outdated contract.

**Data** — incompatible migrations; conflicting schema assumptions; duplicate persistence models; a destructive change another feature does not expect.

**Dependency** — incompatible package versions; two libraries for one job; changed build, runtime, or environment requirements.

**Behavioral** — one feature changes a flow another relies on; authentication or authorization behavior disagrees; error handling, validation, or lifecycle assumptions conflict; two features work alone and fail together.

**Validation** — tests encoding incompatible assumptions; one session invalidating another's fixtures or snapshots; no test covering the combined workflow; separate suites green while the integrated system is broken.

## Ownership and sequencing

Decide and state explicitly:

- one owner for each shared file, contract, schema, or tightly coupled area
- which sessions may proceed independently
- which must finish first
- which must pause, rebase, or move to a separate worktree
- which shared interface must be agreed before implementation continues
- which implementation adapts to an already-established contract
- the integration checkpoints
- the validation required before the next dependent change starts
- the remaining chain of blocking work that controls when integration can finish

Never tell sessions merely to "coordinate." Name the ownership, dependency, contract, or sequencing decision.

## Resolving conflicts

In order:

1. Current `CLAUDE.md` instructions and authoritative project documentation
2. Current code, tests, schemas, configuration, and runtime behavior
3. Explicit user decisions
4. Established shared contracts already in use
5. The smallest safe change that preserves compatibility

Ask the user when both approaches are plausible and the choice materially affects architecture, behavior, data, safety, release timing, or user-visible output.

Do not ask when the repository already answers it, one option is clearly incompatible with current code or tests, it is a minor implementation detail, or a safe default is documented.

## Instructions for each session

Give each active session copy-ready guidance covering what may continue, what must pause, what it owns, what it must not modify, which contracts it must follow, what it must wait for, the changes needed for compatibility, the validation it must run, the evidence it must return, and the condition for calling its work integration-ready.

Include the resume target when useful:

```bash
claude --resume "Session Name"
```

## What to return

1. **Executive summary** — overall compatibility and immediate concern level.
2. **Discovery coverage** — what was directly reviewed, reported by a session, inferred from metadata, inferred from the repository, user-supplied, or potentially missing.
3. **Active work summary** — objective, status, branch or worktree, and affected systems per item.
4. **Shared change map** — ownership, dependencies, contracts, validation impact.
5. **Conflict and overlap matrix** — all seven categories.
6. **Ranked risks** — Critical / High / Medium / Low, each with evidence and a resolution.
7. **Implementation order** — the safest completion and integration sequence.
8. **Instructions for each session** — precise and copy-ready.
9. **Integration verification checklist** — targeted and combined validation.
10. **Open decisions** — only the ones that genuinely need a human.

## Optional repository coordination records

A repository may keep advisory records under:

```text
.claude/coordination/active-work/
```

Start from `templates/active-work-record.md`. In that record, `dependencies` names required upstream artifacts or decisions, `blocked_by` lists the unsatisfied ones, `owned_paths` records write ownership, and `validation_required` defines the gates for integration-ready status. Do not add synonymous fields without a concrete consumer.

These records are aids, not truth. Verify them against current session evidence, Git state, code, tests, and pull requests before relying on them. Do not require every repository to adopt the directory.

Task-created auxiliary worktrees are reconciled inside the owning task — integrated and removed when the gates pass, or preserved with exact path, owner, branch or HEAD, blocker, and next action. A broader stale-worktree sweep is a different workflow, and it never supplies missing ownership evidence.

## Capability limits

Session discovery differs across the CLI, desktop, web, and IDE integrations. Local, remote, and other-client sessions may not share one reachable history, and cross-session messaging may be restricted or disabled.

When discovery is incomplete:

1. Inspect whatever is accessible — metadata, branches, worktrees, commits, diffs, pull requests, active-work records.
2. Report what was inferred rather than reviewed.
3. Name the missing context that could change an integration decision.
4. Ask only for the specific session name, identifier, or summary that would close the gap.

Never imply complete coverage when relevant sessions may be inaccessible.
