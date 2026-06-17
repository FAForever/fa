--*****************************************************************************
--* File: lua/modules/ui/lobby/createui.lua
--* Summary: UI creation functions extracted from lobby.lua for maintainability.
--*          Contains CreateSlotsUI, CreateUI, and CreateUI_Faction_Selector.
--*
--* Globals used (provided by lobby.lua):
--*   GUI, lobbyComm, gameInfo, localPlayerID, singlePlayer, FACTION_NAMES
--*
--* Lobby-internal functions called from here (still defined in lobby.lua):
--*   GetNumAvailStartSpots, GetSanitisedLastFaction, DoSlotBehavior,
--*   FindSlotForID, FindIDForName, FindObserverSlotForID, IsPlayer, IsObserver,
--*   SetSlotInfo, IsColorFree, GetPlayerCount, SendSystemMessage, TryLaunch,
--*   UpdateGame, SetPlayerColor, ClearBadMapFlags, EnableSlot, DisableSlot,
--*   setupChatEdit, RefreshOptionDisplayData, CalcConnectionStatus, AddChatText,
--*   SetPlayerOption, SetGameOptions, SetGameOption, CreateBigPreview,
--*   Ping_AddControlTooltip, ShowTitleDialog, ShowRuleDialog,
--*   GetSlotFactionIndex, RefreshLobbyBackground, ShowLobbyOptionsDialog
--*****************************************************************************

-- Shared module-level imports (mirrors lobby.lua's top-level locals so all
-- three functions below can use them without re-importing each time).
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Button = import("/lua/maui/button.lua").Button
local ToggleButton = import("/lua/ui/controls/togglebutton.lua").ToggleButton
local Group = import("/lua/maui/group.lua").Group
local RadioButton = import("/lua/ui/controls/radiobutton.lua").RadioButton
local ResourceMapPreview = import("/lua/ui/controls/resmappreview.lua").ResourceMapPreview
local Slider = import("/lua/maui/slider.lua").Slider
local TextArea = import("/lua/ui/controls/textarea.lua").TextArea
local Tooltip = import("/lua/ui/game/tooltip.lua")
local LobbyComm = import("/lua/ui/lobby/lobbycomm.lua")
local FactionData = import("/lua/factions.lua")
local Presets = import("/lua/ui/lobby/presets.lua")
local Prefs = import("/lua/user/prefs.lua")
local CPUBenchmark = import("/lua/ui/lobby/lobby_modules/cpubenchmark.lua")

-- Dependency injection from lobby.lua (see _syncCreateUI()/SyncModuleDeps()).
--
-- The functions in this file were extracted from lobby.lua and still reference
-- lobby's mutable state (GUI, lobbyComm, gameInfo, ...) and helper functions
-- (UpdateGame, SetSlotInfo, DoSlotBehavior, ...) as the header's "globals
-- provided by lobby.lua" describe. After the extraction those names no longer
-- live in this module's environment, so lobby.lua pushes them in here.
--
-- They are injected as module-level *globals* (rawset into this file's
-- environment) rather than upvalues on purpose: CreateUI is huge and would
-- otherwise blow past SupCom Lua's per-function upvalue limit. rawset is used
-- so the injection is not blocked by the strict-global guard from
-- system/config.lua.
function Init(deps)
    local env = getfenv(1)
    for k, v in deps do
        rawset(env, k, v)
    end
end

-- UI state that is *owned* by this module (lobby.lua does not read it back), so
-- it is initialised once here rather than pushed in via Init() -- re-injecting on
-- every SyncModuleDeps() would clobber the user's in-session changes. They are
-- declared as module globals to match how the functions below reference them.
playersToSwap = false
autoRandMap = false
HideDefaultOptions = Prefs.GetFromCurrentProfile('LobbyHideDefaultOptions') == 'true'

