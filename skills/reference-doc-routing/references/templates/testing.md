# Testing Strategy

## Test Commands

Document targeted and full validation commands.

State which checks are mandatory, which kinds of change trigger the broader checks, and when an accepted result can be reused. Start with the smallest meaningful checks; run the required affected gates after the last relevant change, not the full suite after every small edit.

## Test Types

Describe available test layers:

- unit
- integration
- end-to-end
- visual/snapshot
- typecheck
- lint/static analysis
- build/smoke

## Test Conventions

Document naming, structure, fixtures, mocks, and setup patterns.

Retain tests for intended final behavior, lasting business rules, and realistic regression risks. Focused unit tests for lasting rules are appropriate. Reuse or extend existing coverage before adding a parallel suite, and keep mocked checks distinct from evidence that the real integration works. Do not add a permanent test for every helper, edit, or partial implementation.

When the approach changes, update, consolidate, or remove the tests, fixtures, and mocks that only preserve the abandoned approach. Keep every still-required assertion and every explicit coverage gate; investigate a failing test before calling it obsolete. Temporary diagnostic checks need not be committed as lasting tests.

## Regression Testing

For bugs, prefer reproduction or regression tests when feasible.

## Snapshot Rules

Do not update snapshots blindly. Inspect diffs and confirm they match intended behavior.

## Known Constraints

Document slow tests, flaky tests, unavailable environments, or validation gaps.
