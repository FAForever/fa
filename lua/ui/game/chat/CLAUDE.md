# Chat — Refactoring Guide

This directory contains the refactored in-game chat system. The goal is to replace the monolithic `chat.lua` with a clean MVC structure where the **model** is reactive (LazyVar-based), the **view** is dumb (reads from the model, never writes), and the **controller** is the only place that sends or receives messages.

---

## Architecture

```
Controller  ──writes──►  Model (LazyVars)  ──OnDirty──►  View
    ▲                                                       │
    └──────────────────── user input ──────────────────────┘
```

- **Model** — a flat set of `LazyVar` instances. No UI, no networking. The single source of truth.
- **View** — UI controls that subscribe to model LazyVars via `OnDirty`. They never touch each other or call back into the controller.
- **Controller** — receives network messages and user input, validates them, and writes to the model.

---

## Reactive State — How LazyVar Works

`LazyVar` (`/lua/lazyvar.lua`) is the reactive primitive in this codebase.

```lua
local Create = import("/lua/lazyvar.lua").Create

-- A LazyVar holding a plain value
local recipient = Create('all')   -- initial value

-- Read the value by calling it
print(recipient())                -- 'all'

-- Write a new value
recipient:Set('allies')           -- triggers OnDirty on recipient and dependents

-- React to changes
recipient.OnDirty = function(self)
    toText:SetText(self())        -- view pulls the new value
end

-- A LazyVar that derives from another LazyVar (computed)
local label = Create()
label:Set(function()
    return 'Sending to: ' .. recipient()   -- re-evaluates whenever recipient changes
end)
label.OnDirty = function(self)
    someText:SetText(self())
end
```

### Rules

1. **Never cache a LazyVar's value in a local.** Always call it (`lv()`) at the moment you need it so the dependency graph stays correct.
2. **`OnDirty` is a pull notification, not a push.** It tells you the value *may* have changed; you call `self()` inside `OnDirty` to get the new value.
3. **One `OnDirty` per LazyVar instance.** Assigning `OnDirty` again overwrites the previous one. If you need multiple observers, derive a second LazyVar that reads the first.
4. **Never write to the model inside an `OnDirty`.** That is controller logic; keep views read-only.
5. **Destroy LazyVars when the owning control is destroyed** to avoid dangling `OnDirty` callbacks.

### What the autolobby got wrong

The autolobby passed `State` tables down through constructors and method calls (prop drilling). When state changed, the controller had to know which child controls needed updating and call them explicitly. This is brittle — adding a new view element means touching the controller. With LazyVars, the view self-subscribes; the controller stays ignorant of the view entirely.

---

## Model

Defined in `ChatModel.lua`. All fields are LazyVars. No UI imports allowed in this file.

```lua
---@class UIChatModel
---@field recipient      LazyVar<'all'|'allies'|number>   # current send target
---@field history        LazyVar<UIChatEntry[]>           # append-only; Set a new table ref to trigger dirty
---@field options        LazyVar<UIChatOptions>           # persisted chat preferences
---@field windowVisible  LazyVar<boolean>                 # whether the chat window is open
```

`UIChatEntry` (plain table, not a LazyVar itself):

```lua
---@class UIChatEntry
---@field name         string      # formatted "Sender to allies:"
---@field text         string      # raw message body
---@field tokey        string      # ChatOptions key for color lookup
---@field color        string      # ARGB hex team color
---@field armyID       number      # for per-army filter
---@field faction      number      # faction icon index
---@field camera?      table       # WorldCamera settings if this is a ping link
```

Display-lifecycle state (`time`, `new`) belongs to the **view**, not to entries.

---

## Controller

Defined in `ChatController.lua`. The only file allowed to call `SessionSendChatMessage`, write to the model, or register with `gamemain.RegisterChatFunc`.

### Receiving

```
gamemain.ReceiveChat(sender, data)          [engine callback]
    └── chatFuncs['Chat'](sender, data)     [registered by controller on init]
        └── ChatController:OnReceive(sender, msg)
            ├── validate (drop non-Chat, unknown senders)
            ├── handle notify subsystem
            └── model.history:Set(appendedTable)
```

### Sending

```
ChatController:Send(text)
    ├── slash-command check  →  commands.RunChatCommand
    ├── taunt check          →  taunt.CheckForAndHandleTaunt
    ├── build msg table      {to, Chat, text, camera?}
    ├── resolve client list  →  FindClients / FindClients(id)
    └── SessionSendChatMessage(clients?, msg)
         + echo locally for private messages
```

### Init

```lua
function ChatController:Init(mapGroup)
    -- build the model
    -- build the view, passing the model
    -- register with gamemain
    import("/lua/ui/game/gamemain.lua").RegisterChatFunc(
        function(sender, data) self:OnReceive(sender, data) end,
        'Chat'
    )
end
```

---

## Standalone Invocation

Every complete UI component in this system (chat window, config dialog, edit view) **must be callable directly from a hotkey** with no prior context. This serves two purposes:

1. **Debugging** — any component can be opened in isolation without launching the full game flow.
2. **Separation of concerns** — if a component requires another component to exist before it can be opened, that is a design smell indicating hidden coupling.

### How hotkeys work in this codebase

`keyactions.lua` defines an action table. Each entry's `action` string is evaluated by the engine:

