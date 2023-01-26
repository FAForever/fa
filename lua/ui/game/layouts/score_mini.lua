local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

function SetLayout()
    local controls = import("/lua/ui/game/score.lua").controls
    local mapGroup = import("/lua/ui/game/score.lua").savedParent

    controls.collapseArrow:SetTexture(UIUtil.UIFile('/game/tab-r-btn/tab-close_btn_up.dds'))
    controls.collapseArrow:SetNewTextures(UIUtil.UIFile('/game/tab-r-btn/tab-close_btn_up.dds'),
        UIUtil.UIFile('/game/tab-r-btn/tab-open_btn_up.dds'),
        UIUtil.UIFile('/game/tab-r-btn/tab-close_btn_over.dds'),
        UIUtil.UIFile('/game/tab-r-btn/tab-open_btn_over.dds'),
        UIUtil.UIFile('/game/tab-r-btn/tab-close_btn_dis.dds'),
        UIUtil.UIFile('/game/tab-r-btn/tab-open_btn_dis.dds'))
    LayoutHelpers.AtRightTopIn(controls.collapseArrow, mapGroup, -3, 21)
    controls.collapseArrow.Depth:Set(function() return controls.bg.Depth() + 10 end)

    LayoutHelpers.AtRightTopIn(controls.bg, mapGroup, 18, 7)
    controls.bg.Width:Set(controls.bgTop.Width)
    controls.bgStretch.Width:Set(controls.bgTop.Width)
    controls.bgBottom.Width:Set(controls.bgTop.Width)

    LayoutHelpers.AtRightTopIn(controls.bgTop, controls.bg, 3)
    LayoutHelpers.AtLeftTopIn(controls.armyGroup, controls.bgTop, 10, 25)
    controls.armyGroup.Width:Set(function() return controls.bgTop.Width() - LayoutHelpers.ScaleNumber(20) end)

    controls.leftBracketMin:SetTexture(UIUtil.UIFile('/game/bracket-left-energy/bracket_bmp_t.dds'))
    LayoutHelpers.AtLeftTopIn(controls.leftBracketMin, controls.bg, -10, -1)

    controls.leftBracketMax:SetTexture(UIUtil.UIFile('/game/bracket-left-energy/bracket_bmp_b.dds'))
    LayoutHelpers.AtBottomIn(controls.leftBracketMax, controls.bg, -1)
    controls.leftBracketMax.Left:Set(controls.leftBracketMin.Left)

    controls.leftBracketMid:SetTexture(UIUtil.UIFile('/game/bracket-left-energy/bracket_bmp_m.dds'))
    controls.leftBracketMid.Top:Set(controls.leftBracketMin.Bottom)
    controls.leftBracketMid.Bottom:Set(controls.leftBracketMax.Top)
    controls.leftBracketMid.Left:Set(function() return controls.leftBracketMin.Left() end)

    controls.rightBracketMin:SetTexture(UIUtil.UIFile('/game/bracket-right/bracket_bmp_t.dds'))
    LayoutHelpers.AtRightTopIn(controls.rightBracketMin, controls.bg, -18, -5)

    controls.rightBracketMax:SetTexture(UIUtil.UIFile('/game/bracket-right/bracket_bmp_b.dds'))
    controls.rightBracketMax.Bottom:Set(function()
            return math.max(controls.bg.Bottom() + 4, controls.rightBracketMin.Bottom() + controls.rightBracketMax.Height())
        end)
    controls.rightBracketMax.Right:Set(controls.rightBracketMin.Right)

    controls.rightBracketMid:SetTexture(UIUtil.UIFile('/game/bracket-right/bracket_bmp_m.dds'))
    controls.rightBracketMid.Top:Set(controls.rightBracketMin.Bottom)
    controls.rightBracketMid.Bottom:Set(controls.rightBracketMax.Top)
    LayoutHelpers.AtRightIn(controls.rightBracketMid, controls.rightBracketMin, 7)

    controls.bgTop:SetTexture(UIUtil.UIFile('/game/score-panel/panel-score_bmp_t.dds'))
    controls.bgBottom:SetTexture(UIUtil.UIFile('/game/score-panel/panel-score_bmp_b.dds'))
    controls.bgStretch:SetTexture(UIUtil.UIFile('/game/score-panel/panel-score_bmp_m.dds'))

    controls.bgBottom.Top:Set(function() return math.max(controls.armyGroup.Bottom() - 14, controls.bgTop.Bottom()) end)
    controls.bgBottom.Right:Set(controls.bgTop.Right)
    controls.bgStretch.Top:Set(controls.bgTop.Bottom)
    controls.bgStretch.Bottom:Set(controls.bgBottom.Top)
    controls.bgStretch.Right:Set(function() return controls.bgTop.Right() - 0 end)

    controls.bg.Height:Set(function() return controls.bgBottom.Bottom() - controls.bgTop.Top() end)

    LayoutHelpers.AtLeftTopIn(controls.timeIcon, controls.bgTop, 10, 6)
    controls.timeIcon:SetTexture(UIUtil.UIFile('/game/unit_view_icons/time.dds'))
    LayoutHelpers.RightOf(controls.time, controls.timeIcon)

    LayoutHelpers.AtRightTopIn(controls.unitIcon, controls.bgTop, 10, 6)
    controls.unitIcon:SetTexture(UIUtil.UIFile('/dialogs/score-overlay/tank_bmp.dds'))
    LayoutHelpers.LeftOf(controls.units, controls.unitIcon)

    LayoutHelpers.SetDimensions(controls.timeIcon, controls.timeIcon.BitmapWidth() * .8, controls.timeIcon.BitmapHeight() * .8)
    LayoutHelpers.SetDimensions(controls.unitIcon, controls.unitIcon.BitmapWidth() * .9, controls.unitIcon.BitmapHeight() * .9)
    local avatarGroup = import("/lua/ui/game/avatars.lua").controls.avatarGroup
    avatarGroup.Top:Set(function() return controls.bgBottom.Bottom() + 4 end)
end

function LayoutArmyLines()
    local controls = import("/lua/ui/game/score.lua").controls

    for index, line in controls.armyLines do
        local i = index
        if i == 1 then
            LayoutHelpers.AtLeftTopIn(controls.armyLines[i], controls.armyGroup)
        else
            LayoutHelpers.Below(controls.armyLines[i], controls.armyLines[i-1])
        end
    end
end
