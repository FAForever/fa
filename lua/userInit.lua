---@declare-global
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- This is the user-specific top-level lua initialization file. It is run at initialization time
-- to set up all lua state for the user layer.

-- Init our language from prefs. This applies to both front-end and session init; for
-- the Sim init, the engine sets __language for us.
__language = GetPreference('options_overrides.language', '')
-- Build language select options
__installedlanguages = DiskFindFiles("/loc/", '*strings_db.lua')
for index, language in __installedlanguages do
    language = string.upper(string.gsub(language, ".*/(.*)/.*", "%1"))
    __installedlanguages[index] = { text = language, key = language }
end


-- # Global (and shared) init
doscript '/lua/globalInit.lua'
doscript '/lua/ui/globals/GpgNetSend.lua'
doscript '/lua/ui/globals/InternalSaveGame.lua'

-- Do we have an custom language set inside user-options ?
local selectedlanguage = import("/lua/user/prefs.lua").GetFromCurrentProfile('options').selectedlanguage
if selectedlanguage ~= nil then
    __language = selectedlanguage
    SetPreference('options_overrides.language', __language)
    doscript '/lua/system/Localization.lua'
end

-- Do we have SC_LuaDebugger window positions in the config ?
if not GetPreference("Windows.Debug") then
    -- no, we set them to some sane defaults if they are missing. Othervise Debugger window is messed up
    SetPreference('Windows.Debug', {
        x = 10,
        y = 10,
        height = 550,
        width = 900,
        Sash = { horizontal = 212, vertical = 330 },
        Watch = {
            Stack = { block = 154, source = 212, line = 72 },
            Global = { value = 212, type = 215, name = 220 },
            Local = { value = 212, type = 134, name = 217 }
        }
    })
end

local AvgFPS = 10
WaitFrames = coroutine.yield

--- Waits the given number of seconds. Always waits at least one frame
function WaitSeconds(n)
    local start = CurrentTime()
    local elapsed_frames = 0
    local elapsed_time = 0
    local wait_frames

    repeat
        wait_frames = math.ceil(math.max(1, AvgFPS * 0.1, n * AvgFPS))
        WaitFrames(wait_frames)
        elapsed_frames = elapsed_frames + wait_frames
        elapsed_time = CurrentTime() - start
    until elapsed_time >= n

    if elapsed_time >= 3 then
        AvgFPS = math.max(10, math.min(200, math.ceil(elapsed_frames / elapsed_time)))
    end
end

--- Waits the given number of ticks. Always waits at least two frames
---@param ticks any
function WaitTicks(ticks)
    -- local scope for performance
    local GameTick = GameTick
    local WaitFrames = WaitFrames

    local start = GameTick()
    repeat
        WaitFrames(2)
    until (start + ticks) <= GameTick()
end

-- a table designed to allow communication from different user states to the front end lua state
FrontEndData = {}

-- Prefetch user side data
Prefetcher = CreatePrefetchSet()

local FileCache = {}
local oldDiskGetFileInfo = DiskGetFileInfo
function DiskGetFileInfo(file)
    if FileCache[file] == nil then
        FileCache[file] = oldDiskGetFileInfo(file) or false
    end
    return FileCache[file]
end

local oldEntityCategoryFilterOut = EntityCategoryFilterOut
function EntityCategoryFilterOut(categories, units)
    return oldEntityCategoryFilterOut(categories, units or {})
end

function PrintText(textData)
    if textData then
        local data = textData
        if type(textData) == 'string' then
            data = { text = textData, size = 14, color = 'ffffffff', duration = 5, location = 'center' }
        end
        import("/lua/ui/game/textdisplay.lua").PrintToScreen(data)
    end
end

local replayID = import("/lua/ui/uiutil.lua").GetReplayId()
if replayID then
    LOG("REPLAY ID: " .. replayID)
end

