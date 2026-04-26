# Chat — Refactoring Guide

This directory contains the refactored in-game chat. The goal is to replace the monolithic legacy `/lua/ui/game/chat.lua` with a clean MVC structure where the **model** is reactive (LazyVar-based), the **view** is dumb (reads from the model, never writes), and the **controller** is the only place that sends or receives messages.

> **Read first:** [`/lua/ui/CLAUDE.md`](/lua/ui/CLAUDE.md) covers project-wide UI patterns — `__init` vs `__post_init`, LazyVars and `Derive`, `TrashBag`, layout, skinning, debug overlays, hot-reload. This doc is chat-specific and assumes those rules. Class field annotation conventions live in [`annotation.md`](annotation.md).

---

## Architecture

```
Controller  ──writes──►  Model (LazyVars)  ──OnDirty──►  View
    ▲                                                       │
    └──────────────────── user input ──────────────────────┘
```

- **Model** — flat sets of `LazyVar` instances in `ChatModel.lua` (chat state) and `config/ChatConfigModel.lua` (options). No UI, no networking. The single source of truth.
- **View** — a tree of `*Interface` Groups and Windows that subscribe to model LazyVars via `Derive`. Views never touch each other or write to the model.
- **Controller** — `ChatController.lua` (chat) and `config/ChatConfigController.lua` (options). The only files allowed to send network messages, register receive handlers, or write to the model.

---

## File Map

The chat tree splits one feature into many small files so each `*Interface` is responsible for a single concern. When adding a feature, this table tells you which file to open.

### Top-level

| File | Responsibility |
|------|----------------|
| [ChatModel.lua](ChatModel.lua) | `UIChatModel` singleton + `UIChatEntry` / `UIChatEntryLocation` shapes; recipient + history + window-visible + last-activity + pin LazyVars |
| [ChatController.lua](ChatController.lua) | Send / receive pipelines, slash-command dispatch, activity heartbeat, recipient routing — the only file allowed to call `SessionSendChatMessage` or write to the model |
| [ChatInterface.lua](ChatInterface.lua) | `UIChatInterface : Window` — main draggable, resizable chat window; owns drag handles, idle/fade `OnFrame` timer, `win_alpha` cascade, standalone-invocation entry points |
| [ChatLinesInterface.lua](ChatLinesInterface.lua) | `UIChatLinesInterface : Group` — line pool, scrollbar, wrap/rebuild on resize, observes `model.History` + `ChatConfigModel.Committed` |
| [ChatLineInterface.lua](ChatLineInterface.lua) | `UIChatLineInterface : Group` — single message row: faction badge, sender name (clickable), body text (clickable when camera/location-tagged) |
| [ChatEditInterface.lua](ChatEditInterface.lua) | `UIChatEditInterface : Group` — edit box, recipient label, recipient-picker dropdown, camera-attach checkbox, command-hint popup, command history ring, Tab completion |
| [ChatFeedInterface.lua](ChatFeedInterface.lua) | `UIChatFeedInterface : Group` — sibling feed shown while the window is closed; per-row age timer fades old lines |
| [ChatListInterface.lua](ChatListInterface.lua) | `UIChatListInterface : Group` — popup recipient picker (all / allies / per-player) |
| [ChatCommandHintInterface.lua](ChatCommandHintInterface.lua) | `UIChatCommandHintInterface : Group` — slash-command auto-suggest popup anchored to the edit box |
| [ChatFactionBadge.lua](ChatFactionBadge.lua) | `ChatFactionBadge : Group` — faction icon with tooltip; rendered on every line |
| [ChatCompletion.lua](ChatCompletion.lua) | Tab-completion cycle state (no UI; consumed by `ChatEditInterface`) |
| [ChatUtils.lua](ChatUtils.lua) | Module-level helpers (max message length, etc.) |
| [ChatDebug.lua](ChatDebug.lua) | Debug helpers — not part of the production tree |

### `config/`

| File | Responsibility |
|------|----------------|
| [config/ChatConfigModel.lua](config/ChatConfigModel.lua) | `UIChatConfigModel` singleton + `UIChatOptions` schema + slider ranges; `Committed` (active) and `Pending` (draft) options LazyVars |
| [config/ChatConfigController.lua](config/ChatConfigController.lua) | Apply / Reset / Cancel / SetOption — the only writer to `ChatConfigModel` |
| [config/ChatConfigInterface.lua](config/ChatConfigInterface.lua) | `UIChatConfigInterface : Window` — options dialog; observes `Pending` to sync controls |

