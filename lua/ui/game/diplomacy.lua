--*****************************************************************************
--* File: lua/modules/ui/game/diplomacy.lua
--* Summary: UI for the diplomacy control
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local EffectHelpers = import('/lua/maui/effecthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Text = import('/lua/maui/text.lua').Text
local Edit = import('/lua/maui/edit.lua').Edit
local Checkbox = import('/lua/maui/Checkbox.lua').Checkbox
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local StatusBar = import('/lua/maui/statusbar.lua').StatusBar
local Slider = import('/lua/maui/Slider.lua').Slider
local GameCommon = import('/lua/ui/game/gamecommon.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local Tabs = import('/lua/ui/game/tabs.lua')

local parent = false
parent.Items = {}

local shareResources = true
local alliedVictory = true

local dialogue = false
local offerQueue = {}
local drawOffered = false
local NeverAllyWith = {}

if SessionGetScenarioInfo().Options.TeamLock and SessionGetScenarioInfo().Options.TeamLock == 'locked' then
    lockTeams = true
end

function ActionHandler(actions)
    local armies = GetArmiesTable().armiesTable
    for _, action in actions do
        if action.Action == 'offer' then
            if not dialogue then
                dialogue = CreateOfferDialogue(action)
            else
                table.insert(offerQueue, action)
            end
        elseif action.Action == 'accept' then
            Announce(LOCF('<LOC diplomacy_0005>%s accepts your alliance.', armies[action.From].nickname))
        elseif action.Action == 'reject' then
            Announce(LOCF('<LOC diplomacy_0006>%s rejects your alliance.', armies[action.From].nickname))
        elseif action.Action == 'never' then
            Announce(LOCF('<LOC diplomacy_0007>%s is now ignoring your requests.', armies[action.From].nickname))
        elseif action.Action == 'break' then
            Announce(LOCF('<LOC diplomacy_0008>Your alliance with %s has been broken.', armies[action.From].nickname))
        end
    end
end

function AnnouncementHandler(announcements)
    for _, announcement in announcements do
        local text = false
        local armies = GetArmiesTable().armiesTable
        if announcement.Action == 'accept' then
            text = LOCF('<LOC diplomacy_0009>%s and %s are now allies.', armies[action.From], armies[action.To])
        elseif announcement.Action == 'break' then
            text = LOCF('<LOC diplomacy_0010>%s and %s are no longer allies.', armies[action.From], armies[action.To])
        end
        if text then
            Announce(text)
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
    local armies = GetArmiesTable().armiesTable
    return UIUtil.QuickDialog(GetFrame(0), LOCF("<LOC diplomacy_0004>%s has offered you an alliance.", armies[action.From].nickname),
        "<LOC _Accept>", function() SendAnswer(action.From, 'accept') end,
        "<LOC _Reject>", function() SendAnswer(action.From, 'reject') end,
        "<LOC _Never>", function() SendAnswer(action.From, 'never') end,
        true, {escapeButton = 2, enterButton = 1, worldCover = false, OnlyWorldCover = true})
end

function SendAnswer(army, answer)
    SimCallback({Func = 'DiplomacyHandler', Args = {Action = answer, From = GetFocusArmy(), To = army}})
    local i = 1
    while offerQueue[i] do
        if offerQueue[i].From == army then
            table.remove(offerQueue, i)
        end
        i = i + 1
    end
    if offerQueue[1] then
        CreateOfferDialogue(offerQueue[1])
        table.remove(offerQueue, 1)
    else
        dialogue = false
    end
end

function CreateContent(inParent)
    parent = Group(inParent)

    BuildPlayerLines()

    parent.Width:Set(266)
    parent.OnDestroy = function(self)
        parent = false
    end

    return parent
end

function BuildPlayerLines()
    local sessionOptions = SessionGetScenarioInfo().Options

    if table.getsize(parent.Items) > 0 then
        for i, _ in parent.Items do
            local index = i
            parent.Items[index]:Destroy()
            parent.Items[index] = nil
        end
        if parent.alliedBG then
            parent.alliedBG:Destroy()
        end
        if parent.enemyBG then
            parent.enemyBG:Destroy()
        end
    end
    local function CreateEntry(data, isAlly)
        local entry = Bitmap(parent)
        entry.Depth:Set(function() return parent.Depth() + 10 end)
        entry:SetSolidColor('00000000')

        entry.typeIcon = Bitmap(entry)
        LayoutHelpers.AtLeftIn(entry.typeIcon, entry)
        if data.human then
            entry.typeIcon:SetTexture(UIUtil.UIFile('/game/options-diplomacy-panel/icon-person_bmp.dds'))
        else
            entry.typeIcon:SetTexture(UIUtil.UIFile('/game/options-diplomacy-panel/icon-ai_bmp.dds'))
        end

        entry.factionIcon = Bitmap(entry)
        LayoutHelpers.RightOf(entry.factionIcon, entry.typeIcon)
        LayoutHelpers.AtTopIn(entry.factionIcon, entry, 1)
        LayoutHelpers.AtVerticalCenterIn(entry.typeIcon, entry.factionIcon)

        entry.color = Bitmap(entry.factionIcon)
        LayoutHelpers.FillParent(entry.color, entry.factionIcon)
        entry.color.Depth:Set(function() return entry.factionIcon.Depth() - 1 end)

        if data.outOfGame then
            entry.factionIcon:SetTexture(UIUtil.UIFile('/game/unit-over/icon-skull_bmp.dds'))
            entry.color:SetSolidColor('ff000000')
        else
            entry.factionIcon:SetTexture(UIUtil.UIFile(UIUtil.GetFactionIcon(data.faction)))
            entry.color:SetSolidColor(data.color)
        end
        entry.name = UIUtil.CreateText(entry, data.nickname, 16, UIUtil.bodyFont)
        entry.name.Right:Set(entry.Right)
        LayoutHelpers.RightOf(entry.name, entry.factionIcon, 5)
        LayoutHelpers.AtTopIn(entry.name, entry.factionIcon)
        entry.name:SetClipToWidth(true)

        entry.Data = data
        --LOG('Making entry for: ', repr(data))
        if isAlly then
            if data.human and not data.outOfGame then
                entry.giveUnitBtn = UIUtil.CreateButton(entry,
                    '/dialogs/toggle_btn/toggle-d_btn_up.dds',
                    '/dialogs/toggle_btn/toggle-d_btn_down.dds',
                    '/dialogs/toggle_btn/toggle-d_btn_over.dds',
                    '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
                    '<LOC diplomacy_0011>Units', 12)
                entry.giveUnitBtn.label:SetFont(UIUtil.bodyFont, 12)
                LayoutHelpers.Below(entry.giveUnitBtn, entry.factionIcon, -2)
                LayoutHelpers.AtLeftIn(entry.giveUnitBtn, entry)
                entry.giveUnitBtn.OnClick = function(self, modifiers)
                    UIUtil.QuickDialog(GetFrame(0), LOCF("<LOC unitxfer_0000>Give Selected Units to %s?", entry.Data.nickname),
                        '<LOC _Yes>', function()
                            local to = entry.Data.armyIndex
                            if IsKeyDown('Shift') then
                                IssueCommand("UNITCOMMAND_Script", {TaskName='GiveTask', To=to}, false)
                            else
                                SimCallback({Func="GiveUnitsToPlayer", Args={ From=GetFocusArmy(), To=to},} , true)
                            end
                        end,
                        '<LOC _No>', nil, nil, nil, nil, {worldCover = false, enterButton = 1, escapeButton = 2})
                end
                Tooltip.AddButtonTooltip(entry.giveUnitBtn, 'dip_give_units')

                entry.giveResourcesBtn = UIUtil.CreateButton(entry,
                    '/dialogs/toggle_btn/toggle-d_btn_up.dds',
                    '/dialogs/toggle_btn/toggle-d_btn_down.dds',
                    '/dialogs/toggle_btn/toggle-d_btn_over.dds',
                    '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
                    '<LOC diplomacy_0012>Resources', 12)
                entry.giveResourcesBtn.label:SetFont(UIUtil.bodyFont, 12)
                LayoutHelpers.RightOf(entry.giveResourcesBtn, entry.giveUnitBtn)
                entry.giveResourcesBtn.OnClick = function(self, modifiers)
                    CreateShareResourcesDialog(entry)
                end
                Tooltip.AddButtonTooltip(entry.giveResourcesBtn, 'dip_give_resources')
            end

            if sessionOptions and sessionOptions.TeamLock == "locked" then
            else
                if not data.outOfGame then
                    entry.breakBtn = UIUtil.CreateButton(entry,
                        '/dialogs/toggle_btn/toggle-d_btn_up.dds',
                        '/dialogs/toggle_btn/toggle-d_btn_down.dds',
                        '/dialogs/toggle_btn/toggle-d_btn_over.dds',
                        '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
                        '<LOC diplomacy_0013>Break', 12)
                    entry.breakBtn.label:SetFont(UIUtil.bodyFont, 12)
                    LayoutHelpers.Below(entry.breakBtn, entry.factionIcon, -2)
                    LayoutHelpers.AtRightIn(entry.breakBtn, entry)
                    LayoutHelpers.ResetLeft(entry.breakBtn)
                    entry.breakBtn.OnClick = function(self, checked)
                        SimCallback({Func = 'DiplomacyHandler', Args = {Action = 'break', From = GetFocusArmy(), To = data.armyIndex}})
                        ForkThread(function()
                            WaitSeconds(1)
                            BuildPlayerLines()
                        end)
                    end
                    Tooltip.AddButtonTooltip(entry.breakBtn, 'dip_break_alliance')
                end
            end
        elseif data.human then
            if sessionOptions and sessionOptions.TeamLock == "locked" then
            else
                if not data.outOfGame then
                    entry.offerBtn = UIUtil.CreateButton(entry,
                        '/dialogs/toggle_btn/toggle-d_btn_up.dds',
                        '/dialogs/toggle_btn/toggle-d_btn_down.dds',
                        '/dialogs/toggle_btn/toggle-d_btn_over.dds',
                        '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
                        '<LOC diplomacy_0014>Offer', 12)
                    entry.offerBtn.label:SetFont(UIUtil.bodyFont, 12)
                    LayoutHelpers.AtRightIn(entry.offerBtn, entry)
                    LayoutHelpers.AtBottomIn(entry.offerBtn, entry)
                    entry.offerBtn.OnClick = function(self, checked)
                        self:Disable()
                        SimCallback({Func = 'DiplomacyHandler', Args = {Action = 'offer', From = GetFocusArmy(), To = data.armyIndex}})
                    end
                    Tooltip.AddButtonTooltip(entry.offerBtn, 'dip_offer_alliance')
                end
            end
        end

        entry.Height:Set(function()
                if (isAlly or data.human) and not data.outOfGame then
                    return 40
                else
                    return entry.factionIcon.Height() + 4
                end
            end)
        entry.Width:Set(function() return parent.Width() - 20 end)

        return entry
    end

    parent.Items = {}

    local allyControls = {}
    local enemyControls = {}

    local i = 1
    for index, playerInfo in GetArmiesTable().armiesTable do
        if playerInfo.civilian or index == GetFocusArmy() then continue end
        playerInfo.armyIndex = index
        if IsAlly(GetFocusArmy(), index) then
            table.insert(allyControls, playerInfo)
        else
            table.insert(enemyControls, playerInfo)
        end
        i = i + 1
    end

    i = 1
    if table.getn(allyControls) > 0 then
        parent.Items[i] = UIUtil.CreateText(parent, LOC('<LOC diplomacy_0002>Allies'), 18, UIUtil.bodyFont)
        parent.Items[i]:SetColor('ff00ff72')
        parent.Items[i]:SetDropShadow(true)
        parent.Items[i].Depth:Set(function() return parent.Depth() + 10 end)
        LayoutHelpers.AtLeftTopIn(parent.Items[i], parent, 8, 10)

        parent.Items[i].srCheck = UIUtil.CreateCheckboxStd(parent.Items[i], '/game/toggle_btn/toggle')
        parent.Items[i].srCheck.label = Bitmap(parent.Items[i].srCheck, UIUtil.UIFile('/game/toggle_btn/icon-shared-resources_bmp.dds'))
        parent.Items[i].srCheck.label:DisableHitTest()
        LayoutHelpers.AtCenterIn(parent.Items[i].srCheck.label, parent.Items[i].srCheck)
        parent.Items[i].srCheck:SetCheck(shareResources, true)
        parent.Items[i].srCheck.OnCheck = function(self, checked)
            shareResources = checked
            SimCallback({  Func = "SetResourceSharing",
                            Args = { Army = GetFocusArmy(),
                                     Value = checked,
                                   }
                         }
                       )
        end
        Tooltip.AddCheckboxTooltip(parent.Items[i].srCheck, 'dip_share_resources')

        parent.Items[i].avCheck = UIUtil.CreateCheckboxStd(parent.Items[i], '/game/toggle_btn/toggle')
        parent.Items[i].avCheck.label = Bitmap(parent.Items[i].avCheck, UIUtil.UIFile('/game/toggle_btn/icon-allied-victory_bmp.dds'))
        parent.Items[i].avCheck.label:DisableHitTest()
        LayoutHelpers.AtCenterIn(parent.Items[i].avCheck.label, parent.Items[i].avCheck)
        parent.Items[i].avCheck:SetCheck(alliedVictory, true)
        parent.Items[i].avCheck.OnCheck = function(self, checked)
            alliedVictory = checked
            SimCallback({  Func = "RequestAlliedVictory",
                            Args = { Army = GetFocusArmy(),
                                     Value = checked,
                                   }
                         }
                       )
        end
        Tooltip.AddCheckboxTooltip(parent.Items[i].avCheck, 'dip_allied_victory')

        LayoutHelpers.AtRightTopIn(parent.Items[i].srCheck, parent, 2, 6)
        LayoutHelpers.LeftOf(parent.Items[i].avCheck, parent.Items[i].srCheck)

        i = i + 1
        local lastAllyControl = false
        for index, info in allyControls do
            parent.Items[i] = CreateEntry(info, true)
            LayoutHelpers.Below(parent.Items[i], parent.Items[i-1], 12)
            if table.getsize(allyControls) != index then
                parent.Items[i].Seperator = Bitmap(parent.Items[i], UIUtil.UIFile('/game/options-diplomacy-panel/line-allies_bmp.dds'))
                local curI = i
                parent.Items[i].Seperator.Top:Set(function() return parent.Items[curI].Bottom() + 12 end)
                LayoutHelpers.AtHorizontalCenterIn(parent.Items[i].Seperator, parent.Items[i], 2)
            end
            lastAllyControl = parent.Items[i]
            i = i + 1
        end

        parent.alliedBG = Bitmap(parent, UIUtil.UIFile('/game/options-diplomacy-panel/panel-allies_bmp_t.dds'))
        parent.alliedBG.Top:Set(function() return parent.Top() + 2 end)
        parent.alliedBG.Left:Set(parent.Left)

        parent.alliedBG.bottomBG = Bitmap(parent.alliedBG, UIUtil.UIFile('/game/options-diplomacy-panel/panel-allies_bmp_b.dds'))
        parent.alliedBG.bottomBG.Depth:Set(parent.alliedBG.Depth)
        parent.alliedBG.bottomBG.Left:Set(parent.alliedBG.Left)
        parent.alliedBG.bottomBG.Top:Set(function() return lastAllyControl.Bottom() + 5 end)

        parent.alliedBG.middleBG = Bitmap(parent.alliedBG, UIUtil.UIFile('/game/options-diplomacy-panel/panel-allies_bmp_m.dds'))
        parent.alliedBG.middleBG.Depth:Set(parent.alliedBG.Depth)
        parent.alliedBG.middleBG.Top:Set(parent.alliedBG.Bottom)
        parent.alliedBG.middleBG.Left:Set(parent.alliedBG.Left)
        parent.alliedBG.middleBG.Bottom:Set(parent.alliedBG.bottomBG.Top)
    end

    parent.Items[i] = UIUtil.CreateText(parent, LOC('<LOC diplomacy_0003>Enemies'), 18, UIUtil.bodyFont)
    parent.Items[i].Depth:Set(function() return parent.Depth() + 10 end)
    parent.Items[i]:SetDropShadow(true)
    parent.Items[i]:SetColor('ffff3c00')

    local enemyTitle = parent.Items[i]
    local lastEnemyControl = false

    if SessionGetScenarioInfo().Options.Ranked then
        parent.Items[i].odCheck = UIUtil.CreateCheckboxStd(parent.Items[i], '/dialogs/toggle_btn/toggle')
        parent.Items[i].odCheck.label = UIUtil.CreateText(parent.Items[i].odCheck, LOC('<LOC _Draw>Draw'), 12, UIUtil.bodyFont)
        LayoutHelpers.AtCenterIn(parent.Items[i].odCheck.label, parent.Items[i].odCheck)
        Tooltip.AddCheckboxTooltip(parent.Items[i].odCheck, 'dip_offer_draw')
        parent.Items[i].odCheck:SetCheck(drawOffered, true)
        parent.Items[i].odCheck.OnCheck = function(self, checked)
            drawOffered = checked
            SimCallback({  Func = "SetOfferDraw",
                            Args = { Army = GetFocusArmy(),
                                     Value = checked,
                                   }
                         }
                       )
            local msg = '<LOC diplomacy_0000>has offered a draw.'
            if not checked then
                msg = '<LOC diplomacy_0001>has rescinded their draw offer.'
            end
            SessionSendChatMessage({to = 'all', ConsoleOutput = msg})
        end
    end

    if i == 1 then
        LayoutHelpers.AtLeftTopIn(parent.Items[i], parent, 6, 10)
        if parent.Items[i].odCheck then
            LayoutHelpers.AtRightTopIn(parent.Items[i].odCheck, parent, 6, 8)
        end
    else
        LayoutHelpers.Below(parent.Items[i], parent.Items[i-1], 40)
        if parent.Items[i].odCheck then
            LayoutHelpers.AtTopIn(parent.Items[i].odCheck, parent.Items[i])
            LayoutHelpers.AtRightIn(parent.Items[i].odCheck, parent)
        end
    end
    i = i + 1
    for index, info in enemyControls do
        parent.Items[i] = CreateEntry(info)
        LayoutHelpers.Below(parent.Items[i], parent.Items[i-1], 2)
        lastEnemyControl = parent.Items[i]
        if table.getsize(enemyControls) != index then
            parent.Items[i].Seperator = Bitmap(parent.Items[i], UIUtil.UIFile('/game/options-diplomacy-panel/line-enemies_bmp.dds'))
            parent.Items[i].Seperator.Top:Set(parent.Items[i].Bottom)
            LayoutHelpers.AtHorizontalCenterIn(parent.Items[i].Seperator, parent.Items[i], 2)
        end
        i = i + 1
    end

    parent.enemyBG = Bitmap(parent, UIUtil.UIFile('/game/options-diplomacy-panel/panel-enemy_bmp_t.dds'))
    parent.enemyBG.Top:Set(function() return enemyTitle.Top() - 8 end)
    parent.enemyBG.Left:Set(parent.Left)
    parent.enemyBG.bottomBG = Bitmap(parent.enemyBG, UIUtil.UIFile('/game/options-diplomacy-panel/panel-enemy_bmp_b.dds'))
    parent.enemyBG.bottomBG.Depth:Set(parent.enemyBG.Depth)
    parent.enemyBG.bottomBG.Left:Set(parent.enemyBG.Left)
    parent.enemyBG.middleBG = Bitmap(parent.enemyBG, UIUtil.UIFile('/game/options-diplomacy-panel/panel-enemy_bmp_m.dds'))
    parent.enemyBG.middleBG.Depth:Set(parent.enemyBG.Depth)
    parent.enemyBG.middleBG.Top:Set(parent.enemyBG.Bottom)
    parent.enemyBG.middleBG.Left:Set(parent.enemyBG.Left)
    parent.enemyBG.middleBG.Bottom:Set(parent.enemyBG.bottomBG.Top)
    if lastEnemyControl then
        parent.enemyBG.bottomBG.Top:Set(function() return lastEnemyControl.Bottom() end)
    else
        parent.enemyBG.bottomBG.Top:Set(function() return enemyTitle.Bottom() end)
    end

    parent.Height:Set(function()
            local height = 0
            for i, item in parent.Items do
                local index = i
                if i == 1 then
                    height = item.Height()
                else
                    height = height + (item.Bottom() - parent.Items[index-1].Bottom())
                end
            end
            return height + 10
        end)
end

function CreateShareResourcesDialog(control)
    if control.giveResourcesGroup then
        control.giveResourcesGroup:Destroy()
        control.giveResourcesGroup = false
        control.Height:Set(control.OrigHeight)
        control.OrigHeight = nil
    else
        control.OrigHeight = control.Height()

        control.giveResourcesGroup = Group(control)
        control.giveResourcesGroup.Height:Set(90)
        control.giveResourcesGroup.Width:Set(control.Width)
        LayoutHelpers.AtBottomIn(control.giveResourcesGroup, control)
        LayoutHelpers.AtLeftIn(control.giveResourcesGroup, control)

        local okBtn = UIUtil.CreateButton(control.giveResourcesGroup,
            '/dialogs/toggle_btn/toggle-d_btn_up.dds',
            '/dialogs/toggle_btn/toggle-d_btn_down.dds',
            '/dialogs/toggle_btn/toggle-d_btn_over.dds',
            '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
            '<LOC _Ok>', 12)

        local cancelBtn = UIUtil.CreateButton(control.giveResourcesGroup,
            '/dialogs/toggle_btn/toggle-d_btn_up.dds',
            '/dialogs/toggle_btn/toggle-d_btn_down.dds',
            '/dialogs/toggle_btn/toggle-d_btn_over.dds',
            '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
            '<LOC _Cancel>', 12)
        cancelBtn.OnClick = function(self, modifiers)
            CreateShareResourcesDialog(control)
        end


        local massStatus = StatusBar(control.giveResourcesGroup, 0, 100, false, false,
            UIUtil.UIFile('/game/resource-bars/mini-mass-bar-back_bmp.dds'),
            UIUtil.UIFile('/game/resource-bars/mini-mass-bar_bmp.dds'), false)
        massStatus.Top:Set(function() return control.giveResourcesGroup.Top() + 10 end)
        massStatus.Left:Set(control.giveResourcesGroup.Left)
        massStatus.Right:Set(function() return control.giveResourcesGroup.Right() - 50 end)

        local massSlider = Slider(control.giveResourcesGroup, false, 0, 100,
            UIUtil.UIFile('/game/slider-btn/slider-mass_btn_up.dds'),
            UIUtil.UIFile('/game/slider-btn/slider-mass_btn_up.dds'),
            UIUtil.UIFile('/game/slider-btn/slider-mass_btn_up.dds'))
        LayoutHelpers.AtVerticalCenterIn(massSlider, massStatus)
        massSlider.Left:Set(control.giveResourcesGroup.Left)
        massSlider.Right:Set(function() return control.giveResourcesGroup.Right() - 50 end)
        massSlider:SetValue(0)

        massInput = UIUtil.CreateText(control.giveResourcesGroup, '0%', 16, UIUtil.bodyFont)
        massInput:SetColor('ff00ff00')
        LayoutHelpers.RightOf(massInput, massStatus, 5)

        massSlider.OnValueChanged = function(self, newValue)
            massInput:SetText(string.format("%d%%", math.max(math.min(math.floor(newValue), 100), 0)))
            massStatus:SetValue(math.floor(newValue))
        end
        massStatus.Depth:Set(function() return massSlider.Depth() - 1 end)


        local energyStatus = StatusBar(control.giveResourcesGroup, 0, 100, false, false,
            UIUtil.UIFile('/game/resource-bars/mini-energy-bar-back_bmp.dds'),
            UIUtil.UIFile('/game/resource-bars/mini-energy-bar_bmp.dds'), false)
        LayoutHelpers.Below(energyStatus, massStatus, 20)
        energyStatus.Left:Set(control.giveResourcesGroup.Left)
        energyStatus.Right:Set(function() return control.giveResourcesGroup.Right() - 50 end)

        local energySlider = Slider(control.giveResourcesGroup, false, 0, 100,
            UIUtil.UIFile('/game/slider-btn/slider-energy_btn_up.dds'),
            UIUtil.UIFile('/game/slider-btn/slider-energy_btn_up.dds'),
            UIUtil.UIFile('/game/slider-btn/slider-energy_btn_up.dds'))
        LayoutHelpers.AtVerticalCenterIn(energySlider, energyStatus)
        energySlider.Left:Set(control.giveResourcesGroup.Left)
        energySlider.Right:Set(function() return control.giveResourcesGroup.Right() - 50 end)
        energySlider:SetValue(0)

        energyInput = UIUtil.CreateText(control.giveResourcesGroup, '0%', 16, UIUtil.bodyFont)
        energyInput:SetColor('ffffc700')
        LayoutHelpers.RightOf(energyInput, energyStatus, 5)

        energySlider.OnValueChanged = function(self, newValue)
            energyInput:SetText(string.format("%d%%", math.max(math.min(math.floor(newValue), 100), 0)))
            energyStatus:SetValue(math.floor(newValue))
        end
        energyStatus.Depth:Set(function() return massSlider.Depth() - 1 end)

        LayoutHelpers.AtBottomIn(okBtn, control.giveResourcesGroup)
        LayoutHelpers.AtBottomIn(cancelBtn, control.giveResourcesGroup)
        okBtn.Left:Set(function() return control.giveResourcesGroup.Left() + (control.giveResourcesGroup.Width() / 4) - (okBtn.Width() / 2) end)
        cancelBtn.Left:Set(function() return control.giveResourcesGroup.Left() + ((control.giveResourcesGroup.Width() / 4) * 3) - (okBtn.Width() / 2) end)

        okBtn.OnClick = function(self, modifiers)
            SimCallback({ Func="GiveResourcesToPlayer",
                           Args={ From=GetFocusArmy(),
                                  To=control.Data.armyIndex,
                                  Mass=massSlider:GetValue() / 100.0,
                                  Energy=energySlider:GetValue() / 100.0,
                                }
                          }
                       )
            CreateShareResourcesDialog(control)
        end

        control.Height:Set(function() return control.OrigHeight + control.giveResourcesGroup.Height() end)
    end
end

function SetAlliedVictory(state)
    alliedVictory = state
end
