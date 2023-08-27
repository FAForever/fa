-----------------------------------------------------------------
-- File: lua/keymap/keymapper.lua
-- Author: Chris Blackwell
-- Summary: Utility functions to map keys to actions
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- This file is called on game start from gamemain.lua to fetch keybindings from prefs, or generate them from defaults
-- It is also used by hotbuild.lua to fetch existing mappings

local Prefs = import("/lua/user/prefs.lua")
local KeyDescriptions = import("/lua/keymap/keydescriptions.lua").keyDescriptions

function GetActionName(action)
    local name = ''
    if KeyDescriptions[action] then
        name = LOC(KeyDescriptions[action])
    else
        name = LOC('<LOC kb_'..action..'>'..action)
    end
    -- check if action is meant to be mapped with a key modifier, e.g. attack vs shift_attack action
    if string.find(action, 'shift_') == 1 then
        name = name .. ' - SHIFT version'
    end
    return name
end

function GetDefaultKeyMapName()
    return Prefs.GetFromCurrentProfile("UserKeyMapName") or "/lua/keymap/defaultkeymap.lua"
end

-- stores preset name of UserKeyMap: 'defaultKeyMap.lua' (GPG) or 'hotbuildKeyMap.lua' (FAF) or 'alternatehotbuildKeyMap.lua' (FAF)
function SetDefaultKeyMapName(preset)
    Prefs.SetToCurrentProfile("UserKeyMapName", preset)
end

function GetDefaultKeyMap()
    local ret = {}
    local defaultKeyMap = import(GetDefaultKeyMapName()).defaultKeyMap
    local debugKeyMap = import(GetDefaultKeyMapName()).debugKeyMap

    for k,v in defaultKeyMap do
        ret[k] = v
    end

    for k,v in debugKeyMap do
        ret[k] = v
    end

    return ret
end

function GetUserKeyMap()
    local ret = {}
    local userKeyMap = Prefs.GetFromCurrentProfile("UserKeyMap")

    if not userKeyMap then return nil end

    for k,v in userKeyMap do
        ret[k] = v
    end

    local debugKeyMap = Prefs.GetFromCurrentProfile("UserDebugKeyMap")
    if not debugKeyMap then
        debugKeyMap = import(GetDefaultKeyMapName()).debugKeyMap
    end

    if debugKeyMap then
        for k,v in debugKeyMap do
            ret[k] = v
        end
    end

    return ret
end

function GetUserDebugKeyMap()
    local ret = {}
    local debugKeyMap = Prefs.GetFromCurrentProfile("UserDebugKeyMap")

    if not debugKeyMap then
        debugKeyMap = import(GetDefaultKeyMapName()).debugKeyMap
    end

    for k,v in debugKeyMap do
        ret[k] = v
    end
    return ret
end

function GetCurrentKeyMap()
    return GetUserKeyMap() or GetDefaultKeyMap()
end

--- Returns the current key binding for an action, or `false` if not found
---@param action string
---@return string | false
function GetCurrentKeyBinding(action)
    local TableFind = table.find -- luckily, this handles nil tables

    local binding = TableFind(Prefs.GetFromCurrentProfile("UserKeyMap"), action)
    if binding then return binding end
    binding = TableFind(Prefs.GetFromCurrentProfile("UserDebugKeyMap"), action)
    if binding then return binding end

    local defaultKeyMap = import(GetDefaultKeyMapName())

    binding = TableFind(defaultKeyMap.defaultKeyMap, action)
    if binding then return binding end
    binding = TableFind(defaultKeyMap.debugKeyMap, action)
    if binding then return binding end

    return false
end

function ClearUserKeyMapping(key)
    if not key then return end

    local newUserMap = GetCurrentKeyMap()
    local newDebugMap = GetUserDebugKeyMap()

    if IsKeyInMap(key, newDebugMap) then
        LOG("Keybindings clearing debug key ".. key)
        newDebugMap[key] = nil
    elseif IsKeyInMap(key, newUserMap) then
        LOG("Keybindings clearing action key ".. key)
        newUserMap[key] = nil
    end

    Prefs.SetToCurrentProfile("UserKeyMap", newUserMap)
    Prefs.SetToCurrentProfile("UserDebugKeyMap", newDebugMap)
