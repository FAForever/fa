---
name: add-chat-command
description: Add a new in-game chat slash command (e.g. `/foo <arg>`) to the FAF chat system. Use when the user asks to add, register, or scaffold a new chat slash-command, or extend the `/help` listing with a new entry. Creates the command file under `lua/ui/game/chat/commands/builtin/`, wires it into `ChatController.RegisterBuiltinCommands`, and follows the parser/Accept/Execute split.
---

# Adding a chat slash-command

Use this when the user wants a new `/something` command in the in-game chat edit box.

The job is two edits: **(1)** a new file under `lua/ui/game/chat/commands/builtin/`, **(2)** one `RegisterFromPath` line in [ChatController.lua](/lua/ui/game/chat/ChatController.lua) (`RegisterBuiltinCommands`, ~line 88). Then verify.

**Code lives in `examples/`, not in this doc:**
- [Command.template.lua](/.claude/skills/add-chat-command/examples/Command.template.lua) — full descriptor with every field.
- [Ping.lua](/.claude/skills/add-chat-command/examples/Ping.lua) — minimal command (the smallest thing that works).
- Real references in the tree: `Whisper.lua` (params + Accept), `GiftResources.lua` (arg normalization + SimCallback), `Recall.lua` (no-param), `EndMission.lua` (`ShouldRegister`).

## Clarify first (only what you can't infer)

1. **Name** — the slash word, lowercase, no spaces. Aliases optional.
2. **What it does** — one sentence → becomes `Description`, shown by `/help`.
3. **Params** — name, type (table below), optional?
4. **Side-effect target** — `ctx.Controller.X`, a `SimCallback`, or just a local system line?
5. **Gating** — observer/replay/single-player/host-only? → `ShouldRegister`.

A fully-specified ask ("add `/ping` that prints 'pong' locally") needs no Q&A — just build it.

## Do / Don't

### File & export

| | Rule |
|---|------|
| ✅ | Name the file PascalCase to match the command (`whisper` → `Whisper.lua`, `gift-resources` → `GiftResources.lua`); one command per file. |
| ✅ | Export a **bare top-level `Command` global** — the registry reads `module.Command` after `import`. |
| ✅ | Copy the `--#region Debugging` hot-reload block (`__moduleinfo.OnReload` / `OnDirty`) into the file. Every builtin has it; the `examples/` files include it. Easiest thing to forget — without it, saving won't reload the command in a running game. |
| 🚫 | Use `return { Command = ... }` — the export is a global, not a return value. |
| 🚫 | Call `Registry.Register` inside the file; registration is central (see below). |
| 🚫 | Do any work at import time, or `import(...)` inside `Execute` — importing must be side-effect-free; keep imports at the top. |
| 🚫 | Import view files (`Chat*Interface.lua`) — commands are headless; they run wherever a model + controller exist. |

### Registration

| | Rule |
|---|------|
| ✅ | Add exactly one line to `RegisterBuiltinCommands` in [ChatController.lua](/lua/ui/game/chat/ChatController.lua), next to thematically similar entries: `Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/<Name>.lua")`. |
| 🚫 | Edit [ChatCommandRegistry.lua](/lua/ui/game/chat/commands/ChatCommandRegistry.lua) (the dispatcher is generic) or [ChatModel.lua](/lua/ui/game/chat/ChatModel.lua) (commands never touch the model directly). |

> **Gotcha:** `RegisterFromPath` swallows errors (bad path, malformed export, missing `Name`/`Execute`) and only logs `WARN Chat command skipped: …`. A broken command won't crash chat — but it silently won't exist either. **Always verify it actually registered.**

### Params & parsing

| | Rule |
|---|------|
| ✅ | Order params in token-consumption order; reuse the existing types. |
| ✅ | Put `Rest` last, if used — it's the only param that may be `Rest`. |
| 🚫 | Re-check missing required args in `Accept` — the parser emits `"/<name>: missing argument <argname>."` automatically. |
| 🚫 | Add a one-off resolver to [ChatCommandTypes.lua](/lua/ui/game/chat/commands/ChatCommandTypes.lua) for a single command; do special parsing inside `Accept`. Only add a resolver type when two or more commands would share it. |

