
local MapUtil = import('/lua/ui/maputil.lua')

--- Returns a shallow copy of the team options
local function GetTeamOptions()
    return { {title = "<LOC uilobby_0001>Team Options", options = import('/lua/ui/lobby/lobbyOptions.lua').teamOptions } }
end

--- Returns a shallow copy of the global options
local function GetGlobalOptions()
    return { {title = "<LOC uilobby_0002>Game Options", options = import('/lua/ui/lobby/lobbyOptions.lua').globalOpts } }
end

--- Returns a shallow copy of the AI options
local function GetAIOptions()
    return { {title = "<LOC uilobby_0003>AI Option", options = import('/lua/ui/lobby/lobbyOptions.lua').AIOpts } }
end

--- Validates the default values of the given table of options 
-- @param options Table of options to validate
local function ValidateOptions(options)

    -- no options are valid options
    if not options then
        return true
    end

    -- verify default values of options
    local valid = true 
    for k, option in options do
        
        -- if there is no default, set it to 1
        if not option.default then
            option.default = 1
            WARN("No default option set for: " .. tostring(option.key))
            valid = false 
        end

        if  type(option.default) ~= "number" or         -- options are indices
            option.default <= 0 or                      -- index can't be negative
            option.default > table.getn(option.values)  -- index can't be more than the values we have
            then

            WARN("Invalid default option set for: " .. tostring(option.key))
            valid = false 

            -- try to recover
            local replacementValue = 1
            for k, v in option.values do
                if v.key == option.default then
                    replacementValue = k
                    break
                end
            end

            option.default = replacementValue
        end
    end

    return valid 
end

--- Checks whether the provided options clashes with the base game options (team / game / default ai options)
-- @param options Options to check for a clash
local function ClashesWithBaseOptions(options)

    -- retrieve options to check for clashes
    local teamOptions = GetTeamOptions()
    local globalOptions = GetGlobalOptions()
    local AIOptions = GetAIOptions()

    local function CheckIndividualOption(option, alts)
        for k, alt in alts do 
            if alt.key == option.key then
                return option.key 
            end
        end
    end

    -- check for clashing of options
    local clashed = false 
    for k, option in options do 
        local isClashing, key

        isClashing, key = CheckIndividualOption(option, teamOptions.options)
        if isClashing then 
            WARN("The following key is clashing with a key of the team options: " .. tostring(key) .. ", skipping options.")
            clashed = true 
        end

        isClashing, key = CheckIndividualOption(option, globalOptions.options)
        if isClashing then 
            WARN("The following key is clashing with a key of the global options: " .. tostring(key) .. ", skipping options.")
            clashed = true 
        end

        isClashing, key = CheckIndividualOption(option, AIOptions.options)
        if isClashing then 
            WARN("The following key is clashing with a key of the default AI options: " .. tostring(key) .. ", skipping options.")
            clashed = true 
        end
    end

    return clashed
end

--- Returns a shallow copy of the map options, if available
local function GetMapOptions(scenario)
    if scenario.options then 

        -- validate options because people make mistakes
        if not MapUtil.ValidateScenarioOptions(scenarioscenarioInfo.options, true) then
            AddChatText("Invalid map options for: " .. tostring(scenario.name) .. ", better check them to be safe.")
        end

        -- if we don't clash, add it in
        if not ClashesWithBaseOptions(scenario.options) then 
            return { {title = "<LOC lobui_0164>Advanced", options = import('/lua/ui/lobby/lobbyOptions.lua').teamOptions } }
        end
    end

    -- no scenario options
    return { }
end

--- Returns a shallow copy of the mod options, if available
-- @param mods List of mods to retrieve options for
local function GetModOptions(mods)

    local out = { }

    for k, mod in mods do 

        local directory = mod.location

        -- look at expected location
        local file = 'mod_options.lua'
        local path = directory .. '/' .. file 
        if not DiskGetFileInfo(path) then

            -- try old location
            file = '/lua/AI/LobbyOptions/lobbyoptions.lua'
            path = directory .. '/' .. file 
            if not DiskGetFileInfo(path) then 
                continue 
            end
        end

        -- try and load in the options
        local options = { } 
        local ok, msg = pcall (
            function()
                doscript(path, options)
            end
        )

        -- report back if it failed
        if not ok then 
            AddChatText("Failed to load options for mod: " .. tostring(mod.name))
            WARN("Failed to load options for mod: " .. mod.name)
            WARN(msg)
            continue 
        end

        -- validate options
        if not ValidateOptions(options) then 
            AddChatText("Invalid mod options for: " .. tostring(mod.name) .. ", better check them to be safe.")
        end

        -- if we don't clash, add it in
        if not ClashesWithBaseOptions(scenario.options) then 
            table.insert(out, { title = mod.name, options = options } )
        end
    end

    return out 
end

--- Retrieves all the options as a list of { title, options } 
-- @param scenario 
function GetOptions(scenario, mods)
    return table.concatenate(
        GetTeamOptions(),
        GetGlobalOptions(),
        GetAIOptions(),
        GetMapOptions(scenario),
        GetModOptions(mods)
    )
end

--- Removes the title / options structure and returns a flat list of all the options, returns a shallow copy of the options
-- @param hierarchy Expects the output of the function GetOptions
function FlattenOptions(hierarchy)
    local flatHead = 1
    local flat = { }
    for k, element in hierarchy do 
        for l, option in element.options do 
            flat[flatHead] = option 
            flat = flat + 1 
        end
    end

    return flat, flatHead - 1
end

--- Maps the list of options to a list of key / default value pairs
-- @param options A flat table of options
function GetDefaultValues(options)

end