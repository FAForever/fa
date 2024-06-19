--*****************************************************************************
--* File: lua/modules/ui/game/diplomacy.lua
--* Summary: UI for the diplomacy control
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

---@alias DiplomacyActionType "accept" | "break" | "never" | "offer" | "reject"

---@class DiplomacyAction
---@field Action DiplomacyActionType
---@field To number army index
---@field From number army index

local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local StatusBar = import("/lua/maui/statusbar.lua").StatusBar
local Slider = import("/lua/maui/slider.lua").Slider
local Tooltip = import("/lua/ui/game/tooltip.lua")
local Tabs = import("/lua/ui/game/tabs.lua")

local ScaleNumber = LayoutHelpers.ScaleNumber
local Layouter = LayoutHelpers.LayoutFor
local CreateBitmap = UIUtil.CreateBitmap
local CreateBitmapStd = UIUtil.CreateBitmapStd

---@type Group
local parent = false
local shareResources = true
local alliedVictory = true

local dialogue = false
local offerQueue = {}
local drawOffered = false

---@type CannotRecallReason
local CannotRequestRecallReason = false

---@return CannotRecallReason
function GetCannotRequestRecallReason()
    return CannotRequestRecallReason
end

---@param reason CannotRecallReason
function SetCannotRequestRecallReason(reason)
    CannotRequestRecallReason = reason
    if parent then
        local button = parent.personalGroup.button
        local tooltipID
        if reason then
            if not button:IsDisabled() then
                local over = button.mMouseOver
                button:Disable()
                button:EnableHitTest() -- let the tooltip show
                button.mMouseOver = over
            end
            tooltipID = "dip_recall_request_dis_" .. reason
        else
            if button:IsDisabled() then
                button:Enable()
            end
            tooltipID = "dip_recall_request"
        end
        Tooltip.AddButtonTooltip(button, tooltipID)
        if button.mMouseOver then
            Tooltip.DestroyMouseoverDisplay()
            Tooltip.CreateMouseoverDisplay(button, tooltipID, nil, true, nil)
        end
    end
end

function ActionHandler(actions)
    local armies = GetArmiesTable().armiesTable
    for _, action in actions do
        local from = armies[action.From].nickname
        local actionName = action.Action
        if actionName == 'offer' then
            if not dialogue then
                dialogue = CreateOfferDialogue(action)
            else
                table.insert(offerQueue, action)
            end
        elseif actionName == 'accept' then
            Announce(LOC('<LOC diplomacy_0005>%s accepts your alliance.'):format(from))
        elseif actionName == 'reject' then
            Announce(LOC('<LOC diplomacy_0006>%s rejects your alliance.'):format(from))
        elseif actionName == 'never' then
            Announce(LOC('<LOC diplomacy_0007>%s is now ignoring your requests.'):format(from))
        elseif actionName == 'break' then
            Announce(LOC('<LOC diplomacy_0008>Your alliance with %s has been broken.'):format(from))
        end
    end
end

function AnnouncementHandler(announcements)
    local armies = GetArmiesTable().armiesTable
    for _, announcement in announcements do
        local announcementName = announcement.Action
        if announcementName == "accept" then
            Announce(LOC('<LOC diplomacy_0009>%s and %s are now allies.'):format(armies[announcement.From].nickname, armies[announcement.To].nickname))
        elseif announcementName == "break" then
            Announce(LOC('<LOC diplomacy_0010>%s and %s are no longer allies.'):format(armies[announcement.From].nickname, armies[announcement.To].nickname))
        elseif announcementName == "recall" then
            Announce(LOC('<LOC diplomacy_0020>Team %s has recalled from battle.'):format(announcement.Team))
        end
    end
end

function Announce(msg)
    Tabs.TabAnnouncement('diplomacy', msg)
    if parent then
        BuildPlayerLines()
    end
end

