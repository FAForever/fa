-- options logic code

local Prefs = import("/lua/user/prefs.lua")

-- contains the current options data
local options

-- handy mapping of keys to option items
local optionItemMap

-- returns the options table with any adjustments needed
function GetOptionsData()
    if not options then
        options = import("/lua/options/options.lua").options
        
        -- build option item map
        optionItemMap = {}
        for section, secInfo in options do
            for index, item in secInfo.items do
                if item.key then 
                    optionItemMap[item.key] = item
                end
            end
        end
        
        -- look for default overrides
        local overrides = GetPreference('options_overrides')
        if overrides then
            for section, secInfo in options do
                for index, item in secInfo.items do
                    if overrides[item.key] then
                        if overrides[item.key].default then
                            options[section]["items"][index].default = overrides[item.key].default
                        end
                        if overrides[item.key].custom then
                            options[section]["items"][index].custom = overrides[item.key].custom
                        end
                    end
                end
            end
        end
    end

    return options
end

-- returns a copy of the current options table, fills in with defaults if not found
-- also will create an options section if needed
function GetCurrent()
    local curOptions = Prefs.GetFromCurrentProfile('options')
    if not curOptions then curOptions = {} end  -- make a table if there aren't options yet
    local needSave = false
    for section, secInfo in GetOptionsData() do
        for index, item in secInfo.items do
            if curOptions[item.key] == nil then
                curOptions[item.key] = item.default
                needSave = true
            end
        end
    end
    if needSave then
        Prefs.SetToCurrentProfile('options', curOptions)
        SavePreferences()
    end
    return curOptions
end


-- this function will get called if a restart is needed for an option
-- it expects to be able to proceed or cancel
-- signature: func(proceedFunc, cancelFunc)
local summonRestartDialogCallback = nil

function SetSummonRestartDialogCallback(callback)
    summonRestartDialogCallback = callback
end

-- this function will get called if a verify dialog is needed for an option
-- it expects to be able to undo
-- signature: func(undoFunc)

local summonVerifyDialogCallback = nil

function SetSummonVerifyDialogCallback(callback)
    summonVerifyDialogCallback = callback
end

-- given a well formed options table, sets them in to the current options, and applies them
-- if compareOptions table is passed in, uses that to compare instead of current set
function SetCurrent(newOptions, compareOptions)
    local curOptions
    if compareOptions then
        curOptions = compareOptions
    else
        curOptions = GetCurrent()
    end
    
    local itemsToSet = {}
    local needsRestart = {}
    local needsVerify = {}
    
    for section, secInfo in GetOptionsData() do
        for index, item in secInfo.items do
            -- no need to place in lists if ignoring
            if item.ignore and item.ignore(newOptions[item.key]) then
                newOptions[item.key] = item.ignore(curOptions[item.key]) or curOptions[item.key]
            else
                if item.restart == true then
                    if newOptions[item.key] != curOptions[item.key] then
                        table.insert(needsRestart, item)
                    end
                end
                if item.verify == true then
                    if newOptions[item.key] != curOptions[item.key] then
                        table.insert(needsVerify, item)
                    end
                end
                if item.set then    -- only run set if it exists in this item
                    if newOptions[item.key] != curOptions[item.key] then
                        table.insert(itemsToSet, item)
                    end
                end
            end
        end
    end

    local function SetAndSave()
        for index, item in itemsToSet do
            item.set(item.key, newOptions[item.key], false)
        end

        -- don't save until after apply in case new options corrupt something
        Prefs.SetToCurrentProfile('options', newOptions)
        SavePreferences()
    end

    local setAndSaveOnExitFunction = true
    -- do restarts first, then do verifies
    if table.getn(needsRestart) != 0 then
        if summonRestartDialogCallback then
            setAndSaveOnExitFunction = false
            summonRestartDialogCallback(
                function()  -- proceed
                    -- no need to set, just save the options
                    Prefs.SetToCurrentProfile('options', newOptions)
                    SavePreferences()
                    ExitApplication()
                end,
                function()  -- cancel
                    -- revert changes to items that need restart
                    for key, val in curOptions do
                        newOptions[key] = curOptions[key]
                        SetValue(key, val, false)
                    end
                    SetAndSave()
                    Repopulate()
                end
            )
        end
    elseif table.getn(needsVerify) != 0 then
        if summonVerifyDialogCallback then
            summonVerifyDialogCallback(
                function() -- undo
                    for index, item in needsVerify do
                        newOptions[item.key] = curOptions[item.key]
                        SetValue(item.key, curOptions[item.key], true)
                    end
                    SetAndSave()
                end
            )
        end
    end
        
    if setAndSaveOnExitFunction == true then
        SetAndSave()
    end
