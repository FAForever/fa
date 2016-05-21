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
    energyViewState = Prefs.GetFromCurrentProfile("energyRateView") or 1,
    massViewState = Prefs.GetFromCurrentProfile("massRateView") or 1,
}

function Contract()
    UIState = false
end

function Expand()
    UIState = true
end

function SetLayout(layout)
    import(UIUtil.GetLayoutFilename('economy')).SetLayout()
    GameMain.RemoveBeatFunction(_BeatFunction)
    ConfigureBeatFunction()
    GameMain.AddBeatFunction(_BeatFunction, true)

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

        group.reclaimDelta = UIUtil.CreateText(group.warningBG, '', 10, UIUtil.bodyFont)
        group.reclaimDelta:SetDropShadow(true)

        group.reclaimTotal = UIUtil.CreateText(group.warningBG, '', 10, UIUtil.bodyFont)
        group.reclaimTotal:SetDropShadow(true)

        group.warningBG:DisableHitTest()
        group.curStorage:DisableHitTest()
        group.maxStorage:DisableHitTest()
        group.storageBar:DisableHitTest()

        return group
    end

    GUI.mass = CreateResourceGroup('mass')
    GUI.energy = CreateResourceGroup('energy')
end

function CommonLogic()
    local function AddGroupLogic(group, prefix)
        group.warningBG.OnHide = function(self, hidden)
            -- This prevents the text controls appearing at game-start before the scroll-in
            -- animation has taken place.
            group.income:SetHidden(hidden)
            group.expense:SetHidden(hidden)
            group.reclaimDelta:SetHidden(hidden)
            group.reclaimTotal:SetHidden(hidden)

            return true
        end

        Tooltip.AddControlTooltip(group.reclaimDelta, prefix..'_reclaim_display')
        Tooltip.AddControlTooltip(group.reclaimTotal, prefix..'_reclaim_display')
        Tooltip.AddControlTooltip(group.income, prefix..'_income_display')
        Tooltip.AddControlTooltip(group.expense, prefix..'_income_display')

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
    local function fmtnum(n)
        return math.round(math.clamp(n, 0, 99999999))
    end

    local function getGetRateColour(warnFull, blink)
        local getRateColour
        -- Flags to make things blink.
        local blinkyFlag = true
        local blink = blink

        -- Counter to give up if the user stopped caring.
        local blinkyCounter = 0

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
                if fractionFull >= 1 and blink then
                    blinkyCounter = blinkyCounter + 1
                    if blinkyCounter > 100 then
                        return 'ffffffff'
                    end

                    -- Display flashing gray-white if high on resource.
                    blinkyFlag = not blinkyFlag
                    if blinkyFlag then
                        return 'ff404040'
                    else
                        return 'ffffffff'
                    end
                else
                    blinkyCounter = 0
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

                    if fractionFull < 0.2 and blink then
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

        local reclaimDelta = GUI.reclaimDelta
        local reclaimTotal = GUI.reclaimTotal

        local econ_warnings = Prefs.GetOption('econ_warnings')
        local warnOnResourceFull = resourceType == "MASS" and econ_warnings
        local getRateColour = getGetRateColour(warnOnResourceFull, econ_warnings)

        local ShowUIWarnings
        if not econ_warnings then
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
        local lastReclaimTotal = 0
        local lastReclaimRate = 0

        -- Finally, glue all the bits together into a a resource-update function.
        return function()
            local econData = GetEconomyTotals()
            local simFrequency = GetSimTicksPerSecond()

            -- Deal with the reclaim column
            -------------------------------
            local totalReclaimed = econData.reclaimed[resourceType]

            -- Reclaimed this tick
            local thisTick = totalReclaimed - lastReclaimTotal

            -- Set a new lastReclaimTotal to carry over
            lastReclaimTotal = totalReclaimed

            -- The quantity we'd gain if we reclaimed at this rate for a full second.
            local reclaimRate = thisTick * simFrequency

            -- Set the text
            reclaimDelta:SetText('+' .. fmtnum(reclaimRate))
            reclaimTotal:SetText(fmtnum(totalReclaimed))

            -- Deal with the Storage
            ------------------------
            local maxStorageVal = econData.maxStorage[resourceType]
            local storedVal = econData.stored[resourceType]

            -- Set the bar fill
            storageBar:SetRange(0, maxStorageVal)
            storageBar:SetValue(storedVal)

            -- Set the text displays
            curStorage:SetText(math.round(storedVal))
            maxStorage:SetText(math.round(maxStorageVal))

            -- Deal with the income/expense column
            --------------------------------------
            local incomeVal = econData.income[resourceType]

            -- Should always be positive integer
            local incomeSec = math.max(0, incomeVal * simFrequency)
            local generatedIncome = incomeSec - lastReclaimRate

            -- How much are we wanting to drain?
            local expense
            if storedVal > 0.5 then
                expense = econData.lastUseActual[resourceType] * simFrequency
            else
                expense = econData.lastUseRequested[resourceType] * simFrequency
            end

            -- Set the text displays. incomeTxt should be only from non-reclaim.
            -- incomeVal is delayed by 1 tick when it comes to accounting for reclaim.
            -- This necessitates the use of the lastReclaimRate stored value.
            incomeTxt:SetText(string.format("+%d", fmtnum(generatedIncome)))
            expenseTxt:SetText(string.format("-%d", fmtnum(expense)))

            -- Store this tick's reclaimRate for next tick
            lastReclaimRate = reclaimRate

            -- Deal with the primary income/expense display
            -----------------------------------------------

            -- incomeSec and expense are already limit-checked and integers
            local rateVal = incomeSec - expense

            -- Calculate resource usage efficiency for % display mode
            local effVal
            if expense == 0 then
                effVal = incomeSec * 100
            else
                effVal = math.round((incomeSec / expense) * 100)
            end

            -- Choose to display efficiency or rate
            if States[viewState] == 2 then
                rateTxt:SetText(string.format("%d%%", math.min(effVal, 100)))
            else
                rateTxt:SetText(string.format("%+d", rateVal))
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
