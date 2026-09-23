---
name: handoff
description: Use when the user asks for a handoff, a fresh continuation session, a clean start that keeps the context, or to carry "everything we have worked on, researched, explored, validated, or verified" into a new Claude Code session. Assembles a complete, evidence-labelled context package, delivers it as a self-contained seed prompt (with a durable file when warranted), and names only session actions Claude Code actually supports for starting the new session. Authorizes preparing the continuation, not continuing the work.
---

# Handoff

Move the current work into a fresh Claude Code session without losing decisions, evidence, failures, workspace state, or the real next gate.

The new session starts with no memory of this one. Everything it needs to continue correctly has to be in the package, and everything in the package has to say how it is known.

A handoff request authorizes gathering and packaging the context, titling the continuation, and telling the user how to start it — and starting it yourself only when the user asks you to, through a supported action. It does not authorize code changes, commits, merges, deployment, publication, cloud or external mutation, destructive cleanup, or continuing the underlying work.

## 1. Establish current truth

Before composing anything:

1. Treat the conversation, the repository, connected services, memory, and the user's statements as separate evidence sources.
2. Recheck the cheap, drift-prone facts that matter to the next session: repository path, branch or ref, commit, upstream and ahead or behind, dirty state, pull-request, check, and review status, deployment state, active worktree, and relevant external access state.
3. Keep verified-current, user-reported, historical, and unverified facts distinct. Never upgrade a source change, a merge, or an old test result into deployed acceptance.
4. Preserve unrelated local work. Record dirty or user-owned paths; do not clean, reset, move, stage, or overwrite them.

Read `references/context-contract.md`, packaged with this skill, before assembling the package. It holds the evidence labels, the material-context inventory, the repository rules, a seed-prompt skeleton, and the completeness check.

## 2. Build the context package

Include all the material context the next session needs to continue correctly — not a transcript:

- the objective and the current verdict
- work completed, with its exact artifacts
- research, experiments, alternatives, and causal findings
- validations run, exact outcomes, warnings, and what they do and do not prove
- user decisions, approvals, rejected approaches, and non-negotiable invariants
- repository, worktree, branch, pull-request, release, and external-system anchors
- the state the playbook's other workflows carry: the plan or task graph with its ready, blocked, and invalidated items and open approval gates; task-created worktrees and their dispositions; branch roles and promotion state; ownership agreed with other sessions
- failures, dead ends, pre-existing defects, and why they were classified that way
- unresolved risks, missing evidence, and the precise next gate
- authorization boundaries — including who handles git — and the actions the next session must not infer

Use exact paths, identifiers, commits, pull requests, run IDs, test counts, and evidence locators wherever they prevent rediscovery or mistakes. Cut repetition and conversational noise. Never include credentials, tokens, private keys, session cookies, sign-in links, device codes, secret values, customer prose, or sensitive payloads the next session does not need.

## 3. Deliver it

The deliverable is always one **self-contained seed prompt**: a reader with no access to this conversation can act on it correctly. It ends with the instruction in the context contract — acknowledge the inherited state, refresh drift-prone facts, state the exact next gate, and start nothing consequential without the user's authority.

Write a durable copy as well when the user asks for one, when the package is too long to paste reliably, or when the next session will start somewhere this output is not visible. Use a path the user names; otherwise `.claude/handoff/<short-slug>.md` in the repository the next session will use. Check whether that path is ignored, and if it is not, tell the user the file is untracked. Never commit it.

Give the continuation a short, unambiguous title, then tell the user exactly how to start it. These are the supported ways to start a **fresh** session — one that begins with no history but the seed prompt:

| Where | How | Notes |
| --- | --- | --- |
| A terminal, in the checkout the package names | `claude -n "<title>"`, then paste the prompt — or pass it as the first prompt: `claude -n "<title>" "<prompt>"` | The default. The session runs in that checkout, so it sees uncommitted work. Pasting avoids quoting trouble with a long prompt. |
| The current terminal | `/clear`, then paste the prompt | Starts a new conversation with an empty context. This one stays saved and resumable with `/resume`. |
| The desktop app | Start a new session in the same project folder, then paste the prompt | Leave the worktree option off unless the package names a worktree. |
| A background session, started for the user | `claude --bg --name "<title>" "<prompt>"` from the repository | Only under the conditions below. |

These session actions are not a fresh continuation, so never offer them as the handoff:

- `claude --continue`, `claude --resume`, and `/resume` reopen an existing conversation with its full history.
- `/branch`, `--fork-session`, and `/fork` copy the existing history into another session.
- `claude -p` runs headless and exits. It would start the work with nobody watching.
- Cross-session messaging reaches a session that already exists; it does not create a fresh one.

The user performs the terminal, `/clear`, and desktop steps. Claude Code documents no tool for the model to open a new interactive session, so your part is the exact steps — or, under the conditions below, running the CLI.

### A background session, only when the user asks for one

Start the continuation yourself only when the user asks you to start it, not merely to prepare it. It runs a model on the user's account and leaves a session they must manage, and agent view, which manages background sessions, is a research preview. Know what a background session does:

- It begins working on its prompt immediately, in the permission mode a new `claude` session in that directory would start in.
- It reads the current checkout, but before it edits anything it moves into its own git worktree under `.claude/worktrees/` — unless the repository sets `worktree.bgIsolation` to `"none"`. That worktree branches from the repository's default branch, or from the current local `HEAD` when `worktree.baseRef` is `"head"`. **Uncommitted work never comes along.**
- When it has changed files in that worktree, it commits them without asking and pushes the branch when a remote exists, unless the task, `CLAUDE.md`, or memory says the user handles git.

So use it only when everything the continuation needs is committed where its worktree will start — or the continuation only reads — and the seed prompt states the git authority explicitly. Its worktree belongs to that session, not to this task's worktree budget.

Run it from the checkout the package names; a background session starts in the directory it is launched from. It prints the session ID. Then verify: `claude agents --json` lists it among the active sessions, and `claude logs <id>` shows that it acknowledged the inherited state without starting anything else. Give the user `claude attach <id>` to open it.

## 4. Verify the handoff

Do not claim success because text was written.

- Reread the prompt, or the file, against the completeness check in the context contract.
- Confirm that the workspace, branch, and artifact paths it names exist as it describes them.
- Confirm it tells the next session to recheck live state before acting.
- Confirm that nothing — a merge, deployment, publication, cloud mutation, destructive action, or the underlying work — started as a side effect.
- Leave the source session alone: do not archive, delete, or rename it unless the user asks.

Finish with a short confirmation: the handoff title, the file path if one was written, how to start the new session, and — only if you started one — its session ID. When no session was created, say so plainly.
