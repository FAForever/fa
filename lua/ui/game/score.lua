--*****************************************************************************
--* File: lua/modules/ui/game/score.lua
--* Author: Chris Blackwell
--* Summary: In game score dialog
--*
--* Copyright © :005 Gas Powered Games, Inc.  All rights reserved.
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

controls = import('/lua/ui/controls.lua').Get()

savedParent = false
local observerLine = false

----  I switched the order of these because it was causing error, originally, the scoreoption line was first
local sessionInfo = SessionGetScenarioInfo()
local replayID = -1


local lastUnitWarning = false
local unitWarningUsed = false
local issuedNoRushWarning = false
local gameSpeed = 0
local needExpand = false
local contractOnCreate = false
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

    SetupPlayerLines()

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

    GameMain.AddBeatFunction(_OnBeat, true)
    controls.bg.OnDestroy = function(self)
        GameMain.RemoveBeatFunction(_OnBeat)
    end

    if contractOnCreate then
        Contract()
    end

    controls.bg:SetNeedsFrameUpdate(true)
    controls.bg.OnFrame = function(self, delta)
        local newRight = self.Right() + (1000*delta)
        if newRight > savedParent.Right() + self.Width() then
            newRight = savedParent.Right() + self.Width()
            self:Hide()
            self:SetNeedsFrameUpdate(false)
        end
        self.Right:Set(newRight)
    end
    controls.collapseArrow:SetCheck(true, true)


end

function fmtnum(ns)
    if (ns < 1000) then         -- 0 to 999
        return string.format("%01.0f", ns)
    elseif (ns < 10000) then   -- 1.0K to 9.9K
        return string.format("%01.1fk", ns / 1000)
    elseif (ns < 1000000) then -- 10K to 999K
        return string.format("%01.0fk", ns / 1000)
    else                       -- 1.0M to ....
        return string.format("%01.1fm", ns / 1000000)
    end
end


function SetLayout()
    if controls.bg then
        import(UIUtil.GetLayoutFilename('score')).SetLayout()
    end
end