### Accept vs. Execute vs. ShouldRegister

| | Rule |
|---|------|
| ✅ | Use `Accept` for *semantic/runtime* checks (target is yourself, observer doing a player action, target disconnected). Return `(false, "/<name>: reason.")`; the string renders as a local system line. May also normalize `args` in place (see `GiftResources.lua`). |
| ✅ | Let `Execute` assume inputs are valid — it just runs the side effect. |
| ✅ | Use `ShouldRegister` for "does this command exist in this session at all" — runs once at registration, drops the command from the registry and `/help`. E.g. `EndMission.lua`: `return not SessionIsMultiplayer()`; observer-only: `return GetFocusArmy() == -1`. |
| 🚫 | Put structural checks (missing args, wrong types) in `Accept` — that's the parser's job. |
| 🚫 | Re-validate in `Execute`. |
| 🚫 | Use `ShouldRegister` for "is this a valid moment to run" — that's `Accept`'s job. |

### Talking to the controller (MVC)

| | Rule |
|---|------|
| ✅ | Route side effects through `ctx.Controller` to preserve MVC discipline (calls below). |
| ✅ | Call LazyVars at the moment of use: `ctx.Model.Recipient()`. |
| 🚫 | Write to `ChatModel` from a command — read the model, mutate via the controller. |
| 🚫 | Cache a LazyVar in a local (see `AGENTS.MD` § Reactive State). |

| Goal | Call |
|------|------|
| Change recipient | `ctx.Controller.SetRecipient(args.target)` |
| Print a local-only system line | `ctx.Controller.AppendLocalSystemMessage("text")` |
| Send a network chat message | `ctx.Controller.Send("text")` |
| Read chat state | `ctx.Model.Recipient()`, `ctx.Model.History()` … |
| Sim-side effect | `SimCallback({ Func = "...", Args = { ... } })` |

### Error strings & localization

| | Rule |
|---|------|
| ✅ | Start every user-facing error with `"/<name>: "`, lowercase, end with a period — e.g. `return false, "/whisper: can't whisper yourself."`. Failures stay self-identifying in the feed. |
| 🚫 | Add `<LOC ...>` tags to error strings yet — keep parity with the existing English-only commands so the eventual localization sweep is uniform. |

## Context shape

```lua
---@class UIChatCommandContext
---@field Model      UIChatModel
---@field Controller table   -- ChatController module
---@field SourceText string  -- raw "/whisper Jip hi" text
```

## Parameter types

Defined in [ChatCommandTypes.lua](/lua/ui/game/chat/commands/ChatCommandTypes.lua):

| Type | Accepts | Resolved value |
|------|---------|----------------|
| `Recipient` | `"all"`, `"allies"`/`"team"`, nickname, army ID | `'all' \| 'allies' \| number` |
| `Player` | nickname or army ID (leading `@` ok) | `number` (army ID) |
| `Int` | integer literal | `number` |
| `String` | one whitespace-delimited token | `string` |
| `Rest` | every remaining token, space-joined | `string` |

## Verification

**Static** (re-read both files):
- File exports `Command = { ... }` at top level (not in a `return`), with non-empty `Name` and a `Execute` function.
- The hot-reload `--#region Debugging` block is present.
- Every `Accept` error string starts with `"/<name>: "`.
- The `RegisterFromPath` line is inside `RegisterBuiltinCommands`, not at module scope.

**Runtime** (ask the user — you can't run the game):
- Launch a skirmish/replay, open chat, type `/help`: the command appears with the right description/aliases.
- Run it; hit each `Accept` rejection to confirm the error strings render as local system lines.
- Check the game log for `WARN Chat command skipped: …` — that means `RegisterFromPath` rejected the file. Fix and reload.

If you can't run the game, say so — don't claim the command works.
