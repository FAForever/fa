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
local TableGetn = table.getn

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

--- Lowers the strings of a hash-based table, crashes when other type of keys are used (integers, for example)
local function LowerHashTable(t)
    local o = { }
    for k, v in t do 
        o[StringLower(k)] = v 
    end
    return o
end

-- mods that have been integrated, based on folder name 
local integratedMods = { }
integratedMods["nvidia fix"] = true
integratedMods = LowerHashTable(integratedMods)

-- typical FAF packages
local allowedAssetsNx2 = { }
allowedAssetsNx2["effects.nx2"] = true
allowedAssetsNx2["env.nx2"] = true
allowedAssetsNx2["etc.nx2"] = true
allowedAssetsNx2["loc.nx2"] = true
allowedAssetsNx2["lua.nx2"] = true
allowedAssetsNx2["meshes.nx2"] = true
allowedAssetsNx2["mods.nx2"] = true
allowedAssetsNx2["projectiles.nx2"] = true
allowedAssetsNx2["schook.nx2"] = true
allowedAssetsNx2["textures.nx2"] = true
allowedAssetsNx2["units.nx2"] = true
allowedAssetsNx2 = LowerHashTable(allowedAssetsNx2)

-- typical FA packages
local allowedAssetsScd = { }
allowedAssetsScd["units.scd"] = true
allowedAssetsScd["textures.scd"] = true
allowedAssetsScd["skins.scd"] = true
allowedAssetsScd["schook.scd"] = true
allowedAssetsScd["props.scd"] = true
allowedAssetsScd["projectiles.scd"] = true
allowedAssetsScd["objects.scd"] = true
allowedAssetsScd["moholua.scd"] = true
allowedAssetsScd["mohodata.scd"] = true
allowedAssetsScd["mods.scd"] = true
allowedAssetsScd["meshes.scd"] = true
allowedAssetsScd["lua.scd"] = true
allowedAssetsScd["loc_us.scd"] = true
allowedAssetsScd["loc_es.scd"] = true
allowedAssetsScd["loc_fr.scd"] = true
allowedAssetsScd["loc_it.scd"] = true
allowedAssetsScd["loc_de.scd"] = true
allowedAssetsScd["loc_ru.scd"] = true
allowedAssetsScd["env.scd"] = true
allowedAssetsScd["effects.scd"] = true
allowedAssetsScd["editor.scd"] = true
allowedAssetsScd["ambience.scd"] = true
allowedAssetsScd["lobbymanager_v105.scd"] = true
allowedAssetsScd["sc_music.scd"] = true
allowedAssetsScd = LowerHashTable(allowedAssetsScd)

-- typical backwards compatible packages
local allowedAssetsNxt = { }
allowedAssetsNxt["texturepack.nxt"] = true
allowedAssetsNxt["advanced strategic icons.nxt"] = true
allowedAssetsNxt["advanced_strategic_icons.nxt"] = true
allowedAssetsNxt = LowerHashTable(allowedAssetsNxt)

-- default wave banks to prevent collisions
local soundsBlocked = { }
local faSounds = IoDir(fa_path .. '/sounds/*')
for k, v in faSounds do 
    if v == '.' or v == '..' then 
        continue 
    end
    soundsBlocked[StringLower(v)] = true
end

-- default movie files to prevent collisions
local moviesBlocked = { }
local faMovies = IoDir(fa_path .. '/movies/*')
for k, v in faMovies do 
    if v == '.' or v == '..' then 
        continue 
    end
    moviesBlocked[StringLower(v)] = true
end

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

--- Mounts all allowed content in a directory, including scd and zip files, to the mountpoint.
-- @param dir The absolute path to the directory
-- @param mountpoint The path to use in the game (e.g., /maps/...)
local function MountContent(dir, mountpoint, allowedAssets)
    for _,entry in IoDir(dir .. '/*') do
        if entry != '.' and entry != '..' then
            local mp = StringLower(entry)
            if allowedAssets[mp] then 
                MountDirectory(dir .. '/' .. entry, mountpoint .. '/' .. mp)
            else 
                LOG("Prevented loading content that is not allowed: " .. entry)
            end
        end
    end
end

--- Mounts all allowed content in a directory, including scd and zip files, directly.
-- @param dir The absolute path to the directory
-- @param mountpoint The path to use in the game (e.g., /maps/...)
local function MountAllowedContent(dir, pattern, allowedAssets)
    for _,entry in IoDir(dir .. pattern) do
        if entry != '.' and entry != '..' then
            local mp = StringLower(entry)
            if allowedAssets[mp] then 
                MountDirectory(dir .. "/" .. entry, '/')
            else 
                LOG("Prevented loading content that is not allowed: " .. entry)
            end
        end
    end
