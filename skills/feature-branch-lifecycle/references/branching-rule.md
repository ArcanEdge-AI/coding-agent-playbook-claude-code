# Feature Integration and Promotion Branching Rule

The procedure behind the `feature-branch-lifecycle` skill. Use it for repositories whose delivery model already has a long-lived integration branch and a long-lived production branch.

The examples call them `staging` and `main`. Always resolve the repository's real names, and the more specific instructions that govern them, before you act on anything here.

## The structure

Where this lifecycle applies, feature, change, or update work that may use one or more development branches follows this structure:

```text
production branch
        ↑
integration branch
        ↑
feature integration branch
        ↑
development branches
```

Read it upward: individual work stays isolated, related work combines before it reaches a long-lived branch, and what moves toward production is a complete reviewable unit.

## 1. Establish the branch model

Before creating any branch:

1. Read the applicable `CLAUDE.md` and any release or contribution documentation.
2. Identify the exact integration and production branches. Do not assume `main` is production, or that a default branch is an integration branch.
3. Verify current remote state where you are authorized and able to — a stale local view is how a branch gets cut from the wrong base.
4. Inspect active branches, open pull requests, their owners, and any worktrees that overlap what you are about to touch.
5. Confirm the repository has actually selected this lifecycle.

If it has not, stop here. Do not create a missing integration branch, rename a permanent branch, or displace an incompatible workflow without an explicit maintainer decision.

## 2. Create the feature integration branch

Cut one dedicated feature integration branch from the current integration branch.

```text
staging
  └── feature/project-permissions
```

This branch is the shared assembly and validation point for the complete feature, change, or update. Everything the feature needs lands here before anything is promoted.

## 3. Create development branches, if they help

Cut individual development branches from the feature integration branch, each scoped to a specific implementation outcome where that is practical.

```text
feature/project-permissions
  ├── dev/add-role-model
  ├── dev/update-api-permissions
  ├── dev/update-permissions-ui
  └── dev/add-permission-tests
```

A development branch merges only into its feature integration branch. It never merges directly into a long-lived integration or production branch.

Skip this step when one branch implements the feature cleanly. The feature integration branch remains the promotion unit regardless.

## 4. Integrate and validate the complete feature

Bring the finished development branches into the feature integration branch. Resolve conflicts there, and validate the combined behavior there.

Validation is proportional to the repository and the change. Consider:

- build validation
- automated tests
- lint, format, typecheck, and static analysis
- contract and integration tests
- end-to-end or manual verification
- a final review of the combined diff
- explicit confirmation that no required development work is still outstanding

Do not use the long-lived integration branch as the workspace for assembling an unfinished feature. A passing subset of checks does not establish that the assembled feature is correct; report what ran, what it produced, and what did not run.

## 5. Promote to the integration branch

Once complete-feature validation passes, open one pull request from the feature integration branch to the long-lived integration branch.

```text
feature/project-permissions
        ↓
      staging
```

Development branches belonging to the feature are not promoted independently. Creating, approving, and merging that pull request remain subject to the task's authority and the repository's review gates.

## 6. Verify cleanup eligibility

Cleanup starts only after the promotion pull request has merged successfully into the exact integration branch.

Immediately before deleting any branch, verify every applicable gate:

| Gate | What counts as evidence |
| --- | --- |
| The expected pull request merged into the exact integration branch | The merge state of that pull request, against that branch by name |
| The expected commits, or an equivalent patch, are present there | The commits or content actually reachable from the integration branch |
| Required checks passed against the accepted result | Check results on the merged state, not on the branch before merge |
| The branch holds no unique work that still needs preserving | A comparison, not an assumption that everything was merged |
| Nothing still depends on it | No open pull request, active task, person, automation, or release process |
| No active worktree has it checked out | The worktree list, resolved against the branch name |
| The exact local and remote deletion targets are resolved | Named refs, not a pattern or a guess |
| Authority exists for each local and remote deletion | The task's actual authority, per target |

A clean working tree, an old timestamp, an inactive-looking branch, or a name that resembles something merged is not sufficient evidence.

If any gate fails, preserve the branch and report the exact blocker and the next action.

## 7. Clean up temporary branches

After every gate passes:

1. Remove the completed development branches, locally and remotely.
2. Remove the feature integration branch, locally and remotely.
3. Verify the intended branches are gone and the permanent branches remain.

Never delete a long-lived integration or production branch. Never use force deletion, reset, a broad cleanup sweep, or history rewriting as a shortcut.

The lifecycle creates an eventual cleanup requirement. It does not by itself authorize a destructive local or remote action. When the current request does not authorize deletion, report exactly which branches are ready and ask for direction.

## 8. Promote to production

When the accepted integration-branch state is ready and production promotion is explicitly authorized, open one pull request from the integration branch to the production branch.

```text
staging → main
```

Never promote a development or feature integration branch directly to production. The integration branch stays permanent after the release.

Production promotion is a separate release action. A request to implement, validate, or integrate a feature does not implicitly authorize it.

## Completion contract

The lifecycle is complete when:

- every required piece of development work is incorporated into the feature integration branch
- complete-feature validation passes, and what ran is reported honestly
- one accepted pull request incorporates the feature into the integration branch
- every temporary branch has a verified disposition: removed under passing gates and real authority, or preserved with an exact blocker and next action
- production promotion, where it is in scope at all, happened only from the integration branch through authorized review

```text
dev/task-a ──┐
dev/task-b ──┼──→ feature integration ── one PR ──→ staging
dev/task-c ──┘                                       │
                                                  cleanup
                                                     │
                                            authorized release
                                                     │
                                                  one PR
                                                     ↓
                                                    main
```
