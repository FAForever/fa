
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')

local Group = import('/lua/maui/group.lua').Group

---@class MapDescription : Group
MapDescription = Class(Group) {

    ---@param self MapDescription
    ---@param mapDialog MapDialog
    __init = function(self, mapDialog)

    end,

    EventMapChange = function(self, scenario)

    end,

}
