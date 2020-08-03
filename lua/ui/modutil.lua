
local Mods = import('/lua/mods.lua')

function LoadModOptions()

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
                -- store it in the expected format in mapselect.lua
                local data = { }
                data.title = mod.name .. " Options"
                data.options = options.options

                -- mark them as mod options
                for l, option in data.options do 
                    option.isModOption = true 
                end

                table.insert(optionsPerMod, data)
            end
        end
    end

    return optionsPerMod
end