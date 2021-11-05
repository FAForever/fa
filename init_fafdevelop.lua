
-- START OF COPY --

-- imports fa_path to determine where it is installed
dofile(InitFileDir .. '/../fa_path.lua')

-- upvalued performance
local dofile = dofile

local StringFind = string.find 
local StringGsub = string.gsub
local StringSub = string.sub
local StringLower = string.lower

local IoDir = io.dir

local TableInsert = table.insert

-- read by the engine to determine where to find assets
path = {}

-- read by the engine to determine hook folders
hook = {
    '/schook'
}

-- read by the engine to determine supported protocols
protocols = {
    'http',
    'https',
    'mailto',
    'ventrilo',
    'teamspeak',
    'daap',
    'im',
}

-- upvalued for performance
local UpvaluedPath = path 
local UpvaluedPathNext = 1

-- defined to read scenario files
STRING = function(s) return s end 

-- mods that have been integrated, based on folder name 
local integratedMods = { 
    "nvidia fix"
}

-- old mods and other things we do not appreciate
local assetsBlocked = {
    "00_BigMap.scd",
    "00_BigMapLEM.scd",
    "fa-ladder.scd",
    "fa_ladder.scd",
    "faladder.scd",
    "powerlobby.scd",
    "02_sorian_ai_pack.scd",
    "03_lobbyenhancement.scd",
    "randmap.scd",
    "_Eject.scd",
    "Eject.scd",
    "gaz_ui",
    "lobby.nxt",
    "faforever.nxt"
}

-- typically FA / FAF related packages that we do appreciate
local assetsAllowed = {
    "effects.nx2",
    "env.nx2",
    "etc.nx2",
    "loc.nx2",
    "lua.nx2",
    "meshes.nx2",
    "mods.nx2",
    "projectiles.nx2",
    "schook.nx2",
    "textures.nx2",
    "units.nx2",
    "murderparty.nxt",
    "labwars.nxt",
    "units.scd",
    "textures.scd",
    "skins.scd",
    "schook.scd",
    "props.scd",
    "projectiles.scd",
    "objects.scd",
    "moholua.scd",
    "mohodata.scd",
    "mods.scd",
    "meshes.scd",
    "lua.scd",
    "loc_us.scd",
    "loc_es.scd",
    "loc_fr.scd",
    "loc_it.scd",
    "loc_de.scd",
    "loc_ru.scd",
    "env.scd",
    "effects.scd",
    "editor.scd",
    "ambience.scd",
    "advanced strategic icons.nxt",
    "lobbymanager_v105.scd",
    "texturepack.nxt",
    "sc_music.scd"
}

--- Mounts a directory or scd / zip file.
-- @param dir The absolute path to the directory
-- @param mountpoint The path to use in the game (e.g., /maps/...)
local function MountDirectory(dir, mountpoint)
    UpvaluedPath[UpvaluedPathNext] = { 
        dir = dir, 
        mountpoint = mountpoint 
    }

    UpvaluedPathNext = UpvaluedPathNext + 1
end

--- Mounts all content in a directory, including scd and zip files.
-- @param dir The absolute path to the directory
-- @param mountpoint The path to use in the game (e.g., /maps/...)
local function MountContent(dir, mountpoint)
    for _,entry in IoDir(dir .. '/*') do
        if entry != '.' and entry != '..' then
            local mp = StringLower(entry)
            local safe = true
            for i, black in assetsBlocked do
                safe = safe and (StringFind(mp, black, 1) == nil)
            end
            if safe then
                mp = StringGsub(mp, '[.]scd$', '')
                mp = StringGsub(mp, '[.]zip$', '')
                MountDirectory(dir .. '/' .. entry, mountpoint .. '/' .. mp)
            else
                LOG('not safe ' .. entry)
            end
        end
    end
end

