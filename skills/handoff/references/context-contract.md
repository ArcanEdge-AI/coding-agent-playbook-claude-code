# Handoff Context Contract

Use this contract to decide what goes into the package for the next session. Adapt the headings to the work, and do not add empty sections just to fill a template.

## Evidence labels

Label every material claim with how it is known:

- **Verified current** — observed now: from the repository, from command output in this turn, or from a read-only query to a connected service.
- **User-reported current** — stated by the user and not independently refreshed in this turn.
- **Historical** — tied to an older run, branch, release, document, or observation time. Give the time or the ref.
- **Unverified** — plausible but unsupported, or blocked by missing access.

State contradictions rather than choosing the more convenient source. When the live state and the source differ — deployed behavior against the code, a remote branch against the local one — record both.

## Material context inventory

### Purpose and status

- The user's actual goal, and why the work exists.
- The current verdict: completed, in progress, blocked, failed, or inconclusive.
- What "done" means, especially any live acceptance boundary.

### Work and findings

- Changes made, analyses completed, and artifacts produced.
- Causal findings, and the evidence behind each one.
- Research, simulations, comparisons, and alternatives explored.
- Approaches rejected or paused, with the reason, so they are not rediscovered as new ideas.

### Validation

- The exact tests, builds, migrations, replays, audits, or live checks that ran.
- Counts, outcomes, warnings, the runtime or dependency context, and when each ran.
- Known pre-existing failures, and the comparison that shows they are pre-existing.
- What the evidence proves, and what remains unproven.

### User decisions and boundaries

- Approved direction, corrections, and non-negotiable behavior.
- Interpretations or implementations the user explicitly rejected.
- Actions already authorized, and actions that still need approval.
- Who handles git — commits, pushes, pull requests, merges — stated explicitly.
- Safety, privacy, credential, customer-data, and production boundaries.

### Continuity anchors

- The repository or project path, and the exact checkout the next session should use.
- Branch or ref, commit, upstream, ahead or behind, dirty state, and any preserved worktrees.
- Pull request, issue, run, release, deployment, environment, and evidence-ledger identifiers.
- Important files, plans, prompts, fixtures, and reports, by exact path.
- The `CLAUDE.md` files and skills that govern the work.
- Connected-service identity and access state, without secret values.
- This session's name or ID, so a detail that turns out to be missing can be looked up with `/resume` instead of guessed.

### Workflow state

Carry the state the playbook's other workflows hold, when it exists:

- The plan or task graph: completed, ready, blocked, and invalidated items, and any open approval gate.
- Helpers used, and what remains of the launch and retry allowance.
- Task-created auxiliary worktrees, each with its disposition: removed, or preserved with path, owner, branch or HEAD, blocker, and next action.
- Branch roles, base branches, permitted merge targets, promotion state, and cleanup eligibility.
- Ownership agreed with other sessions, and the contracts they depend on.

### Remaining work

- Open risks and missing evidence.
- The smallest correct next action.
- Its preconditions and acceptance criteria.
- The stop conditions that produce FAIL, INCONCLUSIVE, or a request for the user's direction.

## Repository handoff rules

- Name the exact checkout. A fresh session in a different checkout or worktree does not see this one's uncommitted work.
- Do not send the next session to a dirty primary checkout when a clean task worktree is the verified source of truth.
- Identify unrelated local changes, and say explicitly that they must be preserved.
- Do not create a duplicate pull request when an existing one owns the work.
- Do not call a branch current without refreshing its remote state when that check is cheap.
- Keep source validation, CI, merge, deployment, and live acceptance as separate states.

## Seed-prompt skeleton

```text
# Handoff: <title>

Prepared <date and time> from session "<name or ID>".
Repository: <path>. Use this checkout: <path>, branch <branch> at <commit>,
<clean, or the dirty paths>. Unrelated local changes to preserve: <paths or none>.

## Objective and verdict
<goal, current verdict, and what "done" means>

## Done, with evidence
- [verified current] <result> — <evidence handle>
- [historical, <when>] <result> — <evidence handle>

## Findings and rejected approaches
<causal findings; approaches ruled out, and why>

## Validation
<what ran, exact outcomes, what it proves, what remains unproven>

## Decisions and boundaries
<approved direction; who handles git; actions that still need approval>

## Workspace and workflow state
<worktrees, branch roles, plan or graph state, other sessions' ownership>

## Open risks and the next gate
<the smallest correct next action, its preconditions, its stop conditions>

Acknowledge the inherited state, refresh drift-prone facts, and state the exact
next gate. Do not begin any merge, deployment, external mutation, destructive
action, or newly expanded implementation without the user's authority.
```

## Final prompt ending

End the seed prompt with an instruction equivalent to:

> Acknowledge the inherited state, refresh drift-prone facts, and state the exact next gate. Do not begin any merge, deployment, external mutation, destructive action, or newly expanded implementation without the user's authority.

## Completeness check

Before delivering the handoff, confirm that:

- every "finished" claim has an evidence handle
- material failures and warnings are present
- the next session can locate the authoritative checkout and artifacts
- current, historical, user-reported, and unverified facts are distinguishable
- every user decision that affects implementation or acceptance is preserved, including who handles git
- no credential or unnecessary sensitive data appears
- the next session can continue without rereading the old transcript
