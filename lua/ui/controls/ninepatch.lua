local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local ScaleNumber = import("/lua/maui/layouthelpers.lua").ScaleNumber

---@class NinePatch : Group
---@field center? Bitmap
---@field tl Bitmap
---@field tr Bitmap
---@field bl Bitmap
---@field br Bitmap
---@field l Bitmap
---@field r Bitmap
---@field t Bitmap
---@field b Bitmap
NinePatch = ClassUI(Group) {
    ---@param self NinePatch
    ---@param parent Control
    ---@param center Lazy<FileName> | nil
    ---@param topLeft Lazy<FileName>
    ---@param topRight Lazy<FileName>
    ---@param bottomLeft Lazy<FileName>
    ---@param bottomRight Lazy<FileName>
    ---@param left Lazy<FileName>
    ---@param right Lazy<FileName>
    ---@param top Lazy<FileName>
    ---@param bottom Lazy<FileName>
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
        self.r = Bitmap(self, right)
        self.t = Bitmap(self, top)
        self.b = Bitmap(self, bottom)

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

    ---@param self NinePatch
    ---@return number
    TotalWidth = function(self)
        return self.l.Width() + self.Width() + self.r.Width()
    end;

    ---@param self NinePatch
    ---@return number
    TotalHeight = function(self)
        return self.t.Height() + self.Height() + self.b.Height()
    end;

    -- Lay this NinePatch out around the given control
    ---@param self NinePatch
    ---@param control Control
    ---@param horizontalPadding number
    ---@param verticalPadding number
    Surround = function(self, control, horizontalPadding, verticalPadding)
        horizontalPadding = ScaleNumber(horizontalPadding)
        verticalPadding = ScaleNumber(verticalPadding)
        self.Left:Set(function() return control.Left() + horizontalPadding end)
        self.Right:Set(function() return control.Right() - horizontalPadding end)
        self.Top:Set(function() return control.Top() + verticalPadding end)
        self.Bottom:Set(function() return control.Bottom() - verticalPadding end)
    end;
}

--- Alternate initializer using the border-name convention instead of the long-name convention
---@param self NinePatch
---@param parent Control
---@param path FileName
InitStd = function(self, parent, path)
    local SkinnableFile = import("/lua/ui/uiutil.lua").SkinnableFile
    NinePatch.__init(self, parent,
        SkinnableFile(path .. "_brd_m.dds"),
        SkinnableFile(path .. "_brd_ul.dds"),
        SkinnableFile(path .. "_brd_ur.dds"),
        SkinnableFile(path .. "_brd_ll.dds"),
        SkinnableFile(path .. "_brd_lr.dds"),
        SkinnableFile(path .. "_brd_vert_l.dds"),
        SkinnableFile(path .. "_brd_vert_r.dds"),
        SkinnableFile(path .. "_brd_horz_um.dds"),
        SkinnableFile(path .. "_brd_lm.dds") -- yes, the suffix doesn't include `horz`
    )
end