do

    -- Moderation functionality
    -- The following hooks and/or overloads exist to assist moderators in evaluation faul play

    local invalidConsoleCommands = {
        "net_MinResendDelay",
        "net_SendDelay",
        "net_ResendPingMultiplier",
        "net_ResendDelayBias",
        "net_CompressionMethod",
        "net_MaxSendRate",
        "net_MaxResendDelay",
        "net_MaxBacklog",
        "net_AckDelay",
        "net_Lag",
    }

    -- upvalue scope for security reasons
    local tonumber = tonumber
    local StringLower = string.lower
    local StringFind = string.find
    local StringMatch = string.match

    local TableGetn = table.getn

    local WaitSeconds = WaitSeconds
    local GetFocusArmy = GetFocusArmy
    local SessionIsReplay = SessionIsReplay
    local GetFocusArmy = GetFocusArmy
    local SessionIsReplay = SessionIsReplay
    local SessionGetScenarioInfo = SessionGetScenarioInfo

    --- We delay the event to make sure we're not trying to send events when a player is trying to leave
    ---@param message string
    local SendModeratorEventThread = function(message)
        local currentFocusArmy = GetFocusArmy()

        if not SessionIsGameOver() then
            SimCallback(
                {
                    Func = "ModeratorEvent",
                    Args = {
                        From = currentFocusArmy,
                        Message = message,
                    },
                }
            )
        end
    end

    local oldSetFocusArmy = SetFocusArmy

    ---@param number number
    _G.SetFocusArmy = function(number)
        -- do a basic check
        local isCheatsEnabled = SessionGetScenarioInfo().Options.CheatsEnabled == "true"
        if not (SessionIsReplay() or isCheatsEnabled) then
            local currentFocusArmy = GetFocusArmy()
            local proposedFocusArmy = number

            ForkThread(SendModeratorEventThread,
                string.format("Is changing focus army from %d to %d via SetFocusArmy!",
                    currentFocusArmy, proposedFocusArmy))
        end

        oldSetFocusArmy(number)
    end

    local oldConExecute = ConExecute

    ---@param command string
    _G.ConExecute = function(command)
        local commandNoCaps = StringLower(command)

        -- do not allow network changes
        for i, command in ipairs(invalidConsoleCommands) do
            if StringFind(commandNoCaps, StringLower(command)) then
                return
            end
        end

        -- inform allies about self-destructed units
        if StringFind(commandNoCaps, 'killselectedunits') then
            local selectedUnits = GetSelectedUnits()
            ForkThread(SendModeratorEventThread, string.format('Self-destructed %d units', TableGetn(selectedUnits)))
        end

        -- do a basic check
        if StringFind(commandNoCaps, 'setfocusarmy') then
            if not SessionIsReplay() then
                local currentFocusArmy = GetFocusArmy()
                local proposedFocusArmy = tonumber(StringMatch(command, '%d+'))
                if StringFind(command, '-') then
                    proposedFocusArmy = proposedFocusArmy * -1
                else
                    proposedFocusArmy = proposedFocusArmy + 1
                end

                ForkThread(SendModeratorEventThread,
                    string.format("Is changing focus army from %d to %d via ConExecute!", currentFocusArmy,
                        proposedFocusArmy))
            end
        end

        oldConExecute(command)
    end

    local oldConExecuteSave = ConExecuteSave

    ---@param command string
    _G.ConExecuteSave = function(command)
        local commandNoCaps = StringLower(command)

        -- do not allow network changes
        for i, command in ipairs(invalidConsoleCommands) do
            if StringFind(commandNoCaps, StringLower(command)) then
                print("Invalid console command")
                return
            end
        end

        -- inform allies about self-destructed units
        if StringFind(commandNoCaps, 'killselectedunits') then
            local selectedUnits = GetSelectedUnits()

            -- try to inform moderators
            ForkThread(SendModeratorEventThread, string.format('Self-destructed %d units', TableGetn(selectedUnits)))
        end

        -- do a basic check
        if StringFind(commandNoCaps, 'setfocusarmy') then
            if not (SessionIsReplay()) then
                local currentFocusArmy = GetFocusArmy()
                local proposedFocusArmy = tonumber(StringMatch(command, '%d+'))
                if StringFind(command, '-') then
                    proposedFocusArmy = proposedFocusArmy * -1
                else
                    proposedFocusArmy = proposedFocusArmy + 1
                end

                -- try to inform moderators
                ForkThread(SendModeratorEventThread,
                    string.format("Is changing focus army from %d to %d via ConExecuteSave!",
                        currentFocusArmy, proposedFocusArmy))
            end
        end

        oldConExecuteSave(command)
    end

    local oldSimCallback = SimCallback

    ---@param callback SimCallback
    ---@param addUnitSelection boolean
    _G.SimCallback = function(callback, addUnitSelection)
        -- inform allies about self-destructed units
        if callback.Func == 'ToggleSelfDestruct' then
            local selectedUnits = GetSelectedUnits()
            if selectedUnits then
                -- try to inform moderators
                ForkThread(SendModeratorEventThread, string.format('Self-destructed %d units', TableGetn(selectedUnits)))
            end

        end

        -- inform moderators about pings
        if callback.Func == 'SpawnPing' then
            if callback.Args.Marker then
                ForkThread(SendModeratorEventThread,
                    string.format("Created a marker with the text: '%s'", tostring(callback.Args.Name)))
            else
                ForkThread(SendModeratorEventThread,
                    string.format("Created a ping of type '%s'", tostring(callback.Args.Type)))
            end
        end

        oldSimCallback(callback, addUnitSelection or false)
    end
