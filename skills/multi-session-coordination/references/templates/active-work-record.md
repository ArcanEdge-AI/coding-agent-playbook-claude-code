# Active Work Record

Use this optional template for repository-local Claude Code coordination records under:

```text
.claude/coordination/active-work/
```

Create one record per active feature, migration, shared contract, or other meaningful workstream.

These records are coordination aids, not automatic truth. Verify them against current Claude Code sessions, branches, worktrees, commits, pull requests, code, and tests.

## Session Naming Standard

When creating a new project session, use:

```text
Project - Three-to-Four-Word Description
```

Examples:

```text
ArcLedger - Validate Billing Evidence
LoreBound - Implement Campaign Imports
United Tradesmen - Coordinate Scheduler Changes
```

Use the detected project name. Derive a concise three-to-four-word description from the session's primary objective. Do not ask the user to supply a name when the project and objective are already clear.

Use Claude Code's native naming controls:

```text
claude -n "Project - Three-to-Four-Word Description"
/rename Project - Three-to-Four-Word Description
```

The square brackets sometimes used to explain the format are placeholders and are not part of the actual session name.

## Record

```yaml
feature: "Short feature or workstream name"
session_name: "Project - Three-to-Four-Word Description"
status: "planned | in-progress | blocked | integration-ready | merged | abandoned"
session_id: "Optional Claude Code session identifier"
owner: "Optional responsible person or team"
project_directory: "."
branch: "feature/example"
base_branch: "Detected repository default branch"
worktree_class: "host-managed-primary | user-managed-existing | task-created-auxiliary"
worktree_path: "Optional canonical path; omit from committed public records when private"
worktree_permit: "Optional root-issued permit for a task-created auxiliary"
worktree_disposition: "active | integration-ready | cleanup-ready | removed | preserved | host-managed"
last_updated: "YYYY-MM-DDTHH:MM:SSZ"

objective: >-
  One concise description of the intended outcome.

owned_paths:
  - "src/example/**"

shared_paths:
  - "src/shared/contracts.ts"

shared_contracts:
  - "Customer"
  - "POST /api/example"

schemas_or_migrations:
  - "db/migrations/0001_example.sql"

dependencies:
  - "customer-schema"

blocked_by: []

must_not_modify:
  - "src/auth/**"

open_decisions: []

validation_required:
  - "targeted tests"
  - "typecheck"
  - "integration test"

notes: >-
  Include only coordination-relevant assumptions, risks, or handoff details.
```

## Maintenance Rules

- Use `dependencies` for identifiers of required upstream work artifacts or decisions, not package dependencies.
- Use `blocked_by` for dependencies or blockers that are currently unmet.
- Treat `owned_paths` as write ownership; `shared_paths` identifies coordination surfaces, not permission for concurrent edits.
- Treat `validation_required` as the handoff and integration gates that must pass before marking work `integration-ready`.
- Keep the record current while the work remains active.
- Use repository-relative paths whenever possible.
- Keep `session_name` aligned with the naming standard for newly created sessions.
- Keep task-created auxiliary ownership, integration target, cleanup condition, and final disposition aligned with the `worktree-lifecycle` skill.
- Do not create one worktree per subagent. Only the owning root may authorize `isolation: worktree`, create, adopt, repurpose, move, or remove an auxiliary.
- Before task completion, mark every task-created auxiliary `removed` with verification or `preserved` with its exact blocker and next action. Do not defer cleanup to scheduled automation.
- Detect the repository's actual default branch instead of assuming `main` or `master`.
- Do not store credentials, tokens, private local paths, or sensitive access material.
- Do not paste full session transcripts, long logs, or unrelated implementation notes.
- Mark abandoned work explicitly instead of silently leaving stale records active.
- Remove or archive the record after the work is merged and no longer affects active coordination.