function SetupPlayerLines()
    local function CreateArmyLine(data, armyIndex)
        local group = Group(controls.bgStretch)
        local sw = 42

        if armyIndex ~= 0 and SessionIsReplay() then
            group.faction = Bitmap(group)
            if armyIndex ~= 0 then
                group.faction:SetTexture(UIUtil.UIFile(UIUtil.GetFactionIcon(data.faction)))
            else
                group.faction:SetTexture(UIUtil.UIFile('/widgets/faction-icons-alpha_bmp/observer_ico.dds'))
            end
            group.faction.Height:Set(14)
            group.faction.Width:Set(14)
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
            LayoutHelpers.AtRightIn(group.score, group, sw * 2)
            LayoutHelpers.AtVerticalCenterIn(group.score, group)
            group.score:SetColor('ffffffff')

            group.name.Right:Set(group.score.Left)
            group.name:SetClipToWidth(true)

            group.mass = Bitmap(group)
            group.mass:SetTexture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
            LayoutHelpers.AtRightIn(group.mass, group, sw * 1)
            LayoutHelpers.AtVerticalCenterIn(group.mass, group)
            group.mass.Height:Set(14)
            group.mass.Width:Set(14)

            group.mass_in = UIUtil.CreateText(group, '', 12, UIUtil.bodyFont)
            group.mass_in:DisableHitTest()
            LayoutHelpers.AtRightIn(group.mass_in, group, sw * 1+14)
            LayoutHelpers.AtVerticalCenterIn(group.mass_in, group)
            group.mass_in:SetColor('ffb7e75f')

            group.energy = Bitmap(group)
            group.energy:SetTexture(UIUtil.UIFile('/game/build-ui/icon-energy_bmp.dds'))
            LayoutHelpers.AtRightIn(group.energy, group, sw * 0)
            LayoutHelpers.AtVerticalCenterIn(group.energy, group)
            group.energy.Height:Set(14)
            group.energy.Width:Set(14)

            group.energy_in = UIUtil.CreateText(group, '', 12, UIUtil.bodyFont)
            group.energy_in:DisableHitTest()
            LayoutHelpers.AtRightIn(group.energy_in, group, sw * 0+14)
            LayoutHelpers.AtVerticalCenterIn(group.energy_in, group)
            group.energy_in:SetColor('fff7c70f')
        else
            group.faction = Bitmap(group)
            if armyIndex ~= 0 then
                group.faction:SetTexture(UIUtil.UIFile(UIUtil.GetFactionIcon(data.faction)))
            else
                group.faction:SetTexture(UIUtil.UIFile('/widgets/faction-icons-alpha_bmp/observer_ico.dds'))
            end
            group.faction.Height:Set(14)
            group.faction.Width:Set(14)
            group.faction:DisableHitTest()
            LayoutHelpers.AtLeftTopIn(group.faction, group)

            group.color = Bitmap(group.faction)
            group.color:SetSolidColor(data.color)
            group.color.Depth:Set(function() return group.faction.Depth() - 1 end)
            group.color:DisableHitTest()
            LayoutHelpers.FillParent(group.color, group.faction)

            group.name = UIUtil.CreateText(group, data.nickname, 12, UIUtil.bodyFont)
            group.name:DisableHitTest()
             LayoutHelpers.AtLeftIn(group.name, group, 16)
            LayoutHelpers.AtVerticalCenterIn(group.name, group)
            group.name:SetColor('ffffffff')

            group.score = UIUtil.CreateText(group, '', 12, UIUtil.bodyFont)
            group.score:DisableHitTest()
            LayoutHelpers.AtRightIn(group.score, group)
            LayoutHelpers.AtVerticalCenterIn(group.score, group)
            group.score:SetColor('ffffffff')

            group.name.Right:Set(group.score.Left)
            group.name:SetClipToWidth(true)
        end
        group.Height:Set(group.faction.Height)
        group.Width:Set(262)
        group.armyID = armyIndex

        if SessionIsReplay() then
            group.bg = Bitmap(group)
            group.bg:SetSolidColor('00000000')
            group.bg.Height:Set(group.faction.Height)
            group.bg.Left:Set(group.faction.Right)
            group.bg.Right:Set(group.Right)
            group.bg.Top:Set(group.faction.Top)
            group.bg:DisableHitTest()
            group.bg.Depth:Set(group.Depth)
            group.HandleEvent = function(self, event)
                if event.Type == 'MouseEnter' then
                    group.bg:SetSolidColor('ff777777')
                elseif event.Type == 'MouseExit' then
                    group.bg:SetSolidColor('00000000')
                elseif event.Type == 'ButtonPress' then
                    ConExecute('SetFocusArmy '..tostring(self.armyID-1))
                end
            end
        else
            group:DisableHitTest()
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
    if SessionIsReplay() then
        observerLine = CreateArmyLine({color = 'ffffffff', nickname = LOC("<LOC score_0003>Observer")}, 0)
        observerLine.name.Top:Set(observerLine.Top)
        observerLine.Height:Set(40)
        observerLine.speedText = UIUtil.CreateText(controls.bgStretch, '', 14, UIUtil.bodyFont)
        observerLine.speedText:SetColor('ff00dbff')
        LayoutHelpers.AtRightIn(observerLine.speedText, observerLine)
        observerLine.speedSlider = IntegerSlider(controls.bgStretch, false, -10, 10, 1,
            UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
            UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'),
            UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
            UIUtil.SkinnableFile('/dialogs/options/slider-back_bmp.dds'))

        observerLine.speedSlider.Left:Set(function() return observerLine.Left() + 5 end)
        observerLine.speedSlider.Right:Set(function() return observerLine.Right() - 20 end)
        observerLine.speedSlider.Bottom:Set(function() return observerLine.Bottom() - 5 end)
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
        controls.armyLines[index] = observerLine
        index = index + 1
    end
    local function CreateMapNameLine(data, armyIndex)
        local group = Group(controls.bgStretch)

        local mapnamesize = string.len(data.mapname)
        local mapoffset = 131 - (mapnamesize * 2.7)
        if sessionInfo.Options.Ranked then
            mapoffset = mapoffset + 10
        end
        group.name = UIUtil.CreateText(group, data.mapname, 10, UIUtil.bodyFont)
        group.name:DisableHitTest()
        LayoutHelpers.AtLeftIn(group.name, group, mapoffset)
        LayoutHelpers.AtVerticalCenterIn(group.name, group, 1)
        group.name:SetColor('ffffffff')

        if sessionInfo.Options.Ranked then
            group.faction = Bitmap(group)
            group.faction:SetTexture("/textures/ui/powerlobby/rankedscore.dds")
            group.faction.Height:Set(14)
            group.faction.Width:Set(14)
            group.faction:DisableHitTest()
            LayoutHelpers.AtLeftTopIn(group.faction, group.name, -15)
        end

        group.score = UIUtil.CreateText(group, '', 10, UIUtil.bodyFont)
        group.score:DisableHitTest()
        LayoutHelpers.AtRightIn(group.score, group)
        LayoutHelpers.AtVerticalCenterIn(group.score, group)
        group.score:SetColor('ffffffff')
        group.name.Right:Set(group.score.Left)
        group.name:SetClipToWidth(true)
        group.Height:Set(18)
        group.Width:Set(262)
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
    mapData.mapname = LOCF("<LOC gamesel_0002>Map: %s", sessionInfo.name)
    if replayID == -1 then -- only do this once
        if HasCommandLineArg("/syncreplay") and HasCommandLineArg("/gpgnet") and GetFrontEndData('syncreplayid') ~= nil and GetFrontEndData('syncreplayid') ~= 0 then
            replayID = GetFrontEndData('syncreplayid')
        elseif HasCommandLineArg("/savereplay") then
            local url = GetCommandLineArg("/savereplay", 1)[1]
            local lastpos = string.find(url, "/", 20)
            replayID = string.sub(url, 20, lastpos-1)
        elseif HasCommandLineArg("/replayid") then
            replayID =  GetCommandLineArg("/replayid", 1)[1]
        end
    end

    -- Temporarily disabled due to formatting error
    --if tonumber(replayID) > 0 then mapData.mapname = mapData.mapname .. ', ID: ' .. replayID end
    controls.armyLines[index] = CreateMapNameLine(mapData, 0)
