
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')

local Group = import('/lua/maui/group.lua').Group

---@class MatchOptions : Group
MatchOptions = Class(Group) {

    ---@param self MapPreview
    ---@param mapDialog MapDialog
    __init = function(self, mapDialog)

        -- register for events
        mapDialog:OnEvent(self, 'EventMapSelected')
    end,

    EventMapSelected = function(self, scenario)

    end,

}