end

--- Keep track of what maps are loaded to prevent collisions
local loadedMaps = { }

--- A helper function that loads in additional content for maps.
-- @param mountpoint The root folder to look for content in.
local function MountMapContent(dir)
    -- look for all directories / maps at the mount point
    for _, map in IoDir(dir .. '/*') do

        -- prevent capital letters messing things up
        map = StringLower(map)

        -- do not do anything with the current / previous directory
        if map == '.' or map == '..' then
            continue 
        end

        -- do not load archives as maps
        if StringSub(map, -4) == ".zip" or StringSub(map, -4) == ".scd"  or StringSub(map, -4) == ".rar" then
            continue 
        end

        -- check if the folder contains map required map files
        local scenarioFile = false 
        local scmapFile = false 
        local saveFile = false 
        local scriptFile = false 
        for _, file in IoDir(dir .. "/" .. map .. "/*") do 
            if StringSub(file, -13) == '_scenario.lua' then 
                scenarioFile = file 
            elseif StringSub(file, -11) == '_script.lua' then 
                scriptFile = file 
            elseif StringSub(file, -9) == '_save.lua' then 
                saveFile = file 
            elseif StringSub(file, -6) == '.scmap' then 
                scmapFile = file 
            end
        end

        -- check if it has a scenario file
        if not scenarioFile then 
            LOG("Map doesn't have a scenario file: " .. dir .. "/" .. map)
            continue 
        end

        if not scmapFile then 
            LOG("Map doesn't have a scmap file: " .. dir .. "/" .. map)
            continue 
        end

        if not saveFile then 
            LOG("Map doesn't have a save file: " .. dir .. "/" .. map)
            continue 
        end

        if not scriptFile then 
            LOG("Map doesn't have a script file: " .. dir .. "/" .. map)
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
        for _, folder in IoDir(dir .. '/' .. map .. '/*') do

            -- do not do anything with the current / previous directory
            if folder == '.' or folder == '..' then
                continue 
            end

            if folder == 'movies' then
                -- find conflicting files
                local conflictingFiles = { }
                for _, file in IoDir(dir .. '/' .. map .. '/movies/*') do
                    if moviesBlocked[StringLower(file)] then 
                        TableInsert(conflictingFiles, file)
                    end
                end
                    
                -- report them if they exist and do not mount
                if TableGetn(conflictingFiles) > 0 then 
                    LOG('Found conflicting movies with the base game for map, cannot mount movies for: ' .. map)
                    for k, v in conflictingFiles do 
                        LOG(" - Conflicting movie file: " .. v )
                    end
                -- else, mount folder
                else
                    LOG("Mounting movies of map: " .. map )
                    MountDirectory(dir..map..'/movies', '/movies')
                end
            elseif folder == 'sounds' then
                -- find conflicting files
                local conflictingFiles = { }
                for _, file in IoDir(dir .. '/' .. map .. '/sounds/*') do
                    if soundsBlocked[StringLower(file)] then 
                        TableInsert(conflictingFiles, file)
                    end
                end
                    
                -- report them if they exist and do not mount
                if TableGetn(conflictingFiles) > 0 then 
                    LOG('Found conflicting sounds with the base game for map, cannot mount sounds for: ' .. map)
                    for k, v in conflictingFiles do 
                        LOG(" - Conflicting sound file: " .. v )
                    end

                -- else, mount folder
                else
                    LOG("Mounting sounds of map: " .. map )
                    MountDirectory(dir..map..'/sounds', '/sounds')
                end
            end
        end
    end
end

--- keep track of what mods are loaded to prevent collisions
local loadedMods = { }

