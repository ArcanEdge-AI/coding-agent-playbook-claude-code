# Task-Local Worktree Lifecycle

A Git worktree is an isolation tool. It is not the unit of delegation, and spawning a subagent is not a reason to create one.

The root session owns every worktree decision made inside a task. This document covers when an auxiliary checkout is justified, how to create one safely, and how to reconcile it before the task ends.

## The default

**Start in the current workspace with an auxiliary-worktree budget of zero.**

Most tasks finish there. Read-only subagents share a workspace with no risk at all. Writers with disjoint file ownership share one safely. A task can use a dozen subagents and zero auxiliary worktrees, and usually should.

The auxiliary budget is separate from anything to do with subagent counts. Raising one never raises the other.

## The base-ref trap

This is the specific behavior that makes casual isolation dangerous:

> A subagent with `isolation: worktree` runs in a worktree branched **by default from your repository's default branch — not from the parent session's `HEAD`.**

So an isolated subagent can start without the changes the current session just made. It will then work against the wrong base, and the result will look fine in isolation and be wrong on integration.

The `worktree.baseRef` setting controls this:

```json
{
  "worktree": {
    "baseRef": "head"
  }
}
```

With `"head"`, new worktrees branch from the current `HEAD` instead of the remote default branch.

Because of this, **record the expected base ref and exact SHA before dispatch, and verify the actual checkout after creation.** Do not treat the host's default as proof that the parent's changes are present.

Two related behaviors:

- An isolated worktree that the subagent leaves unchanged is cleaned up automatically. One with changes is yours to integrate and dispose of.
- `isolation` can be passed on an `Agent` call directly, not only in frontmatter. That is why descendants are told never to pass it — the capability exists, so the rule has to be explicit.
- When the main conversation itself runs isolated in a worktree, Claude Code applies the same containment checks to every subagent it spawns, including subagents without `isolation: worktree`.

## Workspace classes

Classify every checkout you touch. The class determines what you are allowed to do with it.

| Class | What it is | What you may do |
| --- | --- | --- |
| **Host-managed primary** | The active workspace, created or managed by the Claude Code CLI, desktop, web, or an IDE integration. | Record it. Never delete the active checkout from inside itself. Leave it to the host's lifecycle. |
| **User-managed existing** | A checkout that predates the task or is owned outside it. | Inspect read-only unless the user or repository evidence grants ownership. Never remove it as task cleanup. |
| **Task-created auxiliary** | Created under a task-local permit, for a declared isolation need. | Integrate, verify, and remove before the final response — or preserve it with an exact blocker. |

## When an auxiliary is justified

All of these are real reasons:

- The user asked for a separate branch or worktree.
- The host or repository workflow requires branch-isolated delivery.
- An independent writer must preserve conflicting in-progress work while starting from a verified base.
- Build, test, generation, or mutable-state behavior genuinely cannot be isolated in the current workspace.
- A long-running write stream needs a stable checkout while integration proceeds elsewhere.

None of these are:

- Another subagent exists.
- Tasks could run in parallel.
- A node is read-only.
- A previous attempt failed.
- A checkout looks old, or its status looks clean and therefore disposable.

Separate checkouts do not resolve design conflicts or merge conflicts. They defer them, usually to a worse moment.

## Authority

Only the root session may raise the worktree budget, issue a worktree permit, authorize an `isolation: worktree` dispatch, use `EnterWorktree`, create or adopt an auxiliary, change its purpose, move it, or remove it.

The root may authorize **one** active auxiliary without additional user approval. **Two or more require user approval** for the exact count and the reason for each.

Descendants use the exact workspace they were assigned. They do not pass `isolation` on child calls, and they do not create, adopt, repurpose, move, or remove worktrees. When a descendant hits a genuine isolation need, it reports upward with the current path, branch, and Git status; the root decides.

Retries reuse the same compatible worktree. A replacement worker does not automatically get a new one.

No bundled agent sets `isolation: worktree`, and none carries `EnterWorktree` or `ExitWorktree`.

## The permit

Before creating or adopting an auxiliary, record:

