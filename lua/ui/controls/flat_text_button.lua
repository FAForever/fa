-- A button that is only its label: quiet until the mouse is over it, for use inside a flat panel.

local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')

local kPadding = 6

FlatTextButton = ClassUI(Bitmap) {
    __init = function(self, parent, label, pointSize)
        Bitmap.__init(self, parent)
        self:SetSolidColor('00000000')

        self.mLabel = UIUtil.CreateText(self, label, pointSize, UIUtil.bodyFont)
        self.mLabel:DisableHitTest()
        self.mLabel:SetColor(UIUtil.highlightColor())
        LayoutHelpers.AtCenterIn(self.mLabel, self)
        self.mLabel.Depth:Set(function() return self.Depth() + 1 end)

        self.Width:Set(function() return self.mLabel.Width() + LayoutHelpers.ScaleNumber(kPadding * 2) end)
        self.Height:Set(function() return self.mLabel.Height() + LayoutHelpers.ScaleNumber(kPadding) end)
    end,

    HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            self.mLabel:SetColor(UIUtil.fontOverColor())
        elseif event.Type == 'MouseExit' then
            self.mLabel:SetColor(UIUtil.highlightColor())
        elseif event.Type == 'ButtonPress' then
            self:OnClick()
            return true
        end
        return false
    end,

    OnClick = function(self)
    end,
}
