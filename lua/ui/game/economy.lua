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

local _BeatFunction = nil

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
    import(UIUtil.GetLayoutFilename('economy')).SetLayout()
    ConfigureBeatFunction()
    GameMain.RemoveBeatFunction(_BeatFunction)
    GameMain.AddBeatFunction(_BeatFunction)

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
        local reclaimedTitle = UIUtil.CreateText(ecostats, 'reclaimed', 10, UIUtil.bodyFont)

        local massReclaimed = UIUtil.CreateText(ecostats, '', 10, UIUtil.bodyFont)
        massReclaimed:SetColor('FFB8F400')

        local energyReclaimed = UIUtil.CreateText(ecostats, '', 10, UIUtil.bodyFont)
        energyReclaimed:SetColor('FFF8C000')

        -- Attach the textfields to the appropriate GUI groups (slightly hacky, makes life easier
        -- for the beat function though)
        GUI.mass.reclaimed = massReclaimed
        GUI.energy.reclaimed = energyReclaimed

        reclaimedTitle:DisableHitTest(true)
        massReclaimed:DisableHitTest(true)
        energyReclaimed:DisableHitTest(true)

        LayoutHelpers.CenteredAbove(reclaimedTitle, ecostats, -12)
        LayoutHelpers.AtRightTopIn(massReclaimed, ecostats, 4, 10)
        LayoutHelpers.AtRightTopIn(energyReclaimed, ecostats, 4, 20)
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

    GUI.bg.OnDestroy = function(self)
        GameMain.RemoveBeatFunction(_BeatFunction)
    end
    
    GUI.collapseArrow.OnCheck = function(self, checked)
        ToggleEconPanel()
    end
    
    return GUI.mass, GUI.energy
end

