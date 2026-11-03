<!-- Project CLAUDE.md snippet. A Claude Code home that carries the playbook's global instructions already routes local validation this way; merge this snippet only into a project whose agents do not get that route. -->

## Local validation before remote CI

For meaningful code or workflow changes and before an authorized push, PR, remote CI dispatch or retry, apply the available `local-ci-preflight` skill and the project's `LOCAL_VALIDATION.md` or existing equivalent. Where the skill is not installed, follow that project contract directly; the skill is portable Markdown guidance, not a required executor.

Run applicable cheap checks first, then the build and complete affected local E2E flows. Use required CI/native profiles when platform, graphics, SDK, browser, services or environment behavior differs. Preserve existing required checks and authentic remote acceptance. Reuse commands and runtime ownership rather than creating another stack or CI implementation.

Fix locally reproducible failures before using remote CI as the next debugging iteration. Record tested inputs, commands, results and gaps. A missing required tool/profile, skipped assertion or zero tests is not a pass. For a real blocker, state the prerequisite and use a remote exception only when the task authorizes it. Preserve read-only, deployment, access, spending and release boundaries.
