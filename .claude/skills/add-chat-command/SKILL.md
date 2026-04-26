---
name: add-chat-command
description: Add a new in-game chat slash command (e.g. `/foo <arg>`) to the FAF chat system. Use when the user asks to add, register, or scaffold a new chat slash-command, or extend the `/help` listing with a new entry. Creates the command file under `lua/ui/game/chat/commands/builtin/`, wires it into `ChatController.RegisterBuiltinCommands`, and follows the parser/Accept/Execute split documented in `lua/ui/game/chat/commands/design.md`.
---

# Adding a chat slash-command

Use this skill when the user wants a new `/something` command available in the in-game chat edit box.

## Before you start — clarify with the user

Ask only what you can't infer:

1. **Canonical name** — the slash word users type (e.g. `whisper`). Lowercase, no spaces. Aliases optional.
2. **What it does** — one sentence; this becomes `Description` and is shown by `/help`.
3. **Parameters** — name, type, and whether each is optional. Types are listed below. If unsure, propose a shape based on similar existing commands and confirm.
4. **Side effect target** — does it call `ctx.Controller.X`, a `SimCallback`, a global engine function, or just print a system line? Most commands route through `ctx.Controller` to preserve MVC discipline.
5. **Gating** — should the command only register in some sessions (observer-only, replay-only, single-player-only, host-only)? If yes, use `ShouldRegister`.

If the user gives a fully-specified ask ("add `/ping` that prints 'pong' to the local feed"), skip the Q&A and proceed.

## Files you will touch

| File | What changes |
|------|--------------|
| `lua/ui/game/chat/commands/builtin/<Name>.lua` | **New file**. Exports a single top-level `Command` table. |
| `lua/ui/game/chat/ChatController.lua` | Add one `Registry.RegisterFromPath(...)` line inside `RegisterBuiltinCommands` (around line 102). |

Do **not** touch:
- [ChatCommandRegistry.lua](lua/ui/game/chat/commands/ChatCommandRegistry.lua) — the dispatcher is generic.
- [ChatCommandTypes.lua](lua/ui/game/chat/commands/ChatCommandTypes.lua) — only edit if the command needs a brand-new parameter resolver type. Prefer reusing existing types.
- [ChatModel.lua](lua/ui/game/chat/ChatModel.lua) — commands never write to the model directly; they go through the controller.

## File naming

- Filename matches the command in PascalCase: `whisper` → `Whisper.lua`, `gift-resources` → `GiftResources.lua`.
- Place under `lua/ui/game/chat/commands/builtin/`.
- One command per file. Even if two commands share a helper, give them their own files and lift the helper to a sibling module if needed.

## Command descriptor template

```lua

-------------------------------------------------------------------------------
-- /<name> [<args>] — one-line summary mirroring the Description field, plus
-- any constraints worth flagging to a future maintainer (sim callbacks used,
-- gating rules, surprising defaults).

---@type UIChatCommand
Command = {
    Name        = '<name>',
    Aliases     = { '<short>', '<other>' },          -- optional; remove if none
    Description = '<one-line summary shown by /help>',
    Params      = {
        { Name = '<arg1>', Type = 'String' },
        { Name = '<arg2>', Type = 'Int', Optional = true },
    },
    ShouldRegister = function()                      -- optional; remove if always-on
        return GetFocusArmy() ~= -1                  -- e.g. hide from observers
    end,
    Accept = function(args, ctx)
        -- Semantic checks against runtime state. Return (false, "/<name>: reason.")
        -- on rejection. The string is shown to the user as a local system line.
        return true
    end,
    Execute = function(args, ctx)
        -- Side effect. Prefer ctx.Controller.X over importing modules directly.
    end,
}
```

Module file structure rules:

- The export is a **bare top-level `Command` global**, not `return { Command = ... }`. The registry reads `module.Command` after `import`. Match the existing files — see `Whisper.lua` or `Recall.lua`.
- Do **not** call `Registry.Register` inside the file. Registration happens once, centrally, in `ChatController.RegisterBuiltinCommands`.
- Importing the file must have **no side effects**. The command stays inert until the controller registers it.
- Keep `import(...)` calls at the top of the file (e.g. `local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")` — see `GiftResources.lua`). Don't import inside `Execute`.

## Parameter types

Defined in [ChatCommandTypes.lua](lua/ui/game/chat/commands/ChatCommandTypes.lua):

| Type | Accepts | Resolved value |
|------|---------|----------------|
| `Recipient` | `"all"`, `"allies"`/`"team"`, nickname, army ID | `'all' \| 'allies' \| number` |
| `Player` | nickname or army ID (also accepts a leading `@`) | `number` (army ID) |
| `Int` | integer literal | `number` |
| `String` | one whitespace-delimited token | `string` |
| `Rest` | every remaining token, joined with single spaces | `string` |

Rules:
- Param order = token-consumption order.
- Only the **last** param may be `Rest`.
- A missing required param produces `"/<name>: missing argument <argname>."` automatically — don't re-check in `Accept`.

If the command needs a parameter shape none of these cover, add a new resolver to `Resolvers` in `ChatCommandTypes.lua` and the matching string to the `UIChatCommandParamType` alias. Prefer this over ad-hoc string parsing inside `Accept`.

## Accept vs. Execute

