
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local GameCommon = import("/lua/ui/game/gamecommon.lua")
local numSlots = 15
local firstAltSlot = 8
local vertRows = 3
local horzRows = 5
local vertCols = numSlots/vertRows
local horzCols = numSlots/horzRows

function SetLayout()
    local controls = import("/lua/ui/game/orders.lua").controls

    controls.bg:SetTexture(UIUtil.UIFile('/game/orders-panel_vert/order-panel_bmp.dds'))
    LayoutHelpers.AtLeftIn(controls.bg, controls.controlClusterGroup, 17)
    LayoutHelpers.AtTopIn(controls.bg, controls.controlClusterGroup, 0)
    LayoutHelpers.ResetRight(controls.bg)
    LayoutHelpers.ResetBottom(controls.bg)

    controls.bracket:SetTexture(UIUtil.UIFile('/game/bracket-left/bracket_bmp_t.dds'))
    LayoutHelpers.AtLeftIn(controls.bracket, controls.bg, -17)
    LayoutHelpers.AtTopIn(controls.bracket, controls.bg, -2)
    LayoutHelpers.ResetBottom(controls.bracket)
    LayoutHelpers.ResetRight(controls.bracket)

    controls.bracketMax:SetTexture(UIUtil.UIFile('/game/bracket-left/bracket_bmp_b.dds'))
    LayoutHelpers.AtLeftIn(controls.bracketMax, controls.bracket)
    LayoutHelpers.AtBottomIn(controls.bracketMax, controls.bg, 2)

    controls.bracketMid:SetTexture(UIUtil.UIFile('/game/bracket-left/bracket_bmp_m.dds'))
    LayoutHelpers.AtLeftIn(controls.bracketMid, controls.bracket)
    controls.bracketMid.Top:Set(controls.bracket.Bottom)
    controls.bracketMid.Bottom:Set(controls.bracketMax.Top)

    if controls.bracketRightMin then
        controls.bracketRightMin:Destroy()
        controls.bracketRightMax:Destroy()
        controls.bracketRightMid:Destroy()

        controls.bracketRightMin = nil
        controls.bracketRightMax = nil
        controls.bracketRightMid = nil
    end

    controls.bracketMax:SetTexture(UIUtil.UIFile('/game/bracket-left/bracket_bmp_b.dds'))
    LayoutHelpers.AtLeftIn(controls.bracketMax, controls.bracket)
    LayoutHelpers.AtBottomIn(controls.bracketMax, controls.bg, -2)

    controls.bracketMid:SetTexture(UIUtil.UIFile('/game/bracket-left/bracket_bmp_m.dds'))
    LayoutHelpers.AtLeftIn(controls.bracketMid, controls.bracket, 7)
    controls.bracketMid.Top:Set(controls.bracket.Bottom)
    controls.bracketMid.Bottom:Set(controls.bracketMax.Top)

    LayoutHelpers.SetDimensions(controls.orderButtonGrid, GameCommon.iconWidth * horzCols, GameCommon.iconHeight * horzRows)
    LayoutHelpers.AtCenterIn(controls.orderButtonGrid, controls.bg, 0, -1)
    controls.orderButtonGrid:AppendRows(horzRows)
    controls.orderButtonGrid:AppendCols(horzCols)

    controls.bg.Mini = function(state)
        controls.bg:SetHidden(state)
        controls.orderButtonGrid:SetHidden(state)
    end
end