### `commands/`

| File | Responsibility |
|------|----------------|
| [commands/ChatCommandRegistry.lua](commands/ChatCommandRegistry.lua) | Registry, tokenizer, dispatcher; legacy fallback to `/lua/ui/notify/commands.lua` |
| [commands/ChatCommandTypes.lua](commands/ChatCommandTypes.lua) | Parameter resolvers: `Recipient`, `Player`, `Int`, `String`, `Rest` |
| [commands/builtin/*.lua](commands/builtin/) | One file per built-in command (`/all`, `/allies`, `/whisper`, `/help`, …); each exports a `Command` table |
| [commands/design.md](commands/design.md) | Slash-command system design — read before adding a command |

To add a slash command, follow the [`add-chat-command`](../../../../.claude/skills/add-chat-command/SKILL.md) skill.

---

## Model

### `UIChatModel` ([ChatModel.lua](ChatModel.lua))

```lua
---@class UIChatModel
---@field History       LazyVar<UIChatEntry[]>     # append-only log; Set a new table ref to trigger dirty
---@field Recipient     LazyVar<UIChatRecipient>   # current send target
---@field WindowVisible LazyVar<boolean>           # whether the chat window is open
---@field LastActivity  LazyVar<number>            # GetSystemTimeSeconds() of the most recent engagement; drives the fade timer
---@field Pinned        LazyVar<boolean>           # title-bar pin checkbox; suspends auto-close while true
```

`UIChatRecipient` is `'all' | 'allies' | number` — the engine-level target. The two string constants are exported as `ChatModel.RecipientAll` / `ChatModel.RecipientAllies` so nothing hardcodes the strings.

### `UIChatEntry`

```lua
---@class UIChatEntry
---@field Name        string             # formatted prefix, e.g. "Sender to allies:"
---@field Text        string             # raw message body
---@field Color       string             # ARGB hex of the sender's team colour
---@field BodyColor?  string             # explicit body ARGB; bypasses palette lookup (system / synthetic lines)
---@field ColorKey?   string             # palette key resolved against `ChatConfigModel.GetOptions()` at render time
---@field ArmyID      number             # sender's army index
---@field Faction     number             # 1-based faction icon index
---@field Recipient   UIChatRecipient    # original target of the message
---@field Camera?     table              # SaveSettings snapshot when the sender attached their view
---@field Location?   UIChatEntryLocation # lightweight {Position?, Area?} hint from sim-side senders
---@field Id?         string             # near-unique sender-stamped id; dedupes the Sync.ChatMessages path against SessionSendChatMessage
---@field WrappedText? string[]          # view-side wrap cache; populated by ChatLinesInterface
```

Display-lifecycle state (per-row `time` / `visible` flags, fade alpha) lives on the **view**, not on entries. `WrappedText` is the one exception — the wrap cache attaches to the entry because it depends on the entry's text and the current row width, and avoids re-wrapping every frame.

### `UIChatConfigModel` ([config/ChatConfigModel.lua](config/ChatConfigModel.lua))

```lua
---@class UIChatConfigModel
---@field Committed LazyVar<UIChatOptions>   # the active, persisted options observed by the chat tree
---@field Pending   LazyVar<UIChatOptions>   # the draft being edited in the config dialog
```

The two LazyVars exist so the config dialog can preview changes (`Pending`) without affecting live UI (`Committed`) until the user clicks Apply. Views observing chat options always read `Committed`.

`UIChatOptions` is a plain table; option keys are exported as module globals (`ChatConfigModel.KeyFontSize`, etc.) so call sites don't repeat magic strings. Slider bounds (`FontSizeRange`, `FadeTimeRange`, `WinAlphaSliderRange`) live in the same module.

| Key | Default | Meaning |
|-----|---------|---------|
| `all_color` | 1 | Palette index (1–8) for "all" messages |
| `allies_color` | 2 | Palette index for ally messages |
| `priv_color` | 3 | Palette index for private messages |
| `link_color` | 4 | Palette index for camera/location-link messages and observer chatter |
| `notify_color` | 8 | Palette index for Notify subsystem messages |
| `font_size` | 14 | Chat font size (12–18) |
| `fade_time` | 15 | Seconds before idle window/feed auto-hides (5–30) |
| `win_alpha` | 1.0 | Window opacity (0.0–1.0; edited via 20–100% slider) |
| `feed_background` | false | Semi-transparent backdrop behind feed lines |
| `send_type` | false | Default recipient: false = all, true = allies |
| `links` | true | Show camera-link messages |
| `muted` | `{}` | Per-army mute filter (`armyID → true` when muted) |

---

## Controller

### Receiving

```
gamemain.ReceiveChat(sender, data)              [engine callback]
    └── chatFuncs['Chat'](sender, data)         [registered by ChatController.Init]
        └── ChatController.OnReceive(sender, msg)
            ├── shape-validate the payload (drop malformed, modded, or hostile)
            ├── route Notify subsystem messages through their handlers
            └── ChatModel.AppendEntry(entry)     # writes model.History + stamps LastActivity
```

`OnSyncChatMessages` is the parallel path for sim-originated and replay messages — it goes through the same `OnReceive` once it has unpacked the sync payload, so live and replay paths converge.

### Sending

```
ChatController.Send(text, attachCamera?)
    ├── slash-command check  →  ChatCommandRegistry.Dispatch
    ├── taunt check          →  /lua/ui/notify/taunt
    ├── package message      {to, Chat, text, Camera?, Id, Sender}
    ├── resolve clients      →  FindClients[AsObserver|AsPlayer]
    └── SessionSendChatMessage(clients?, msg)
         + SimCallback('SendChatMessage') for the sim/replay path
         + locally echo private messages (engine doesn't bounce them back)
```

Every public function on `ChatController` either reads input, writes the model, or speaks to the engine — there is no UI-side state on the controller. Anything in `/lua/ui/game/chat` that wants to mutate chat state goes through one of these:

| Function | What it does |
|----------|--------------|
| `OpenWindow` / `CloseWindow` / `ToggleWindow` | Flip `model.WindowVisible` |
| `NotifyActivity` | Stamp `model.LastActivity` — the activity heartbeat read by the fade timer |
| `SetPinned(bool)` | Flip `model.Pinned` (and re-stamp activity on unpin) |
| `SetRecipient(target)` | Write `model.Recipient` |
| `AppendEntry(entry)` | Append to `model.History` + stamp activity |
| `AppendLocalSystemMessage(text)` | Synthesize a local-only system line (used by command errors) |
| `Send(text, attachCamera?)` | Slash dispatch / taunt / network send pipeline |
| `ActivateChat(modifiers?)` | Engine hotkey entry: open window with default recipient layered with Shift |
| `RegisterBuiltinCommands` | Re-runs the registry population; idempotent and safe under hot reload |
| `Init` | Registers `OnReceive` with gamemain, populates the registry, ensures the chat tree is mounted |

### Init

`ChatController.Init` is called once from `gamemain.lua` during UI setup. Hot reload re-runs `Init` via the `__moduleinfo.OnReload` hook so the gamemain registration rebinds to the freshly imported `OnReceive` closure — without that, edits to the controller leave stale code receiving messages.

---

## Views

Every `*Interface` file follows the rules in [`/lua/ui/CLAUDE.md`](../../CLAUDE.md) — `__init` for state and children, `__post_init` for layout, observers via `Derive`, cleanup via `TrashBag`. The chat-specific bits are which model fields each interface observes and which controller calls it makes.

| Interface | Observes | Calls into controller |
|-----------|----------|-----------------------|
| `UIChatInterface` ([ChatInterface.lua](ChatInterface.lua)) | `model.WindowVisible`, `model.Pinned`, `ChatConfigModel.Committed.win_alpha` | `CloseWindow`, `SetPinned`, `NotifyActivity` |
| `UIChatLinesInterface` ([ChatLinesInterface.lua](ChatLinesInterface.lua)) | `model.History`, `ChatConfigModel.Committed` (font, palette, mute, links) | (read-only; click forwarders handed in by parent) |
| `UIChatLineInterface` ([ChatLineInterface.lua](ChatLineInterface.lua)) | (per-row; populated by `ChatLinesInterface`) | row click → `SetRecipient`, camera click → `WorldCamera:RestoreSettings` |
| `UIChatEditInterface` ([ChatEditInterface.lua](ChatEditInterface.lua)) | `model.Recipient` | `Send`, `SetRecipient`, `NotifyActivity`, `CloseWindow` |
| `UIChatFeedInterface` ([ChatFeedInterface.lua](ChatFeedInterface.lua)) | `model.History`, `ChatConfigModel.Committed` (palette, fade, feed_background) | (read-only) |
| `UIChatListInterface` ([ChatListInterface.lua](ChatListInterface.lua)) | (driven by edit dropdown) | `SetRecipient` |
| `UIChatCommandHintInterface` ([ChatCommandHintInterface.lua](ChatCommandHintInterface.lua)) | (driven by edit text) | (no controller calls; hint UI only) |
| `UIChatConfigInterface` ([config/ChatConfigInterface.lua](config/ChatConfigInterface.lua)) | `ChatConfigModel.Pending` | `ChatConfigController.SetOption` / `Apply` / `Reset` / `Cancel` |

### Imports vs callbacks

Views import models and controllers directly at the top of the file rather than receiving them through constructors:

```lua
local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatController = import("/lua/ui/game/chat/ChatController.lua")
local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")
```

This keeps dependencies visible at the top of the file and avoids the autolobby's "prop drilling" pattern, where state was threaded through every constructor and every change required touching the controller. The MVC discipline is preserved by convention: views still only **read** from the model and **call** the controller — they never write to the model directly.

---

## UI Elements

| Element | File | Parent |
|---------|------|--------|
| Chat window (title bar + drag handles) | [ChatInterface.lua](ChatInterface.lua) | `GetFrame(0)` |
| Line pool + scrollbar | [ChatLinesInterface.lua](ChatLinesInterface.lua) | chat window's client area |
| Single message row | [ChatLineInterface.lua](ChatLineInterface.lua) | line pool |
| Sibling feed (window-hidden mode) | [ChatFeedInterface.lua](ChatFeedInterface.lua) | `GetFrame(0)` (anchored to chat window's lines rect) |
| Edit box, recipient label, recipient picker, camera checkbox | [ChatEditInterface.lua](ChatEditInterface.lua) | chat window's client area |
| Recipient-picker popup | [ChatListInterface.lua](ChatListInterface.lua) | edit interface |
| Slash-command hint popup | [ChatCommandHintInterface.lua](ChatCommandHintInterface.lua) | edit interface |
| Faction icon (per row) | [ChatFactionBadge.lua](ChatFactionBadge.lua) | line interface |
| Options dialog | [config/ChatConfigInterface.lua](config/ChatConfigInterface.lua) | `GetFrame(0)` |

---

## Standalone Invocation

Every complete UI component in this system (chat window, options dialog, edit area) **must be callable directly from a hotkey** with no prior context. This serves two purposes:

1. **Debugging** — any component can be opened in isolation without launching the full game flow.
2. **Separation of concerns** — if a component requires another component to exist before it can be opened, that is a design smell indicating hidden coupling.

Each top-level view module exports module-level `Toggle()` / `Open()` / `Close()` and an `Instance` local. Bind `chat_toggle` and `chat_config` actions in `keyactions.lua` to `UI_Lua import("/lua/ui/game/chat/ChatInterface.lua").Toggle()` and the corresponding config call. The same `Toggle()` is also what the hot-reload `__moduleinfo.OnReload` block reopens after a save — see [`/lua/ui/CLAUDE.md § 7.2`](../../CLAUDE.md).

> This convention is currently chat-specific but is a candidate to lift into [`/lua/ui/CLAUDE.md`](../../CLAUDE.md). Until it does, treat this as the reference for any other top-level UI module.

---

## Don'ts

- **Don't store UI references in the model.** The model must be constructable with no UI present (and is — see the model singleton's hot-reload hook, which rebuilds without touching the view tree).
- **Don't write to the model from a view.** Views call into the controller; the controller writes.
- **Don't call `SessionSendChatMessage` or `gamemain.RegisterChatFunc` from anywhere but `ChatController`.** Network and sim-side traffic is funnelled through that file precisely so legacy/notify/script paths don't fork.
- **Don't mutate `model.History` (or any LazyVar's table) in place.** Build a new table and `Set` it; otherwise dependents never go dirty. See [`/lua/ui/CLAUDE.md § 2 Reactivity rules`](../../CLAUDE.md).
- **Don't replicate the autolobby's drilling pattern.** State is on the model; views import and subscribe — no parent needs to push updates into children.
- **Don't add a slash command by editing the registry directly.** Drop a file in [`commands/builtin/`](commands/builtin/) and add one `Registry.RegisterFromPath` line in `ChatController.RegisterBuiltinCommands` — see the [`add-chat-command`](../../../../.claude/skills/add-chat-command/SKILL.md) skill.
