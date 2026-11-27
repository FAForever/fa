# Editing the agent guides

Read the root [AGENTS.md](../AGENTS.md) first. These rules apply to `AGENTS.md`, the guides in `agents/`, [annotation.md](../annotation.md), and agent skills.

## Where a fact goes

- Give each fact one home and link to it from elsewhere. Engine behavior goes in the [engine/](../engine/) stub, the behavior of a Lua file goes in that file, and a guide says where to look and what is easy to get wrong ([annotation.md](../annotation.md#rules), rule 5).
- Every session loads `AGENTS.md`, and agents read a guide only when they decide to. Put a rule in `AGENTS.md` only when agents break it before they would think to look it up, such as calling an engine function that doesn't exist in the Lua state the code runs in. Put everything else in the guide for its path.
- Give every new guide a row in the `AGENTS.md` table. Agents don't find a guide that has no row.
- Keep test procedures to what an agent can't work out from the stubs. Checks that must always pass belong in CI.

## What gets in

- Add a rule only for a mistake an agent made or a request from a reviewer. Name it in the commit message, not in the guide.
- A PR that adds a skill shows the skill in use, in proportion to its scope.
- Check a claim in game or in the code before writing it. Say when it depends only on faf-re ([Gotchas](../AGENTS.md#gotchas)).
- Leave out the results of a single test run, and procedures that ignore what the engine allows, such as a fixed wait.
- Leave out exploits and other security findings until they are fixed and released.
- Notes about one person or machine go in personal files ([Personal notes](../AGENTS.md#personal-notes)).

## How to write

- Say what to do. Leave out the reasoning, the history, and examples, unless the rule is unclear without them.
- The [code style](../AGENTS.md#code-style) and [comment style](../annotation.md#comment-style) rules apply: short declarative sentences, the serial comma, no em-dashes, and links to the file with the name of the function or field, not a line number.
- Write for any coding agent. `CLAUDE.md` only imports `AGENTS.md`, and nothing in `AGENTS.md` or `agents/` depends on one harness.

## Testing a change with agents

Test guide changes with subagents or other sessions only when the user asks for it. Otherwise finish the change, and in the final report say it wasn't tested with agents and suggest the test below.

1. Make one copy of the repository per run, in a folder with a neutral name, so runs don't change each other's files. Check out the commit the change is based on, remove the remote, and add the change as one commit with a neutral message, so the history doesn't hint at the change. If the change moves or removes files, fix the links to them so that agents don't look for the files in other checkouts.
   To save disk space, clone with `git clone --shared`, which reuses the original's objects, and unless the change is about assets, use a sparse checkout that leaves them out. They are most of the repository's size.
2. Start each agent in the copy with no context but the task: a new session, or a subagent that doesn't inherit the current session's context. If the agent doesn't load the instructions file at startup, as subagents often don't, tell it to read the file first.
3. Give a realistic task in the area the change covers, and let the agent make the change.
4. When it's done, check which guides it opened in its tool calls, and grade the changes in its copy against the rules the change adds. If the harness doesn't show a subagent's tool calls, ask the agent which files it read.
5. Test several models, because stronger models are more likely to find guides than weaker ones.
6. In the PR description, list each run's harness, model, task, the guides it opened, and the rules it missed, and say when the startup load was simulated.
