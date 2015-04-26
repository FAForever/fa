--*****************************************************************************
--* File: lua/LobbyManager_PlayerList.lua
--* Author: Duck42
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local LobbyManager = import('/lua/ui/lobby/lobbymanager/LobbyManager.lua')
local ReasonTable = import('/lua/ui/lobby/lobbymanager/LobbyManager.lua').reasonTable
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup

local players = {}
local config = {}
local datalist = {}

function LoadData()
	config = LobbyManager.LoadConfig()
	datalist = {}
	local tempData
	for i,v in config.BannedPlayers do
		tempData = v
		tempData.Type = 'B'
		table.insert(datalist, tempData)
	end
	for i,v in config.ProbationaryPlayers do
		tempData = v
		tempData.Type = 'P'
		table.insert(datalist, tempData)
	end
    for i,v in config.NotedPlayers do
		tempData = v
		tempData.Type = 'N'
		table.insert(datalist, tempData)
	end
end

function CreateDialog2(parent)
	players = {}
	
	--Dialog setup
	local dialogContent = Group(parent)
    dialogContent.Width:Set(600)
    dialogContent.Height:Set(600)
	dialogContent.top = 0

    local dialog = Popup(parent, dialogContent)
		
	LoadData()
	
	local title = UIUtil.CreateText(dialogContent, "Lobby Manager Player List", 14, UIUtil.titleFont)
	LayoutHelpers.AtTopIn(title, dialogContent, 5)
	LayoutHelpers.AtHorizontalCenterIn(title, dialogContent)
	
	local function CreatePlayerElements()
		local function CreateElement(index)
			players[index] = Group(dialogContent)
			players[index].Height:Set(36)
			players[index].Width:Set(dialogContent.Width() - 37)
			players[index].Depth:Set(function() return dialogContent.Depth() + 10 end)
			players[index]:DisableHitTest()

			players[index].text = UIUtil.CreateText(players[index], '', 14, "Arial")
			players[index].text:SetColor(UIUtil.fontColor)
			players[index].text:DisableHitTest()
			LayoutHelpers.AtLeftTopIn(players[index].text, players[index], 5)
			
			players[index].delete = UIUtil.CreateButtonStd(players[index], '/scx_menu/lobby_manager/close_btn/close', "", 0, 0)
			LayoutHelpers.AtRightTopIn(players[index].delete, players[index], 5)
			Tooltip.AddButtonTooltip(players[index].delete, {text='Remove Entry', body='Removes this entry from your ban/probation/notes list.'})
			players[index].delete.OnClick = function(self, modifiers)
				local u = players[index].uid
				local eType = players[index].entryType
				UIUtil.QuickDialog(dialogContent, "Remove entry for UID "..u.."?",
					"Remove Entry", function()
							if eType == 'B' then
								LobbyManager.RemoveBannedPlayer(u)
							elseif eType == 'P' then
								LobbyManager.RemoveProbationaryPlayer(u)
							elseif eType == 'N' then
								LobbyManager.RemoveNotedPlayer(u)
							end
							LoadData()
							dialogContent.top = math.max(0, dialogContent.top - 1)
							dialogContent:CalcVisible()
						end,
					"<LOC _Cancel>", nil,
					nil, nil,
					true,
					{worldCover = true, enterButton = 1, escapeButton = 2})
				
			end
			
			players[index].promoteentry = UIUtil.CreateButtonStd(players[index], '/scx_menu/lobby_manager/up_btn/up', "", 0, 0)
			LayoutHelpers.AtRightTopIn(players[index].promoteentry, players[index], 41)
			Tooltip.AddButtonTooltip(players[index].promoteentry, {text='Convert to Probation/Ban', body='Changes this entry from a note to probation or from probation to a ban.'})
			players[index].promoteentry.OnClick = function(self, modifiers)
				local u = players[index].uid
                local et = players[index].entryType
				if et == 'P' then
					LobbyManager.ConvertToBan(u)
				elseif et == 'N' then
					LobbyManager.ConvertToProbation(u)
				end
				
				LoadData()
				dialogContent.top = math.max(0, dialogContent.top - 1)
				dialogContent:CalcVisible()
			end
			players[index].promoteentry:Hide()
			
			players[index].demoteentry = UIUtil.CreateButtonStd(players[index], '/scx_menu/lobby_manager/down_btn/down', "", 0, 0)
			LayoutHelpers.AtRightTopIn(players[index].demoteentry, players[index], 23)
			Tooltip.AddButtonTooltip(players[index].demoteentry, {text='Convert to Probation/Note', body='Changes this entry from a ban to a probation or from a probation to a note.'})
			players[index].demoteentry.OnClick = function(self, modifiers)
				local u = players[index].uid
                local et = players[index].entryType
				if et == 'B' then
					LobbyManager.ConvertToProbation(u)
				elseif et == 'P' then
					LobbyManager.ConvertToNoted(u)
				end
				
				LoadData()
				dialogContent.top = math.max(0, dialogContent.top - 1)
				dialogContent:CalcVisible()
			end
			players[index].demoteentry:Hide()
            
			
			players[index].edit = UIUtil.CreateButtonStd(players[index], '/scx_menu/lobby_manager/edit_btn/edit', "", 0, 0)
			LayoutHelpers.AtRightTopIn(players[index].edit, players[index], 59)
			Tooltip.AddButtonTooltip(players[index].edit, {text='Edit Entry', body='Allows you to modify the information in this entry.'})
			players[index].edit.OnClick = function(self, modifiers)
				local data = datalist[players[index].linekey]
				local iOpt = {}
				iOpt.pId = players[index].uid
				if data.OriginalName then
					iOpt.pName = data.OriginalName
				else
					iOpt.pName = 'Unknown'
				end
				local eType = players[index].entryType
				if eType == 'B' then
					iOpt.action = 'ban'
				elseif eType == 'P' then
					iOpt.action = 'warn'
				elseif eType == 'N' then
					iOpt.action = 'note'
				end
				iOpt.isEdit = true
				iOpt.editData = data
				import('/lua/ui/lobby/lobbymanager/LobbyManager_BanProbation.lua').CreateDialog(dialogContent, iOpt, function() 
                				LoadData()
                                dialogContent.top = math.max(0, dialogContent.top - 1)
                                dialogContent:CalcVisible()
                end, function() end, false)
				
				LoadData()
				dialogContent.top = math.max(0, dialogContent.top - 1)
				dialogContent:CalcVisible()
			end
			
			players[index].value = UIUtil.CreateText(players[index], '', 14, "Arial")
			players[index].value:SetColor(UIUtil.fontOverColor)
			players[index].value:DisableHitTest()
			LayoutHelpers.AtLeftTopIn(players[index].value, players[index], 5, 16)

			players[index].value.bg = Bitmap(players[index])
			players[index].value.bg:SetSolidColor('ff333333')
			players[index].value.bg.Left:Set(players[index].Left)
			players[index].value.bg.Right:Set(players[index].Right)
			players[index].value.bg.Bottom:Set(function() return players[index].value.Bottom() + 2 end)
			players[index].value.bg.Top:Set(players[index].Top)
			players[index].value.bg.Depth:Set(function() return players[index].Depth() - 2 end)

			players[index].value.bg2 = Bitmap(players[index])
			players[index].value.bg2:SetSolidColor('ff000000')
			players[index].value.bg2.Left:Set(function() return players[index].value.bg.Left() + 1 end)
			players[index].value.bg2.Right:Set(function() return players[index].value.bg.Right() - 1 end)
			players[index].value.bg2.Bottom:Set(function() return players[index].value.bg.Bottom() - 1 end)
			players[index].value.bg2.Top:Set(function() return players[index].value.Top() + 0 end)
			players[index].value.bg2.Depth:Set(function() return players[index].value.bg.Depth() + 1 end)
		end

		CreateElement(1)
		LayoutHelpers.AtLeftTopIn(players[1], dialogContent, 10, 30)

		local index = 2
		while players[table.getsize(players)].Bottom() + players[1].Height() < (dialogContent.Bottom() - 45) do
			CreateElement(index)
			LayoutHelpers.Below(players[index], players[index-1])
			index = index + 1
		end
	end
	
	CreatePlayerElements()
	
	local numLines = function() return table.getsize(players) end

	local function DataSize()
		return table.getn(datalist)
	end

	-- called when the scrollbar for the control requires data to size itself
	-- GetScrollValues must return 4 values in this order:
	-- rangeMin, rangeMax, visibleMin, visibleMax
	-- aixs can be "Vert" or "Horz"
	dialogContent.GetScrollValues = function(self, axis)
		local size = DataSize()
		--LOG(size, ":", self.top, ":", math.min(self.top + numLines, size))
		return 0, size, self.top, math.min(self.top + numLines(), size)
	end

	-- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
	dialogContent.ScrollLines = function(self, axis, delta)
		self:ScrollSetTop(axis, self.top + math.floor(delta))
	end

	-- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
	dialogContent.ScrollPages = function(self, axis, delta)
		self:ScrollSetTop(axis, self.top + math.floor(delta) * numLines())
	end

	-- called when the scrollbar wants to set a new visible top line
	dialogContent.ScrollSetTop = function(self, axis, top)
		top = math.floor(top)
		if top == self.top then return end
		local size = DataSize()
		self.top = math.max(math.min(size - numLines() , top), 0)
		self:CalcVisible()
	end

	-- called to determine if the control is scrollable on a particular access. Must return true or false.
	dialogContent.IsScrollable = function(self, axis)
		return true
	end
	-- determines what controls should be visible or not
	dialogContent.CalcVisible = function(self)
		local function SetTextLine(line, data, lineID)
			line.linekey = lineID
			line.uid = data.UID
			line.entryType = data.Type
			local prefix = ''
			if data.Type == 'B' then
				line.text:SetColor('ff7777')
				prefix = 'Banned'
				line.demoteentry:Show()
				line.promoteentry:Hide()
			elseif data.Type == 'P' then
				line.text:SetColor('ffc177')
				prefix = 'Probationary'
				line.demoteentry:Show()
				line.promoteentry:Show()
			elseif data.Type == 'N' then
				line.text:SetColor('77ff77')
				prefix = 'Notes'
				line.demoteentry:Hide()
				line.promoteentry:Show()
			end
			local t1 = ''
			if data.OriginalName then
				t1 = ', Original Name: '..data.OriginalName
			end
			line.text:SetText(prefix..' UID: '..data.UID..t1)
			
			local t2 = ''
			if data.Notes then
				t2 = data.Notes
			end
			line.value:SetText(t2)
			
			line.value.bg.HandleEvent = Group.HandleEvent
			line.value.bg2.HandleEvent = Bitmap.HandleEvent
			
			local t3 = ''
			for i,v in data.BanReasons do
				if i == 1 then
					t3 = ReasonTable[v]
				else
					t3 = t3..', '..ReasonTable[v]
				end
			end
			Tooltip.AddControlTooltip(line.value.bg, {text='Reason(s)', body=t3})
		end
		for i, v in players do
			if datalist[i + self.top] then
				SetTextLine(v, datalist[i + self.top], i + self.top)
			end
		end
	end

	dialogContent:CalcVisible()

	dialogContent.HandleEvent = function(self, event)
		if event.Type == 'WheelRotation' then
			local lines = 1
			if event.WheelRotation > 0 then
				lines = -1
			end
			self:ScrollLines(nil, lines)
		end
	end

	UIUtil.CreateLobbyVertScrollbar(dialogContent, -17, -2, 2)
	
	--Exit Button
	local QuitButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Done")
		LayoutHelpers.AtHorizontalCenterIn(QuitButton, dialogContent, 0)
		LayoutHelpers.AtBottomIn(QuitButton, dialogContent, 10)
		QuitButton.OnClick = function(self)
			dialog:Destroy()			
		end
end