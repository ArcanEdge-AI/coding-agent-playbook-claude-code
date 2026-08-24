---
description: Coordinate all active work for the current project across parallel Claude Code sessions, branches, worktrees, and pull requests.
argument-hint: "[optional constraints, e.g. 'prioritize billing' or 'planning only']"
---

Coordinate all active work for the current project.

Use the `multi-session-coordination` skill and consult `references/multi-session-coordination.md`. Consult `references/worktrees.md` if any participating task owns or proposes an auxiliary worktree.

Detect the project directory, repository, default branch, active branch, worktree, and applicable CLAUDE.md instructions from the environment. Do not ask for anything you can determine reliably yourself.

Where cross-session messaging is enabled, use `ListAgents` to see which sessions you can reach and `SendMessage` to ask them directly what they own and what they assumed. A session's own answer is stronger evidence than reconstruction from its commits. Note that inbound delivery can be restricted by settings and that some session kinds receive without being able to reply — check what each row supports rather than assuming a round trip.

Where messaging is unavailable, fall back to session metadata, branches, worktrees, pull requests, commits, diffs, tests, and any active-work records — and label the evidence accordingly.

Use `Project - Three-to-Four-Word Description` for new session names. Detect the project name and derive the description from the primary objective. No literal square brackets, and do not ask for a name when the project and task are already clear. If you cannot rename the current session yourself, return the exact recommended name and `/rename` command rather than claiming the rename happened.

Begin with sessions active in the previous 72 hours where session history is accessible. Include older work when evidence shows it remains unmerged, incomplete, blocked, contract-relevant, or otherwise active. Repository state outranks session recency.

Label every work item explicitly as a directly reviewed session, a direct session report, session-metadata inference, repository-inferred work, user-supplied, or potentially missing. Do not claim you reviewed a session when you inspected only its branch, pull request, or diff.

Classify relevant checkouts as host-managed primary, user-managed existing, or task-created auxiliary. Do not infer cleanup authority from age, inactivity, or a clean status. Each owning task integrates and removes its own auxiliaries when the gates pass, or preserves them with exact path, owner, branch or HEAD, blocker, and next action. Do not defer that to scheduled automation, and do not remove a host-managed, user-managed, or other session's worktree.

Build a shared change map and find conflicts across all seven categories, not just Git merge conflicts: file and ownership, architecture, contract, data, dependency, behavioral, and validation. The dangerous case is two sessions doing correct work against different assumptions about a shared contract, both passing their own tests, merging cleanly, and being broken together.

For each dependency, distinguish a software or service dependency from a required upstream work artifact or decision. Identify unmet blockers, the integration verification gates, and the remaining chain of blocking work that controls when integration can finish.

Assign one owner for each shared file, contract, schema, or tightly coupled area. Recommend the safest implementation order, say which sessions should continue and which should pause, and give copy-ready instructions for each active session. Never tell a session merely to "coordinate with" another one — name the exact ownership, dependency, contract, or sequencing decision.

Return:

1. Executive summary
2. Discovery coverage
3. Active session and work summary
4. Shared change map
5. Conflict and overlap matrix
6. Ranked integration risks (Critical / High / Medium / Low, each with evidence)
7. Recommended implementation order
8. Copy-ready instructions for each session
9. Integration verification checklist
10. Open decisions requiring approval

Do not implement changes unless explicitly asked. Do not claim complete coverage when relevant session context is inaccessible — say what is missing and what it could change. Ask for a specific session name or identifier only when the missing context genuinely prevents a safe coordination decision.

Additional constraints from the user, if any: $ARGUMENTS