--- A helper function that loads in additional content for mods.
-- @param mountpoint The root folder to look for content in.
local function MountModContent(dir)
    -- get all directories / mods at the mount point
    for _, mod in io.dir(dir..'/*.*') do
        
        -- prevent capital letters messing things up
        mod = StringLower(mod)

        -- do not do anything with the current / previous directory
        if mod == '.' or mod == '..' then
            continue 
        end

        -- do not load integrated mods
        if integratedMods[mod] then 
            _ALERT("Blocked mod that is integrated: " .. mod )
            continue 
        end 

        -- do not load archives as mods
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
        for _, folder in IoDir(dir .. '/' .. mod .. '/*') do
            
            -- if we found a directory named 'sounds' then we mount its content
            if folder == 'sounds' then
                -- find conflicting files
                local conflictingFiles = { }
                for _, file in IoDir(dir .. '/' .. mod .. '/sounds/*') do
                    if soundsBlocked[StringLower(file)] then 
                        TableInsert(conflictingFiles, file)
                    end
                end
                    
                -- report them if they exist and do not mount
                if TableGetn(conflictingFiles) > 0 then 
                    LOG('Found conflicting sounds with the base game for mod, cannot mount sounds for: ' .. mod)
                    for k, v in conflictingFiles do 
                        LOG(" - Conflicting sound file: " .. v )
                    end
                -- else, mount folder
                else
                    LOG("Mounting sounds in mod: " .. mod )
                    MountDirectory(dir .. mod .. '/sounds', '/sounds')
                end
            end

            -- if we found a directory named 'custom-strategic-icons' then we mount its content
            if folder == 'custom-strategic-icons' then
                local mountLocation = '/textures/ui/common/game/strategicicons/' .. mod
                LOG('Found mod icons in ' .. mod .. ', mounted at: ' .. mountLocation)
                MountDirectory(dir .. '/' .. mod .. '/custom-strategic-icons', mountLocation) 
            end

            -- if we found a file named 'custom-strategic-icons.scd' then we mount its content - good for performance when the number of icons is high
            if folder == 'custom-strategic-icons.scd' then 
                local mountLocation = '/textures/ui/common/game/strategicicons/' .. mod
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
	MountMapContent(path .. '/maps')
	MountModContent(path .. '/mods')
end

-- END OF COPY --

-- load maps / mods from custom vault location, if set by client
if custom_vault_path then
	LOG('Loading custom vault path' .. custom_vault_path)
	LoadVaultContent(custom_vault_path)
else
    LOG("No custom vault path defined: loading from backup locations. You should update your client to 2021/10/+.")
    -- load maps / mods from backup vault location location
    LoadVaultContent(InitFileDir .. '/../user/My Games/Gas Powered Games/Supreme Commander Forged Alliance')
    -- load maps / mods from my documents vault location
    LoadVaultContent(SHGetFolderPath('PERSONAL') .. 'My Games/Gas Powered Games/Supreme Commander Forged Alliance')
end

-- load in any .nxt that matches the whitelist / blacklist in FAF gamedata
MountAllowedContent(InitFileDir .. '/../gamedata/', '*.nx5', '/')

-- load in any .nxt that matches the whitelist / blacklist in FA gamedata
MountAllowedContent(fa_path .. '/gamedata/', '*.scd', '/')

-- get direct access to preferences file, letting us have much more control over its content. This also includes cache and similar
MountDirectory(SHGetFolderPath('LOCAL_APPDATA') .. 'Gas Powered Games/Supreme Commander Forged Alliance', '/preferences')

-- Load in all the data of the steam installation (movies, maps, sound folders)
MountDirectory(fa_path .. "/movies", '/movies')
MountDirectory(fa_path .. "/sounds", '/sounds')
MountDirectory(fa_path .. "/maps", '/maps')
MountDirectory(fa_path .. "/fonts", '/fonts')


-- Dump of global scope --

-- local function repr(t, indent, seen)
--     if type(t) == "table" then 
--         for k, v in t do 
--             if k != "_G" then 
--                 seen[k] = true
--                 LOG(indent .. tostring(k) .. ": " .. tostring(v))
--                 repr(v, indent .. " - ")
--             end
--         end
--     end
-- end

-- repr(_G, "", { })

