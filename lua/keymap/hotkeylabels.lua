-- This file is called from gamemain.lua when a game launches
-- It assigns unit IDs and order strings to the basic key (The key without modifiers) bound to them

local unitkeygroups = import("/lua/keymap/unitkeygroups.lua").unitkeygroups
local construction = import("/lua/ui/game/construction.lua")
local orders = import("/lua/ui/game/orders.lua")
local Prefs = import("/lua/user/prefs.lua")

-- Turn engine string reference to certain symbols into the actual symbol
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
    ["LeftBracket"] = "[", -- this key is the rightbracket for azerty
    ["RightBracket"] = "]",
    ["Chevron"] = "<", -- added for french keyboard
    ["Backtick"] = "`",
}

-- Which colour do we make the label? Shift is not taken into account here
local colours = {
    "ffffffff", -- White, no modifier
    "fffafa00", -- Yellow, ctrl
    "ffffbf80", -- Orange, alt
    "FFe80a0a", -- Red, ctrl + alt
}

-- Depends on amount of characters in the key name
local textSizes = {
    [1] = 18,
    [2] = 14,
    [3] = 14,
}

-- This table maps an action command to the tooltip of the button or buttons it corresponds to
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

-- Called from gamemain.lua
function init()
    local idRelations, upgradeKey, orderKeys = getKeyTables()
    construction.setIdRelations(idRelations, upgradeKey)
    orders.setOrderKeys(orderKeys)
end

-- Called from onSelectionChanged in gamemain.lua
function onSelectionChanged(upgradesTo, isFactory)
    construction.setUpgradeAndAllowing(upgradesTo, isFactory)
end

function getKeyTables()
    local idRelations = {}
    local helpIdRelations = {}
    local otherRelations = {}
    local upgradeKey = false
    local orderKeys = {}

    -- Get them from the building tab
    for groupName, groupItems in unitkeygroups do -- Since this file hardcodes all unit ids that can be affected by hotbuild, helpidrelations will get them all
        local g = groupName:lower()
        for _, item in groupItems do
            local i = item:lower()

            if __blueprints[i] then
                if not helpIdRelations[i] then
                    helpIdRelations[i] = {g}
                else
                    table.insert(helpIdRelations[i], g)
                end
            else
                if otherRelations[i] then
                    table.insert(otherRelations[i], g)
                else
                    otherRelations[i] = {g}
                end
            end
        end
    end

    -- Go through unitkeygroups to properly map IDs
    for id, group in pairs(helpIdRelations) do
        for key, value in group do
            if otherRelations[value] then -- Check if the group contained more than just unit IDs
                for ids, values in pairs(otherRelations[value]) do
                    table.insert(helpIdRelations[id], values:lower())
                end
            end
        end
    end

    -- Match user pref keymap
    local savedPrefs = Prefs.GetFromCurrentProfile("UserKeyMap")
    for keyCombo, action in savedPrefs or {} do
        local baseKey, colour = getKeyUse(keyCombo)  -- Returns the base key without modifiers, and a colour key to say which modifiers got removed (Were there)

        -- Handle unit IDs
        for id, group in pairs(helpIdRelations) do
            for key, value in group do
                if value == action then -- If it's an action that's assigned to a key at all, link the id to the key
                    idRelations[id] = {
                        ["key"] = baseKey,
                        ["colour"] = colour,
                    }
                end
            end
        end

        -- Handle orders
        if orderDelegations[action] then
            for _, o in orderDelegations[action] do
                orderKeys[o] = {
                    ["key"] = baseKey,
                    ["colour"] = colour,
                }
            end
        end

        -- Handle upgrades
        if action == "upgrades" then
            upgradeKey = {
                ["key"] = baseKey,
                ["colour"] = colour,
            }
        end
    end

    -- Rename signs for Unit ID list and orders
    for _, metagroup in {idRelations, orderKeys} do
        for id1, group in metagroup do
            if signs[group.key] then
                metagroup[id1].key = signs[group.key]
            end
        end
    end

    -- Handle signs for upgrades seperately
    if upgradeKey then
        if signs[upgradeKey.key] then
            upgradeKey.key = signs[upgradeKey.key]
        end
    end

    -- Remove unused ones (too long)
    for _, metagroup in {idRelations, orderKeys} do
        for id1, group in metagroup do
            group["textsize"] = textSizes[string.len(group.key)]
            if not group["textsize"] then
                WARN('Not showing label for keybind ' .. group.key .. ' due to length')
                metagroup[id1] = nil
            end
        end
    end

    -- Handle textsize for upgrades seperately
    if upgradeKey then
        upgradeKey["textsize"] = textSizes[string.len(upgradeKey.key)]
        if not upgradeKey["textsize"] then
            WARN('Not showing label for keybind ' .. upgradeKey.key .. ' due to length')
            upgradeKey = nil
        end
    end

    return idRelations, upgradeKey, orderKeys
end

-- Determine which modifier keys are present in the keybind string
function getKeyUse(key)
    local colour = 1
    if string.find(key, "Shift*") then
        -- No colour change for shift
        key = key:gsub("Shift.", "")
    end

    if string.find(key, "Ctrl*") then
        colour = colour + 1
        key = key:gsub("Ctrl.", "")
    end

    if string.find(key, "Alt*") then
        colour = colour + 2
        key = key:gsub("Alt.", "")
    end

    return key, colours[colour]
end
