--*****************************************************************************
--* File: lua/modules/ui/lobby/gamecreate.lua
--* Author: Chris Blackwell
--* Summary: game creation UI
--*
--* Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Edit = import("/lua/maui/edit.lua").Edit
local Prefs = import("/lua/user/prefs.lua")

local unselectedCheckboxFile = UIUtil.SkinnableFile('/widgets/rad_un.dds')
local selectedCheckboxFile = UIUtil.SkinnableFile('/widgets/rad_sel.dds')

local errorDialog = false
local defaultPort = 16010   -- this is the default port

function CreateEditField(parent)
    local control = Edit(parent)
    control:SetForegroundColor(UIUtil.fontColor)
    control:SetHighlightForegroundColor(UIUtil.highlightColor)
    control:SetHighlightBackgroundColor("880085EF")
    control.Height:Set(function() return control:GetFontHeight() end)
    LayoutHelpers.SetWidth(control, 250)
    control:SetFont(UIUtil.bodyFont, 16)
    return control
end

function CreateUI(playerName, over, exitBehavior)
    playerName = playerName or Prefs.GetFromCurrentProfile('NetName') or Prefs.GetFromCurrentProfile('Name')

    -- control layout
	local parent = over

    local panel = Bitmap(parent, UIUtil.SkinnableFile('/scx_menu/gamecreate/panel-brackets_bmp.dds'))
    LayoutHelpers.AtCenterIn(panel, parent)

	local exitButton = UIUtil.CreateButtonStd(panel, '/scx_menu/small-btn/small', "<LOC _Cancel>", 16, 2, 0, "UI_Back_MouseDown")
	LayoutHelpers.AtRightIn(exitButton, panel, 38)
	LayoutHelpers.AtBottomIn(exitButton, panel, 34)

    import("/lua/ui/uimain.lua").SetEscapeHandler(function() exitButton.OnClick(exitButton) end)

    local panelTitle = UIUtil.CreateText(panel, "<LOC _Create_LAN_Game>", 22)
    LayoutHelpers.AtHorizontalCenterIn(panelTitle, panel)
    LayoutHelpers.AtTopIn(panelTitle, panel, 50)

    local gameNameEdit = CreateEditField(panel)
    gameNameEdit:SetText(Prefs.GetFromCurrentProfile('last_game_name') or "")
    LayoutHelpers.SetWidth(gameNameEdit, 340)
    LayoutHelpers.AtHorizontalCenterIn(gameNameEdit, panel)
    LayoutHelpers.AtTopIn(gameNameEdit, panel, 120)
    gameNameEdit:SetMaxChars(32)
    gameNameEdit:ShowBackground(false)

    local gameNameLabel = UIUtil.CreateText(panel, "<LOC _Game_Name>", 14, UIUtil.bodyFont)
    LayoutHelpers.Above(gameNameLabel, gameNameEdit, 5)

    local portEdit = CreateEditField(panel)
    portEdit.Width:Set(gameNameEdit.Width)
    LayoutHelpers.AtHorizontalCenterIn(portEdit, panel)
    LayoutHelpers.Below(portEdit, gameNameEdit, 36)
    portEdit:ShowBackground(false)

    local portLabel = UIUtil.CreateText(panel, "<LOC _Port>", 14, UIUtil.bodyFont)
    LayoutHelpers.Above(portLabel, portEdit, 5)

    local autoPort = UIUtil.CreateCheckboxStd(panel, '/dialogs/check-box_btn/radio')
    autoPort.Right:Set(portEdit.Right)
    LayoutHelpers.AnchorToTop(autoPort, portEdit, 5)
    autoPort.OnCheck = function(self, checked)
        if checked then
            portEdit:Disable()
            portEdit:SetText(LOC("<LOC GAMECREATE_0002>Auto"))
        else
            portEdit:Enable()
            portEdit:SetText(Prefs.GetFromCurrentProfile('LastPort') or defaultPort)
        end
    end
    autoPort:SetCheck(true)

    local autoPortLabel = UIUtil.CreateText(panel, "<LOC GAMECREATE_0003>Auto Port", 14, UIUtil.bodyFont)
    autoPortLabel.Right:Set(autoPort.Left)
    autoPortLabel.Bottom:Set(autoPort.Bottom)

    -- ascii values of 0-9
    local portValidSet = {
        [48] = true,
        [49] = true,
        [50] = true,
        [51] = true,
        [52] = true,
        [53] = true,
        [54] = true,
        [55] = true,
        [56] = true,
        [57] = true,
        [46] = true,
    }

    portEdit.OnCharPressed = function(self, charcode)
        if portValidSet[charcode] then
            return false
        else
            local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
            PlaySound(sound)
            return true
        end
    end

    portEdit.OnEnterPressed = function(self, text)
        portEdit:AbandonFocus()
        return true
    end

    local continueButton = UIUtil.CreateButtonStd(panel, '/scx_menu/small-btn/small', "<LOC _OK>", 16, 2)
	LayoutHelpers.AtLeftIn(continueButton, panel, 38)
	LayoutHelpers.AtBottomIn(continueButton, panel, 34)

    --  control behvaior
    exitButton.OnClick = function(self)
   		panel:Destroy()
    	import("/lua/ui/lobby/gameselect.lua").CreateUI(over, exitBehavior)
    end

    gameNameEdit.OnEnterPressed = function(self, text)
        continueButton:OnClick()
        return true
    end

    continueButton.OnClick = function(self)
        local gameName = gameNameEdit:GetText()
        if (not gameName) or (gameName == "") then
            if errorDialog then errorDialog:Destroy() end
            errorDialog = UIUtil.ShowInfoDialog(parent, "<LOC GAMECREATE_0000>Please choose a valid game name", "<LOC _OK>")
            return
        end

        -- check game name for all spaces
        local gnBegin, gnEnd = string.find(gameName, "%s+")
        if gnBegin and (gnBegin == 1 and gnEnd == string.len(gameName)) then
            if errorDialog then errorDialog:Destroy() end
            errorDialog = UIUtil.ShowInfoDialog(parent, "<LOC GAMECREATE_0004>Please choose a name that does not contain only whitespace characters", "<LOC _OK>")
            return
        end

        local port = tonumber(portEdit:GetText()) or 0  -- default of port 0 will cause engine to choose

        if not autoPort:IsChecked() then
            if not port or math.floor(port) ~= port or port < 1 or port > 65535 then
                if errorDialog then errorDialog:Destroy() end
                errorDialog = UIUtil.ShowInfoDialog(parent, LOCF('<LOC DIRCON_0003>Invalid port number: %s.  Must be an integer between 1 and 65535', portEdit:GetText()), "<LOC _OK>")
                return
            end
        end

        if port ~= 0 then
            Prefs.SetToCurrentProfile('LastPort', port)
        end

        -- modify this if you want "TCP" or "None"
        -- no longer user selectable
        local protocol = "UDP"

        local function StartLobby(scenarioFileName)
            local lobby = import("/lua/ui/lobby/lobby.lua")
            lobby.CreateLobby(protocol, port, playerName, nil, nil, over, exitBehavior)
            Prefs.SetToCurrentProfile('last_game_name', gameName)
            lobby.HostGame(gameName, scenarioFileName, false)
        end

		panel:Destroy()

        local lastScenario = Prefs.GetFromCurrentProfile('LastScenario') or UIUtil.defaultScenario
        if lastScenario then
            StartLobby(lastScenario)
        end
    end
end

function CanQuickHost()
    local lastScenario = Prefs.GetFromCurrentProfile('LastScenario')
    local lastPort = Prefs.GetFromCurrentProfile('LastPort')
    local playerName = Prefs.GetFromCurrentProfile('NetName') or Prefs.GetFromCurrentProfile('Name')
    local lastGameName = Prefs.GetFromCurrentProfile('last_game_name')

    return lastScenario ~= nil and lastPort ~= nil and playerName ~= nil and lastGameName ~= nil
end

function QuickHost()
    local lastScenario = Prefs.GetFromCurrentProfile('LastScenario')
    local lastPort = Prefs.GetFromCurrentProfile('LastPort')
    local playerName = Prefs.GetFromCurrentProfile('NetName') or Prefs.GetFromCurrentProfile('Name')
    local lastGameName = Prefs.GetFromCurrentProfile('last_game_name')

    local lobby = import("/lua/ui/lobby/lobby.lua")
    lobby.CreateLobby("UDP", lastPort, playerName, nil, nil)
    lobby.HostGame(lastGameName, lastScenario, false)
end