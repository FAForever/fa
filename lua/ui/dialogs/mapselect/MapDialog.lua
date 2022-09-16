
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')

local Group = import('/lua/maui/group.lua').Group
local EventEmitter = import('/lua/ui/common/EventEmitter.lua').EventEmitter

---@class MapDialog : Group, EventEmitter
MapDialog = Class(Group, EventEmitter) {

    ---@param self MapDialog
    ---@param parent Control
    __init = function(self, parent)

        self.MapDescription = import('/lua/ui/dialogs/mapselect/MapDescription.lua').MapDescription(self)
        self.MapFilters = import('/lua/ui/dialogs/mapselect/MapFilters.lua').MapFilters(self)
        self.MapList = import('/lua/ui/dialogs/mapselect/MapList.lua').MapList(self)
        self.MapPreview = import('/lua/ui/dialogs/mapselect/MapPreview.lua').MapPreview(self)
        self.MatchOptions = import('/lua/ui/dialogs/mapselect/MatchOptions.lua').MatchOptions(self)

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
