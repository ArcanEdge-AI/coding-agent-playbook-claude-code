## Summary

-

## Type of change

- [ ] Instruction wording
- [ ] Reference document
- [ ] Skill definition
- [ ] Custom agent definition
- [ ] Template
- [ ] Documentation

## Checklist

- [ ] Markdown formatting and fenced code blocks were reviewed.
- [ ] Links and paths match the repository tree.
- [ ] `SKILL.md` files include `name` and `description` frontmatter if changed.
- [ ] Custom agent `.md` files include valid YAML frontmatter (`name`, `description`, `model`, `permissionMode`, `tools`, `disallowedTools`), declare an approved default route (`haiku` with no `effort`, or `opus` with `effort: medium`), keep the **Role perspective** / **Applying this perspective directly** / **Delegated use** structure and their stop conditions, and select no `sonnet`, `fable`, `high`, `xhigh`, `max`, or fast-mode route if changed.
- [ ] Design and testing guidance changes keep improve-before-replace, whole-affected-flow investigation, E2E-only test retention with temporary unit tests, and no invented support commitments intact.
- [ ] Instruction changes preserve authority, scope, approval gates, exceptions, and required evidence.
- [ ] No third-party skill is vendored; any companion links to its official Claude distribution, is credited in `THIRD_PARTY.md`, and has no pinned version; install instructions tell users to download companions separately and install or update them to their latest versions.
- [ ] Nothing was added for another coding-agent environment.
- [ ] No sensitive or private material was added.
- [ ] General guidance stays tool-agnostic; explicitly Claude Code–specific files, examples, and templates keep their intended scope.

## Notes
