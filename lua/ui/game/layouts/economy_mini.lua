
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Button = import("/lua/maui/button.lua").Button
local StatusBar = import("/lua/maui/statusbar.lua").StatusBar
local parent = import("/lua/ui/game/economy.lua").savedParent

local style = {
    mass = {
        textColor = 'ffb7e75f',
        barTexture = '/game/resource-bars/mini-mass-bar_bmp.dds',
        iconTexture = '/game/resources/mass_btn_up.dds',
        warningcolor = '8800ff00',
    },
    energy = {
        textColor = 'fff7c70f',
        barTexture = '/game/resource-bars/mini-energy-bar_bmp.dds',
        iconTexture = '/game/resources/energy_btn_up.dds',
        warningcolor = '88ff9000',
    },
}

function SetLayout()
    local GUI = import("/lua/ui/game/economy.lua").GUI
    local parent = import("/lua/ui/game/economy.lua").savedParent

    GUI.collapseArrow:SetTexture(UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_up.dds'))
    GUI.collapseArrow:SetNewTextures(UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_up.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_up.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_over.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_over.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_dis.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_dis.dds'))
    LayoutHelpers.AtLeftTopIn(GUI.collapseArrow, GetFrame(0), -3, 22)
    GUI.collapseArrow.Depth:Set(function() return GUI.bg.Depth() + 10 end)

    GUI.bg.panel:SetTexture(UIUtil.UIFile('/game/resource-panel/resources_panel_bmp.dds'))
    LayoutHelpers.AtLeftTopIn(GUI.bg.panel, GUI.bg)

    GUI.bg.Height:Set(GUI.bg.panel.Height)
    GUI.bg.Width:Set(GUI.bg.panel.Width)
    LayoutHelpers.AtLeftTopIn(GUI.bg, parent, 16, 3)
    GUI.bg:DisableHitTest()

    GUI.bg.leftBracket:SetTexture(UIUtil.UIFile('/game/filter-ping-panel/bracket-left_bmp.dds'))
    GUI.bg.leftBracketGlow:SetTexture(UIUtil.UIFile('/game/filter-ping-panel/bracket-energy-l_bmp.dds'))

    LayoutHelpers.AnchorToLeft(GUI.bg.leftBracket, GUI.bg.panel, -10)
    LayoutHelpers.AtLeftIn(GUI.bg.leftBracketGlow, GUI.bg.leftBracket, 12)

    GUI.bg.leftBracket.Depth:Set(GUI.bg.panel.Depth)
    LayoutHelpers.DepthUnderParent(GUI.bg.leftBracketGlow, GUI.bg.leftBracket)

    LayoutHelpers.AtVerticalCenterIn(GUI.bg.leftBracket, GUI.bg.panel)
    LayoutHelpers.AtVerticalCenterIn(GUI.bg.leftBracketGlow, GUI.bg.panel)

    GUI.bg.rightGlowTop:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_t.dds'))
    GUI.bg.rightGlowMiddle:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_m.dds'))
    GUI.bg.rightGlowBottom:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_b.dds'))

    LayoutHelpers.AtTopIn(GUI.bg.rightGlowTop, GUI.bg, 2)
    LayoutHelpers.AnchorToRight(GUI.bg.rightGlowTop, GUI.bg, -12)
    LayoutHelpers.AtBottomIn(GUI.bg.rightGlowBottom, GUI.bg, 2)
    GUI.bg.rightGlowBottom.Left:Set(GUI.bg.rightGlowTop.Left)
    GUI.bg.rightGlowMiddle.Top:Set(GUI.bg.rightGlowTop.Bottom)
    GUI.bg.rightGlowMiddle.Bottom:Set(function() return math.max(GUI.bg.rightGlowTop.Bottom(), GUI.bg.rightGlowBottom.Top()) end)
    GUI.bg.rightGlowMiddle.Right:Set(function() return GUI.bg.rightGlowTop.Right() end)

    LayoutResourceGroup(GUI.mass, 'mass')
    LayoutResourceGroup(GUI.energy, 'energy')

    LayoutHelpers.AtLeftTopIn(GUI.mass, GUI.bg, 14, 9)
    LayoutHelpers.Below(GUI.energy, GUI.mass, 4)
end

function LayoutResourceGroup(group, groupType)
    group.icon:SetTexture(UIUtil.UIFile(style[groupType].iconTexture))
    if groupType == 'mass' then
        LayoutHelpers.SetWidth(group.icon, 44)
        LayoutHelpers.AtLeftIn(group.icon, group, -14)
    elseif groupType == 'energy' then
        LayoutHelpers.SetWidth(group.icon, 36)
        LayoutHelpers.AtLeftIn(group.icon, group, -10)
    end
    LayoutHelpers.SetHeight(group.icon, 36)
    LayoutHelpers.AtVerticalCenterIn(group.icon, group)

    LayoutHelpers.AtCenterIn(group.warningBG, group, 0, -2)

    LayoutHelpers.SetDimensions(group.storageBar, 100, 10)
    group.storageBar._bar:SetTexture(UIUtil.UIFile(style[groupType].barTexture))
    LayoutHelpers.AtLeftTopIn(group.storageBar, group, 22, 2)

    LayoutHelpers.Below(group.curStorage, group.storageBar)
    LayoutHelpers.AtLeftIn(group.curStorage, group.storageBar)
    group.curStorage:SetColor(style[groupType].textColor)

    LayoutHelpers.Below(group.maxStorage, group.storageBar)
    LayoutHelpers.AtRightIn(group.maxStorage, group.storageBar)
    LayoutHelpers.ResetLeft(group.maxStorage)
    group.maxStorage:SetColor(style[groupType].textColor)

    group.storageTooltipGroup.Left:Set(group.storageBar.Left)
    group.storageTooltipGroup.Right:Set(group.storageBar.Right)
    group.storageTooltipGroup.Top:Set(group.storageBar.Top)
    group.storageTooltipGroup.Bottom:Set(group.maxStorage.Bottom)

    LayoutHelpers.RightOf(group.rate, group.storageBar, 4)
    LayoutHelpers.AtVerticalCenterIn(group.rate, group)

    LayoutHelpers.AtRightIn(group.income, group, 2)
    LayoutHelpers.AtTopIn(group.income, group)
    group.income:SetColor('ffb7e75f')

    LayoutHelpers.AtRightIn(group.expense, group, 2)
    LayoutHelpers.AtBottomIn(group.expense, group)
    LayoutHelpers.ResetTop(group.expense)
    group.expense:SetColor('fff30017')

    -- Reclaim info
    LayoutHelpers.AtRightIn(group.reclaimDelta, group, 49)
    LayoutHelpers.AtTopIn(group.reclaimDelta, group)
    group.reclaimDelta:SetColor('ffb7e75f')

    LayoutHelpers.AtRightIn(group.reclaimTotal, group, 49)
    LayoutHelpers.AtBottomIn(group.reclaimTotal, group)
    LayoutHelpers.ResetTop(group.reclaimTotal)

    if groupType == 'mass' then
        group.reclaimTotal:SetColor('FFB8F400')
    else
        group.reclaimTotal:SetColor('FFF8C000')
    end

    LayoutHelpers.SetDimensions(group, 296, 25)
end

function TogglePanelAnimation(state)
    local GUI = import("/lua/ui/game/economy.lua").GUI
    local savedParent = import("/lua/ui/game/economy.lua").savedParent
    if UIUtil.GetAnimationPrefs() then
        if state or GUI.bg:IsHidden() then
            PlaySound(Sound({Cue = "UI_Score_Window_Open", Bank = "Interface"}))
            GUI.bg:Show()
            GUI.bg:SetNeedsFrameUpdate(true)
            GUI.bg.OnFrame = function(self, delta)
                local newLeft = self.Left() + (1000*delta)
                if newLeft > savedParent.Left()+14 then
                    newLeft = savedParent.Left()+14
                    self:SetNeedsFrameUpdate(false)
                end
                self.Left:Set(newLeft)
            end
            GUI.collapseArrow:SetCheck(false, true)
        else
            PlaySound(Sound({Cue = "UI_Score_Window_Close", Bank = "Interface"}))
            GUI.bg:SetNeedsFrameUpdate(true)
            GUI.bg.OnFrame = function(self, delta)
                local newLeft = self.Left() - (1000*delta)
                if newLeft < savedParent.Left()-self.Width() then
                    newLeft = savedParent.Left()-self.Width()
                    self:SetNeedsFrameUpdate(false)
                    self:Hide()
                end
                self.Left:Set(newLeft)
            end
            GUI.collapseArrow:SetCheck(true, true)
        end
    else
        if state or GUI.bg:IsHidden() then
            GUI.bg:Show()
            GUI.collapseArrow:SetCheck(false, true)
        else
            GUI.bg:Hide()
            GUI.collapseArrow:SetCheck(true, true)
        end
    end
end

function InitAnimation()
    local GUI = import("/lua/ui/game/economy.lua").GUI
    local savedParent = import("/lua/ui/game/economy.lua").savedParent
    GUI.bg:Show()
    GUI.bg.Left:Set(savedParent.Left()-GUI.bg.Width())
    GUI.bg:SetNeedsFrameUpdate(true)
    GUI.bg.OnFrame = function(self, delta)
        local newLeft = self.Left() + (1000*delta)
        if newLeft > savedParent.Left()+14 then
            newLeft = savedParent.Left()+14
            self:SetNeedsFrameUpdate(false)
        end
        self.Left:Set(newLeft)
    end
    GUI.collapseArrow:Show()
    GUI.collapseArrow:SetCheck(false, true)
end
