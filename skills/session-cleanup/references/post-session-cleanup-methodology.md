# Post-Session Cleanup and Integrity Pass

The procedure behind the `session-cleanup` skill. Use it at the end of substantial work, over the complete work delta between the current implementation and its verified integration baseline, together with any staged, unstaged, and untracked changes.

The work may have spanned a long session, several compactions, many commits, interrupted runs, subagents, or more than one session. Do not assume this conversation still holds a reliable memory of all of it: after compaction it keeps a summary, not the history.

The goal is not to redesign the system or start another round of speculative refactoring. It is to leave the changed portion of the repository clean, coherent, efficient, maintainable, and tested — free of implementation debris, abandoned approaches, speculative compatibility code, and avoidable technical debt.

Development is iterative. The final codebase should keep the required implementation, not the history of how it was reached.

## Contents

- Governing principles
- The compatibility rule
- 1. Establish the baseline and reconstruct the work delta
- 2. Look for implementation debris
- 3. Check for abandoned approaches and speculative compatibility
- 4. Simplify and minimize the implementation surface
- 5. Check code quality
- 6. Check errors and edge cases
- 7. Check data and state integrity
- 8. Check security boundaries
- 9. Check dependencies and configuration
- 10. Check UI and UX changes
- 11. Check tests
- 12. Run the project's validation pipeline
- 13. Check documentation against reality
- 14. Resolve deferred-work markers
- 15. Check repository hygiene
- 16. Do a final next-developer review
- 17. Final scope check
- The completion report

## Governing principles

- Do not over-engineer it. Make it elegant, not bloated.
- Prefer the smallest complete solution that reliably solves the demonstrated problem, and the smallest maintainable implementation surface — not merely the fewest lines.
- Keep the complexity that correctness, security, data integrity, accessibility, maintainability, or a demonstrated compatibility requirement needs.
- Prefer the project's existing patterns, components, and conventions over new abstractions.
- Prefer one canonical implementation path.
- Do not rewrite working baseline code because you would have structured it differently.
- Do not expand scope unless something must be corrected for the completed work to be safe, complete, or clean.
- Remove accidental complexity the implementation introduced, and the branch-only experiments, intermediate designs, and superseded approaches nothing still requires.
- Do not keep code merely because it existed earlier in the development process.
- Solve the demonstrated present requirement, not hypothetical future ones, and add no backwards-compatibility behavior for hypothetical users or consumers.
- Leave the changed area easier for the next developer, or the next session, to understand.

## The compatibility rule

Compatibility code must have evidence. Valid evidence includes:

- currently deployed older application versions
- real persisted data in the old representation
- active API or integration consumers of the old contract
- documented supported-version requirements
- an active migration window
- repository, configuration, test, deployment, or runtime evidence that the path is still required

These are not sufficient by themselves:

- "someone might still use it"
- "for backwards compatibility"
- "to be safe"
- "future-proofing"
- hypothetical users, old data, integrations, or external consumers

Do not introduce aliases, adapters, deprecated interfaces, dual code paths, fallback APIs, compatibility wrappers, old-schema handling, transitional feature flags, or migration behavior without a demonstrated requirement.

Compatibility code that predates the work delta is different. Do not remove it because it looks old: verify callers, persisted data, supported clients, deployed versions, migrations, configuration, and dynamic usage first — the `legacy-path-retirement` skill holds that decision. If its necessity cannot be established either way, leave the pre-existing path unchanged and report the uncertainty.

Branch history is not production history. Code introduced and superseded entirely within an unmerged development branch needs no compatibility with earlier commits on that branch.

## 1. Establish the baseline and reconstruct the work delta

Determine what the work actually changed from repository evidence. Do not reconstruct the scope from conversational memory.

### Establish the integration baseline

The baseline is the branch this work will integrate into.

1. Where the repository uses the feature-branch lifecycle, a development branch integrates into its feature integration branch, and a feature integration branch integrates into the long-lived integration branch. The `feature-branch-lifecycle` skill resolves those roles.
2. Otherwise, prefer `staging` when it exists and repository evidence shows it is the normal integration target, and use `main` or the verified primary integration branch when it is not.
3. Verify the choice from `CLAUDE.md`, release documentation, configuration, branch and pull-request conventions, or history. Do not choose a baseline because a branch happens to be named `staging` or `main`.
4. Compare against the baseline's current state. When the local branch may be stale and you are allowed to refresh it, use the updated remote-tracking ref, and say which ref you used.

Find the merge base between the current branch and the baseline. The complete committed delta from that merge base through `HEAD`, together with staged, unstaged, and untracked work, is the primary cleanup surface.

If the current branch is itself the baseline, or has no meaningful committed divergence, use the verified working-tree changes and explicit task evidence as the work delta.

