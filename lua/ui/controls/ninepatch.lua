local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

NinePatch = Class(Group) {
    __init = function(self, parent, center, topLeft, topRight, bottomLeft, bottomRight, left, right, top, bottom)
        Group.__init(self, parent)

        -- Minor special-snowflaking for the sake of Border.
        if center then
            self.center = Bitmap(self, center)

            self.center.Top:Set(self.Top)
            self.center.Left:Set(self.Left)
            self.center.Bottom:Set(self.Bottom)
            self.center.Right:Set(self.Right)
        end

        self.tl = Bitmap(self, topLeft)
        self.tr = Bitmap(self, topRight)
        self.bl = Bitmap(self, bottomLeft)
        self.br = Bitmap(self, bottomRight)
        self.l = Bitmap(self, left)
        self.l:SetTiled(true)
        self.r = Bitmap(self, right)
        self.r:SetTiled(true)
        self.t = Bitmap(self, top)
        self.t:SetTiled(true)
        self.b = Bitmap(self, bottom)
        self.b:SetTiled(true)

        self.tl.Bottom:Set(self.Top)
        self.tl.Right:Set(self.Left)

        self.tr.Bottom:Set(self.Top)
        self.tr.Left:Set(self.Right)

        self.t.Bottom:Set(self.Top)
        self.t.Right:Set(self.Right)
        self.t.Left:Set(self.Left)

        self.l.Bottom:Set(self.Bottom)
        self.l.Top:Set(self.Top)
        self.l.Right:Set(self.Left)

        self.r.Bottom:Set(self.Bottom)
        self.r.Top:Set(self.Top)
        self.r.Left:Set(self.Right)

        self.bl.Top:Set(self.Bottom)
        self.bl.Right:Set(self.Left)

        self.br.Top:Set(self.Bottom)
        self.br.Left:Set(self.Right)

        self.b.Top:Set(self.Bottom)
        self.b.Right:Set(self.Right)
        self.b.Left:Set(self.Left)

        self:DisableHitTest(true)
    end,

    -- Lay this NinePatch out around the given control
    Surround = function(self, control, horizontalPadding, verticalPadding)
        self.Left:Set(function() return control.Left() + horizontalPadding end)
        self.Right:Set(function() return control.Right() - horizontalPadding end)
        self.Top:Set(function() return control.Top() + verticalPadding end)
        self.Bottom:Set(function() return control.Bottom() - verticalPadding end)
    end
}