function CreateSlotsUI(makeLabel)
    local Combo = import("/lua/ui/controls/combo.lua").Combo
    local BitmapCombo = import("/lua/ui/controls/combo.lua").BitmapCombo
    local StatusBar = import("/lua/maui/statusbar.lua").StatusBar
    local ColumnLayout = import("/lua/ui/controls/columnlayout.lua").ColumnLayout

    -- The dimensions of the columns used for slot UI controls.
    local COLUMN_POSITIONS = {1, 21, 47, 91, 133, 395, 465, 535, 605, 677, 749}
    local COLUMN_WIDTHS = {20, 20, 45, 45, 257, 59, 59, 59, 62, 62, 51}

    local labelGroup = ColumnLayout(GUI.playerPanel, COLUMN_POSITIONS, COLUMN_WIDTHS)

    GUI.labelGroup = labelGroup
    LayoutHelpers.SetDimensions(labelGroup, 791, 21)
    LayoutHelpers.AtLeftTopIn(labelGroup, GUI.playerPanel, 5, 5)

    local slotLabel = makeLabel("--", 14)
    labelGroup:AddChild(slotLabel)

    -- No label required for the second column (flag), so skip it. (Even eviler hack)
    labelGroup.numChildren = labelGroup.numChildren + 1

    local ratingLabel = makeLabel("R", 14)
    labelGroup:AddChild(ratingLabel)

    local numGamesLabel = makeLabel("G", 14)
    labelGroup:AddChild(numGamesLabel)

    local nameLabel = makeLabel(LOC("<LOC NICKNAME>Nickname"), 14)
    labelGroup:AddChild(nameLabel)

    local colorLabel = makeLabel(LOC("<LOC lobui_0214>Color"), 14)
    labelGroup:AddChild(colorLabel)

    local factionLabel = makeLabel(LOC("<LOC lobui_0215>Faction"), 14)
    labelGroup:AddChild(factionLabel)

    local teamLabel = makeLabel(LOC("<LOC lobui_0216>Team"), 14)
    labelGroup:AddChild(teamLabel)

    labelGroup:AddChild(makeLabel(LOC("<LOC lobui_0450>CPU"), 14))

    if not singlePlayer then
        labelGroup:AddChild(makeLabel(LOC("<LOC lobui_0451>Ping"), 14))
        labelGroup:AddChild(makeLabel(LOC("<LOC lobui_0218>Ready"), 14))
    end

    for i= 1, LobbyComm.maxPlayerSlots do
        -- Capture the index in the current closure so it's accessible on callbacks
        local curRow = i

        -- The background is parented on the GUI so it doesn't vanish when we hide the slot.
        local slotBackground = Bitmap(GUI, UIUtil.SkinnableFile("/SLOT/slot-dis.dds"))

        -- Inherit dimensions of the slot control from the background image.
        local newSlot = ColumnLayout(GUI.playerPanel, COLUMN_POSITIONS, COLUMN_WIDTHS)
        newSlot.Width:Set(slotBackground.Width)
        newSlot.Height:Set(slotBackground.Height)

        LayoutHelpers.AtLeftTopIn(slotBackground, newSlot)
        newSlot.SlotBackground = slotBackground

        -- Default mouse behaviours for the slot.
        local defaultHandler = function(self, event)
            if curRow > numOpenSlots then
                return
            end

            local associatedMarker = GUI.mapView.startPositions[curRow]
            if event.Type == 'MouseEnter' then
                if gameInfo.GameOptions['TeamSpawn'] == 'fixed' then
                    associatedMarker.indicator:Play()
                end
            elseif event.Type == 'MouseExit' then
                associatedMarker.indicator:Stop()
            elseif event.Type == 'ButtonDClick' then
                DoSlotBehavior(curRow, 'occupy', '')
            end

            return Group.HandleEvent(self, event)
        end
        newSlot.HandleEvent = defaultHandler

        -- Slot number
        local slotNumber = UIUtil.CreateText(newSlot, tostring(i), 14, 'Arial')
        newSlot.slotNumber = slotNumber
        LayoutHelpers.SetWidth(slotNumber, COLUMN_WIDTHS[1])
        slotNumber.Height:Set(newSlot.Height)
        newSlot:AddChild(slotNumber)
        newSlot.tooltipnumber = Tooltip.AddControlTooltip(slotNumber, 'slot_number')
        slotNumber.id = i
        slotNumber.HandleEvent = function(self,event)
            
            if lobbyComm:IsHost() then
                if event.Type == 'ButtonPress' then
                    if playersToSwap then
                        --same number clicked
                        if self.id == playersToSwap then
                            playersToSwap = false
                            self:SetColor(UIUtil.fontColor)
                        elseif gameInfo.PlayerOptions[playersToSwap] then
                            HostUtils.SwapPlayers(playersToSwap, self.id)
                            GUI.slots[playersToSwap].slotNumber:SetColor(UIUtil.fontColor)
                            playersToSwap = false
                        elseif gameInfo.PlayerOptions[self.id] then
                            HostUtils.SwapPlayers(self.id, playersToSwap)
                            GUI.slots[playersToSwap].slotNumber:SetColor(UIUtil.fontColor)
                            playersToSwap = false
                        end
                    else
                        self:SetColor('ff00ffff')
                        playersToSwap = self.id
                    end
                end
            end
        end
        -- COUNTRY
        -- Added a bitmap on the left of Rating, the bitmap is a Flag of Country
        local flag = Bitmap(newSlot, UIUtil.SkinnableFile("/countries/world.dds"))
        newSlot.KinderCountry = flag
        LayoutHelpers.SetWidth(flag, COLUMN_WIDTHS[2])
        newSlot:AddChild(flag)

        -- TODO: Factorise this boilerplate.
        -- Rating
        local ratingText = UIUtil.CreateText(newSlot, "", 14, 'Arial')
        newSlot.ratingText = ratingText
        ratingText:SetColor('B9BFB9')
        ratingText:SetDropShadow(true)
        newSlot:AddChild(ratingText)

        -- NumGame
        local numGamesText = UIUtil.CreateText(newSlot, "", 14, 'Arial')
        newSlot.numGamesText = numGamesText
        numGamesText:SetColor('B9BFB9')
        numGamesText:SetDropShadow(true)
        Tooltip.AddControlTooltip(numGamesText, 'num_games')
        newSlot:AddChild(numGamesText)

        -- Name
        local nameLabel = Combo(newSlot, 14, 16, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        newSlot.name = nameLabel
        nameLabel._text:SetFont('Arial Gras', 15)
        newSlot:AddChild(nameLabel)
        LayoutHelpers.SetWidth(nameLabel, COLUMN_WIDTHS[5])
        -- left deal with name clicks
        nameLabel.OnEvent = defaultHandler
        nameLabel.OnClick = function(self, index, text)
            DoSlotBehavior(curRow, self.slotKeys[index], text)
        end

        -- Hide the marker when the dropdown is hidden
        nameLabel.OnHide = function()
            local associatedMarker = GUI.mapView.startPositions[curRow]
            if associatedMarker then
                associatedMarker.indicator:Stop()
            end
        end

        -- Color
        local colorSelector = BitmapCombo(newSlot, gameColors.PlayerColors, 1, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        newSlot.color = colorSelector

        newSlot:AddChild(colorSelector)
        LayoutHelpers.SetWidth(colorSelector, COLUMN_WIDTHS[6])
        colorSelector.OnClick = function(self, index)
            if not lobbyComm:IsHost() then
                lobbyComm:SendData(hostID, { Type = 'RequestColor', Color = index })
                SetPlayerColor(gameInfo.PlayerOptions[curRow], index)
                UpdateGame()
            else
                if IsColorFree(index) then
                    lobbyComm:BroadcastData({ Type = 'SetColor', Color = index, Slot = curRow })
                    SetPlayerColor(gameInfo.PlayerOptions[curRow], index)
                    UpdateGame()
                else
                    self:SetItem(gameInfo.PlayerOptions[curRow].PlayerColor)
                end
            end
        end
        colorSelector.OnEvent = defaultHandler
        Tooltip.AddControlTooltip(colorSelector, 'lob_color')

        -- Faction
        -- builds the faction tables, and then adds random faction icon to the end
        local factionBmps = {}
        local factionTooltips = {}
        local factionList = {}
        for index, tbl in FactionData.Factions do
            factionBmps[index] = tbl.SmallIcon
            factionTooltips[index] = tbl.TooltipID
            factionList[index] = tbl.Key
        end
        table.insert(factionBmps, "/faction_icon-sm/random_ico.dds")
        table.insert(factionTooltips, 'lob_random')
        table.insert(factionList, 'random')
        -- lobby.lua reads this list (faction selector / GetSlotFactionIndex), so
        -- write through to its global rather than to our own environment copy.
        SetAllAvailableFactionsList(factionList)

        local factionSelector = BitmapCombo(newSlot, factionBmps, table.getn(factionBmps), nil, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        newSlot.faction = factionSelector
        newSlot.AvailableFactions = factionList
        newSlot:AddChild(factionSelector)
        LayoutHelpers.SetWidth(factionSelector, COLUMN_WIDTHS[7])
        factionSelector.OnClick = function(self, index)
            SetPlayerOption(curRow, 'Faction', index)
            if curRow == FindSlotForID(FindIDForName(localPlayerName)) then
                local fact = GUI.slots[FindSlotForID(localPlayerID)].AvailableFactions[index]
                for ind,value in GetAllAvailableFactionsList() do
                    if fact == value then
                        GUI.factionSelector:SetSelected(ind)
                        break
                    end
                end
            end

            Tooltip.DestroyMouseoverDisplay()
        end
        Tooltip.AddControlTooltip(factionSelector, 'lob_faction')
        Tooltip.AddComboTooltip(factionSelector, factionTooltips)
        factionSelector.OnEvent = defaultHandler

        -- Team
        local teamSelector = Combo(newSlot, 17, 9, nil, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        teamSelector:AddItems({' - ', ' 1', ' 2', ' 3', ' 4', ' 5', ' 6', ' 7', ' 8'})
        teamSelector._text:SetFont('Arial', 14)
        teamSelector._titleColor = 'White'
        newSlot.team = teamSelector
        newSlot:AddChild(teamSelector)
        LayoutHelpers.SetWidth(teamSelector, COLUMN_WIDTHS[8])
        teamSelector.OnClick = function(self, index, text)
            Tooltip.DestroyMouseoverDisplay()
            SetPlayerOption(curRow, 'Team', index)
        end
        Tooltip.AddControlTooltip(teamSelector, 'lob_team')
        teamSelector.OnEvent = defaultHandler

        -- CPU
        local barMax = 450
        local barMin = 0
        local CPUGroup = Group(newSlot)
        newSlot.CPUGroup = CPUGroup
        LayoutHelpers.SetWidth(CPUGroup, COLUMN_WIDTHS[9])
        CPUGroup.Height:Set(newSlot.Height)
        newSlot:AddChild(CPUGroup)
        local CPUSpeedBar = StatusBar(CPUGroup, barMin, barMax, false, false,
        UIUtil.UIFile('/game/unit_bmp/bar_black_bmp.dds'),
        UIUtil.UIFile('/game/unit_bmp/bar_purple_bmp.dds'),
        true)
        newSlot.CPUSpeedBar = CPUSpeedBar
        LayoutHelpers.AtTopIn(CPUSpeedBar, CPUGroup, 7)
        LayoutHelpers.AtLeftIn(CPUSpeedBar, CPUGroup, 0)
        LayoutHelpers.AtRightIn(CPUSpeedBar, CPUGroup, 0)
        CPUBenchmark.CPU_AddControlTooltip(CPUSpeedBar, 0, curRow)
        CPUSpeedBar.CPUActualValue = 450
        CPUSpeedBar.barMax = barMax

        -- Ping
        barMax = 1000
        barMin = 0
        local pingGroup = Group(newSlot)
        newSlot.pingGroup = pingGroup
        LayoutHelpers.SetWidth(pingGroup, COLUMN_WIDTHS[10])
        pingGroup.Height:Set(newSlot.Height)
        newSlot:AddChild(pingGroup)
        local pingStatus = StatusBar(pingGroup, barMin, barMax, false, false,
            UIUtil.SkinnableFile('/game/unit_bmp/bar-back_bmp.dds'),
            UIUtil.SkinnableFile('/game/unit_bmp/bar-01_bmp.dds'),
            true)
        newSlot.pingStatus = pingStatus
        LayoutHelpers.AtTopIn(pingStatus, pingGroup, 7)
        LayoutHelpers.AtLeftIn(pingStatus, pingGroup, 0)
        LayoutHelpers.AtRightIn(pingStatus, pingGroup, 0)
        Ping_AddControlTooltip(pingStatus, 0, curRow)

        -- Ready Checkbox
        local readyBox = UIUtil.CreateCheckbox(newSlot, '/CHECKBOX/')
        newSlot.ready = readyBox
        newSlot:AddChild(readyBox)
        readyBox.OnCheck = function(self, checked)
            UIUtil.setEnabled(GUI.becomeObserver, not checked)
            if checked then
                DisableSlot(curRow, true)
            else
                EnableSlot(curRow)
            end
            SetPlayerOption(curRow, 'Ready', checked)
        end

        newSlot.HideControls = function()
            -- hide these to clear slot of visible data
            flag:Hide()
            ratingText:Hide()
            numGamesText:Hide()
            factionSelector:Hide()
            colorSelector:Hide()
            teamSelector:Hide()
            CPUSpeedBar:Hide()
            pingStatus:Hide()
            readyBox:Hide()
        end
        newSlot.HideControls()

        if singlePlayer then
            -- TODO: Use of groups may allow this to be simplified...
            readyBox:Hide()
            pingStatus:Hide()
        end

        if i == 1 then
            LayoutHelpers.Below(newSlot, GUI.labelGroup)
        else
            LayoutHelpers.Below(newSlot, GUI.slots[i - 1], 3)
        end

        GUI.slots[i] = newSlot
    end
end

-- create UI won't typically be called directly by another module


-- create UI won't typically be called directly by another module
function CreateUI(maxPlayers)
    local ResourceMapPreview = import("/lua/ui/controls/resmappreview.lua").ResourceMapPreview
    local ItemList = import("/lua/maui/itemlist.lua").ItemList
    local Prefs = import("/lua/user/prefs.lua")
    local Tooltip = import("/lua/ui/game/tooltip.lua")
    local Combo = import("/lua/ui/controls/combo.lua")

    local isHost = lobbyComm:IsHost()
    local lastFaction = GetSanitisedLastFaction()
    UIUtil.SetCurrentSkin(FACTION_NAMES[lastFaction])

    ---------------------------------------------------------------------------
    -- Set up main control panels
    ---------------------------------------------------------------------------
    GUI.panel = Bitmap(GUI, UIUtil.SkinnableFile("/scx_menu/lan-game-lobby/lobby.dds"))
    LayoutHelpers.AtCenterIn(GUI.panel, GUI)
    GUI.panelWideLeft = Bitmap(GUI, UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/wide.dds'))
    LayoutHelpers.CenteredLeftOf(GUI.panelWideLeft, GUI.panel)
    GUI.panelWideLeft.Left:Set(function() return GUI.Left() end)
    GUI.panelWideRight = Bitmap(GUI, UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/wide.dds'))
    LayoutHelpers.CenteredRightOf(GUI.panelWideRight, GUI.panel)
    GUI.panelWideRight.Right:Set(function() return GUI.Right() end)

    -- Create a label with a given size and initial text
    local function makeLabel(text, size)
        return UIUtil.CreateText(GUI.panel, text, size, 'Arial Gras', true)
    end

    -- Map name label
    GUI.MapNameLabel = makeLabel(LOC("<LOC LOADING>Loading..."), 17)
    LayoutHelpers.AtRightTopIn(GUI.MapNameLabel, GUI.panel, 5, 45)

    -- Game Quality Label
    GUI.GameQualityLabel = makeLabel("", 11)
    LayoutHelpers.AtRightTopIn(GUI.GameQualityLabel, GUI.panel, 5, 64)

    -- Title Label
    GUI.titleText = makeLabel(LOC("<LOC lobui_0427>FAF Game Lobby"), 17)
    LayoutHelpers.AtLeftTopIn(GUI.titleText, GUI.panel, 5, 20)

    if isHost then
        GUI.titleText.HandleEvent = function(self, event)
            if event.Type == 'ButtonPress' then
                ShowTitleDialog()
            end
        end
    end

    -- Rule Label
    local RuleLabel = TextArea(GUI.panel, 350, 34)
    GUI.RuleLabel = RuleLabel
    RuleLabel:SetFont('Arial Gras', 11)
    RuleLabel:SetColors("B9BFB9", "00000000", "B9BFB9", "00000000")
    LayoutHelpers.AtLeftTopIn(RuleLabel, GUI.panel, 5, 44)
    RuleLabel:DeleteAllItems()
    local tmptext
    if isHost then
        tmptext = LOC("<LOC lobui_0420>No Rules: Click to add rules")
        RuleLabel:SetColors("FFCC00")
    else
        tmptext = LOC("<LOC lobui_0421>No rules")
    end

    RuleLabel:SetText(tmptext)
    if isHost then
        RuleLabel.OnClick = function(self)
            ShowRuleDialog()
        end
    end

    -- Mod Label
    GUI.ModFeaturedLabel = makeLabel("", 13)
    LayoutHelpers.AtLeftTopIn(GUI.ModFeaturedLabel, GUI.panel, 50, 61)

    -- Set the mod name to a value appropriate for the mod in use.
    local modLabels = {
        ["init_faf.lua"] = "FA Forever",
        ["init_blackops.lua"] = "BlackOps",
        ["init_coop.lua"] = "COOP",
        ["init_balancetesting.lua"] = "Balance Testing",
        ["init_gw.lua"] = "Galactic War",
        ["init_labwars.lua"] = "Labwars",
        ["init_ladder1v1.lua"] = "Ladder 1v1",
        ["init_nomads.lua"] = "Nomads Mod",
        ["init_phantomx.lua"] = "PhantomX",
        ["init_supremedestruction.lua"] = "SupremeDestruction",
        ["init_xtremewars.lua"] = "XtremeWars",

    }
    GUI.ModFeaturedLabel:StreamText(modLabels[argv.initName] or "", 20)

    -- Lobby options panel
    GUI.LobbyOptions = UIUtil.CreateButtonWithDropshadow(GUI.panel, '/BUTTON/medium/', LOC("<LOC tooltipui0705>Settings"))
    LayoutHelpers.AtRightTopIn(GUI.LobbyOptions, GUI.panel, 44, 3)
    GUI.LobbyOptions.OnClick = function()
        ShowLobbyOptionsDialog()
    end
    Tooltip.AddButtonTooltip(GUI.LobbyOptions, 'lobby_click_Settings')

    -- Logo
    GUI.logo = Bitmap(GUI, '/textures/ui/common/scx_menu/lan-game-lobby/logo.dds')
    LayoutHelpers.AtLeftTopIn(GUI.logo, GUI, 1, 1)

    local version, gametype, commit = import("/lua/version.lua").GetVersionData()
    GUI.gameVersionText = UIUtil.CreateText(GUI.panel, LOC('<LOC lobui_0466>Game version ') .. version, 9, UIUtil.bodyFont)
    GUI.gameVersionText:SetColor('677983')
    GUI.gameVersionText:SetDropShadow(true)

    Tooltip.AddControlTooltipManual(GUI.gameVersionText, '<LOC lobui_0467>Version control', string.format(
        LOC('<LOC lobui_0468>Game version: %s\nGame type: %s\nCommit hash: %s'), version, gametype, commit:sub(1, 8)
    ))

    LayoutHelpers.AtLeftTopIn(GUI.gameVersionText, GUI.panel, 70, 3)

    -- Player Slots
    GUI.playerPanel = Group(GUI.panel, "playerPanel")
    LayoutHelpers.AtLeftTopIn(GUI.playerPanel, GUI.panel, 6, 70)
    LayoutHelpers.SetDimensions(GUI.playerPanel, 706, 307)

    -- Observer section
    GUI.observerPanel = Group(GUI.panel, "observerPanel")

    -- Scale the observer panel according to the buttons we are showing.
    local obsOffset
    local obsHeight
    if isHost then
        obsHeight = 84--159
        obsOffset = 620--545
    else
        obsHeight = 206
        obsOffset = 498
    end
    LayoutHelpers.AtLeftTopIn(GUI.observerPanel, GUI.panel, 512, obsOffset)
    LayoutHelpers.SetDimensions(GUI.observerPanel, 278, obsHeight)
    UIUtil.SurroundWithBorder(GUI.observerPanel, '/scx_menu/lan-game-lobby/frame/')

    -- Chat
    GUI.chatPanel = Group(GUI.panel, "chatPanel")
    LayoutHelpers.AtLeftTopIn(GUI.chatPanel, GUI.panel, 11, 459)
    LayoutHelpers.SetWidth(GUI.chatPanel, 478)
    LayoutHelpers.SetHeight(GUI.chatPanel, 245)
    UIUtil.SurroundWithBorder(GUI.chatPanel, '/scx_menu/lan-game-lobby/frame/')

    if isHost then
        GUI.AIFillPanel = Group(GUI.panel)
        GUI.AIFillPanel.Left:Set(GUI.observerPanel.Left)
        GUI.AIFillPanel.Top:Set(GUI.chatPanel.Top)
        LayoutHelpers.SetHeight(GUI.AIFillPanel, 60)
        LayoutHelpers.SetWidth(GUI.AIFillPanel, 278)
        UIUtil.SurroundWithBorder(GUI.AIFillPanel, '/scx_menu/lan-game-lobby/frame/')
        GUI.AIFillCombo = Combo.Combo(GUI.AIFillPanel, 14, 12, false, nil)
        LayoutHelpers.AtHorizontalCenterIn(GUI.AIFillCombo, GUI.AIFillPanel)
        LayoutHelpers.AtTopIn(GUI.AIFillCombo, GUI.AIFillPanel, 5)
        GUI.AIFillCombo.Width:Set(function() return GUI.AIFillPanel.Width() - LayoutHelpers.ScaleNumber(15) end)
        GUI.AIFillCombo:AddItems(AIStrings)
        GUI.AIFillCombo:SetTitleText(LOC('<LOC lobui_0461>Choose AI for autofilling'))
        Tooltip.AddComboTooltip(GUI.AIFillCombo, AITooltips)
        GUI.AIFillButton = UIUtil.CreateButtonStd(GUI.AIFillCombo, '/BUTTON/medium/', LOC('<LOC lobui_0462>Fill Slots'), 12)
        LayoutHelpers.SetWidth(GUI.AIFillButton, 129)
        LayoutHelpers.SetHeight(GUI.AIFillButton, 30)
        LayoutHelpers.AtLeftTopIn(GUI.AIFillButton, GUI.AIFillCombo, -10, 20)
        GUI.AIClearButton = UIUtil.CreateButtonStd(GUI.AIFillButton, '/BUTTON/medium/', LOC('<LOC lobui_0463>Clear Slots'), 12)
        GUI.AIClearButton.Width:Set(GUI.AIFillButton.Width)
        GUI.AIClearButton.Height:Set(GUI.AIFillButton.Height)
        LayoutHelpers.RightOf(GUI.AIClearButton, GUI.AIFillButton, -19)
        GUI.TeamCountSelector = Combo.BitmapCombo(GUI.AIClearButton, teamIcons, 1, false, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        LayoutHelpers.SetWidth(GUI.TeamCountSelector, 44)
        LayoutHelpers.AtTopIn(GUI.TeamCountSelector, GUI.AIClearButton, 5)
        LayoutHelpers.AtRightIn(GUI.TeamCountSelector, GUI.AIFillPanel, 8)
        local tooltipText = {}
        tooltipText['text'] = '<LOC tooltipui0710>Teams Count'
        tooltipText['body'] = '<LOC tooltipui0711>On how many teams share players?'
        Tooltip.AddControlTooltip(GUI.TeamCountSelector, tooltipText, 0)
        local ChangedSlots = {}
        GUI.AIFillButton.OnClick = function()
          local AIKeyIndex, AIName = GUI.AIFillCombo:GetItem()
          if ChangedSlots[1] ~= nil then
            for i = 1, table.getn(ChangedSlots) do
              HostUtils.AddAI(AIName, AIKeys[AIKeyIndex], ChangedSlots[i])
            end
          else
            for Slot = 1, GetNumAvailStartSpots() do
              if not (gameInfo.PlayerOptions[Slot] or gameInfo.ClosedSlots[Slot]) then
                HostUtils.AddAI(AIName, AIKeys[AIKeyIndex], Slot)
                table.insert(ChangedSlots, Slot)
              end
            end
          end
          if gameInfo.GameOptions.AutoTeams == 'none' then
            GUI.TeamCountSelector.OnClick(nil, GUI.TeamCountSelector:GetItem(), nil)
          else
            Autobalance.AssignAutoTeams()
          end
        end
        GUI.AIClearButton.OnClick = function()
          for i = 1, table.getn(ChangedSlots) do
            HostUtils.RemoveAI(ChangedSlots[i])
          end
          ChangedSlots = {}
        end
        GUI.TeamCountSelector.OnClick = function(Self, Index, Text)
          local OccupiedSlots = 0
          local AvailStartSpots = GetNumAvailStartSpots()
          for Slot = 1, AvailStartSpots do
            if gameInfo.PlayerOptions[Slot] ~= nil then
              OccupiedSlots = OccupiedSlots + 1
            end
          end
          local PlayersPerTeam = 0
          if Index > 1 then
            PlayersPerTeam = math.floor(OccupiedSlots / (Index - 1))
          end
          local AssignedTeam = 2
          local Counter = 0
          for Slot = 1, AvailStartSpots do
            if gameInfo.PlayerOptions[Slot] then
              if AssignedTeam > Index then
                SetPlayerOption(Slot, 'Team', 1, true)
              else
                SetPlayerOption(Slot, 'Team', AssignedTeam, true)
                Counter = Counter + 1
                if Counter >= PlayersPerTeam then
                  AssignedTeam = AssignedTeam + 1
                  Counter = 0
                end
              end
              SetSlotInfo(Slot, gameInfo.PlayerOptions[Slot])
            end
          end
        end
    end

    -- Map Preview
    GUI.mapPanel = Group(GUI.panel, "mapPanel")
    LayoutHelpers.AtLeftTopIn(GUI.mapPanel, GUI.panel, 813, 88)
    LayoutHelpers.SetDimensions(GUI.mapPanel, 198, 198)
    LayoutHelpers.DepthOverParent(GUI.mapPanel, GUI.panel, 2)
    UIUtil.SurroundWithBorder(GUI.mapPanel, '/scx_menu/lan-game-lobby/frame/')

    -- Map Preview Info Labels
    local tooltipText = {}
    tooltipText['text'] = LOC("<LOC lobui_0772>Map Preview")
    -- Map Preview Info Labels
    if isHost then
        tooltipText['body'] = LOCF("%s\n%s", "<LOC lobui_0769>Left click ACU icon to move yourself or swap players.", "<LOC lobui_0770>Right click ACU icon to close or open the slot.")
    else
        tooltipText['body'] = LOC("<LOC lobui_0771>Left click ACU icon to move yourself.")
    end
    Tooltip.AddControlTooltip(GUI.mapPanel, tooltipText)

    GUI.optionsPanel = Group(GUI.panel, "optionsPanel") -- ORANGE Square in Screenshoot
    LayoutHelpers.AtLeftTopIn(GUI.optionsPanel, GUI.panel, 813, 325)
    LayoutHelpers.SetDimensions(GUI.optionsPanel, 198, 337)
    LayoutHelpers.DepthOverParent(GUI.optionsPanel, GUI.panel, 2)
    UIUtil.SurroundWithBorder(GUI.optionsPanel, '/scx_menu/lan-game-lobby/frame/')

    ---------------------------------------------------------------------------
    -- set up map panel
    ---------------------------------------------------------------------------
    GUI.mapView = ResourceMapPreview(GUI.mapPanel, 200, 3, 5)
    LayoutHelpers.AtLeftTopIn(GUI.mapView, GUI.mapPanel, -1, -1)
    LayoutHelpers.DepthOverParent(GUI.mapView, GUI.mapPanel, -1)

    GUI.LargeMapPreview = UIUtil.CreateButtonWithDropshadow(GUI.mapPanel, '/BUTTON/zoom/', "")
    LayoutHelpers.SetDimensions(GUI.LargeMapPreview, 30, 30)
    LayoutHelpers.AtRightIn(GUI.LargeMapPreview, GUI.mapPanel, -1)
    LayoutHelpers.AtBottomIn(GUI.LargeMapPreview, GUI.mapPanel, -1)
    LayoutHelpers.DepthOverParent(GUI.LargeMapPreview, GUI.mapPanel, 2)
    Tooltip.AddButtonTooltip(GUI.LargeMapPreview, 'lob_click_LargeMapPreview')
    GUI.LargeMapPreview.OnClick = function()
        CreateBigPreview(GUI)
    end

    -- Checkbox Show changed Options
    local cbox_ShowChangedOption = UIUtil.CreateCheckbox(GUI.optionsPanel, '/CHECKBOX/', LOC("<LOC lobui_0422>Hide default options"), true, 11)
    LayoutHelpers.AtLeftTopIn(cbox_ShowChangedOption, GUI.optionsPanel, 0, -32)

    Tooltip.AddCheckboxTooltip(cbox_ShowChangedOption, {text=LOC("<LOC lobui_0422>Hide default options"), body=LOC("<LOC lobui_0423>Show only changed Options and Advanced Map Options")})
    cbox_ShowChangedOption.OnCheck = function(self, checked)
        HideDefaultOptions = checked
        RefreshOptionDisplayData()
        GUI.OptionContainer:ScrollSetTop('Vert', 0)
        Prefs.SetToCurrentProfile('LobbyHideDefaultOptions', tostring(checked))
    end

    -- Patchnotes Button
    GUI.patchnotesButton = UIUtil.CreateButtonWithDropshadow(GUI.panel, '/Button/medium/', "<LOC _Patchnotes>Patchnotes")
    Tooltip.AddButtonTooltip(GUI.patchnotesButton, 'Lobby_patchnotes')
    LayoutHelpers.AtBottomIn(GUI.patchnotesButton, GUI.optionsPanel, -51)
    LayoutHelpers.AtHorizontalCenterIn(GUI.patchnotesButton, GUI.optionsPanel, -55)
    GUI.patchnotesButton.OnClick = function(self, event)
        import("/lua/ui/lobby/changelog/changelogdialog.lua").CreateChangelogDialog(GUI)
    end

    -- Create mission briefing button
    local briefingButton = UIUtil.CreateButtonWithDropshadow(GUI.optionsPanel, '/BUTTON/medium/', "<LOC _Briefing>Briefing")
    GUI.briefingButton = briefingButton
    LayoutHelpers.AtBottomIn(GUI.briefingButton, GUI.optionsPanel, -51)
    LayoutHelpers.AtHorizontalCenterIn(GUI.briefingButton, GUI.optionsPanel, -55)
    briefingButton.OnClick = function(self, modifiers)
        GUI.briefing = Group(GUI)
        GUI.briefing.Depth:Set(function() return GUI.Depth() + 20 end)
        LayoutHelpers.FillParent(GUI.briefing, GUI)
        import('/lua/ui/campaign/operationbriefing.lua').CreateUI(GUI.briefing, gameInfo.GameOptions.ScenarioFile)
    end

    -- A buton that, for the host, is "game options", but for everyone else shows a ready-only mod
    -- manager.
    if isHost then
        GUI.gameoptionsButton = UIUtil.CreateButtonWithDropshadow(GUI.optionsPanel, '/BUTTON/medium/', "<LOC _Options>")
        Tooltip.AddButtonTooltip(GUI.gameoptionsButton, 'lob_select_map')
        GUI.gameoptionsButton.OnClick = function(self)
            local mapSelectDialog

            autoRandMap = false
            local function selectBehavior(selectedScenario, changedOptions, restrictedCategories)
                local options = {}
                if autoRandMap then
                    options['ScenarioFile'] = selectedScenario.file
                else
                    mapSelectDialog:Destroy()
                    GUI.chatEdit:AcquireFocus()

                    -- remove old 'Advanced options incase of new map
                    if gameInfo.GameOptions.ScenarioFile and string.lower(selectedScenario.file) ~= string.lower(gameInfo.GameOptions.ScenarioFile) then
                        local scenario = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
                        if scenario.options then
                            for _,value in scenario.options do
                                gameInfo.GameOptions[value.key] = nil
                            end
                        end
                    end

                    for optionKey, data in changedOptions do
                        options[optionKey] = data.value
                    end
                    options['ScenarioFile'] = selectedScenario.file
                    options['RestrictedCategories'] = restrictedCategories

                    -- every new map, clear the flags, and clients will report if a new map is bad
                    ClearBadMapFlags()
                    HostUtils.UpdateMods()
                    SetGameOptions(options)
                end
                for optionKey, data in changedOptions do
                    if optionKey == 'AutoTeams' then
                        Autobalance.AssignAutoTeams()
                    end
                end
            end

            local function exitBehavior()
                mapSelectDialog:Close()
                GUI.chatEdit:AcquireFocus()
                UpdateGame()
            end

            GUI.chatEdit:AbandonFocus()

            mapSelectDialog = import("/lua/ui/dialogs/mapselect.lua").CreateDialog(
                selectBehavior,
                exitBehavior,
                GUI,
                singlePlayer,
                gameInfo.GameOptions.ScenarioFile,
                gameInfo.GameOptions,
                availableMods,
                OnModsChanged
            )
        end
    else
        local modsManagerCallback = function(active_sim_mods, active_ui_mods)
            import("/lua/mods.lua").SetSelectedMods(SetUtils.Union(active_sim_mods, active_ui_mods))
            RefreshOptionDisplayData()
            GUI.chatEdit:AcquireFocus()
        end
        GUI.gameoptionsButton = UIUtil.CreateButtonWithDropshadow(GUI.optionsPanel, '/BUTTON/medium/', LOC("<LOC _Mod_Manager>"))
        GUI.gameoptionsButton.OnClick = function(self, modifiers)
            import("/lua/ui/lobby/modsmanager.lua").CreateDialog(GUI, false, nil, modsManagerCallback)
        end
        Tooltip.AddButtonTooltip(GUI.gameoptionsButton, 'Lobby_Mods')
    end

    LayoutHelpers.AtBottomIn(GUI.gameoptionsButton, GUI.optionsPanel, -51)
    LayoutHelpers.AtHorizontalCenterIn(GUI.gameoptionsButton, GUI.optionsPanel, 53)

    ---------------------------------------------------------------------------
    -- set up chat display
    ---------------------------------------------------------------------------

    GUI.chatDisplay = import("/lua/ui/lobby/chatarea.lua").ChatArea(
        GUI.chatPanel,
        function() return GUI.chatPanel.Width() - 20 end,
        function() return GUI.chatPanel.Height() - GUI.chatBG.Height() end
    )
    LayoutHelpers.AtLeftTopIn(GUI.chatDisplay, GUI.chatPanel, 2)
    LayoutHelpers.DepthUnderParent(GUI.chatDisplay, GUI.chatPanel)

    ---------------------------------------------------------------------------
    -- set up all .*Scroll* functions for the chat panel
    ---------------------------------------------------------------------------
    GUI.chatPanel.top = 1 -- using 1-based index scrolling

    -- this function get index of 1st line on the last scroll page (when scroll all the way down)
    GUI.chatPanel.GetScrollLastPage = function(self)
        return table.getn(GUI.chatDisplay.ChatLines) - self.linesPerScrollPage
    end
    -- this function gets scrolling max range and current range
    GUI.chatPanel.GetScrollValues = function(self, axis)
        local max = table.getsize(GUI.chatDisplay.ChatLines)
        local bottom = math.min(self.top + self.linesPerScrollPage, max)
        return 1, max, self.top, bottom
    end
    -- this function controls how many lines to scroll when clicking on up/down arrows of the scrollbar
    GUI.chatPanel.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end
    -- this function controls how many pages to scroll when clicking above/below thumb of the scrollbar
    GUI.chatPanel.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * self.linesPerScrollPage)
    end
    -- this function controls how to scroll to an item from top index
    GUI.chatPanel.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        local delta = self:GetScrollLastPage()
        self.top = math.max(math.min(delta + 1, top), 1)
        self.bottom = self.top + self.linesPerScrollPage
        GUI.chatDisplay:ShowLines(self.top, self.bottom)
        if self.top >= delta + 1 then
           GUI.newMessageArrow:Disable()
        end
    end
    -- this function triggers scrolling on mouse wheel event
    GUI.chatPanel.HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            -- scroll chat panel by 1 line in up/down direction
            local lines = event.WheelRotation > 0 and -1 or 1
            self:ScrollLines(nil, lines)
        end
    end
    -- this function informs vertical scrollbar that the chat panel can be scrolled
    GUI.chatPanel.IsScrollable = function(self, axis)
        return true
    end
    GUI.chatPanel.ScrollToBottom = function(self)
        self:ScrollSetTop(nil, self:GetScrollLastPage() + 1)
    end
    GUI.chatPanel.IsScrolledToBottom = function(self)
        return self.top >= self:GetScrollLastPage()
    end
    -- this function set how many chat lines can fit per scroll page (chatPanel)
    GUI.chatPanel.LinesOnPage = import("/lua/lazyvar.lua").Create()
    GUI.chatPanel.LinesOnPage.OnDirty = function(var)
        GUI.chatPanel.linesPerScrollPage = var()
    end
    -- --------- Chat Scrolling Functions -----------------------

    -- this function sets font for all chat lines and re-creates them
    GUI.chatPanel.SetFont = function(self, fontFamily, fontSize)
        GUI.chatDisplay:SetFont(fontFamily, fontSize)
        GUI.chatDisplay:ShowLines(self.top, self.bottom)
    end
    -- set initial scrolling based on chat font size
    local fontSize = tonumber(Prefs.GetFromCurrentProfile('LobbyChatFontSize')) or 14

    local newMessageArrow = Button(GUI.chatPanel, '/textures/ui/common/lobby/chat_arrow/arrow_up.dds', '/textures/ui/common/lobby/chat_arrow/arrow_down.dds', '/textures/ui/common/lobby/chat_arrow/arrow_down.dds','/textures/ui/common/lobby/chat_arrow/arrow_dis.dds', "UI_Arrow_Click")
    GUI.newMessageArrow = newMessageArrow
    -- newMessageArrow:SetTexture('/textures/ui/common/FACTIONSELECTOR/aeon/d_up.dds')
    LayoutHelpers.AtBottomIn(newMessageArrow, GUI.chatDisplay, 5)
    LayoutHelpers.AtRightIn(newMessageArrow, GUI.chatDisplay, 5)
    LayoutHelpers.DepthOverParent(newMessageArrow, GUI.chatDisplay, 5)
    newMessageArrow.Width:Set(25)
    newMessageArrow.Height:Set(25)
    GUI.newMessageArrow.OnClick = function(this, modifiers)
        GUI.chatPanel:ScrollToBottom()
    end
    GUI.newMessageArrow:Disable()

    -- Annoying evil extra Bitmap to make chat box have padding inside its background.
    local chatBG = Bitmap(GUI.chatPanel)
    GUI.chatBG = chatBG
    chatBG:SetSolidColor('FF212123')
    LayoutHelpers.Below(chatBG, GUI.chatDisplay, 0)
    LayoutHelpers.AtLeftIn(chatBG, GUI.chatDisplay, -2)
    chatBG.Width:Set(GUI.chatPanel.Width)
    LayoutHelpers.SetHeight(chatBG, 24)
    
    -- Set up the chat edit buttons and functions
    setupChatEdit(GUI.chatPanel)
    -- finally create chat lines
    GUI.chatDisplay:CreateLines()
    ---------------------------------------------------------------------------
    -- Option display
    ---------------------------------------------------------------------------
    GUI.OptionContainer = Group(GUI.optionsPanel)
    GUI.OptionContainer.Bottom:Set(function() return GUI.optionsPanel.Bottom() end)

    -- Leave space for the scrollbar.
    GUI.OptionContainer.Width:Set(function() return GUI.optionsPanel.Width() - LayoutHelpers.ScaleNumber(18) end)
    GUI.OptionContainer.top = 0
    LayoutHelpers.AtLeftTopIn(GUI.OptionContainer, GUI.optionsPanel, 1, 1)
    LayoutHelpers.DepthOverParent(GUI.OptionContainer, GUI.optionsPanel, -1)

    GUI.OptionDisplay = {}

    function CreateOptionElements()
        local function CreateElement(index)
            local element = Group(GUI.OptionContainer)

            element.bg = Bitmap(element)
            element.bg:SetSolidColor('ff333333')
            element.bg.Left:Set(element.Left)
            element.bg.Right:Set(element.Right)
            element.bg.Bottom:Set(function() return element.value.Bottom() + 2 end)
            element.bg.Top:Set(element.Top)

            element.bg2 = Bitmap(element)
            element.bg2:SetSolidColor('ff000000')
            element.bg2.Left:Set(function() return element.bg.Left() + 1 end)
            element.bg2.Right:Set(function() return element.bg.Right() - 1 end)
            element.bg2.Bottom:Set(function() return element.bg.Bottom() - 1 end)
            element.bg2.Top:Set(function() return element.value.Top() + 0 end)

            LayoutHelpers.SetHeight(element, 36)
            element.Width:Set(GUI.OptionContainer.Width)
            element:DisableHitTest()

            element.text = UIUtil.CreateText(element, '', 14, "Arial")
            element.text:SetColor(UIUtil.fontColor)
            element.text:DisableHitTest()
            LayoutHelpers.AtLeftTopIn(element.text, element, 5)

            element.value = UIUtil.CreateText(element, '', 14, "Arial")
            element.value:SetColor(UIUtil.fontOverColor)
            element.value:DisableHitTest()
            LayoutHelpers.AtRightTopIn(element.value, element, 5, 16)

            GUI.OptionDisplay[index] = element
        end

        CreateElement(1)
        LayoutHelpers.AtLeftTopIn(GUI.OptionDisplay[1], GUI.OptionContainer)

        local index = 2
        while index ~= 10 do
            CreateElement(index)
            LayoutHelpers.Below(GUI.OptionDisplay[index], GUI.OptionDisplay[index-1])
            index = index + 1
        end
    end
    CreateOptionElements()

    local numLines = function() return table.getsize(GUI.OptionDisplay) end

    local function DataSize()
        if HideDefaultOptions then
            return table.getn(GetNonDefaultFormattedOptions())
        else
            return table.getn(GetFormattedOptions())
        end
    end

    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    GUI.OptionContainer.GetScrollValues = function(self, axis)
        local size = DataSize()
        --LOG(size, ":", self.top, ":", math.min(self.top + numLines, size))
        return 0, size, self.top, math.min(self.top + numLines(), size)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    GUI.OptionContainer.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    GUI.OptionContainer.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * numLines())
    end

    -- called when the scrollbar wants to set a new visible top line
    GUI.OptionContainer.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        local size = DataSize()
        self.top = math.max(math.min(size - numLines() , top), 0)
        self:CalcVisible()
    end

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    GUI.OptionContainer.IsScrollable = function(self, axis)
        return true
    end
    -- determines what controls should be visible or not
    GUI.OptionContainer.CalcVisible = function(self)
        local function SetTextLine(line, data, lineID)
            if data.mod then
                -- The special label at the top stating the number of mods.
                line.text:SetColor('ffff7777')
                LayoutHelpers.AtHorizontalCenterIn(line.text, line, 5)
                LayoutHelpers.AtHorizontalCenterIn(line.value, line, 5, 16)
                LayoutHelpers.ResetRight(line.value)
            else
                -- Game options.
                line.text:SetColor(UIUtil.fontColor)
                LayoutHelpers.AtLeftTopIn(line.text, line, 5)
                LayoutHelpers.AtRightTopIn(line.value, line, 5, 16)
                LayoutHelpers.ResetLeft(line.value)
            end
            line.text:SetText(LOCF(data.text, data.key))
            line.bg:Show()
            line.value:SetText(LOCF(data.value, data.key))
            line.bg2:Show()
            line.bg.HandleEvent = Group.HandleEvent
            line.bg2.HandleEvent = Bitmap.HandleEvent
            if data.tooltip then
                Tooltip.AddControlTooltip(line.bg, data.tooltip)
                Tooltip.AddControlTooltip(line.bg2, data.valueTooltip)
            end

            if data.manualTooltipTitle then
                Tooltip.AddControlTooltipManual(line.bg, data.manualTooltipTitle, data.manualTooltipDescription )
                Tooltip.AddControlTooltipManual(line.bg2, data.manualTooltipTitle, data.manualTooltipDescription )
            end

        end

        local optionsToUse
        if HideDefaultOptions then
            optionsToUse = GetNonDefaultFormattedOptions()
        else
            optionsToUse = GetFormattedOptions()
        end

        for i, v in GUI.OptionDisplay do
            if optionsToUse[i + self.top] then
                SetTextLine(v, optionsToUse[i + self.top], i + self.top)
            else
                v.text:SetText('')
                v.value:SetText('')
                v.bg:Hide()
                v.bg2:Hide()
            end
        end
    end

    GUI.OptionContainer.HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            local lines = 1
            if event.WheelRotation > 0 then
                lines = -1
            end
            self:ScrollLines(nil, lines)
        end
    end

    RefreshOptionDisplayData()

    GUI.OptionContainerScroll = UIUtil.CreateLobbyVertScrollbar(GUI.OptionContainer, 2)
    LayoutHelpers.DepthOverParent(GUI.OptionContainerScroll, GUI.OptionContainer, 2)

    -- Launch Button
    local launchGameButton = UIUtil.CreateButtonWithDropshadow(GUI.chatPanel, '/BUTTON/large/', LOC("<LOC tooltipui0173>Launch Game"))
    GUI.launchGameButton = launchGameButton
    LayoutHelpers.AtHorizontalCenterIn(launchGameButton, GUI)
    LayoutHelpers.AtBottomIn(launchGameButton, GUI.panel, -8)
    Tooltip.AddButtonTooltip(launchGameButton, 'Lobby_Launch')
    UIUtil.setVisible(launchGameButton, isHost)
    launchGameButton.OnClick = function(self)
        TryLaunch(false)
    end

    -- Create skirmish mode's "load game" button.
    local loadButton = UIUtil.CreateButtonWithDropshadow(GUI.optionsPanel, '/BUTTON/medium/',"<LOC lobui_0176>Load")
    GUI.loadButton = loadButton
    UIUtil.setVisible(loadButton, singlePlayer)
    LayoutHelpers.AtVerticalCenterIn(GUI.loadButton, launchGameButton, 7)
    LayoutHelpers.AtHorizontalCenterIn(GUI.loadButton, GUI.optionsPanel)
    loadButton.OnClick = function(self, modifiers)
        import("/lua/ui/dialogs/saveload.lua").CreateLoadDialog(GUI)
    end
    Tooltip.AddButtonTooltip(loadButton, 'Lobby_Load')

    -- Create the "Lobby presets" button for the host. If not the host, the same field is occupied
    -- instead by the read-only "Unit Manager" button.
    GUI.restrictedUnitsOrPresetsBtn = UIUtil.CreateButtonWithDropshadow(GUI.optionsPanel, '/BUTTON/medium/', "")

    if singlePlayer then
        GUI.restrictedUnitsOrPresetsBtn:Hide()
    elseif isHost then
        GUI.restrictedUnitsOrPresetsBtn.label:SetText(LOC("<LOC lobui_0424>Presets"))
        GUI.restrictedUnitsOrPresetsBtn.OnClick = function(self, modifiers)
            Presets.CreateUI(GUI)
        end
        Tooltip.AddButtonTooltip(GUI.restrictedUnitsOrPresetsBtn, 'Lobby_presetDescription')
    else
        GUI.restrictedUnitsOrPresetsBtn.label:SetText(LOC("<LOC lobui_0332>Unit Manager"))
        GUI.restrictedUnitsOrPresetsBtn.OnClick = function(self, modifiers)
            import("/lua/ui/lobby/unitsmanager.lua").CreateDialog(GUI.panel, gameInfo.GameOptions.RestrictedCategories, function() end, function() end, false)
        end
        Tooltip.AddButtonTooltip(GUI.restrictedUnitsOrPresetsBtn, 'lob_RestrictedUnitsClient')
    end
    LayoutHelpers.AtVerticalCenterIn(GUI.restrictedUnitsOrPresetsBtn, launchGameButton, 7)
    LayoutHelpers.AtHorizontalCenterIn(GUI.restrictedUnitsOrPresetsBtn, GUI.optionsPanel)

    ---------------------------------------------------------------------------
    -- Checkbox Show changed Options
    ---------------------------------------------------------------------------
    cbox_ShowChangedOption:SetCheck(HideDefaultOptions, false)

    ---------------------------------------------------------------------------
    -- set up : player grid
    ---------------------------------------------------------------------------

    -- For disgusting reasons, we pass the label factory as a parameter.
    CreateSlotsUI(makeLabel)

    -- Exit Button
    GUI.exitButton = UIUtil.CreateButtonWithDropshadow(GUI.chatPanel, '/BUTTON/medium/', LOC("<LOC tooltipui0285>Exit"))
    LayoutHelpers.AtLeftIn(GUI.exitButton, GUI.chatPanel, 33)
    LayoutHelpers.AtVerticalCenterIn(GUI.exitButton, launchGameButton, 7)
    if HasCommandLineArg("/gpgnet") then
        -- Quit to desktop
        GUI.exitButton.label:SetText(LOC("<LOC _Exit>"))
        Tooltip.AddButtonTooltip(GUI.exitButton, 'esc_exit')
    else
        -- Back to main menu
        GUI.exitButton.label:SetText(LOC("<LOC _Back>"))
        Tooltip.AddButtonTooltip(GUI.exitButton, 'esc_quit')
    end

    GUI.exitButton.OnClick = GUI.exitLobbyEscapeHandler


    -- Small buttons are 100 wide, 44 tall

    -- Default option button
    GUI.defaultOptions = UIUtil.CreateButtonStd(GUI.observerPanel, '/BUTTON/defaultoption/')
    -- If we're the host, position the buttons lower down (and eventually shrink the observer panel)
    if not isHost then
        GUI.defaultOptions:Hide()
    end
    LayoutHelpers.AtLeftTopIn(GUI.defaultOptions, GUI.observerPanel, 11, -94)

    Tooltip.AddButtonTooltip(GUI.defaultOptions, 'lob_click_rankedoptions')
    if not isHost then
        GUI.defaultOptions:Disable()
    else
        GUI.defaultOptions.OnClick = function()
            UIUtil.QuickDialog(GUI, LOC('<LOC options_0002>Are you sure you want to reset to default values?'),
                "<LOC _Yes>", function()
                    -- Return all options to their default values.
                    OptionUtils.SetDefaults()
                    lobbyComm:BroadcastData({ Type = "SetAllPlayerNotReady" })
                    UpdateGame()
                end,

                "<LOC _Cancel>", nil,
                nil, nil,
                true
            )
        end
    end

    -- RANDOM MAP BUTTON --
    GUI.randMap = UIUtil.CreateButtonStd(GUI.observerPanel, '/BUTTON/randommap/')
    LayoutHelpers.RightOf(GUI.randMap, GUI.defaultOptions, -19)
    Tooltip.AddButtonTooltip(GUI.randMap, 'lob_click_randmap')
    if not isHost then
        GUI.randMap:Hide()
    else
        GUI.randMap.OnClick = function()
            local randomMap
            local mapSelectDialog

            autoRandMap = false

            -- Load the set of all available maps, with a slight evil hack on the mapselect module.
            local mapDialog = import("/lua/ui/dialogs/mapselect.lua")
            local allMaps = mapDialog.LoadScenarios()  -- Result will be cached.

            -- Only include maps which have enough slots for the players we have.
            local filteredMaps = table.filter(allMaps,
                function(scenInfo)
                    local supportedPlayers = table.getsize(scenInfo.Configurations.standard.teams[1].armies)
                    return supportedPlayers >= GetPlayerCount()
                end
            )
            local mapCount = table.getn(filteredMaps)
            local selectedMap = filteredMaps[math.floor(math.random(1, mapCount))]

            -- Set the new map.
            SetGameOption('ScenarioFile', selectedMap.file)
            ClearBadMapFlags()
            UpdateGame()
        end
    end

    local autoteamButtonStates = {
        {
            key = 'tvsb',
            tooltip = 'lob_auto_tvsb'
        },
        {
            key = 'lvsr',
            tooltip = 'lob_auto_lvsr'
        },
        {
            key = 'pvsi',
            tooltip = 'lob_auto_pvsi'
        },
        {
            key = 'manual',
            tooltip = 'lob_auto_manual'
        },
        {
            key = 'none',
            tooltip = 'lob_auto_none'
        },
    }

    local initialState = Prefs.GetFromCurrentProfile("LobbyOpt_AutoTeams") or "none"
    GUI.autoTeams = ToggleButton(GUI.observerPanel, '/BUTTON/autoteam/', autoteamButtonStates, initialState)

    LayoutHelpers.RightOf(GUI.autoTeams, GUI.randMap, -19)
    if not isHost then
        GUI.autoTeams:Hide()
    else
        GUI.autoTeams.OnStateChanged = function(self, newState)
            SetGameOption('AutoTeams', newState)
            Autobalance.AssignAutoTeams()
        end
    end

    -- CLOSE/OPEN EMPTY SLOTS BUTTON --
    GUI.closeEmptySlots = UIUtil.CreateButtonStd(GUI.observerPanel, '/BUTTON/closeslots/')
    Tooltip.AddButtonTooltip(GUI.closeEmptySlots, 'lob_close_empty_slots')
    if not isHost then
        GUI.closeEmptySlots:Hide()
        LayoutHelpers.AtLeftTopIn(GUI.closeEmptySlots, GUI.defaultOptions, -40, 43)
    else
        LayoutHelpers.AtLeftTopIn(GUI.closeEmptySlots, GUI.defaultOptions, -31, 43)
        GUI.closeEmptySlots.OnClick = function(self, modifiers)
            if lobbyComm:IsHost() then
                if modifiers.Ctrl then
                    for slot = 1,numOpenSlots do
                        HostUtils.SetSlotClosed(slot, false)
                    end
                    return
                end
                local openSpot = false
                for slot = 1,numOpenSlots do
                    openSpot = openSpot or not (gameInfo.PlayerOptions[slot] or gameInfo.ClosedSlots[slot])
                end
                if modifiers.Right and gameInfo.AdaptiveMap then
                    for slot = 1,numOpenSlots do
                        if openSpot then
                            if not (gameInfo.PlayerOptions[slot] or gameInfo.ClosedSlots[slot]) then
                                HostUtils.SetSlotClosedSpawnMex(slot)
                            end
                        else
                            if gameInfo.ClosedSlots[slot] and gameInfo.SpawnMex[slot] then
                                HostUtils.SetSlotClosed(slot, false)
                            end
                        end
                    end
                else
                    for slot = 1,numOpenSlots do
                        if not gameInfo.SpawnMex[slot] then
                            HostUtils.SetSlotClosed(slot, openSpot)
                        end
                    end
                end
            end
        end
    end


    -- GO OBSERVER BUTTON --
    GUI.becomeObserver = UIUtil.CreateButtonStd(GUI.observerPanel, '/BUTTON/observer/')
    LayoutHelpers.RightOf(GUI.becomeObserver, GUI.closeEmptySlots, -25)
    Tooltip.AddButtonTooltip(GUI.becomeObserver, 'lob_become_observer')
    GUI.becomeObserver.OnClick = function()
        if IsPlayer(localPlayerID) then
            if isHost then
                HostUtils.ConvertPlayerToObserver(FindSlotForID(localPlayerID))
            else
                lobbyComm:SendData(hostID, {Type = 'RequestConvertToObserver'})
            end
        elseif IsObserver(localPlayerID) then
            if isHost then
                HostUtils.ConvertObserverToPlayer(FindObserverSlotForID(localPlayerID))
            else
                lobbyComm:SendData(hostID, {Type = 'RequestConvertToPlayer'})
            end
        end
    end

    -- CPU BENCH BUTTON --
    GUI.rerunBenchmark = UIUtil.CreateButtonStd(GUI.observerPanel, '/BUTTON/cputest/', '', 11)
    LayoutHelpers.RightOf(GUI.rerunBenchmark, GUI.becomeObserver, -25)
    Tooltip.AddButtonTooltip(GUI.rerunBenchmark,{text=LOC("<LOC lobui_0425>Run CPU Benchmark Test"), body=LOC("<LOC lobui_0426>Recalculates your CPU rating.")})
    GUI.rerunBenchmark.OnClick = function(self, modifiers)
        ForkThread(function() CPUBenchmark.UpdateBenchmark(true) end)
    end

    -- Autobalance Button --
    GUI.PenguinAutoBalance = UIUtil.CreateButtonStd(GUI.observerPanel, '/BUTTON/autobalance/')
    LayoutHelpers.RightOf(GUI.PenguinAutoBalance, GUI.rerunBenchmark, -25)
    Tooltip.AddButtonTooltip(GUI.PenguinAutoBalance, {text=LOC("<LOC lobui_0444>Autobalance"), body=LOC("<LOC lobui_0445>Automatically balance players into 2 equally sized teams")})
    if not isHost then
        GUI.PenguinAutoBalance:Hide()
    else
        -- What this does: it balances all occupied slots into two teams with equal numbers of
        -- players.  If teams are set manually and half of the occupied slots are set to team 1
        -- and half to team 2, then it balances the players while keeping the team-slot matches.
        -- If the teams are set manually, but there is an uneven number of players on teams 1
        -- and 2, then players' teams are changed automatically to be alternating team 1 and team 2.
        -- If there are an odd number of occupied slots, the last one is set to team - (no team)
        -- and the others are balanced without it.  Alternatively, if teams are not set manually,
        -- players will be balanced into the slowest available slot numbers on their teams.
        -- If there is an odd number of players in that case, the last player will be made an
        -- observer if human or removed if AI.

        -- How it balances: this function checks every possible balance combination for making 
        -- the two teams (while keeping their player counts equal to half the number of occupied
        -- slots, rounded down, and not using the last player if there is an odd number of players).
        -- To do this, the function sums up all the relevant players' ratings (keeping mean and
        -- deviation separate - it balances teams to have similar total ratings, and also similar
        -- total uncertainties (grayness)), and then divides by two. That yields the goal values
        -- for each team. Any deviation from those values is calculated to help determine a team's
        -- imbalance value. Then, the various team combinations are tested, and the one with the
        -- lowest imbalance value is used.


        -- Automatically balance an even number of non-observer players into 2 teams in the lobby
        GUI.PenguinAutoBalance.OnClick = function()

            -- make sure spawns are set to fixed or penguin_autobalance
            if gameInfo.GameOptions.TeamSpawn ~= 'fixed' and gameInfo.GameOptions.TeamSpawn ~= 'penguin_autobalance' then
                gameInfo.GameOptions.TeamSpawn = 'fixed'
                -- tell everyone else to set spawns to fixed
                lobbyComm:BroadcastData {
                    Type = 'GameOptions',
                    Options = {['TeamSpawn'] = 'fixed'}
                }
                AddChatText(LOC("<LOC lobui_0446>Enabled fixed spawn locations"))
            end

            -- a table of the target mean, target deviation, and the lowest logged imbalance value
            local goalValue = {0, 0, 99999}

            local playerCount = 0
            -- a table of the highest occupied slot's slot number, that slot's player's order number
            -- in the playerRatings table, and a booleon of whether or not that player is human
            local lastSlot = {0, 0, false}
            local playerRatings = {}
            -- get rating data for each player
            for i, player in gameInfo.PlayerOptions:pairs() do
                playerRatings[i] = {player.MEAN, player.DEV, player.StartSpot, player.Team - 1}
                playerCount = playerCount + 1
                if player.StartSpot > lastSlot[1] then
                    lastSlot = {player.StartSpot, i, player.Human}
                end
                goalValue[1] = goalValue[1] + player.MEAN
                goalValue[2] = goalValue[2] + player.DEV
            end

            -- if there are fewer than 2 players, there is no need to balance
            if playerCount < 2 then
                UpdateGame()
                return
            end

            -- if there is an odd number of players, remove the last one from the balancing
            if math.mod(playerCount, 2) == 1 then
                goalValue[1] = goalValue[1] - playerRatings[lastSlot[2]][1]
                goalValue[2] = goalValue[2] - playerRatings[lastSlot[2]][2]
                playerRatings[lastSlot[2]] = nil
                playerCount = playerCount - 1
                -- set the player to not be on a team if teams are manual and fixed
                -- otherwise make the player an observer if human or remove it if AI
                if gameInfo.GameOptions.AutoTeams == 'none' and gameInfo.GameOptions.TeamSpawn == 'fixed' then
                    for i, player in gameInfo.PlayerOptions:pairs() do
                        if player.StartSpot == lastSlot[1] then
                            player.Team = 1 -- no team
                            break
                        end
                    end
                else
                    if lastSlot[3] then
                        HostUtils.ConvertPlayerToObserver(lastSlot[1])
                    else
                        HostUtils.RemoveAI(lastSlot[1])
                    end
                end
            end

            -- the goal value is all of the remaining players' ratings divided by 2
            goalValue[1] = goalValue[1] / 2
            goalValue[2] = goalValue[2] / 2

            local sortedPlayerRatings = {}
            local sortedSlotTeams = {}
            local numPlayersTeam1 = 0
            local numPlayersTeam2 = 0
            local sortingValue1
            local sortingValue2
            -- sort the players in a weighted cross between displayed and base rating
            -- the order goes from greatest to lowest result of: mean - (deviation * 2.2)
            for i, player in playerRatings do
                local orderNum = 1
                sortingValue1 = player[1] - (player[2] * 2.2)
                for i2, player2 in playerRatings do
                    sortingValue2 = player2[1] - (player2[2] * 2.2)
                    if sortingValue1 < sortingValue2 or (sortingValue1 == sortingValue2 and i > i2) then
                        orderNum = orderNum + 1
                    end
                end
                -- these are sorted in parallel
                sortedPlayerRatings[orderNum] = {player[1], player[2]}
                sortedSlotTeams[orderNum] = {player[3], player[4]}
                if player[4] == 1 then
                    numPlayersTeam1 = numPlayersTeam1 + 1
                elseif player[4] == 2 then
                    numPlayersTeam2 = numPlayersTeam2 + 1
                end
            end


            -- the number of players per team
            local teamSize = playerCount / 2


            -- make the sorted list of slots for each team
            local sortedTeam1Slots = {}
            local sortedTeam2Slots = {}
            local team1OrderNum = 0
            local team2OrderNum = 0

            local manualTeams
                
            if gameInfo.GameOptions.AutoTeams == 'pvsi' then -- odd vs even
                for i = 1, 16 do
                    if not gameInfo.ClosedSlots[i] then
                        if math.mod(i, 2) == 1  then
                            team1OrderNum = team1OrderNum + 1
                            sortedTeam1Slots[team1OrderNum] = i
                        else
                            team2OrderNum = team2OrderNum + 1
                            sortedTeam2Slots[team2OrderNum] = i
                        end
                    end
                end
            elseif gameInfo.GameOptions.AutoTeams == 'tvsb' then -- top vs bottom
                local midLine = GUI.mapView.Top() + (GUI.mapView.Height() / 2)
                for i, startPosition in GUI.mapView.startPositions do
                    if not gameInfo.ClosedSlots[i] then
                        if startPosition.Top() < midLine then
                            team1OrderNum = team1OrderNum + 1
                            sortedTeam1Slots[team1OrderNum] = i
                        else
                            team2OrderNum = team2OrderNum + 1
                            sortedTeam2Slots[team2OrderNum] = i
                        end
                    end
                end
            elseif gameInfo.GameOptions.AutoTeams == 'lvsr' then -- left vs right
                local midLine = GUI.mapView.Left() + (GUI.mapView.Width() / 2)
                for i, startPosition in GUI.mapView.startPositions do
                    if not gameInfo.ClosedSlots[i] then
                        if startPosition.Left() < midLine then
                            team1OrderNum = team1OrderNum + 1
                            sortedTeam1Slots[team1OrderNum] = i
                        else
                            team2OrderNum = team2OrderNum + 1
                            sortedTeam2Slots[team2OrderNum] = i
                        end
                    end
                end
            else
                manualTeams = true
            end

            -- If the teams were not set properly, set them properly.
            -- When teams are set manually, they are not set properly if the number of 
            -- players on either team does not equal the team size.  
            -- When teams are not set manually, they are not set properly if the number
            -- of slots on either team is less than the team size.
            if (manualTeams and (numPlayersTeam1 != teamSize or numPlayersTeam2 != teamSize))
             or (not manualTeams and (table.getn(sortedTeam1Slots) < teamSize or table.getn(sortedTeam2Slots) < teamSize)) then
                -- set AutoTeams to none (so, they can be set by slot by this function)
                gameInfo.GameOptions.AutoTeams = 'none'
                local counter = 0
                for i, player in gameInfo.PlayerOptions:pairs() do
                    for i2, slotTeam in sortedSlotTeams do
                        if player.StartSpot == slotTeam[1] then
                            counter = counter + 1
                            -- set the player's team
                            if math.mod(counter, 2) == 1  then
                                player.Team = 2 -- team 1
                                slotTeam[2] = 1
                            else
                                player.Team = 3 -- team 2
                                slotTeam[2] = 2
                            end
                            -- tell everyone else the team number for that slot
                            lobbyComm:BroadcastData(
                            {
                                Type = 'PlayerOptions',
                                Options = {['Team'] = slotTeam[2] + 1}, -- make team number 1 higher for the backend
                                Slot = slotTeam[1],
                            })
                            break
                        end
                    end
                end
            end

            -- if teams are set to manual, make the sorted list of slots for each team
            if gameInfo.GameOptions.AutoTeams == 'none' then
                sortedTeam1Slots = {}
                sortedTeam2Slots = {}
                for i, slotTeam in sortedSlotTeams do 
                    team1OrderNum = 0
                    team2OrderNum = 0
                    for i2, slotTeam2 in sortedSlotTeams do
                        if slotTeam[1] > slotTeam2[1] or (slotTeam[1] == slotTeam2[1] and i >= i2) then
                            if slotTeam2[2] == 1 then
                                team1OrderNum = team1OrderNum + 1
                            else
                                team2OrderNum = team2OrderNum + 1
                            end
                        end
                    end
                    -- add the slot to its team's table
                    if slotTeam[2] == 1 then
                        sortedTeam1Slots[team1OrderNum] = slotTeam[1]
                    else
                        sortedTeam2Slots[team2OrderNum] = slotTeam[1]
                    end
                end
            end



            -- a table of team1's mean, deviation, and imbalance value
            local teamValue
            -- a table of team members
            local team1 = {}
            -- a table of the most balanced team
            local bestTeam = {}
            local choosableCount = playerCount - teamSize

            -- the number of iterations is the number of team combinations to check, which is
            -- exactly half of the number of possible teams, which covers every possibility,
            -- since the remaining half are just the opposite of what was already checked,
            -- which means they have the exact same balance
            -- ie: Player A + Player B vs Player C + Player D == Player C + Player D vs Player A + Player B
            -- this works because of the order in which the combinations are tested
            local numIterations
            if teamSize == 2 then
                numIterations = 3
            elseif teamSize == 3 then
                numIterations = 10
            elseif teamSize == 4 then
                numIterations = 35
            elseif teamSize == 5 then
                numIterations = 126
            elseif teamSize == 6 then
                numIterations = 462
            elseif teamSize == 7 then
                numIterations = 1716
            else
                numIterations = 6435
            end

            local currentIteration = 0

            -- test the balance of different combinations of teams, covering balance possibility
            -- intended for use with 2 teams of even player counts
            -- combinations are iterated starting with the lowest-numbered players on team1 first,
            -- and progressively iterating the highest-numbered player on team1 to each higher-numbered
            -- possible player, and then repeating the process with the next highest-numbered player
            -- increasing by 1... this process continues until every possible balacnce combination
            -- of 2 equally sized teams of even player counts has been covered
            local function testCombinations(team1MemberNumber, firstPlayerToCheck)
                -- check if this player is the last player on the team
                local lastPlayer
                if team1MemberNumber < teamSize then
                    lastPlayer = false
                else
                    lastPlayer = true
                end
                -- iterate through the possible players for this team1MemberNumber
                for i = firstPlayerToCheck, choosableCount + team1MemberNumber do
                    -- when the number of iterations is reached, every possible balance of even player count
                    --  of the 2 equally sized teams has been checked, and the function ends
                    if currentIteration >= numIterations then
                        return
                    end
                    team1[team1MemberNumber] = i
                    if lastPlayer then
                        -- test this combination of team members
                        teamValue = {0, 0, 0}
                        -- add each team member's base rating and devation to the team's values
                        for i, player in team1 do
                            teamValue[1] = teamValue[1] + sortedPlayerRatings[player][1]
                            teamValue[2] = teamValue[2] + sortedPlayerRatings[player][2]
                        end
                        -- calculate the team's imbalance value
                        teamValue[3] = math.abs(teamValue[2] - goalValue[2]) * 1.2 + math.abs(teamValue[1] - goalValue[1])
                        -- check if the team's imbalance value is lower than the lowest logged imbalance value
                        if teamValue[3] < goalValue[3] then
                            -- if it is lower, then this is the best balance so far, and it is logged over the previous best balance
                            goalValue[3] = teamValue[3]
                            -- deepcopy the team's player numbers
                            for i, player in team1 do
                                bestTeam[i] = player
                            end
                        end
                        currentIteration = currentIteration + 1
                    else
                        -- test a subset of combinations
                        testCombinations(team1MemberNumber + 1, i + 1)
                    end
                end
            end

            testCombinations(1, 1)


            -- specify the players on team 2 (aka, the ones not on team 1)
            local bestTeam2 = {}
            for i = 1, playerCount do
                if not table.find(bestTeam, i) then
                    table.insert(bestTeam2, i)
                end
            end

            --shuffle player pairs
            local random
            local temp
            for i, slot in bestTeam do
                random = Random(1, teamSize)

                --random swap on team 1
                temp = bestTeam[random]
                bestTeam[random] = bestTeam[i]
                bestTeam[i] = temp

                --mirrored swap on team2
                temp = bestTeam2[random]
                bestTeam2[random] = bestTeam2[i]
                bestTeam2[i] = temp
            end

            -- move players on team1 to the intended slots
            local team1OrderNum = 0
            local slotA
            local slotB
            for i, player in bestTeam do
                team1OrderNum = team1OrderNum + 1
                slotA = sortedSlotTeams[player][1]
                slotB = sortedTeam1Slots[team1OrderNum]
                HostUtils.SwapPlayers(slotA, slotB)
                -- keep track of the slot changes in sortedSlotTeams
                for i, slotTeam in sortedSlotTeams do
                    if slotTeam[1] == slotB then
                        slotTeam[1] = slotA
                        break
                    end
                end
                sortedSlotTeams[player][1] = slotB
            end

            -- move players on team2 to the intended slots
            local team2OrderNum = 0
            for i, player in bestTeam2 do
                team2OrderNum = team2OrderNum + 1
                slotA = sortedSlotTeams[player][1]
                slotB = sortedTeam2Slots[team2OrderNum]
                HostUtils.SwapPlayers(slotA, slotB)
                -- keep track of the slot changes in sortedSlotTeams
                for i, slotTeam in sortedSlotTeams do
                    if slotTeam[1] == slotB then
                        slotTeam[1] = slotA
                        break
                    end
                end
                sortedSlotTeams[player][1] = slotB
            end
            UpdateGame()
            AddChatText(LOC("<LOC lobui_0626>Finished autobalancing"))
        end
    end

    -- Observer List
    GUI.observerList = ItemList(GUI.observerPanel)
    GUI.observerList:SetFont(UIUtil.bodyFont, 12)
    GUI.observerList:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontOverColor, UIUtil.highlightColor, "ffbcfffe")
    LayoutHelpers.AtLeftTopIn(GUI.observerList, GUI.observerPanel, 4, 2)
    LayoutHelpers.AtRightBottomIn(GUI.observerList, GUI.observerPanel, 15)
    GUI.observerList.OnClick = function(self, row, event)
        if isHost and event.Modifiers.Right then
            -- determine the number of teams (excluding the no team (-) option that equals 1 on the backend)
            local teams = {}
            local numTeams = 0
            for i, player in gameInfo.PlayerOptions:pairs() do
                if not teams[player.Team] and player.Team ~= 1 then
                    teams[player.Team] = true
                    numTeams = numTeams + 1
                end
            end

            -- adjust index by 1 because 0-based (ItemList rows) vs 1-based (Lua array) indexing
            local obsIndex = row + 1
            local maxObsIndex = self:GetItemCount()

            -- adjust index by the number of rows taken up by team ratings. 
            ---@see refreshObserverList
            if gameInfo.GameOptions['TeamSpawn'] == 'fixed' then
                if numTeams < 3 then
                    obsIndex = obsIndex - numTeams
                else
                    -- 3+ teams has ratings at the end of the list, don't allow kicking when clicking those rating rows
                    maxObsIndex = maxObsIndex - numTeams
                end
            end
            
            -- the host can get the kick dialog brought up for observer list rows that are players (aka, they have
            -- a positive observer index and thereby aren't team ratings) and that aren't the local player (the host)
            -- and that aren't the rows with team ratings when there are 3 or more teams
            if obsIndex > 0 and gameInfo.Observers[obsIndex].OwnerID ~= localPlayerID and obsIndex <= maxObsIndex then
                UIUtil.QuickDialog(GUI, "<LOC lobui_0166>Are you sure?",
                                        "<LOC lobui_0167>Kick Player", function()
                                            SendSystemMessage("lobui_0756", gameInfo.Observers[obsIndex].PlayerName)
                                            lobbyComm:EjectPeer(gameInfo.Observers[obsIndex].OwnerID, "KickedByHost")
                                        end,
                                        "<LOC _Cancel>", nil,
                                        nil, nil,
                                        true,
                                        {worldCover = false, enterButton = 1, escapeButton = 2}
                )
            end
        end
    end
    UIUtil.CreateLobbyVertScrollbar(GUI.observerList, 0, 0, -1)

    -- Setup large pretty faction selector and set the factional background to its initial value.
    local lastFaction = GetSanitisedLastFaction()
    CreateUI_Faction_Selector(lastFaction)

    RefreshLobbyBackground(lastFaction)

    GUI.uiCreated = true

    if singlePlayer then
        -- observers are always allowed in skirmish games.
        SetGameOption("AllowObservers", true)
    end

    ---------------------------------------------------------------------------
    -- other logic, including lobby callbacks
    ---------------------------------------------------------------------------
    GUI.posGroup = false
    -- get ping times
    GUI.pingThread = ForkThread(
    function()
        while lobbyComm do
            for slot, player in gameInfo.PlayerOptions:pairs() do
                if player.Human and player.OwnerID ~= localPlayerID then
                    local peer = lobbyComm:GetPeer(player.OwnerID)
                    local ping = peer.ping
                    local connectionStatus = CalcConnectionStatus(peer)
                    GUI.slots[slot].pingStatus.ConnectionStatus = connectionStatus
                    if ping then
                        ping = math.floor(ping)
                        GUI.slots[slot].pingStatus.PingActualValue = ping
                        GUI.slots[slot].pingStatus:SetValue(ping)
                        if ping > 500 then
                            GUI.slots[slot].pingStatus:Show()
                        else
                            GUI.slots[slot].pingStatus:Hide()
                        end
                        -- Set the ping bar to a colour representing the status of our connection.
                        GUI.slots[slot].pingStatus._bar:SetTexture(UIUtil.SkinnableFile('/game/unit_bmp/bar-0' .. connectionStatus .. '_bmp.dds'))
                    else
                        GUI.slots[slot].pingStatus:Hide()
                    end
                end
            end
            WaitSeconds(1)
        end
    end)
    if false then
        import("/lua/ui/events/snowflake.lua"). CreateSnowFlakes(GUI)
    end
end



function CreateUI_Faction_Selector(lastFaction)
    -- Build a list of button objects from the list of defined factions. Each faction will use the
    -- faction key as its RadioButton texture path offset.
    local buttons = {}
    for i, faction in FactionData.Factions do
        buttons[i] = {
            texturePath = faction.Key
        }
    end

    -- Special-snowflaking for the random faction.
    table.insert(buttons, {
        texturePath = "random"
    })

    local factionSelector = RadioButton(GUI.panel, "/factionselector/", buttons, lastFaction, true)
    GUI.factionSelector = factionSelector
    LayoutHelpers.AtLeftTopIn(factionSelector, GUI.panel, 407, 20)
    factionSelector.OnChoose = function(self, targetFaction, key)
        local localSlot = FindSlotForID(localPlayerID)
        local slotFactionIndex = GetSlotFactionIndex(targetFaction)
        Prefs.SetToCurrentProfile('LastFaction', targetFaction)
        GUI.slots[localSlot].faction:SetItem(slotFactionIndex)
        SetPlayerOption(localSlot, 'Faction', slotFactionIndex)
        gameInfo.PlayerOptions[localSlot].Faction = slotFactionIndex

        RefreshLobbyBackground(targetFaction)
        UIUtil.SetCurrentSkin(FACTION_NAMES[targetFaction])
    end

    -- Only enable all buttons incase all the buttons are disabled, to avoid overriding partially disabling of the buttons
    factionSelector.Enable = function(self)
        for k, v in self.mButtons do
            if v._controlState == "up" then
                return
            end
        end
        for k, v in self.mButtons do
            v:Enable()
        end
    end

    factionSelector.SetCheck = function(self, index)
        for i,button in self.mButtons do
            if index ==i then
                button:SetCheck(true)
            else
                button:SetCheck(false)
            end
        end
        self.mCurSelection = index
    end

    factionSelector.EnableSpecificButtons = function(self, specificButtons)
        for i,button in self.mButtons do
            if specificButtons[i] then
                button:Enable()
            else
                button:Disable()
            end
        end
    end
end

