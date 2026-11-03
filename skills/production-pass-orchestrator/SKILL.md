---
name: production-pass-orchestrator
description: Coordinate a production-readiness pass across a codebase with eleven specialist review lanes (security, testing, performance, DevOps, reliability, API readiness, database integrity, UX, architecture, code quality, and documentation), followed by risk classification, implementation sequencing, validation, and a go/no-go release recommendation. Use when the user wants a complete production pass rather than a narrow single-area review.
---

# Production Pass Orchestrator

## Core purpose

Run a structured production-readiness pass on the repository.

The goal is to prepare the codebase for safe production release, not to perform a broad rewrite or speculative refactor.

## Operating principles

- Use the repository as the source of truth.
- Audit before broad implementation.
- Prioritize production safety over cosmetic improvement.
- Preserve existing product behavior unless a change is required to fix a production risk.
- Keep changes small, reviewable, and reversible.
- Do not introduce new dependencies unless clearly justified.
- Do not expose secrets, credentials, tokens, private keys, or sensitive values.
- Do not perform destructive migrations or production-impacting operations without explicit approval.
- If required tooling is unavailable, unhealthy, read-only, or missing, document the blocker instead of bypassing the workflow.

## Production-readiness deliverables

Use the output format requested by the user. An assessment remains read-only and reports findings without application, test, or repository-document edits. A requested full production pass may include the following project artifacts when needed for its agreed deliverables; do not create all six automatically:

- `PRODUCTION_READINESS_REPORT.md`
- `RISK_REGISTER.md`
- `RELEASE_CHECKLIST.md`
- `TESTING_SUMMARY.md`
- `DEPLOYMENT_NOTES.md`
- `DOCUMENTATION_GAPS.md`

When the user requests a client-facing, evidence-backed readiness report, the `production-readiness-report` skill can turn the lane findings into that report.

## Phase 1: Repository discovery

Inspect the repository before implementation.

Identify:

- Application type and primary stack
- Frontend framework
- Backend framework
- Database or persistence layer
- Package manager
- Build system
- Test tooling
- Linting, formatting, and type-checking setup
- CI/CD configuration
- Deployment configuration
- Environment variable patterns
- Authentication and authorization model
- API structure
- Third-party integrations
- Critical user flows
- Production entry points
- Existing documentation quality

Record the discovery summary in the requested report or response.

## Phase 2: Specialist lane audit

Use the relevant specialist production skills as lanes, and invoke each lane by its skill name:

- `production-code-quality`
- `production-architecture-review`
- `production-security-review`
- `production-testing-qa`
- `production-performance-review`
- `production-reliability-observability`
- `production-database-integrity`
- `production-api-integration`
- `production-ux-accessibility`
- `production-devops-release`
- `production-documentation-onboarding`

Each lane should produce findings, classify risks, recommend fixes, and identify validation steps.

Apply each lane yourself in the root session by default: invoke the lane's skill (for example the `production-security-review` skill) and work through it directly. A lane is a review perspective, not a subagent, and eleven lanes are not a reason to dispatch eleven helpers. Dispatch a bounded helper for a lane only when its concrete benefit justifies the cost or an independent check is required, following the `subagent-orchestration` skill. For example, dispatch the bundled `read-only-explorer` subagent on its approved route to map entry points and call paths, the bundled `senior-reviewer` subagent on its approved route for an independent lane review, or the bundled `test-triager` subagent on its approved route to run suites. Bundled roles cannot invoke skills, so name the lane skill and its `SKILL.md` path in the assignment and require the helper to read it before the covered work. Keep your own model, effort, permissions, and accountability unchanged. The root session keeps cross-lane synthesis, deduplication, severity and risk ranking, security, authorization, data-migration, destructive-operation, and release decisions, and final acceptance, including the go/no-go recommendation.

Complete the initial audit and risk assessment before broad implementation. Assessment-only requests stop at reporting; remediation requires task authority and release operations require their own authority.

## Severity model

### Blocker

Prevents safe production release.

Examples:

- Exposed secrets
- Failing build
- Broken critical user flow
- Critical authentication flaw
- Critical authorization flaw
- Data loss risk
- Unsafe production migration
- Severe dependency vulnerability with practical exploit risk

### High

Serious production risk that should be fixed before release.

Examples:

