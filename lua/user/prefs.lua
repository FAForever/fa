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

-- do not run any code in the scope of the file for mod compatibility with Alliance of Heroes and others

-- check if there are any profiles defined
---@return boolean
function ProfilesExist()
    local profiles = GetPreference("profile.profiles")
    if (not profiles) or (table.empty(profiles)) then
        return false
    end
    return true
end

---@return number
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
---@return boolean
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
        table.insert(profiles, { Name = name })
        SetPreference("profile.current", table.getn(profiles)) -- table.insert adds to the end of the table
    else
        return false
    end
    SetPreference("profile.profiles", profiles)
    -- set default video options in to new profile, but don't actually cause any functions to get set
    SetToCurrentProfile('options', { primary_adapter = primaryAdapter, secondary_adapter = secondaryAdapter })
    SavePreferences()
    return true
end

---@return table?
function GetCurrentProfile()
    local current = GetPreference('profile.current')
    if not current then return nil end
    return GetPreference('profile.profiles.' .. current)
end

-- Get the map last requested by the player
---@return any
function GetFromCurrentProfile(fieldName)
    local current = GetPreference('profile.current')
    if not current then return nil end
    return GetPreference('profile.profiles.' .. current .. '.' .. fieldName)
end

--- Returns a value from the current profile.
---@deprecated
---@param fieldName string
---@return any
function GetFieldFromCurrentProfile(fieldName)
    return GetFromCurrentProfile(fieldName)
end

--- Updates a value in the current profile.
---@param fieldName string
---@param data any
function SetToCurrentProfile(fieldName, data)
    local profile = GetPreference('profile')
    if profile.current then
        if profile.profiles[profile.current] then
            profile.profiles[profile.current][fieldName] = data
            SetPreference('profile', profile)
        end
    end
end

-- Retrieves an option. Returns the default value if the option does not exist.
---@param optionKey string
function GetOption(optionKey)
    local ret = GetOptions(optionKey)

    -- try to find the default value
    if ret == nil then
        for section, secInfo in import("/lua/options/optionslogic.lua").GetOptionsData() do
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

--- Updates an option
---@param optionKey string
---@param newValue any
function SetOption(optionKey, newValue)
    local tempOptionTable = import("/lua/options/optionslogic.lua").GetCurrent()
    for i, v in tempOptionTable do
        if i == optionKey then
            tempOptionTable[i] = newValue
            break
        end
    end

    import("/lua/options/optionslogic.lua").SetCurrent(tempOptionTable)
end
