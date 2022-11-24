
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

function SetLayout()
    local controls = import("/lua/ui/game/multifunction.lua").controls
    local savedParent = import("/lua/ui/game/multifunction.lua").savedParent
    local econControl = import("/lua/ui/game/economy.lua").GUI.bg

    controls.bg.panel:SetTexture(UIUtil.UIFile('/game/filter-ping-panel/filter-ping-panel02_bmp.dds'))
    controls.bg.leftBrace:SetTexture(UIUtil.UIFile('/game/filter-ping-panel/bracket-left_bmp.dds'))
    controls.bg.leftGlow:SetTexture(UIUtil.UIFile('/game/filter-ping-panel/bracket-energy-l_bmp.dds'))
    controls.bg.rightGlowTop:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_t.dds'))
    controls.bg.rightGlowMiddle:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_m.dds'))
    controls.bg.rightGlowBottom:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_b.dds'))

    controls.collapseArrow:SetTexture(UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_up.dds'))
    controls.collapseArrow:SetNewTextures(UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_up.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_up.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_over.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_over.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_dis.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_dis.dds'))
    LayoutHelpers.AtLeftTopIn(controls.collapseArrow, GetFrame(0), -3, 97)
    controls.collapseArrow.Depth:Set(function() return controls.bg.Depth() + 10 end)

    LayoutHelpers.Below(controls.bg, econControl, 5)
    if controls.collapseArrow:IsChecked() then
        LayoutHelpers.AtLeftIn(controls.bg, savedParent, -200)
    else
        LayoutHelpers.AtLeftIn(controls.bg, savedParent, 15)
    end
    controls.bg.Height:Set(controls.bg.panel.Height)
    controls.bg.Width:Set(controls.bg.panel.Width)

    LayoutHelpers.AtLeftTopIn(controls.bg.panel, controls.bg, 2)
    LayoutHelpers.AnchorToLeft(controls.bg.leftBrace, controls.bg, -11)
    LayoutHelpers.AtTopIn(controls.bg.leftBrace, controls.bg, 2)
    LayoutHelpers.AtLeftIn(controls.bg.leftGlow, controls.bg.leftBrace, 12)
    LayoutHelpers.AtTopIn(controls.bg.leftGlow, controls.bg)
    controls.bg.leftGlow.Depth:Set(function() return controls.bg.leftBrace.Depth() - 1 end)
    LayoutHelpers.AtTopIn(controls.bg.rightGlowTop, controls.bg, 3)
    LayoutHelpers.AnchorToRight(controls.bg.rightGlowTop, controls.bg, -9)
    LayoutHelpers.AtBottomIn(controls.bg.rightGlowBottom, controls.bg, 3)
    controls.bg.rightGlowBottom.Left:Set(controls.bg.rightGlowTop.Left)
    controls.bg.rightGlowMiddle.Top:Set(controls.bg.rightGlowTop.Bottom)
    controls.bg.rightGlowMiddle.Bottom:Set(function() return math.max(controls.bg.rightGlowTop.Bottom(), controls.bg.rightGlowBottom.Top()) end)
    controls.bg.rightGlowMiddle.Right:Set(function() return controls.bg.rightGlowTop.Right() end)


    for i, control in controls.overlayBtns do
        local index = i
        if index == 1 then
            LayoutHelpers.AtLeftTopIn(control, controls.bg, 3, 33)
        else
            LayoutHelpers.RightOf(control, controls.overlayBtns[index-1], -7)
        end
        if control.dropout then
            LayoutHelpers.RightOf(control.dropout, control, -15)
            LayoutHelpers.AtVerticalCenterIn(control.dropout, control, -1)
        end
    end

    for i, control in controls.pingBtns do
        local index = i
        if index == 1 then
            LayoutHelpers.AtLeftTopIn(control, controls.bg, 15, 6)
        else
            LayoutHelpers.RightOf(control, controls.pingBtns[index-1], -7)
        end
    end

end