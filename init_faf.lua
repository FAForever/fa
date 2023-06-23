-- START OF COPY --

-- in an ideal world this file would be loaded (using dofile) by the other
-- initialisation files to prevent code duplication. However, as it stands
-- we can not load in additional init files with the current deployment 
-- system and therefore we copy/paste this section into the other init files.

-- imports fa_path to determine where it is installed
dofile(InitFileDir .. '/../fa_path.lua')

LOG("Client version: " .. tostring(ClientVersion))
LOG("Game version: " .. tostring(GameVersion))
LOG("Game type: " .. tostring(GameType))

-- upvalued performance
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

local function FindFilesWithExtension(dir, extension, prepend, files)
    files = files or { }

    for k, file in IoDir(dir .. "/*") do
        if not (file == '.' or file == '..') then
            if StringSub(file, -3) == extension then
                LOG(prepend .. "/" .. file)
                TableInsert(files, prepend .. "/" .. file)
            end
            FindFilesWithExtension(dir .. "/" .. file, extension, prepend .. "/" .. file, files)
        end
    end

    return files
end

-- mods that have been integrated, based on folder name 
local integratedMods = { }
integratedMods["nvidia fix"] = true

integratedMods = LowerHashTable(integratedMods)

-- take care that the folder name is properly spelled and Capitalized
-- deprecatedMods["Mod Folder Name"] = deprecation status
--   true: deprecated regardless of mod version
--   versionstring: lower or equal version numbers are deprecated, eg: "3.10"
local deprecatedMods = {}

-- mods that are deprecated, based on mod folder name
deprecatedMods["simspeed++"] = true
deprecatedMods["#quality of performance 2022"] = true
deprecatedMods["em"] = "11"

-- as per #4119 the control groups (called selection sets in code) are completely overhauled and extended feature-wise,
-- because of that these mods are no longer viable / broken / integrated
deprecatedMods["group_split"] = "0.1"
deprecatedMods["Control Group Zoom Mod"] = "2"
deprecatedMods["additionalControlGroupStuff"] = true

-- as per #4124 the cursor and command interactions are complete overhauled and extended feature-wise,
-- because of that these mods are no longer viable / broken / integrated
deprecatedMods["additionalCameraStuff"] = "3"
deprecatedMods["RUI"] = "1.0"

-- as per #4232 the reclaim view is completely overhauled
deprecatedMods["Advanced Reclaim&Selection Info"] = "1"
deprecatedMods["AdvancedReclaimInfo"] = "1"
deprecatedMods["BetterReclaimView"] = "2"
deprecatedMods["disableReclaimUI"] = "2"
deprecatedMods["DynamicReclaimGrouping"] = "1"
deprecatedMods["EzReclaim"] = "1.0"
deprecatedMods["OnScreenReclaimCounter"] = "8"
deprecatedMods["ORV"] = "1"
deprecatedMods["SmartReclaimSupport"] = "3"
deprecatedMods["DrimsUIPack"] = "3"
deprecatedMods["Rheclaim"] = "2"

-- convert all mod folder name keys to lower case to prevent typos
deprecatedMods = LowerHashTable(deprecatedMods)

-- typical FA packages
local allowedAssetsScd = { }
allowedAssetsScd["units.scd"] = true
allowedAssetsScd["textures.scd"] = true
allowedAssetsScd["skins.scd"] = true
allowedAssetsScd["schook.scd"] = false      -- completely embedded in the repository
allowedAssetsScd["props.scd"] = true
allowedAssetsScd["projectiles.scd"] = true
allowedAssetsScd["objects.scd"] = true
allowedAssetsScd["moholua.scd"] = false     -- completely embedded in the repository
allowedAssetsScd["mohodata.scd"] = false    -- completely embedded in the repository
allowedAssetsScd["mods.scd"] = true
allowedAssetsScd["meshes.scd"] = true
allowedAssetsScd["lua.scd"] = false         -- completely embedded in the repository
allowedAssetsScd["loc_us.scd"] = true
allowedAssetsScd["loc_es.scd"] = true
allowedAssetsScd["loc_fr.scd"] = true
allowedAssetsScd["loc_it.scd"] = true
allowedAssetsScd["loc_de.scd"] = true
allowedAssetsScd["loc_ru.scd"] = true
allowedAssetsScd["env.scd"] = true
allowedAssetsScd["effects.scd"] = true
allowedAssetsScd["editor.scd"] = false      -- Unused
allowedAssetsScd["ambience.scd"] = false    -- Empty 
allowedAssetsScd["sc_music.scd"] = true
allowedAssetsScd = LowerHashTable(allowedAssetsScd)

