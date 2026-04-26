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

Closing is still reachable via the close button, the `Escape` key on an empty edit box, and the `debug_chat_window` keybind.

---

## Layout-specific chat-window *positions* are gone (skin-driven theming is preserved)

Skins and layouts are independent axes:
- **Skin** drives texture / colour palette — resolved per-asset via `UIUtil.SkinnableFile`.
- **Layout** drives HUD widget arrangement (`bottom`, `left`, `right`) — defined in [`/lua/skins/layouts.lua`](../../../skins/layouts.lua) as a table mapping HUD-widget keys to per-widget layout files.

The deleted `/lua/ui/game/layouts/chat_layout.lua` was the chat's *layout* entry, providing layout-specific positions and sizes (where the chat lived for each of `bottom` / `left` / `right`). That file is gone, along with its `chat` entries in `/lua/skins/layouts.lua`; the new [`ChatInterface`](ChatInterface.lua) uses a single rect (`DefaultRect`) regardless of layout, and the user can drag / resize from there. Switching layouts no longer repositions the chat window.

**Theming is preserved on the skin axis.** [`ChatInterface`](ChatInterface.lua) loads its border, corner-grip, scrollbar, and titlebar-button textures through `UIUtil.SkinnableFile` rather than `UIUtil.UIFile`, so each path resolves against the current skin every time MAUI reads the bound LazyVar. Switching skins reactively repaints the chrome without touching the chat tree. The legacy `SetLayout` global that re-ran the chat's layout file is therefore unneeded — the [chat.lua compatibility shim](../chat.lua) keeps it around as a deprecated no-op.

### Why no `OnLayoutChanged` hook

[`gamemain.SetLayout(layout)`](../gamemain.lua) fans out to every HUD widget when the user picks a different HUD arrangement. The chat is intentionally **not** in that chain. Considered alternatives:

- *Per-layout default rects* — would mean three more rect tables that mostly differ by where they choose to overlap other widgets. Not enough variation in the legacy `chat_layout.lua` to justify the surface area.
- *Auto-reset on layout change* — would clobber the user's saved rect on every layout switch. User-hostile.
- *Clamp-to-screen on layout change* — defensible, but `DefaultRect` already lives well inside any layout's safe area, and the new title-bar **Reset-position** button covers the "I've gotten lost" case explicitly without overwriting anyone's preferences.

The chat is **user-positioned**: its rect persists under the prefs key `chat_window_v2` and survives layout / skin / session changes by design. Mods that need layout-aware repositioning can call into `model.WindowVisible` and write a new rect via the existing prefs path — no new public API.

---

## Empty-text Enter always closes the window

Legacy behaviour: pressing `Enter` on an empty edit box called `ToggleChat()` — i.e. close if open, open if hidden. Since Enter only fires when the edit box has focus (and focus implies the window is already visible), the new [`ChatEditInterface.OnEnterPressed`](ChatEditInterface.lua) unconditionally calls `ChatController.CloseWindow()` on empty text. Net effect: identical.

---

## Legacy `chat.lua` renamed to `chat.legacy.lua`

The original monolithic file is preserved on disk as [`chat.legacy.lua`](../chat.legacy.lua) so its source is still available as a reference while porting the remaining gaps. **No live importer remains** — every caller was repointed before the rename. The file can be deleted outright once [GAPS.md](GAPS.md) is empty.

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
