# Repository Coding Agent Instructions

Follow the host's instruction hierarchy first. Within the same authority level, the repository-specific instructions here apply where they are more specific than global guidance.

## Repository Overview

Describe:

- what this repository does
- major applications/services/packages
- primary languages and frameworks
- important directories
- ownership boundaries

## Build, Test, and Validation

Document the normal commands for:

- install and setup
- targeted E2E tests
- full E2E suite
- typecheck
- lint
- format
- build
- local run and smoke test
- local validation before remote CI (`LOCAL_VALIDATION.md`, if the project keeps one)

Retain only E2E behavioral tests. Every unit test created is temporary, whatever its purpose; none remains in a completed change. Unit tests may guide development, but remove them, and the support code only they use, once passing E2E coverage carries their still-required assertions. Preserve still-required assertions, failure cases, and repository gates, and migrate existing non-E2E tests only within authorized scope.

## Architecture Rules

Document:

- where new behavior should be added
- where new behavior should not be added
- existing patterns to follow
- shared components, dialogs, hooks, validators, and utilities to reuse before writing new ones, and where they live
- boundaries between modules/services/packages

## Change Rules

Document:

- branch/submission expectations
- generated files
- dependency policy
- migration policy
- compatibility commitments: supported versions, consumers, and deprecation windows
- release/versioning policy

## Reference Docs

List relevant repo docs and their authority level:

- `docs/architecture.md` — [authoritative/advisory/historical]
- `docs/testing.md` — [authoritative/advisory/historical]
- `docs/security.md` — [authoritative/advisory/historical]
