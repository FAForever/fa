local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

function SetLayout()
    local controls = import("/lua/ui/game/tabs.lua").controls

    controls.collapseArrow:SetTexture(UIUtil.UIFile('/game/tab-t-btn/tab-close_btn_up.dds'))
    controls.collapseArrow:SetNewTextures(UIUtil.UIFile('/game/tab-t-btn/tab-close_btn_up.dds'),
        UIUtil.UIFile('/game/tab-t-btn/tab-open_btn_up.dds'),
        UIUtil.UIFile('/game/tab-t-btn/tab-close_btn_over.dds'),
        UIUtil.UIFile('/game/tab-t-btn/tab-open_btn_over.dds'),
        UIUtil.UIFile('/game/tab-t-btn/tab-close_btn_dis.dds'),
        UIUtil.UIFile('/game/tab-t-btn/tab-open_btn_dis.dds'))
    LayoutHelpers.AtTopIn(controls.collapseArrow, GetFrame(0), -3)
    LayoutHelpers.AtHorizontalCenterIn(controls.collapseArrow, controls.parent)
    controls.collapseArrow.Depth:Set(function() return controls.bgTop.Depth() + 10 end)

    controls.bgTop.center:SetTexture(UIUtil.UIFile('/game/options-panel/options_brd_horz_um.dds'))
    controls.bgTop.left:SetTexture(UIUtil.UIFile('/game/options-panel/options_brd_ul.dds'))
    controls.bgTop.right:SetTexture(UIUtil.UIFile('/game/options-panel/options_brd_ur.dds'))

    controls.bgTop.centerLeft:SetTexture(UIUtil.UIFile('/game/options-panel/options_brd_horz_uml.dds'))
    controls.bgTop.centerRight:SetTexture(UIUtil.UIFile('/game/options-panel/options_brd_horz_umr.dds'))

    LayoutHelpers.AtTopIn(controls.bgTop, controls.parent)
    LayoutHelpers.AtHorizontalCenterIn(controls.bgTop, controls.parent)

    controls.bgBottom.center:SetTexture(UIUtil.UIFile('/game/options-panel/options_brd_horz_lm.dds'))
    controls.bgBottom.left:SetTexture(UIUtil.UIFile('/game/options-panel/options_brd_ll.dds'))
    controls.bgBottom.right:SetTexture(UIUtil.UIFile('/game/options-panel/options_brd_lr.dds'))
    controls.bgBottom.Top:Set(controls.bgTop.Bottom)
    LayoutHelpers.AtHorizontalCenterIn(controls.bgBottom, controls.parent)

    local containerWidth, containerHeight = 0, 0

    for index, tab in controls.tabs do
        local i = index
        if i == 1 then
            LayoutHelpers.AtLeftTopIn(tab, controls.tabContainer)
        else
            LayoutHelpers.RightOf(tab, controls.tabs[i-1], -5)
        end
        if tab.Data.pause then
            tab:SetNewTextures(UIUtil.UIFile('/game/options_tab/pause_btn_up.dds'),
                UIUtil.UIFile('/game/options_tab/play_btn_up.dds'),
                UIUtil.UIFile('/game/options_tab/pause_btn_down.dds'),
                UIUtil.UIFile('/game/options_tab/play_btn_down.dds'),
                UIUtil.UIFile('/game/options_tab/pause_btn_dis.dds'),
                UIUtil.UIFile('/game/options_tab/play_btn_dis.dds'))
        else
            tab:SetNewTextures(UIUtil.UIFile('/game/options_tab/'..tab.Data.bitmap..'_btn_up.dds'),
                UIUtil.UIFile('/game/options_tab/'..tab.Data.bitmap..'_btn_selected.dds'),
                UIUtil.UIFile('/game/options_tab/'..tab.Data.bitmap..'_btn_over.dds'),
                UIUtil.UIFile('/game/options_tab/'..tab.Data.bitmap..'_btn_down.dds'),
                UIUtil.UIFile('/game/options_tab/'..tab.Data.bitmap..'_btn_dis.dds'),
                UIUtil.UIFile('/game/options_tab/'..tab.Data.bitmap..'_btn_dis.dds'))
        end
        if tab.Glow then
            tab.Glow:SetTexture(UIUtil.UIFile('/game/pause_btn/glow_bmp.dds'))
        end
        containerWidth = containerWidth + tab.Width() - 4
        containerHeight = math.max(containerHeight, tab.Height())
    end

    controls.tabContainer.Width:Set(containerWidth)
    controls.tabContainer.Height:Set(containerHeight)
    LayoutHelpers.AtHorizontalCenterIn(controls.tabContainer, controls.parent)
    LayoutHelpers.AtTopIn(controls.tabContainer, controls.bgTop, 10)

    controls.parent.Width:Set(controls.bgTop.Width)
    controls.parent.Height:Set(function() return controls.bgTop.Height() + controls.bgBottom.Height() end)
    LayoutHelpers.AtHorizontalCenterIn(controls.parent, GetFrame(0))
    LayoutHelpers.AtTopIn(controls.parent, GetFrame(0))
    controls.bgTop.defWidth = LayoutHelpers.ScaleNumber(180)
    controls.bgTop.Width:Set(controls.bgTop.defWidth)
