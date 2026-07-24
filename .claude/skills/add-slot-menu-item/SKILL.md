---
name: add-slot-menu-item
description: Add an entry to the CustomLobby slot right-click context menu (e.g. Kick, Move to observers, Close slot). Use when the user asks to add, gate, or scaffold a slot context-menu action in the custom lobby. Edits the declarative list in lua/ui/lobby/customlobby/CustomLobbyMenus.lua and, for a new operation, adds a CustomLobbyController intent.
---

# Adding a slot context-menu item

One edit in most cases: append an entry to the `SlotMenu` list in [CustomLobbyMenus.lua](/lua/ui/lobby/customlobby/CustomLobbyMenus.lua).

```lua
{
    label  = "Close slot",   -- example of a NEW action (RequestCloseSlot doesn't exist yet — add it)
    when   = function(ctx) return ctx.isHost and ctx.isOpen end,
    action = function(ctx) CustomLobbyController.RequestCloseSlot(ctx.slot) end,
    -- enabled = function(ctx) ... end,  -- optional; omit for always-enabled. false = greyed, not hidden
},
```

(Already wired, for reference: `Move to observers` → `RequestMoveToObserver`, `Eject` → `RequestEject`, ready toggles, `Take this slot` → `RequestTakeSlot`.)

`ctx` (see `SlotContext`): `slot`, `player|false`, `isHost`, `isYou`, `isOpen`.

## Do / Don't

| | Rule |
|---|------|
| ✅ | Gate visibility with `when(ctx)` — that's how host vs player / open vs occupied menus differ. Use `enabled` only when you want the item shown-but-greyed. |
| ✅ | Have `action(ctx)` call a **`CustomLobbyController` intent** (`RequestX`). Keep it one line. |
| ✅ | If the action is a new operation, add the intent to [CustomLobbyController.lua](/lua/ui/lobby/customlobby/CustomLobbyController.lua) first: host applies + `BroadcastPlayers`; a client `SendData`s a request the host validates (add a typed message in [CustomLobbyMessages.lua](/lua/ui/lobby/customlobby/CustomLobbyMessages.lua) + a `ProcessX` handler). The host stays authoritative. |
| 🚫 | Write to the model from `action` — read it, mutate via a controller intent. |
| 🚫 | Touch [CustomLobbyContextMenu.lua](/lua/ui/lobby/customlobby/CustomLobbyContextMenu.lua) — it's a generic renderer and knows nothing about the lobby. |
| 🚫 | Build the menu in the slot row — the row only calls `BuildSlotMenu(slot)`; definitions live in `CustomLobbyMenus`. |
| 🚫 | Use the `%` operator (FAF is Lua 5.0 — use `math.mod`). |

## A whole new menu surface (not just a slot item)

The renderer [CustomLobbyContextMenu.lua](/lua/ui/lobby/customlobby/CustomLobbyContextMenu.lua) is generic — slots are just its first caller. To add another surface (lobby background, observer list, options…): add a new entry list + `BuildXMenu(...)` in `CustomLobbyMenus.lua` (its own `ctx` shape), then have that control's right-click call `CustomLobbyContextMenu.Show(CustomLobbyMenus.BuildXMenu(...), event.MouseX, event.MouseY)`. Don't edit the renderer.

## Verify

An empty result simply doesn't show. Right-click a slot in each relevant state (your own / another's / open; as host and as client) and confirm the item appears only `when` it should and its intent round-trips. UI-only check: `import("/lua/ui/lobby/customlobby/customlobbyinterface.lua").OpenDebug()`.
