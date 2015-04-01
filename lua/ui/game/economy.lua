--*****************************************************************************
--* File: lua/modules/ui/game/economy.lua
--* Author: Chris Blackwell
--* Summary: Economy bar UI
--*
--* Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local StatusBar = import('/lua/maui/statusbar.lua').StatusBar
local GameMain = import('/lua/ui/game/gamemain.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local Prefs = import('/lua/user/prefs.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local options = Prefs.GetFromCurrentProfile('options')

local UIState = true

local lastEfficiency = {MASS=1, ENERGY=1}
local Reclaim = {focus=-1, MASS={rate=0, history={}}, ENERGY={rate=0, history={}}}

group = false
savedParent = false

GUI = {
    bg = false,
}

States = {
    energyDetail = Prefs.GetFromCurrentProfile("energyDetailedView"),
    energyViewState = Prefs.GetFromCurrentProfile("energyRateView") or 1,
    massDetail = Prefs.GetFromCurrentProfile("massDetailedView"),
    massViewState = Prefs.GetFromCurrentProfile("massRateView") or 1,
}

if States.energyDetail == nil then
    States.energyDetail = true
end

if States.massDetail == nil then
    States.massDetail = true
end

function Contract() 
    UIState = false
end

function Expand()
    UIState = true
end

function SetLayout(layout)
    GameMain.RemoveBeatFunction(_BeatFunction)
    import(UIUtil.GetLayoutFilename('economy')).SetLayout()
    return CommonLogic()
end


function CreateEconomyBar(parent)
    savedParent = parent
    CreateUI()
    return SetLayout()
end

function CreateUI()
    GUI.bg = Group(savedParent)
    GUI.bg.panel = Bitmap(GUI.bg)
    GUI.bg.leftBracket = Bitmap(GUI.bg)
    GUI.bg.leftBracketGlow = Bitmap(GUI.bg)
    
    GUI.bg.rightGlowTop = Bitmap(GUI.bg)
    GUI.bg.rightGlowMiddle = Bitmap(GUI.bg)
    GUI.bg.rightGlowBottom = Bitmap(GUI.bg)
    
    GUI.collapseArrow = Checkbox(savedParent)
    Tooltip.AddCheckboxTooltip(GUI.collapseArrow, 'econ_collapse')
    
    local function CreateResourceGroup(warningBitmap)
        local group = Group(GUI.bg)
        
        group.warningBG = Bitmap(group)
        group.warningBG.Depth:Set(group.Depth)
        group.warningBG.State = ''
        group.warningBG.ascending = 1
        group.warningBG.cycles = 0
        group.warningBG.flashMod = 1
        group.warningBG.warningBitmap = warningBitmap
        group.warningBG.SetToState = function(self, state)
            if self.State ~= state then
                if state == 'red' then
                    self:SetTexture(UIUtil.UIFile('/game/resource-panel/alert-'..self.warningBitmap..'-panel_bmp.dds'))
                    self.flashMod = 1.6
                elseif state == 'yellow' then
                    self:SetTexture(UIUtil.UIFile('/game/resource-panel/caution-'..self.warningBitmap..'-panel_bmp.dds'))
                    self.flashMod = 1.25
                end
                self.cycles = 0
                self.State = state
                self:SetNeedsFrameUpdate(true)
            end
        end
        
        group.warningBG.OnFrame = function(self, deltaTime)
            if self.State == 'hide' then
                local newAlpha = self:GetAlpha() - deltaTime
                if newAlpha < 0 then
                    self:SetAlpha(0)
                    self:SetNeedsFrameUpdate(false)
                else
                    self:SetAlpha(newAlpha)
                end
            else
                local newAlpha = self:GetAlpha() + ((deltaTime * self.flashMod) * self.ascending)
                if newAlpha > .5 then
                    newAlpha = .5
                    self.cycles = self.cycles + 1
                    self.ascending = -1
                elseif newAlpha < 0 then
                    newAlpha = 0
                    self.ascending = 1
                end
                self:SetAlpha(newAlpha)
                if self.cycles == 5 then
                    self:SetNeedsFrameUpdate(false)
                end
            end
        end
        
        group.icon = Bitmap(group)
        group.rate = UIUtil.CreateText(group, '', 18, UIUtil.bodyFont)
        group.rate:SetDropShadow(true)
        group.storageBar = StatusBar(group, 0, 100, false, false, 
            UIUtil.UIFile('/game/resource-mini-bars/mini-energy-bar-back_bmp.dds'), 
            UIUtil.UIFile('/game/resource-mini-bars/mini-energy-bar_bmp.dds'), false)
            
        group.curStorage = UIUtil.CreateText(group, '', 10, UIUtil.bodyFont)
        group.curStorage:SetDropShadow(true)
        group.maxStorage = UIUtil.CreateText(group, '', 10, UIUtil.bodyFont)
        group.maxStorage:SetDropShadow(true)
        
        group.storageTooltipGroup = Group(group.storageBar)
        group.storageTooltipGroup.Depth:Set(function() return group.storageBar.Depth() + 10 end)
        
        group.income = UIUtil.CreateText(group.warningBG, '', 10, UIUtil.bodyFont)
        group.income:SetDropShadow(true)
        group.expense = UIUtil.CreateText(group.warningBG, '', 10, UIUtil.bodyFont)
        group.expense:SetDropShadow(true)
        
        group.hideTarget = Group(group)
        group.hideTarget.Depth:Set(function() return group.income.Depth() + 1 end)
        
        group.warningBG:DisableHitTest()
        group.curStorage:DisableHitTest()
        group.maxStorage:DisableHitTest()
        group.storageBar:DisableHitTest()
        group.income:DisableHitTest()
        group.expense:DisableHitTest()
        
        return group
    end
    
    GUI.mass = CreateResourceGroup('mass')
    GUI.energy = CreateResourceGroup('energy')

    if options.gui_display_reclaim_totals == 1 then
        ecostats = Bitmap(GetFrame(0))
        ecostats:SetTexture('/textures/ui/common/game/economic-overlay/econ_bmp_m.dds')
        ecostats.Depth:Set(99)
        LayoutHelpers.AtLeftTopIn(ecostats, GetFrame(0), 340, 8)
        ecostats.Height:Set(36)
        ecostats.Width:Set(80)
        ecostats:DisableHitTest(true)
        local TextLine01 = UIUtil.CreateText(ecostats, 'reclaimed', 10, UIUtil.bodyFont)
        LayoutHelpers.CenteredAbove(TextLine01, ecostats, -12)
        TextLine02 = UIUtil.CreateText(ecostats, '', 10, UIUtil.bodyFont)
        TextLine02:SetColor('FFB8F400')
        LayoutHelpers.AtRightTopIn(TextLine02, ecostats, 4, 10)
        TextLine03 = UIUtil.CreateText(ecostats, '', 10, UIUtil.bodyFont)
        TextLine03:SetColor('FFF8C000')
        TextLine01:DisableHitTest(true)
        TextLine02:DisableHitTest(true)
        TextLine03:DisableHitTest(true)
        LayoutHelpers.AtRightTopIn(TextLine03, ecostats, 4, 20)
    end
end

function CommonLogic()
    local function AddGroupLogic(group, prefix)
        group.warningBG.OnHide = function(self, hidden)
            if hidden then
                group.income:SetHidden(true)
                group.expense:SetHidden(true)
            else
                group.income:SetHidden(not States[prefix.."Detail"])
                group.expense:SetHidden(not States[prefix.."Detail"])
            end
            return true
        end
        
        group.hideTarget.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                if States[prefix.."Detail"] == false then
                    group.income:Show()
                    group.expense:Show()
                end
                Tooltip.CreateMouseoverDisplay(self, prefix .. "_extended_display", nil, true)
                local sound = Sound({Bank = 'Interface', Cue = 'UI_Economy_Rollover'})
                PlaySound(sound)
            elseif event.Type == 'MouseExit' then
                Tooltip.DestroyMouseoverDisplay()
                if States[prefix.."Detail"] == false then
                    group.income:Hide()
                    group.expense:Hide()
                end
            elseif event.Type == 'ButtonPress' then
                local sound = Sound({Bank = 'Interface', Cue = 'UI_Economy_Click'})
                PlaySound(sound)
                States[prefix.."Detail"] = not States[prefix.."Detail"]
                group.income:SetHidden(not States[prefix.."Detail"])
                group.expense:SetHidden(not States[prefix.."Detail"])
                Prefs.SetToCurrentProfile(prefix.."DetailedView", States[prefix.."Detail"])
            end
            return true
        end
        
-- this causes errors, need to investigate why
--        Tooltip.AddControlTooltip(group.icon, prefix..'_button')
        
        group.storageTooltipGroup.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                Tooltip.CreateMouseoverDisplay(self, prefix .. "_storage", nil, true)
            elseif event.Type == 'MouseExit' then
                Tooltip.DestroyMouseoverDisplay()
            end
            return true
        end
        
        group.rate.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                Tooltip.CreateMouseoverDisplay(self, prefix .. "_rate", nil, true)
            elseif event.Type == 'MouseExit' then
                Tooltip.DestroyMouseoverDisplay()
            elseif event.Type == 'ButtonPress' then
                States[prefix..'ViewState'] = States[prefix..'ViewState'] + 1
                if States[prefix..'ViewState'] > 2 then
                    States[prefix..'ViewState'] = 1
                end
                Prefs.SetToCurrentProfile(prefix..'RateView', States[prefix..'ViewState'])
                local sound = Sound({Bank = 'Interface', Cue = 'UI_Economy_Click'})
                PlaySound(sound)
            end
            return true
        end
    end
    
    AddGroupLogic(GUI.mass, 'mass')
    AddGroupLogic(GUI.energy, 'energy')
        
    GameMain.AddBeatFunction(_BeatFunction)
    GUI.bg.OnDestroy = function(self)
        GameMain.RemoveBeatFunction(_BeatFunction)
    end
    
    GUI.collapseArrow.OnCheck = function(self, checked)
        ToggleEconPanel()
    end
    
    return GUI.mass, GUI.energy
end

function round(value)
    return math.floor(value + .5)
end

function UpdateReclaim(econData)
    local INTERVAL = 10
    local HISTORY_SIZE = 5
    local focus = GetFocusArmy()
    if Reclaim.focus ~= focus then
        Reclaim = {focus=focus, MASS={rate=0, history={}}, ENERGY={rate=0, history={}}}
    end

    if not Reclaim.MASS.history or math.mod(GameTick(), INTERVAL) == 0 then
        for _, t in {'MASS', 'ENERGY'} do
            local reclaimed = econData.reclaimed[t]

            table.insert(Reclaim[t].history, 1, reclaimed)
            Reclaim[t].history[HISTORY_SIZE + 1] = nil

            local n = table.getsize(Reclaim[t].history)
            Reclaim[t].rate = round((reclaimed - Reclaim[t].history[n]) / (n / (10 / INTERVAL)))
        end
    end

    TextLine02:SetText(string.format("%d (%d/s)", econData.reclaimed['MASS'], Reclaim['MASS'].rate))
    TextLine03:SetText(string.format("%d (%d/s)", econData.reclaimed['ENERGY'], Reclaim['ENERGY'].rate))
end

local flags = {full=false, empty=false}
function UpdateEconData(eco, type)
    local smart = options.gui_smart_economy_indicators == 1
    local lower_type = string.lower(type)
    local tps = GetSimTicksPerSecond()
    local controls = GUI[lower_type]
    local viewstate = lower_type..'ViewState'
    local stored = eco['stored'][type]
    local maxStorage = eco['maxStorage'][type]
    local ratio = stored / maxStorage
    local income = eco['income'][type] * tps
    local eff = lastEfficiency[type]

    local key
    if stored > 0.5 then
        key = 'lastUseActual'
    else
        key = 'lastUseRequested'
    end
    
    local expense = eco[key][type] * tps
    local rate = round(income - expense)

    controls.storageBar:SetRange(0, maxStorage)
    controls.storageBar:SetValue(stored)
    controls.curStorage:SetText(round(stored))
    controls.maxStorage:SetText(round(maxStorage))
    controls.income:SetText(string.format("+%d", round(income)))
    controls.expense:SetText(string.format("-%d", round(expense)))

    if expense == 0 then
        eff = 1
    else
        if smart then
            eff = eff * 0.95 + (income / expense) * 0.05
        else
            eff = income / expense
        end
    end

    local rate_str
    if States[viewstate] == 2 then -- show efficiency
        if expense == 0 then
            rate_str = 'infinite'
        else
            rate_str = string.format("%d%%", round(eff * 100))
        end
    else
        rate_str = string.format('%+d', round(rate))
    end
    controls.rate:SetText(rate_str)

    local color = 'ffb7e75f'
    if smart then
        local flag
        if rate < 0 then
            if type == 'ENERGY' and ratio < 0.2 then
                flag = 'empty'
            elseif eff > 0.8 and type == 'MASS' then
            elseif eff > 0.5 then
                color = 'yellow'
            else
                color = 'red'
            end
        elseif type == 'MASS' and ratio > 0.8 then
            flag = 'full'
        end

        if flag then
            if flags[flag] then
                color = 'ff404040'
            else
                color = 'ffffffff'
            end
            flags[flag] = not flags[flag]
        end
    else
        if rate < 0 then
            if stored > 0 then
                color = 'yellow'
            else
                color = 'red'
            end
        end
    end
    controls.rate:SetColor(color)

    local state = 'hide'
    if Prefs.GetOption('econ_warnings') and UIState then
        if ratio < 0.2 then
            if eff < 0.25 then
                state = 'red'
            elseif eff < 0.75 then
                state = 'yellow'
            end
        elseif smart and ratio > 0.8 and type == 'MASS' then
            if eff > 2.0 then
                state = 'red'
            elseif eff > 1.0 then
                state = 'yellow'
            end
        end
    end
    controls.warningBG:SetToState(state)

    lastEfficiency[type] = eff
end

function _BeatFunction()
    local econData = GetEconomyTotals()
    
    UpdateEconData(econData, 'MASS')
    UpdateEconData(econData, 'ENERGY')
    
    if options.gui_display_reclaim_totals == 1 then
        UpdateReclaim(econData)
    end
end

function ToggleEconPanel(state)
    if import('/lua/ui/game/gamemain.lua').gameUIHidden and state ~= nil then
        return
    end
    import(UIUtil.GetLayoutFilename('economy')).TogglePanelAnimation(state)
end

function InitialAnimation()
    import(UIUtil.GetLayoutFilename('economy')).InitAnimation()
end