If a reliable baseline cannot be established, continue only with independently verified cleanup, and do not claim `complete and clean`.

### Reconstruct the delta

```bash
git merge-base HEAD <baseline>              # the fork point
git log --oneline <baseline>..HEAD          # commits in the delta
git diff --stat <baseline>...HEAD           # committed changes since the fork point
git status --porcelain                      # staged, unstaged, and untracked, at a glance
git diff --cached                           # staged changes
git diff                                    # unstaged changes
git ls-files --others --exclude-standard    # untracked files
```

Review the complete delta:

- committed changes since the merge base, and the diff against the verified baseline
- staged, unstaged, and untracked changes
- files created, deleted, renamed, or moved
- configuration and dependency changes
- schema and migration changes
- tests added or modified
- documentation changed
- generated artifacts
- scripts or tooling introduced

Do not limit the review to files you remember editing. Changes a subagent made are part of the delta whether or not you typed them, and a helper's summary of what it changed is a claim — the diff is the evidence.

Identify the intended outcome of the work, and compare it with the implementation that now exists. Distinguish:

- work-delta changes
- pre-existing baseline behavior
- unrelated working-tree changes, including another session's work in a shared checkout
- files or hunks whose ownership is uncertain

Never silently treat unrelated dirty files as part of the cleanup.

## 2. Look for implementation debris

Search the affected code for temporary or accidental artifacts:

- debug logging, print statements, and temporary tracing
- commented-out code and experimental branches of logic
- temporary UI elements, test controls, and API routes
- hardcoded test values, placeholder content, and fake or mock data left active
- temporary credentials or tokens, local paths, and environment-specific values
- scratch files, backup files, and generated files that should not be committed
- unused assets, imports, variables, functions, and components
- abandoned files and duplicate implementations
- stale feature flags and temporary bypasses
- disabled validation, authentication, or authorization
- skipped tests, and focus or skip modifiers such as `.only` and `.skip`

Remove these when they are clearly artifacts of the work delta. "Looks unused" is a lead, not a conclusion: verify that something is actually unnecessary before deleting it.

## 3. Check for abandoned approaches and speculative compatibility

Long-running work often tries several implementations before the final one emerges. Inspect the complete branch delta for churn, and determine whether later changes superseded earlier code introduced on the same branch.

Look for:

- two utilities solving the same problem, or duplicate API clients
- old components replaced by newer ones
- unused helper functions, abandoned hooks, and obsolete types or interfaces
- redundant state and multiple sources of truth
- unnecessary adapters and temporary wrapper functions
- duplicate validation logic
- transitional compatibility code that is no longer needed
- compatibility wrappers around implementations that no longer exist
- aliases preserving names that never shipped, and old interfaces created only during development
- fallback behavior for intermediate, branch-only states
- feature flags for transitions that never reached a deployed environment
- migrations whose only purpose is a schema state that was never deployed
- re-export layers or forwarding APIs that exist only because the implementation changed during the branch

Prefer one clear canonical implementation, and remove obsolete work-delta paths when doing so is safe and directly related to the completed work. Do not preserve an earlier branch implementation because another commit on the same unmerged branch once depended on it.

When the work delta introduced compatibility behavior, require evidence of a real supported dependency; without one, remove the speculative path and keep the current canonical behavior. When compatibility behavior predates the work delta, verify its usage before removal. Do not turn a cleanup pass into an unsupported legacy-removal project, and do not perform broad, unrelated codebase cleanup.

## 4. Simplify and minimize the implementation surface

Review the final implementation with fresh eyes. For each file, abstraction, wrapper, helper, state variable, configuration option, dependency, feature flag, compatibility path, and code path the work delta introduced, ask whether the demonstrated requirement needs it.

- Is there a simpler way to express this?
- Did implementation churn introduce unnecessary layers?
- Did we create an abstraction with only one meaningful use and no boundary or invariant to justify it?
- Did we create configuration where a straightforward behavior would work?
- Did we add state that could be derived instead?
- Did we build a component, dialog, hook, validator, or utility the project already had, or duplicate logic instead of using an existing pattern?
- Did we create indirection that makes the code harder to follow?
- Are there too many wrappers, factories, managers, services, hooks, or utilities?
- Did we add a dependency for behavior the repository already supports?
- Did we create more than one way to perform the same operation?
- Did we keep an earlier implementation after its replacement became canonical?
- Did we add compatibility behavior without evidence of a real consumer?
- Did we solve hypothetical future problems instead of the current requirement?

Remove work-delta code that exists only because:

