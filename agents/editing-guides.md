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
