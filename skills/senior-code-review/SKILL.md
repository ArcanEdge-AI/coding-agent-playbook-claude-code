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

**Test gaps** — the specific case that would have caught the bug. Not "add more tests."

**Scope creep** — changes with no traceable link to the request, unrelated refactors, formatting churn, edits to generated, vendored, compiled, or package-owned files.

**Cleanup correctness** — imports, variables, types, functions, and files your change actually orphaned. Pre-existing dead code stays.

**Safety** — authentication, authorization, injection, secret handling, unsafe deserialization, path traversal, privilege boundaries.

**Performance** — new work in a hot loop, N+1 access, unbounded growth, a synchronous call on a latency path.

**Accessibility** — semantics, labels, focus management, contrast, keyboard reachability, for UI changes.

**Maintainability and design** — naming that hides intent; an abstraction, layer, dependency, or piece of state that no concrete current requirement justifies; speculative configurability; a duplicated source of truth or hidden coupling; a symptom patch where a root-cause fix at the correct boundary was in scope; a change that would ripple through unrelated components on a small requirement change; a pattern that fights the surrounding code.

**Completeness** — the integration and verification the change needed: an unconverted caller, a missed call site, a check that was required but never run. A smaller diff that leaves these behind is unfinished, not simpler.

**Unrecorded tradeoffs** — material technical debt (a compatibility shim, a staged migration, a deferred cleanup) accepted without its scope, rationale, and follow-up condition written into the plan, the change description, or the project's docs. Minor implementation choices do not need this; material ones do.

**Unverified subagent claims** — anything a subagent asserted that you never checked against evidence. This is the most common gap in delegated work: a confident summary of a file, accepted without opening the file. Include the route: every dispatch went to a bundled role with that role's model passed explicitly, and nothing suggests a forced or substituted model answered instead.

**Unreconciled workspaces** — task-created auxiliary worktrees without integration evidence and a final `removed` or `preserved` disposition.

## The test

```text
Would I approve this in review, from someone else?
```

If not, fix it or state the remaining risk plainly. Do not hand over a change whose problems you can already name.

## Validation honesty

State exactly what you ran and what happened.

- Name the command and the result.
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