-- typical backwards compatible packages
local allowedAssetsNxt = { }
allowedAssetsNxt["kyros.nxt"] = true
allowedAssetsNxt["advanced strategic icons.nxt"] = true
allowedAssetsNxt["advanced_strategic_icons.nxt"] = true
allowedAssetsNxt = LowerHashTable(allowedAssetsNxt)

-- default wave banks to prevent collisions
local soundsBlocked = { }
local sounds = FindFilesWithExtension(fa_path .. '/sounds', "xwb", "/sounds")
for k, v in sounds do 
    if v == '.' or v == '..' then 
        continue 
    end
    soundsBlocked[StringLower(v)] = "FA installation"
end

-- default movie files to prevent collisions
local moviesBlocked = { }
local faMovies = IoDir(fa_path .. '/movies/*')
for k, v in faMovies do 
    if v == '.' or v == '..' then 
        continue 
    end
    moviesBlocked[StringLower(v)] = "FA installation"
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

--- Mounts all allowed content in a directory, including scd and zip files, directly.
-- @param dir The absolute path to the directory
-- @param mountpoint The path to use in the game (e.g., /maps/...)
local function MountAllowedContent(dir, pattern, allowedAssets)
    for _,entry in IoDir(dir .. pattern) do
        if entry != '.' and entry != '..' then
            local mp = StringLower(entry)
            if (not allowedAssets) or allowedAssets[mp] then
                LOG("mounting content: " .. entry)
                MountDirectory(dir .. "/" .. entry, '/')
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
        local extension = StringSub(map, -4)
        if extension == ".zip" or extension == ".scd" or extension == ".rar" then
            LOG("Prevented loading a map inside a zip / scd / rar file: " .. dir .. "/" .. map)
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
            LOG("Prevented loading a map with no scenario file: " .. dir .. "/" .. map)
            continue 
        end

        if not scmapFile then 
            LOG("Prevented loading a map with no scmap file: " .. dir .. "/" .. map)
            continue 
        end

        if not saveFile then 
            LOG("Prevented loading a map with no save file: " .. dir .. "/" .. map)
            continue 
        end

        if not scriptFile then 
            LOG("Prevented loading a map with no script file: " .. dir .. "/" .. map)
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
                    if not (file == '.' or file == '..') then 
                        local identifier = StringLower(file) 
                        if moviesBlocked[identifier] then 
                            TableInsert(conflictingFiles, { file = file, conflict = moviesBlocked[identifier] })
                        else 
                            moviesBlocked[identifier] = StringLower(map)
                        end
                    end
                end
                    
                -- report them if they exist and do not mount
                if TableGetn(conflictingFiles) > 0 then 
                    LOG("Found conflicting movie banks for map: '" .. map .. "', cannot mount the movie bank(s):")
                    for k, v in conflictingFiles do 
                        LOG(" - Conflicting movie bank: '" .. v.file .. "' of map '" .. map .. "' is conflicting with a movie bank from: '" .. v.conflict .. "'" )
                    end
                -- else, mount folder
                else
                    LOG("Mounting movies of map: " .. map )
                    MountDirectory(dir .. "/" .. map .. '/movies', '/movies')
                end
            elseif folder == 'sounds' then
                local banks = FindFilesWithExtension(dir .. '/' .. map .. "/sounds", "xwb", "/sounds")

                -- find conflicting files
                local conflictingFiles = { }
                for _, bank in banks do
                    local identifier = StringLower(bank) 
                    if soundsBlocked[identifier] then 
                        TableInsert(conflictingFiles, { file = bank, conflict = soundsBlocked[identifier] })
                    else 
                        soundsBlocked[identifier] = StringLower(map)
                    end
                end
                
                -- report them if they exist and do not mount
                if TableGetn(conflictingFiles) > 0 then 
                    LOG("Found conflicting sound banks for map: '" .. map .. "', cannot mount the sound bank(s):")
                    for k, v in conflictingFiles do 
                        LOG(" - Conflicting sound bank: '" .. v.file .. "' of map '" .. map .. "' is conflicting with a sound bank from: '" .. v.conflict .. "'" )
                    end

                -- else, mount folder
                else
                    LOG("Mounting sounds of map: " .. map )
                    MountDirectory(dir.. "/" .. map .. '/sounds', '/sounds')
                end
            end
        end
    end
