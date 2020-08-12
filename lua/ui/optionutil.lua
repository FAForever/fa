
local globalOptions = import('/lua/ui/lobby/lobbyOptions.lua').globalOpts
local teamOptions = import('/lua/ui/lobby/lobbyOptions.lua').teamOptions
local AIOptions = import('/lua/ui/lobby/lobbyOptions.lua').AIOpts

function MakeHeader(title, content, tooltipTitle, tooltipValue)
    return {
        type = 'header',
        title = title,
        content = content,
        tooltipTitle = tooltipTitle,
        tooltipValue = tooltipValue
    }
end

-- makes a title component
function MakeTitle(text)
    return {
        type = 'title',
        text = text
    }
end

-- makes a sub title component
function MakeSubTitle(text)
    return { 
        type = 'subtitle',
        text = text 
    }
end

-- makes a sub title component
function MakeText(text)
    return { 
        type = 'text',
        text = text 
    }
end

-- makes a spacer component
function MakeSpacer()
    return {
        type = 'spacer'
    }
end

-- makes an option component
function MakeOption(text, data, default)
    return {
        type = 'option',
        text = text,
        data = data,
        default = default
    }
end

function MakeOptions (unformatted)
    local formatted = { }
    for k, option in unformatted do 
        local text = option.label
        local data = option
        local default = option.default
        table.insert(formatted, MakeOption(text, data, default))
    end
    return formatted
end

-- returns a table of type:
-- {
--     {
--         type = title
--         text = string
--     }
--     {
--         type = option
--         option = {
--             ...
--         }
--     }
--     {
--         type = option
--         option = {
--             ...
--         }
--     }
--     ...
-- }
function TeamOptionsFormatted()
    local title = { MakeTitle('Team options') }
    local options = MakeOptions(teamOptions)
    return table.cat(title, options)
end

function GameOptionsFormatted()
    local title = { MakeTitle('Game options') }
    local options = MakeOptions(globalOptions)
    return table.cat(title, options)
end

function AIOptionsFormatted() 
    local title = { MakeTitle('AI options') }
    local options = MakeOptions(AIOptions)
    return table.cat(title, options)
end

function MapOptionsFormatted(scenario)
    local title = { MakeTitle('Map options') }
    local options = { }

    -- no scenario (map) can be chosen
    if scenario then 
        -- no _options.lua file can be defined for the scenario
        if scenario.options then 
            options = MakeOptions(scenario.options)
        else
            SPEW("Option Util: No options defined by scenario.")
        end
    else
        SPEW("Option Util: No scenario defined.")
    end
    return table.cat(title, options)
end

function ModOptionsFormatted(mods)

    local options = { }

    -- returns a function that given an option, checks if the key matches.
    local function CheckForClash(option, key)
        return option.key == key
    end

    local function FindOptionsOfMod(path)

        -- does such a file exist?
        if DiskGetFileInfo(path) then

            -- try to retrieve the options
            local data = {}
            doscript(path, data)

            -- find the options, keep backwards compatibility in mind
            local unformattedOptions = data.options or data.AIOpts
            if unformattedOptions ~= nil then 

                -- go over the options, find out if there is a name clash with the team / game options
                for k, option in unformattedOptions do 

                    local key = option.key
                    local clashed = false 

                    -- if we haven't clashed already, check these options too
                    if not clashed then 
                        if table.predicate(teamOptions, CheckForClash, key) then
                            WARN("A mod option key clashes with a key from the team options: " .. key .. ". The option is not shown and not taken into account.")
                            clashed = true
                        end
                    end

                    -- if we haven't clashed already, check these options too
                    if not clashed then 
                        if table.predicate(globalOptions, CheckForClash, key) then
                            WARN("A mod option key clashes with a key from the global options: " .. key .. ". The option is not shown and not taken into account.")
                            clashed = true
                        end
                    end

                    -- if we haven't clashed already, check these options too
                    if not clashed then 
                        if table.predicate(AIOptions, CheckForClash, key) then
                            WARN("A mod option key clashes with a key from the AI options: " .. key .. ". The option is not shown and not taken into account.")
                            clashed = true
                        end
                    end

                    -- if we haven't clashed, consider it a valid option!
                    if not clashed then 
                        local text = option.label
                        local data = option
                        local default = option.default
                        table.insert(options, MakeOption(text, data, default))
                    end
                end
            end
        end
    end

    -- load in the options file for each mod
    for k, mod in mods do 

        -- add in the subtitle
        table.insert(options, MakeSubTitle(mod.name))

        -- determine the path to the options file
        local directory = mod.location
        local file = 'mod_options.lua'
        local path = directory .. '/' .. file 
        FindOptionsOfMod(path)

        -- determine the path to the backwards compatible AI options file
        local file_old = 'lua/ai/lobbyoptions/lobbyoptions.lua'
        local path = directory .. '/' .. file_old
        FindOptionsOfMod(path)
    end

    -- add in the title of the section
    local title = { MakeTitle('Mod options') }
    return table.cat(title, options)