function CreateOfferDialogue(action)
    local from = action.From
    local army = GetArmiesTable().armiesTable[from].nickname
    return UIUtil.QuickDialog(
        GetFrame(0),
        LOC("<LOC diplomacy_0004>%s has offered you an alliance."):format(army),
        "<LOC _Accept>", function() SendAnswer(from, 'accept') end,
        "<LOC _Reject>", function() SendAnswer(from, 'reject') end,
        "<LOC _Never>",  function() SendAnswer(from, 'never') end,
        true, {
            escapeButton = 2,
            enterButton = 1,
            worldCover = false,
            OnlyWorldCover = true,
        }
    )
end

function SendAnswer(army, answer)
    SimCallback({
        Func = 'DiplomacyHandler',
        Args = {
            Action = answer,
            From = GetFocusArmy(),
            To = army,
        },
    })
    local i = 1
    local offer = offerQueue[i]
    while offer do
        if offer.From == army then
            table.remove(offerQueue, i)
        else
            i = i + 1
        end
        offer = offerQueue[i]
    end
    offer = offerQueue[1]
    if offer then
        CreateOfferDialogue(offer)
        table.remove(offerQueue, 1)
    else
        dialogue = false
    end
end

function CreateContent(inParent)
    parent = Group(inParent)

    BuildPlayerLines()

    LayoutHelpers.SetWidth(parent, 266)
    parent.OnDestroy = function(self)
        parent = false
    end

    return parent
end

local function LayoutMajorAlliedEntry(entry, manualShare)
    local giveUnitBtn = UIUtil.CreateButtonStd(entry,
        '/dialogs/toggle_btn/toggle-d',
        '<LOC diplomacy_0011>Units', 12
    )
    giveUnitBtn.label:SetFont(UIUtil.bodyFont, 12)
    LayoutHelpers.Below(giveUnitBtn, entry.factionIcon, -2)
    LayoutHelpers.AtLeftIn(giveUnitBtn, entry)
    Tooltip.AddButtonTooltip(giveUnitBtn, 'dip_give_units')
    entry.giveUnitBtn = giveUnitBtn

    if manualShare == 'none' then
        giveUnitBtn:Disable()
    else
        giveUnitBtn.OnClick = function(self, modifiers)
            UIUtil.QuickDialog(GetFrame(0),
                LOC("<LOC unitxfer_0000>Give Selected Units to %s?"):format(entry.Data.nickname),
                '<LOC _Yes>',
                function()
                    local to = entry.Data.armyIndex
                    if IsKeyDown('Shift') then
                        IssueCommand("UNITCOMMAND_Script", {TaskName = 'GiveTask', To = to}, false)
                    else
                        SimCallback({
                            Func = "GiveUnitsToPlayer",
                            Args = {
                                From = GetFocusArmy(),
                                To = to,
                            },
                        }, true)
                    end
                end,
                '<LOC _No>', nil, nil, nil, nil,
                {worldCover = false, enterButton = 1, escapeButton = 2}
            )
        end
    end

    local giveResourcesBtn = UIUtil.CreateButtonStd(entry,
        '/dialogs/toggle_btn/toggle-d',
        '<LOC diplomacy_0012>Resources', 12
    )
    LayoutHelpers.RightOf(giveResourcesBtn, giveUnitBtn)
    giveResourcesBtn.label:SetFont(UIUtil.bodyFont, 12)
    Tooltip.AddButtonTooltip(giveResourcesBtn, 'dip_give_resources')
    entry.giveResourcesBtn = giveResourcesBtn

    giveResourcesBtn.OnClick = function(self, modifiers)
        CreateShareResourcesDialog(entry)
    end
end

local function LayoutAlliedEntry(entry, armyIndex, isHuman, outOfGame, teamsLocked, manualShare)
    if isHuman and not outOfGame then
        LayoutMajorAlliedEntry(entry, manualShare)
    end

    if teamsLocked then
    else
        if not outOfGame then
            local breakBtn = UIUtil.CreateButtonStd(entry,
                "/dialogs/toggle_btn/toggle-d",
                "<LOC diplomacy_0013>Break", 12
            )
            breakBtn.label:SetFont(UIUtil.bodyFont, 12)
            LayoutHelpers.Below(breakBtn, entry.factionIcon, -2)
            LayoutHelpers.AtRightIn(breakBtn, entry)
            LayoutHelpers.ResetLeft(breakBtn)
            Tooltip.AddButtonTooltip(breakBtn, "dip_break_alliance")
            entry.breakBtn = breakBtn

            breakBtn.OnClick = function(self, checked)
                SimCallback({
                    Func = "DiplomacyHandler",
                    Args = {
                        Action = "break",
                        From = GetFocusArmy(),
                        To = armyIndex,
                    },
                })
                ForkThread(function()
                    WaitSeconds(1)
                    BuildPlayerLines()
                end)
            end
        end
    end
