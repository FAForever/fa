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

--- Waits the given number of ticks. Always waits at least four frames
---@param ticks any
function WaitTicks(ticks)
    local start = GameTick()
    repeat
        WaitFrames(4)
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
    -- upvalues for security reasons
    local lower = string.lower
    local find = string.find

    local oldConExecute = ConExecute

    ---@param command string
    _G.ConExecute = function(command)
        local lower = lower(command)

        -- do not allow network changes
        if find(lower, 'net_') then
            return
        end

        oldConExecute(command)
    end

    local oldConExecuteSave = ConExecuteSave

    ---@param command string
    _G.ConExecuteSave = function(command)
        local lower = lower(command)

        -- do not allow network changes
        if find(lower, 'net_') then
            return
        end

        oldConExecuteSave(command)
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
    local OldOpenURL = _G.OpenURL

    --- Opens a URL after the user confirms the link
    ---@param url string
    _G.OpenURL = function(url, dialogParent)
        local UIUtil = import("/lua/ui/uiutil.lua")

        if not dialogParent then dialogParent = GetFrame(0) end
        UIUtil.QuickDialog(
            dialogParent,
            string.format("You're about to open a browser to:\r\n\r\n%s", url),
            'Open browser',
            function() OldOpenURL(url) end,
            'Cancel'
        )
    end
end

do

    ---@type { [1]: UserUnit }
    local UnitsCache = { }

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

    ---@param unit UserUnit[]
    ---@param command UserUnitBlueprintCommand
    ---@param blueprintid UnitId
    ---@param count number
    ---@param clear boolean? defaults to false
    _G.IssueBlueprintCommandToUnit = function(unit, command, blueprintid, count, clear)
        UnitsCache[1] = unit
        IssueBlueprintCommandToUnits(UnitsCache, command, blueprintid, count, clear)
    end
end
