
local Mods = import('/lua/mods.lua')

-- used to detect team / game / ai <-> mod option clashes
local globalOpts = import('/lua/ui/lobby/lobbyOptions.lua').globalOpts
local teamOpts = import('/lua/ui/lobby/lobbyOptions.lua').teamOptions
local AIOpts = import('/lua/ui/lobby/lobbyOptions.lua').AIOpts

function LoadModOptions()

    -- returns a function that given an option, checks if they key matches.
    local function CheckForClash(option, key)
        return option.key == key
    end

    -- get the selected game mods
    local mods = Mods.GetGameMods()

    -- load in the options file for each mod
    local optionsPerMod = { }
    for k, mod in mods do 
        -- determine the path to the options file
        local directory = mod.location
        local file = 'mod_options.lua'
        local path = directory .. '/' .. file 

        -- does such a file exist?
        if DiskGetFileInfo(path) then
            -- try to retrieve the options
            local options = {}
            doscript(path, options)
            if options.options ~= nil then 
                local valids = { }

                -- go over the options, find out if there is a name clash with the team / game options
                for k, option in options.options do 
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
                        table.insert(valids, option)
                    end
                end

                -- store it in the expected format in mapselect.lua
                local data = { }
                data.title = mod.name .. " Options"
                data.options = valids
                table.insert(optionsPerMod, data)
            end
        end
    end

    return optionsPerMod
end