end

local function LayoutEnemyEntry(entry, armyIndex, isHuman, outOfGame, teamsLocked)
    if isHuman and not teamsLocked and not outOfGame then
        local offerBtn = UIUtil.CreateButtonStd(entry,
            '/dialogs/toggle_btn/toggle-d',
            '<LOC diplomacy_0014>Offer', 12
        )
        offerBtn.label:SetFont(UIUtil.bodyFont, 12)
        LayoutHelpers.AtRightBottomIn(offerBtn, entry)
        Tooltip.AddButtonTooltip(offerBtn, 'dip_offer_alliance')
        entry.offerBtn = offerBtn

        offerBtn.OnClick = function(self, checked)
            self:Disable()
            SimCallback({
                Func = 'DiplomacyHandler',
                Args = {
                    Action = 'offer',
                    From = GetFocusArmy(),
                    To = armyIndex,
                },
            })
        end
    end
end

local function CreateDiplomacyEntry(parent, data, isAlly)
    local sessionOptions = SessionGetScenarioInfo().Options
    local isHuman = data.human
    local outOfGame = data.outOfGame
    local teamsLocked = sessionOptions and sessionOptions.TeamLock == "locked"
    local manualShare = sessionOptions.ManualUnitShare
    local armyIndex = data.armyIndex

    local entry = Bitmap(parent)
    entry.Height:Set(function()
        local data = entry.Data
        if (isAlly or isHuman) and not data.outOfGame then
            return entry.factionIcon.Height() + 12 + ScaleNumber(12)
        else
            return entry.factionIcon.Height() + ScaleNumber(4)
        end
    end)
    entry.Width:Set(function() return parent.Width() - 12 end)
    entry.Depth:Set(function() return parent.Depth() + 10 end)
    entry:SetSolidColor('00000000')
    entry.Data = data

    local typeIcon, factionIcon, colorIcon
    if isHuman then
        typeIcon = "/game/options-diplomacy-panel/icon-person"
    else
        typeIcon = "/game/options-diplomacy-panel/icon-ai"
    end
    if outOfGame then
        factionIcon = "/game/unit-over/icon-skull_bmp.dds"
        colorIcon = "ff000000"
    else
        factionIcon = UIUtil.GetFactionIcon(data.faction)
        colorIcon = data.color
    end

    typeIcon = CreateBitmapStd(entry, typeIcon)
    LayoutHelpers.AtLeftIn(typeIcon, entry)
    entry.typeIcon = typeIcon

    factionIcon = CreateBitmap(entry, factionIcon)
    LayoutHelpers.RightOf(factionIcon, typeIcon)
    LayoutHelpers.AtTopIn(factionIcon, entry)
    entry.factionIcon = factionIcon

    LayoutHelpers.AtVerticalCenterIn(typeIcon, factionIcon)

    colorIcon = UIUtil.CreateBitmapColor(factionIcon, colorIcon)
    colorIcon.Depth:Set(function() return factionIcon.Depth() - 1 end)
    LayoutHelpers.FillParent(colorIcon, factionIcon)
    entry.color = colorIcon

    local name = UIUtil.CreateText(entry, data.nickname, 16, UIUtil.bodyFont)
    LayoutHelpers.AtRightIn(name, entry)
    LayoutHelpers.AnchorToRight(name, factionIcon, 5)
    LayoutHelpers.AtVerticalCenterIn(name, factionIcon)
    entry.name = name

    if isAlly then
        LayoutAlliedEntry(entry, armyIndex, isHuman, outOfGame, teamsLocked, manualShare)
    else
        LayoutEnemyEntry(entry, armyIndex, isHuman, outOfGame, teamsLocked)
    end

    return entry
