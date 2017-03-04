local bt = import('/modules/buildingtab.lua')
local construction = import('/lua/ui/game/construction.lua')
local orders = import('/lua/ui/game/orders.lua')
local Prefs = import('/lua/user/prefs.lua')

local special = { -- Stupid name mismatches in game.prefs and buildingtab.lua
    ["defenses"] = "defense",
    ["arty"] = "mobilearty",
    ["engystations"] = "engystation",
    ["mobileshields"] = "mobileshield"
}

local ignoreGroups = { -- Don't want to check these groups, they mess up some bindings
    "t3_armored_assault_bot",
    "t3_siege_assault_bot",
    "t3_tank",
    "t3_siege_tank"
}

local signs = {
    ["Comma"] = ",",
    ["Period"] = ".",
    ["Slash"] = "/",
    ["Backslash"] = "\\",
    ["NumPlus"] = "+",
    ["NumMinus"] = "-",
    ["NumStar"] = "*",
    ["NumSlash"] = "/",
    ["Quote"] = "'",
}

local colours = {
    [0] = "ffffffff",    -- White, no modifier
    [1] = "ff0088b2",    -- Blue, ctrl
    [2] = "ff217a13",    -- Green, alt
    [3] = "FFe80a0a",    -- Red, ctrl + alt
}

local textSizes = {
    -- Depends on amount of characters in the key name
    [1] = 18,
    [2] = 14,
    [3] = 14,
}

local orderDelegations = {
    attack =                {"attack"},
    shift_attack =          {"attack"},
    move =                  {"move"},
    shift_move =            {"move"},
    assist =                {"assist"},
    shift_assist =          {"assist"},
    guard =                 {"assist"},
    shift_guard =           {"assist"},
    stop =                  {"stop"},
    soft_stop =             {"stop"},
    patrol =                {"patrol"},
    shift_patrol =          {"patrol"},
    repair =                {"repair"},
    shift_repair =          {"repair"},
    capture =               {"capture"},
    shift_capture =         {"capture"},
    reclaim =               {"reclaim"},
    shift_reclaim =         {"reclaim"},
    overcharge =            {"overcharge"},

    teleport =              {"teleport"},
    dive =                  {"dive"},
    transport =             {"transport"},
    ferry =                 {"ferry"},
    sacrifice =             {"sacrifice"},
    dock =                  {"dock"},

    launch_tactical =       {"fire_tactical"},
    shift_launch_tactical = {"fire_tactical"},
    build_tactical =        {"build_tactical"},
    build_billy =           {"build_billy"},
    nuke =                  {"fire_nuke"},
    shift_nuke =            {"fire_nuke"},
    build_nuke =            {"build_nuke"},

    toggle_all =            {"toggle_shield","toggle_shield_dome","toggle_radar","toggle_sonar","toggle_omni",
                                "toggle_cloak","toggle_jamming","toggle_stealth_field","toggle_scrying"},

    toggle_intelshield =    {"toggle_shield","toggle_shield_dome","toggle_radar","toggle_sonar","toggle_omni"},
    toggle_shield =         {"toggle_shield"},
    toggle_shield_dome =    {"toggle_shield_dome"},

    toggle_cloakjammingstealth = {"toggle_cloak","toggle_jamming","toggle_stealth_field"},
    toggle_cloak =          {"toggle_cloak"},
    toggle_jamming =        {"toggle_jamming"},
    toggle_stealth_field =  {"toggle_stealth_field"},

    mode =                  {"mode"},

    toggle_intel =          {"toggle_radar", "toggle_sonar", "toggle_omni"},
    toggle_scrying =        {"toggle_scrying"},
    scry_target =           {"scry_target"},
}

local immutableOrderKeys = {
    attack_move =
        {
            ["key"] = 'RMB',
            ["colour"] = colours[2],
        }
}

