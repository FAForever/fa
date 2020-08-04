
local Mods = import('/lua/mods.lua')
local OptionUtils = import('/lua/ui/optionutil.lua')

-- used to detect team / game / ai <-> mod option clashes
local globalOpts = import('/lua/ui/lobby/lobbyOptions.lua').globalOpts
local teamOpts = import('/lua/ui/lobby/lobbyOptions.lua').teamOptions
local AIOpts = import('/lua/ui/lobby/lobbyOptions.lua').AIOpts

-- Returns a table of tables where each subtable contains a list of 
-- options along with the name of the mod. The format is:
-- { 
--     {
--         title,  (string)
--         options (table)
--     }
--     {
--         title,  (string)
--         options (table)
--     }
--     ...
-- }

-- {
--     { 
--         type = title
--         text = string
--     }
--     {
--         type = subtitle
--         text = string
--     }
--     {
--         type = spacer
--     }
--     {
--         type = option
--         option = {
--             ...
--         }
--     }
-- }

-- {
--     title = string
--     options = {
--         ...
--     }
-- }

-- which gets converted to

-- {
--     { 
--         type = title
--         text = string
--     }
--     {
--         {
--             type = option
--             text = optionData.label
--             data = optionData
--             default = optionData.default
--         }
--         ...
--     }
--     ...
-- }


-- {
--     {
--         type = subtitle
--         text = string 
--     }
--     {
--         type = option
--         text = optionData.label
--         data = optionData
--         default = optionData.default
--     }
--     ...
-- }
function LoadModOptionsFormatted()

    -- returns a function that given an option, checks if they key matches.
    local function CheckForClash(option, key)
        return option.key == key
    end

    -- get the selected game mods
    local mods = Mods.GetGameMods()

    -- load in the options file for each mod
    local options = { }
    for k, mod in mods do 

        -- add in the subtitle
        table.insert(options, OptionUtils.MakeSubTitle(mod.name .. " Options"))

        -- determine the path to the options file
        local directory = mod.location
        local file = 'mod_options.lua'
        local path = directory .. '/' .. file 

        -- does such a file exist?
        if DiskGetFileInfo(path) then
            -- try to retrieve the options
            local data = {}
            doscript(path, data)

            if data.options ~= nil then 

                -- go over the options, find out if there is a name clash with the team / game options
                for k, option in data.options do 

                    local key = option.key
                    local clashed = false 

                    -- if we haven't clashed already, check these options too
                    if not clashed then 
                        if table.predicate(globalOpts, CheckForClash, key) then
                            WARN("A mod option key clashes with a key from the global options: " .. key .. ". The option is not shown and not taken into account.")
                            clashed = true
                        end
                    end

                    -- if we haven't clashed already, check these options too
                    if not clashed then 
                        if table.predicate(teamOpts, CheckForClash, key) then
                            WARN("A mod option key clashes with a key from the team options: " .. key .. ". The option is not shown and not taken into account.")
                            clashed = true
                        end
                    end

                    -- if we haven't clashed already, check these options too
                    if not clashed then 
                        if table.predicate(AIOpts, CheckForClash, key) then
                            WARN("A mod option key clashes with a key from the AI options: " .. key .. ". The option is not shown and not taken into account.")
                            clashed = true
                        end
                    end

                    -- if we haven't clashed, consider it a valid option!
                    if not clashed then 
                        local text = option.label
                        local data = option
                        local default = option.default
                        table.insert(options, OptionUtils.MakeOption(text, data, default))
                    end
                end
            end
        end
    end

    return options
end

-- Returns a list of the options of all mods in a single list to match the layout set by map, 
-- team, game and AI options defined in (for example) lobbyOptions.lua. The format is:
-- { 
--      option,
--      option,
--      option,
--      ...
-- }
function LoadModOptions()
    local optionsStripped = { }

    local optionsformatted = LoadModOptionsFormatted()
    for _, entry in optionsformatted do
        if entry.type == 'option' then
            table.insert(optionsStripped, entry.data)
        end
    end

    return optionsStripped
end