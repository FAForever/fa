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
3. **Never assign `OnDirty` directly on a LazyVar you don't own.** Direct assignment overwrites whatever handler was there before — silently breaking unrelated code. *Always* derive a fresh LazyVar, hang your handler on **that**, and read the upstream LazyVar from its compute. The first read registers your observer in the upstream's `used_by` table, so future changes propagate to your handler without ever touching the upstream's `OnDirty` slot.

Use `Derive(source, onDirty)` from `/lua/lazyvar.lua` — it bundles the three-step dance (create, set OnDirty, `Set` a reader) into one call:

```lua
-- DON'T — clobbers any other subscriber:
model.History.OnDirty = function(lv) self:OnHistoryChanged(lv()) end

-- DO — derive a per-subscriber LazyVar:
self.HistoryObserver = Derive(model.History, function(lv)
    self:OnHistoryChanged(lv())
end)

-- And on teardown:
self.HistoryObserver:Destroy()
```

**`Create` vs `Derive`** — `Create(value)` makes a LazyVar holding a static initial value. If you pass a function or another LazyVar, it is stored *verbatim* as the cached value — not interpreted as a dependency. `Derive(source, onDirty)` makes a LazyVar that tracks `source` and fires `onDirty` whenever it changes. When you want to observe an existing LazyVar, you want `Derive`; `Create` won't wire up the dependency edge.

This rule applies to every LazyVar in the system — including ones in our own `Model` files. Treat `Foo.OnDirty` as private to whoever creates `Foo`.
4. **Never write to the model inside an `OnDirty`.** That is controller logic; keep views read-only.
5. **Destroy LazyVars when the owning control is destroyed** to avoid dangling `OnDirty` callbacks. The standard pattern is a `TrashBag` (see `/lua/system/trashbag.lua`): allocate `self.Trash = TrashBag()` in `__init`, hand every derived observer to it via `self.Trash:Add(...)`, and destroy the bag in `OnDestroy`:

    ```lua
    __init = function(self, ...)
        self.Trash = TrashBag()
        self.HistoryObserver = self.Trash:Add(Derive(model.History, function(lv)
            self:OnHistoryChanged(lv())
        end))
    end,
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
    ```

    `Trash:Add` returns what you pass it, so the assignment stays a one-liner.

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

Calls directly:
- `ChatController.Send(text, cameraState?)` — user pressed Enter
- `ChatController.SetRecipient(target)` — user picked from the dropdown or clicked a name in the feed

### ChatConfigView

Observes:
- `model.Pending.OnDirty` → sync control states

Calls directly:
- `ChatConfigController.SetOption(key, value)` — user changed a control
- `ChatConfigController.Apply / Reset / Cancel` — user clicked the corresponding button

### Imports vs callbacks

Views import the model and controller modules directly at the top of the file rather than receiving callback tables in their constructor:

```lua
local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")
local ChatConfigController = import("/lua/ui/game/chat/config/ChatConfigController.lua")
```

This keeps dependencies visible at the top of the file and avoids the boilerplate of threading callback tables through constructors. The MVC discipline is preserved by convention: views still only **read** from the model and **call** the controller — they never write to the model directly.

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
| `send_type` | false | Default recipient: false = all, true = allies |
| `links` | true | Show camera-link messages |
| `[armyID]` | true | Per-army message filter |

---

## Class Field Annotations

Every field assigned to `self` inside `__init` must have a matching `---@field` annotation on the class definition. This gives the language server full type information across the whole file and makes the class self-documenting at a glance.

### Rule

Annotate the class immediately above the `ClassUI(...)` call. List every `self.X` field in the order it appears in `__init`. For fields whose type is an array of a named struct, define that struct as its own `---@class` above the main class.

### Example

```lua
---@class UIChatConfigColorRow
---@field label Text
---@field combo BitmapCombo
---@field key   string

---@class UIChatConfigInterface : Window
---@field LabelColors    Text
---@field ColorRows      UIChatConfigColorRow[]
---@field LabelFontSize  Text
---@field SliderFontSize IntegerSlider
---@field LabelBehavior  Text
---@field Checkboxes     Checkbox[]
---@field BtnApply       Button
---@field BtnOk          Button
local ChatConfigInterface = ClassUI(Window) {
    __init = function(self, parent, ...)
        self.LabelColors    = UIUtil.CreateText(...)
        self.ColorRows      = {}
        self.LabelFontSize  = UIUtil.CreateText(...)
        self.SliderFontSize = IntegerSlider(...)
        self.LabelBehavior  = UIUtil.CreateText(...)
        self.Checkboxes     = {}
        self.BtnApply       = UIUtil.CreateButtonStd(...)
        self.BtnOk          = UIUtil.CreateButtonStd(...)
    end,
}
```

### What counts as a field

- Every `self.Foo` written in `__init` or `__post_init`.
- Fields inherited from the parent class (e.g. `Window`) do **not** need repeating — the `: Window` in the class declaration inherits them.
- Temporary locals inside a method are not fields and need no annotation.

---

## What Not To Do

- **Do not store UI references in the model.** The model must be constructable with no UI present.
- **Do not write to the model from a view.** Views call into the controller; the controller writes.
- **Do not mutate a LazyVar's held table in place.** Create a new table and `Set` it; otherwise dependents never go dirty.
- **Do not replicate the autolobby's drilling pattern.** State is on the model; views subscribe — no parent needs to push updates into children.