function init()
    local idRelations, upgradeKey, orderKeys = getKeyTables()
    construction.setIdRelations(idRelations, upgradeKey)
    orders.setOrderKeys(orderKeys)
end

function onSelectionChanged(upgradesTo, isFactory)
    construction.setUpgradeAndAllowing(upgradesTo, isFactory)
end

function getKeyTables()
    local idRelations = {}
    local helpIdRelations = {}
    local otherRelations = {}
    local upgradeKey = nil
    local orderKeys = {}

    -- Get them from the building tab
    for groupName, groupItems in bt.buildingTab do
        local g = groupName.lower(groupName)
        if not isToBeIgnored(g) then
            for _, item in groupItems do
                local i = item.lower(item)
                if isBlueprintString(i) then
                    helpIdRelations[i] = g
                else
                    otherRelations[i] = g
                end
            end
        end
    end

    -- Go through buildingtab groups
    local changed = true
    while changed do
        changed = false
        for id, group in helpIdRelations do
            if otherRelations[group] then
                helpIdRelations[id] = otherRelations[group].lower(otherRelations[group])
                changed = true
            end
        end
    end

    helpIdRelations = resolveExceptions(helpIdRelations)

    -- Match user pref keymap
    local savedPrefs = Prefs.GetFromCurrentProfile("UserKeyMap")
    for key, action in savedPrefs or {} do
        local use, keyname, colour = getKeyUse(key) 
        if use then
            for id, action2 in helpIdRelations do
                if action2 == action then
                    idRelations[id] = {
                        ["key"] = keyname,
                        ["colour"] = colour,
                    }
                end
            end
            if orderDelegations[action] then
                for _, o in orderDelegations[action] do
                    orderKeys[o] = {
                        ["key"] = keyname,
                        ["colour"] = colour,
                    }
                end
            end
        end
        if action == "upgrades" then
            upgradeKey = {
                ["key"] = keyname,
                ["colour"] = colour,
            }
        end
    end
    
    orderKeys = table.merged(orderKeys, immutableOrderKeys)
    
    -- Rename signs
    for id0, metagroup in {idRelations, orderKeys} do
        for id1, group in metagroup do
            if signs[group.key] then
                metagroup[id1].key = signs[group.key]
            end
        end
    end

    if upgradeKey then
        if signs[upgradeKey.key] then
            upgradeKey.key = signs[upgradeKey.key]
        end
    end

    -- Remove unused ones (too long)
    for id0, metagroup in {idRelations, orderKeys} do
        for id1, group in metagroup do
            group["textsize"] = textSizes[string.len(group.key)]
            if not group["textsize"] then
                metagroup[id1] = nil
            end
        end    
    end

    if upgradeKey then
        upgradeKey["textsize"] = textSizes[string.len(upgradeKey.key)]
        if not upgradeKey["textsize"] then
            upgradeKey = nil
        end
    end

    return idRelations, upgradeKey, orderKeys
end

function resolveExceptions(t)
    -- Stupid exceptions
    for id, group in t do
        for sId, sGroup in special do
            local g = group:lower(group)
            if g == sId then
                t[id] = sGroup
            end
        end
    end

    return t
end

function isToBeIgnored(name)
    for _, iN in ignoreGroups do
        if name == iN then
            return true
        end
    end

    return false
end

function getKeyUse(key)
    local colour = 0
    if string.find(key, "Shift*") then
        -- No colour change for shift
        key = key.gsub(key, "Shift.", "")
    end

    if string.find(key, "Ctrl*") then
        colour = colour + 1
        key = key.gsub(key, "Ctrl.", "")
    end

    if string.find(key, "Alt*") then
        colour = colour + 2
        key = key.gsub(key, "Alt.", "")
    end

    return true, key, colours[colour]
end

function isBlueprintString(s)
    if s:len(s) ~= 7 then
        return false
    end

    if string.find(s, "...[0-9]+") then
        return true
    end

    return false
end
