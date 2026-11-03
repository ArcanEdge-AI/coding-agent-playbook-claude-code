# Testing Strategy

## Test Commands

Document the targeted and full E2E commands, plus the build, lint, type checking, and static validation commands.

State which checks are mandatory, which kinds of change trigger the broader checks, and when an accepted result can be reused. Start with the smallest meaningful checks; run the required affected gates after the last relevant change, not the full suite after every small edit.

If the project keeps a `LOCAL_VALIDATION.md`, link it here; it is the contract the `local-ci-preflight` skill runs before a push, pull request, or remote CI run.

## Retained Test Policy

Retain only end-to-end (E2E) behavioral tests. Do not retain unit or isolated integration suites as lasting coverage for new work. An E2E test exercises a complete supported flow through a real UI, API, or CLI entry point, with the relevant dependencies and an observable result such as persisted data or user-visible state. A direct helper call or a mocked internal flow is not E2E evidence, whatever its file name says.

Build, lint, type checking, and static validation remain appropriate checks for what they establish. Visual or snapshot assertions can be part of an E2E flow; on their own they do not establish the flow.

Existing required suites and repository gates stay in force. Document here which existing non-E2E suites are still mandatory, and migrate them only within authorized scope, after their replacement E2E coverage passes.

## Test Conventions

Document E2E naming, structure, fixtures, environment setup, dependency boundaries, and how disposable test data is cleaned up.

Reuse or extend existing E2E coverage for the intended final behavior, important business rules, meaningful failures, boundary cases, and realistic regression risks. Do not add a permanent test for every helper, edit, or partial implementation.

## Runtime Reuse and Concurrency

Document the established environment's identity, the supported recovery commands, the test-isolation requirements, the browser-test worker limits, and how to account for known overlapping heavy jobs on the same machine. The global runtime-resource rules apply: discover stopped and unhealthy resources left by earlier sessions as well as running ones. A new test run or a retry does not by itself require a new browser, container stack, or virtualized environment.

- Reuse a compatible browser instance through supported tools. Use a fresh isolated context when clean test state is required and the tool supports one; never carry cookies, authentication, or mutable state across an isolation boundary. When the runner cannot reuse an existing browser, keep the lifecycle it requires.
- Start with one browser-test worker when safe capacity is unverified or heavy jobs already overlap, unless the required scenario needs more. Raise concurrency only for an identified need and verified capacity. Coordinate or serialize browser suites, image builds, and other heavy validation, and do not change another owner's jobs without authority.
- Before reusing a container or image, verify the project and service ownership, the current source or image identity, configuration, ports, mounts, data, and health. Start or recover the existing project environment before considering a replacement, including when an earlier session created it. Use an isolated resource when shared mutable state would contaminate the tests. When current inputs require it, update or recreate the affected service under the established project identity, preserving required data first. Stale runtime state is not current E2E evidence.
- Reuse valid images and build caches. Record any required fresh build or additional runtime in the task record, and make sure teardown closes task-owned temporary resources after both passing and failing runs, without stopping shared services or deleting persistent data.

### Example: recovering a Docker and WSL environment

Adapt this example to the repository's actual launcher, installed tools, and authority. Do not run host-wide recovery just because a test failed.

1. Resolve the existing Docker context, project name, configuration files, services, data mounts, and registered WSL distribution. Inspect stopped containers and distributions as well as running ones. A daemon connection error does not establish that no environment exists; do not respond by choosing a new context, project suffix, port range, or distribution.
2. Use the project's lifecycle launcher when there is one. Otherwise, target the verified existing project and services: [Compose start](https://docs.docker.com/reference/cli/docker/compose/start/) starts existing containers, and [Compose restart](https://docs.docker.com/reference/cli/docker/compose/restart/) restarts services but does not apply configuration changes. If the Docker engine itself is the failed dependency, recover it through its supported controls.
3. When an image or configuration change requires recreation, use the established project and configuration with [Compose up](https://docs.docker.com/reference/cli/docker/compose/up/), preserving or migrating required data first. That is a controlled update of the existing environment, not permission to create parallel stacks. Images are build artifacts, not processes you can restart.
4. Use [WSL's installed-distribution inventory and lifecycle commands](https://learn.microsoft.com/en-us/windows/wsl/basic-commands) to start the registered distribution, or to terminate and relaunch the affected distribution once its consumers and restart authority are verified. Prefer the supported Docker controls for a Docker-managed backend. A WSL-wide shutdown stops every running distribution and its utility VM: establish that impact, and get authority for any unrelated or unresolved disruption before using it.
5. Keep to the global recovery limit and bounded readiness waits, and verify the same environment after recovery. Do not install or import another distribution, unregister an existing one, delete its virtual disk, reset data, or prune volumes to work around a startup failure. If recovery stays blocked, stop and report the blocker rather than multiplying environments.

## Temporary Unit Tests and Cleanup

Every unit test created is temporary, whatever its purpose or whoever writes it; none remains in a completed change. Unit tests may guide development or diagnosis. Map their still-required behavioral assertions to E2E cases, and once those cases pass, remove every created unit test along with the fixtures, mocks, helpers, or dependencies only they used. Keep support code that E2E tests or production still use. Classify tests by the behavior they exercise, not by file names or labels: renaming a unit test does not make it an E2E test.

Investigate a failing test before removing it, and never weaken a required assertion or disable a repository gate to obtain a pass. If E2E execution is unavailable or blocked, report the gap and the unfinished cleanup instead of treating unit coverage as the completed solution.

As the implementation changes, update, consolidate, or remove E2E tests and fixtures that only preserve abandoned fixes, keeping every still-required assertion and explicit coverage gate.

## Regression Testing

For bugs, prefer an E2E reproduction or regression test when feasible, and verify the actual success, failure, and boundary outcomes the fix affects.

## Snapshot Rules

Do not update snapshots blindly. Inspect diffs and confirm they match intended behavior.

## Known Constraints

Document slow tests, flaky tests, unavailable environments, missing E2E entry points, or validation gaps.
