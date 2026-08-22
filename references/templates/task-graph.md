# Task Graph: [Task Name]

Use this only for work that genuinely benefits from writing the topology down. Keep smaller or linear tasks in the normal working plan.

This is a plan you maintain by hand. It is not a scheduler, and nothing here is mechanically enforced.

## Metadata

- **Goal**: [one concrete outcome]
- **Owner**: [the root session]
- **Main session model**: [what the user actually selected — do not assume Opus]
- **Repository and worktree**: [verified current context]
- **Applicable instructions**: [`CLAUDE.md` paths or other sources]
- **Status**: [Proposed / Active / Blocked / Complete]
- **Last updated**: [timestamp or checkpoint]
- **Why a graph**: [what makes the structure worth its cost]
- **Multi-session preflight**: [not needed / completed, with evidence / blocked]

## Success Criteria

- [observable criterion]
- [required validation]
- [required user-visible result]

## Budgets

- **Subagent count**: [expected number of dispatches across both layers]
- **Auxiliary-worktree budget**: [default 0 — separate from anything about subagent counts; two or more active auxiliaries require user approval]

## Nodes

| ID | Work | Executor | Inputs | Output and acceptance condition | Depends on | Reads | Writes | Model | Role / effort | Mode / tools | Workspace | Verification gate | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| N0 | [bounded work] | [named role, or root] | [authoritative inputs] | [artifact + how you will accept it] | None | [read scope] | None | [explicit model] | [role / its fixed effort] | [permissionMode / tools] | [shared workspace, or W#] | [evidence required] | Ready |

Node states: `Proposed`, `Ready`, `Running`, `Complete`, `Failed`, `Blocked`, `Superseded`.

Notes on the routing columns:

- **Model** is passed explicitly on every dispatch, at or below the main session's tier (`opus` > `sonnet` > `haiku`). Equal tier is valid. Frontmatter pins `haiku` so an omitted model fails closed.
- **Effort** comes from the role definition and overrides session effort. It is a property of the role, not a ceiling inherited from the caller — choose the role whose effort fits the work.
- **Mode / tools** must be no broader than the caller's. Remember that `plan`-mode roles cannot reliably run test suites; route execution to `test-triager`.

## Dependency Edges

| From | To | Consumed artifact or decision |
| --- | --- | --- |
| N0 | N1 | [why N1 cannot correctly begin without N0's accepted output] |

Every edge must survive this question:

> Can the downstream node begin correctly without an accepted output or decision from the upstream node?

If yes, delete the edge. Narrative order is not a dependency, and each false edge costs parallelism.

## Hidden Constraints

Things that order work without appearing as data edges:

- **Shared file writes**: [none, or the exact conflicts]
- **Shared mutable state**: [ports, services, environments, locks, credentials, rate limits, cost]
- **Schema, interface, migration, or contract ordering**: [none, or the exact dependency]
- **Other session, branch, worktree, or PR ownership**: [none, or the exact constraint]
- **Worktree base state**: [current workspace, or the required verified starting point]
- **Destructive, irreversible, production, sensitive, costly, or audience-facing actions**: [none, or the approval gate]

## Current Ready Set

- [node IDs whose dependencies *and* hidden constraints are satisfied]

Dispatch only these, and only while there is runtime, safety, permission, and ownership capacity. A concurrency limit is backpressure, not a reason to queue speculative work.

## Fan-Out Subtrees

Fill this in only where a node uses `local-orchestrator`.

| Parent node | Leaves dispatched | Write ownership (must be disjoint) | Inherited boundary | Child models | Returned |
| --- | --- | --- | --- | --- | --- |
| N1 | [leaf roles and subtasks] | [paths or state; no overlap] | [inputs, data, scope, permissions, tools, workspace, authority] | [explicit models, at or below N1's] | [artifacts, evidence, blockers] |

Claude Code allows nesting three layers below the main conversation by default; this playbook uses two. `local-orchestrator` may dispatch immediately — there is no flag to verify. The cap holds because every leaf role omits `Agent` from `tools` and lists it in `disallowedTools`.

Retries reuse the node ID and workspace. A second identical failure is information — report the blocker rather than retrying again. Only the root introduces a replacement node, at any tier within the main session's ceiling.

## Worktree Lifecycle

Worktrees are not delegation units. Start in the current workspace with an auxiliary budget of zero. Only the root authorizes `isolation: worktree`.

Record the base ref deliberately: an isolated subagent branches from the repository default branch, not the parent's `HEAD`, unless `worktree.baseRef` is `"head"`.

| Permit | Owner | Canonical path | Base ref and SHA | Branch or HEAD | Creation path and isolation reason | Integration target | Cleanup condition | State |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| W1 | [owner] | [exact path] | [ref and SHA] | [branch or detached SHA] | [`isolation: worktree`, `EnterWorktree`, host UI, or Git; and why sharing fails] | [accepted handoff] | [required evidence] | [proposed / active / integration-ready / cleanup-ready / removed / preserved] |

Delete the placeholder row when no auxiliary exists. Descendants never request isolation or create, adopt, repurpose, move, or remove worktrees. Before the final response, mark each task-created auxiliary `removed` with path and registration evidence, or `preserved` with exact path, owner, branch or HEAD, blocker, and next action.

## Execution Ledger

| Node | Attempt | Result | Evidence or artifact | Downstream invalidated |
| --- | --- | --- | --- | --- |
| N0 | 1 | [Complete / Failed / Blocked] | [path, command result, diff, finding] | [none, or IDs] |

## Completeness Check

Write these down before consolidating — this is where completeness silently disappears.

- Expected: [IDs]
- Accepted: [IDs]
- Missing: [IDs or None]
- Failed: [IDs or None]
- Blocked: [IDs or None]
- Superseded: [IDs or None]

## Approval Gates

| Gate | Action | Exact scope and consequence | Required authority | Status |
| --- | --- | --- | --- | --- |
| G1 | [action] | [target, audience, cost, permanence, recovery path] | [user, or active permission-mode authority] | Blocked |

Write `None` and delete the row if nothing here needs approval. Approval of the plan or an earlier node does not authorize a broader or different irreversible action, and the permission mode is never changed to avoid a prompt.

## Fan-In and Final Verification

- **Consolidation nodes**: [IDs and expected inputs]
- **Preserved evidence**: [paths, node IDs, counts, severity, confidence]
- **Integrated validation**: [commands, runtime checks, inspection]
- **Independent verification**: [`senior-reviewer` or `test-triager` node, or why it is not needed]
- **Final diff reviewed**: [Yes / No]
- **All required nodes and gates complete**: [Yes / No]
- **Every task-created auxiliary has a final disposition**: [Yes / No / N/A]

Give a verifier the source artifacts and acceptance criteria, not the producer's summary — a verifier handed a summary verifies the summary.

## Maintenance Rules

- The root owns topology, ready-set transitions, integration, authority-bound actions, and final acceptance.
- `local-orchestrator` manages only its own subtree and never changes root topology or advances root-ready work.
- Every child stays at or below its parent in model, permissions, tools, scope, data access, workspace, and authority. Pass the model explicitly; reject a dispatch whose effective model you cannot determine.
- A dependency is real only when the downstream node consumes an accepted upstream artifact or decision.
- Keep completed outputs unless their inputs actually became invalid.
- Update the ready set after every accepted, failed, blocked, or superseded node.
- Never change or bypass a permission mode to advance a node.
- Never store credentials, sensitive access material, private local paths, transcripts, or long logs here.
- Send compact artifact paths, evidence, and blockers upward — not full histories.
- Preserve or delete this artifact according to repository policy when the task completes.
