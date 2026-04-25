# Chat System — Design Document

**Purpose:** Captures the existing functionality of the in-game chat system as a basis for a refactoring effort.

---

## 1. Entry Points and Lifecycle

### 1.1 Initialization

`gamemain.lua` drives the full lifecycle:

1. **`SetLayout()`** — called from `gamemain.lua:SetLayout()`. Delegates to the skin-specific layout file (`layouts/chat_layout.lua`) which positions the chat `Window` and its sub-controls relative to the screen frame.
2. **`SetupChatLayout(mapGroup)`** — called from `gamemain.lua` at game-start. Calls `CreateChat()` and then registers `ReceiveChat` as the handler for the `'Chat'` identifier via `gamemain.RegisterChatFunc`.

### 1.2 `CreateChat()`

Builds the full chat UI tree:
- `CreateChatBackground()` → a draggable, resizable `Window` (`GUI.bg`)
- `CreateChatEdit()` → the text-input group (`GUI.chatEdit`)
- `CreateChatLines()` → the array of display lines (`GUI.chatLines[]`)
- Wires up all `OnResize`, `OnMove`, `OnFrame`, `OnClose`, `OnPinCheck`, and `OnConfigClick` callbacks
- Calls `ToggleChat()` at the end (so the window starts hidden)

---

## 2. Message Transport

### 2.1 Sending — `SessionSendChatMessage`

The engine function `SessionSendChatMessage(clients?, msg)` delivers a Lua table as a chat message to one or more peers. The `clients` argument is either omitted (broadcast to all) or a list of client indices returned by `FindClients`.

All callers encode meaning in specific fields of `msg`. The following fields are observed across the codebase:

| Field | Type | Meaning |
|-------|------|---------|
| `to` | `'all'` \| `'allies'` \| `'notify'` \| number | Recipient scope |
| `Chat` | bool | Must be `true` for the standard chat display path |
| `text` | string | Message body |
| `from` | string | Override sender name (used for private-message echo) |
| `echo` | bool | Marks a message that was sent to a specific player (shown to the sender) |
| `Observer` | bool | Marks an observer-originated message |
| `camera` | table | Camera state (from `WorldCamera:SaveSettings()`) attached to a "ping" link |
| `ConsoleOutput` | string | Alternative payload — printed to console, not displayed in chat feed |
| `Taunt` | bool | Routes message to the taunt subsystem |
| `Template` | bool | Build-template share (from `build_templates.lua`) |
| `SendResumedBy` | bool | Game-resume notification (from `pause.lua`) |
| `ShareablePainting` | table | Painting data (from `PaintingCanvasAdapter.lua`) |
| `Identifier` | string | Modern routing key for `RegisterChatFunc` dispatch (preferred) |
| `data` | table | Payload for Notify messages (`{category, source, trigger, time?}`) |

> **Size limit:** `SessionSendChatMessage` silently errors out above ~4 KB per message. Paintings chunk their payload to stay under this limit.

### 2.2 `FindClients(id?)`

Utility in `chat.lua` that returns a list of client indices.

- No argument → allied clients of the focus army (or all observer clients if observing)
- `id` (army number) → clients controlling that specific army

Imported directly by `score.lua`, `notify.lua`, and `painting/ShareAdapters/PaintingCanvasAdapter.lua`.

---

## 3. Receiving — The Dispatch Chain

### 3.1 Engine callback: `gamemain.ReceiveChat(sender, data)`

This is the **single engine callback** invoked whenever any peer calls `SessionSendChatMessage`. It dispatches via the `chatFuncs` registry:

```
gamemain.ReceiveChat(sender, data)
  │
  ├─ data.Identifier present → chatFuncs[data.Identifier](sender, data)   [preferred path]
  │
  └─ legacy fallback → iterate chatFuncs, call func if data[identifier] is truthy
```

### 3.2 `RegisterChatFunc(func, identifier)`

Registers a handler. Current registrations:

| Identifier | Handler | Registered in |
|------------|---------|---------------|
| `'Chat'` | `chat.ReceiveChat` | `chat.SetupChatLayout` |
| `'SendResumedBy'` | `SendResumedBy` (local fn) | `gamemain` init |
| `'Taunt'` | (legacy field match) | via field `data.Taunt` |
| `'Template'` | build-template handler | via field `data.Template` |
| `'ShareablePainting'` | painting adapter | via field `data.ShareablePainting` |

