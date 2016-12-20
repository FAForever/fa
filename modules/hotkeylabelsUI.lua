local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

function addLabel(control, parent, key)
    control.hotbuildKeyBg = Bitmap(parent)
    control.hotbuildKeyBg.Depth:Set(99)
    control.hotbuildKeyBg.Height:Set(20)
    control.hotbuildKeyBg.Width:Set(20)
    LayoutHelpers.AtRightTopIn(control.hotbuildKeyBg, parent, 0, parent.Height() - 20)
    control.hotbuildKeyBg:SetTexture('/textures/ui/bg.png')
    control.hotbuildKeyBg:DisableHitTest()

    control.hotbuildKeyText = UIUtil.CreateText(control.hotbuildKeyBg, key.key, key.textsize, UIUtil.bodyFont)
    control.hotbuildKeyText:SetColor(key.colour)
    LayoutHelpers.AtCenterIn(control.hotbuildKeyText, control.hotbuildKeyBg, 1, 0)
    control.hotbuildKeyText:DisableHitTest(true)
end