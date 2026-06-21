# Custom Lobby — rebuild (work in progress)

A ground-up, reactive-MVC rebuild of the custom-games lobby (the player-driven
counterpart to the matchmaker [`autolobby/`](../autolobby/CLAUDE.md)). It replaces
the organically-grown [`/lua/ui/lobby/lobby.lua`](../lobby.lua).

> **Read first**, in order:
> - [`/lua/ui/CLAUDE.md`](/lua/ui/CLAUDE.md) — UI patterns (LazyVar/`Derive`, `__init`/`__post_init`, `TrashBag`).
> - [`/lua/ui/lobby/autolobby/CLAUDE.md`](../autolobby/CLAUDE.md) — the proven Model / Instance / Controller / components split this mirrors.
> - [`/lua/ui/lobby/TARGET_ARCHITECTURE.md`](../TARGET_ARCHITECTURE.md) — the design for this rebuild.
> - [`/lua/ui/lobby/FEATURES.md`](../FEATURES.md) / [`USER_STORIES.md`](../USER_STORIES.md) — the parity target.

## Naming

Folder `customlobby/`, class/module prefix `CustomLobby` — pairs with `autolobby/` /
`Autolobby*`. "Custom" is FAF's own term for non-matchmaker games (the autolobby is
the automated/matchmaker path).

## Status — first vertical slice

Built so far (no networking yet — driven by the model + a debug entry point):

| File | Role |
|------|------|
| [CustomLobbyModel.lua](CustomLobbyModel.lua) | reactive model singleton. `Players` is an **array of per-slot LazyVars** so one slot's change re-fires only that row. Write helpers (`SetPlayer`, `SetPlayerField`, …) keep the copy-then-`Set` discipline. |
| [CustomLobbySlotInterface.lua](CustomLobbySlotInterface.lua) | one slot row; subscribes to `model.Players[slot]`, renders it (read-only for now). |
| [CustomLobbyInterface.lua](CustomLobbyInterface.lua) | composition root (no subscriptions of its own); lays out the slot rows; `OpenDebug()` / `SetupSingleton` / hot-reload. |

Inspect it without networking:

```
UI_Lua import("/lua/ui/lobby/customlobby/customlobbyinterface.lua").OpenDebug()
```

`CloseDebug()` tears it down. For the real flow, `scripts/LaunchCustomLobby.ps1`
launches host + clients into the regular lobby.

## Next slices (per TARGET_ARCHITECTURE.md)

1. `CustomLobbyController` (free functions) + `CustomLobbyInstance` (thin `moho` shell) +
   `CustomLobbyMessages` registry — the host-authority request→validate→broadcast flow.
2. Make slot controls interactive (faction/colour/team/ready → controller **intents**).
3. Options panel, map preview, observer list, footer, chat — each its own subscribing component.
4. Sub-dialogs (map select, mods, units, presets, prefs) as mini-MVC.

## Rules (same as autolobby)

- Components subscribe via `Derive`; they never write the model.
- The controller is the only writer, through the model write-helpers (never mutate a held table in place).
- A `Derive` handler must read its own LazyVar (`function(xLazy) self:OnX(xLazy()) end`).
- FAF is Lua 5.0 — no `%` operator; use `math.mod`.