| Field | Value |
| --- | --- |
| Permit ID | Root-issued, separate from any subagent identifier. |
| Owner | The worker responsible for the checkout. |
| Repository identity | Repository root and common Git directory. |
| Canonical path | Exact absolute path — or the host-assigned path, verified immediately after creation. |
| Base | Base ref **and** exact base SHA. |
| Branch or detached HEAD | The intended Git state. |
| Write scope | Paths or mutable state owned in this workspace. |
| Isolation reason | Why shared execution or serialization is insufficient. |
| Creation path | `isolation: worktree`, `EnterWorktree`, host UI, or an explicit Git command. |
| Integration target | Branch, commit, patch, pull request, or other accepted handoff. |
| Cleanup condition | The evidence that will make removal safe. |
| State | `proposed`, `active`, `integration-ready`, `cleanup-ready`, `removed`, or `preserved`. |

Use `templates/worktree-manifest.md` when the ledger must survive across phases or sessions. For a small task, a few lines in the working plan is enough.

## Creating one

1. Run `git worktree list --porcelain` from the verified repository.
2. Resolve the common Git directory, current branch or detached HEAD, exact HEAD, and dirty state.
3. Check whether another Claude Code session, branch, or worktree already owns this area.
4. Prefer shared execution, serialization, or reusing a compatible task-owned auxiliary. Exhaust those first.
5. Confirm the path does not collide with a registered checkout.
6. Confirm the branch is not checked out elsewhere, and that the base SHA is the one you intend. Set or account for `worktree.baseRef`.
7. Record the permit. Get user approval first if this would make two or more active auxiliaries.
8. Let only the root create it, through supported Claude Code behavior or non-force Git.
9. **Verify the actual result**: canonical path, registration, branch or HEAD, base SHA, and starting status — before assigning any work to it.

Never create one speculatively. Never let a descendant choose an unrecorded path, base, branch, or isolation mode.

## Working in one

- Give every writer an exact workspace and an exact write scope.
- Keep sibling write ownership disjoint even across different checkouts.
- Record HEAD and dirty state at meaningful handoffs.
- Validate the artifact before integrating it.
- Integrate through the declared target, and verify the combined result in the integration workspace — not in the auxiliary.
- Keep the auxiliary until the accepted work is recoverable elsewhere.
- Reuse the same workspace for a retry unless evidence proves it incompatible.

## Cleanup, before the final response

For every task-created auxiliary:

1. Reconfirm canonical path, common Git directory, branch or detached HEAD, exact HEAD, and permit.
2. Confirm its output is integrated, or that abandoning it is explicitly within task authority.
3. Account for tracked files, untracked files, submodules, and valuable ignored artifacts. A short `git status` is not sufficient evidence.
4. Check for running processes, terminals, servers, or watchers depending on the checkout, where the environment can show you.
5. Confirm the work is recoverable through the integration target, a remote, a tag, or an explicit preservation decision.
6. Confirm the target is not the active checkout and is not owned by another session or user.
7. Prefer the supported Claude Code lifecycle when the host owns the auxiliary. Otherwise use non-force `git worktree remove <exact-path>`, targeting only the verified task-created checkout.
8. Prune only stale registration metadata, and never as a substitute for an ownership check.
9. Verify both that the path is gone and that it no longer appears in `git worktree list --porcelain`.
10. Mark the permit `removed`, with evidence.

**Never** use force removal, `reset`, `clean`, `stash`, broad recursive deletion, or age, inactivity, or clean status alone as authority to delete.

If any check is unavailable or ambiguous, mark it `preserved` and report the exact missing evidence or ownership blocker. Preserving something you cannot verify is the correct outcome, not a failure.

Do not defer task-local cleanup to scheduled automation. If your task made it, your task reconciles it.

## Final report

Give every relevant checkout exactly one disposition:

- `removed` — cleanup gates passed; path and registration removal both verified.
- `preserved` — exact path, owner, branch or HEAD, blocker, and next action named.
- `reused` — the task used an existing checkout and did not own its removal.
- `host-managed` — the active workspace, left to the host lifecycle.

Do not describe the task as clean because automation might inspect it later.
