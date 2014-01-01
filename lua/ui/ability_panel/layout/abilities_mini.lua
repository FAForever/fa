local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local GameCommon = import('/lua/ui/game/gamecommon.lua')
local numSlots = 6
local firstAltSlot = 1
local vertRows = 6
local horzRows = 1
local vertCols = numSlots/vertRows
local horzCols = numSlots/horzRows

function SetLayout()

    local controls = import('/lua/ui/ability_panel/abilities.lua').controls
    local savedParent = import('/lua/ui/ability_panel/abilities.lua').savedParent
    local econControl = import('/lua/ui/game/economy.lua').GUI.bg

	LayoutHelpers.AtLeftTopIn(controls.collapseArrow, GetFrame(0), -3, 97)
    
    controls.collapseArrow:SetTexture(UIUtil.SkinnableFile('/game/tab-l-btn/tab-close_btn_up.dds'))
    controls.collapseArrow:SetNewTextures(UIUtil.SkinnableFile('/game/tab-l-btn/tab-close_btn_up.dds'),
    UIUtil.SkinnableFile('/game/tab-l-btn/tab-open_btn_up.dds'),
    UIUtil.SkinnableFile('/game/tab-l-btn/tab-close_btn_over.dds'),
    UIUtil.SkinnableFile('/game/tab-l-btn/tab-open_btn_over.dds'),
    UIUtil.SkinnableFile('/game/tab-l-btn/tab-close_btn_dis.dds'),
    UIUtil.SkinnableFile('/game/tab-l-btn/tab-open_btn_dis.dds'))
    
    controls.collapseArrow.Depth:Set(function() return controls.bg.leftBrace.Depth() + 1 end)
    
    LayoutHelpers.Below(controls.bg, econControl, 5)

    if controls.collapseArrow:IsChecked() then
        LayoutHelpers.AtLeftIn(controls.bg, savedParent, -200)
    else
        LayoutHelpers.AtLeftIn(controls.bg, savedParent, 15)
    end
	
    controls.bg.Height:Set(controls.bg.panel.Height)
    controls.bg.Width:Set(controls.bg.panel.Width)
    
    controls.bg.panel:SetTexture(UIUtil.SkinnableFile('/game/filter-ping-panel/filter-ping-panel02_bmp.dds'))
    controls.bg.leftBrace:SetTexture(UIUtil.SkinnableFile('/game/filter-ping-panel/bracket-left_bmp.dds'))
    controls.bg.leftGlow:SetTexture(UIUtil.SkinnableFile('/game/filter-ping-panel/bracket-energy-l_bmp.dds'))
    controls.bg.rightGlowTop:SetTexture(UIUtil.SkinnableFile('/game/bracket-right-energy/bracket_bmp_t.dds'))
    controls.bg.rightGlowMiddle:SetTexture(UIUtil.SkinnableFile('/game/bracket-right-energy/bracket_bmp_m.dds'))
    controls.bg.rightGlowBottom:SetTexture(UIUtil.SkinnableFile('/game/bracket-right-energy/bracket_bmp_b.dds'))
        
    LayoutHelpers.AtLeftTopIn(controls.bg.panel, controls.bg, 2)
    controls.bg.leftBrace.Right:Set(function() return controls.bg.Left() + 11 end)
    controls.bg.leftBrace.Top:Set(function() return controls.bg.Top() + 2 end)
    controls.bg.leftGlow.Left:Set(function() return controls.bg.leftBrace.Left() + 12 end)
    controls.bg.leftGlow.Top:Set(function() return controls.bg.Top() - 0 end)
    controls.bg.leftGlow.Depth:Set(function() return controls.bg.leftBrace.Depth() - 1 end)
    controls.bg.rightGlowTop.Top:Set(function() return controls.bg.Top() + 3 end)
    controls.bg.rightGlowTop.Left:Set(function() return controls.bg.Right() - 9 end)
    controls.bg.rightGlowBottom.Bottom:Set(function() return controls.bg.Bottom() - 3 end)
    controls.bg.rightGlowBottom.Left:Set(controls.bg.rightGlowTop.Left)
    controls.bg.rightGlowMiddle.Top:Set(controls.bg.rightGlowTop.Bottom)
    controls.bg.rightGlowMiddle.Bottom:Set(function() return math.max(controls.bg.rightGlowTop.Bottom(), controls.bg.rightGlowBottom.Top()) end)
    controls.bg.rightGlowMiddle.Right:Set(function() return controls.bg.rightGlowTop.Right() end)
    
    controls.orderButtonGrid.Width:Set(GameCommon.iconWidth * horzCols)
    controls.orderButtonGrid.Height:Set(GameCommon.iconHeight * horzRows)
    LayoutHelpers.AtLeftTopIn(controls.orderButtonGrid, controls.bg, 11, 9)
    controls.orderButtonGrid:AppendRows(horzRows)
    controls.orderButtonGrid:AppendCols(horzCols)
    
    controls.bg.Mini = function(state)
        controls.bg:SetHidden(state)
        controls.orderButtonGrid:SetHidden(state)
    end
end