end

function SetUserKeyMapping(key, oldKey, action)
    if not key or not action then return end

    ClearUserKeyMapping(key)
    local newUserMap = GetCurrentKeyMap()
    local newDebugMap = GetUserDebugKeyMap()

    if oldKey ~= nil then
        if IsKeyInMap(oldKey, newDebugMap) then
            newDebugMap[oldKey] = nil
        elseif IsKeyInMap(oldKey, newUserMap) then
            newUserMap[oldKey] = nil
        end
    end

    if IsActionInMap(action, newUserMap) or IsActionInMap(action, import("/lua/keymap/defaultkeymap.lua").defaultKeyMap) then
        LOG('Keybindings adding key "'..key .. '" in user map for action: ' .. action)
        newUserMap[key] = action
    elseif IsActionInMap(action, newDebugMap) or IsActionInMap(action, import("/lua/keymap/defaultkeymap.lua").debugKeyMap) then
        LOG('Keybindings adding key "'..key .. '" in debug map for action: ' .. action)
        newDebugMap[key] = action
    else
        LOG('Keybindings adding key "'..key .. '" in user map for action: ' .. action)
        newUserMap[key] = action
    end

    Prefs.SetToCurrentProfile("UserKeyMap", newUserMap)
    Prefs.SetToCurrentProfile("UserDebugKeyMap", newDebugMap)
end

function ClearUserKeyMap()
    Prefs.SetToCurrentProfile("UserKeyMap", nil)
    Prefs.SetToCurrentProfile("UserDebugKeyMap", nil)
end

-- resets UserKeyMap in game references file and saves new keybinding preset: 'defaultKeyMap.lua' (GPG) or hotbuildKeyMap.lua' (FAF) or 'alternatehotbuildKeyMap.lua' (FAF)
function ResetUserKeyMapTo(newPreset)
    local oldPreset = GetDefaultKeyMapName()
    LOG('Keybindings Preset changed from "' .. oldPreset .. '" to "' .. newPreset .. '"')
    Prefs.SetToCurrentProfile("UserKeyMapName", newPreset)
    local oldKeyMap = Prefs.GetFromCurrentProfile("UserKeyMap")
    if not table.empty(oldKeyMap) then
        LOG('Keybindings Count changed from ' .. table.getsize(oldKeyMap) .. ' to 0')
    end
     -- key maps must be nil until they are save by a user when existing keybinding UI otherwise UI will show incorrect info
    Prefs.SetToCurrentProfile("UserKeyMap", nil)
    Prefs.SetToCurrentProfile("UserDebugKeyMap", nil)
end

-- saves current UserKeyMap to game references file
function SaveUserKeyMap()
    local oldKeyMap = Prefs.GetFromCurrentProfile("UserKeyMap")
    local newKeyMap = GetCurrentKeyMap()
    if table.getsize(oldKeyMap) ~= table.getsize(newKeyMap) then
        LOG('Keybindings Count changed from ' .. table.getsize(oldKeyMap) .. ' to ' .. table.getsize(newKeyMap))
    end
    Prefs.SetToCurrentProfile("UserKeyMap", newKeyMap)
    Prefs.SetToCurrentProfile("UserDebugKeyMap", GetUserDebugKeyMap())
end