end
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
    local armiesInfo = GetArmiesTable().armiesTable
    if currentScores then
        for index, scoreData in currentScores do
            for _, line in controls.armyLines do
                if line.armyID == index then
                    if line.OOG then break end
                    if SessionIsReplay() then
                        if scoreData.resources.massin.rate then
                            line.mass_in:SetText(fmtnum(scoreData.resources.massin.rate * 10))
                            line.energy_in:SetText(fmtnum(scoreData.resources.energyin.rate * 10))
                        end
                    end
                    if scoreData.general.score == -1 then
                        line.score:SetText(LOC("<LOC _Playing>Playing"))
                        line.scoreNumber = -1
                    else
                        line.score:SetText(fmtnum(scoreData.general.score))
                        line.scoreNumber = scoreData.general.score
                    end
                    if GetFocusArmy() == index then
                        line.name:SetColor('ffff7f00')
                        line.score:SetColor('ffff7f00')
                        line.name:SetFont('Arial Bold', 12)
                        line.score:SetFont('Arial Bold', 12)
                        if scoreData.general.currentcap.count > 0 then
                            SetUnitText(scoreData.general.currentunits.count, scoreData.general.currentcap.count)
                        end
                    else
                        line.name:SetColor('ffffffff')
                        line.score:SetColor('ffffffff')
                        line.name:SetFont(UIUtil.bodyFont, 12)
                        line.score:SetFont(UIUtil.bodyFont, 12)
                    end
                    if armiesInfo[index].outOfGame then
                        if scoreData.general.score == -1 then
                            line.score:SetText(LOC("<LOC _Defeated>Defeated"))
                            line.scoreNumber = -1
                        end
                        line.OOG = true
                        line.faction:SetTexture(UIUtil.UIFile('/game/unit-over/icon-skull_bmp.dds'))
                        line.color:SetSolidColor('ff000000')
                        line.name:SetColor('ffa0a0a0')
                        line.score:SetColor('ffa0a0a0')
                        if SessionIsReplay() then
                            line.mass_in:SetColor('ffa0a0a0')
                            line.energy_in:SetColor('ffa0a0a0')
                        end
                    end
                    break
                end
            end
        end
        table.sort(controls.armyLines, function(a,b)
            if a.armyID == 0 or b.armyID == 0 then
                return a.armyID >= b.armyID
            else
                if tonumber(a.scoreNumber) == tonumber(b.scoreNumber) then
                    return a.name:GetText() < b.name:GetText()
                else
                    return tonumber(a.scoreNumber) > tonumber(b.scoreNumber)
                end
            end
        end)
        import(UIUtil.GetLayoutFilename('score')).LayoutArmyLines()
        currentScores = false -- dont render score UI until next score update
    end

    if observerLine then
        if GetFocusArmy() == -1 then
            observerLine.name:SetColor('ffff7f00')
            observerLine.name:SetFont('Arial Bold', 14)
        else
            observerLine.name:SetColor('ffffffff')
            observerLine.name:SetFont(UIUtil.bodyFont, 14)
        end
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
            controls.bg.OnFrame = function(self, delta)
                local newRight = self.Right() - (1000*delta)
                if newRight < savedParent.Right() - 3 then
                    self.Right:Set(function() return savedParent.Right() - 18 end)
                    self:SetNeedsFrameUpdate(false)
                else
                    self.Right:Set(newRight)
                end
            end
        else
            Prefs.SetToCurrentProfile("scoreoverlay", false)
            local sound = Sound({Cue = "UI_Score_Window_Close", Bank = "Interface",})
            PlaySound(sound)
            controls.bg:SetNeedsFrameUpdate(true)
            controls.bg.OnFrame = function(self, delta)
                local newRight = self.Right() + (1000*delta)
                if newRight > savedParent.Right() + self.Width() then
                    self.Right:Set(function() return savedParent.Right() + self.Width() end)
                    self:Hide()
                    self:SetNeedsFrameUpdate(false)
                else
                    self.Right:Set(newRight)
                end
            end
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
        controls.bg.OnFrame = function(self, delta)
            local newRight = self.Right() - (1000*delta)
            if newRight < savedParent.Right() - 3 then
                self.Right:Set(function() return savedParent.Right() - 18 end)
                self:SetNeedsFrameUpdate(false)
            else
                self.Right:Set(newRight)
            end
        end
    end
end

function NoteGameSpeedChanged(newSpeed)
    gameSpeed = newSpeed
    if sessionInfo.Options.GameSpeed and sessionInfo.Options.GameSpeed == 'adjustable' and controls.time then
        controls.time:SetText(string.format("%s (%+d)", GetGameTime(), gameSpeed))
    end
    if observerLine then
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