end

do
    local OldOpenURL = _G.OpenURL

    --- Opens a URL after the user confirms the link
    ---@param url string
    _G.OpenURL = function(url, dialogParent)
        local UIUtil = import("/lua/ui/uiutil.lua")

        if GetCurrentUIState() == 'game' then
            if not dialogParent then dialogParent = GetFrame(0) end
            UIUtil.QuickDialog(
                dialogParent,
                string.format("You're about to open a browser to:\r\n\r\n%s", url),
                'Open browser',
                function() OldOpenURL(url) end,
                'Cancel'
            )
        else
            OldOpenURL(url)
        end
    end

    --- Retrieves the terrain elevation, can be compared with the y coordinate of `GetMouseWorldPos` to determine if the mouse is above water
    ---@return number
    _G.GetMouseTerrainElevation = function()
        if __EngineStats and __EngineStats.Children then
            for _, a in __EngineStats.Children do
                if a.Name == 'Camera' then
                    for _, b in a.Children do
                        if b.Name == 'Cursor' then
                            for _, c in b.Children do
                                if c.Name == 'Elevation' then
                                    return c.Value
                                end
                            end
                            break
                        end
                    end
                end
            end
        end

        return 0
    end
end

do

    ---@type { [1]: UserUnit }
    local UnitsCache = {}

    ---@param unit UserUnit
    ---@param pause boolean
    _G.SetPausedOfUnit = function(unit, pause)
        UnitsCache[1] = unit
        return SetPaused(UnitsCache, pause)
    end

    ---@param unit UserUnit
    ---@return boolean
    _G.GetIsPausedOfUnit = function(unit)
        UnitsCache[1] = unit
        return GetIsPaused(UnitsCache)
    end

    ---@param unit UserUnit
    ---@return string[] orders
    ---@return CommandCap[] availableToggles
    ---@return EntityCategory buildableCategories
    _G.GetUnitCommandDataOfUnit = function(unit)
        UnitsCache[1] = unit
        return GetUnitCommandData(UnitsCache)
    end

    ---@param units UserUnit[]
    ---@param command UserUnitBlueprintCommand
    ---@param blueprintid UnitId
    ---@param count number
    ---@param clear boolean? defaults to false
    _G.IssueBlueprintCommandToUnits = function(units, command, blueprintid, count, clear)
        local gameMain = import("/lua/ui/game/gamemain.lua")
        local commandMode = import("/lua/ui/game/commandmode.lua")

        -- prevents losing command mode
        commandMode.CacheAndClearCommandMode()
        gameMain.SetIgnoreSelection(true)
        local oldSelection = GetSelectedUnits()
        SelectUnits(units)
        IssueBlueprintCommand(command, blueprintid, count, clear)
        SelectUnits(oldSelection)
        gameMain.SetIgnoreSelection(false)
        commandMode.RestoreCommandMode(true)
    end

    ---@param unit UserUnit
    ---@param command UserUnitBlueprintCommand
    ---@param blueprintid UnitId
    ---@param count number
    ---@param clear boolean? defaults to false
    _G.IssueBlueprintCommandToUnit = function(unit, command, blueprintid, count, clear)
        UnitsCache[1] = unit
        IssueBlueprintCommandToUnits(UnitsCache, command, blueprintid, count, clear)
    end

    --- Issue a command to a given unit
    ---@param unit UserUnit
    ---@param command UserUnitCommand # Will crash the game if not a valid command.
    ---@param luaParams? table | string | number | boolean # Will crash the game if the table contains non-serializable types.
    ---@param clear? boolean
    _G.IssueUnitCommandToUnit = function(unit, command, luaParams, clear)
        UnitsCache[1] = unit
        IssueUnitCommand(UnitsCache, command, luaParams, clear)
    end