function GetKeyActions()
    local ret = {}

    -- load actions from preference file
    local userActions = Prefs.GetFromCurrentProfile("UserKeyActions")
    if userActions ~= nil then
        for k,v in userActions do
            ret[k] = v
        end
    end

    -- load default keyactions, overwrite those in the preference when applicable
    local keyActions = import("/lua/keymap/keyactions.lua").keyActions
    local debugKeyActions = import("/lua/keymap/debugkeyactions.lua").debugKeyActions

    for k,v in keyActions do
        if ret[k] and ret[k] != v.action then
            WARN(string.format("Overwriting user key action: %s -> %s", k, ret[k].action))
        end

        ret[k] = v
    end

    for k,v in debugKeyActions do
        if ret[k] and ret[k] != v.action then
            WARN(string.format("Overwriting user key action: %s -> %s", k, ret[k].action))
        end

        ret[k] = v
    end

    for k,v in ret do
        if string.find(k, '-') then
            WARN(string.format("Removed invalid key action '%s' for using '-'", k))
            ret[k] = nil
        end
    end

    return ret
end

function SetUserKeyAction(actionName, actionTable)
    local newActions = Prefs.GetFromCurrentProfile("UserKeyActions") or {}
    newActions[actionName] = actionTable
    Prefs.SetToCurrentProfile("UserKeyActions", newActions)
end

function ClearUserKeyActions()
    Prefs.SetToCurrentProfile("UserKeyActions", nil)
end

-- Returns keys mapped to actions
function GetKeyMappings()
    local currentKeyMap = GetCurrentKeyMap()
    local keyActions = GetKeyActions()
    local keyMap = {}

    -- Set up default mapping
    for key, action in currentKeyMap do
        keyMap[key] = keyActions[action]
        if keyMap[key] == nil then
            WARN('Keybindings cannot find action "' .. action .. '" for key ' .. key)
        end
    end

    return keyMap
end

-- Returns details for keys mapped to actions
function GetKeyMappingDetails()
    local keyMap = GetCurrentKeyMap()
    local keyActions = GetKeyActions()
    local ret = {}
    for key, action in keyMap do
        if keyActions[action] then
            local info = {}
            info.name = GetActionName(action)
            info.action = keyActions[action]
            info.category = string.upper(keyActions[action].category or 'none')
            info.key = key
            info.id = action
            ret[key] = info
        end
    end
    return ret
end

-- Returns key mappings with modifier shortcuts generated on the fly based on current hotbuild mappings
function GenerateHotbuildModifiers()
    local keyDetails = GetKeyMappingDetails()
    local modifiers = {}

    for key, info in keyDetails do
        local cat = info.action["category"]
        if cat == "hotbuilding" or cat == "hotbuildingAlternative" or cat == "hotbuildingExtra" then
            if key ~= nil then
                local shiftModKey = "Shift-" .. key
                local altModKey = "Alt-" .. key
                local shiftModBinding = keyDetails[shiftModKey]
                local altModBinding = keyDetails[altModKey]
                if not shiftModBinding and not altModBinding then
                    modifiers[shiftModKey] =  info.action
                    modifiers[altModKey] =  info.action
                elseif not shiftModBinding then
                    modifiers[shiftModKey] =  info.action
                    WARN('Hotbuild key '..altModKey..' is already bound to action "'..altModBinding.name..'" under "'..altModBinding.category..'" category')
                elseif not altModBinding then
                    modifiers[altModKey] =  info.action
                    WARN('Hotbuild key '..shiftModKey..' is already bound to action "'..shiftModBinding.name..'" under "'..shiftModBinding.category..'" category')
                else
                    WARN('Hotbuild key '..shiftModKey..' is already bound to action "'..shiftModBinding.name..'" under "'..shiftModBinding.category..'" category')
                    WARN('Hotbuild key '..altModKey..' is already bound to action "'..altModBinding.name..'" under "'..altModBinding.category..'" category')
                end
            end
        end
    end
    return modifiers
end

-- Returns action names mapped to keys
function GetKeyLookup()
    local currentKeyMap = GetCurrentKeyMap()

    -- Get default keys
    local ret = {}
    for k,v in currentKeyMap do
        ret[v] = k
    end

    return ret
end

-- Returns a table of raw (windows) key codes mapped to key names
function GetKeyCodeLookup()
    local ret = {}
    local keyCodeTable = import("/lua/keymap/keynames.lua").keyNames
    for k, v in keyCodeTable do
        local codeInt = STR_xtoi(k)
        ret[codeInt] = v
    end

    return ret
