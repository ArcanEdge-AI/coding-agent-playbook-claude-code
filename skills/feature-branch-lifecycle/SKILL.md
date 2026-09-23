---
name: feature-branch-lifecycle
description: Use when a feature, change, or update may use one or more development branches and has to be assembled, validated, promoted through long-lived integration and production branches, and cleaned up safely. Covers branch-model detection, the promotion sequence, complete-feature validation, the gates that must pass before any temporary branch is deleted, and the authority each step needs. Not for worktree isolation, session ownership, or dependency planning.
---

# Feature Branch Lifecycle

Keep feature assembly out of long-lived branches, and make promotion and cleanup explicit rather than assumed.

**Read `references/branching-rule.md`, packaged with this skill, before you create the branch structure, open a promotion pull request, or delete anything.** This file is the decision surface; that one is the procedure.

## First, decide whether the model applies

This lifecycle is for repositories that already run a long-lived integration branch and a long-lived production branch. Before using it, resolve from the repository itself:

- the applicable `CLAUDE.md` and any release or contribution documentation
- the default branch, the current branch, and which branches are the integration and production branches
- remotes, open pull requests, branch protections, and worktrees
- active work that may still depend on a branch you would touch

Use the repository's real branch names. The examples here say `staging` and `main` because they are easy to read, not because they are correct anywhere.

If the repository has no such model, **do not create one because this skill is installed.** Follow the more specific repository workflow, or ask for a maintainer decision. Inventing a missing long-lived branch, renaming a permanent branch, or overriding an incompatible workflow is a maintainer's call, not yours.

## The sequence, when it applies

```text
development branches
        ↓
feature integration branch
        ↓
long-lived integration branch, for example staging
        ↓
long-lived production branch, for example main
```

| Invariant | Why it exists |
| --- | --- |
| The feature integration branch is cut from the current integration branch. | It starts from what is actually released next, not from a stale base. |
| Development branches are cut from the feature integration branch. | They combine cleanly, because they share the feature's base. |
| A development branch merges only into its feature integration branch. | A half-feature never reaches a long-lived branch. |
| The complete feature is assembled and validated on the feature integration branch. | The long-lived integration branch is not a workspace. |
| One pull request promotes the feature integration branch to the integration branch. | The promotion unit is the whole reviewable feature. |
| Production is promoted only from the integration branch, under separate authority. | Release is its own decision. |
| Permanent integration and production branches are never deleted. | They are the repository, not task scaffolding. |
| Every temporary branch ends with a verified disposition. | Removed under passing gates, or preserved with an exact blocker. |

Development branches are optional. When one feature integration branch implements the whole feature cleanly, use just that. The feature integration branch stays the promotion unit either way.

## Before promoting, validate the whole feature

Run what the repository and the change actually warrant: build, tests, lint, format, typecheck, static analysis, contract and integration tests, end-to-end or manual checks, and a final review of the combined diff. Then confirm no required development work is still outstanding.

A passing subset is not evidence that the assembled feature works. Say what you ran and what it produced, and name anything you did not run.

## Cleanup is gated, and the gates are not optional

Cleanup begins only after the promotion pull request has merged into the exact long-lived integration branch. Immediately before deleting any branch, verify every gate in the packaged reference: incorporation, required checks, no unique unpreserved work, no remaining dependency, no active worktree holding it, exact local and remote targets, and authority for each deletion.

A clean working tree, an old date, quiet activity, or a name that looks merged is not evidence.

When a gate fails or the deletion is not authorized, preserve the branch and report the exact blocker and the next action. Never force-delete, reset, sweep broadly, or rewrite history to get there.

## This skill's boundary

The sequence tells you what order things must happen in. It grants no authority of its own. Creating remote branches, opening or merging pull requests, deleting local or remote branches, and promoting production each need the authority the task actually carries. A request to build or integrate a feature is not a request to release it.

## Route these elsewhere

| Concern | Skill |
| --- | --- |
| A branch is checked out in an auxiliary worktree, or a checkout needs isolating, integrating, or removing | `worktree-lifecycle` |
| Independent Claude Code sessions or other people own related branches | `multi-session-coordination` |
| Integration, validation, promotion, and cleanup are nodes in a wider dependency graph | `task-graph-orchestration` |

A branch is not a worktree, a branch is not a session, and a feature integration branch is not automatically a graph node. Keep the lifecycles separate.

## What to report

- the resolved branch roles and their exact names
- each temporary branch, with its base and its permitted merge target
- the complete-feature validation you ran, and its results
- pull-request and merge state
- cleanup eligibility and the final disposition of every temporary branch
- any missing authority, failed gate, or live dependency that forced preservation
