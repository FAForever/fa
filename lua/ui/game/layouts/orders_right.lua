
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local GameCommon = import("/lua/ui/game/gamecommon.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local numSlots = 14
local firstAltSlot = 8
local vertRows = 7
local horzRows = 2
local vertCols = numSlots/vertRows
local horzCols = numSlots/horzRows

function SetLayout()
    local controls = import("/lua/ui/game/orders.lua").controls

    controls.bg:SetTexture(UIUtil.SkinnableFile('/game/orders-panel/order-panel_bmp.dds'))
    LayoutHelpers.AtRightIn(controls.bg, controls.controlClusterGroup, 10)
    LayoutHelpers.AtBottomIn(controls.bg, controls.controlClusterGroup)
    LayoutHelpers.ResetLeft(controls.bg)
    LayoutHelpers.ResetTop(controls.bg)

    controls.bracket:SetTexture(UIUtil.UIFile('/game/bracket-left-energy/bracket_bmp_t.dds'))
    LayoutHelpers.AtLeftIn(controls.bracket, controls.bg, -6)
    LayoutHelpers.AtTopIn(controls.bracket, controls.bg, 2)
    LayoutHelpers.ResetBottom(controls.bracket)
    LayoutHelpers.ResetRight(controls.bracket)

    controls.bracketMax:SetTexture(UIUtil.UIFile('/game/bracket-left-energy/bracket_bmp_b.dds'))
    LayoutHelpers.AtLeftIn(controls.bracketMax, controls.bracket)
    LayoutHelpers.AtBottomIn(controls.bracketMax, controls.bg, 2)

    controls.bracketMid:SetTexture(UIUtil.UIFile('/game/bracket-left-energy/bracket_bmp_m.dds'))
    LayoutHelpers.AtLeftIn(controls.bracketMid, controls.bracket)
    controls.bracketMid.Top:Set(controls.bracket.Bottom)
    controls.bracketMid.Bottom:Set(controls.bracketMax.Top)

    if not controls.bracketRightMin then
        controls.bracketRightMin = Bitmap(controls.bg)
        controls.bracketRightMax = Bitmap(controls.bg)
        controls.bracketRightMid = Bitmap(controls.bg)
        controls.bracketRightMin:DisableHitTest()
        controls.bracketRightMax:DisableHitTest()
        controls.bracketRightMid:DisableHitTest()
    end

    controls.bracketRightMin:SetTexture(UIUtil.UIFile('/game/bracket-right/bracket_bmp_t.dds'))
    controls.bracketRightMax:SetTexture(UIUtil.UIFile('/game/bracket-right/bracket_bmp_b.dds'))
    controls.bracketRightMid:SetTexture(UIUtil.UIFile('/game/bracket-right/bracket_bmp_m.dds'))

    controls.bracketRightMin.Top:Set(controls.bg.Top)
    controls.bracketRightMin.Right:Set(function() return controls.bg.Right() + 11 end)

    controls.bracketRightMax.Bottom:Set(controls.bg.Bottom)
    controls.bracketRightMax.Right:Set(controls.bracketRightMin.Right)

    controls.bracketRightMid.Bottom:Set(controls.bracketRightMax.Top)
    controls.bracketRightMid.Top:Set(controls.bracketRightMin.Bottom)
    controls.bracketRightMid.Right:Set(function() return controls.bracketRightMin.Right() - 7 end)

    LayoutHelpers.SetDimensions(controls.orderButtonGrid, GameCommon.iconWidth * horzCols, GameCommon.iconHeight * horzRows)
    LayoutHelpers.AtCenterIn(controls.orderButtonGrid, controls.bg, 0, -1)
    controls.orderButtonGrid:AppendRows(horzRows)
    controls.orderButtonGrid:AppendCols(horzCols)

    controls.bg.Mini = function(state)
        controls.bg:SetHidden(state)
        controls.orderButtonGrid:SetHidden(state)
    end
end
