
--***************************************************************************
--** Summary: Chat component for the AI brain. Lets any AI drop a line into
--** every UI's chat feed with a single call — no knowledge of the sim-to-UI
--** sync plumbing required.
--**
--** The legacy `AIChatSorian` path pushed messages through a dedicated
--** `Sync.AIChat` → UI `AIChat()` → `ChatController.OnReceive` pipeline that
--** bypassed the rest of the chat system. Since the UI now listens on
--** `Sync.ChatMessages` (dedup'd by a sender-stamped `Id`), a sim-side
--** emitter — AI brain, campaign script, whatever — can write straight to
--** that stream and have its message surface through the same code path as
--** player chat, including the replay-playback path.
--****************************************************************************

local ChatUtils = import("/lua/chatutils.lua")

---@alias AIBrainChatRecipient 'all' | 'allies' | integer

--- Optional location hint attached to a chat message. The UI renders the
--- cam-icon affordance when either `Position` or `Area` is set and, on
--- click, points the viewer's camera at the matching spot — `MoveTo` for a
--- point (viewer's pitch/heading/zoom preserved) or `MoveToRegion` for an
--- area (framing computed automatically). Only one of the two is used; if
--- both are present `Area` wins.
---@class AIBrainChatLocation
---@field Position? Vector         # world-space focus point
---@field Area?     Rectangle      # world-space rectangle to frame

---@class AIBrainChatComponent
AIBrainChatComponent = ClassSimple {

    --- Broadcasts a message to every connected UI as an "all" chat line.
    ---@param self AIBrainChatComponent
    ---@param text string
    ---@param location? AIBrainChatLocation
    SendChatToAll = function(self, text, location)
        self:SendChatTo('all', text, location)
    end,

    --- Broadcasts a message to the AI's allies. `Sync.ChatMessages` reaches
    --- every UI, so the non-ally filter is applied client-side on display.
    ---@param self AIBrainChatComponent
    ---@param text string
    ---@param location? AIBrainChatLocation
    SendChatToAllies = function(self, text, location)
        self:SendChatTo('allies', text, location)
    end,

    --- Whispers a message to a specific army. No ally constraint — the AI is
    --- trusted sim code and may legitimately taunt an enemy or message a
    --- neutral party.
    ---@param self AIBrainChatComponent
    ---@param army integer
    ---@param text string
    ---@param location? AIBrainChatLocation
    SendChatToPlayer = function(self, army, text, location)
        self:SendChatTo(army, text, location)
    end,

    --- Addresses a message back at this brain's own army. Useful for
    --- debug-style output and campaign hints that should only reach whoever
    --- is watching this AI's perspective (typically just observers with
    --- full vision, or a human controller in campaign setups).
    ---@param self AIBrainChatComponent | AIBrain
    ---@param text string
    ---@param location? AIBrainChatLocation
    SendChatToSelf = function(self, text, location)
        self:SendChatTo(self:GetArmyIndex(), text, location)
    end,

    --- Shared implementation: builds the message, stamps it with the
    --- brain's army index and a dedupe id, and hands it to
    --- `ChatUtils.RelayChatMessage` for sim-side recipient filtering.
    --- The id is the message table's address — near-unique, survives
    --- serialisation as a plain string, and keeps the UI dedupe from
    --- double-posting if the same message arrives more than once (see
    --- `ChatController.OnSyncChatMessages`).
    ---
    --- `location`, if provided, rides on the message as `msg.location` and
    --- is surfaced to the UI as `entry.Location` — the click handler in
    --- `ChatInterface` translates it to a `MoveTo`/`MoveToRegion` call at
    --- click time, so there is no need to synthesise a camera snapshot
    --- sim-side.
    ---@param self AIBrainChatComponent | AIBrain
    ---@param to AIBrainChatRecipient
    ---@param text string
    ---@param location? AIBrainChatLocation
    SendChatTo = function(self, to, text, location)
        if type(text) ~= 'string' or text == '' then return end

        local msg = {
            Chat     = true,
            to       = to,
            text     = text,
            From     = self:GetArmyIndex(),
            location = location,
        }
        msg.Id = tostring(msg)

        ChatUtils.RelayChatMessage(msg)
    end,
}
