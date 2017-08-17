-- This is a helper file that creates the little UI label for a key binding on a construction or order button
-- It is called from construction.lua and orders.lua respectively

local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Prefs = import('/lua/user/prefs.lua')

function addLabel(control, parent, key)
    if not Prefs.GetFromCurrentProfile('options').show_hotkeylabels then
        return
    end

    control.hotbuildKeyBg = Bitmap(parent)
    control.hotbuildKeyBg.Depth:Set(99)
    control.hotbuildKeyBg.Height:Set(20)
    if string.len(key.key) <= 2 then
        control.hotbuildKeyBg.Width:Set(20)
    else
        control.hotbuildKeyBg.Width:Set(30)
    end
    LayoutHelpers.AtRightTopIn(control.hotbuildKeyBg, parent, 0, parent.Height() - 20)
    control.hotbuildKeyBg:SetTexture('/textures/ui/bg.png')
    control.hotbuildKeyBg:DisableHitTest()

    control.hotbuildKeyText = UIUtil.CreateText(control.hotbuildKeyBg, key.key, key.textsize, UIUtil.bodyFont)
    control.hotbuildKeyText:SetColor(key.colour)
    LayoutHelpers.AtCenterIn(control.hotbuildKeyText, control.hotbuildKeyBg, 1, 0)
    control.hotbuildKeyText:DisableHitTest(true)
end