- an earlier implementation was abandoned
- the agent was experimenting
- the design changed during development
- it duplicates an existing repository capability
- it anticipates an unrequested future requirement
- it supports a hypothetical legacy consumer
- it provides configuration for behavior that does not actually vary
- it adds indirection without reducing meaningful complexity

Simplify when the improvement is obvious, low-risk, verifiable, and within the scope of the completed work. This is not code golf: keep useful boundaries and necessary complexity, and do not chase architectural purity.

## 5. Check code quality

**Naming**

- Names describe purpose accurately.
- Temporary names have been replaced.
- Naming follows the project's conventions, and similar concepts use consistent terms.

**Structure**

- Functions and components have clear responsibilities.
- Logic lives where someone familiar with the repository would expect it.
- Files have not become unnecessarily large or tangled, and related behavior is grouped.
- There is one obvious canonical path for the changed behavior, unless several are genuinely required.

**Readability**

- Control flow is understandable, and clever code has not replaced clear code.
- Complex behavior is explained where the explanation is genuinely useful.
- Comments explain intent or non-obvious constraints rather than restating code.
- No comment justifies speculative compatibility with hypothetical users or future requirements.

**Duplication**

- Meaningful duplicate logic the work delta introduced has been consolidated.
- No abstraction was created just to remove trivial duplication.

## 6. Check errors and edge cases

On the paths the work delta changed, check for:

- missing error handling, swallowed exceptions, and misleading fallback behavior
- unsafe assumptions and null or undefined handling
- empty and loading states
- failed network requests, retries where appropriate, and partial failures
- malformed inputs and invalid states
- duplicate submissions, race conditions, and stale state
- unexpected API responses and permission failures

Make failures deliberate rather than accidental. Do not add elaborate defensive or fallback systems for scenarios the application cannot realistically encounter, and do not turn hypothetical edge cases into permanent compatibility architecture without evidence the system must support them.

## 7. Check data and state integrity

If the work delta touched persistence, state management, APIs, or databases, verify that:

- there is one clear source of truth, and data is not unintentionally duplicated
- writes cannot silently corrupt state, and reads use the intended canonical source
- validation happens at the appropriate boundary, and frontend validation is not treated as security
- IDs and relationships stay consistent
- migrations match the current schema, and are safe and correctly ordered
- API contracts match their consumers
- serialization and deserialization are correct
- default values are intentional
- old and new data states are both handled only when a demonstrated compatibility requirement exists

Watch for implementation changes that created two competing sources of truth. Do not add migration or dual-read and dual-write behavior because an earlier commit on the branch used a different representation — a branch-only intermediate schema is not a production migration requirement.

## 8. Check security boundaries

For everything the work delta affected, verify that the work did not leave:

- exposed secrets or credentials in source
- authentication or authorization bypasses
- overly permissive database access or insecure direct object access
- missing ownership checks
- sensitive information in logs
- unsafe client-side trust or unvalidated external input
- dangerous dynamic execution or insecure file handling
- unnecessarily exposed API endpoints

Focus on the attack surface this work touched; do not run an unrelated full security audit unless it was requested. When you find a secret, report its location — never print or copy its value.

## 9. Check dependencies and configuration

Review dependency and configuration changes in the work delta. Verify that:

- every new dependency is actually necessary, and none was added for something the project already supports
- abandoned dependencies are removed, and imports match installed packages
- lockfiles are consistent, and package versions are intentional
- environment variables are documented where necessary, and configuration defaults are appropriate
- no local-machine configuration leaked into the repository
- build configuration still reflects how the project is actually deployed
- compatibility switches or flags have a demonstrated active requirement

Prefer removing unnecessary dependencies and configuration over keeping them "just in case."

## 10. Check UI and UX changes

If the work delta affected the interface, verify the actual user flow, not only the source. Run the app and drive the flow where the environment allows — a browser or preview tool, a simulator, or the project's end-to-end harness. When you cannot, report the UI behavior as unverified instead of inferring it from the code.

Check:

- loading, empty, error, success, and disabled states
- validation messages
- navigation, including back and forward behavior where relevant
- responsive behavior
- keyboard interaction, focus behavior, labels, and basic accessibility
- accidental duplicate controls and inconsistent terminology
- stale UI after mutations, and confusing intermediate states
- obsolete controls or flows left over from an abandoned implementation

The final interface should represent the actual system state and the canonical behavior. Do not introduce visual redesigns unrelated to the task.

## 11. Check tests

Review the tests associated with the work:

- Are the important new behaviors covered?
- Do the tests verify behavior rather than implementation trivia?
- Was any existing test weakened just to make it pass, or any assertion removed without justification?
- Are skipped tests still present?
- Are fixtures or mocks left in an unrealistic state?
- Are there edge cases worth covering?
- Do old tests still describe the current intended behavior?
- Do any tests preserve branch-only transitional behavior that never shipped?
- Is every compatibility test backed by an actual supported compatibility requirement?

