# Lobby chat — design

The custom lobby's chat. The in-game chat ([`/lua/ui/game/chat/`](/lua/ui/game/chat/)) can't be
reused — it transfers over the engine's `SessionSendChatMessage` across *armies*, and a lobby has
*peers/slots*, not armies. So chat is built on the lobby's own host-authoritative message layer.

## Two principles

1. **The host is authoritative for broadcasting chat.** A client never broadcasts directly; it *asks*
   the host, and the host decides whether to relay. That gives one chokepoint
   ([`CustomLobbyController.ProcessRequestChat`](/lua/ui/lobby/customlobby/CustomLobbyController.lua))
   where filtering — mute, rate-limit, slow-mode, profanity — will live, without touching anything else.
2. **A line you send is shown to you immediately, then its state can change.** The sender echoes the
   line locally as `Pending` the instant they hit Enter; when the host's authoritative copy comes
   back, it reconciles to `Confirmed` (or could be `Rejected`/dropped). This is why a chat entry has a
   mutable `Status` and a stable, client-stamped `Id`.

## Chat is a per-peer feed, not synced state

What is host-authoritative is the *decision to broadcast a message* — a transient wire message — not
stored shared state. Each peer just accumulates the lines it receives. So chat is **not** a fourth
synced model; it is the chat equivalent of [`CustomLobbyLog`](/lua/ui/lobby/customlobby/CustomLobbyLog.lua):
a per-peer reactive `Entries` ring buffer. Unlike the Log it is *written by the controller*, so it is
a `ClassSimple : Destroyable` registered in the session trash (freed on `Teardown()`), like the
[derived models](/lua/ui/lobby/customlobby/models/derived/CLAUDE.md).

## The flow

```
edit box Enter
  └─ CustomLobbyChatController.Send(text)                       [input path: command vs chat]
       ├─ '/' line → handled locally, NOTHING on the wire       (registry = slice 2; stub for now)
       └─ plain   → ChatModel.Append(Pending) + Controller.RequestChat(text, id)

CustomLobbyController.RequestChat(text, id)                      [the wire half]
  ├─ host:   ProcessRequestChat(self, {SenderID=me, Text, Id})  (short-circuit)
  └─ client: SendData(host, { Type='RequestChat', Text, Id })

CustomLobbyController.ProcessRequestChat(instance, data)         ★ the single chat chokepoint
  ├─ (future) mute / rate-limit / slow-mode — return early to drop
  ├─ SenderName = FindNameForOwner(data.SenderID)               (host resolves it; clients can't spoof)
  ├─ instance:BroadcastData({ Type='ChatMessage', Id, SenderID, SenderName, Text })
  └─ ProcessChatMessage(instance, message)                      (broadcast doesn't loop back → show locally)

CustomLobbyController.ProcessChatMessage(instance, data)         [every peer]
  └─ CustomLobbyChatModel.Receive{ Id, SenderId, SenderName, Text }
       ├─ a held Pending line with this Id → reconcile to Confirmed   (our own echo)
       └─ otherwise → append a new Confirmed line                     (someone else's)
```

Ids are `localPeerId .. ':' .. counter`, unique across peers, so the echo reconciles only the
originator's optimistic line. The host's own line reconciles in the same frame (its broadcast doesn't
loop back, so `ProcessRequestChat` displays it directly); a client's line takes a real round-trip —
the same mechanism either way.

## Files (slice 1)

| File | Role |
|---|---|
| [CustomLobbyChatModel.lua](CustomLobbyChatModel.lua) | per-peer reactive `Entries` ring buffer; `Append` (optimistic / system) + `Receive` (reconcile-or-append) + `NextId`. |
| [CustomLobbyChatController.lua](CustomLobbyChatController.lua) | the send pipeline: `Send` (command-vs-chat), `AppendLocalSystem`, `SetRecipient`. |
| [CustomLobbyChatPanel.lua](CustomLobbyChatPanel.lua) | the Chat tab: a scrollable feed (built to the [Logs-tab](CustomLobbyLogsPanel.lua) shape) over an edit box. |
| [`../CustomLobbyMessages.lua`](/lua/ui/lobby/customlobby/CustomLobbyMessages.lua) | `RequestChat` (Accept: any peer) + `ChatMessage` (Accept: from host) + `SystemNotice` (Accept: from host — join/leave). |
| [`../CustomLobbyController.lua`](/lua/ui/lobby/customlobby/CustomLobbyController.lua) | `RequestChat` / `ProcessRequestChat` (chokepoint) / `ProcessChatMessage` + `FindNameForOwner`; `BroadcastSystemNotice` / `ProcessSystemNotice` (join/leave, hooked in `ProcessAddPlayer` / `OnPeerDisconnected`). |

## Roadmap (later slices)

- **Slice 2 — commands.** A `social/commands/` registry mirroring
  [`/lua/ui/game/chat/commands/`](/lua/ui/game/chat/commands/) (own `Commands` table, own resolvers
  `Slot`/`Peer`, own dispatch `ctx`). Built-ins call existing controller intents (`/take`, `/close`,
  `/help`). **Host-gating goes in `Accept`, not `ShouldRegister`** — `IsHost` flips only after the
  connection handshake, so it must be evaluated per-invocation. `Send`'s `/` branch dispatches here.
- **Slice 3 — whisper.** `RequestChat` carries a `Recipient`; `ProcessRequestChat` `SendData`s to
  sender+target instead of `BroadcastData`. Same chokepoint.
- **Slice 4 — system notices (done).** The host emits a `SystemNotice` (a senderless system line) at
  its authoritative change sites; `BroadcastSystemNotice` broadcasts it **and** shows it on the host too
  (the broadcast doesn't loop back). Chosen over the originally-sketched "each peer diffs the roster
  locally" because (a) the host doesn't run `ProcessSetPlayers` on itself, so a local diff would skip the
  host, and (b) a joining peer would otherwise spam "X joined" for the whole existing roster on its first
  snapshot. Host-broadcast is one symmetric path with no diff and no baseline-flag.
  - Wired: **join** (`ProcessAddPlayer`), **leave** (`OnPeerDisconnected`), **kick** (`RequestEject` adds
    "Host removed X."; a human kick also produces the disconnect's "left" line — two lines is fine),
    **map / mods / options / restrictions** changes (the `RequestSet*` intents, which fire
    once per action — *not* on snapshot rebroadcasts, so no spam), **seat swap / move** (`SwapSlots`,
    covering host-initiated and any client-requested swap), **move-to-observers**
    (`RequestMoveToObserver`), and **auto-balance applied** (`RequestApplyBalance`).
  - Not yet emitted (deliberately, as noise-prone): ready toggles, slot takes, faction/colour picks.
    Per-option diffs ("changed Unit Cap to 1000") would read better than the generic "changed the game
    options" but need an old-vs-new compare in the intent.
- **Refinements.** Multi-line wrapping (slice 1 truncates one line per row — the in-game
  [`ChatLinesInterface`](/lua/ui/game/chat/ChatLinesInterface.lua) is the reference); unread-since-last-view
  badge count (slice 1 shows the total line count).
```