end

do
    ---@alias UIBuildQueue UIBuildQueueItem[]

    ---@class UIBuildQueueItem
    ---@field count number
    ---@field id UnitId

    ---@type UserUnit | nil
    local buildQueueOfUnit = nil

    ---@type UIBuildQueue
    local buildQueue = {}

    local OldClearCurrentFactoryForQueueDisplay = _G.ClearCurrentFactoryForQueueDisplay
    local OldSetCurrentFactoryForQueueDisplay = _G.SetCurrentFactoryForQueueDisplay
    local OldDecreaseBuildCountInQueue = _G.DecreaseBuildCountInQueue
    local OldIncreaseBuildCountInQueue = _G.IncreaseBuildCountInQueue

    --- Clears the current build queue
    ---@see DecreaseBuildCountInQueue           # To decrease the build count in the queue
    ---@see IncreaseBuildCountInQueue           # To increase the build count in the queue
    ---@see SetCurrentFactoryForQueueDisplay    # To set the current queue
    ---@see GetCurrentFactoryForQueueDisplay    # To get the current queue
    ---@see ClearCurrentFactoryForQueueDisplay  # To clear the current queue
    _G.ClearCurrentFactoryForQueueDisplay = function()
        buildQueueOfUnit = nil
        buildQueue = {}
        OldClearCurrentFactoryForQueueDisplay()
    end

    --- Defines the current build queue
    ---@see DecreaseBuildCountInQueue           # To decrease the build count in the queue
    ---@see IncreaseBuildCountInQueue           # To increase the build count in the queue
    ---@see SetCurrentFactoryForQueueDisplay    # To set the current queue
    ---@see GetCurrentFactoryForQueueDisplay    # To get the current queue
    ---@see ClearCurrentFactoryForQueueDisplay  # To clear the current queue
    ---@param userUnit UserUnit
    ---@return UIBuildQueue
    _G.SetCurrentFactoryForQueueDisplay = function(userUnit)
        buildQueueOfUnit = userUnit
        buildQueue = OldSetCurrentFactoryForQueueDisplay(userUnit)
        return buildQueue
    end

    --- Retrieve the build queue without changing the global state
    ---@see DecreaseBuildCountInQueue           # To decrease the build count in the queue
    ---@see IncreaseBuildCountInQueue           # To increase the build count in the queue
    ---@see SetCurrentFactoryForQueueDisplay    # To set the current queue
    ---@see GetCurrentFactoryForQueueDisplay    # To get the current queue
    ---@see ClearCurrentFactoryForQueueDisplay  # To clear the current queue
    ---@param userUnit UserUnit
    ---@return UIBuildQueue
    _G.PeekCurrentFactoryForQueueDisplay = function(userUnit)
        if IsDestroyed(userUnit) then
            return {}
        end

        local oldBuildQueueOfUnit = buildQueueOfUnit
        local queue = SetCurrentFactoryForQueueDisplay(userUnit)

        if oldBuildQueueOfUnit then
            SetCurrentFactoryForQueueDisplay(oldBuildQueueOfUnit)
        else
            ClearCurrentFactoryForQueueDisplay()
        end

        return queue
    end

    --- Update the current command queue. Does not update the internal state of the engine - do not use directly!
    ---@see DecreaseBuildCountInQueue           # To decrease the build count in the queue
    ---@see IncreaseBuildCountInQueue           # To increase the build count in the queue
    ---@see SetCurrentFactoryForQueueDisplay    # To set the current queue
    ---@see GetCurrentFactoryForQueueDisplay    # To get the current queue
    ---@see ClearCurrentFactoryForQueueDisplay  # To clear the current queue
    ---@param queue UIBuildQueue
    _G.UpdateCurrentFactoryForQueueDisplay = function(queue)
        buildQueue = queue
    end

    --- Retrieves the current build queue
    ---@see DecreaseBuildCountInQueue           # To decrease the build count in the queue
    ---@see IncreaseBuildCountInQueue           # To increase the build count in the queue
    ---@see SetCurrentFactoryForQueueDisplay    # To set the current queue
    ---@see GetCurrentFactoryForQueueDisplay    # To get the current queue
    ---@see ClearCurrentFactoryForQueueDisplay  # To clear the current queue
    ---@return UIBuildQueue[]
    _G.GetCurrentFactoryForQueueDisplay = function()
        return buildQueue
    end

    --- Decrease the count at a given location of the current build queue
    ---@see DecreaseBuildCountInQueue           # To decrease the build count in the queue
    ---@see IncreaseBuildCountInQueue           # To increase the build count in the queue
    ---@see SetCurrentFactoryForQueueDisplay    # To set the current queue
    ---@see GetCurrentFactoryForQueueDisplay    # To get the current queue
    ---@see ClearCurrentFactoryForQueueDisplay  # To clear the current queue
    ---@param index number
    ---@param count number
    _G.DecreaseBuildCountInQueue = function(index, count)
        if not buildQueueOfUnit then
            WARN("Unable to decrease build queue count when no build queue is set")
            return
        end

        if table.empty(buildQueue) then
            WARN("Unable to decrease build queue is empty")
            return
        end

        if index < 1 then
            WARN("Unable to decrease build queue count when index is smaller than 1")
            return
        end

        if index > table.getn(buildQueue) then
            WARN("Unable to decrease build queue count when queue index is larger than the elements in the queue")
            return
        end

        return OldDecreaseBuildCountInQueue(index, count)
    end

    --- Increase the count at a given location of the current build queue
    ---@see DecreaseBuildCountInQueue           # To decrease the build count in the queue
    ---@see IncreaseBuildCountInQueue           # To increase the build count in the queue
    ---@see SetCurrentFactoryForQueueDisplay    # To set the current queue
    ---@see GetCurrentFactoryForQueueDisplay    # To get the current queue
    ---@see ClearCurrentFactoryForQueueDisplay  # To clear the current queue
    ---@param index number
    ---@param count number
    _G.IncreaseBuildCountInQueue = function(index, count)
        if not buildQueueOfUnit then
            WARN("Unable to increase build queue count when no build queue is set")
            return
        end

        if table.empty(buildQueue) then
            WARN("Unable to increase build queue is empty")
            return
        end

        if table.empty(buildQueue) then
            WARN("Unable to increase build queue count when no build queue is set")
            return
        end

        if index < 1 then
            WARN("Unable to increase build queue count when index is smaller than 1")
            return
        end

        if index > table.getn(buildQueue) then
            WARN("Unable to increase build queue count when queue index is larger than the elements in the queue")
            return
        end

        return OldIncreaseBuildCountInQueue(index, count)
    end
end
