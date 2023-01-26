--*****************************************************************************
--* File: lua/modules/ui/prefs.lua
--* Author: Chris Blackwell
--* Summary: Access to preferences that are used in the UI
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local optionsLogic = import("/lua/options/optionslogic.lua")

-- do not run any code in the scope of the file for mod compatibility with Alliance of Heroes and others

-- check if there are any profiles defined
function ProfilesExist()
    local profiles = GetPreference("profile.profiles")
    if (not profiles) or (table.empty(profiles)) then
        return false
    end
    return true
end

function GetProfileCount()
    local profiles = GetPreference("profile.profiles")
    if profiles then
        return table.getn(profiles)
    else
        return 0
    end
end

-- creates a profile and sets it as current
-- if it returns false, the name is already chosen
function CreateProfile(name)
    local profiles = GetPreference("profile.profiles")
    if not profiles then
        profiles = {}
    end

    local foundName = 0
    for key, value in profiles do
        if value.Name == name then
            foundName = key
        end
    end

    local primaryAdapter = GetOption('primary_adapter')
    local secondaryAdapter = GetOption('secondary_adapter')

    if primaryAdapter == 'overridden' then
        primaryAdapter = '1024,768,60'
    end

    if secondaryAdapter == 'overridden' then
        secondaryAdapter = 'disabled'
    end

    if foundName == 0 then
        table.insert(profiles, {Name = name})
        SetPreference("profile.current", table.getn(profiles)) -- table.insert adds to the end of the table
    else
        return false
    end

    SetPreference("profile.profiles", profiles)

    -- set default video options in to new profile, but don't actually cause any functions to get set
    SetToCurrentProfile('options', {primary_adapter = primaryAdapter, secondary_adapter = secondaryAdapter})

    SavePreferences()

    return true
end

function GetCurrentProfile()
    local current = GetPreference('profile.current')
    if not current then return nil end
    return GetPreference('profile.profiles.'..current)
end

-- Get the map last requested by the player
function GetFromCurrentProfile(fieldName)
    local current = GetPreference('profile.current')
    if not current then return nil end
    return GetPreference('profile.profiles.'..current..'.'..fieldName)
end

-- set the map
function SetToCurrentProfile(fieldName, data)
    local profile = GetPreference('profile')
    if profile.current then
        if profile.profiles[profile.current] then
            profile.profiles[profile.current][fieldName] = data
            SetPreference('profile', profile)
        end
    end
end

-- read from the current options set, find and return default if not available
function GetOption(optionKey)
    local ret = GetOptions(optionKey)

    if ret == nil then
        for section, secInfo in optionsLogic.GetOptionsData() do
            for index, item in secInfo.items do
                if item.key == optionKey then
                    ret = item.default
                    break
                end
            end
        end
    end

    return ret
end

function SetOption(optionKey, newValue)
    local tempOptionTable = optionsLogic.GetCurrent()

    for i, v in tempOptionTable do
        if i == optionKey then
            tempOptionTable[i] = newValue
            break
        end
    end

    optionsLogic.SetCurrent(tempOptionTable)
end