end


--- Parses a `major.minor` string into its numeric parts, where the minor portion is optional
---@param version string
---@return number major
---@return number? minor
local function ParseVersion(version)
    local major, minor
    local dot_pos1 = version:find('.', 1, true)
    if dot_pos1 then
        major = tonumber(version:sub(1, dot_pos1 - 1))
		-- we aren't looking for the build number, but we still need to be able to parse
		-- the minor number properly if it does exist
		local dot_pos2 = version:find('.', dot_pos1 + 1, true)
		if dot_pos2 then
			minor = tonumber(version:sub(dot_pos1 + 1, dot_pos2 - 1))
		else
			minor = tonumber(version:sub(dot_pos1 + 1))
		end
    else
        major = tonumber(version)
    end
    return major, minor
end

---@param majorA number
---@param minorA number | nil
---@param majorB number
---@param minorB number | nil
---@return number
local function CompareVersions(majorA, minorA, majorB, minorB)
    if majorA ~= majorB then
        return majorA - majorB
    end
    minorA = minorA or 0
    minorB = minorB or 0
    return minorA - minorB
end

--- Returns the version string found in the mod info file (which can be `nil`), or `false` if the
--- file cannot be read
---@param modinfo FileName
---@return string|nil | false
local function GetModVersion(modinfo)
    local handle = io.open(modinfo, 'rb')
    if not handle then
        return false -- can't read file
    end

    local _,version
    for line in handle:lines() do
        -- find the version
        _,_,version = line:find("^%s*version%s*=%s*v?([%d.]*)")
		if version then
            break -- stop if found
        end
    end

    handle:close()
    return version
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

        local moddir = dir .. '/' .. mod

        -- do not load integrated mods
        if integratedMods[mod] then 
            LOG("Prevented loading a mod that is integrated: " .. mod )
            continue 
        end 

        -- do not load archives as mods
        local extension = StringSub(mod, -4)
        if extension == ".zip" or extension == ".scd" or extension == ".rar" then
            LOG("Prevented loading a mod inside a zip / scd / rar file: " .. moddir)
            continue 
        end

        -- check if the folder contains a `mod_info.lua` file
        local modinfo_file = IoDir(moddir .. "/mod_info.lua")[1]

        -- check if it has a scenario file
        if not modinfo_file then
            LOG("Prevented loading an invalid mod: " .. mod .. " does not have an info file: " .. moddir)
            continue
        end
        modinfo_file = moddir .. '/' .. modinfo_file

        -- do not load deprecated mods
        local deprecation_status = deprecatedMods[mod]
        if deprecation_status then
            if deprecation_status == true then
                -- deprecated regardless of version
                LOG("Prevented loading a deprecated mod: " .. mod)
                continue
            elseif type(deprecation_status) == "string" then
                -- depcreated only when the mod version is less than or equal to the deprecation version
                local mod_version = GetModVersion(modinfo_file)
                if mod_version == false then
                    LOG("Prevented loading a deprecated mod: " .. mod .. " does not have readable mod info (" .. modinfo_file .. ')')
                    continue
                end
                if mod_version == nil then
                    LOG("Prevented loading a deprecated mod version: " .. mod .. " does not specify a version number (must be higher than version " .. deprecation_status .. ')')
                    continue
                end
                local mod_major, mod_minor = ParseVersion(mod_version)
                local dep_major, dep_minor = ParseVersion(deprecation_status)
                if not mod_major or CompareVersions(mod_major, mod_minor, dep_major, dep_minor) <= 0 then
                    LOG("Prevented loading a deprecated mod version: " .. mod .. " version " .. mod_version .. " (must be higher than version " .. deprecation_status .. ')')
                    continue
                end
            end
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
                local banks = FindFilesWithExtension(dir .. '/' ..  mod .. "/sounds", "xwb", "/sounds")

                -- find conflicting files
                local conflictingFiles = { }
                for _, bank in banks do
                    local identifier = StringLower(bank) 
                    if soundsBlocked[identifier] then 
                        TableInsert(conflictingFiles, { file = bank, conflict = soundsBlocked[identifier] })
                    else
                        soundsBlocked[identifier] = StringLower(mod)
                    end
                end

                -- report them if they exist and do not mount
                if TableGetn(conflictingFiles) > 0 then 
                    LOG("Found conflicting sound banks for mod: '" .. mod .. "', cannot mount the sound bank(s):")
                    for _, v in conflictingFiles do 
                        LOG(" - Conflicting sound bank: '" .. v.file .. "' of mod '" .. mod .. "' is conflicting with a sound bank from: '" .. v.conflict .. "'" )
                    end
                -- else, mount folder
                else
                    LOG("Mounting sounds in mod: " .. mod )
                    MountDirectory(dir .. "/" .. mod .. '/sounds', '/sounds')
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

