--******************************************************************************************************
--** Copyright (c) 2024  FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local optionsLogic = import("/lua/options/optionslogic.lua")

--- Acts as a cache to prevent accessing the preference file.
---@type number | false
local CurrentProfileIndex = false

--- Acts as a cache to prevent allocating tables from the preference file.
---@type table | false
local CurrentProfiles = false

-- upvalue scope for performance
local GetPreference = GetPreference
local StringSplit = StringSplit

local StringFind = string.find

local TableGetn = table.getn
local TableEmpty = table.empty

--- Retrieves the (cached) index of the current profile. 
---@return number?  # nil when there are no profiles
local function GetCurrentProfileIndex()
    local current = GetPreference('profile.current')
    if not current then
        -- reset our cache
        CurrentProfileIndex = false
        CurrentProfiles = false
        return nil 
    end

    if current != CurrentProfileIndex then
        -- populate our cache
        CurrentProfileIndex = current
        CurrentProfiles = GetPreference('profile.profiles')
    end

    return current
end

-- Returns a boolean that indicates whether there are user profiles.
---@return boolean
function ProfilesExist()
    local profiles = GetPreference("profile.profiles")
    if (not profiles) or (TableEmpty(profiles)) then
        return false
    end
    return true
end

--- Returns the number of profiles.
---@return number
function GetProfileCount()
    local profiles = GetPreference("profile.profiles")
    if profiles then
        return TableGetn(profiles)
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

--- Returns the (cached) current profile. 
---@return table?   # nil when there are no profiles
function GetCurrentProfile()
    local currentProfileIndex = GetCurrentProfileIndex()
    if not currentProfileIndex then
        return nil
    end

    -- populate the cache if it does not exist
    if not CurrentProfiles then
        return nil
    end

    return CurrentProfiles[currentProfileIndex]
end

--- Returns a value from the current profile.
---@param fieldName string
---@return any
function GetFromCurrentProfile(fieldName)
    local currentProfile = GetCurrentProfile()
    if not currentProfile then
        return nil
    end

    -- fields can try to access subfields, as an example: `options.options_show_player_names`. This 
    -- pattern is actively discouraged, instead retrieve the initial field and manually search for sub fields,
    -- as an example:
    -- 
    -- - `GetFromCurrentProfile('options').options_show_player_names`

    if StringFind(fieldName, '.') then
        local field = currentProfile
        local fields = StringSplit(fieldName, '.')
        local fieldCount = TableGetn(fields)
        for k = 1, fieldCount do
            field = field[fields[k]]
        end

        return field
    else
        return currentProfile[fieldName]
    end
end

--- Returns a value from the current profile.
---@param fieldName string
---@return any
function GetFieldFromCurrentProfile(fieldName)
    local currentProfile = GetCurrentProfile()
    if not currentProfile then
        return nil
    end
    return currentProfile[fieldName]
end

--- Updates a value in the current profile.
---@param fieldName string
---@param data any
function SetToCurrentProfile(fieldName, data)
    local currentProfileIndex = GetCurrentProfileIndex()
    if not currentProfileIndex then
        return
    end

    if not CurrentProfiles then
        return
    end

    -- store the data and set the preference
    CurrentProfiles[currentProfileIndex][fieldName] = data
    SetPreference('profile.profiles', CurrentProfiles)
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


local OldSavePreferences = _G.SavePreferences
_G.SavePreferences = function()
    LOG(debug.traceback())
    OldSavePreferences()
end
