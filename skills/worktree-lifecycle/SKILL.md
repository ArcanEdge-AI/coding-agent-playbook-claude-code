---
name: worktree-lifecycle
description: Use when Git worktree isolation is being proposed for a Claude Code task, when parallel writers might need filesystem isolation, when a task already owns an auxiliary checkout, or when a task-created worktree must be integrated, preserved, or removed before finishing. Keeps worktree use finite, root-owned, and reconciled inside the task.
---

# Worktree Lifecycle

The default is the current workspace with an auxiliary-worktree budget of zero, and most tasks should end there. A subagent is never a reason to create a worktree.

Full rules: `references/worktrees.md`. Durable ledger: `references/templates/worktree-manifest.md`.

## The thing that bites people

> A subagent with `isolation: worktree` gets a worktree branched **from your repository's default branch, not from the current session's `HEAD`** — unless `worktree.baseRef` is set to `"head"`.

So an isolated subagent can start without the changes you just made, do good work against the wrong base, and hand back something that looks correct and integrates wrong.

Record the expected base ref and exact SHA before dispatch. Verify the actual checkout after creation. Never treat the host default as proof your changes are present.

## Workflow

1. Inspect the current checkout: `git worktree list --porcelain`, the common Git directory, branch or detached HEAD, exact HEAD, dirty state, and any known session ownership.
2. Classify it — **host-managed primary**, **user-managed existing**, or **task-created auxiliary**. The class determines what you may do with it.
3. Keep the budget at zero unless a specific writer needs branch or filesystem isolation that sharing or serializing cannot provide safely.
4. Only the root raises the budget and issues a permit. One active auxiliary needs no extra approval; **two or more require the user's approval** for the exact count and reasons.
5. Record the base ref and exact SHA, and account for `worktree.baseRef`.
6. Reuse a compatible task-owned worktree before creating another. A new subagent or a retry is not a reason to create one.
7. Give every worker an exact workspace and write scope. Descendants never request isolation or create, adopt, repurpose, move, or remove worktrees.
8. Integrate accepted work through the declared target, and validate the combined result in the integration workspace.
9. Before your final response, set every task-created auxiliary to `removed` under verified gates, or `preserved` with an exact blocker.

## Creation gate

Create one only when **all** of these hold:

- repository and common Git directory verified
- base ref and exact SHA recorded
- path and branch explicit or host-assigned, and collision-free
- a concrete write or mutable-state isolation need exists
- sharing, reuse, and serialization are all insufficient
- the budget has capacity and a root permit exists
- ownership, integration target, and cleanup condition recorded

No bundled agent sets `isolation: worktree`, and none carries `EnterWorktree` or `ExitWorktree`. Use isolation only on a root-authorized dispatch.

Not reasons to create one: another subagent exists; work could run in parallel; a node is read-only; a previous attempt failed; a checkout looks old or clean.

## Completion gate

Remove a task-created auxiliary only after verifying:

- exact permit, canonical path, repository identity, owner, branch or HEAD
- accepted work is integrated, or abandonment is explicitly authorized
- tracked, untracked, submodule, and valuable ignored artifacts are accounted for
- no running process, terminal, server, or watcher depends on the checkout
- the work is recoverable through its integration or backup target
- it is not the active checkout and not owned by another session or user

Prefer the supported Claude Code cleanup path when the host owns the auxiliary. Otherwise use non-force `git worktree remove <exact-path>`, then verify both that the path is gone and that it no longer appears in `git worktree list --porcelain`.

**Never** use force removal, `reset`, `clean`, `stash`, broad recursive deletion, or age, inactivity, or clean status alone as authority to delete.

If any gate fails, preserve it and report the canonical path, owner, branch or detached HEAD, exact blocker, and next action. Preserving something you cannot verify is the correct outcome.

## Report

Return a compact ledger: starting worktrees, auxiliary budget, permits issued, workspaces created or reused, integration evidence, final disposition for each (`removed`, `preserved`, `reused`, `host-managed`), and any preserved blocker.

Do not defer task-owned cleanup to scheduled automation, and leave the active host-managed worktree to the host's lifecycle.
