local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group

--- A Group for arranging controls horizontally in fixed-width columns.
---@class ColumnLayout : Group
ColumnLayout = ClassUI(Group) {
    --- Create a new ColumnLayout
    ---@param self ColumnLayout
    ---@param parent Control
    ---@param positions number[] A list of values representing the x co-ordinate of the leftmost pixel of each column. 
    ---@param widths number[] A list of values representing the width of each column.
    __init = function(self, parent, positions, widths)
        Group.__init(self, parent)

        self.positions = positions
        self.widths = widths
        self.numChildren = 0
    end,

    --- Add a control to the group, inserting it into the next available column.
    ---@param self ColumnLayout
    ---@param control Control
    AddChild = function(self, control)
        self.numChildren = self.numChildren + 1
        LayoutHelpers.SetWidth(control, self.widths[self.numChildren])
        LayoutHelpers.AtLeftIn(control, self, self.positions[self.numChildren])
        LayoutHelpers.AtVerticalCenterIn(control, self, 1)
    end
}
