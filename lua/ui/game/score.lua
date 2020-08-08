--*****************************************************************************
--* File: lua/modules/ui/game/score.lua
--* Author: Chris Blackwell
--* Summary: In game score dialog
--*
--* Copyright © :2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

-- current score will contain the most recent score update from the sync
currentScores = false

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local GameMain = import('/lua/ui/game/gamemain.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local Text = import('/lua/maui/text.lua').Text
local Grid = import('/lua/maui/Grid.lua').Grid
local Prefs = import('/lua/user/prefs.lua')
local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider
local Tooltip = import('/lua/ui/game/tooltip.lua')
local FindClients = import('/lua/ui/game/chat.lua').FindClients
local scoreMini = import(UIUtil.GetLayoutFilename('score'))

controls = import('/lua/ui/controls.lua').Get()

savedParent = false
local observerLine = false

----  I switched the order of these because it was causing error, originally, the scoreoption line was first
local sessionInfo = SessionGetScenarioInfo()

local lastUnitWarning = false
local unitWarningUsed = false
local issuedNoRushWarning = false
local gameSpeed = 0
local needExpand = false
local contractOnCreate = false
local ScoresCache = {}
local resModeSwitch = {}
local DisplayResMode = 0
local DisplayStorage = 0

function armyGroupHeight()
    local height = 0
    for _, line in controls.armyLines do
        height = height + line.Height()
    end
    return height
end

function CreateScoreUI(parent)
    savedParent = GetFrame(0)

    controls.bg = Group(savedParent)
    controls.bg.Depth:Set(10)

    controls.collapseArrow = Checkbox(savedParent)
    controls.collapseArrow.OnCheck = function(self, checked)
        ToggleScoreControl(not checked)
    end
    Tooltip.AddCheckboxTooltip(controls.collapseArrow, 'score_collapse')

    controls.bgTop = Bitmap(controls.bg)
    controls.bgBottom = Bitmap(controls.bg)
    controls.bgStretch = Bitmap(controls.bg)
    controls.armyGroup = Group(controls.bg)

    controls.leftBracketMin = Bitmap(controls.bg)
    controls.leftBracketMax = Bitmap(controls.bg)
    controls.leftBracketMid = Bitmap(controls.bg)

    controls.rightBracketMin = Bitmap(controls.bg)
    controls.rightBracketMax = Bitmap(controls.bg)
    controls.rightBracketMid = Bitmap(controls.bg)

    controls.leftBracketMin:DisableHitTest()
    controls.leftBracketMax:DisableHitTest()
    controls.leftBracketMid:DisableHitTest()
    controls.rightBracketMin:DisableHitTest()
    controls.rightBracketMax:DisableHitTest()
    controls.rightBracketMid:DisableHitTest()

    controls.bg:DisableHitTest(true)

    LayoutHelpers.SetWidth(controls.bgTop, 320)

    controls.time = UIUtil.CreateText(controls.bgTop, '0', 12, UIUtil.bodyFont)
    controls.time:SetColor('ff00dbff')
    controls.timeIcon = Bitmap(controls.bgTop)
    Tooltip.AddControlTooltip(controls.timeIcon, 'score_time')
    Tooltip.AddControlTooltip(controls.time, 'score_time')
    controls.unitIcon = Bitmap(controls.bgTop)
    Tooltip.AddControlTooltip(controls.unitIcon, 'score_units')
    controls.units = UIUtil.CreateText(controls.bgTop, '0', 12, UIUtil.bodyFont)
    controls.units:SetColor('ffff9900')
    Tooltip.AddControlTooltip(controls.units, 'score_units')

    SetLayout()
    SetupPlayerLines()
    controls.armyGroup.Height:Set(armyGroupHeight())
    scoreMini.LayoutArmyLines()

    GameMain.AddBeatFunction(_OnBeat, true)
    controls.bg.OnDestroy = function(self)
        GameMain.RemoveBeatFunction(_OnBeat)
    end

    if contractOnCreate then
        Contract()
    end

    controls.bg:SetNeedsFrameUpdate(true)
    controls.bg.OnFrame = function(self, delta)
        if controls.collapseArrow:IsChecked() then
            local newRight = self.Right() + (1000 * delta)
            if newRight > savedParent.Right() + self.Width() then
                self.Right:Set(function() return savedParent.Right() + self.Width() end)
                self:Hide()
                self:SetNeedsFrameUpdate(false)
            else
                self.Right:Set(newRight)
            end
        else
            local newRight = self.Right() - (1000*delta)
            if newRight < savedParent.Right() - 3 then
                self.Right:Set(function() return savedParent.Right() - 18 end)
                self:SetNeedsFrameUpdate(false)
            else
                self.Right:Set(newRight)
            end
        end
    end
    controls.collapseArrow:SetCheck(true, true)
end

local function blockOnHide(self, hidden)
    return true
end

local function fmtnum(ns)
    if (math.abs(ns) < 1000) then        -- 0 to 999
        return string.format("%01.0f", ns)
    elseif (math.abs(ns) < 10000) then   -- 1.0K to 9.9K
        return string.format("%01.1fk", ns / 1000)
    elseif (math.abs(ns) < 1000000) then -- 10K to 999K
        return string.format("%01.0fk", ns / 1000)
    else                                 -- 1.0M to ....
        return string.format("%01.1fm", ns / 1000000)
    end
end

function SetLayout()
    if controls.bg then
        scoreMini.SetLayout()
    end
end

local function UpdResDisplay(mode)
    for index, scoreData in ScoresCache do
        if scoreData.resources then
            for _, line in controls.armyLines do
                if line.armyID == index then
                    DisplayResources(scoreData.resources, line, mode)
                    break
                end
            end
        end
    end
end

local function LinesColoring(curFA)
    for _, line in controls.armyLines do
        if curFA > 0 and line.armyID > 0 and IsAlly(curFA, line.armyID) then
            line.bg:SetSolidColor('ff00c000')
            if line.bg:GetAlpha() < 0.2 then
                line.bg:SetAlpha(0.2)
            end
        elseif line.bg.SetSolidColor then
            line.bg:SetSolidColor('ffa0a0a0')
            if line.bg:GetAlpha() < 0.6 then
                line.bg:SetAlpha(0)
            end
        end
    end
end

local function ResourceClickProcessing(self, event, uiGroup, resType)
    if (event.Type == 'MouseEnter') or (event.Type == 'MouseExit') then
        if event.Type == 'MouseEnter' then
            DisplayStorage = DisplayStorage + 1
            UpdResDisplay(2)
        else
            DisplayStorage = DisplayStorage - 1
            UpdResDisplay(DisplayResMode)
        end
    elseif event.Type == 'ButtonPress' then
        --if not event.Modifiers.Left then return end
        local armyID = uiGroup.armyID
        if IsObserver() then return end
        if event.Modifiers.Shift then
            if GetFocusArmy() == armyID then
                SessionSendChatMessage(FindClients(), { from = ScoresCache[GetFocusArmy()].name,
                    to = 'allies', Chat = true, text = 'Who needs '..resType..'?' })
                return
            end
            local scoreData = ScoresCache[armyID]
            if not scoreData.resources then return end
            local EconData = GetEconomyTotals()
            local ResVolume = EconData.stored[string.upper(resType)]
            if ResVolume <= 0 then return end
            local SentValue = scoreData.resources.storage['max'..resType] - scoreData.resources.storage['stored'..resType]
            if SentValue <= 0 then return end
            SentValue = math.min(SentValue,ResVolume * 0.25)
            local Value = {Mass = 0, Energy = 0}
            Value[resType] = SentValue / ResVolume
            SimCallback( { Func = "GiveResourcesToPlayer",
                           Args = { From = GetFocusArmy(), To = armyID,
                           Mass = Value.Mass, Energy = Value.Energy, }} )
            scoreData.resources.storage['stored'..resType] = scoreData.resources.storage['stored'..resType] + SentValue
            uiGroup[string.lower(resType)..'_in']:SetText(fmtnum(scoreData.resources.storage['stored'..resType]))
            SessionSendChatMessage(FindClients(), { from = ScoresCache[GetFocusArmy()].name, to = 'allies', Chat = true,
                text = 'Sent '..resType..' '..fmtnum(SentValue)..' to '..ScoresCache[armyID].name })
        elseif event.Modifiers.Ctrl then
            if GetFocusArmy() == armyID then
                SessionSendChatMessage(FindClients(), { from = ScoresCache[GetFocusArmy()].name,
                    to = 'allies', Chat = true, text = 'Give me '..resType })
            else
                SessionSendChatMessage(FindClients(), { from = ScoresCache[GetFocusArmy()].name,
                    to = 'allies', Chat = true, text = ScoresCache[armyID].name..' give me '..resType })
            end
        end
    end
end

function SetupPlayerLines()
    local function CreateArmyLine(data, armyIndex)
        local group = Group(controls.bgStretch)
        local sw = 42

        group.faction = Bitmap(group)
        if armyIndex ~= 0 then
            group.faction:SetTexture(UIUtil.UIFile(UIUtil.GetFactionIcon(data.faction)))
        else
            group.faction:SetTexture(UIUtil.UIFile('/widgets/faction-icons-alpha_bmp/observer_ico.dds'))
        end
        LayoutHelpers.SetDimensions(group.faction, 14, 14)
        group.faction:DisableHitTest()
        LayoutHelpers.AtLeftTopIn(group.faction, group, -4)

        group.color = Bitmap(group.faction)
        group.color:SetSolidColor(data.color)
        group.color.Depth:Set(function() return group.faction.Depth() - 1 end)
        group.color:DisableHitTest()
        LayoutHelpers.FillParent(group.color, group.faction)

        group.name = UIUtil.CreateText(group, data.nickname, 12, UIUtil.bodyFont)
        group.name:DisableHitTest()
        LayoutHelpers.AtLeftIn(group.name, group, 12)
        LayoutHelpers.AtVerticalCenterIn(group.name, group)
        group.name:SetColor('ffffffff')

        group.score = UIUtil.CreateText(group, '', 12, UIUtil.bodyFont)
        group.score:DisableHitTest()
        LayoutHelpers.AtRightIn(group.score, group, sw * 2 + 16)
        LayoutHelpers.AtVerticalCenterIn(group.score, group)
        group.score:SetColor('ffffffff')

        LayoutHelpers.AnchorToLeft(group.name, group.score, 5)
        group.name:SetClipToWidth(true)

        if armyIndex ~= 0 then
            group.mass = Bitmap(group)
            group.mass:SetTexture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
            LayoutHelpers.AtRightIn(group.mass, group, sw * 1 + 16)
            LayoutHelpers.AtVerticalCenterIn(group.mass, group)
            LayoutHelpers.SetDimensions(group.mass, 14, 14)
            group.mass.HandleEvent = function(self, event)
                ResourceClickProcessing(self, event, group, 'Mass')
            end
            local bodyText = '<LOC tooltipui0716>By Ctrl+click request mass from this ally.\nBy Shift+click gives 25% mass to this ally.'
            Tooltip.AddControlTooltip(group.mass, {text = '', body = bodyText}, 1)

            group.mass_in = UIUtil.CreateText(group, '', 12, UIUtil.bodyFont)
            LayoutHelpers.AtRightIn(group.mass_in, group, sw * 1 + 14 + 16)
            LayoutHelpers.AtVerticalCenterIn(group.mass_in, group)
            group.mass_in:SetColor('ffb7e75f')
            group.mass_in.HandleEvent = function(self, event)
                ResourceClickProcessing(self, event, group, 'Mass')
            end

            group.energy = Bitmap(group)
            group.energy:SetTexture(UIUtil.UIFile('/game/build-ui/icon-energy_bmp.dds'))
            LayoutHelpers.AtRightIn(group.energy, group, sw * 0 + 16)
            LayoutHelpers.AtVerticalCenterIn(group.energy, group)
            LayoutHelpers.SetDimensions(group.energy, 14, 14)
            group.energy.HandleEvent = function(self, event)
                ResourceClickProcessing(self, event, group, 'Energy')
            end
            local bodyText = '<LOC tooltipui0717>By Ctrl+click request energy from this ally.\nBy Shift+click gives 25% energy to this ally.'
            Tooltip.AddControlTooltip(group.energy, {text = '', body = bodyText}, 1)

            group.energy_in = UIUtil.CreateText(group, '', 12, UIUtil.bodyFont)
            LayoutHelpers.AtRightIn(group.energy_in, group, sw * 0 + 14 + 16)
            LayoutHelpers.AtVerticalCenterIn(group.energy_in, group)
            group.energy_in:SetColor('fff7c70f')
            group.energy_in.HandleEvent = function(self, event)
                ResourceClickProcessing(self, event, group, 'Energy')
            end

            group.units = Bitmap(group)
            group.units:SetTexture(UIUtil.UIFile('/textures/ui/icons_strategic/commander_generic.dds'))
            LayoutHelpers.AtRightIn(group.units, group, sw * 0)
            LayoutHelpers.AtVerticalCenterIn(group.units, group)
            LayoutHelpers.SetDimensions(group.units, 14, 14)
            group.units.HandleEvent = function(self, event)
                if (event.Type ~= 'ButtonPress') or (not event.Modifiers.Left) or (IsObserver()) or (GetFocusArmy() == group.armyID) then return end
                if event.Modifiers.Shift then
                    local SelUnits = GetSelectedUnits()
                    if (not SelUnits) or ((table.getn(SelUnits) == 1) and EntityCategoryContains(categories.COMMAND, SelUnits[1])) then return end
                    SimCallback( { Func = "GiveUnitsToPlayer", Args = { From = GetFocusArmy(), To = group.armyID }, }, true)
                    SessionSendChatMessage(FindClients(), { from = ScoresCache[GetFocusArmy()].name,
                        to = 'allies', Chat = true, text = 'Sent units to '..ScoresCache[group.armyID].name })
                elseif event.Modifiers.Ctrl then
                    SessionSendChatMessage(FindClients(), { from = ScoresCache[GetFocusArmy()].name,
                        to = 'allies', Chat = true, text = ScoresCache[group.armyID].name..' give me Engineer' })
                end
            end
            local bodyText = '<LOC tooltipui0718>By Ctrl+click request engineer from this ally.\nBy Shift+click gives selected units to this ally.'
            Tooltip.AddControlTooltip(group.units, {text = '', body = bodyText}, 1)
        end

        group.Height:Set(group.faction.Height)
        group.Width:Set(controls.armyGroup.Width)
        group.armyID = armyIndex

        group.bg = Bitmap(group)
        group.bg:SetSolidColor('ffa0a0a0')
        group.bg:SetAlpha(0)
        group.bg.Height:Set(group.faction.Height)
        group.bg.Left:Set(group.faction.Right)
        group.bg.Right:Set(group.Right)
        group.bg.Top:Set(group.faction.Top)
        group.bg:DisableHitTest()
        group.bg.Depth:Set(group.Depth)
        group.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                self.bg:SetAlpha(0.6)
            elseif event.Type == 'MouseExit' then
                local curFA = GetFocusArmy()
                if curFA > 0 and self.armyID > 0 and IsAlly(curFA, self.armyID) then
                    self.bg:SetAlpha(0.2)
                else
                    self.bg:SetAlpha(0)
                end
            elseif (event.Type == 'ButtonPress') and (not event.Modifiers.Shift) and (not event.Modifiers.Ctrl) then
                ConExecute('SetFocusArmy '..tostring(self.armyID - 1))
                LinesColoring(self.armyID)
            end
        end

        return group
    end

    controls.armyLines = {}
    local index = 1
    for armyIndex, armyData in GetArmiesTable().armiesTable do
        if armyData.civilian or not armyData.showScore then continue end
        controls.armyLines[index] = CreateArmyLine(armyData, armyIndex)
        index = index + 1
    end

    observerLine = CreateArmyLine({color = 'ffffffff', nickname = LOC("<LOC score_0003>Observer")}, 0)
    observerLine:Hide()
    observerLine.OnHide = blockOnHide
    observerLine.name.Top:Set(observerLine.Top)
    LayoutHelpers.SetHeight(observerLine, 15)

    if SessionIsReplay() then
        sessionInfo.Options.Score = 'yes'
        LayoutHelpers.SetHeight(observerLine, 40)
        observerLine.speedText = UIUtil.CreateText(observerLine, '', 12, UIUtil.bodyFont)
        observerLine.speedText:Hide()
        observerLine.speedText:SetColor('ff00dbff')
        LayoutHelpers.AtRightIn(observerLine.speedText, observerLine)
        observerLine.speedSlider = IntegerSlider(observerLine, false, -10, 10, 1,
            UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
            UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'),
            UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
            UIUtil.SkinnableFile('/dialogs/options/slider-back_bmp.dds'))
        observerLine.speedSlider:Hide()
        observerLine.speedSlider.Left:Set(observerLine.Left)
        LayoutHelpers.AtRightIn(observerLine.speedSlider, observerLine, 20)
        observerLine.speedSlider.Bottom:Set(observerLine.Bottom)
        observerLine.speedSlider._background.Left:Set(observerLine.speedSlider.Left)
        observerLine.speedSlider._background.Right:Set(observerLine.speedSlider.Right)
        observerLine.speedSlider._background.Top:Set(observerLine.speedSlider.Top)
        observerLine.speedSlider._background.Bottom:Set(observerLine.speedSlider.Bottom)
        observerLine.speedSlider._thumb.Depth:Set(function() return observerLine.Depth() + 5 end)
        Tooltip.AddControlTooltip(observerLine.speedSlider._thumb, 'Lobby_Gen_GameSpeed')
        observerLine.speedSlider._background.Depth:Set(function() return observerLine.speedSlider._thumb.Depth() - 1 end)
        LayoutHelpers.AtVerticalCenterIn(observerLine.speedText, observerLine.speedSlider)

        observerLine.speedSlider.OnValueChanged = function(self, newValue)
            observerLine.speedText:SetText(string.format("%+d", math.floor(tostring(newValue))))
        end

        observerLine.speedSlider.OnValueSet = function(self, newValue)
            ConExecute("WLD_GameSpeed " .. newValue)
        end
        observerLine.speedSlider:SetValue(gameSpeed)
    end

    local function CreateMapNameLine(data)
        local group = Group(controls.bgStretch)

        group.name = UIUtil.CreateText(group, data.mapname, 10, UIUtil.bodyFont)
        group.name:DisableHitTest()
        LayoutHelpers.AtLeftIn(group.name, group)
        LayoutHelpers.AtVerticalCenterIn(group.name, group)
        group.name:SetColor('ffffffff')

        if sessionInfo.Options.Ranked then
            group.ranked = Bitmap(group)
            group.ranked:SetTexture("/textures/ui/powerlobby/rankedscore.dds")
            LayoutHelpers.SetDimensions(group.ranked, 16, 16)
            group.ranked:DisableHitTest()
            LayoutHelpers.AtRightTopIn(group.ranked, group, -1)
        end

        group.name.Right:Set(group.Right)
        group.name:SetClipToWidth(true)
        LayoutHelpers.SetHeight(group, 19)
        group.Width:Set(controls.armyGroup.Width)
        group:DisableHitTest()

        return group
    end

    for _, line in controls.armyLines do
        local playerName = line.name:GetText()
        local playerRating = sessionInfo.Options.Ratings[playerName] or 0
        local playerClan = sessionInfo.Options.ClanTags[playerName]

        if playerClan and playerClan ~= "" then
            playerClan = '[' .. playerClan .. '] '
        else
            playerClan = ""
        end

        if playerRating then
            playerRating = ' [' .. math.floor(playerRating+0.5) .. ']'
        end

        line.name:SetText(playerClan .. playerName .. playerRating)
    end

    mapData = {}
    mapData.Sizekm = {Width = math.floor(sessionInfo.size[1] / 51.2), Height = math.floor(sessionInfo.size[2] / 51.2)}
    mapData.mapname = LOCF("<LOC gamesel_0002>Map: %s", sessionInfo.name)..' ('..mapData.Sizekm.Width..' x '..mapData.Sizekm.Height..')'
    local replayID = UIUtil.GetReplayId()
    if replayID then
        mapData.mapname = mapData.mapname..', ID: '..replayID
    end

    controls.armyLines[index] = CreateMapNameLine(mapData)

    resModeSwitch.icon = UIUtil.CreateText(controls.armyGroup, '⃝', 13, 'Calibri')
    resModeSwitch.icon.Depth:Set(resModeSwitch.icon.Depth() + 1)
    LayoutHelpers.AtLeftTopIn(resModeSwitch.icon, controls.armyLines[table.getn(controls.armyLines) - 1], 0, -1)
    LayoutHelpers.AtHorizontalCenterIn(resModeSwitch.icon, controls.armyLines[1].energy)
    resModeSwitch.text = UIUtil.CreateText(resModeSwitch.icon, 'I', 10, UIUtil.bodyFont)
    resModeSwitch.text:DisableHitTest()
    LayoutHelpers.AtCenterIn(resModeSwitch.text, resModeSwitch.icon, 1)
    resModeSwitch.text:SetColor('ffffffff')
    resModeSwitch.icon.HandleEvent = function(self, event)
        if event.Type ~= 'ButtonPress' then return end
        if DisplayResMode == 2 then
            DisplayResMode = 0
        else
            DisplayResMode = DisplayResMode + 1
        end
        if DisplayResMode == 0 then
            resModeSwitch.text:SetText('I')
        elseif DisplayResMode == 1 then
            resModeSwitch.text:SetText('B')
        elseif DisplayResMode == 2 then
            resModeSwitch.text:SetText('S')
        end
        UpdResDisplay(DisplayResMode)
    end
    local bodyText = 'I - '..LOC('<LOC tooltipui0714>Income')..'\n B - '..
        LOC('<LOC tooltipui0715>Balance')..'\n S - '..LOC('<LOC uvd_0006>Storage')
    Tooltip.AddControlTooltip(resModeSwitch.icon, {text = '', body = bodyText}, 1)
end

function DisplayResources(resources, line, mode)
    if resources then
        local Tmp = {}
        if mode == 0 then
            Tmp = {Mass = resources.massin.rate, Energy = resources.energyin.rate}
        elseif mode == 1 then
            Tmp = {Mass = resources.massin.rate - resources.massout.rate, Energy = resources.energyin.rate - resources.energyout.rate}
        elseif mode == 2 then
            Tmp = {Mass = resources.storage.storedMass * 0.1, Energy = resources.storage.storedEnergy * 0.1}
        end
        line.mass_in:SetText('  '..fmtnum(Tmp.Mass * 10))
        line.energy_in:SetText('  '..fmtnum(Tmp.Energy * 10))
        line.mass.OnHide = nil
        line.energy.OnHide = nil
        line.units.OnHide = nil
        line.mass:Show()
        line.energy:Show()
        line.units:Show()
    else
        line.mass_in:SetText('')
        line.energy_in:SetText('')
        line.mass:Hide()
        line.energy:Hide()
        line.units:Hide()
        line.mass.OnHide = blockOnHide
        line.energy.OnHide = blockOnHide
        line.units.OnHide = blockOnHide
    end
end

local prevArmy = -2

function _OnBeat()
    local s = string.format("%s (%+d / %+d)", GetGameTime(), gameSpeed, GetSimRate())
    if sessionInfo.Options.Quality then
        s = string.format("%s Q:%.2f%%", s, sessionInfo.Options.Quality)
    end
    controls.time:SetText(s)

    if sessionInfo.Options.NoRushOption and sessionInfo.Options.NoRushOption ~= 'Off' then
        local norush = tonumber(sessionInfo.Options.NoRushOption) * 60
        if norush > GetGameTimeSeconds() then
            local time = norush - GetGameTimeSeconds()
            controls.time:SetText(LOCF('%02d:%02d:%02d', math.floor(time / 3600), math.floor(time/60), math.mod(time, 60)))
        end
        if not issuedNoRushWarning and norush == math.floor(GetGameTimeSeconds()) then
            import('/lua/ui/game/announcement.lua').CreateAnnouncement('<LOC score_0001>No Rush Time Elapsed', controls.time)
            local sound = Sound{ Bank = 'XGG', Cue = 'XGG_Computer_CV01_04766' }
            PlayVoice(sound)
            issuedNoRushWarning = true
        end
    end

    local curFA = GetFocusArmy()
    if currentScores then
        ScoresCache = currentScores
        for index, scoreData in currentScores do
            for _, line in controls.armyLines do
                if line.armyID == index then
                    if scoreData.general.score >= 0 then
                        line.score:SetText(fmtnum(scoreData.general.score))
                    end

                    if DisplayStorage > 0 then
                        DisplayResources(scoreData.resources, line, 2)
                    else
                        DisplayResources(scoreData.resources, line, DisplayResMode)
                    end

                    if (not line.OOG) and (scoreData.Defeated) then
                        line.OOG = true
                        line.faction:SetTexture(UIUtil.UIFile('/game/unit-over/icon-skull_bmp.dds'))
                        line.color:SetSolidColor('ff000000')
                        if GetFocusArmy() ~= index then
                            line.name:SetColor('ffa0a0a0')
                            line.score:SetColor('ffa0a0a0')
                        end
                        line.mass_in:SetColor('ffa0a0a0')
                        line.energy_in:SetColor('ffa0a0a0')
                    end
                    break
                end
            end
        end
        LinesColoring(curFA)

        local scoreData = currentScores[curFA]
        if scoreData.general.currentcap then
            SetUnitText(scoreData.general.currentunits, scoreData.general.currentcap)
        end
        if (curFA > 0) and (not SessionIsReplay()) then
            local di = 1
            for si, data in controls.armyLines do
                if data.armyID > 0 then
                    if data.armyID < controls.armyLines[di].armyID then
                        table.remove(controls.armyLines, si)
                        table.insert(controls.armyLines, di, data)
                        di = di + 1
                    end
                end
            end
            local di = 1
            for si, data in controls.armyLines do
                if data.armyID > 0 then
                    if IsAlly(data.armyID, curFA) then
                        table.remove(controls.armyLines, si)
                        table.insert(controls.armyLines, di, data)
                        di = di + 1
                    end
                end
            end
            scoreMini.LayoutArmyLines()
        end
        local line = {}
        for _, data in controls.armyLines do
            if data.armyID > 0 then
                line = data
            end
        end
        LayoutHelpers.Below(resModeSwitch.icon, line.energy, -1)
        currentScores = false -- dont render score UI until next score update
    end

    if prevArmy ~= curFA then
        for _, line in controls.armyLines do
            if line.armyID == prevArmy then
                if line.OOG then
                    line.name:SetColor('ffa0a0a0')
                    line.score:SetColor('ffa0a0a0')
                else
                    line.name:SetColor('ffffffff')
                    line.score:SetColor('ffffffff')
                end
                line.name:SetFont(UIUtil.bodyFont, 12)
                line.score:SetFont(UIUtil.bodyFont, 12)
            elseif line.armyID == curFA then
                line.name:SetColor('ffff7f00')
                line.score:SetColor('ffff7f00')
                line.name:SetFont('Arial Bold', 12)
                line.score:SetFont('Arial Bold', 12)
            end
        end
        if curFA < 1 then
            observerLine.name:SetColor('ffff7f00')
            observerLine.name:SetFont('Arial Bold', 12)
        elseif prevArmy < 1 then
            observerLine.name:SetColor('ffffffff')
            observerLine.name:SetFont(UIUtil.bodyFont, 12)
        end
        if observerLine:IsHidden() and ((curFA < 1) or (sessionInfo.Options.CheatsEnabled == 'true')) then
            table.insert(controls.armyLines, table.getsize(controls.armyLines), observerLine)
            scoreMini.LayoutArmyLines()
            controls.armyGroup.Height:Set(armyGroupHeight())
            observerLine.OnHide = nil
            observerLine:Show()
            if observerLine.speedText then
                observerLine.speedText:Show()
                observerLine.speedSlider:Show()
            end
        end
        prevArmy = curFA
    end
end

function SetUnitText(current, cap)
    controls.units:SetText(string.format("%d/%d", current, cap))
    if current == cap then
        if (not lastUnitWarning or GameTime() - lastUnitWarning > 60) and not unitWarningUsed then
            import('/lua/ui/game/announcement.lua').CreateAnnouncement(LOC('<LOC score_0002>Unit Cap Reached'), controls.units)
            lastUnitWarning = GameTime()
            unitWarningUsed = true
        end
    else
        unitWarningUsed = false
    end
end

function ToggleScoreControl(state)
    -- disable when in Screen Capture mode
    if import('/lua/ui/game/gamemain.lua').gameUIHidden then
        return
    end

    if not controls.bg then
        import('/lua/ui/game/objectives2.lua').ToggleObjectives()
        return
    end

    if UIUtil.GetAnimationPrefs() then
        if state or controls.bg:IsHidden() then
            Prefs.SetToCurrentProfile("scoreoverlay", true)
            local sound = Sound({Cue = "UI_Score_Window_Open", Bank = "Interface",})
            PlaySound(sound)
            controls.collapseArrow:SetCheck(false, true)
            controls.bg:Show()
            controls.bg:SetNeedsFrameUpdate(true)
        else
            Prefs.SetToCurrentProfile("scoreoverlay", false)
            local sound = Sound({Cue = "UI_Score_Window_Close", Bank = "Interface",})
            PlaySound(sound)
            controls.bg:SetNeedsFrameUpdate(true)
            controls.collapseArrow:SetCheck(true, true)
        end
    else
        if state or controls.bg:IsHidden() then
            Prefs.SetToCurrentProfile("scoreoverlay", true)
            controls.bg:Show()
            local sound = Sound({Cue = "UI_Score_Window_Open", Bank = "Interface",})
            PlaySound(sound)
            controls.collapseArrow:SetCheck(false, true)
        else
            Prefs.SetToCurrentProfile("scoreoverlay", false)
            local sound = Sound({Cue = "UI_Score_Window_Close", Bank = "Interface",})
            PlaySound(sound)
            controls.bg:Hide()
            controls.collapseArrow:SetCheck(true, true)
        end
    end
end

function Expand()
    if needExpand then
        controls.bg:Show()
        controls.collapseArrow:Show()
        local sound = Sound({Cue = "UI_Score_Window_Open", Bank = "Interface",})
        PlaySound(sound)
        needExpand = false
    end
end

function Contract()
    if controls.bg then
        if not controls.bg:IsHidden() then
            local sound = Sound({Cue = "UI_Score_Window_Close", Bank = "Interface",})
            PlaySound(sound)
            controls.bg:Hide()
            controls.collapseArrow:Hide()
            needExpand = true
        else
            needExpand = false
        end
    else
        contractOnCreate = true
    end
end

function InitialAnimation(state)
    controls.bg.Right:Set(savedParent.Right() + controls.bg.Width())
    controls.bg:Hide()
    if Prefs.GetFromCurrentProfile("scoreoverlay") ~= false then
        controls.collapseArrow:SetCheck(false, true)
        controls.bg:Show()
        controls.bg:SetNeedsFrameUpdate(true)
    end
end

function NoteGameSpeedChanged(newSpeed)
    gameSpeed = newSpeed
    if observerLine.speedSlider then
        observerLine.speedSlider:SetValue(gameSpeed)
    end
end

function ArmyAnnounce(army, text)
    if not controls.armyLines then
        return
    end
    local armyLine = false
    for _, line in controls.armyLines do
        if line.armyID == army then
            armyLine = line
            break
        end
    end
    if armyLine then
        import('/lua/ui/game/announcement.lua').CreateAnnouncement(LOC(text), armyLine)
    end
end
