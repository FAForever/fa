local NinePatch = import('/lua/ui/controls/ninepatch.lua').NinePatch

-- A nine-patch without a background, useful for laying out around things. An eight-patch.
Border = Class(NinePatch) {
    __init = function(self, parent, topLeft, topRight, bottomLeft, bottomRight, left, right, top, bottom)
        NinePatch.__init(self, parent, nil, topLeft, topRight, bottomLeft, bottomRight, left, right, top, bottom)
    end,

    -- Lay this border out around the given control
    Surround = function(self, control, horizontalPadding, verticalPadding)
        self.Left:Set(function() return control.Left() + horizontalPadding end)
        self.Right:Set(function() return control.Right() - horizontalPadding end)
        self.Top:Set(function() return control.Top() + verticalPadding end)
        self.Bottom:Set(function() return control.Bottom() - verticalPadding end)
    end
}
