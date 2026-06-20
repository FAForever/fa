
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
---@class AIChatLocation
---@field Position? Vector         # world-space focus point
---@field Area?     Rectangle      # world-space rectangle to frame

---@class AIChatBrainComponent
AIChatBrainComponent = ClassSimple {

    --- Broadcasts a message to every connected UI as an "all" chat line.
    ---@param self AIChatBrainComponent
    ---@param text string
    ---@param args? any[]                   # optional `string.format` arguments; UI applies `LOCF(text, unpack(args))` on receive
    ---@param location? AIChatLocation
    SendChatToAll = function(self, text, args, location)
        self:SendChatTo('all', text, args, location)
    end,

    --- Broadcasts a message to the AI's allies. `Sync.ChatMessages` reaches
    --- every UI, so the non-ally filter is applied client-side on display.
    ---@param self AIChatBrainComponent
    ---@param text string
    ---@param args? any[]
    ---@param location? AIChatLocation
    SendChatToAllies = function(self, text, args, location)
        self:SendChatTo('allies', text, args, location)
    end,

    --- Whispers a message to a specific army. No ally constraint — the AI is
    --- trusted sim code and may legitimately taunt an enemy or message a
    --- neutral party.
    ---@param self AIChatBrainComponent
    ---@param army integer
    ---@param text string
    ---@param args? any[]
    ---@param location? AIChatLocation
    SendChatToPlayer = function(self, army, text, args, location)
        self:SendChatTo(army, text, args, location)
    end,

    --- Addresses a message back at this brain's own army. Useful for
    --- debug-style output, campaign hints, and sim-event announcements
    --- that should only reach the army the event happened to (resource
    --- gifts received, ACU under attack, etc.) — `IsLocalRecipient`
    --- ensures only that army's UI renders the line.
    ---@param self AIChatBrainComponent | AIBrain
    ---@param text string
    ---@param args? any[]
    ---@param location? AIChatLocation
    SendChatToSelf = function(self, text, args, location)
        self:SendChatTo(self:GetArmyIndex(), text, args, location)
    end,

    --- Shared implementation: builds the message, stamps it with the
    --- brain's army index and a dedupe id, and hands it to
    --- `ChatUtils.RelayChatMessage` for sim-side recipient filtering.
    --- The id is the message table's address — near-unique, survives
    --- serialisation as a plain string, and keeps the UI dedupe from
    --- double-posting if the same message arrives more than once (see
    --- `ChatController.OnSyncChatMessages`).
    ---
    --- `args`, if provided, rides on the message as `msg.Args` and is
    --- consumed by the UI's receive path: `LOCF(msg.text, unpack(msg.Args))`
    --- runs once per recipient against their own locale, so callers can
    --- pass a `<LOC ...>` format-string template plus raw values (army
    --- nicknames, resource amounts, …) instead of pre-formatting and
    --- losing localisation.
    ---
    --- `location`, if provided, rides as `msg.location` and is surfaced to
    --- the UI as `entry.Location` — the click handler in `ChatInterface`
    --- translates it to a `MoveTo`/`MoveToRegion` call at click time, so
    --- there is no need to synthesise a camera snapshot sim-side.
    ---@param self AIChatBrainComponent | AIBrain
    ---@param to AIBrainChatRecipient
    ---@param text string
    ---@param args? any[]
    ---@param location? AIChatLocation
    SendChatTo = function(self, to, text, args, location)
        if type(text) ~= 'string' or text == '' then return end

        local msg = {
            Chat     = true,
            to       = to,
            text     = text,
            Args     = args,
            From     = self:GetArmyIndex(),
            location = location,
        }
        msg.Id = tostring(msg)

        ChatUtils.RelayChatMessage(msg)
    end,
}