Add or improve tests where this work introduced a meaningful gap. Remove or update work-delta tests that only preserve abandoned branch behavior. Do not write excessive tests for trivial implementation details.

## 12. Run the project's validation pipeline

Find the repository's own validation commands — its `CLAUDE.md`, README, package scripts, task runner, or CI configuration — and run the appropriate ones:

- formatting
- linting
- type checking
- unit tests
- integration tests
- relevant end-to-end tests
- build
- project-specific verification scripts

Do not invent replacement commands when the repository already defines them. If a step cannot run, say why. Never silently ignore a failure.

Investigate each failure far enough to classify it as:

1. introduced by the work delta
2. pre-existing
3. environmental or tooling related
4. unknown, because the evidence is insufficient

Fix the failures the work delta introduced. Do not opportunistically repair unrelated failures unless this work needs them fixed. After cleanup, rerun the affected checks and re-review the comparison against the verified baseline.

## 13. Check documentation against reality

Review the documentation the implementation directly affects:

- README and setup instructions
- environment variables and configuration instructions
- API documentation and examples
- comments and architecture notes
- user-facing copy and developer documentation

Update documentation the completed implementation made inaccurate, and delete obsolete work-delta documentation where appropriate. Do not create documentation for its own sake, and do not document abandoned branch behavior as though it were still supported. Do document real compatibility requirements or constraints that the next person could not easily infer.

## 14. Resolve deferred-work markers

Search the lines the work delta added:

```bash
git diff <merge-base> -U0 | grep -nE '^\+.*(TODO|FIXME|HACK|TEMP|XXX)'
```

That covers committed, staged, and unstaged changes to tracked files; search the untracked files the delta added the same way. Also look for workaround comments and phrases such as "for now", "temporary", "later", and "remove after".

For each marker the work delta introduced or affected:

- resolve it if it should have been part of the completed work
- remove it if it is obsolete
- leave it only if it represents legitimate deferred work

Do not use a TODO as a substitute for completing required behavior, and do not leave speculative compatibility TODOs for hypothetical future consumers.

## 15. Check repository hygiene

Before finishing, verify that:

- `git status` and the baseline comparison contain nothing unexpected
- no secret or credential files are present
- no editor, IDE, or operating-system debris was introduced
- no unnecessary generated artifacts or accidental binary files were added
- no duplicate files remain from renames, and no abandoned implementation files remain in the delta
- ignore rules remain appropriate, and tool state — a `.claude/worktrees/` checkout, a local handoff file — has not been staged
- temporary scripts created for investigation are either intentionally kept or removed
- file names and directory placement follow repository conventions

Never use destructive cleanup commands blindly; inspect before deleting. Temporary branches and task-created worktrees are not removed here: list each with its state, and route branch deletion to the `feature-branch-lifecycle` skill and worktree removal to the `worktree-lifecycle` skill.

## 16. Do a final next-developer review

Pretend you did not write this code. Imagine opening the affected area tomorrow with no memory of the process — only the repository, the verified baseline, and the current branch to explain what changed.

- Can I understand what changed?
- Is there one obvious implementation path?
- Is anything misleading, or temporary but pretending to be permanent?
- Are there unexplained magic values?
- Are responsibilities clear, and is there accidental duplication?
- Are errors understandable?
- Would another developer know where to modify this behavior?
- Is any code present only because the implementation took several attempts?
- Is any compatibility path present without a real supported consumer?
- Did the work delta leave technical debt that can reasonably be eliminated now?

Fix clear problems. Do not start another redesign.

## 17. Final scope check

Before making any additional cleanup change, ask:

> Is this necessary to correctly complete, simplify, stabilize, or clean up the current work delta?

If not, leave it alone and record the unrelated baseline issue separately. Cleanup is not permission for broad refactoring.

## The completion report

Report in the exact five-section shape the skill's `SKILL.md` defines. What belongs in each section:

- **Cleaned Up** — the meaningful cleanup performed, not every keystroke.
- **Validation** — each check actually run, and its outcome. A check that could not run is listed with the reason, never as a pass.
- **Problems Found** — defects, incomplete work, accidental technical debt, abandoned approaches, speculative compatibility paths, and unnecessary complexity discovered.
- **Remaining Issues** — work-delta-introduced issues, pre-existing issues, and optional future improvements, kept separate, each with the reason it was left unresolved.
- **Final State** — exactly one of `complete and clean`, `complete with documented remaining issues`, or `not yet safe to consider complete`.

Do not claim success when validation was not actually performed. Do not claim `complete and clean` when the integration baseline, the ownership of material changes, or material changed behavior remains unresolved.