local function MountAllowedContent(dir, glob, mountpoint)
    local sorted = {}
    for _,entry in IoDir(dir .. glob) do
        if entry != '.' and entry != '..' then
            local mp = StringLower(entry)
            local notsafe = true
            for i, white in assetsAllowed do
                notsafe = notsafe and (StringFind(mp, white, 1) == nil)
            end
            if notsafe then
                LOG('not safe ' .. dir .. entry)
            else
                table.insert(sorted, dir .. entry)
            end
        end
    end
    table.sort(sorted)
    table.foreach(sorted, function(k,v) MountDirectory(v,'/') end)
end

function MountNotBlockedContent(dir, glob, mountpoint)
    local sorted = {}
    for _,entry in IoDir(dir .. glob) do
        if entry != '.' and entry != '..' then
            local mp = StringLower(entry)
            local safe = true
            for i, black in assetsBlocked do
                safe = safe and (StringFind(mp, black, 1) == nil)
            end
            if safe then
                table.insert(sorted, dir .. entry)
            else
                LOG('not safe ' .. dir .. entry)
            end
        end
    end
    table.sort(sorted)
    table.foreach(sorted, function(k,v) MountDirectory(v,'/') end)
end

--- Keep track of what maps are loaded to prevent collisions
local loadedMaps = { }

--- A helper function that loads in additional content for maps.
-- @param mountpoint The root folder to look for content in.
function MountMapContent(dir)
    -- look for all directories / maps at the mount point
    for _, map in IoDir(dir .. '//**') do

        -- prevent capital letters messing things up
        map = StringLower(map)

        -- do not do anything with the current / previous directory
        if map == '.' or map == '..' then
            continue 
        end

        -- do not load scds / zips as maps
        if StringFind(map, ".zip") or StringFind(map, ".scd")  or StringFind(map, ".rar") then
            continue 
        end

        -- check if the folder contains an _scenario.lua
        local scenarioFile = false 
        for _, file in IoDir(dir .. "/" .. map .. "/*") do 
            if StringSub(file, -13) == '_scenario.lua' then 
                scenarioFile = file 
            end
        end

        -- check if it has a scenario file
        if not scenarioFile then 
            _ALERT("Map doesn't have a scenario file: " .. dir .. "/" .. map)
            continue 
        end

        -- tried to load in the scenario file, but in all cases it pollutes the global scope and we can't have that
        -- https://stackoverflow.com/questions/9540732/loadfile-without-polluting-global-environment

        -- do not load maps twice
        if loadedMaps[map] then 
            LOG("Prevented loading a map twice: " .. map)
            continue
        end

        -- consider this one loaded
        loadedMaps[map] = true 

        -- mount the map
        MountDirectory(dir .. "/" .. map, "/maps/" .. map)

        -- look at each directory inside this map
        for _, folder in IoDir(dir..'/'..map..'/**') do
            -- if we found a directory named 'movies' then we mount its content
            if folder == 'movies' then
                LOG('Found map movies in: '..map)
                MountDirectory(dir..map..'/movies', '/movies')
            end

            -- if we found a directory named 'sounds' then we mount its content
            if folder == 'sounds' then
                LOG('Found map sounds in: '..map)
                MountDirectory(dir..map..'/sounds', '/sounds')
            end
        end
    end
end

--- keep track of what mods are loaded to prevent collisions
local loadedMods = { }