```lua
-- keyactions.lua
local keyActionsChat = {
    ['chat_toggle'] = {
        action = 'UI_Lua import("/lua/ui/game/chat/ChatView.lua").Toggle()',
        category = 'chat',
    },
    ['chat_config'] = {
        action = 'UI_Lua import("/lua/ui/game/chat/ChatConfigView.lua").Toggle()',
        category = 'chat',
    },
}
```

`keydescriptions.lua` provides the display name shown in the key-binding settings UI:

```lua
['chat_toggle'] = '<LOC key_desc_chat_0001>Toggle chat window',
['chat_config'] = '<LOC key_desc_chat_0002>Toggle chat options',
```

### Convention for every view module

Each view file must export a `Toggle()` function (and optionally `Open()` / `Close()`) at module level. The function must be safe to call at any time:

```lua
-- ChatConfigView.lua

local instance = nil

function Toggle()
    if instance then
        instance:Destroy()
        instance = nil
    else
        Open()
    end
end

function Open()
    if instance then return end
    -- obtain or create the model singleton, then build the view
    local model = import("/lua/ui/game/chat/ChatModel.lua").GetSingleton()
    instance = CreateConfigWindow(GetFrame(0), model)
end

function Close()
    if instance then
        instance:Destroy()
        instance = nil
    end
end
```

`GetFrame(0)` is always available in a UI context, so no parent reference needs to be threaded in. A component that cannot be opened this way is not truly standalone.

### No default key bindings required

You do not need to assign a default key to every component — the binding table entry is enough to make it available in the key-binding UI and invocable from the console during development:

```
UI_Lua import("/lua/ui/game/chat/ChatConfigView.lua").Toggle()
```

---

## View

Defined in `ChatView.lua` (window + feed) and `ChatEditView.lua` (input area). Views receive the model at construction and subscribe via `OnDirty`. They never import the controller.

### ChatView

Observes:
- `model.history.OnDirty` → re-render visible lines
- `model.windowVisible.OnDirty` → show/hide `GUI.bg`
- `model.options.OnDirty` → apply font size, colors, alpha, rewrap text

Owns internally:
- `chatHistory` display-side shadow: a parallel array of `{time, visible}` per entry — **not** stored on the entries themselves
- The line pool (`GUI.chatLines[]`) and scroll container
- The fade timer (`OnFrame` on `GUI.bg`)

### ChatEditView

Observes:
- `model.recipient.OnDirty` → update the "To Allies:" label

Emits (to controller, via a callback registered at construction):
- `onSend(text, cameraState?)` — user pressed Enter
- `onRecipientChange(target)` — user picked from the dropdown or clicked a name in the feed

### ChatConfigView

Observes:
- `model.options.OnDirty` → sync control states

Writes (to model via controller callback):
- `onOptionsApply(newOptions)`

---

## UI Elements

| Element | File | Parent |
|---------|------|--------|
| Chat window (`GUI.bg`) | `ChatView.lua` | `GetFrame(0)` |
| Scroll container + line pool | `ChatView.lua` | `GUI.bg` client area |
| Feed lines (hidden-window mode) | `ChatView.lua` | same line pool |
| Input edit box | `ChatEditView.lua` | `GUI.bg` client area |
| Recipient label ("To Allies:") | `ChatEditView.lua` | edit group |
| Chat-bubble dropdown | `ChatEditView.lua` | edit group |
| Camera-attach checkbox | `ChatEditView.lua` | edit group |
| Options config window | `ChatConfigView.lua` | `GetFrame(0)` |

Each chat line (`GUI.chatLines[i]`) contains:
- `teamColor` — solid-colour bitmap (team colour)
- `factionIcon` — faction logo
- `name` — clickable text; click → `onRecipientChange(armyID)`
- `text` — message body; click (if `entry.camera`) → `WorldCamera:RestoreSettings`
- `lineStickybg` — feed-mode readability background

---

## Options

`UIChatOptions` is a plain table loaded from and saved to the player profile. The model holds one LazyVar for the whole options table. A new table reference must be `Set` to trigger dirty (do not mutate in place).

| Key | Default | Meaning |
|-----|---------|---------|
| `all_color` | 1 | Color index (1–8) for "all" messages |
| `allies_color` | 2 | Color index for ally messages |
| `priv_color` | 3 | Color index for private messages |
| `link_color` | 4 | Color index for camera-link messages |
| `notify_color` | 8 | Color index for Notify messages |
| `font_size` | 14 | Chat font size (12–18) |
| `fade_time` | 15 | Seconds before feed/window auto-hides |
| `win_alpha` | 1.0 | Window opacity (stored 0–100, normalized on use) |
| `feed_background` | false | Semi-transparent bg behind feed lines |
| `feed_persist` | true | Keep feed lines until individually timed out |
| `send_type` | false | Default recipient: false = all, true = allies |
| `links` | true | Show camera-link messages |
| `[armyID]` | true | Per-army message filter |

---

## What Not To Do

- **Do not store UI references in the model.** The model must be constructable with no UI present.
- **Do not write to the model from a view.** User actions fire a controller callback; the controller writes.
- **Do not pass the controller into views.** Pass narrow callbacks (`onSend`, `onRecipientChange`) instead.
- **Do not mutate a LazyVar's held table in place.** Create a new table and `Set` it; otherwise dependents never go dirty.
- **Do not replicate the autolobby's drilling pattern.** State is on the model; views subscribe — no parent needs to push updates into children.
