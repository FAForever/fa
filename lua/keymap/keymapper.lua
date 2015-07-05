--*****************************************************************************
--* File: lua/keymap/keymapper.lua
--* Author: Chris Blackwell
--* Summary: Utility functions to map keys to actions
--*
--* Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local Prefs = import('/lua/user/prefs.lua')

function GetDefaultKeyMap(includeDebugKeys)
    local ret = {}
    local defaultKeyMap = import('defaultKeyMap.lua').defaultKeyMap
    local debugKeyMap = import('defaultKeyMap.lua').debugKeyMap
    
    for k,v in defaultKeyMap do
        ret[k] = v
    end
    

    for k,v in debugKeyMap do
        ret[k] = v
    end

    
    return ret
end

function GetUserKeyMap(includeDebugKeys)
    local ret = {}
    local userKeyMap = Prefs.GetFromCurrentProfile("UserKeyMap")
    
    if not userKeyMap then return nil end
    
    for k,v in userKeyMap do
        ret[k] = v
    end
    

    local userDebugKeyMap = Prefs.GetFromCurrentProfile("UserDebugKeyMap")
    if not userDebugKeyMap then
        userDebugKeyMap = import('defaultKeyMap.lua').debugKeyMap
    end

    if userDebugKeyMap then
        for k,v in userDebugKeyMap do
            ret[k] = v 
        end
    end

    return ret
end

function GetUserDebugKeyMap()
    local ret = {}
    local UserDebugKeyMap = Prefs.GetFromCurrentProfile("UserDebugKeyMap")
    
    if not UserDebugKeyMap then return nil end
    
    for k,v in UserDebugKeyMap do
        ret[k] = v
    end
    return ret
end

function GetCurrentKeyMap(includeDebugKeys)
    return GetUserKeyMap(true) or GetDefaultKeyMap(true)
end

function ClearUserKeyMapping(key)
    
    local newUserMap = GetCurrentKeyMap(false)
    local newDebugMap = GetUserDebugKeyMap()
    if not newDebugMap then
        newDebugMap = import('defaultKeyMap.lua').debugKeyMap
    end

    if IsKeyInMap(key, newDebugMap) then
        LOG("clearing debug key ".. key)
        newDebugMap[key] = nil
    elseif IsKeyInMap(key, newUserMap) then
        LOG("clearing key ".. key)
        newUserMap[key] = nil
    end

    Prefs.SetToCurrentProfile("UserKeyMap", newUserMap)
    Prefs.SetToCurrentProfile("UserDebugKeyMap", newDebugMap)
end

function SetUserKeyMapping(key, oldKey, action)
    ClearUserKeyMapping(key)
    local newUserMap = GetCurrentKeyMap(false)
    local newDebugMap = GetUserDebugKeyMap()
    if not newDebugMap then
        newDebugMap = import('defaultKeyMap.lua').debugKeyMap
    end

    if oldKey != nil then
        if IsKeyInMap(oldKey, newDebugMap) then
            newDebugMap[oldKey] = nil
        elseif IsKeyInMap(oldKey, newUserMap) then
            newUserMap[oldKey] = nil
        end
    end

    if IsActionInMap(action, newUserMap) or IsActionInMap(action, import('defaultKeyMap.lua').defaultKeyMap) then
        LOG("adding key "..key .. " in user map")
        newUserMap[key] = action
    elseif IsActionInMap(action, newDebugMap) or IsActionInMap(action, import('defaultKeyMap.lua').debugKeyMap) then
        LOG("adding key "..key .. " in user map debug")
        newDebugMap[key] = action
    else
        LOG("adding key "..key .. " in user map")
        newUserMap[key] = action
    end

    Prefs.SetToCurrentProfile("UserKeyMap", newUserMap)
    Prefs.SetToCurrentProfile("UserDebugKeyMap", newDebugMap)

end

function ClearUserKeyMap()
    Prefs.SetToCurrentProfile("UserKeyMap", nil)
    Prefs.SetToCurrentProfile("UserDebugKeyMap", nil)
end

function GetKeyActions(includeDebugKeys)
    local ret = {}

    local keyActions = import('keyactions.lua').keyActions
    local debugKeyActions = import('keyactions.lua').debugKeyActions
    
    for k,v in keyActions do
        ret[k] = v
    end
    

    for k,v in debugKeyActions do
        ret[k] = v
    end


    local userActions = Prefs.GetFromCurrentProfile("UserKeyActions")
    if userActions != nil then
        for k,v in userActions do
            ret[k] = v
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

-- returns keys mapped to actions
function GetKeyMappings(includeDebugKeys)
    local currentKeyMap = GetCurrentKeyMap(true)
    local keyActions = GetKeyActions(true)    
    local keyMap = {}

    -- set up default mapping
    for key, action in currentKeyMap do
        keyMap[key] = keyActions[action]
        if keyMap[key] == nil then
            WARN("Key action not found " .. action .. " for key " .. key)
        end
    end
    
    return keyMap
end

-- returns action names mapped to keys
function GetKeyLookup()
    local currentKeyMap = GetCurrentKeyMap(true)
    
    -- get default keys
    local ret = {}
    for k,v in currentKeyMap do
        ret[v] = k    
    end

    return ret
end

-- returns a table of raw (windows) key codes mapped to key names
function GetKeyCodeLookup()
    local ret = {}
    local keyCodeTable = import('/lua/keymap/keynames.lua').keyNames
    for k, v in keyCodeTable do
        local codeInt = STR_xtoi(k)
        ret[codeInt] = v
    end
    return ret
end

    -- given a key string makes it always ctrl-shift-alt-key for comparison
    -- returns a table with modifier keys extracted
function NormalizeKey(inKey)
    local retVal = {}
    local keyNames = import('/lua/keymap/keyNames.lua').keyNames
    local modKeys = {[keyNames['11']] = true, -- ctrl
                     [keyNames['10']] = true, -- shift
                     [keyNames['12']] = true, -- alt
                    }
                    
    local startpos = 1
    while startpos do
        local fst, lst = string.find(inKey, "-", startpos)
        local str
        if fst then
            str = string.sub(inKey, startpos, fst - 1)
            startpos = lst + 1
        else
            str = string.sub(inKey, startpos, string.len(inKey))
            startpos = nil
        end
        if modKeys[str] then
            retVal[str] = true
        else
            retVal["key"] = str
        end
    end
    return retVal
end

-- given a key in string form, checks to see if it's already in the key map
function IsKeyInMap(key, map)
    local compKeyCombo = NormalizeKey(key)
    for keyCombo, action in map do
        local curKeyCombo = NormalizeKey(keyCombo)
        if table.equal(curKeyCombo, compKeyCombo) then
            return true
        end    
    end
    
    return false
end

-- given an action in string form, checks to see if it's already in the key map
function IsActionInMap(action, map)
    LOG("checking " .. action)
    for keyCombo, curaction in map do
        if action == curaction then
            return true
        end    
    end
    
    return false
end

function KeyCategory(key, map, actions)
    local compKeyCombo = NormalizeKey(key)
    -- return the category of a key
    for keyCombo, action in map do
        local curKeyCombo = NormalizeKey(keyCombo)
        if table.equal(curKeyCombo, compKeyCombo) then
            if actions[action] != nil then
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