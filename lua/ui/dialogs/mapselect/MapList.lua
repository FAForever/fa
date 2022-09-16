
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')

local Group = import('/lua/maui/group.lua').Group

---@class MapList : Group
MapList = Class(Group) {

    ---@param self MapList
    ---@param mapDialog MapDialog
    __init = function(self, mapDialog)

        -- register for events
        mapDialog:OnEvent(self, 'EventFiltersChanged')
    end,

    EventFiltersChanged = function(self, filters)

    end,
}