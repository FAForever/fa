
-- performance
local stringFind = string.find 
local stringGsub = string.gsub 
local stringLower = string.lower
local ioDir = io.dir

-- imports fa_path to determine where it is installed
dofile(InitFileDir .. '\\..\\fa_path.lua')

-- read by the engine to determine where to find assets
path = {}

-- old mods and other things we do not appreciate
assetsBlocked = {
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
assetsAllowed = {
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
function mount_dir(dir, mountpoint)
    table.insert(path, { dir = dir, mountpoint = mountpoint })
end

--- Mounts all content in a directory, including scd and zip files.
-- @param dir The absolute path to the directory
-- @param mountpoint The path to use in the game (e.g., /maps/...)
function mount_contents(dir, mountpoint)
    LOG('checking ' .. dir)
    for _,entry in io.dir(dir .. '\\*') do
        if entry != '.' and entry != '..' then
            local mp = string.lower(entry)
            local safe = true
            for i, black in assetsBlocked do
                safe = safe and (string.find(mp, black, 1) == nil)
            end
            if safe then
                mp = string.gsub(mp, '[.]scd$', '')
                mp = string.gsub(mp, '[.]zip$', '')
                mount_dir(dir .. '\\' .. entry, mountpoint .. '/' .. mp)
            else
                LOG('not safe ' .. entry)
            end
        end
    end
end

function mount_dir_with_assetsAllowed(dir, glob, mountpoint)
    sorted = {}
    LOG('checking ' .. dir .. glob)
    for _,entry in io.dir(dir .. glob) do
        if entry != '.' and entry != '..' then
            local mp = string.lower(entry)
            local notsafe = true
            for i, white in assetsAllowed do
                notsafe = notsafe and (string.find(mp, white, 1) == nil)
            end
            if notsafe then
                LOG('not safe ' .. dir .. entry)
            else
                table.insert(sorted, dir .. entry)
            end
        end
    end
    table.sort(sorted)
    table.foreach(sorted, function(k,v) mount_dir(v,'/') end)
end

function mount_dir_with_assetsBlocked(dir, glob, mountpoint)
    sorted = {}
    LOG('checking ' .. dir .. glob)
    for _,entry in io.dir(dir .. glob) do
        if entry != '.' and entry != '..' then
            local mp = string.lower(entry)
            local safe = true
            for i, black in assetsBlocked do
                safe = safe and (string.find(mp, black, 1) == nil)
            end
            if safe then
                table.insert(sorted, dir .. entry)
            else
                LOG('not safe ' .. dir .. entry)
            end
        end
    end
    table.sort(sorted)
    table.foreach(sorted, function(k,v) mount_dir(v,'/') end)
end


--- Keep track of what maps are loaded to prevent collisions
local loadedMaps = { }

--- A helper function that loads in additional content for maps.
-- @param mountpoint The root folder to look for content in.
function mount_map_content(dir)
    -- look for all directories / maps at the mount point
    for _, map in io.dir(dir .. '//**') do

        -- prevent capital letters messing things up
        map = string.lower(map)

        -- do not do anything with the current / previous directory
        if map == '.' or map == '..' then
            continue 
        end

        -- do not load scds / zips as maps
        if string.find(map, ".zip") or string.find(map, ".scd") then
            continue 
        end

        -- check if the folder contains a .scmap / _scenario.lua / _save.lua
        -- TODO

        -- do not load maps twice
        if loadedMaps[map] then 
            LOG("Prevented loading a map twice: " .. map)
            continue
        end

        -- consider this one loaded
        loadedMaps[map] = true 

        -- mount the map
        mount_dir(dir .. "/" .. map, "/maps/" .. map)

        -- look at each directory inside this map
        for _, folder in io.dir(dir..'\\'..map..'\\**') do
            -- if we found a directory named 'movies' then we mount its content
            if folder == 'movies' then
                LOG('Found map movies in: '..map)
                mount_dir(dir..map..'\\movies', '/movies')
            end

            -- if we found a directory named 'sounds' then we mount its content
            if folder == 'sounds' then
                LOG('Found map sounds in: '..map)
                mount_dir(dir..map..'\\sounds', '/sounds')
            end
        end
    end
end

--- keep track of what mods are loaded to prevent collisions
local loadedMods = { }

--- A helper function that loads in additional content for mods.
-- @param mountpoint The root folder to look for content in.
function mount_mod_content(dir)
    -- get all directories / mods at the mount point
    for _, mod in io.dir(dir..'/*.*') do
        
        -- prevent capital letters messing things up
        mod = string.lower(mod)

        -- do not do anything with the current / previous directory
        if mod == '.' or mod == '..' then
            continue 
        end

        -- do not load scds / zips as mods
        if string.find(mod, ".zip") or string.find(mod, ".scd") then
            continue 
        end

        -- check if the folder contains a _info.lua
        -- TODO

        -- do not load mods twice
        if loadedMods[mod] then 
            LOG("Prevented loading a mod twice: " .. mod)
            continue
        end

        -- consider this one loaded
        loadedMods[mod] = true 

        -- mount the mod
        mount_dir(dir .. "/" .. mod, "/mods/" .. mod)

        -- look at each directory inside this mod
        for _, folder in io.dir(dir..'\\'..mod..'\\*.*') do
            
            -- if we found a directory named 'sounds' then we mount its content
            if folder == 'sounds' then
                LOG('Found mod sounds in: '..mod)
                mount_dir(dir..'\\'..mod..'\\sounds', '/sounds')
            end

            -- if we found a directory named 'custom-strategic-icons' then we mount its content
            if folder == 'custom-strategic-icons' then
                local mountLocation = '/textures/ui/common/game/strategicicons/' .. string.lower(mod)
                LOG('Found mod icons in ' .. mod .. ', mounted at: ' .. mountLocation)
                mount_dir(dir..'\\'..mod..'\\custom-strategic-icons', mountLocation) 
            end

            -- if we found a file named 'custom-strategic-icons.scd' then we mount its content - good for performance when the number of icons is high
            if folder == 'custom-strategic-icons.scd' then 
                local mountLocation = '/textures/ui/common/game/strategicicons/' .. string.lower(mod)
                LOG('Found mod icon package in ' .. mod .. ', mounted at: ' .. mountLocation)
                mount_dir(dir..'\\'..mod..'\\custom-strategic-icons.scd', mountLocation) 
            end
        end
    end
end

--- A helper function to load in all maps and mods on a given location.
-- @param path The root folder for the maps and mods
function load_content(path)
    -- load in additional things, like sounds and 
	mount_map_content(path .. '\\maps\\', '**', '/maps')
	mount_mod_content(path .. '\\mods')
end

hook = {
    '/schook'
}

protocols = {
    'http',
    'https',
    'mailto',
    'ventrilo',
    'teamspeak',
    'daap',
    'im',
}
