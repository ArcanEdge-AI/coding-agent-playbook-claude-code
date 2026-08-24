<!-- Coding Agent Playbook — Claude Code Edition. Managed file; edits are replaced on update. -->

# Elegant Code, Simplicity, and Surgical Changes

## Elegant code

Prefer code that is boring, clear, and hard to misuse.

- Match existing architecture and style before introducing a new pattern.
- Name things for intent and domain meaning.
- Keep functions, modules, components, and public APIs small and focused.
- Make invalid states hard to represent where the language supports it.
- Prefer explicit data flow over hidden global state, implicit mutation, or clever indirection.
- Prefer local reasoning over action at a distance.
- Prefer existing utilities, libraries, and conventions over new ones.
- Add a dependency only when it clearly reduces complexity or risk; ask before adding production dependencies unless repository guidance says otherwise.
- Keep error handling proportional to realistic failure modes and existing contracts.
- Comment non-obvious intent, invariants, tradeoffs, safety concerns, and external constraints. Do not comment obvious code.
- Avoid speculative abstractions, generic frameworks, and unrequested configurability.
- Introduce an abstraction when the current code benefits now, not because future code might.
- Delete complexity your change makes unnecessary — but only complexity related to the task.

A senior engineer should be able to say: "This is the smallest clear change that fits the codebase."

## Simplicity first

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No unrequested flexibility or configurability.
- No rewrite where a targeted change suffices.
- No new state unless existing state cannot represent the requirement.
- No new dependency when the platform or codebase already solves it.
- No error handling for cases the existing contract makes impossible, unless the failure would be severe or the codebase consistently handles it.
- If the solution is growing, stop and look for a simpler existing pattern.

Ask: "Would a senior engineer call this overcomplicated?" If yes, simplify.

## Surgical changes

Touch only what the task requires.

- Do not overwrite or revert unrelated local changes.
- Do not reformat unrelated files.
- Do not clean up adjacent code unless the task needs it.
- Do not refactor what is not broken.
- Match existing style even where you would choose differently in a new project.
- Do not edit generated, vendored, compiled, or package-owned files unless repository guidance requires it or the user asks.
- When you notice unrelated dead code, defects, flaky tests, or design problems, mention them instead of fixing them.

Remove only imports, variables, functions, types, files, and code paths your change actually orphaned. Leave pre-existing dead code alone.

Every changed line should trace to the user's request.
