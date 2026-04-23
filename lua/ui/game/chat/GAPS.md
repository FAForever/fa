# Chat MVC refactor — remaining gaps

Inventory of legacy [`/lua/ui/game/chat.lua`](../chat.lua) behaviour that the new MVC tree does **not** yet replicate. Gaps are grouped by concern and cite line numbers in the old file so a future author can jump in.

Accepted & intentional differences live in [CHANGES.md](CHANGES.md); this file only tracks work that hasn't happened yet.

---

## Feed mode / fade / pin

The most conspicuous missing chunk. None of the "auto-fading feed of recent chat when the window is hidden" behaviour has been ported.

- **Per-line fade timer** — `line.OnFrame` delta-time countdown driven by `ChatOptions.fade_time` ([chat.lua:471-492](../chat.lua)).
- **Window auto-close timer** — `GUI.bg.OnFrame` hides the whole window after `fade_time` with no new traffic ([chat.lua:1171-1176](../chat.lua)).
- **Translucent feed background** — `line.lineStickybg` when `feed_background` is enabled ([chat.lua:233-238, 465](../chat.lua)). Explicitly dropped from `ChatLineInterface` (see its comment at line 22).
- **Feed persist** — `feed_persist` keeps feed lines until their individual timer runs out ([chat.lua:912-920](../chat.lua)).
- **Window opacity** — `SetAlpha(win_alpha)` on window bg and lines ([chat.lua:501, 1150, 1199](../chat.lua)).
- **Pin toggle** — `GUI.bg.OnPinCheck` suspends fade while pinned ([chat.lua:1177-1187](../chat.lua)). No pin button in the new window.

## Message filtering

[`ChatInterface.IsValidEntry`](ChatInterface.lua) is a stub returning `true`. The legacy filter gated on three things ([chat.lua:304-310](../chat.lua)):

- `ChatOptions.links` — hides camera-link messages.
- `ChatOptions[armyID]` — per-sender on/off checkboxes.
- Self-echo suppression and observer rules on receive.

Per-army filter UI needs re-adding to [`ChatConfigInterface`](config/ChatConfigInterface.lua) (legacy: [chat.lua:1194-1198, 1437-1442](../chat.lua)).

## Config options not reaching the view

[`ChatConfigModel`](config/ChatConfigModel.lua) defines every key correctly, but only `font_size` is subscribed by the view (see [`ChatInterface.ApplyOptions`](ChatInterface.lua)). Not yet wired:

- `all_color` / `allies_color` / `priv_color` / `link_color` / `notify_color` — the per-recipient text-colour palette ([chat.lua:63, 446-450](../chat.lua)).
- `fade_time`, `win_alpha`, `feed_background`, `feed_persist` — feed-mode options (blocked on the feed-mode port above).
- `links` — blocked on filtering port.
- `[armyID]` per-army filter keys — blocked on filtering port.

No replacement exists for the legacy public `AddChatOptionSetCallback` ([chat.lua:1071-1102](../chat.lua)) — external subscribers to option changes have no API.

## Camera / ping links

`UIChatEntry.Camera` is declared on the model but never populated or rendered.

- **Outgoing**: `chatEdit.camData` checkbox + `tempCam` recall ([chat.lua:750-754](../chat.lua)) not present on [`ChatEditInterface`](ChatEditInterface.lua). `ChatController.Send` never attaches `msg.camera`.
- **Incoming render**: `camIcon` bitmap on the line ([chat.lua:419-428](../chat.lua)) not on [`ChatLineInterface`](ChatLineInterface.lua).
- **Click to jump**: `line.Text` click → `GetCamera('WorldCamera'):RestoreSettings` ([chat.lua:223-229](../chat.lua)) — [`ChatLineInterface`](ChatLineInterface.lua) disables hit-test on the text control.

## Private reply by clicking a name

Legacy click on `line.name` set `ChatTo:Set(line.chatID)` and re-focused the edit ([chat.lua:199-212](../chat.lua)). [`ChatLineInterface`](ChatLineInterface.lua) disables hit-test on both name and text controls. No `last_sender` tracking either.

## Notify-command bridge

Slash commands in the old dispatcher fell through to `RunChatCommand` in [`/lua/ui/notify/commands.lua`](../../notify/commands.lua) ([chat.lua:729](../chat.lua)), so `/enablenotify`, `/disablenotify`, `/enablenotifyoverlay`, `/disablenotifyoverlay` all worked from chat. The new [`ChatCommandRegistry`](commands/ChatCommandRegistry.lua) dispatcher does not call `RunChatCommand`, so those commands are dead.

## Command history recall (↑ / ↓)

Legacy kept a `commandHistory` ring and recalled it on `VK_UP` / `VK_DOWN` ([chat.lua:681-701](../chat.lua)). Not ported. The new [`ChatEditInterface.OnNonTextKeyPressed`](ChatEditInterface.lua) only handles `PgUp` / `PgDn`.

## Shift-Enter → allies hotkey

Legacy `ActivateChat(modifiers)` ([chat.lua:924-933](../chat.lua)) opened the window with the recipient forced to allies when Shift was held — the primary way to toggle between `all` and `allies` mid-typing. [`keyactions.lua` `chat_window`](../../../keymap/keyactions.lua) only toggles visibility; the modifier argument is gone.

[`ChatController.ApplyDefaultRecipient`](ChatController.lua) reads the `send_type` preference but ignores any caller-supplied modifier.

## Drag / resize / window-state

Smaller things still missing on the window itself:

- **Pin button** — gated on feed-mode port.
- **`OnMoveSet` / `OnResizeSet` focus grab** — the legacy window re-acquired edit focus after moves ([chat.lua:1124, 1131-1135](../chat.lua)). [`ChatInterface.OnResizeSet`](ChatInterface.lua) does not.
- **Button tooltips** — `chat_pin`, `chat_config`, `chat_close`, `chat_camera`, `chat_reset` ([chat.lua:1200, 1211-1214](../chat.lua)) — none attached in the new tree.
- **Wheel-forward when hidden** — legacy `GUI.bg.HandleEvent` forwarded scroll to the worldview when chat was hidden ([chat.lua:1202-1209](../chat.lua)). Not ported.

## Army / observer markers

Per-line visuals mostly work (team-colour square + faction icon via [`ChatLineInterface.SetHeader`](ChatLineInterface.lua)). Missing:

- **Own-army name disable** — legacy `line.name:Disable()` greyed the sender name on your own messages ([chat.lua:409-413](../chat.lua)).

## Legacy public API with no replacement

If any external mod still calls these (no in-tree callers remain), they will break:

- `GUI` table (chat window handles)
- `ChatLines`
- `ReceiveChat` / `ReceiveChatFromSim` — migrate to [`ChatController.OnReceive`](ChatController.lua)
- `SetupChatLayout`
- `OnNISBegin`
- `ChatPageUp` / `ChatPageDown` — migrate to [`ChatInterface.OpenAndScrollLines`](ChatInterface.lua)
- `CloseChatConfig` — migrate to [`ChatConfigInterface.Close`](config/ChatConfigInterface.lua)
- `CloseChat`
- `AddChatOptionSetCallback`
- `SetLayout`
- `GetArmyData` (the one defined in chat.lua; several other copies exist elsewhere)

---

## Already closed (do not re-list)

Send path, receive path, `FindClients`, controller `Init`, external importers, skin-layout orphan, `ConsoleOutput` sim-side logging, empty-text Enter.
