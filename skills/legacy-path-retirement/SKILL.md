---
name: legacy-path-retirement
description: Use when an authorized change raises whether to keep, migrate, or remove superseded code, a duplicate writer, a compatibility fallback, an old contract, or a transitional flag — and before you add a compatibility shim or another guard around an old path. Traces current dependencies and explicit retention requirements before deciding, keeps code retirement separate from what happens to existing data, and carries correctness safeguards into the authoritative path. Not permission for unrelated cleanup, breaking a supported contract, or destructive data changes.
---

# Legacy Path Retirement

Aim for one authoritative implementation within the scope you were given. Keep a compatibility path only when a **demonstrated current dependency** or an **explicit retention requirement** needs it — not for hypothetical consumers, and not merely because old code or old data exists.

Evidence cuts both ways here. A clean symbol search does not prove a path is unused: dynamic dispatch, configuration, scheduled jobs, stored data, and external clients do not show up in it. And an unresolved question does not justify keeping a fallback forever. Missing dependency evidence is a gap to report, never proof that removal is safe.

This skill decides; it does not authorize. An audit or diagnosis stays read-only. Nothing here authorizes unrelated cleanup, breaking a contract someone still depends on, destructive data changes, publication, or deployment.

## 1. Establish scope and current requirements

Identify:

- the requested change, and the authoritative implementation it should leave behind
- the candidate paths: superseded code, duplicate writers, outdated forms or contracts, compatibility fallbacks, transitional flags
- the repository's support commitments — supported versions, deprecation windows, published contracts — from its `CLAUDE.md`, release documentation, or the user
- the product stage, and which actions the task actually authorizes

Do not infer pre-production status, or that data is disposable, from a development environment. Pre-production usually makes a direct consolidation practical when no supported older consumer exists; it does not remove current integrations, useful configuration, release constraints, or correctness requirements. Production may need a bounded migration. That is an evidence-based dependency, not a reason to keep every old path.

## 2. Keep three decisions separate

| Concern | How it is decided |
| --- | --- |
| Superseded code, duplicate writers, outdated forms or contracts, compatibility fallbacks | Retain, migrate, or remove — on current dependency evidence and explicit requirements |
| Existing development data and useful configuration | Preserve or migrate deliberately. Reset or delete only with authority for the exact data and its consequences |
| Correctness safeguards | Preserve the guarantee even when the implementation changes. A safeguard is not compatibility debt |

Safeguards include stable identifiers and references, authorization, input and upload validation, persistence integrity, retry and idempotency behavior where it is required, and orphan cleanup. When an obsolete path is the only thing currently providing one of these, carry the guarantee into the authoritative path and test it there. Do not keep the obsolete path just to house it.

## 3. Trace dependencies before choosing

Start from the candidate and look at the evidence that actually bears on it:

- callers, imports, routes, entry points, configuration, feature flags, dynamic dispatch, reflection or string-built names, and scheduled jobs
- readers and writers, schemas, migrations, stored formats, fixtures, and generated contracts
- supported clients, external integrations, deployed versions, and release or rollback requirements, where they are relevant
- in-flight work in other sessions or branches that may still call the old path — use the `multi-session-coordination` skill when such work exists
- repository guidance and explicit user retention requirements

Widen only where the evidence or a material risk calls for it. Old tests and documentation may describe superseded behavior; establish whether that behavior is still required before treating them as a dependency.

Record one bounded conclusion per candidate, with its evidence:

| Conclusion | What to record |
| --- | --- |
| Demonstrated dependency | The current consumer, by name. |
| Explicit retention requirement | The commitment that requires it, cited. |
| No current dependency found | Which checks ran, and what they could not see. |
| Unresolved | The missing evidence, and what would settle it. |

For example:

```text
Candidate:   legacy draft writer `saveDraftV1`, beside the new `saveDraft`
Conclusion:  no current dependency found
Checks:      no imports outside the drafts module; this change removes the v1 route;
             no scheduled job or configuration names it; stored drafts are already
             in the v2 shape, migrated in every environment per the release notes
Cannot see:  third-party clients — the release notes list none as supported
Decision:    remove the writer and its v1-only tests; keep the v2 validation that
             duplicated its checks
```

Do not turn missing information into either permanent compatibility or permission to delete.

## 4. Choose: retain, migrate, remove, or defer

- **Retain** — a supported consumer or an explicit requirement still needs the old behavior. Keep the smallest boundary that serves it. A transitional adapter is material technical debt: record its dependent consumer, the rationale, and an observable removal condition in the plan or the project's maintained documentation.
- **Migrate** — current consumers or useful data can move to the authoritative implementation within scope and authority. Validate that move before retiring the old path.
- **Remove** — the relevant checks found no required current dependency, and removal is part of the authorized change. Remove the obsolete call sites, wiring, and tests with it, and nothing unrelated.
- **Defer** — material dependency evidence, or authority for a destructive step, is missing. State the exact gap and the smallest next check or approval, and continue the independent work.

Question a proposed compatibility check or fallback before you harden it. Every guard added around a path that should be retired makes it harder to retire later.

Code that was introduced and superseded within the same unmerged branch never reached a consumer. Branch history is not release history: that code needs no compatibility path, and the `session-cleanup` pass removes it.

## 5. Keep data disposition independent

Existing development records do not justify permanent dual writers or compatibility layers. Decide separately whether they hold useful data or configuration, and choose a deliberate way to preserve or migrate them.

A request to simplify code is not permission to reset a database, drop stored files, remove user configuration, or discard records that do not map cleanly. Before any destructive data step, resolve the exact targets, what depends on them, the consequences, the recovery options, and the authority for that exact action. Follow the repository's migration policy, and do not erase historical migrations or durable contract history because the runtime code that used them is gone.

If useful data still depends on the old path, migrate it or report the dependency; do not delete the path first. If the data's value, or the authority to reset it, is unresolved, preserve it and name the blocker — without inventing a permanent fallback to cover the gap.

## 6. Implement and verify within scope

When implementation is authorized:

- move the required callers and guarantees to the authoritative path
- remove only confirmed-obsolete code, and the machinery your change made unused
- update affected contracts, fixtures, tests, and current documentation to the accepted behavior
- verify real call paths and, where it applies, persistence and reload behavior — compiling is not enough
- test the meaningful failures and safeguards that are affected: authorization, invalid input, reference integrity, and cleanup
- confirm that duplicate writes, competing sources of truth, and wiring to the retired path are gone from the affected surface

Keep the regression tests that still describe required behavior. Replace tests that only enforce obsolete behavior with tests for the accepted contract, and never change an authoritative acceptance requirement just to get a pass.

## 7. Record the outcome

In the existing plan or the final report — not a new tracking system:

- the authoritative implementation and the affected scope
- each material retain, migrate, or remove decision, with its dependency evidence
- useful data or configuration retained, migrated, or explicitly approved for reset
- the correctness guarantees preserved, and the checks that actually ran
- any transitional compatibility kept, with its removal condition
- unresolved consumers, evidence gaps, approval gates, and behavior not verified

## Route these elsewhere

| Concern | Skill |
| --- | --- |
| Whether a retained adapter or staged migration is the right design, and how to record the debt | `reference-doc-routing`, through its engineering-design decision aid |
| Another session or branch still depends on the path | `multi-session-coordination` |
| An end-of-work pass that removes debris and branch-only paths across the whole work delta | `session-cleanup` |
