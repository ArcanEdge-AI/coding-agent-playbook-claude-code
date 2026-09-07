---
name: task-graph-orchestration
description: Use for a complex Claude Code task with substantial fan-out, several genuine dependencies, broad repository scope, layered consolidation, separate implementation and verification paths, or an approval-gated irreversible action. Makes the work topology explicit in Markdown, runs only the parts whose inputs are ready, preserves completeness through consolidation, and reruns only what a failure actually invalidated. Skip it for small or genuinely linear work.
---

# Task Graph Orchestration

For work complicated enough that "what can start now?" stops being obvious, write the topology down before you execute it.

This is a planning discipline expressed in Markdown. It adds **no** graph database, scheduler, runner, schema package, or orchestration framework. You still do ordinary work and dispatch ordinary subagents; the graph is how you keep track of what is ready, what is blocked, and what a failure invalidated.

## When it earns its cost

Use a formal graph when several of these hold:

- Multiple independent investigations can run concurrently.
- Several subagents will be involved.
- Many similar items must be audited or transformed with no omissions.
- Results need layered consolidation.
- Implementation branches share contracts, schemas, interfaces, or mutable state.
- A schema or interface change creates downstream consumers.
- The result is hard for the user to verify by eye.
- The task ends in deployment, deletion, publication, outbound communication, or another approval-gated action.

Skip it when the work is small, genuinely linear, dominated by one coherent design judgment, confined to tightly coupled writes, or simply cheaper to do than to model. Skipping the graph does not mean skipping delegation — the normal engineering loop still applies.

## Preflight

1. Read the request, the repository state, the applicable `CLAUDE.md`, the validation surfaces, and who already owns what.
2. **Run `multi-session-coordination` first** if other sessions, branches, worktrees, pull requests, or active-work records might touch this. Treat their work as external constraints; your graph does not control it.
3. State the goal and the observable success criteria.
4. Note the main session's model for provenance only. It does not set the subagent route — each role's model and effort are fixed regardless.
5. Identify every action that will need explicit approval — audience-facing, destructive, irreversible, sensitive, production-affecting, materially costly, or outside current authority.
6. Read `references/templates/task-graph.md` before creating a graph artifact.
7. Read `references/worktrees.md` if any node proposes or already uses an auxiliary checkout.

Keep a medium graph in your working plan. For long-running, multi-phase, or multi-session work, write `.claude/coordination/task-graphs/<task-slug>.md` when repository policy allows a local coordination artifact. Do not create a repository artifact for an informational question or a task that does not authorize changes.

## Define the nodes

Each node gets:

- a stable ID
- one bounded goal
- an executor — a named subagent role, or yourself for orchestration, integration, verification, approval, and final acceptance
- its authoritative inputs
- a declared output shape and acceptance condition
- only the upstream nodes whose **accepted output it actually consumes**
- read scope, and write ownership if it edits
- the bundled role (which fixes its effort), with that role's model on the dispatch
- permission mode and tool boundary
- an exact workspace
- a verification gate proportionate to the risk
- a status

## Audit every edge

For each proposed dependency, ask one question:

> **Can the downstream node begin correctly without an accepted output or decision from the upstream node?**

If yes, there is no data dependency. Delete the edge. Narrative order is not dependency, and every false edge costs you parallelism.

Then look separately for the constraints that do not appear as data edges:

- overlapping file or mutable-state writes
- schemas, migrations, interfaces, public contracts
- shared ports, services, environments, locks, credentials, rate limits
- cost or resource ceilings
- active ownership in another session or worktree
- worktree base-state requirements
- destructive, irreversible, production, or audience-facing actions

Add explicit consolidation nodes where several outputs must combine. Add independent verification nodes for high-risk claims. Add approval nodes immediately before actions that need authorization. Then identify the path that actually controls completion, and the initial ready set.

## Dispatch only what is ready

A node is ready when every declared dependency has an **accepted** output and every hidden constraint is satisfied.

- Dispatch ready nodes with remaining runtime, safety, permission, and ownership capacity.
- Concurrent-subagent limits are backpressure, not a reason to queue speculative work.
- If parallelism is unavailable, run ready nodes sequentially while preserving dependencies.
- Keep architecture, security judgment, destructive operations, migrations, concurrency design, public API compatibility, and final acceptance with yourself.
- Use `plan` mode roles for exploration, research, and review; `default` for write-capable roles. Remember `plan`-mode subagents cannot reliably run suites — route execution to `test-triager`.
- Pass the role's model explicitly on every dispatch (`haiku` for lookup roles, `sonnet` for judgment roles) and use a bundled role so its fixed effort applies. The route is the same at every layer, for retries, and for replacements; a forced subagent model or an allowlist substitution is a constraint to report, not a substitute to accept.
- Start in the shared workspace with an auxiliary-worktree budget of zero. Only you may authorize `isolation: worktree`, and descendants never request it.

Add to the standard assignment:

```text
Graph node:
Depends on (accepted outputs consumed):
Declared inputs:
Output shape and acceptance condition:
Read scope / write ownership:
Model: [haiku or sonnet, per role]
Role (and its fixed effort):
Permission mode and tools:
Exact workspace:
Verification gate:
```

A subagent must not restructure your graph, consume undeclared inputs, widen its own capabilities, or report a blocked dependency as complete. A `local-orchestrator` manages only its declared subtree, and returns its output or an exact gap.

## Update state after every return

1. Check the output against its acceptance condition and the primary evidence.
2. Record status, evidence, artifacts, and any assumption that changed.
3. Keep dependents blocked while an output is missing, failed, or rejected.
4. Recompute the ready set.
5. Before consolidating, write down which node IDs you expected, received, are missing, failed, or blocked.

For large fan-out, consolidate in layers. Preserve node IDs, paths, evidence references, counts, severity, and confidence. Do not collapse specific findings into a vague summary — that is where completeness silently disappears. Confirm every expected node appears exactly once or is explicitly listed as missing, failed, blocked, or superseded.

## Verify and retry narrowly

Use an independent `senior-reviewer` or `test-triager` node when risk, blast radius, or unverifiable synthesis warrants it. Give the verifier the source artifacts and the acceptance criteria — **not** the producer's summary. A verifier handed a summary verifies the summary.

When a gate fails:

- Keep accepted outputs from unrelated nodes.
- Rerun the failed node on the same route; do not change the model or raise effort to make it pass.
- Rerun downstream nodes **only** where the input they consumed actually became invalid.
- Recompile the affected portion when the failure reveals a missing edge or a wrong decomposition.
- Stop retrying when the same failure repeats, and report the blocker.

Before completion: verify combined behavior and the final diff, confirm the completeness counts, and confirm no required node or approval gate is still open. Reconcile every task-created auxiliary worktree.

## Approval gates

Do the safe inspection, reversible preparation, and validation before the gate.

Immediately before the gated action, state the exact target, scope, consequences, cost, audience, and rollback path. Then stop until authorization is explicit.

The active permission mode still applies, and you never change or bypass it to avoid a prompt. Approval of the plan, or of an earlier node, does not authorize a broader or different irreversible action.

## What this is not

Soft semantics, not a scheduler. Concurrency may be unavailable, graph state can drift, your dependency classification can be wrong, and there is no caching or transactional state. Recheck repository state, ownership, node inputs, permission mode, and approval status at every consequential transition.

Do not describe the result to the user as a graph runtime or a mechanically enforced workflow. It is a plan you are keeping honestly.