end

-- calling this will cause all options to call their "set" functions which will 
-- cause all options that are not just pref values
function Apply(startup)
    startup = startup or false
    local curOptions = GetCurrent()
    for section, secInfo in GetOptionsData() do
        for index, item in secInfo.items do
            if item.set then
                item.set(item.key, curOptions[item.key], startup)
            end
        end
    end
end

-- resets all options to their default
function ResetToDefaults()
    local resetOptions = {}
    local compareOptions = GetCurrent()
    for section, secInfo in GetOptionsData() do
        for index, item in secInfo.items do
            resetOptions[item.key] = item.default
            -- reseting ignored values shouldn't trigger those values to update, just save them when SetCurrent is called (using its ignore logic)
            if item.ignore then
                if item.ignore(item.default) then
                    compareOptions[item.key] = item.default
                end
            end
            if item.cancel then
                item.cancel()
            end
        end
    end
    SetCurrent(resetOptions, compareOptions)
end

-- given an option key, finds the option item
function FindOptionItem(key)
    local optionItem = nil
    for section, secInfo in GetOptionsData() do
        for index, item in secInfo.items do
            if item.key == key then
                optionItem = item
                break
            end
        end
    end
    return optionItem
end

-- this can be set to allow updates to occur when the custom data is changed
-- function signature: func(optioneKey, newCustomData, newDefault)
local customDataChangedCallback = nil

function SetCustomDataChangedCallback(func)
    customDataChangedCallback = func
end

-- set new states for a given option, wholesale replaces custom data, so must be in correct format (see options.lua for format)
-- new default value is optional
function SetCustomData(optionKey, newCustomData, newDefault)
    -- find option with key
    local optionItem = FindOptionItem(optionKey)

    if not optionItem then
        LOG("optionsLogic:SetCustomData - attempt to set invalid option: " .. tostring(optionKey))
        return
    end
    
    optionItem.custom = newCustomData
    if newDefault then
        optionItem.default = newDefault
    end

    -- store the overrides to prefs, they will always get picked up until SetCustomData called again
    local overrides = GetPreference('options_overrides')
    if not overrides then overrides = {} end
    overrides[optionKey] = {}
    overrides[optionKey].default = newDefault;
    overrides[optionKey].custom = newCustomData;
    SetPreference('options_overrides', overrides)

    if nil != customDataChangedCallback then
        customDataChangedCallback(optionKey, newCustomData, newDefault)
    end
end

-- sets the option to a new value, and updates its control
function SetValue(optionKey, value, skipUpdate)
    -- find option with key
    local optionItem = FindOptionItem(optionKey)

    if not optionItem then
        LOG("optionsLogic:SetValue - attempt to set invalid option: " .. tostring(optionKey))
        return
    end
    
    if optionItem.change and optionItem.control then
		optionItem.change(optionItem.control, value, skipUpdate)
	end
end

-- call this if you need to repopulate runtime updated options
function Repopulate()
    local curOptions = GetCurrent()
    for section, secInfo in GetOptionsData() do
        for index, item in secInfo.items do
            if item.populate then
                local value
                if curOptions then
                    value = curOptions[item.key]
                else
                    value = item.default
                end
                item.populate(value)
            end
        end
    end
    
end