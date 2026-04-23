# Chat MVC refactor — behavioural differences

Catalogue of every intentional change vs. the legacy [`/lua/ui/game/chat.lua`](../chat.lua) after it was replaced by the MVC tree under [`/lua/ui/game/chat/`](.). Additive — new features belong in the individual module docs, not here.

---

## Sim-side `ConsoleOutput` messages

Sim-originated chat messages carrying a `ConsoleOutput` field are log-only — they never open a chat line. The legacy path inspected this field inside `ReceiveChatFromSim`; the new [`ChatController.OnReceive`](ChatController.lua) drops any message whose `Chat` flag is false, so the `ConsoleOutput` branch moved up the stack.

**New home**: [`gamemain.lua` `SendChat`](../gamemain.lua) — the sim-chat replay loop prints `ConsoleOutput` messages directly instead of forwarding them to the controller. Every other message still goes through `sendChat(chat.sender, chat.msg)`.

This keeps the controller focused on displayable messages and preserves the old log behaviour for sim diagnostics.

---

## `PgDn` at scroll-bottom no longer closes the window

Legacy `ChatPageDown(mod)` had a quirk: pressing it when the feed was already scrolled to the bottom (or the window was hidden) would toggle the window. The new [`ChatInterface.OpenAndScrollLines`](ChatInterface.lua) keybind entry-point opens-then-scrolls; `PgDn` on an already-open, already-bottom window now does nothing.

Closing is still reachable via the close button, the `Escape` key on an empty edit box, and the `chat_window` keybind.

---

## Skin-specific chat-window theming is gone

The old `layouts/chat_layout.lua` file (loaded via `UIUtil.GetLayoutFilename('chat')`) applied skin-specific window textures and drag-handle art to the chat window. That file has been deleted along with its `bottom` / `left` / `right` entries in [`/lua/skins/layouts.lua`](../../../skins/layouts.lua).

The new [`ChatInterface`](ChatInterface.lua) uses a single set of textures for every skin. Skin switching no longer re-themes the chat window.

---

## Empty-text Enter always closes the window

Legacy behaviour: pressing `Enter` on an empty edit box called `ToggleChat()` — i.e. close if open, open if hidden. Since Enter only fires when the edit box has focus (and focus implies the window is already visible), the new [`ChatEditInterface.OnEnterPressed`](ChatEditInterface.lua) unconditionally calls `ChatController.CloseWindow()` on empty text. Net effect: identical.

---

## Engine registration moved out of module-load

`/lua/ui/game/chat.lua` registered its receive function and built-in commands as a side-effect of being imported. The new controller exposes an explicit [`ChatController.Init()`](ChatController.lua) which [`gamemain.lua`](../gamemain.lua) calls during UI setup, next to `taunt.Init()` and `build_templates.Init()`.

**Why**: mods can hook `ChatController` (replacing `Init`, `OnReceive`, or `RegisterBuiltinCommands`) before any wiring happens. A module-load-time register would run before mods get a chance to override.

---

## `ReceiveChat` → `OnReceive` at every injection point

The legacy `chat.lua.ReceiveChat(sender, msg)` is now [`ChatController.OnReceive(sender, msg)`](ChatController.lua). All existing injection points have been repointed:

| Caller | Purpose |
|---|---|
| [`AIChatSorian.AISendChatMessage`](../../../AIChatSorian.lua) | AI-to-player chat |
| [`taunt.lua` taunt display](../taunt.lua) | Taunt text as a chat line |
| [`gamemain.lua` `SendChat`](../gamemain.lua) | Sim-replayed chat |

Message shape and semantics are unchanged — callers pass the same `{Chat, text, to, ...}` tables.

---

## `FindClients` has a new home

Moved from `/lua/ui/game/chat.lua` to [`ChatController.FindClients`](ChatController.lua). Behaviour is byte-identical (same observer-mode, same ally-resolution logic). Callers updated:

- [`notify.lua`](../../notify/notify.lua)
- [`score.lua`](../score.lua)
- [`PaintingCanvasAdapter.lua`](../painting/ShareAdapters/PaintingCanvasAdapter.lua)

---

## `CloseChatConfig` → `ChatConfigInterface.Close`

The legacy standalone config-close entry point is now the `Close()` method on the new config module. Callers updated:

- [`tabs.lua`](../tabs.lua)
- [`multifunction.lua`](../multifunction.lua)

---

## `ChatPageUp` / `ChatPageDown` → `OpenAndScrollLines`

The `chat_page_up`, `chat_page_down`, `chat_line_up`, `chat_line_down` key bindings in [`keyactions.lua`](../../../keymap/keyactions.lua) now call [`ChatInterface.OpenAndScrollLines(±n)`](ChatInterface.lua) with a signed delta (negative = older messages) instead of separate up / down module functions.