end

function ModOptionsRaw(mods)
    local formatted = ModOptionsFormatted(mods)

    local stripped = { }
    for _, entry in formatted do
        if entry.type == 'option' then
            table.insert(stripped, entry.data)
        end
    end

    return stripped
end

function OptionsFormatted(scenario, mods)
    local teamOptionsFormatted = TeamOptionsFormatted()
    local gameOptionsFormatted = GameOptionsFormatted()
    local aIOptionsFormatted = AIOptionsFormatted()
    local mapOptionsFormatted = MapOptionsFormatted(scenario)
    local modOptionsFormatted = ModOptionsFormatted(mods)

    return table.concatenate(
        teamOptionsFormatted,
        gameOptionsFormatted,
        aIOptionsFormatted,
        mapOptionsFormatted,
        modOptionsFormatted
    )
end

function OptionsCorrectedWithMessage(entries, noContentMessage)
    local corrected = { }
    for k, entry in entries do 
        -- add in the entry itself
        table.insert(corrected, entry)

        -- check if a title has content, otherwise add in a message
        if entry.type == 'title' then 
            if not TitleHasContent(entries, k) then 
                table.insert(corrected, MakeText(noContentMessage))
            end
        end

        -- check if a subtitle has content, otherwise add in a message
        if entry.type == 'subtitle' then 
            if not SubtitleHasContent(entries, k) then 
                table.insert(corrected, MakeText(noContentMessage))
            end
        end
    end
    return corrected
end

function OptionsCorrectedWithRemoval(entries)
    local previous = entries
    local corrected = { }

    -- allows us to recursively remove sections and subsections
    local removing = true 
    while removing do 

        -- start off clean
        corrected = { }

        -- assume this is the last iteration
        removing = false
        for k, entry in previous do 
            -- check if a title has content, keep it
            if entry.type == 'title' then 
                if TitleHasContent(previous, k) then 
                    table.insert(corrected, entry)
                else
                    -- check again, see if some title now has no elements under it
                    removing = true
                end
            end

            -- check if a subtitle has content, keep it
            if entry.type == 'subtitle' then 
                if SubtitleHasContent(previous, k) then 
                    table.insert(corrected, entry)
                else
                    -- check again, see if some title now has no elements under it
                    removing = true
                end
            end

            -- add in everything else
            if not (entry.type == 'title' or entry.type == 'subtitle') then
                table.insert(corrected, entry)
            end
        end

        -- switch it up
        previous = corrected
    end
    return corrected
end

function TitleHasContent(entries, index)
    local next = index + 1
    while entries[next] do  
        -- we count subtitles as content
        if entries[next].type == 'subtitle' then 
            return true
        end

        -- we count options as content
        if entries[next].type == 'option' then 
            return true
        end

        -- we 'count' headers as content?
        if entries[next].type == 'header' then
            WARN("UI: Headers should be at the top.")
            return true
        end

        -- we do not count titles as content
        if entries[next].type == 'title' then 
            return false 
        end

        -- look further
        if entries[next].type == 'spacer' then 
            next = next + 1
        end
    end

    -- end of the table, this entry has no content under it     
    return false
end

function SubtitleHasContent(entries, index)
    local next = index + 1
    while entries[next] do  
        -- we count options as content
        if entries[next].type == 'option' then 
            return true
        end

        -- we do not count subtitles as content
        if entries[next].type == 'subtitle' then 
            return false
        end

        -- we do not count titles as content
        if entries[next].type == 'title' then 
            return false 
        end

        -- look further
        if entries[next].type == 'spacer' then 
            next = next + 1
        end
    end

    -- end of the table, this entry has no content under it  
    return false
end