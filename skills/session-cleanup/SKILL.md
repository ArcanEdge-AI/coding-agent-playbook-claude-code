---
name: session-cleanup
description: Use at the end of substantial coding work — a long session, several compactions, many commits, interrupted runs, or work done by more than one agent or session — and whenever the user asks for a final cleanup or integrity pass. Reconstructs the complete work delta from the repository against a verified integration baseline, removes in-scope debris, abandoned approaches, speculative compatibility code, and unnecessary complexity, preserves unrelated changes, runs the project's own checks, and reports the final state honestly. Not an audit after every edit, and not authority for destructive cleanup, commits, branch deletion, or worktree removal.
---

# Session Cleanup

The final codebase should keep the required implementation, not the history of how you reached it. Long work leaves debris — a debug log, an abandoned helper, a compatibility shim for an interface that never shipped — and a conversation that has been compacted keeps a summary, not a record of all of it.

So the cleanup boundary comes from the repository, never from what this conversation remembers.

Read `references/post-session-cleanup-methodology.md`, packaged with this skill, for the checks that apply to the current work delta. Its numbered sections are the procedure.

## 1. Establish the baseline and the work delta

1. Resolve the verified integration baseline — the branch this work will integrate into.
   - Where the `feature-branch-lifecycle` model applies, a development branch integrates into its feature integration branch, and a feature integration branch into the long-lived integration branch.
   - Otherwise use the repository's verified integration branch: `staging` where the repository really uses one as its normal integration target, else `main` or the verified primary branch.
   - Confirm the choice from `CLAUDE.md`, release documentation, branch and pull-request conventions, or history. A branch name alone is not evidence.
2. Find the merge base between the current branch and that baseline.
3. The **work delta** is everything from that merge base through `HEAD`, plus staged, unstaged, and untracked changes.
4. If the current branch *is* the baseline, or nothing meaningful has been committed since it diverged, use the verified working-tree changes and explicit task evidence as the work delta.
5. If the baseline stays uncertain, say so, continue only with independently verified cleanup, and do not claim a clean completion.

Never shrink the surface to what you remember editing. After compaction, across sessions, or when helpers did part of the work, memory is the least reliable source you have.

## 2. Know what you may touch

| In the working tree | What to do |
| --- | --- |
| Work-delta changes attributable to this work | Clean up, correct, and simplify within scope |
| Pre-existing baseline behavior | Leave it, unless the work delta broke it |
| Unrelated edits, staging, and files — including another session's changes in a shared checkout | Preserve them exactly, staged state included |
| Files or hunks whose ownership is uncertain | Report them, and continue with the independently verified work |

"Clean" means the work delta holds no unexpected debris, unresolved defect, abandoned implementation, or complexity that should reasonably go now. It does not mean an empty `git status`.

A cleanup request authorizes reversible, in-scope cleanup. An inspection-only request stays read-only. Existing approval carries forward only within its stated scope.

Never use a destructive `reset`, `clean`, `stash`, or history rewrite, and make no implicit production or deployment change. Do not stage, commit, discard, or deploy on your own initiative. Keep security checks to the touched surfaces, and never print a secret value.

This skill does not delete branches or remove worktrees. A temporary branch that looks finished goes through the `feature-branch-lifecycle` cleanup gates; a task-created auxiliary checkout goes through `worktree-lifecycle`.

## 3. Compatibility needs evidence

- Add no compatibility behavior for hypothetical users, old data, API consumers, deployments, or integrations. New compatibility code needs a real supported dependency: a deployed older version, persisted data in the old representation, an active consumer of the old contract, a documented supported-version requirement, or an active migration window.
- "Someone might use it", "for backwards compatibility", "to be safe", and "future-proofing" are not evidence.
- Code introduced and superseded entirely within an unmerged branch never shipped. Branch history is not production history, so remove it without a compatibility path.
- Compatibility code that predates the work delta is different: it may have consumers you cannot see. Apply the `legacy-path-retirement` skill before removing it, and when its necessity cannot be established either way, leave it unchanged and report the uncertainty.

## 4. Review sequence

1. Reconstruct the full work delta before editing: the intended outcome, the changed paths, their ownership, and the classes of change — committed branch changes; staged, unstaged, and untracked work; renames; configuration; dependencies; schemas and migrations; tests; documentation; generated artifacts; tooling.
2. Apply every methodology section the delta touches, using the map below. Do not skip one because the visible diff looks small.
3. Remove or correct clear work-delta debris, defects, abandoned approaches, speculative compatibility code, and unnecessary complexity. Before each change, verify ownership and usages. Afterwards, re-review the baseline comparison and the status.
4. Validate with the project's own commands, narrowest first, then the broader required gates. Classify every failure or unrun check as work-delta-introduced, pre-existing, environmental or tooling, or unknown. A material changed behavior that could not be validated cannot be called complete and clean.
5. Report blockers and unresolved ownership or compatibility evidence plainly.

Before every additional change, ask: *is this necessary to correctly complete, simplify, stabilize, or clean up the current work delta?* If not, leave it and record the unrelated issue separately.

### Which methodology sections apply

| Section | Apply when |
| --- | --- |
| 1. Baseline and work delta | Always |
| 2. Implementation debris | Always |
| 3. Abandoned approaches and speculative compatibility | Always |
| 4. Minimize the implementation surface | Always |
| 5. Code quality | Always |
| 6. Errors and edge cases | Behavior, inputs, network calls, permissions, retries, or state transitions changed |
| 7. Data and state integrity | Persistence, APIs, schemas, migrations, serialization, or state management changed |
| 8. Security boundaries | A touched surface handles secrets, identity, authorization, ownership, input, logs, dynamic execution, or files |
| 9. Dependencies and configuration | Packages, lockfiles, environment variables, build settings, or deployment configuration changed |
| 10. UI and UX | Any user interface changed. Reading the source does not prove UI behavior |
| 11. Tests | Always |
| 12. Validation pipeline | Always |
| 13. Documentation against reality | Documentation, setup, configuration, APIs, examples, or user-facing copy is affected |
| 14. Deferred-work markers | Always |
| 15. Repository hygiene | Always |
| 16. Next-developer review | Always |
| 17. Final scope check | Before every additional cleanup change |

## 5. How this relates to review

`senior-code-review` reviews the final diff before you hand it over; run it on whatever this pass changes. This skill is the broader editing pass that comes first at the end of substantial work: it reconstructs the whole delta, removes what should not ship, and runs the full validation pipeline.

## Required report

Return exactly these five sections, even when one is empty:

```text
## Cleaned Up
[Meaningful cleanup performed.]

## Validation
[Checks actually run, and their outcomes.]

## Problems Found
[Defects, incomplete work, accidental technical debt, abandoned approaches,
speculative compatibility paths, or unnecessary complexity discovered.]

## Remaining Issues
[Work-delta-introduced issues, pre-existing issues, and optional future
improvements, kept separate, each with the reason it was left.]

## Final State
[Exactly one of: complete and clean / complete with documented remaining issues /
not yet safe to consider complete]
```

Use `not yet safe to consider complete` for a required work-delta defect or material unvalidated behavior. Documented remaining issues allow a complete state only when they do not block a validated requirement. Never claim `complete and clean` when required validation did not run, or when the baseline, the ownership of material changes, or material changed behavior is unresolved.
