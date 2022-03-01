
local MapUtil = import('/lua/ui/maputil.lua')

--- Example of a set of options

--- Options using descriptive values
-- {
--   default=1,
--   help="<LOC aisettings_0148>Set the AIx global intel toggle",
--   key="OmniCheat",
--   label="<LOC aisettings_0147>AIx Omni Setting",
--   values={
--     {
--       help="<LOC aisettings_0150>Full map omni on",
--       key="on",
--       text="<LOC aisettings_0149>On"
--     },
--     {
--       help="<LOC aisettings_0152>Full map omni off",
--       key="off",
--       text="<LOC aisettings_0151>Off"
--     }
--   }
-- }

--- Options using simple values
-- {
--   default=11,
--   help="<LOC aisettings_0055>Set the build rate multiplier for the cheating AIs.",
--   key="BuildMult",
--   label="<LOC aisettings_0054>AIx Build Multiplier",
--   value_help="<LOC aisettings_0056>Build multiplier of %s",
--   value_text="%s",
--   values={
--     "1.0",
--     "1.1",
--     "1.2",
--     "1.3",
--     "1.4",
--     "1.5",
--     "1.6",
--     "1.7",
--     "1.8",
--     "1.9",
--     "2.0",
--   }
-- }


--- Returns a shallow copy of the team options
local function GetTeamOptions()
    return {title = "<LOC uilobby_0001>Team Options", options = import('/lua/ui/lobby/lobbyOptions.lua').teamOptions }
end

--- Returns a shallow copy of the global options
local function GetGlobalOptions()
    return {title = "<LOC uilobby_0002>Game Options", options = import('/lua/ui/lobby/lobbyOptions.lua').globalOpts }
end

--- Returns a shallow copy of the AI options
local function GetAIOptions()
    return {title = "<LOC uilobby_0003>AI Option", options = import('/lua/ui/lobby/lobbyOptions.lua').AIOpts }
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
        if not MapUtil.ValidateScenarioOptions(scenario.scenarioInfo.options, true) then
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
        local options = false 
        local ok, msg = pcall (
            function()
                local temp = { }
                doscript(path, temp)
                options = temp.Options or temp.AIOpts or false 
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
        if not ClashesWithBaseOptions(options) then 
            table.insert(out, { title = mod.name, options = options } )
        end
    end

    return out 
end

--- Retrieves all the options as a list of { title, options } 
-- @param scenario 
function GetOptions(scenario, mods)
    return table.concatenate(
        { GetTeamOptions() },
        { GetGlobalOptions() },
        { GetAIOptions() },
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
            flatHead = flatHead + 1 
        end
    end

    return flat, flatHead - 1
end

--- Maps the list of options to a list of key / default value pairs
-- @param options A flat table of options
function GetDefaultValues(options)
    local defaults = { }
    for k, option in options do 

        -- key is always at the same location
        local key = option.key 

        -- value can reside in two places
        local value = option.values[option.default].key
        if value == nil then 
            value = option.values[option.default]
        end

        defaults[key] = value 
    end

    return defaults
end

--- Adjusts the layout of the options to match the expected format for the map selection dialogue
-- @param hierarchy Expects the output of the function GetOptions
-- @param isSinglePlayer A boolean that indicates whether the game is single player or not
function ToMapDialogueOptions (hierarchy, isSinglePlayer)

    local options = { }
    local optionsh = 1

    for k, set in hierarchy do 

        -- exclude empty set of options
        if not (table.empty(set) or table.getn(set.options) == 0) then 

            options[optionsh] = {
                type = 'title', 
                text = set.title
            }

            optionsh = optionsh + 1

            for l, option in set.options do 

                -- exclude multiplayer-only options
                if not (isSinglePlayer and option.mponly) then 
                    options[optionsh] = {
                        type = 'option', 
                        text = option.label, 
                        data = option, 
                        default = option.default
                    }
                    
                    optionsh = optionsh + 1
                end 
            end
        end
    end 

    return options 
end

--- Adjusts the layout of the options to match the expected format for the lobby
-- @param hierarchy Expects the output of the function FlattenOptions
function ToLobbyOptions(options, selectedOptions, preset, isSinglePlayer)

    local allOptions = table.deepcopy(preset)
    local allOptionsh = table.getn(preset) + 1

    local nonDefaultOptions = table.deepcopy(preset)
    local nonDefaultOptionsh = table.getn(preset) + 1

    -- for each available option
    for k, option in options do 

        -- skip multiplayer-only options
        if option.mponly and isSinglePlayer then
            continue
        end

        -- get the value that we've selected
        local selectedValue = selectedOptions[option.key]

        -- find the entry that belongs to that value
        for l, val in option.values do

            local key = val.key or val
            if key == selectedValue then

                -- format the option accordingly
                local format = {
                    text = option.label,
                    tooltip = { text = option.label, body = option.help },
                    key = key,
                    value = val.text or option.value_text,
                    valueTooltip = { text = option.label, body = val.help or option.value_help }
                }

                -- store it here regardless
                allOptions[allOptionsh] = format 
                allOptionsh = allOptionsh + 1

                -- store it here if it isn't a default value
                if l ~= option.default then
                    nonDefaultOptions[nonDefaultOptionsh] = format 
                    nonDefaultOptionsh = nonDefaultOptionsh + 1
                end

                -- early exit when we've found our key
                break
            end
        end
    end

    return allOptions, nonDefaultOptions
end