end

function LayoutStretchBG()
    local controls = import("/lua/ui/game/tabs.lua").controls

    controls.bgBottomLeftGlow:SetTexture(UIUtil.UIFile('/game/options-panel/options_brd_vert_ll.dds'))
    controls.bgBottomLeftGlow.Bottom:Set(controls.bgBottom.Top)
    controls.bgBottomLeftGlow.Left:Set(controls.bgBottom.Left)
    controls.bgBottomLeftGlow.Top:Set(function() return math.max(controls.bgTopLeftGlow.Bottom(), controls.bgBottomLeftGlow.Bottom() - controls.bgBottomLeftGlow.Height()) end)

    controls.bgTopLeftGlow:SetTexture(UIUtil.UIFile('/game/options-panel/options_brd_vert_ul.dds'))
    controls.bgTopLeftGlow.Top:Set(controls.bgTop.Bottom)
    controls.bgTopLeftGlow.Left:Set(controls.bgTop.Left)
    controls.bgTopLeftGlow.Bottom:Set(function() return math.min(controls.bgBottom.Top(), controls.bgTop.Bottom() + controls.bgTopLeftGlow.Height()) end)

    controls.bgLeftStretch:SetTexture(UIUtil.UIFile('/game/options-panel/options_brd_vert_l.dds'))
    controls.bgLeftStretch.Bottom:Set(controls.bgBottomLeftGlow.Top)
    LayoutHelpers.AtLeftIn(controls.bgLeftStretch, controls.bgTopLeftGlow, 4)
    controls.bgLeftStretch.Top:Set(controls.bgTopLeftGlow.Bottom)

    controls.bgBottomRightGlow:SetTexture(UIUtil.UIFile('/game/options-panel/options_brd_vert_lr.dds'))
    controls.bgBottomRightGlow.Bottom:Set(controls.bgBottom.Top)
    controls.bgBottomRightGlow.Right:Set(controls.bgBottom.Right)
    controls.bgBottomRightGlow.Top:Set(function() return math.max(controls.bgTopRightGlow.Bottom(), controls.bgBottomRightGlow.Bottom() - controls.bgBottomRightGlow.Height()) end)

    controls.bgTopRightGlow:SetTexture(UIUtil.UIFile('/game/options-panel/options_brd_vert_ur.dds'))
    controls.bgTopRightGlow.Top:Set(controls.bgTop.Bottom)
    controls.bgTopRightGlow.Right:Set(controls.bgTop.Right)
    controls.bgTopRightGlow.Bottom:Set(function() return math.min(controls.bgBottom.Top(), controls.bgTop.Bottom() + controls.bgTopRightGlow.Height()) end)

    controls.bgRightStretch:SetTexture(UIUtil.UIFile('/game/options-panel/options_brd_vert_r.dds'))
    controls.bgRightStretch.Bottom:Set(controls.bgBottomRightGlow.Top)
    LayoutHelpers.AtRightIn(controls.bgRightStretch, controls.bgTopRightGlow, 4)
    controls.bgRightStretch.Top:Set(controls.bgTopRightGlow.Bottom)

    controls.bgMidStretch:SetTexture(UIUtil.UIFile('/game/options-panel/options_brd_m.dds'))
    controls.bgMidStretch.Top:Set(controls.bgTop.Bottom)
    controls.bgMidStretch.Left:Set(controls.bgLeftStretch.Right)
    controls.bgMidStretch.Right:Set(controls.bgRightStretch.Left)
    controls.bgMidStretch.Bottom:Set(controls.bgBottom.Top)
end