
-------------------------------------------------------------------------------
-- Helpers for the `debug_chat_*` hotkeys in
-- `/lua/keymap/debugKeyActions.lua`.

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatController = import("/lua/ui/game/chat/ChatController.lua")

--- Long enough to force wrapping at every supported font size.
local LongText =
    "The quick brown fox jumps over the lazy dog and then doubles back, " ..
    "dodges a passing T2 mobile artillery shell, ramps off a discarded " ..
    "engineer drone, and lands neatly on the scoreboard with a triumphant " ..
    "bark, at which point the dog wakes up and demands to know who " ..
    "authorised the construction of the ramp in the first place."

--- Builds a synthetic `UIChatEntry` for debug injection, optionally
--- overriding fields from the defaults.
---@param overrides table   # fields merged on top of the synth defaults
---@return UIChatEntry
local function SynthEntry(overrides)
    -- Stamps the entry with the local focus army's metadata so the colour
    -- and faction icon match a real outgoing message. Fresh `Id` so the
    -- `OnSyncChatMessages` dedupe doesn't swallow it later.
    local focus = GetFocusArmy()
    local armies = GetArmiesTable().armiesTable
    local data = (focus and focus > 0) and armies[focus] or {}
    local entry = {
        Name      = (data.nickname or 'Debug') .. ' to all:',
        Text      = '[debug] sample message at ' .. tostring(GetSystemTimeSeconds()),
        Color     = data.color or 'ffffffff',
        ArmyID    = focus or 1,
        Faction   = (data.faction or 4) + 1,
        Recipient = ChatModel.RecipientAll,
    }
    for k, v in overrides or {} do
        entry[k] = v
    end
    entry.Id = entry.Id or tostring(entry)
    return entry
end

-------------------------------------------------------------------------------
-- Window & dialog toggles
-------------------------------------------------------------------------------

--- Debug hotkey: flips the chat window's visibility.
function ToggleWindow()
    import("/lua/ui/game/chat/ChatInterface.lua").Toggle()
end

--- Debug hotkey: flips the chat options dialog's visibility.
function ToggleConfig()
    import("/lua/ui/game/chat/config/ChatConfigInterface.lua").Toggle()
end

-------------------------------------------------------------------------------
-- Synthetic message injection
-------------------------------------------------------------------------------

--- Debug hotkey: appends a synthetic system message.
function AppendSystemMessage()
    ChatController.AppendLocalSystemMessage(
        '[debug] system message at ' .. tostring(GetSystemTimeSeconds())
    )
end

--- Debug hotkey: appends a one-line synthetic message from the local player.
function AppendShortMessage()
    ChatController.AppendEntry(SynthEntry({}))
end

--- Appends a long synthetic message that exercises the continuation-row layout.
function AppendLongMessage()
    -- Body wraps onto several rows at every supported font size.
    ChatController.AppendEntry(SynthEntry({ Text = LongText }))
end

--- Appends ten synthetic entries in one batch.
function AppendBurst()
    -- Exercises pool sizing past the line cap and snap-to-bottom on
    -- rapid arrivals.
    for i = 1, 10 do
        ChatController.AppendEntry(SynthEntry({
            Text = string.format('[debug] burst %d / 10', i),
        }))
    end
end

--- Appends a synthetic message tagged with the current camera focus.
function AppendCameraMessage()
    -- Captures the camera focus at hotkey time so panning and clicking
    -- the camera icon should bounce back to the original spot.
    local cam = GetCamera('WorldCamera')
    local settings = cam:SaveSettings()
    ChatController.AppendEntry(SynthEntry({
        Text     = '[debug] click the camera icon to jump back here',
        Location = { Position = settings.Focus },
    }))
end

-------------------------------------------------------------------------------
-- Recipient state
-------------------------------------------------------------------------------

--- Debug hotkey: forces the recipient back to "All".
function SetRecipientAll()
    ChatController.SetRecipient(ChatModel.RecipientAll)
end

--- Debug hotkey: forces the recipient back to "Allies".
function SetRecipientAllies()
    ChatController.SetRecipient(ChatModel.RecipientAllies)
end

-------------------------------------------------------------------------------
-- History reset
-------------------------------------------------------------------------------

--- Debug hotkey: wipes the entire history log.
function ClearHistory()
    ChatModel.GetSingleton().History:Set({})
end

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: re-imports this module on save.
function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
