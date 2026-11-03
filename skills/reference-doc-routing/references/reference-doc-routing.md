# Reference Document Routing

Reference documents are useful exactly when they are routed. Dumped wholesale into a prompt they are noise; ignored entirely they let you rebuild something the project already decided.

The rule that governs all of this:

> **A reference document describes what someone intended. The code describes what is true. When they disagree, the code wins and the disagreement is worth reporting.**

## When to reach for one

Consult reference docs when the task touches architecture, domain rules, API contracts, data models, schemas or migrations, testing strategy, design-system conventions, safety and access-control requirements, release or deployment expectations, worktree ownership and lifecycle, known pitfalls, recurring mistakes, or subagent role definitions and review checklists.

Skip them when the answer is directly readable from the code and reading the doc would only add a second, possibly stale, account of it.

## Classify before you rely

Every document gets one of three labels, and the label changes how much weight it carries.

### Authoritative

Repository or user instructions explicitly make it the source of truth. Follow it, and raise a conflict rather than quietly deviating.

Typically: the current API contract, schema migration rules, design-system rules, access-control model, release checklist.

### Advisory

Useful guidance that current code, tests, or user instructions can override.

Typically: architecture overviews, style guidance, testing recommendations, implementation notes.

### Historical

It may describe past decisions or behavior that no longer exists.

Typically: incident notes, old migration plans, archived design proposals, superseded implementation docs.

Never rely on a historical document for current implementation without verifying it first. The most expensive version of this mistake is implementing against an architecture document that describes the system as it was two refactors ago — everything reads coherently and none of it matches the code.

Signals that a document has drifted: it references files, symbols, or endpoints that no longer exist; its examples use an API shape the code no longer has; it predates a migration you can see in the history; it contradicts the tests.

## Read narrowly

Find the sections that bear on the task and read those. A large document read end to end costs context that the actual code needed.

`Grep` the document for the symbol, endpoint, table, or concept you care about, then read around the hits. Read the whole document only when the task is genuinely about the whole subject.

## When a document and the code disagree

Two different questions are hiding in every disagreement: what the system *does* now, and what it *must* do. Evidence answers the first; authority answers the second.

1. **Settle authority first.** Follow the host's instruction hierarchy, then the relevant scope and specificity within the same authority level. An authorized requirement, an explicit user decision, or an approval gate governs the target behavior.
2. **Say so.** Report the conflict, keeping what the system currently does separate from what the governing requirement says it must do. Do not silently pick one.
3. **Establish current behavior from primary evidence.** Code, tests, schemas, configuration, and runtime observations show what is true now — but code or a passing test does not override an authorized target contract, a user decision, or an approval gate.
4. **Work out which is wrong.** Sometimes the code is a bug and the doc is right; sometimes the doc is stale; sometimes the code is deliberately working around something the doc does not mention. These lead to different actions.
5. **Update stale documentation only within the task's authority**; otherwise flag it. Do not silently decide which requirement to discard.

Primary evidence is: current code, tests, schemas, configuration, logs, build output, typecheck output, runtime behavior, and authoritative external documentation.

## Passing documents to subagents

A subagent starts with a fresh context. It sees only what you send.

Send **the path and the relevant section**, not the document:

```text
Reference documents:
- docs/api-contracts.md, "Checkout" section — authoritative. Follow the request
  and response shapes exactly.
- docs/architecture.md, "Payments" section — advisory, and last updated before
  the Stripe migration. Verify anything you take from it against current code.

Verify implementation-relevant claims against the current code before relying
on them. Do not summarize unrelated sections.
```

Always tell the subagent which label applies. A subagent given an unlabeled document treats it as truth, and you will get back work built on a stale premise with a confident summary attached.

Require claims supported by evidence, not agreement: the subagent should come back with the paths and symbols it checked, not with a restatement of the document you sent it.