--- A helper function that loads in additional content for mods.
-- @param mountpoint The root folder to look for content in.
function MountModContent(dir)
    -- get all directories / mods at the mount point
    for _, mod in io.dir(dir..'/*.*') do
        
        -- prevent capital letters messing things up
        mod = StringLower(mod)

        -- do not do anything with the current / previous directory
        if mod == '.' or mod == '..' then
            continue 
        end

        LOG(mod)

        -- do not load integrated mods
        for k, integrated in integratedMods do
            if StringLower(integrated) == mod then 
                _ALERT("Blocked mod that is integrated: " .. mod )
                continue 
            end
        end 

        -- do not load scds / zips as mods
        if StringFind(mod, ".zip") or StringFind(mod, ".scd") or StringFind(mod, ".rar") then
            continue 
        end

        -- check if the folder contains a _info.lua
        local infoFile = false 
        for _, file in IoDir(dir .. "/" .. mod .. "/*") do 
            if StringSub(file, -9) == '_info.lua' then 
                infoFile = file 
            end
        end

        -- check if it has a scenario file
        if not infoFile then 
            _ALERT("Mod doesn't have an info file: " .. dir .. "/" .. mod)
            continue 
        end

        -- do not load mods twice
        if loadedMods[mod] then 
            LOG("Prevented loading a mod twice: " .. mod)
            continue
        end

        -- consider this one loaded
        loadedMods[mod] = true 

        -- mount the mod
        MountDirectory(dir .. "/" .. mod, "/mods/" .. mod)

        -- look at each directory inside this mod
        for _, folder in IoDir(dir .. '/' .. mod .. '/*.*') do
            
            -- if we found a directory named 'sounds' then we mount its content
            if folder == 'sounds' then
                LOG('Found mod sounds in: ' .. mod)
                MountDirectory(dir .. '/' .. mod .. '/sounds', '/sounds')
            end

            -- if we found a directory named 'custom-strategic-icons' then we mount its content
            if folder == 'custom-strategic-icons' then
                local mountLocation = '/textures/ui/common/game/strategicicons/' .. StringLower(mod)
                LOG('Found mod icons in ' .. mod .. ', mounted at: ' .. mountLocation)
                MountDirectory(dir .. '/' .. mod .. '/custom-strategic-icons', mountLocation) 
            end

            -- if we found a file named 'custom-strategic-icons.scd' then we mount its content - good for performance when the number of icons is high
            if folder == 'custom-strategic-icons.scd' then 
                local mountLocation = '/textures/ui/common/game/strategicicons/' .. StringLower(mod)
                LOG('Found mod icon package in ' .. mod .. ', mounted at: ' .. mountLocation)
                MountDirectory(dir .. '/' .. mod .. '/custom-strategic-icons.scd', mountLocation) 
            end
        end
    end
end

--- A helper function to load in all maps and mods on a given location.
-- @param path The root folder for the maps and mods
local function LoadVaultContent(path)
    -- load in additional things, like sounds and 
	MountMapContent(path .. '/maps/', '**', '/maps')
	MountModContent(path .. '/mods')
end

-- END OF COPY --

-- load maps / mods from custom vault location, if set by client
if custom_vault_path then
	LOG('Loading custom vault path' .. custom_vault_path)
	LoadVaultContent(custom_vault_path)
else
    LOG("No custom vault path defined.")
end

-- load maps / mods from backup vault location location
LoadVaultContent(InitFileDir .. '/../user/My Games/Gas Powered Games/Supreme Commander Forged Alliance')

-- load maps / mods from my documents vault location
LoadVaultContent(SHGetFolderPath('PERSONAL') .. 'My Games/Gas Powered Games/Supreme Commander Forged Alliance')

-- load in any .nxt that matches the whitelist / blacklist in FAF gamedata
MountAllowedContent(InitFileDir .. '/../gamedata/', '*.nxt', '/')
MountAllowedContent(InitFileDir .. '/../gamedata/', '*.nx5', '/')

-- load in any .nxt that matches the whitelist / blacklist in FA gamedata
MountAllowedContent(fa_path .. '/gamedata/', '*.scd', '/')

-- get direct access to preferences file, letting us have much more control over its content. This also includes cache and similar
MountDirectory(SHGetFolderPath('LOCAL_APPDATA') .. 'Gas Powered Games/Supreme Commander Forged Alliance', '/preferences')

-- Load in all the data of the steam installation (movies, maps, sound folders)
MountDirectory(fa_path, '/')