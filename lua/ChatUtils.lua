
-- Sim-side helpers for the refactored in-game chat. Lives outside `SimUtils`
-- so chat can grow without bloating the general utility file, and so UI and
-- other sim systems have one obvious place to look for chat-relay logic.
--
-- The UI-side counterparts live under `/lua/ui/game/chat/`. Anything that
-- has to run sim-side (command-source lookups, trusted sender stamping,
-- `Sync` writes) belongs here; pure formatting or routing of an already-
-- trusted message should stay on the UI side.

local SimUtils = import("/lua/simutils.lua")

--- Legacy replay hook kept for external callers that may still reference it.
--- The refactored chat path no longer uses this — chat is now relayed through
--- `Sync.ChatMessages` (see `SendChatMessage`) and external replay parsers
--- read the `Sender`/`Msg` fields off the recorded `GiveResourcesToPlayer`
--- callback args, which the UI sender emits once per outgoing message.
---@param data {Sender: integer, Msg: string}
function SendChatToReplay(data)
    if data.Sender and data.Msg then
        if not Sync.UnitData.Chat then
            Sync.UnitData.Chat = {}
        end
        table.insert(Sync.UnitData.Chat, { sender = data.Sender, msg = data.Msg })
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
---@param data {Msg: table}
function SendChatMessage(data)
    if type(data) ~= 'table' or type(data.Msg) ~= 'table' then return end
    local msg = data.Msg
    if msg.Chat ~= true then return end
    if type(msg.text) ~= 'string' or msg.text == '' then return end

    -- Trusted sender stamp; ignore whatever the client put in `msg.From`.
    local from = SimUtils.GetCurrentCommandSourceArmy()
    if not from then return end

    -- Private-message guard: a numeric `to` is an army ID the sender is
    -- whispering to. Cross-alliance whispers are rejected.
    if type(msg.to) == 'number' and not IsAlly(from, msg.to) then
        return
    end

    msg.From = from

    Sync.ChatMessages = Sync.ChatMessages or {}
    table.insert(Sync.ChatMessages, msg)
end
