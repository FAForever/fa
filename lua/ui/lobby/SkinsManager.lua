local Prefs = import('/lua/user/prefs.lua')

local _skinCache = nil

-- faction identifiers and sort order
Factions = { 
    ['UEF']      = { order = 1, color = 'FF219EEC', icon = '/textures/ui/common/faction_icon-lg/uef_ico.dds'},
    ['AEON']     = { order = 2, color = 'FF22CB1E', icon = '/textures/ui/common/faction_icon-lg/aeon_ico.dds'},
    ['CYBRAN']   = { order = 3, color = 'FFF73E12', icon = '/textures/ui/common/faction_icon-lg/cybran_ico.dds'},
    ['SERAPHIM'] = { order = 4, color = 'FFDECA21', icon = '/textures/ui/common/faction_icon-lg/seraphim_ico.dds'},
    ['NOMADS']   = { order = 5, color = 'FFDE8221', icon = '/textures/ui/common/faction_icon-lg/nomads_ico.dds'},
    ['UNKNOWN']  = { order = 6, color = 'FFF4F3F2', icon = '/textures/ui/common/dialogs/mod-manager/generic-icon_bmp.dds'},
}

function GetSkinNameVersion(skin)
    local name = skin.name
    name = name:gsub(" %[", " ")
    name = name:gsub("%]", "")
    name = name:gsub(" V", " ")
    name = name:gsub(" v", " ")
    name = name:gsub(" %(V", " ")
    name = name:gsub(" %(v", " ")
    name = name:gsub("%d%)", "")
    name = name:gsub(" %d%_%d%_%d", "")
    name = name:gsub(" %d%.%d%d%d", "")
    name = name:gsub(" %d%.%d%d", "")
    name = name:gsub(" %d%.%d", "")
    name = name:gsub(" %d%.", "")
    name = name:gsub(" %d", "")
    -- cleanup name
    name = name:gsub(" %(%)", "")
    name = name:gsub("%)", "")
    name = name:gsub(" %-", " ")
    name = name:gsub("%- ", "")
    name = name:gsub("%-", " ", 1)
    name = name:gsub("%_", " ")
    name = name:gsub(" %(", " - ")
    name = StringCapitalize(name)

    if not skin.version then
        name = name .. ' ---- (v1.0)'
    elseif type(skin.version) == 'number' then
        local ver = string.format("v%01.2f", skin.version)
        ver = ver:gsub("%.*0$", "")
        name = name .. ' ---- (' .. ver .. ')'
    elseif type(skin.version) == 'string' then
        local ver = skin.version
        if string.find(ver, "%d%.%d%.%d") then
            ver = StringReverse(ver)
            ver = ver:gsub("%.", "", 1)
            ver = StringReverse(ver)
        elseif not string.find(ver, "%.") then
            ver = ver .. '.0'
        end
        name = name .. ' ---- (v' .. ver .. ')'
    end
    return name
end

function LoadSkinInfo(filename)
    -- fill in some defaults to start with...
    local skin = {
        location = Dirname(filename),
        name = filename,
        description = "<LOC uimod_0006>(No description)",
        author = '',
        copyright = '',
        exclusive = false, 
        selectable = true,
        hookdir = '/hook',      -- specify the name of the hook sub-directory
        shadowdir = '/shadow',  -- specify the name of shadow sub-directory
        uid = filename, -- default uid to name, should be a unique id
    }
    local ok, result = pcall(doscript, filename, skin)
    if not ok then
        WARN("SkinManager failed on loading " .. filename .. ":\n" .. result)
        return nil 
    else
        skin.location = Dirname(filename)
        skin.title = GetSkinNameVersion(skin)
        skin.icon = skin.location .. '/skin_icon.dds'
        if not DiskGetFileInfo(skin.icon) then
            skin.icon = '/textures/ui/common/dialogs/mod-manager/generic-icon_bmp.dds'
        end
        
        if not skin.faction or not Factions[skin.faction] then
            skin.faction = 'UNKNOWN'
        end
        skin.factionIcon = Factions[skin.faction].icon
        
        if not skin.target then
            WARN('SkinManager found skin_info without target: '..  skin.title  )
            --skin.target = 'skin.target'
        end

        return skin
    end
end

function ClearCache()
    _skinCache = nil
end

function GetAllSkins()

    if _skinCache then return _skinCache end
    
    --TODO add server function to get UIDs of skins that the current player can use

    _skinCache = {}
    -- assuming all unit skins are in FAF textures otherwise players without skins will not see them
    local skinLocation = '/textures/ui/unitSkins'
    local skinPattern = '*skin_info.lua'
    for i,file in DiskFindFiles(skinLocation, skinPattern) do
        local skin = LoadSkinInfo(file) 
        --TODO check if a skin can be used by the current player
        if skin and (skin.enabled ~= false) and (skin.name ~= "Hotstats") then
            _skinCache[skin.uid] = skin
        end
    end 
    
    return _skinCache
end

function SaveSkins(newSkins)
    
    LOG("SkinManager SaveSkins:") 
    for uid, _ in newSkins or {} do
        LOG("\t" .. uid .. ' - ' .. tostring(_skinCache[uid].name))
    end

    Prefs.SetToCurrentProfile("active_skins", newSkins)
    UpdateSkins()
     
end

-- gets locally available skins
function GetLocalSkins()
    local result = {}
    for k, skin in GetAllSkins() do
        result[skin.uid] = true
    end
    return result
end

-- Get List of selected mods and check if they still exist.
function GetSelectedSkins()
    local skinsFromGamePrefs = Prefs.GetFromCurrentProfile('active_skins') or {}
    local skinsFromDisk = {}
    for uid, skin in GetAllSkins() do
        skinsFromDisk[skin.uid] = true
    end
    for uid in skinsFromGamePrefs do
        if not skinsFromDisk[uid] then
            skinsFromGamePrefs[uid] = nil
            Prefs.SetToCurrentProfile("active_skins", skinsFromGamePrefs)
        end
    end
    
    return skinsFromGamePrefs
end
 

function GetSelectedSkinFaction() 
    local result = {}
    for uid, skin in GetSelectedSkins() do
        if skin.faction then
            result[uid] = skin.faction 
        end
    end
    return result
end
 

function GetSkinIcon(file)
    local i, j = string.find(file, 'skin_info.lua')
    return string.sub(file, 1, i-1) .. 'skin_icon.dds'
end

function GetSelectableSkins()
    local r = {}
    for uid, skin in GetAllSkins() do
        r[uid] = skin
    end
    return r
end

local function SkinComp(first, second)
    if _skinCache[first].before then
        for i,uid in _skinCache[first].before do
            if _skinCache[second].uid == uid then
                return true
            end
        end
    end

    if _skinCache[first].after then
        for i,uid in _skinCache[first].after do
            if _skinCache[second].uid == uid then
                return false
            end
        end
    end

    return first < second
end

local function GetActiveSkinsFiltered(filter, selected)
    if not selected then
        selected = GetSelectedSkins()
    end

    local all_skins = GetAllSkins()
    local r = {}
    for uid,m in sortedpairs(all_skins, SkinComp) do
        if selected[uid] and filter(m) then
            table.insert(r,m)
        end
    end
    return r
end

function GetSkinFaction(selected)
    return GetActiveSkinsFiltered(function(m) return m.skin_faction end, selected)
end

function UpdateSkins()
    _active_skins = {}
    for i,m in ipairs(GetSkinFaction()) do
        table.insert(_active_skins, m)
    end
end

-- initialize unit skins
_skinCache = GetAllSkins()