# Chat Commands — Design

**Purpose:** Handle `/slash` commands entered in the chat edit box. Parses the command, validates arguments, optionally checks legitimacy, executes side effects (usually on the controller), and surfaces failures as local-only system lines in the chat feed.

---

## 1. Architecture

```
ChatEditInterface.EditBox:OnEnterPressed(text)
    └── ChatController.Send(text)
        └── text starts with '/'?
            └── ChatCommandRegistry.Dispatch(text)
                ├── Tokenize(text)                  -- "/whisper Jip" → ("whisper", {"Jip"})
                ├── Lookup(name)                    -- name + aliases
                ├── ParseArgs(cmd, tokens)          -- typed, coerced, validated
                ├── cmd.Accept(args, ctx)           -- semantic legitimacy check
                └── cmd.Execute(args, ctx)          -- run side effect (usually ctx.Controller.*)
```

- **Registry** — flat `name → command` table plus `alias → name`. Exports `Register`, `Unregister`, `Lookup`, `GetAll`, `Dispatch`.
- **Types** — a table of `{recipient, player, int, string, rest}` resolvers. Each takes a raw token and returns `(ok, value_or_error)`.
- **Builtins** — `/all`, `/allies`, `/whisper`, `/help`. Loaded lazily on the first `Dispatch` call.

Commands do not touch the model directly. They call through `ctx.Controller`, preserving the MVC rule from `CLAUDE.md`.

---

## 2. Command Descriptor

```lua
---@class UIChatCommand
---@field Name        string                           # canonical name without leading slash
---@field Aliases?    string[]                         # alternative names (e.g. {'w','pm'} for whisper)
---@field Description string                           # one-line summary shown by /help
---@field Params?     UIChatCommandParam[]             # declarative parameter schema
---@field Accept?     fun(args, ctx): boolean, string? # runtime legitimacy check
---@field Execute     fun(args, ctx)                   # the actual side effect

---@class UIChatCommandParam
---@field Name     string
---@field Type     'Recipient' | 'Player' | 'Int' | 'String' | 'Rest'
---@field Optional boolean?
```

Rules:

- `Name` and every entry of `Aliases` are case-insensitive.
- `Params` order is the order tokens will be consumed.
- Only the last param may be `Rest`; it greedy-consumes every remaining token, joining them with single spaces.
- `Accept` and `Execute` both receive the already-typed `args` table and a shared `ctx`.

## 3. Parameter Types

Each resolver is `fun(token: string): ok, value | error`.

| Type | Accepts | Resolves to |
|------|---------|-------------|
| `Recipient` | `"all"`, `"allies"`, `"team"`, nickname, army ID | `UIChatRecipient` (`'all' \| 'allies' \| number`) |
| `Player` | nickname or army ID | `number` (army ID) — same rules as `Recipient` but rejects `all`/`allies` |
| `Int` | integer literal | `number` |
| `String` | a single whitespace-delimited token | `string` |
| `Rest` | one or more remaining tokens | `string` (tokens joined by single spaces) |

Army lookup goes through `GetArmiesTable()`, matching the source `ChatListInterface` already uses for the recipient picker. Civilian armies are excluded.

## 4. Execution Context

```lua
---@class UIChatCommandContext
---@field Model       UIChatModel
---@field Controller  table   -- ChatController module
---@field SourceText  string  -- the original "/whisper Jip" text
```

Passing `ctx` rather than each command importing the controller/model keeps commands decoupled from the chat tree and trivially testable.

## 5. Error Surfaces

`Dispatch` returns `(handled, errorText)`:

| Return | Meaning | Caller action |
|--------|---------|---------------|
| `(true,  nil)`    | command ran | return |
| `(false, errText)` | parse/accept/unknown error | print `errText` as a local system line, return |
| `(false, nil)`     | lone `/` or empty body | treat as normal text |

Error strings are produced at a single site in the registry so they stay uniform:

| Cause | Example |
|-------|---------|
| Unknown name | `Invalid command: /xyz. Type /help for a list.` |
| Missing arg | `/whisper: missing argument <target>.` |
| Bad arg | `/whisper: no player named 'bob'.` |
| Rejected by `Accept` | whatever string `Accept` returned |

Printing goes through `ChatController.AppendLocalSystemMessage(text)`, which appends a synthetic `UIChatEntry` to `model.History`. No network traffic; the line renders through the existing `ChatListInterface` path with no view changes.

## 6. Adding a Command

```lua
local Registry = import("/lua/ui/game/chat/commands/ChatCommandRegistry.lua")
local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")

Registry.Register {
    Name = 'whisper',
    Aliases = { 'w', 'pm' },
    Description = 'Whisper to a specific player.',
    Params = {
        { Name = 'target', Type = 'Player' },
    },
    Accept = function(args)
        local armies = GetArmiesTable()
        if armies and args.target == armies.focusArmy then
            return false, "/whisper: can't whisper yourself."
        end
        return true
    end,
    Execute = function(args, ctx)
        ctx.Controller.SetRecipient(args.target)
    end,
}
```

`/whisper Jip` and `/whisper 3` both route here with `args.target` already normalized to an army ID — one command definition, two user-facing forms.

## 7. `Accept` vs. `Execute`

- **Parser** handles *structural* errors: missing args, wrong types, unknown name.
- **`Accept`** handles *semantic* errors that depend on runtime state: whispering yourself, command disabled in replay, target just disconnected.
- **`Execute`** runs the side effect and trusts its inputs.

Splitting `Accept` out keeps the failure path uniform (always surfaces as a system feed line with the reason) and leaves room for things like tab-completion previews that call `Accept` without `Execute`.

## 8. Bootstrap

`BuiltinCommands.lua` has no side effects on import — it just exports each command as a named `UIChatCommand` table (`All`, `Allies`, `Whisper`, `Help`). Importing the module does not register anything.

`ChatController.RegisterBuiltinCommands()` is the single registration site: it pulls the named exports from `BuiltinCommands` and hands them to `ChatCommandRegistry.Register`. It is idempotent, so it can be called from multiple init paths without harm. `ChatController.Send` invokes it lazily on the first slash-prefixed message so the feature works without an explicit init hook; once a proper `ChatController:Init` exists (see `CLAUDE.md §Init`), the call should move there.

External modules (notify, mods, future subsystems) register their own commands by calling `Registry.Register` directly, independent of the builtins.

## 9. Integration with `ChatController.Send`

```lua
function Send(text)
    if text and string.sub(text, 1, 1) == '/' then
        local Registry = import("/lua/ui/game/chat/commands/ChatCommandRegistry.lua")
        local handled, err = Registry.Dispatch(text)
        if handled then return end
        if err then
            AppendLocalSystemMessage(err)
            return
        end
        -- lone '/' falls through
    end
    -- ... taunt check, network send ...
end
```

The slash branch is the first step of the send pipeline, matching `CLAUDE.md §Sending`.

## 10. Open Questions

1. **Nicknames with spaces.** Current tokenizer splits on whitespace. If nicknames with spaces are real, we need either quoted strings (`/whisper "Jip E"`) or a smarter `player` resolver that greedy-matches across tokens. Left as future work.
2. **Localization.** Error strings and command descriptions should go through `<LOC …>` like other chat text; currently hardcoded English.
3. **Replay/observer gating.** Some commands are meaningless in replay. `accept` can enforce per-command; a shared `ctx.mode` flag (`'live' | 'replay' | 'observer'`) would avoid each command re-deriving it.
4. **Tab completion / history.** The registry exposes `GetAll()` so an edit-view enhancement can offer completion for command names and (via `Params[i].Type`) argument suggestions. Not wired up here.
