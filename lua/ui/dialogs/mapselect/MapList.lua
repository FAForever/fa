
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')

local Group = import('/lua/maui/group.lua').Group

---@class MapList : Group
MapList = Class(Group) {

    __init = function(self, mapDialog)

    end,

    EventFiltersChanged = function(self, filters)

    end,
}
