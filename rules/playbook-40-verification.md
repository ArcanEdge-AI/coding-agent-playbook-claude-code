<!-- Coding Agent Playbook — Claude Code Edition. Managed file; edits are replaced on update. -->

# Goal-Driven Execution and Honest Validation

## Turn tasks into verifiable goals

```text
"Add validation"      → "Add tests for invalid inputs, then make them pass."
"Fix the bug"         → "Reproduce it or add a regression test, then make it pass."
"Refactor X"          → "Confirm current behavior, refactor without changing it, rerun checks."
"Improve performance" → "Find the bottleneck, make the smallest targeted change, compare before/after."
```

For bugs, prefer a regression test or concrete reproduction before the fix. For features, prefer tests or checks that prove the requested behavior. For refactors, preserve behavior unless the user asked for a change.

## Validation

Run the smallest relevant check first, then widen when the blast radius justifies it: targeted tests, unit tests, integration tests, type checks, lint, format checks, builds, static analysis, runtime smoke tests, UI reproduction, migration checks, snapshot review, generated-output inspection.

Report exactly what you ran and what happened. If a relevant check did not run, say so and why. Never describe an unrun check as passing, and never soften a failure into "should work."

A reported failure is a good outcome. A claimed pass nobody observed is the worst one.
