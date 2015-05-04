--*****************************************************************************
--* File: lua/LobbyManager_Options.lua
--* Author: Chris Blackwell (Modified by Duck42 for use as a UI mod options panel)
--*
--* Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local LobbyManager = import('/lua/ui/lobby/lobbymanager/LobbyManager.lua')
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup

local checkBoxes = {}
local dialog = false
local dialog2 = false
local dialogContent = false

local options = {
    AUTOKICKBAN = {
        name = "Automatically kick banned players",
        tooltip = "If this option is checked, banned players will automatically be kicked from games you host.",
    },
    PROMPTKICKBAN = {
        name = "Prompt before kicking banned players",
        tooltip = "If this option is checked, you will be prompted before a banned players is automatically kicked from a game you are hosting.",
    },
    LOCKBANNEDOBSERVER = {
        name = "Keep banned players in observer mode",
        tooltip = "If this option is checked, banned players will be locked in observer mode and will not be able to occupy a game slot.",        
    },
    SHOWREASONS = {
        name = "Show reasons in the chat window",
        tooltip = "If this option is checked, ban and probation reasons are displayed in the chat window.  Ban reasons will be visible to everyone.  Probation reasons will only be visible to you and the offender.",
    },
    SHOWNOTES = {
        name = "Show notes in the chat window",
        tooltip = "If this option is checked, ban and probation notes are displayed in the chat window.  Notes are only visible to you.",
    },
}

sortOrder = {
    "AUTOKICKBAN",
    "PROMPTKICKBAN",
    "LOCKBANNEDOBSERVER",
    "SHOWREASONS",
    "SHOWNOTES",
}

function CreateDialog2(parent)
    dialogContent = Group(parent)
    dialogContent.Width:Set(536)
    dialogContent.Height:Set(400)

    local dialog = Popup(parent, dialogContent)
	
	local currConfig = LobbyManager.LoadConfig()
	
	-- Checkbox Code
	local position = 20
	for index, key in sortOrder do
		if options[key] then
			local cbox = UIUtil.CreateCheckbox(dialogContent, '/CHECKBOX/', options[key].name, true, 11)
			cbox:SetCheck(GetConfigValue(currConfig, key), true)
			cbox.KeyId = key
			LayoutHelpers.AtLeftIn(cbox, dialogContent, 20)
			LayoutHelpers.AtTopIn(cbox, dialogContent, position)
			Tooltip.AddCheckboxTooltip(cbox, {text=options[key].name, body=options[key].tooltip})
			cbox.OnCheck = function(self, checked)
				if checked then
					SetConfig(self.KeyId, true)
				else
					SetConfig(self.KeyId, false)
					--cbox:SetCheck(true, true)
				end
			end
			checkBoxes[key] = cbox
		end
		position = position + 20
	end
	
	--Credit Text
	local credit_text = {'Lobby Manager',
						'-------------------------------------------------------------------',
						'- Created by Duck_42'}
	for i, v in credit_text do
		local textVar = UIUtil.CreateText(dialogContent, v, 10, 'Arial')
		textVar:SetColor('B9BFB9')
		textVar:SetDropShadow(true)
		LayoutHelpers.AtLeftIn(textVar, dialogContent, 20)
		LayoutHelpers.AtBottomIn(textVar, dialogContent, 120-(15*i))
	end
	
	--List Button	
	local ShowListButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Player List")
		LayoutHelpers.AtRightIn(ShowListButton, dialogContent, 20)
		LayoutHelpers.AtTopIn(ShowListButton, dialogContent, 20)
		ShowListButton.OnClick = function(self)
			ShowPlayerListDialog()
		end
    if table.getn(currConfig.BannedPlayers) + table.getn(currConfig.ProbationaryPlayers) == 0 then
        ShowListButton:Disable()
    end
	
	--Exit Button
	local QuitButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Done")
		LayoutHelpers.AtHorizontalCenterIn(QuitButton, dialogContent, 0)
		LayoutHelpers.AtBottomIn(QuitButton, dialogContent, 10)
		QuitButton.OnClick = function(self)
			dialog:Destroy()			
		end
end

function ShowPlayerListDialog()
		import('/lua/ui/lobby/lobbymanager/LobbyManager_PlayerList.lua').CreateDialog2(dialogContent)
end

function GetConfigValue(currConfig, key)
	local value = false
	if key == 'PROMPTKICKBAN' then
		value = currConfig.PromptBeforeKickBanned
	elseif key == 'SHOWREASONS' then
		value = currConfig.ShowReasons
	elseif key == 'SHOWNOTES' then
		value = currConfig.ShowNotes
	elseif key == 'LOCKBANNEDOBSERVER' then
		value = currConfig.LockBannedInObserver
	elseif key == 'AUTOKICKBAN' then
		value = currConfig.AutoKickBannedPlayers
	end
	return value
end

function SetConfig(key, value)
	local currConfig = LobbyManager.LoadConfig()
	
	if key == 'PROMPTKICKBAN' then
		currConfig.PromptBeforeKickBanned = value
	elseif key == 'SHOWREASONS' then
		currConfig.ShowReasons = value
	elseif key == 'SHOWNOTES' then
		currConfig.ShowNotes = value
	elseif key == 'LOCKBANNEDOBSERVER' then
		currConfig.LockBannedInObserver = value
	elseif key == 'AUTOKICKBAN' then
		currConfig.AutoKickBannedPlayers = value
	end
	
	LobbyManager.SaveConfig(currConfig)
end