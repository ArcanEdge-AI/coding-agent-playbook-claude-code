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
- [ ] Design and testing guidance changes keep improve-before-replace, whole-affected-flow investigation, proportionate testing, and no invented support commitments intact.
- [ ] Generic policy changes were compared with the companion Codex playbook; any intentional divergence names its harness-specific reason.
- [ ] No sensitive or private material was added.
- [ ] The change stays tool-agnostic unless it is explicitly an example.

## Notes
