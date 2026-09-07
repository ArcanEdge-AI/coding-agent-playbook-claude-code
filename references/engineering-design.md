# Engineering Design Decision Aid

Build the smallest complete solution that solves the actual problem correctly and fits the existing system. The global instructions state that standard; this reference holds the questions and worked cases for applying it when a design choice is not obvious.

## When to open this

Reach for selected questions when a change is non-trivial, cross-cutting, or hard to reverse; when you are about to add an abstraction, layer, dependency, persisted state, or configuration mechanism; or when an implementation starts accumulating special cases and workarounds. Do not run the whole list for routine work, and record only the assumptions and tradeoffs that materially affect the outcome.

The record, when one is warranted, is a few sentences in the plan or the change description: the problem, the option chosen, the alternatives rejected, and why. Its length tracks complexity, risk, and consequence — a private helper needs nothing; a change to a shared contract or a persisted schema deserves the comparison written down.

## Decision questions

Problem and scope:

1. What actual problem and desired behavior are we addressing? Restate it without the proposed solution embedded in it.
2. Does the proposed change solve the root cause or only its symptom? Is the root cause within the authorized scope? If not, what gets reported?
3. Which assumptions are constraining the approach, and which of them have been checked against the code rather than inherited from the request?

Simpler paths:

4. Could a different approach eliminate the problem, or the need for new machinery, entirely?
5. Can an existing capability — a utility, a pattern, a library already in use, a field that already exists — satisfy the requirement?
6. Can the implementation be clearer or smaller while remaining complete, including integration and verification?
7. Does the existing architecture already provide the appropriate pattern? If you are departing from it, what makes the existing pattern harmful or insufficient here?

Cost of the change:

8. What complexity does this introduce — new concepts, moving parts, states, places that must change together?
9. Which current requirement, boundary, invariant, duplication, or demonstrated variability justifies that complexity?
10. What maintenance burden does it create, and who carries it?
11. When the requirement changes, which components change with it, and is that ripple proportionate to the size of the requirement change?
12. Can another engineer understand the purpose and the constraints from the code and its necessary documentation, without this conversation?
13. On current evidence, does this make likely future changes easier without building for hypothetical ones?

## Earned abstractions

An abstraction earns its place by delivering a concrete benefit now. The benefit can be a real boundary or invariant, meaningful duplication removed, demonstrated variability isolated, or change amplification reduced. Repetition alone is not a reason to generalize, and use-count alone is not a reason to refuse.

A single-use adapter that isolates an external dependency or translates a foreign contract can be justified by its boundary even though nothing else calls it: it keeps the dependency's shape from leaking into domain code, and it gives the replacement a seam.

Conversely, two similar-looking functions may serve different rules and change for different reasons. Merging them because their syntax matches buys a shared function with a growing parameter list and conditional branches. Combine problems only when they share demonstrated behavior, an invariant, or a meaningful boundary.

Prefer clear responsibilities and small interfaces. Wrappers, managers, factories, service layers, plugin systems, and configuration mechanisms that add indirection without a present benefit are complexity with no payer. No category of abstraction is inherently forbidden or required; each one answers question 9.

## Simpler approaches and complete fixes

**Derived versus stored state.** If a value can be reliably derived from existing state, storing a second copy creates synchronization and consistency work that never ends. Inspect the actual requirement — latency, atomicity, audit — before introducing the copy, and if you do, name the invariant that keeps the two in step.

**Workaround versus boundary fix.** A small patch that repeats a workaround at each call site can cost more to maintain than a focused change at the correct boundary. Compare the two by completeness, affected surfaces, reliability, and verification needs — not by counting changed lines. A broader root cause is not permission for an unrelated redesign; it is a reason to fix the boundary that is in scope and report the rest.

**Structural change versus smaller patch.** A necessary structural change can be the smallest complete solution when the alternative is a workaround that introduces hidden coupling, a second source of truth, or a fragile special case. Prefer the structural change when it is within scope and its benefit is concrete; prefer the targeted change when it solves the problem completely on its own.

**Change amplification as a signal.** If a one-line requirement change would touch five files across three layers, the structure is misaligned with how the requirement actually varies. That does not always mean fix it now — but it should be named, and it should inform where the current change lands.

## Material technical debt

Prefer avoiding known debt. When constraints justify a material compromise, record three things:

- **Scope** — the affected behavior or component and the limitation being accepted.
- **Rationale** — the constraint, and why the tradeoff beats the available alternatives.
- **Follow-up condition** — the event, requirement, or agreed milestone that should trigger reassessment or removal.

For example, a compatibility adapter may remain while a supported caller still uses the older contract; its removal is tied to that caller's migration. A bounded transition with a named exit is different from a fragile workaround that quietly became permanent.

Write the record into the existing plan, the change description, or the project's maintained documentation. Do not invent a tracking system, a deadline, or a cleanup commitment without a real need and the authority to make it. And do not apply this to minor implementation choices — a reporting ritual for every small decision buries the tradeoffs that matter.

## Review questions for the finished change

Before calling a meaningful change done, ask:

- Is it complete — integrated, verified, and free of unconverted callers or unrun checks?
- Is anything in it speculative — flexibility, configurability, or generality nobody asked for and no current requirement uses?
- Did it introduce a duplicated source of truth, hidden coupling, or a workaround where a boundary fix was in scope?
- Would a small change in the requirement now ripple further than it should?
- Is every material tradeoff recorded with scope, rationale, and follow-up condition?
- Can it be tested, debugged, replaced, and removed without archaeology?
