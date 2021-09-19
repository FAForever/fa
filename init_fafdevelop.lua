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
    "effects.nx5",
    "env.nx5",
    "etc.nx5",
    "loc.nx5",
    "lua.nx5",
    "meshes.nx5",
    "mods.nx5",
    "projectiles.nx5",
    "schook.nx5",
    "textures.nx5",
    "units.nx5",
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

-- Begin map mounting section
-- This section mounts movies and sounds from maps, essential for custom missions and scripted maps
local function mount_map_dir(dir, glob, mountpoint)
    LOG('mounting maps from: '..dir)
    mount_contents(dir, mountpoint)
    for _, map in io.dir(dir..glob) do
        for _, folder in io.dir(dir..'\\'..map..'\\**') do
            if folder == 'movies' then
                LOG('Found map movies in: '..map)
                mount_dir(dir..map..'\\movies', '/movies')
            elseif folder == 'sounds' then
                LOG('Found map sounds in: '..map)
                mount_dir(dir..map..'\\sounds', '/sounds')
            end
        end
    end
end

-- Begin mod mounting section
-- This section mounts sounds and ui textures from the mods directory to allow mods to add custom sounds and textures to the game
function mount_mod_content(MODFOLDER)
    -- searching for mods inside the modfolder
    for _,mod in io.dir(MODFOLDER..'\\*.*') do
        -- do we have a true directory ?
        if mod != '.' and mod != '..' then
            -- searching for sounds inside mod folder
            for _,folder in io.dir(MODFOLDER..'\\'..mod..'\\*.*') do
                -- if we found a folder named sounds then mount it
                if folder == 'sounds' then
                    LOG('Found mod sounds in: '..mod)
                    mount_dir(MODFOLDER..'\\'..mod..'\\sounds', '/sounds')
                -- mount ui textures if there are any
                elseif folder == 'textures' then
                    for _,folder in io.dir(MODFOLDER..'\\'..mod..'\\textures\\*.*') do
                        if folder == 'ui' then
                          LOG('Found mod icons in: '..mod)
                          mount_dir(MODFOLDER..'\\'..mod..'\\textures\\ui', '/textures/ui')
                          break
                        end
                    end
                end
            end
        end
    end
end

-- adds maps / mods to keep track of for the game
local function load_vault(vault_path)
	mount_map_dir(vault_path .. '\\maps\\', '**', '/maps')
	mount_mod_content(vault_path .. '\\mods')

	mount_contents(vault_path .. '\\mods', '/mods')
	mount_contents(vault_path .. '\\maps', '/maps')
end

-- load in custom vault location first so that it takes precendence
if custom_vault_path then
	LOG('Loading custom vault path' .. custom_vault_path)
	load_vault(custom_vault_path)
else
    LOG("No custom vault path defined.")
end

-- load in files from backup vault location
load_vault(InitFileDir .. '\\..\\user\\My Games\\Gas Powered Games\\Supreme Commander Forged Alliance')

-- load in files from default vault location
load_vault(SHGetFolderPath('PERSONAL') .. 'My Games\\Gas Powered Games\\Supreme Commander Forged Alliance')

mount_dir_with_whitelist(InitFileDir .. '\\..\\gamedata\\', '*.nxt', '/')
mount_dir_with_whitelist(InitFileDir .. '\\..\\gamedata\\', '*.nx5', '/')

-- these are using the newly generated path from the dofile() statement at the beginning of this script
mount_dir_with_whitelist(fa_path .. '\\gamedata\\', '*.scd', '/')
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

table.insert(path, 1, { dir = InitFileDir .. '\\..\\DevData', mountpoint = '/' })