end

local function CreatePlayerGroup(parent, panelFilename, titleLoc, titleColor, controls, controlCount, isAlly)
    local lineFilename = panelFilename .. "-line"
    local group = UIUtil.CreateVertFillGroup(parent, panelFilename)

    local title = UIUtil.CreateText(group, titleLoc, 18, UIUtil.bodyFont)
    Layouter(title)
        :Color(titleColor)
        :DropShadow(true)
        :Over(group, 10)
    title.Left:Set(function() return group.Left() + 8 end)
    title.Top:Set(function() return group.Top() + 8 end)
    title.Right:Set(function() return group.Right() - 8 end)

    local entry = CreateDiplomacyEntry(group, controls[1], isAlly)
    LayoutHelpers.Below(entry, title, 4)
    local belowEntry = entry
    local lines = {entry}

    for index = 2, controlCount do
        local entry = CreateDiplomacyEntry(group, controls[index], isAlly)
        LayoutHelpers.Below(entry, belowEntry, 4)
        lines[index] = entry

        local separator = CreateBitmapStd(entry, lineFilename)
        separator.Left:Set(function() return group.Left() + 6 end)
        separator.Top:Set(function() return entry.Top() - 4 end)
        entry.Separator = separator

        belowEntry = entry
    end

    group.Height:Set(function()
        return lines[controlCount].Bottom() - title.Top() + 20
    end)
    group.title = title
    group.lines = lines

    return group
end


