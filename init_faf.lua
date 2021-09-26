
dev_path = 'C:\\Users\\Jip\\Documents\\Supreme Commander\\fa'

-- This imports a path file that is written by Forged Alliance Forever right before it starts the game.
dofile(InitFileDir .. '\\..\\fa_path.lua')

path = {}

blacklist = {
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

whitelist = {
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

local function mount_dir(dir, mountpoint)
    table.insert(path, { dir = dir, mountpoint = mountpoint })
end

local function mount_contents(dir, mountpoint)
    LOG('checking ' .. dir)
    for _,entry in io.dir(dir .. '\\*') do
        if entry != '.' and entry != '..' then
            local mp = string.lower(entry)
            local safe = true
            for i, black in blacklist do
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

local function mount_dir_with_whitelist(dir, glob, mountpoint)
    sorted = {}
    LOG('checking ' .. dir .. glob)
    for _,entry in io.dir(dir .. glob) do
        if entry != '.' and entry != '..' then
            local mp = string.lower(entry)
            local notsafe = true
            for i, white in whitelist do
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

local function mount_dir_with_blacklist(dir, glob, mountpoint)
    sorted = {}
    LOG('checking ' .. dir .. glob)
    for _,entry in io.dir(dir .. glob) do
        if entry != '.' and entry != '..' then
            local mp = string.lower(entry)
            local safe = true
            for i, black in blacklist do
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

--- A helper function that loads in additional content for maps.
-- @param mountpoint The root folder to look for content in.
local function mount_map_content(dir, glob, mountpoint)
    LOG('mounting maps from: '..dir)
    mount_contents(dir, mountpoint)

    -- look for all directories / maps at the mount point
    for _, map in io.dir(dir..glob) do

        -- make sure we're not retrieving the current / previous directory
        if map != '.' and map != '..' then

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
end

--- A helper function that loads in additional content for mods.
-- @param mountpoint The root folder to look for content in.
function mount_mod_content(mountpoint)
    -- get all directories / mods at the mount point
    for _, mod in io.dir(mountpoint..'\\*.*') do
        
        -- make sure we're not retrieving the current / previous directory
        if mod != '.' and mod != '..' then

            -- look at each directory inside this mod
            for _, folder in io.dir(mountpoint..'\\'..mod..'\\*.*') do
                
                -- if we found a directory named 'sounds' then we mount its content
                if folder == 'sounds' then
                    LOG('Found mod sounds in: '..mod)
                    mount_dir(mountpoint..'\\'..mod..'\\sounds', '/sounds')
                end

                -- if we found a directory named 'custom-strategic-icons' then we mount its content
                if folder == 'custom-strategic-icons' then
                    local mountLocation = '/textures/ui/common/game/strategicicons/' .. string.lower(mod)
                    LOG('Found mod icons in ' .. mod .. ', mounted at: ' .. mountLocation)
                    mount_dir(mountpoint..'\\'..mod..'\\custom-strategic-icons', mountLocation) 
                end
            end
        end
    end
end

--- A helper function to load in all maps and mods on a given location.
-- @param path The root folder for the maps and mods
local function load_content(path)
    -- load in additional things, like sounds and 
	mount_map_content(path .. '\\maps\\', '**', '/maps')
	mount_mod_content(path .. '\\mods')

	mount_contents(path .. '\\mods', '/mods')
	mount_contents(path .. '\\maps', '/maps')
end

-- load in development assets
mount_dir(dev_path, '/')

-- load maps / mods from custom vault location, if set by client
if custom_vault_path then
	LOG('Loading custom vault path' .. custom_vault_path)
	load_content(custom_vault_path)
else
    LOG("No custom vault path defined.")
end

-- load maps / mods from backup vault location location
load_content(InitFileDir .. '\\..\\user\\My Games\\Gas Powered Games\\Supreme Commander Forged Alliance')

-- load maps / mods from my documents vault location
load_content(SHGetFolderPath('PERSONAL') .. 'My Games\\Gas Powered Games\\Supreme Commander Forged Alliance')

-- load in any .nxt that matches the whitelist / blacklist in FAF gamedata
mount_dir_with_whitelist(InitFileDir .. '\\..\\gamedata\\', '*.nxt', '/')
mount_dir_with_whitelist(InitFileDir .. '\\..\\gamedata\\', '*.nx2', '/')

-- load in any .nxt that matches the whitelist / blacklist in FA gamedata
mount_dir_with_whitelist(fa_path .. '\\gamedata\\', '*.scd', '/')

-- TODO: should we limit this?
-- load preferences into the game as well, letting us have much more control over their contents. This also includes cache and similar.
mount_dir(SHGetFolderPath('LOCAL_APPDATA') .. 'Gas Powered Games\\Supreme Commander Forged Alliance', '/preferences')

-- TODO: ?
mount_dir(fa_path, '/')

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

