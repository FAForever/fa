
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')

local Group = import('/lua/maui/group.lua').Group

---@class MapDialog : Group
MapDialog = Class(Group) {

    __init = function(self, parent)

    end,

    RegisterEvent = function(self, identifier)

    end,

    EmitEvent = function(self, identifier, data)

    end,
}


---@param parent Control
---@param callbackOk function<string, table<string, string>, any>   -- called when ok                       -> acquires focus back to lobby text box, updates the lobby
---@param callbackCancel function()                                 -- called when cancelled                -> acquires focus back to lobby text box
---@param callbackModsChanged function()                            -- called when mods have been changed   -> informs all other players that mods have been adjusted
---@param singlePlayer boolean                                      -- whether we are in single player or not
---@param defaultScenarioName string                                -- name of the selected scenario
---@param curOptions table<string, string>                          -- for each option, the key / value pair
---@param availableMods table<number, table<string, boolean>>       -- for each player, list of mod identifiers that are available
function OpenDialog(parent, callbackOk, callbackCancel, callbackModsChanged, singlePlayer, defaultScenarioName, curOptions, availableMods)

end