-- string: table: 10020208
--  - sub: cfunction: 101C88C0
--  - lualex: cfunction: 101C8B80
--  - gfind: cfunction: 101C8B00
--  - rep: cfunction: 101C89C0
--  - gsub: cfunction: 101C8B40
--  - char: cfunction: 101C8980
--  - dump: cfunction: 101C8A80
--  - find: cfunction: 101C8AC0
--  - upper: cfunction: 101C8940
--  - len: cfunction: 101C8880
--  - format: cfunction: 101C8A40
--  - byte: cfunction: 101C8A00
--  - lower: cfunction: 101C8900
-- tostring: cfunction: 100504C0
-- gcinfo: cfunction: 10050700
-- _ALERT: cfunction: 101CAF80
-- loadlib: cfunction: 101CAE80
-- os: table: 10020168
--  - exit: cfunction: 101C8C80
--  - setlocale: cfunction: 101C8D80
--  - execute: cfunction: 101C8C40
--  - getenv: cfunction: 101C8CC0
--  - difftime: cfunction: 101C8C00
--  - remove: cfunction: 101C8D00
--  - time: cfunction: 101C8DC0
--  - clock: cfunction: 101C8040
--  - tmpname: cfunction: 101C8E00
--  - rename: cfunction: 101C8D40
--  - date: cfunction: 101C8000
-- unpack: cfunction: 10050580
-- require: cfunction: 101C83C0
-- getfenv: cfunction: 10050B00
-- serialize: table: 100201E0
--  - fromstring: cfunction: 101C8840
--  - tostring: cfunction: 101C8800
-- setmetatable: cfunction: 10050AC0
-- next: cfunction: 10050B80
-- _TRACEBACK: cfunction: 101CAE40
-- assert: cfunction: 10050540
-- tonumber: cfunction: 10050480
-- io: table: 100201B8
--  - popen: cfunction: 101C91E0
--  - write: cfunction: 101C90F0
--  - close: cfunction: 101C9280
--  - flush: cfunction: 101C9320
--  - open: cfunction: 101C9230
--  - output: cfunction: 101C9370
--  - dir: cfunction: 101C90A0
--  - read: cfunction: 101C9190
--  - stderr: file (101C7B38)
--  - stdin: file (101C7B08)
--  - input: cfunction: 101C93C0
--  - stdout: file (101C7B20)
--  - lines: cfunction: 101C92D0
--  - tmpfile: cfunction: 101C9140
-- rawequal: cfunction: 100505C0
-- collectgarbage: cfunction: 100506C0
-- getmetatable: cfunction: 10050A80
-- InitFileDir: C:\ProgramData\FAForever\bin
-- _LOADED: table: 10020668
-- rawset: cfunction: 10050640
-- LuaDumpBinary: cfunction: 101CAF00
-- LaunchDir: C:\ProgramData\FAForever\bin
-- SHGetFolderPath: cfunction: 101CAFC0
-- LOG: cfunction: 101CAF40
-- math: table: 10020230
--  - log: cfunction: 101C87C0
--  - atan: cfunction: 101C8540
--  - ldexp: cfunction: 101C86C0
--  - deg: cfunction: 101CA340
--  - tan: cfunction: 101C8480
--  - cos: cfunction: 101C8440
--  - pi: 3.1415927410126
--  - random: cfunction: 101CA280
--  - randomseed: cfunction: 101CA240
--  - frexp: cfunction: 101C8680
--  - ceil: cfunction: 101C85C0
--  - floor: cfunction: 101C8600
--  - rad: cfunction: 101CA2C0
--  - max: cfunction: 101C8780
--  - sqrt: cfunction: 101C8700
--  - pow: cfunction: 101CA300
--  - asin: cfunction: 101C84C0
--  - min: cfunction: 101C8740
--  - mod: cfunction: 101C8640
--  - exp: cfunction: 101CA380
--  - log10: cfunction: 101CA3C0
--  - atan2: cfunction: 101C8580
--  - acos: cfunction: 101C8500
--  - sin: cfunction: 101C8400
--  - abs: cfunction: 101C8BC0
-- import: cfunction: 101CAEC0
-- pcall: cfunction: 10050680
-- debug: table: 10020258
--  - listlocals: cfunction: 101CACC0
--  - allocatedsize: cfunction: 101CAE00
--  - gethook: cfunction: 101CA140
--  - traceback: cfunction: 101CAC00
--  - getlocal: cfunction: 101CA1C0
--  - getupvalue: cfunction: 101CA100
--  - listcode: cfunction: 101CAC40
--  - debug: cfunction: 101CA000
--  - listk: cfunction: 101CAC80
--  - allobjects: cfunction: 101CAD40
--  - sethook: cfunction: 101CA0C0
--  - trackallocations: cfunction: 101CADC0
--  - getinfo: cfunction: 101CA180
--  - setupvalue: cfunction: 101CA040
--  - allocinfo: cfunction: 101CAD80
--  - profiledata: cfunction: 101CAD00
--  - setlocal: cfunction: 101CA080
-- __pow: cfunction: 101CA200
-- type: cfunction: 10050500
-- newproxy: cfunction: 10053AA0
-- table: table: 10020690
--  - setn: cfunction: 101C8140
--  - insert: cfunction: 101C80C0
--  - getn: cfunction: 101C8180
--  - foreachi: cfunction: 101C81C0
--  - foreach: cfunction: 101C8200
--  - sort: cfunction: 101C8100
--  - remove: cfunction: 101C8080
--  - concat: cfunction: 101C8240
-- coroutine: table: 10020640
--  - resume: cfunction: 101C8300
--  - yield: cfunction: 101C82C0
--  - status: cfunction: 101C8280
--  - wrap: cfunction: 101C8340
--  - create: cfunction: 101C8380
-- print: cfunction: 10050440
-- rawget: cfunction: 10050600
-- loadstring: cfunction: 100507C0
-- _VERSION: Lua 5.0.1
-- dofile: cfunction: 10050780
-- setfenv: cfunction: 10050B40
-- pairs: cfunction: 10050400
-- ipairs: cfunction: 10050BC0
-- error: cfunction: 10050A40
-- loadfile: cfunction: 10050740