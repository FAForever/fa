--*****************************************************************************
--* File: lua/modules/ui/game/economy.lua
--* Author: Chris Blackwell
--* Summary: Economy bar UI
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
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

local filteredEnergy = 1
local filteredMass = 1
local fullFlag = false
local emptyFlag = false


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
            if self.State != state then
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

function _BeatFunction()
    local econData = GetEconomyTotals()
    local simFrequency = GetSimTicksPerSecond()
    if options.gui_display_reclaim_totals == 1 then
    -- fetch & format reclaim values
        reclaimedTotalsMass = math.ceil(econData.reclaimed.MASS)
        reclaimedTotalsEnergy = math.ceil(econData.reclaimed.ENERGY)
    end
    

    if options.gui_smart_economy_indicators == 1 then
        local function DisplayEconData(controls, tableID, viewPref, filtered, warnfull)
            local maxStorageVal = econData["maxStorage"][tableID]
            local storedVal = econData["stored"][tableID]
            local incomeVal = econData["income"][tableID]
            local lastRequestedVal = econData["lastUseRequested"][tableID]
            local lastActualVal = econData["lastUseActual"][tableID]

            local requestedAvg = math.min(lastRequestedVal * simFrequency, 99999999)
            local actualAvg = math.min(lastActualVal * simFrequency, 99999999)
            local incomeAvg = math.min(incomeVal * simFrequency, 99999999)

            controls.storageBar:SetRange(0, maxStorageVal)
            controls.storageBar:SetValue(storedVal)
            controls.curStorage:SetText(math.ceil(storedVal))
            controls.maxStorage:SetText(math.ceil(maxStorageVal))

            controls.income:SetText(string.format("+%d", math.ceil(incomeAvg)))
            if (storedVal > 0.5) then
                controls.expense:SetText(string.format("-%d", math.ceil(actualAvg)))
            else
                controls.expense:SetText(string.format("-%d", math.ceil(requestedAvg)))
            end

            local rateVal = 0
            if storedVal > 0.5 then
                rateVal = math.ceil(incomeAvg - actualAvg)
            else
                rateVal = math.ceil(incomeAvg - requestedAvg)
            end


            -- CHANGED by THYGRRR: Effective value calculation and rate calculation separated.
            local rateStr = string.format('%+d', math.min(math.max(rateVal, -99999999), 99999999))
            local effVal = 0
            if (options.gui_smart_economy_indicators == 1) then
                -- CHANGED BY THYGRRR: inlined local function to facilitate easier filtering
                if (requestedAvg == 0) then
                    effVal = "infinite"
                else
                    if (storedVal > 0.5) then
                        filtered = filtered * 0.95 + (incomeAvg / actualAvg) * 0.05
                        effVal = string.format("%d%%", math.ceil(filtered * 100))
                    else
                        filtered = filtered * 0.95 + (incomeAvg / requestedAvg) * 0.05
                        effVal = string.format("%d%%", math.ceil(filtered * 100))
                    end
                end
            else
                -- CHANGED BY THYGRRR: option turned off, normal behavior (re-coded though)
                if (requestedAvg == 0) then
                    effVal = "100%"
                    filtered = 1.0
                else
                    if (storedVal > 0.5) then
                        filtered = (incomeAvg / actualAvg)
                        effVal = string.format("%d%%", math.min(math.ceil(filtered * 100), 100))
                    else
                        filtered = (incomeAvg / requestedAvg)
                        effVal = string.format("%d%%", math.min(math.ceil(filtered * 100), 100))
                    end
                end
            end

            -- CHOOSE RATE or EFFICIENCY STRING - CHANGED BY THYGRRR: Allow more than 100% - removed: math.min(effVal, 100)
            if States[viewPref] == 2 then
                controls.rate:SetText(effVal)
            else
                controls.rate:SetText(string.format("%+s", rateStr))
            end

            -- SET RATE/EFFICIENCY COLOR
            local rateColor
            if (rateVal < 0) then
                if (options.gui_smart_economy_indicators == 1) and (not warnfull) and (storedVal / maxStorageVal < 0.2) then
                    --THYGRRR: display flashing gray-white if low on resource and warnfull is false ('warnempty')
                    if (emptyFlag) then
                        emptyFlag = false
                        rateColor = 'ff404040'
                    else
                        emptyFlag = true
                        rateColor = 'ffffffff'
                    end
                else
                    -- SITUATION SPECIFIC COLOR CODE, modified to use filtered value and go red below 50%, and green above 80%
                    if (options.gui_smart_economy_indicators == 1) then
                        if (filtered > 0.8) and (warnfull) then
                            rateColor = 'ffb7e75f'
                        else
                            if (filtered > 0.5) then
                                rateColor = 'yellow'
                            else
                                rateColor = 'red'
                            end
                        end
                    else
                        -- OLD COLOR CODE
                        if (rateVal < 0) then
                            if (storedVal > 0) then
                                rateColor = 'yellow'
                            else
                                rateColor = 'red'
                            end
                        else
                            rateColor = 'ffb7e75f'
                        end
                    end
                end
            else
                if (options.gui_smart_economy_indicators == 1) and (warnfull) and (storedVal / maxStorageVal > 0.8) then
                    --THYGRRR: display flashing gray-white if high on resource and warnfull is true
                    if (fullFlag) then
                        fullFlag = false
                        rateColor = 'ff404040'
                    else
                        fullFlag = true
                        rateColor = 'ffffffff'
                    end
                else
                    -- ORIGINAL COLOR CODE
                    rateColor = 'ffb7e75f'
                end
            end
            controls.rate:SetColor(rateColor)

            -- ECONOMY WARNINGS
            -- CHANGED BY THYGRRR: Use the filtered value, which is cleaner
            if Prefs.GetOption('econ_warnings') and UIState then
                if (warnfull) and (options.gui_smart_economy_indicators == 1) then
                    if (storedVal / maxStorageVal > 0.8) then
                        if (filtered > 2.0) then
                            controls.warningBG:SetToState('red')
                        elseif (filtered > 1.0) then
                            controls.warningBG:SetToState('yellow')
                        elseif (filtered < 1.0) then
                            controls.warningBG:SetToState('hide')
                        end
                    else
                        controls.warningBG:SetToState('hide')
                    end
                else
                    -- original behavior
                    if (storedVal / maxStorageVal < 0.2) then
                        if (filtered < 0.25) then
                            controls.warningBG:SetToState('red')
                        elseif (filtered < 0.75) then
                            controls.warningBG:SetToState('yellow')
                        elseif (filtered > 1.0) then
                            controls.warningBG:SetToState('hide')
                        end
                    else
                        controls.warningBG:SetToState('hide')
                    end
                end
            else
                controls.warningBG:SetToState('hide')
            end

            return filtered
        end        
        if options.gui_display_reclaim_totals == 1 then
            TextLine02:SetText(reclaimedTotalsMass)
            TextLine03:SetText(reclaimedTotalsEnergy)
        end
        filteredEnergy = DisplayEconData(GUI.energy, 'ENERGY', 'energyViewState', filteredEnergy, false)
        filteredMass = DisplayEconData(GUI.mass, 'MASS', 'massViewState', filteredMass, true)        

    else
        local function DisplayEconData(controls, tableID, viewPref)
            local function FormatRateString(RateVal, StoredVal, IncomeAvg, ActualAvg, RequestedAvg)
                
                local retRateStr = string.format('%+d', math.min(math.max(RateVal, -99999999), 99999999))

                local retEffVal = 0
                if RequestedAvg == 0 then
                    retEffVal = math.ceil(IncomeAvg) * 100
                else
                    if StoredVal > 0.5 then
                        retEffVal = math.ceil( (IncomeAvg / ActualAvg) * 100 )
                    else
                        retEffVal = math.ceil( (IncomeAvg / RequestedAvg) * 100 )
                    end    
                end
                return retRateStr, retEffVal
            end
            
            local maxStorageVal = econData["maxStorage"][tableID]
            local storedVal = econData["stored"][tableID]
            local incomeVal = econData["income"][tableID]
            local lastRequestedVal = econData["lastUseRequested"][tableID]
            local lastActualVal = econData["lastUseActual"][tableID]
        
            local requestedAvg = math.min(lastRequestedVal * simFrequency, 99999999)
            local actualAvg = math.min(lastActualVal * simFrequency, 9999999)
            local incomeAvg = math.min(incomeVal * simFrequency, 99999999)
            
            controls.storageBar:SetRange(0, maxStorageVal)
            controls.storageBar:SetValue(storedVal)
            controls.curStorage:SetText(math.ceil(storedVal))
            controls.maxStorage:SetText(math.ceil(maxStorageVal))
            
            controls.income:SetText(string.format("+%d", math.ceil(incomeAvg)))
            if storedVal > 0.5 then
                controls.expense:SetText(string.format("-%d", math.ceil(actualAvg)))
            else
                controls.expense:SetText(string.format("-%d", math.ceil(requestedAvg)))
            end
        
            local rateVal = 0
            if storedVal > 0.5 then
                rateVal = math.ceil(incomeAvg - actualAvg)
            else
                rateVal = math.ceil(incomeAvg - requestedAvg)
            end
            local rateStr = string.format('%+d', math.min(math.max(rateVal, -99999999), 99999999))
            local rateStr, effVal = FormatRateString(rateVal, storedVal, incomeAvg, actualAvg, requestedAvg)
        -- CHOOSE RATE or EFFICIENCY STRING
            if States[viewPref] == 2 then
                controls.rate:SetText(string.format("%d%%", math.min(effVal, 100)))   
            else
                controls.rate:SetText(string.format("%+s", rateStr))
            end
        -- SET RATE/EFFICIENCY COLOR
            local rateColor
            if rateVal < 0 then
                if storedVal > 0 then
                    rateColor = 'yellow'
                else
                    rateColor = 'red'
                end
            else
                rateColor = 'ffb7e75f'
            end
            controls.rate:SetColor(rateColor)
            
        -- ECONOMY WARNINGS        
            if Prefs.GetOption('econ_warnings') and UIState then
                if storedVal / maxStorageVal < .2 then
                    if effVal < 25 then
                        controls.warningBG:SetToState('red')
                    elseif effVal < 75 then
                        controls.warningBG:SetToState('yellow')
                    elseif effVal > 100 then
                        controls.warningBG:SetToState('hide')
                    end
                else
                    controls.warningBG:SetToState('hide')
                end
            else
                controls.warningBG:SetToState('hide')
            end
        end
        
        DisplayEconData(GUI.mass, 'MASS', 'massViewState')
        DisplayEconData(GUI.energy, 'ENERGY', 'energyViewState')

        if options.gui_display_reclaim_totals == 1 then
            TextLine02:SetText(reclaimedTotalsMass)
            TextLine03:SetText(reclaimedTotalsEnergy)
        end
    end
end

function ToggleEconPanel(state)
    if import('/lua/ui/game/gamemain.lua').gameUIHidden and state != nil then
        return
    end
    import(UIUtil.GetLayoutFilename('economy')).TogglePanelAnimation(state)
end

function InitialAnimation()
    import(UIUtil.GetLayoutFilename('economy')).InitAnimation()
end