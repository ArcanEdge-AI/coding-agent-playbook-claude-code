---
name: senior-code-review
description: Use before finalizing a meaningful code change. Reviews the final diff for correctness bugs, regressions, scope creep, missing tests, safety, performance, accessibility, and maintainability risk — and for subagent claims that were never independently verified.
---

# Senior Code Review

Run this before you tell the user the work is done. You are looking for the thing you would be embarrassed to have shipped.

Review the diff you are about to hand over, not the diff you intended to write. Read it with `git diff` and go through it as a reviewer who did not write it.

## What to look for

**Correctness** — logic errors, off-by-one, inverted conditions, unhandled `null` or error paths, races, resource leaks, wrong assumptions about an API's contract.

**Regressions** — behavior the change alters that nobody asked it to alter, including behavior covered only indirectly.

**Contracts** — public API shape, serialized formats, persisted schemas, migrations, event payloads, config keys. Breakage here is expensive and often silent.

**Test gaps and test excess** — the specific case that would have caught the bug, not "add more tests"; and on the other side, redundant tests, fixtures, or mocks, tests that pin implementation details, and tests that only preserve an abandoned partial fix instead of the intended final behavior. Recommend a new test only for an important behavior or a realistic regression risk existing checks do not establish; a focused unit test for a lasting rule qualifies, a permanent test per implementation step does not. Consolidation keeps every still-required assertion, and deleting a failing test never resolves its failure.

**Scope creep** — changes with no traceable link to the request, unrelated refactors, formatting churn, edits to generated, vendored, compiled, or package-owned files.

**Cleanup correctness** — imports, variables, types, functions, and files your change actually orphaned. Pre-existing dead code stays.

**Safety** — authentication, authorization, injection, secret handling, unsafe deserialization, path traversal, privilege boundaries.

**Performance** — new work in a hot loop, N+1 access, unbounded growth, a synchronous call on a latency path.

**Accessibility** — semantics, labels, focus management, contrast, keyboard reachability, for UI changes.

**Maintainability and design** — naming that hides intent; new code that duplicates a component, dialog, hook, validator, or utility the project already had and the change could have reused or extended; an abstraction, layer, dependency, or piece of state that no concrete current requirement justifies; a substantial replacement of a working flow without evidence of a significant benefit over improving it once migration, verification, and maintenance costs are counted; speculative configurability; a duplicated source of truth or hidden coupling; a symptom patch where a root-cause fix at the correct boundary was in scope; a change that would ripple through unrelated components on a small requirement change; a pattern that fights the surrounding code.

**Completeness** — the integration and verification the change needed: an unconverted caller, a missed call site, a check that was required but never run. A smaller diff that leaves these behind is unfinished, not simpler, and a passing check for a partial fix or a mocked integration does not establish that the affected flow works.

**Legacy paths and data** — a compatibility path or fallback kept without a demonstrated dependency or explicit retention requirement, or removed while a consumer is still unresolved; a support commitment invented for a hypothetical user, an old test account, a fixture, or an intermediate development version; code retirement that discards useful data or configuration without authority, or drops a correctness safeguard the old path provided.

**Unrecorded tradeoffs** — material technical debt (a compatibility shim, a staged migration, a deferred cleanup) accepted without its scope, rationale, and follow-up condition written into the plan, the change description, or the project's docs. Minor implementation choices do not need this; material ones do.

**Unverified subagent claims** — anything a subagent asserted that you never checked against evidence. This is the most common gap in delegated work: a confident summary of a file, accepted without opening the file. Include the route: every dispatch went to a bundled role with an approved model passed explicitly for the work assigned, and nothing suggests a forced or substituted model answered instead. Include the cost: a helper whose concrete benefit did not justify its context, coordination, and review overhead is a finding too.

**Self-review presented as independent review** — a required independent-verification gate claimed satisfied by your own reread, including one made through a role's perspective.

**Unreconciled workspaces** — task-created auxiliary worktrees without integration evidence and a final `removed` or `preserved` disposition.

**Unmet skill and graph deliverables** — a skill you selected whose required checks or outputs were never produced; a graph node or approval gate still open. Naming a skill is not applying it.

## The test

```text
Would I approve this in review, from someone else?
```

If not, fix it or state the remaining risk plainly. Do not hand over a change whose problems you can already name.

## Validation honesty

State exactly what you ran and what happened.

- Name the command and the result.
- Separate checks run now from historical results, pre-existing failures, and behavior you did not verify. A passing subset does not establish a new feature.
- If a relevant check did not run, say so and why. Do not describe an unrun check as passing.
- If a check failed and you could not fix it in scope, report the failure with its output.

A reported failure is a good outcome. A claimed pass that nobody observed is the worst thing this skill exists to prevent.

## Report

```text
Summary:
- [What changed, and what it does now that it did not before.]

Verification:
- Ran: [exact command]
  Result: [pass / fail / not run, with the reason]

Risks and notes:
- [Assumptions, remaining risk, unrelated issues you noticed but did not fix,
   subagent work you accepted and how you checked it, follow-ups.]
```
