# Worktree Manifest: [Task Name]

Use this template only when a task creates, adopts, or coordinates auxiliary Git worktrees. Keep a small ledger in the working plan when a repository artifact is unnecessary.

## Task Context

- Root owner: [Root Claude Code session]
- Repository root: [Verified path]
- Common Git directory: [Verified path]
- Primary workspace: [Canonical path]
- Primary workspace class: [Host-managed primary / user-managed existing]
- Auxiliary-worktree budget: [Finite count; default 0]
- User approval for two or more active auxiliaries: [N/A or exact approval]
- Applicable `CLAUDE.md` instructions: [Paths]

> **Record the base ref deliberately.** A subagent with `isolation: worktree` gets a worktree branched from the repository default branch, **not** from the parent session's `HEAD`, unless `worktree.baseRef` is set to `"head"`. Verify the actual checkout after creation rather than trusting the host default — otherwise a worker starts without the changes the current session just made.

## Permit Ledger

| Permit | Node or owner | Canonical path | Base ref and SHA | Branch or HEAD | Write scope | Isolation reason and creation path | Integration target | Cleanup condition | State |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| W1 | [Owner] | [Exact path] | [Ref and SHA] | [Branch or detached SHA] | [Paths/state] | [`isolation: worktree`, `EnterWorktree`, host UI, or Git; why sharing fails] | [Accepted handoff] | [Required evidence] | proposed |

Allowed states: `proposed`, `active`, `integration-ready`, `cleanup-ready`, `removed`, or `preserved`.

Only the root issues permits or changes the budget. Descendants may report isolation needs but must not create, adopt, repurpose, move, or remove worktrees or set `isolation: worktree` on child invocations.

## Handoff and Integration

| Permit | Produced artifact or commit | Acceptance evidence | Integrated into | Combined validation |
| --- | --- | --- | --- | --- |
| W1 | [Artifact] | [Evidence] | [Target] | [Command/result] |

## Cleanup Ledger

| Permit | Tracked/untracked/submodules accounted for | Ignored artifacts checked | Processes checked | Recoverability verified | Path and registration verified absent | Final disposition or blocker |
| --- | --- | --- | --- | --- | --- | --- |
| W1 | [Yes/evidence] | [Yes/evidence] | [Yes/evidence] | [Yes/evidence] | [Yes/evidence or N/A] | [removed / preserved with exact blocker] |

## Completion Check

- Every task-created auxiliary permit has a final disposition: [Yes / No]
- No descendant created, moved, or removed a worktree: [Confirmed / Exception]
- Retries reused their compatible workspace: [Yes / N/A]
- Integrated behavior was validated from the integration workspace: [Yes / No]
- Preserved worktrees name exact owner, path, branch or HEAD, blocker, and next action: [Yes / N/A]
- Cleanup completed inside the task rather than being deferred to scheduled automation: [Yes / No]
- Active host-managed worktree remains under the host lifecycle: [Yes / N/A]

Do not store credentials, sensitive access material, private local paths in committed public examples, full transcripts, or long logs.
