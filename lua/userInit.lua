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
    language =  string.upper(string.gsub(language, ".*/(.*)/.*","%1"))
    __installedlanguages[index] = {text = language, key = language}
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

function WaitSeconds(n)
    local start = CurrentTime()
    local elapsed_frames = 0
    local elapsed_time = 0
    local wait_frames

    repeat
        wait_frames = math.ceil(math.max(1, AvgFPS*0.1, n * AvgFPS))
        WaitFrames(wait_frames)
        elapsed_frames = elapsed_frames + wait_frames
        elapsed_time = CurrentTime() - start
    until elapsed_time >= n

    if elapsed_time >= 3 then
        AvgFPS = math.max(10, math.min(200, math.ceil(elapsed_frames / elapsed_time)))
    end
end


-- a table designed to allow communication from different user states to the front end lua state
FrontEndData = {}

-- Prefetch user side data
Prefetcher = CreatePrefetchSet()

local FileCache =  {}
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
            data = {text = textData, size = 14, color = 'ffffffff', duration = 5, location = 'center'}
        end
        import("/lua/ui/game/textdisplay.lua").PrintToScreen(data)
    end
end

local replayID = import("/lua/ui/uiutil.lua").GetReplayId()
if replayID then
    LOG("REPLAY ID: " .. replayID)
end

do
    local oldConExecute = ConExecute

    ---@param command string
    _G.ConExecute = function(command)
        local lower = string.lower(command)

        -- do not allow network changes by UI mods
        if string.find(lower, 'net_') then
            return
        end

        oldConExecute(command)
    end

    local oldConExecuteSave = ConExecuteSave

    ---@param command string
    _G.ConExecuteSave = function(command)
        local lower = string.lower(command)

        -- do not allow network changes by UI mods
        if string.find(lower, 'net_') then
            return
        end

        oldConExecuteSave(command)
    end
end