### 3.3 `chat.ReceiveChat(sender, msg)`

The `'Chat'`-identifier handler. Two responsibilities:

1. **Sim callback** (non-replay, non-console): fires `GiveResourcesToPlayer` with zero resources as a sim-side hook to synchronise chat receipt across the sim boundary.
2. Delegates to `ReceiveChatFromSim(sender, msg)` for all display logic (skipped during replay — the replay system drives `ReceiveChatFromSim` directly from `gamemain`).

### 3.4 `ReceiveChatFromSim(sender, msg)`

Performs final validation and appends to `chatHistory`:

1. `msg.ConsoleOutput` → `print()` only, no chat display, early return.
2. `msg.Chat ~= true` → dropped silently.
3. `msg.to == 'notify'` → routed through `notify.processIncomingMessage`; if that returns `false` the message is suppressed.
4. `armyData` lookup by sender name; drops unknown senders in non-replay multiplayer.
5. Builds an `entry` record with `name`, `tokey`, `color`, `armyID`, `faction`, `text`, `wrappedtext`, `new`, `camera`.
6. Inserts into `chatHistory` and triggers a scroll-to-bottom refresh.

---

## 4. AI Chat Path

AI chat bypasses `SessionSendChatMessage` entirely.

`AIChatSorian.AISendChatMessage(towho, msg)` calls `chat.ReceiveChat(msg.aisender, msg)` directly on the local client — no network round-trip. The `aisender` field carries the AI player's name string. Taunts from AI are routed to `taunt.RecieveAITaunt` instead.

---

## 5. Chat Display

### 5.1 `chatHistory`

A module-local table of entry records. Each record:

```lua
{
    name        = string,     -- formatted "sender to-string"
    tokey       = string,     -- key into ChatOptions for color lookup
    color       = string,     -- ARGB hex of sender's team color
    armyID      = number,     -- index for per-army filter
    faction     = number,     -- faction icon index
    text        = string,     -- raw message text
    wrappedtext = string[],   -- text wrapped to current window width
    new         = bool,       -- true until first displayed
    camera      = table|nil,  -- camera settings if a ping link is attached
    time        = number|nil  -- fade timer (seconds since display, set lazily)
}
```

### 5.2 Chat Lines (`GUI.chatLines[]`)

A pool of `Group` controls, one per visible row. Each row contains:
- `teamColor` — solid-colour bitmap (team colour border)
- `factionIcon` — faction logo bitmap
- `name` — clickable text label (clicking sets `ChatTo` to that player for private reply)
- `text` — message text; clickable if the entry has `camera` data (restores camera on click)
- `lineStickybg` — semi-transparent background shown in feed mode

Line count is recalculated on resize to fill the container exactly.

### 5.3 Scrolling

The `chatContainer` implements the standard MAUI scrollable interface (`GetScrollValues`, `ScrollLines`, `ScrollPages`, `ScrollSetTop`, `IsScrollable`). The virtual size is the total wrapped-line count across all *filtered* history entries.

`CalcVisible()` maps the current scroll position into `chatHistory`, handles line wrapping, and populates each `GUI.chatLines[i]` accordingly.

### 5.4 Feed Mode (window hidden)

When `GUI.bg` is hidden, the most recent lines are shown directly over the game world without the window frame. Each line:
- Shows until `curHistory.time >= ChatOptions.fade_time`, then hides itself via `OnFrame`.
- Optionally shows `lineStickybg` for readability (controlled by `ChatOptions.feed_background`).

### 5.5 Text Wrapping

`WrapText(data)` delegates to `maui/text.lua.WrapText`. Width is measured in screen pixels by querying `GUI.chatLines[1]`'s actual pixel width, accounting for the name prefix on the first continuation line. All history entries are re-wrapped on resize (`RewrapLog()`).

---

## 6. Sending — Input Flow

### 6.1 Recipient Selection

`ChatTo` is a `lazyvar` holding:
- `'all'` — all players + observers
- `'allies'` — allied players only
- A number (army index) — private message to one player

`ActivateChat(modifiers)` resolves the initial value based on `ChatOptions.send_type` and the Shift modifier.

The chat-bubble button (`group.chatBubble`) opens `CreateChatList`, a dropdown showing all armies plus "All" and "Allies". Selecting an entry sets `ChatTo`.

Clicking a **name** in the feed also sets `ChatTo` to that player's army index.

