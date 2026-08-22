---
name: reference-doc-routing
description: Use when a task might need architecture, testing, access-control, design-system, API, release, data-model, subagent, or worktree reference documents. Helps pick the ones that matter, judge how much authority each has, read only the relevant sections, and pass concise labeled context to subagents.
---

# Reference Doc Routing

A reference document tells you what someone intended. The code tells you what is true. Route documents so you get the intent without inheriting the drift.

Full detail: `references/reference-doc-routing.md`.

## Workflow

1. **Identify what actually needs reference context.** Much of a task is answerable from the code alone. Reading a document you did not need costs context the code needed.
2. **Find the candidates** — global references under the Claude Code home, and repository docs.
3. **Classify each one:**
   - **Authoritative** — instructions make it the source of truth. Follow it; raise conflicts rather than deviating.
   - **Advisory** — useful, but current code, tests, or user instructions override it.
   - **Historical** — may describe decisions or behavior that no longer exist.
4. **Read narrowly.** `Grep` for the symbol, endpoint, table, or concept, then read around the hits. Read end to end only when the task really is about the whole subject.
5. **Check for drift.** Does it reference files, symbols, or endpoints that no longer exist? Do its examples use an API shape the code has moved past? Does it predate a migration visible in the history? Does it contradict the tests?
6. **Verify anything implementation-relevant against the code** before you rely on it.
7. **Report conflicts** between a document and primary evidence. Do not silently pick one — work out whether the doc is stale, the code is a bug, or the code is deliberately working around something.

## Passing documents to a subagent

A subagent has a fresh context and sees only what you send. Send the path, the section, and **the label**:

```text
Reference documents:
- docs/api-contracts.md, "Checkout" section — authoritative. Follow these
  request and response shapes exactly.
- docs/architecture.md, "Payments" section — advisory, last updated before the
  Stripe migration. Verify anything you take from it against current code.

Verify implementation-relevant claims against the current code. Do not
summarize unrelated sections.
```

An unlabeled document is treated as truth. That is how you get back confident work built on a stale premise.

Ask for evidence, not agreement: the subagent should return the paths and symbols it checked, not a restatement of what you sent.

## Primary evidence

Current code, tests, schemas, configuration, logs, build output, typecheck output, runtime behavior, and authoritative external documentation.