function BuildPlayerLines()
    local sessionOptions = SessionGetScenarioInfo().Options
    local focusArmy = GetFocusArmy()
    if focusArmy == -1 then
        focusArmy = import("/lua/ui/game/gamemain.lua").OriginalFocusArmy
        if focusArmy == -1 then
            return
        end
    end

    local group = parent.personalGroup
    if group then
        group:Destroy()
    end
    group = parent.alliedGroup
    if group then
        group:Destroy()
    end
    group = parent.enemyGroup
    if group then
        group:Destroy()
    end

    local allyControls = {}
    local allyCount = 0
    local enemyControls = {}
    local enemyCount = 0
    local allHumanGame = true

    for index, playerInfo in GetArmiesTable().armiesTable do
        if playerInfo.civilian or index == focusArmy then continue end
        playerInfo.armyIndex = index
        if IsAlly(focusArmy, index) then
            allyCount = allyCount + 1
            allyControls[allyCount] = playerInfo
        else
            enemyCount = enemyCount + 1
            enemyControls[enemyCount] = playerInfo
        end
        if allHumanGame and not (playerInfo.human or playerInfo.outOfGame) then
            allHumanGame = false
        end
    end

    local belowEntry = parent

    local reason = GetCannotRequestRecallReason()
    if not import("/lua/ui/campaign/campaignmanager.lua").campaignMode and reason ~= "observer" then
        local personalGroup = CreateBitmapStd(parent, "/game/options-diplomacy-panel/panel-recall")
        if belowEntry == parent then
            LayoutHelpers.AtLeftTopIn(personalGroup, belowEntry, 0, 8)
        else
            LayoutHelpers.Below(personalGroup, belowEntry, 8)
        end
        parent.personalGroup = personalGroup

        local recallButton = UIUtil.CreateButtonStd(personalGroup, "/widgets02/small")
        Layouter(recallButton)
            :AtCenterIn(personalGroup)
            :Over(personalGroup, 5)
        personalGroup.button = recallButton

        if reason then
            recallButton:Disable()
            recallButton:EnableHitTest() -- let the tooltip show
            Tooltip.AddButtonTooltip(recallButton, "dip_recall_request_dis_" .. reason)
        else
            local function OnAcceptRecall()
                SimCallback({
                    Func = "SetRecallVote",
                    Args = {
                        From = GetFocusArmy(),
                        Vote = true,
                    },
                })
                -- preemptively expect the sim to accept our recall and disable the button so we
                -- can't possiblely confuse the sim with more than one request
                -- note that if--for some reason (*ahem* due to a mod maybe)--the sim *doesn't*
                -- end up accepting it, then we'll be stuck until the sim sends a new update
                recallButton:Disable()
                SetCannotRequestRecallReason("active")
                Tooltip.AddButtonTooltip(recallButton, "dip_recall_request_dis_active")
                import("/lua/ui/game/tabs.lua").CollapseWindow()
            end
            recallButton.OnClick = function(self, modifiers)
                -- the sim will only start a vote if there are teammates
                local txt = "<LOC diplomacy_0027>Are you sure you want to recall from battle?"
                local focusArmy = GetFocusArmy()
                for index, playerInfo in GetArmiesTable().armiesTable do
                    if index ~= focusArmy and not playerInfo.outOfGame and not playerInfo.civilian and IsAlly(focusArmy, index) then
                        txt = "<LOC diplomacy_0019>Are you sure you're ready to recall from battle? This will send a request to your team."
                        break
                    end
                end
                UIUtil.QuickDialog(GetFrame(0),
                    txt,
                    "<LOC _Yes>",
                    OnAcceptRecall,
                    "<LOC _No>", nil, nil, nil, nil,
                    {worldCover = false, enterButton = 1, escapeButton = 2}
                )
            end
            Tooltip.AddButtonTooltip(recallButton, "dip_recall_request")
        end

        local recallIcon = CreateBitmapStd(recallButton, "/game/recall-panel/icon-recall")
        Layouter(recallIcon)
            :DisableHitTest()
            :AtCenterIn(recallButton, 1)
            :Width(20)
            :Height(25)
            :Over(recallButton, 5)
        recallButton.label = recallIcon

        belowEntry = personalGroup
    end

    if allyCount > 0 then
        local allyGroup = CreatePlayerGroup(parent,
            "/game/options-diplomacy-panel/panel-allies",
            "<LOC diplomacy_0002>Allies", "ff00ff72",
            allyControls, allyCount, true
        )
        if belowEntry == parent then
            LayoutHelpers.AtLeftTopIn(allyGroup, belowEntry, 0, 8)
        else
            LayoutHelpers.Below(allyGroup, belowEntry, 8)
        end
        parent.alliedGroup = allyGroup

        local allyTitle = allyGroup.title

        local srCheck = UIUtil.CreateCheckboxStd(allyTitle, '/game/toggle_btn/toggle')
        srCheck:SetCheck(shareResources, true)
        LayoutHelpers.AtRightIn(srCheck, allyTitle)
        srCheck.Top:Set(function() return allyGroup.Top() + 4 end)
        Tooltip.AddCheckboxTooltip(srCheck, 'dip_share_resources')
        allyTitle.srCheck = srCheck

        local icon = CreateBitmapStd(srCheck, "/game/toggle_btn/icon-shared-resources")
        icon:DisableHitTest()
        LayoutHelpers.AtCenterIn(icon, srCheck)
        srCheck.label = icon

        if sessionOptions.TeamLock == "unlocked" then
            local avCheck = UIUtil.CreateCheckboxStd(allyTitle, "/game/toggle_btn/toggle")
            avCheck:SetCheck(alliedVictory, true)
            LayoutHelpers.LeftOf(avCheck, srCheck)
            Tooltip.AddCheckboxTooltip(avCheck, "dip_allied_victory")
            allyTitle.avCheck = avCheck

            icon = CreateBitmapStd(avCheck, "/game/toggle_btn/icon-allied-victory")
            icon:DisableHitTest()
            LayoutHelpers.AtCenterIn(icon, avCheck)
            avCheck.label = icon

            avCheck.OnCheck = function(self, checked)
                alliedVictory = checked
                SimCallback({
                    Func = "RequestAlliedVictory",
                    Args = {
                        Army = GetFocusArmy(),
                        Value = checked,
                    },
                })
            end
        end

        belowEntry = allyGroup._bottom

        srCheck.OnCheck = function(self, checked)
            shareResources = checked
            SimCallback({
                Func = "SetResourceSharing",
                Args = {
                    Army = GetFocusArmy(),
                    Value = checked,
                },
            })
        end
    end

    if enemyCount > 0 then
        local enemyGroup = CreatePlayerGroup(parent,
            "/game/options-diplomacy-panel/panel-enemy",
            "<LOC diplomacy_0003>Enemies", "ffff3c00",
            enemyControls, enemyCount, false
        )
        if belowEntry == parent then
            LayoutHelpers.AtLeftTopIn(enemyGroup, belowEntry, 0, 8)
        else
            LayoutHelpers.Below(enemyGroup, belowEntry, 8)
        end
        parent.enemyGroup = enemyGroup

        local enemyTitle = enemyGroup.title

        if allHumanGame then
            local odCheck = UIUtil.CreateCheckboxStd(enemyTitle, "/dialogs/toggle_btn/toggle")
            odCheck:SetCheck(drawOffered, true)
            odCheck.Top:Set(function() return enemyGroup.Top() + 4 end)
            LayoutHelpers.AtRightIn(odCheck, enemyTitle)
            Tooltip.AddCheckboxTooltip(odCheck, 'dip_offer_draw')
            enemyTitle.odCheck = odCheck

            odCheck.label = UIUtil.CreateText(odCheck, "<LOC _Draw>Draw", 12, UIUtil.bodyFont)
            LayoutHelpers.AtCenterIn(odCheck.label, odCheck)

            odCheck.OnCheck = function(self, checked)
                drawOffered = checked
                SimCallback({
                    Func = "SetOfferDraw",
                    Args = {
                        Army = GetFocusArmy(),
                        Value = checked,
                    },
                })
                local msg = '<LOC diplomacy_0000>has offered a draw.'
                if not checked then
                    msg = '<LOC diplomacy_0001>has rescinded their draw offer.'
                end
                SessionSendChatMessage({to = 'all', ConsoleOutput = msg})
            end
        end

        belowEntry = enemyGroup._bottom
    end

    LayoutHelpers.AtBottomIn(parent, belowEntry, 14)