end

---@class NormalizedKeyBinding
---@field key string
---@field Ctrl? true
---@field Shift? true
---@field Alt? true

--- Given a key string makes it always Ctrl-Shift-Alt-key for comparison
--- Returns a table with modifier keys extracted
---@param inKey string
---@return string
function NormalizeKeyBinding(inKey)
    local ctrl, alt, shift = false, false, false
    local norm = ""
    inKey:gsub("([^-]+)", function(c)
        if c == "Ctrl" then
            ctrl = true
        elseif c == "Shift" then
            shift = true
        elseif c == "Alt" then
            alt = true
        else
            norm = c
        end
    end)
    -- build backwards
    if norm ~= "Alt" and alt then norm = "Alt-" .. norm end
    if norm ~= "Shift" and shift then norm = "Shift-" .. norm end
    if norm ~= "Ctrl" and ctrl then norm = "Ctrl-" .. norm end
    return norm
end

--- Given a key string returns a table with modifier keys extracted
---@param inKey string
---@return NormalizedKeyBinding
function NormalizeKey(inKey)
    local norm = {}
    inKey:gsub("([^-]+)", function(c)
        if c == "Ctrl" then
            norm.Ctrl = true
        elseif c == "Shift" then
            norm.Shift = true
        elseif c == "Alt" then
            norm.Alt = true
        else
            norm.key = c
        end
    end)
    return norm
end

-- TODO: reconcile with `/lua/ui/dialogs/keybindings.lua#FormatKeyName`
function LocalizeKeyName(inKey)
    local ctrl, alt, shift = false, false, false
    local norm = ""
    inKey:gsub("([^-]+)", function(c)
        if c == "Ctrl" then
            ctrl = true
        elseif c == "Shift" then
            shift = true
        elseif c == "Alt" then
            alt = true
        else
            norm = c
        end
    end)
    -- build backwards
    local properKeyNames = import("/lua/keymap/properkeynames.lua").properKeyNames
    if norm ~= "Alt" and alt then
        norm = LOC(properKeyNames.Alt) .. "+" .. norm
    end
    if norm ~= "Shift" and shift then
        norm = LOC(properKeyNames.Shift) .. "+" .. norm
    end
    if norm ~= "Ctrl" and ctrl then
        norm = LOC(properKeyNames.Ctrl) .. "+" .. norm
    end
    return norm
end

-- Given a key in string form, checks to see if it's already in the key map
function IsKeyInMap(key, map)
    key = NormalizeKeyBinding(key)
    for keyCombo, action in map do
        if key == NormalizeKeyBinding(keyCombo) then
            return action
        end
    end
    return false
end

-- Given an action in string form, checks to see if it's already in the key map
function IsActionInMap(action, map)
    for key, curaction in map do
        if action == curaction then
            return key
        end
    end
    return false
end

-- Return a shift action (if exists) for specified action name, e.g. 'shift_attack' for 'attack' action
function GetShiftAction(actionName, category)
    local keyActions = GetKeyActions()
    local keyLookup = GetKeyLookup()

    local name = 'shift_' .. actionName
    local action = keyActions[name]
    if action  and action.category == category then
        action.name = name
        action.key = keyLookup[name]
        return action
    end
    return false
end

function ContainsKeyModifiers(key)
    return StringStarts(key, 'Shift') or StringStarts(key, 'Ctrl') or StringStarts(key, 'Alt')
end

function KeyCategory(key, map, actions)
    local compKeyCombo = NormalizeKey(key)
    -- Return the category of a key
    for keyCombo, action in map do
        local curKeyCombo = NormalizeKey(keyCombo)
        if table.equal(curKeyCombo, compKeyCombo) then
            if actions[action] ~= nil then
                if actions[action].category then
                    return actions[action].category
                else
                    return false
                end
            end
        end
    end

    return false
end
