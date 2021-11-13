-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- This is the user-specific top-level lua initialization file. It is run at initialization time
-- to set up all lua state for the user layer.

-- Init our language from prefs. This applies to both front-end and session init; for
-- the Sim init, the engine sets __language for us.
local ipairs = ipairs
local stringUpper = string.upper
local mathMax = math.max
local mathCeil = math.ceil
local DiskFindFiles = DiskFindFiles
local CreatePrefetchSet = CreatePrefetchSet
local stringGsub = string.gsub
local mathMin = math.min
local next = next

__language = GetPreference('options_overrides.language', '')
-- Build language select options
__installedlanguages = DiskFindFiles("/loc/", '*strings_db.lua')
for index, language in __installedlanguages do
    language =  stringUpper(stringGsub(language, ".*/(.*)/.*","%1"))
    __installedlanguages[index] = {text = language, key = language}
end


-- Do global init
doscript '/lua/globalInit.lua'

-- Do we have an custom language set inside user-options ?
local selectedlanguage = import('/lua/user/prefs.lua').GetFromCurrentProfile('options').selectedlanguage
if selectedlanguage ~= nil then
    __language = selectedlanguage
    SetPreference('options_overrides.language', __language)
    doscript '/lua/system/Localization.lua'
end

local AvgFPS = 10
WaitFrames = coroutine.yield

function WaitSeconds(n)
    local start = CurrentTime()
    local elapsed_frames = 0
    local elapsed_time = 0
    local wait_frames

    repeat
        wait_frames = mathCeil(mathMax(1, AvgFPS*0.1, n * AvgFPS))
        WaitFrames(wait_frames)
        elapsed_frames = elapsed_frames + wait_frames
        elapsed_time = CurrentTime() - start
    until elapsed_time >= n

    if elapsed_time >= 3 then
        AvgFPS = mathMax(10, mathMin(200, mathCeil(elapsed_frames / elapsed_time)))
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