### 6.2 `OnEnterPressed(text)`

Executed when the user submits a message:

1. **Slash commands** — if text starts with `/`, parse words, call `RunChatCommand(args)` (from `notify/commands.lua`); if handled, return early.
2. Empty text or whitespace-only → `ToggleChat()` (closes window).
3. Taunt check — `taunt.CheckForAndHandleTaunt(text)`; if it matches a taunt string, send via taunt path and return.
4. Build `msg` table: `{to = ChatTo(), Chat = true, text = text}`.
5. Attach `camera` if the camData checkbox is checked or `tempCam` is set.
6. Dispatch via `SessionSendChatMessage` with appropriate client list based on `ChatTo()` and `GetFocusArmy()`:
   - `'allies'` + player → `FindClients()`
   - `'allies'` + observer → `FindClients()` + `msg.Observer = true`
   - number (private) → `FindClients(ChatTo())`, then echo locally via `ReceiveChat`
   - `'all'` + player → `SessionSendChatMessage(msg)` (no explicit client list = broadcast)
   - `'all'` + observer → `FindClients()` + `msg.Observer = true`
7. Append to `commandHistory`.

### 6.3 Command History

Arrow-Up/Down in the edit box cycles through `commandHistory`. Each entry is the full `msg` table, so camera state is restored alongside text.

### 6.4 Camera Attachment

The camData `Checkbox` in the edit area lets the user attach the current `WorldCamera` settings to a message. Clicking a received message that has `camera` data calls `WorldCamera:RestoreSettings(cameraData)`.

### 6.5 Keyboard Shortcuts

Registered in `keymap/keyactions.lua`:

| Key | Action |
|-----|--------|
| Page Up | `chat.ChatPageUp(10)` |
| Page Down | `chat.ChatPageDown(10)` |
| Shift+Page Up | `chat.ChatPageUp(1)` |
| Shift+Page Down | `chat.ChatPageDown(1)` |
| Page Up (in edit box) | same as above |
| Page Down (in edit box) | same as above |

---

## 7. Chat Options (Preferences)

`ChatOptions` is loaded from the profile at module initialisation and saved back on Apply/OK.

| Key | Type | Default | Meaning |
|-----|------|---------|---------|
| `all_color` | 1–8 | 1 | Color index for "all" messages |
| `allies_color` | 1–8 | 2 | Color index for ally messages |
| `priv_color` | 1–8 | 3 | Color index for private messages |
| `link_color` | 1–8 | 4 | Color index for camera-link messages |
| `notify_color` | 1–8 | 8 | Color index for Notify messages |
| `font_size` | 12–18 | 14 | Chat font size in points |
| `fade_time` | 5–30 | 15 | Seconds before feed lines/window auto-hide |
| `win_alpha` | 0.2–1.0 | 1 | Window opacity (stored as 0–100, normalized on use) |
| `feed_background` | bool | false | Show semi-transparent bg behind feed lines |
| `send_type` | bool | false | Default recipient: false = all, true = allies |
| `links` | bool | true | Show camera-link messages |
| `[armyID]` | bool | true | Per-army message filter (one key per army, set at game start) |

**Color palette:** 8 fixed ARGB hex values (`chatColors[]`), shown as swatches in the config window.

**Callback system:** External code can subscribe to options changes via `AddChatOptionSetCallback(callback, id?)`. The callback is called immediately with current options and again whenever the user applies new options.

---

## 8. Window Behaviour

- **Pin button** — prevents the auto-hide timer from running.
- **Auto-hide timer** — `GUI.bg.OnFrame` increments `curTime`; when it exceeds `fade_time` the window is hidden via `ToggleChat()`. Any user activity (typing, scrolling, receiving a message) resets `curTime`.
- **Resize** — drag handles at all four corners. `OnResizeSet` triggers `RewrapLog()` + `CreateChatLines()` + `CalcVisible()`.
- **Reset position button** — snaps the window back to its default screen position.
- **Config button** — opens/closes `CreateConfigWindow()` (a separate draggable `Window`).
- **Close button** — calls `ToggleChat()`.
- **Mouse wheel** on hidden window — forwarded to the world-view zoom.

---

## 9. Notify Subsystem Integration

`notify.lua` registers ACU-upgrade messages with `to = 'notify'` and `Chat = true`.

