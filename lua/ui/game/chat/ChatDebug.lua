
-------------------------------------------------------------------------------
-- Helpers wired to the `debug_chat_*` hotkeys in
-- `/lua/keymap/debugKeyActions.lua`. Each function exercises a distinct
-- chat path so the rendering / scrolling / camera / recipient flows can be
-- inspected without needing a second client to actually send messages.

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatController = import("/lua/ui/game/chat/ChatController.lua")

--- A sample paragraph long enough to force the chat line wrapper to span
--- multiple rows at every supported font size.
local LongText =
    "The quick brown fox jumps over the lazy dog and then doubles back, " ..
    "dodges a passing T2 mobile artillery shell, ramps off a discarded " ..
    "engineer drone, and lands neatly on the scoreboard with a triumphant " ..
    "bark — at which point the dog wakes up and demands to know who " ..
    "authorised the construction of the ramp in the first place."

--- Synthesises a chat entry stamped with the local focus army's metadata so
--- the rendering colour and faction icon match a real outgoing message. The
--- entry carries a fresh `Id` so the dedupe in `OnSyncChatMessages` doesn't
--- swallow it later.
---@param overrides table   # fields merged on top of the synth defaults
---@return UIChatEntry
local function SynthEntry(overrides)
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

--- Toggles the chat window. Thin wrapper so the hotkey action string can
--- live alongside the rest of the chat-debug helpers.
function ToggleWindow()
    import("/lua/ui/game/chat/ChatInterface.lua").Toggle()
end

--- Toggles the chat config dialog.
function ToggleConfig()
    import("/lua/ui/game/chat/config/ChatConfigInterface.lua").Toggle()
end

-------------------------------------------------------------------------------
-- Synthetic message injection
-------------------------------------------------------------------------------

--- Appends a local-only system line. Exercises
--- `ChatController.AppendLocalSystemMessage` and the system-style colour.
function AppendSystemMessage()
    ChatController.AppendLocalSystemMessage(
        '[debug] system message at ' .. tostring(GetSystemTimeSeconds())
    )
end

--- Appends a single short synthetic chat entry. Exercises the basic
--- model→view path and the auto-scroll-to-bottom on history change.
function AppendShortMessage()
    ChatController.AppendEntry(SynthEntry({}))
end

--- Appends a synthetic entry whose body is long enough to wrap onto several
--- rows at every supported font size. Exercises `ChatLinesInterface.WrapEntry`
--- and the continuation-row layout.
function AppendLongMessage()
    ChatController.AppendEntry(SynthEntry({ Text = LongText }))
end

--- Appends ten short entries in a single batch. Exercises pool sizing
--- (the visible window grows past the line cap), virtual-size accounting,
--- and the snap-to-bottom behaviour on rapid arrivals.
function AppendBurst()
    for i = 1, 10 do
        ChatController.AppendEntry(SynthEntry({
            Text = string.format('[debug] burst %d / 10', i),
        }))
    end
end

--- Appends an entry with a `Location` hint pointing at the current world
--- camera focus. Exercises the camera-icon toggle on the row and the
--- `Camera:MoveTo` jump on click. The point is captured at hotkey time, so
--- pressing the key, panning the camera, and clicking the icon should
--- bounce the camera back to the original spot.
function AppendCameraMessage()
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

--- Forces the current send target to "all". Exercises the recipient-label
--- LazyVar binding in the edit row.
function SetRecipientAll()
    ChatController.SetRecipient(ChatModel.RecipientAll)
end

--- Forces the current send target to "allies".
function SetRecipientAllies()
    ChatController.SetRecipient(ChatModel.RecipientAllies)
end

-------------------------------------------------------------------------------
-- History reset
-------------------------------------------------------------------------------

--- Wipes the history log. Exercises the empty-pool branch in
--- `ChatLinesInterface.CalcVisible` and the model-side dirty propagation.
function ClearHistory()
    ChatModel.GetSingleton().History:Set({})
end

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