--- Build a beat function for updating the UI suitable for the current options.
--
-- The UI must be constructed first.
function ConfigureBeatFunction()
    -- Create an update function for each resource type...

    --- Get a `getRateColour` function.
    --
    -- @param warnFull Should the returned getRateColour function use warning colours for fullness?
    local function getGetRateColour(warnFull)
        local getRateColour
        -- Flags to make things blink.
        local blinkyFlag = true

        if warnFull then
            return function(rateVal, storedVal, maxStorageVal)
                local fractionFull = storedVal / maxStorageVal

                if rateVal < 0 then
                    if storedVal > 0 then
                        return 'yellow'
                    else
                        return 'red'
                    end
                end

                -- Positive rate, check if we're wasting money (and flash irritatingly if so)
                if fractionFull > 0.9 then
                    -- Display flashing gray-white if high on resource.
                    blinkyFlag = not blinkyFlag
                    if blinkyFlag then
                        return 'ff404040'
                    else
                        return 'ffffffff'
                    end
                end

                return 'ffb7e75f'
            end
        else
            return function(rateVal, storedVal, maxStorageVal)
                local fractionFull = storedVal / maxStorageVal

                if rateVal < 0 then
                    if storedVal <= 0 then
                        return 'red'
                    end

                    if fractionFull < 0.2 then
                        -- Display flashing gray-white if low on resource.
                        blinkyFlag = not blinkyFlag
                        if blinkyFlag then
                            return 'ff404040'
                        else
                            return 'ffffffff'
                        end
                    end

                    return 'yellow'
                end

                return 'ffb7e75f'
            end
        end
    end

    local function getResourceUpdateFunction(rType, vState, GUI)
        -- Closure copy
        local resourceType = rType
        local viewState = vState

        local storageBar = GUI.storageBar
        local curStorage = GUI.curStorage
        local maxStorage = GUI.maxStorage
        local incomeTxt = GUI.income
        local expenseTxt = GUI.expense
        local rateTxt = GUI.rate
        local warningBG = GUI.warningBG

        local showReclaim = options.gui_display_reclaim_totals == 1
        local reclaimed
        if showReclaim then
            reclaimed = GUI.reclaimed
        end

        local warnOnResourceFull = resourceType == "MASS"
        local getRateColour = getGetRateColour(warnOnResourceFull)

        local ShowUIWarnings
        if not Prefs.GetOption('econ_warnings') then
            ShowUIWarnings = function() end
        else
            if warnOnResourceFull then
                ShowUIWarnings = function(effVal, storedVal, maxStorageVal)
                    if storedVal / maxStorageVal > 0.8 then
                        if effVal > 2.0 then
                            warningBG:SetToState('red')
                        elseif effVal > 1.0 then
                            warningBG:SetToState('yellow')
                        elseif effVal < 1.0 then
                            warningBG:SetToState('hide')
                        end
                    else
                        warningBG:SetToState('hide')
                    end
                end
            else
                ShowUIWarnings = function(effVal, storedVal, maxStorageVal)
                    if storedVal / maxStorageVal < 0.2 then
                        if effVal < 0.25 then
                            warningBG:SetToState('red')
                        elseif effVal < 0.75 then
                            warningBG:SetToState('yellow')
                        elseif effVal > 1.0 then
                            warningBG:SetToState('hide')
                        end
                    else
                        warningBG:SetToState('hide')
                    end
                end
            end
        end

        -- The quantity of the appropriate resource that had been reclaimed at the end of the last
        -- tick (captured into the returned closure).
        local lastReclaim = 0

        -- Finally, glue all the bits together into a a resource-update function.
        return function()
            local econData = GetEconomyTotals()
            local simFrequency = GetSimTicksPerSecond()

            if showReclaim then
                local totalReclaimed = math.ceil(econData.reclaimed[resourceType])

                -- Reclaimed this tick
                local thisTick = totalReclaimed - lastReclaim

                -- The quantity we'd gain if we reclaimed at this rate for a full second.
                local rate = thisTick * simFrequency

                reclaimed:SetText(string.format("%d (%d/s)", totalReclaimed, rate))
                lastReclaim = totalReclaimed
            end

            -- Extract the economy data from the economy data.
            local maxStorageVal = econData.maxStorage[resourceType]
            local storedVal = econData.stored[resourceType]
            local incomeVal = econData.income[resourceType]

            local average
            if storedVal > 0.5 then
                average = math.min(econData.lastUseActual[resourceType] * simFrequency, 99999999)
            else
                average = math.min(econData.lastUseRequested[resourceType] * simFrequency, 99999999)
            end
            local incomeAvg = math.min(incomeVal * simFrequency, 99999999)

            -- Update the UI
            storageBar:SetRange(0, maxStorageVal)
            storageBar:SetValue(storedVal)
            curStorage:SetText(math.ceil(storedVal))
            maxStorage:SetText(math.ceil(maxStorageVal))

            incomeTxt:SetText(string.format("+%d", math.ceil(incomeAvg)))
            expenseTxt:SetText(string.format("-%d", math.ceil(average)))

            local rateVal = math.ceil(incomeAvg - average)
            local rateStr = string.format('%+d', math.min(math.max(rateVal, -99999999), 99999999))

            local effVal
            if average == 0 then
                effVal = math.ceil(incomeAvg) * 100
            else
                effVal = math.ceil((incomeAvg / average) * 100)
            end

            -- CHOOSE RATE or EFFICIENCY STRING
            if States[viewState] == 2 then
                rateTxt:SetText(string.format("%d%%", math.min(effVal, 100)))
            else
                rateTxt:SetText(string.format("%+s", rateStr))
            end

            rateTxt:SetColor(getRateColour(rateVal, storedVal, maxStorageVal))

            if not UIState then
                return
            end

            ShowUIWarnings(effVal, storedVal, maxStorageVal)
        end
    end

    local massUpdateFunction = getResourceUpdateFunction('MASS', 'massViewState', GUI.mass)
    local energyUpdateFunction = getResourceUpdateFunction('ENERGY', 'energyViewState', GUI.energy)

    _BeatFunction = function()
        massUpdateFunction()
        energyUpdateFunction()
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