In `ReceiveChatFromSim`, the `to == 'notify'` check calls `notify.processIncomingMessage(sender, msg)`:
- Returns `false` → message suppressed (category disabled, rate-limited, or NIS mode).
- Returns `true` (possibly mutating `msg.text` to a default message) → falls through to normal display.

Notify messages use `notify_color` for their text color.

---

## 10. Special Message Types Bypassing the Chat Feed

These use `SessionSendChatMessage` as transport but do **not** display in the chat window:

| Sender | Fields | Effect |
|--------|--------|--------|
| `diplomacy.lua` | `{to='all', ConsoleOutput=msg}` | Printed to game console only |
| `pause.lua` | `{SendResumedBy=true}` | Triggers `SendResumedBy` handler in gamemain |
| `build_templates.lua` | `{Template=true, data=…}` | Shares a build template to an ally |
| `casting/mouse.lua` | custom fields | Observer mouse-position broadcast |
| `painting/PaintingCanvasAdapter.lua` | `{ShareablePainting=…}` | Painting canvas data (chunked, ~4 KB limit) |

---

## 11. Taunt Integration

`taunt.lua` intercepts text entered in the chat edit box via `CheckForAndHandleTaunt(text)` before the message is sent. If matched:
- Sends `{Taunt=true, data=tauntIndex}` via `SessionSendChatMessage` (no explicit client list).
- The receiving side handles this through the `Taunt` field match in the legacy chatFuncs dispatch.
- On receipt, the taunt text is fed back into `chat.ReceiveChat` as a normal `Chat=true` message for display.

---

## 12. File Map

| File | Role |
|------|------|
| `lua/ui/game/chat.lua` | Core module: UI creation, history, display, sending |
| `lua/ui/game/gamemain.lua` | Engine callback (`ReceiveChat`), `RegisterChatFunc` registry, lifecycle calls |
| `lua/ui/game/layouts/chat_layout.lua` | Layout skin: positions the chat Window |
| `lua/ui/notify/notify.lua` | Notify subsystem: ACU upgrade messages, filter state |
| `lua/ui/notify/commands.lua` | `/command` dispatch table |
| `lua/AIChatSorian.lua` | AI chat: bypasses network, calls `chat.ReceiveChat` directly |
| `lua/ui/game/taunt.lua` | Taunt interception and display |
| `lua/ui/game/ping.lua` | Map-ping messages with attached camera state |
| `lua/ui/game/score.lua` | Resource-sharing chat notifications |
| `lua/ui/game/pause.lua` | Pause/resume chat notifications |
| `lua/ui/game/diplomacy.lua` | Draw-offer console output via chat transport |
| `lua/ui/game/build_templates.lua` | Build-template sharing via chat transport |
| `lua/ui/game/casting/mouse.lua` | Observer mouse-position broadcast via chat transport |
| `lua/ui/game/painting/…/PaintingCanvasAdapter.lua` | Painting sharing via chunked chat messages |
| `lua/keymap/keyactions.lua` | Keyboard shortcut bindings for chat scroll |

---

## 13. Known Design Issues (Refactoring Targets)

1. **Single monolithic file** — `chat.lua` mixes UI creation, layout, message-routing logic, history management, text wrapping, options persistence, and the config dialog into one ~1560-line file.

2. **`GUI` is a module-global shared with the layout file** — `GUI` is obtained from `/lua/ui/controls.lua` and mutated freely; there is no clear ownership boundary.

3. **`chatHistory` entries carry display state** — `time` and `new` are display-lifecycle fields stored on data records, coupling the history model to the feed renderer.

4. **Dual receive paths** — `ReceiveChat` and `ReceiveChatFromSim` exist because of the sim-callback detour; the naming is confusing and the split responsibilities are not obvious.

5. **`msg` table schema is implicit** — no type annotations or schema definition; each caller adds ad-hoc fields. The `Identifier` field was added as a preferred routing key but most senders still rely on the legacy field-match fallback.

6. **`FindClients` is imported by multiple unrelated modules** — its coupling to army/team logic could be separated into a `clientutils`-style module (a partial precedent exists in `gamemain.lua` which already imports `clientutils.GetAll()`).

7. **`ChatOptions` is read at module load time** — changes require a full `GUI.bg:OnOptionsSet()` cycle; there is no reactive binding except via `AddChatOptionSetCallback`.

8. **Window state leaks into history entries** — `entry.time` and `entry.new` are display-lifecycle fields stored on data records; they should be display-side state.