-- -- minimum viable shader version - should be bumped to the next release version when we change the shaders
-- local minimumShaderVersion = 3745

-- -- look for unviable shaders and remove them
-- local shaderCache = SHGetFolderPath('LOCAL_APPDATA') .. 'Gas Powered Games/Supreme Commander Forged Alliance/cache'
-- for k, file in IoDir(shaderCache .. '/*') do
--     if file != '.' and file != '..' then 
--         local version = tonumber(string.sub(file, -4))
--         if not version or version < minimumShaderVersion then 
--             LOG("Removed incompatible shader: " .. file)
--             os.remove(shaderCache .. '/' .. file)
--         end
--     end
-- end

-- Clears out the shader cache as it takes a release to reset the shaders
local shaderCache = SHGetFolderPath('LOCAL_APPDATA') .. 'Gas Powered Games/Supreme Commander Forged Alliance/cache'
for k, file in IoDir(shaderCache .. '/*') do
    if file != '.' and file != '..' then 
        os.remove(shaderCache .. '/' .. file)
    end
end

-- typical FAF packages
local allowedAssetsNxy = { }
allowedAssetsNxy["effects.nx2"] = true
allowedAssetsNxy["env.nx2"] = true
allowedAssetsNxy["etc.nx2"] = true
allowedAssetsNxy["loc.nx2"] = true
allowedAssetsNxy["lua.nx2"] = true
allowedAssetsNxy["meshes.nx2"] = true
allowedAssetsNxy["mods.nx2"] = true
allowedAssetsNxy["projectiles.nx2"] = true
-- allowedAssetsNxy["schook.nx2"] = true
allowedAssetsNxy["textures.nx2"] = true
allowedAssetsNxy["units.nx2"] = true
allowedAssetsNxy = LowerHashTable(allowedAssetsNxy)

-- load maps / mods from custom vault location, if set by client
if custom_vault_path then
	LOG('Loading custom vault path: ' .. custom_vault_path)
	LoadVaultContent(custom_vault_path)
else
    LOG("No custom vault path defined: loading from backup locations. You should update your client to 2021/10/+.")
    -- load maps / mods from backup vault location location
    LoadVaultContent(InitFileDir .. '/../user/My Games/Gas Powered Games/Supreme Commander Forged Alliance')
    -- load maps / mods from my documents vault location
    LoadVaultContent(SHGetFolderPath('PERSONAL') .. 'My Games/Gas Powered Games/Supreme Commander Forged Alliance')
end

-- load in .nxt / .nx2 / .scd files that we allow
MountAllowedContent(InitFileDir .. '/../gamedata/', '*.nxt', allowedAssetsNxt)
MountAllowedContent(InitFileDir .. '/../gamedata/', '*.nx2', allowedAssetsNxy)
MountAllowedContent(fa_path .. '/gamedata/', '*.scd', allowedAssetsScd)

-- get direct access to preferences file, letting us have much more control over its content. This also includes cache and similar
MountDirectory(SHGetFolderPath('LOCAL_APPDATA') .. 'Gas Powered Games/Supreme Commander Forged Alliance', '/preferences')

-- Load in all the data of the steam installation (movies, maps, sound folders)
MountDirectory(fa_path .. "/movies", '/movies')
MountDirectory(fa_path .. "/sounds", '/sounds')
MountDirectory(fa_path .. "/maps", '/maps')
MountDirectory(fa_path .. "/fonts", '/fonts')