- Missing authorization on important routes
- Missing validation on sensitive inputs
- Untested payment, onboarding, or account flows
- Major performance issue
- No rollback path
- Critical observability gap
- Fragile deployment process

### Medium

Should be addressed soon but does not necessarily block release.

Examples:

- Moderate duplication
- Missing non-critical tests
- Incomplete documentation
- Inconsistent error states
- Minor performance inefficiency

### Low

Cleanup, polish, or future improvement.

Examples:

- Naming cleanup
- Minor refactor
- Cosmetic inconsistency
- Optional documentation improvement

## Phase 3: Prioritization

After specialist audits:

- Merge findings into the requested risk report, using `RISK_REGISTER.md` when that project artifact is in scope.
- Deduplicate overlapping issues.
- Assign severity to every finding.
- Identify Blockers.
- Identify High-priority risks.
- Define the implementation sequence.
- Identify files with cross-lane overlap.
- Identify which lane owns each fix. Lane ownership is a domain classification, not agent write ownership: the root session implements fixes by default, and a bundled `isolated-worker` subagent, when one is used, gets exact write ownership with conflicting writes serialized.
- Produce an initial go/no-go status.

Do not implement Medium or Low findings until Blocker and High findings are resolved or explicitly deferred.

## Phase 4: Implementation

Enter this phase only when remediation is authorized. Implement only in-scope Blocker and High-priority items unless instructed otherwise. For assessment-only requests, provide the proposed sequence without edits.

Implementation order:

1. Build, install, and configuration blockers
2. Security blockers
3. Authentication and authorization blockers
4. Data integrity blockers
5. Critical user-flow blockers
6. High-risk reliability issues
7. High-risk test gaps
8. High-risk deployment gaps
9. Required release documentation

Rules:

- Work in small batches.
- Group changes by domain.
- Avoid broad rewrites.
- Avoid overlapping edits from different lanes.
- Update the E2E coverage of the affected flow when behavior changes (see Phase 5).
- Update documentation when setup, deployment, or behavior changes.
- Record every changed file and why.
- Run the narrowest useful validation after each substantial edit.

## Phase 5: Validation

Use available repository commands for:

- Install verification (using the existing lockfile and installed dependencies; ask the user before any command that downloads packages or runs downloaded code)
- Lint
- Formatting check
- Type check
- Existing mandatory repository suites, including pre-existing unit or integration checks
- E2E tests of complete supported flows, important business rules, meaningful failures, and boundary cases
- Build
- Dependency audit and security scan, if configured, and only when the task authorizes any registry or service network access they need; otherwise record them as unavailable (see `production-security-review`)

Report validation in the requested deliverable; update `TESTING_SUMMARY.md` when that artifact is in scope, covering:

- Commands run
- Results
- Failures
- Fixes applied
- Tests not available
- Manual QA required

If a command fails, investigate and document the evidence. Fix it only within authorized remediation scope; otherwise report the proposed fix.

Retain new behavioral tests as E2E coverage only. Every created unit test is temporary; remove it and exclusively used support code once corresponding E2E assertions pass. Preserve still-required assertions and repository gates, and keep migration of pre-existing suites within authorized scope. Missing or skipped required coverage is a gap, not a pass.

## Phase 6: Final release readiness

Produce a final summary with:

- Executive summary
- Go/no-go recommendation
- Blockers found
- Blockers fixed
- Remaining blockers
- High-priority risks found
- High-priority risks fixed
- Remaining high-priority risks
- Medium and Low risks deferred
- Files changed
- Tests added or updated, and temporary unit tests removed
- Validation commands and results
- Manual QA checklist
- Deployment notes
- Rollback considerations
- Monitoring and observability gaps
- Recommended next sprint items

## Final response format

Use this format:

```text
Production Readiness Result

Go/No-Go:
- [Go, Conditional Go, or No-Go]

Summary:
- [Brief summary]

Blockers:
- [Fixed and remaining]

High Risks:
- [Fixed and remaining]

Validation:
- Lint:
- Typecheck:
- Tests:
- Build:
- Security/dependency audit:

Files Changed:
- [File path]: [reason]

Manual QA Required:
- [Checklist]

Remaining Risks:
- [Risks]

Recommended Next Sprint:
1. [Item]
2. [Item]
3. [Item]
```