- **Parser** rejects *structural* errors (missing args, wrong types, unknown name) — you don't write code for these.
- **`Accept`** rejects *semantic* errors that depend on runtime state: target is yourself, observer trying a player-only action, target just disconnected. Return `(false, "/<name>: human reason.")`. The string surfaces as a local system feed line.
- **`Execute`** assumes inputs are valid and runs the side effect. Don't re-validate.

`Accept` may also normalize `args` in-place — e.g. `GiftResources.lua` rewrites `args.type` to `'mass'`/`'energy'` and back-fills `args.target` from the model when the user omitted it.

## Error-string convention

Every user-facing error from a command must start with `"/<name>: "` so failures are self-identifying in the chat feed. Lowercase the message, end with a period.

```lua
return false, "/whisper: can't whisper yourself."
```

## ShouldRegister gating

Use when the command should be invisible (and unparseable) outside specific sessions. The hook runs once at registration; the command is dropped from the registry **and from `/help`** if it returns false. Examples already in the tree:

- Observer-only: `return GetFocusArmy() == -1`
- Single-player-only: `return SessionIsGameOver() or SessionIsReplay() or ...` — see `EndMission.lua` for a real example.
- Replay-only: gate on `SessionIsReplay()`.

Don't use `ShouldRegister` for "is this a valid moment to run" — that's `Accept`'s job. `ShouldRegister` is for "does this command exist at all in this session."

## Wiring it up

After writing the file, add one line to [ChatController.lua](lua/ui/game/chat/ChatController.lua) inside `RegisterBuiltinCommands` (around line 102). The list is loosely grouped — keep yours next to thematically similar entries:

```lua
Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/<Name>.lua")
```

`RegisterFromPath` is defensive: a missing file, a bad import, a malformed `Command` export, or a throw inside `Register` are all logged and swallowed. So a broken new command can't take down the entire chat system — but verify your file actually got registered (see Verification below).

## Calling back into the controller

The execution context passed to `Accept` / `Execute`:

```lua
---@class UIChatCommandContext
---@field Model      UIChatModel
---@field Controller table   -- ChatController module
---@field SourceText string  -- raw "/whisper Jip hi" text
```

Common patterns:

| Goal | How |
|------|-----|
| Change recipient | `ctx.Controller.SetRecipient(args.target)` |
| Print a local system line (no network) | `ctx.Controller.AppendLocalSystemMessage("text")` |
| Send a chat message via the network | `ctx.Controller.Send("text")` |
| Read current chat state | `ctx.Model.Recipient()`, `ctx.Model.History()`, etc. (call the LazyVar — never store) |
| Sim callback | `SimCallback({ Func = "...", Args = { ... } })` directly |

Reading a LazyVar: always `ctx.Model.Recipient()` (call it). Never cache it in a local. See `CLAUDE.md` § Reactive State.

## Worked example: `/ping`

Adding a tiny `/ping` command that prints "pong" locally — useful as a smoke test.

**1.** Create `lua/ui/game/chat/commands/builtin/Ping.lua`:

```lua

-------------------------------------------------------------------------------
-- /ping — prints "pong" as a local system line. No network traffic. Useful
-- as a smoke test that the command pipeline is alive end-to-end.

---@type UIChatCommand
Command = {
    Name        = 'ping',
    Description = 'Prints "pong" locally — smoke test for the chat command pipeline.',
    Execute = function(_, ctx)
        ctx.Controller.AppendLocalSystemMessage("pong")
    end,
}
```

**2.** Register it in [ChatController.lua](lua/ui/game/chat/ChatController.lua):

```lua
Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/Ping.lua")
```

**3.** Verify (see below).

## Verification

After making the changes:

1. **Static check** — re-read both files. Confirm:
   - The file exports `Command = { ... }` at top level (not inside `return`).
   - Required keys present: `Name` (non-empty string), `Execute` (function). Everything else is optional.
   - Every error string returned from `Accept` starts with `"/<name>: "`.
   - The `RegisterFromPath` line is inside `RegisterBuiltinCommands`, not at module scope.
2. **Runtime check (ask the user to do this)**:
   - Launch a skirmish or replay, open chat, type `/help`. The new command should appear in the list with the right description and aliases.
   - Type the new command. Hit each error path (`Accept` rejections) to confirm the error strings render as local system lines.
   - Check the game log for `WARN Chat command skipped: …` lines — those mean `RegisterFromPath` rejected the file (path typo, malformed export, bad `Name`/`Execute`). Fix and reload.

If you can't run the game, say so explicitly rather than claiming the command works.

## Don'ts

- **Don't write to `ChatModel` from inside a command.** Go through `ctx.Controller`. Commands are MVC peers of views — read the model, mutate via the controller.
- **Don't call `Registry.Register` from the command file itself.** Central registration in `ChatController` is the only way; it makes hot-reload (the `Reload()` path) work and keeps the bootstrap order deterministic.
- **Don't add `<LOC ...>` localization tags to error strings yet.** This is listed as open work in `commands/design.md` § 10 — keep parity with the existing English-only commands so the eventual sweep is uniform.
- **Don't reach into `ChatCommandTypes.lua` to add a one-off resolver.** If a command needs special parsing of one argument, do it inside `Accept`. Only add a new resolver type when two or more commands would share it.
- **Don't import view files** (`Chat*Interface.lua`). Commands are headless — they should run in any context that has a model and controller.