end

function CreateShareResourcesDialog(control)
    local giveResGroup = control.giveResourcesGroup
    if giveResGroup then
        giveResGroup:Destroy()
        control.giveResourcesGroup = false
        control.Height:Set(control.OrigHeight)
        control.OrigHeight = nil
    else
        control.OrigHeight = control.Height()

        giveResGroup = Group(control)
        giveResGroup.Width:Set(control.Width)
        LayoutHelpers.SetHeight(giveResGroup, 90)
        LayoutHelpers.AtLeftBottomIn(giveResGroup, control)
        control.giveResourcesGroup = giveResGroup

        local okBtn = UIUtil.CreateButtonStd(giveResGroup,
            '/dialogs/toggle_btn/toggle-d',
            '<LOC _Ok>', 12
        )
        LayoutHelpers.AtBottomIn(okBtn, giveResGroup)
        okBtn.Left:Set(function()
            local giveResGroup = control.giveResourcesGroup
            return giveResGroup.Left() + giveResGroup.Width() * 0.25 - okBtn.Width() * 0.5
        end)

        local cancelBtn = UIUtil.CreateButtonStd(giveResGroup,
            '/dialogs/toggle_btn/toggle-d',
            '<LOC _Cancel>', 12
        )
        LayoutHelpers.AtBottomIn(cancelBtn, giveResGroup)
        cancelBtn.Left:Set(function()
            local giveResGroup = control.giveResourcesGroup
            return giveResGroup.Left() + giveResGroup.Width() * 0.75 - okBtn.Width() * 0.5
        end)

        local massStatus = StatusBar(giveResGroup, 0, 100, false, false,
            UIUtil.UIFile('/game/resource-bars/mini-mass-bar-back_bmp.dds'),
            UIUtil.UIFile('/game/resource-bars/mini-mass-bar_bmp.dds'), false
        )
        massStatus.Left:Set(giveResGroup.Left)
        LayoutHelpers.AtRightTopIn(massStatus, giveResGroup, 50, 10)

        local massSlider = Slider(giveResGroup, false, 0, 100,
            UIUtil.UIFile('/game/slider-btn/slider-mass_btn_up.dds'),
            UIUtil.UIFile('/game/slider-btn/slider-mass_btn_up.dds'),
            UIUtil.UIFile('/game/slider-btn/slider-mass_btn_up.dds')
        )
        LayoutHelpers.AtVerticalCenterIn(massSlider, massStatus)
        massSlider.Left:Set(giveResGroup.Left)
        massSlider:SetValue(0)
        LayoutHelpers.AtRightIn(massSlider, giveResGroup, 50)

        massInput = UIUtil.CreateText(giveResGroup, '0%', 16, UIUtil.bodyFont)
        massInput:SetColor('ff00ff00')
        LayoutHelpers.RightOf(massInput, massStatus, 5)

        massSlider.OnValueChanged = function(self, newValue)
            massInput:SetText(string.format("%d%%", math.max(math.min(math.floor(newValue), 100), 0)))
            massStatus:SetValue(math.floor(newValue))
        end
        massStatus.Depth:Set(function() return massSlider.Depth() - 1 end)


        local energyStatus = StatusBar(giveResGroup, 0, 100, false, false,
            UIUtil.UIFile('/game/resource-bars/mini-energy-bar-back_bmp.dds'),
            UIUtil.UIFile('/game/resource-bars/mini-energy-bar_bmp.dds'), false
        )
        energyStatus.Left:Set(giveResGroup.Left)
        LayoutHelpers.Below(energyStatus, massStatus, 20)
        LayoutHelpers.AtRightIn(energyStatus, giveResGroup, 50)

        local energySlider = Slider(giveResGroup, false, 0, 100,
            UIUtil.UIFile('/game/slider-btn/slider-energy_btn_up.dds'),
            UIUtil.UIFile('/game/slider-btn/slider-energy_btn_up.dds'),
            UIUtil.UIFile('/game/slider-btn/slider-energy_btn_up.dds')
        )
        LayoutHelpers.AtVerticalCenterIn(energySlider, energyStatus)
        energySlider.Left:Set(giveResGroup.Left)
        energySlider:SetValue(0)
        LayoutHelpers.AtRightIn(energySlider, giveResGroup, 50)

        energyInput = UIUtil.CreateText(giveResGroup, '0%', 16, UIUtil.bodyFont)
        energyInput:SetColor('ffffc700')
        LayoutHelpers.RightOf(energyInput, energyStatus, 5)

        energySlider.OnValueChanged = function(self, newValue)
            energyInput:SetText(string.format("%d%%", math.max(math.min(math.floor(newValue), 100), 0)))
            energyStatus:SetValue(math.floor(newValue))
        end
        energyStatus.Depth:Set(function() return massSlider.Depth() - 1 end)

        control.Height:Set(function()
            return control.OrigHeight + control.giveResourcesGroup.Height()
        end)

        okBtn.OnClick = function(self, modifiers)
            SimCallback({
                Func = "GiveResourcesToPlayer",
                Args = {
                    From = GetFocusArmy(),
                    To = control.Data.armyIndex,
                    Mass = massSlider:GetValue() * 0.01,
                    Energy = energySlider:GetValue() * 0.01,
                },
            })
            CreateShareResourcesDialog(control)
        end
        cancelBtn.OnClick = function(self, modifiers)
            CreateShareResourcesDialog(control)
        end
    end
end

function SetAlliedVictory(state)
    alliedVictory = state
end



--- Unused

local EffectHelpers = import("/lua/maui/effecthelpers.lua")
local Text = import("/lua/maui/text.lua").Text
local Edit = import("/lua/maui/edit.lua").Edit
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local Button = import("/lua/maui/button.lua").Button
local GameCommon = import("/lua/ui/game/gamecommon.lua")
local NeverAllyWith = {}

if SessionGetScenarioInfo().Options.TeamLock == 'locked' then
    lockTeams = true
end