
-- Sim-side helpers for the refactored in-game chat. Lives outside `SimUtils`
-- so chat can grow without bloating the general utility file, and so UI and
-- other sim systems have one obvious place to look for chat-relay logic.
--
-- The UI-side counterparts live under `/lua/ui/game/chat/`. Anything that
-- has to run sim-side (command-source lookups, trusted sender stamping,
-- `Sync` writes) belongs here; pure formatting or routing of an already-
-- trusted message should stay on the UI side.

local SimUtils = import("/lua/simutils.lua")
local ChatPayload = import("/lua/shared/ChatPayload.lua")

--- Per-client recipient filter. The sim runs deterministically on every
--- client, but `Sync` is per-client and `GetFocusArmy()` reads the local
--- viewer's focus — so every client can independently decide whether to
--- relay a given message to its own UI, without diverging the shared sim
--- state. Mirrors the legacy `FindClients` routing policy:
---
--- * Observers (`focus == -1`) see everything, matching the legacy replay
---   and live-spectator behaviour where privates become visible so the
---   conversation can be attributed.
--- * `all` broadcasts always pass.
--- * `allies` broadcasts pass to the sender and to anyone `IsAlly` with
---   the sender.
--- * Numeric `to` is a private whisper — only the sender and the named
---   recipient pass.
---@param msg ChatPayload
---@return boolean
function IsLocalRecipient(msg)
    local focus = GetFocusArmy()
    if focus == -1 then return true end

    local to = msg.to
    if to == 'all' then return true end
    if to == 'allies' then
        return focus == msg.From or IsAlly(focus, msg.From)
    end

    if type(to) == 'number' then
        return focus == msg.From or focus == to
    end
    return false
end

--- Writes `msg` onto `Sync.ChatMessages` only if the local client is a
--- legitimate recipient. Shared entry point for every sim-originated
--- chat emitter (the `SendChatMessage` callback for UI-sent messages, the
--- `AIChatBrainComponent` for AI-emitted lines, and any future sim system
--- that wants to drop a line into the chat feed) so the recipient policy
--- is enforced sim-side in exactly one place.
---@param msg ChatPayload
function RelayChatMessage(msg)
    if IsLocalRecipient(msg) then
        Sync.ChatMessages = Sync.ChatMessages or {}
        table.insert(Sync.ChatMessages, msg)
    end
end

--- Relays a chat message from a UI client back to every UI client via
--- `Sync.ChatMessages`. The sender field is taken from the command source
--- and written into `Msg.From` so clients can't spoof the originating army.
--- UI-side listeners dedupe against messages already in history (by `Id`),
--- so firing this alongside the legacy `SessionSendChatMessage` path is safe.
---
--- Ally checks: private messages (numeric `msg.to`) require `IsAlly(from, to)`
--- — we refuse to relay a whisper between non-allies the way the legacy
--- `FindClients` path refused to route one. The `all` and `allies` channels
--- are permitted from any player; `Sync.ChatMessages` broadcasts to every UI,
--- so the UI is responsible for hiding `allies` messages from non-allies on
--- display.
---
--- Observers have no entry in the command-source-to-army map, so this path
--- drops their messages. Observer chat continues to work over the legacy
--- `SessionSendChatMessage` path; a future iteration can extend the sim
--- relay to carry an observer-identity field if we decide replays need to
--- show observer lines.
---
--- This is also the hook for sim-originated chat: a sim system that wants a
--- line to appear in every UI's chat feed can call `SendChatMessage` with a
--- synthesised `Msg` table (remember to set `Chat = true` and a non-empty
--- `text`, and leave `From` alone — we overwrite it).
---@param data {Msg: ChatPayload}
function SendChatMessage(data)
    if type(data) ~= 'table' then return end
    local msg = data.Msg

    -- Pure shape validation — type, length, recipient shape, optional
    -- payload table-types. Bouncing here saves the `Sync.ChatMessages`
    -- round-trip on every other client when the UI receive path would
    -- have dropped the message anyway.
    if not ChatPayload.IsValidPayload(msg) then return end

    -- `'notify'` is a UI subsystem channel — players reach this relay path
    -- only with broadcast or whisper recipients, so reject the shared
    -- validator's broader allow-list here.
    if msg.to == 'notify' then return end

    -- Trusted sender stamp; ignore whatever the client put in `msg.From`.
    local from = SimUtils.GetCurrentCommandSourceArmy()
    if not from then return end

    -- Private-message guard: a numeric `to` is an army ID the sender is
    -- whispering to. Cross-alliance whispers are rejected.
    if type(msg.to) == 'number' and not IsAlly(from, msg.to --[[@as integer]]) then
        return
    end

    msg.From = from

    RelayChatMessage(msg)
end
