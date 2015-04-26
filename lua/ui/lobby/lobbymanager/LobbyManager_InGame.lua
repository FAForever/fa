local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Edit = import('/lua/maui/edit.lua').Edit
local LobbyManager = import('/lua/ui/lobby/lobbymanager/LobbyManager.lua')

local menu
local listSender = ''
local tempList

function DestroyDialog()
    if menu then 
        menu:Destroy()
        menu = false
    end
end

function Init()
	import('/lua/ui/game/gamemain.lua').RegisterChatFunc(ReceiveLobbyManagerList, 'LobbyManagerList')
end

function CreateLobbyManagerOptionsMenu(button, playerName)
	DestroyDialog()
	
    local group = Group(button)
    group.Depth:Set(button:GetRootFrame():GetTopmostDepth() + 1)
    local title = Edit(group)
    local items = {
        {label = 'Add to Ban List',
        action = function()			
			local data = {}
			data.pId = GetClientIdByName(playerName)
			data.pName = playerName
			data.action = 'ban'
			import('/lua/ui/lobby/lobbymanager/LobbyManager_BanProbation.lua').CreateDialog(GetFrame(0), data, function() end, function() end, false)
			DestroyDialog()
        end,},
        {label = 'Add to Probation List',
        action = function()
			local data = {}
			data.pId = GetClientIdByName(playerName)
			data.pName = playerName
			data.action = 'warn'
			import('/lua/ui/lobby/lobbymanager/LobbyManager_BanProbation.lua').CreateDialog(GetFrame(0), data, function() end, function() end, false)
			DestroyDialog()
        end,
        arrow = true},
        {label = 'Add a Note',
        action = function()
			local data = {}
			data.pId = GetClientIdByName(playerName)
			data.pName = playerName
			data.action = 'note'
			import('/lua/ui/lobby/lobbymanager/LobbyManager_BanProbation.lua').CreateDialog(GetFrame(0), data, function() end, function() end, false)
			DestroyDialog()
        end,
        arrow = true},
        {label = 'Send List',
        action = function()
            -- local armies = GetArmiesTable().armiesTable
            -- local entries = {}
            -- for i, armyData in armies do
                -- if i != GetFocusArmy() and armyData.human then
                    -- local entry = UIUtil.CreateText(group, armyData.nickname, 12, UIUtil.bodyFont)
                    -- entry.ID = i
                    -- table.insert(entries, entry)
                -- end
            -- end
            -- if table.getsize(entries) > 0 then
                -- group.SubMenu = CreateSubMenu(group, entries, function(id)
                    -- Templates.SendTemplate(button.Data.template.templateID, id)
                    -- RefreshUI()
                -- end)
            -- end
        end,
        disabledFunc = function()
            if table.getsize(GetSessionClients()) > 1 then
                return false
            else
                return true
            end
        end,
        arrow = true},
		{label = 'Cancel',
        action = function()
			DestroyDialog()
        end,},
    }
    local function CreateItem(data)
        local bg = Bitmap(group)
        bg:SetSolidColor('00000000')
        bg.label = UIUtil.CreateText(bg, LOC(data.label), 12, UIUtil.bodyFont)
        bg.label:DisableHitTest()
        LayoutHelpers.AtLeftTopIn(bg.label, bg, 2)
        bg.Height:Set(function() return bg.label.Height() + 2 end)
        bg.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                self:SetSolidColor('ff777777')
            elseif event.Type == 'MouseExit' then
                self:SetSolidColor('00000000')
            elseif event.Type == 'ButtonPress' then
                if group.SubMenu then
                    group.SubMenu:Destroy()
                    group.SubMenu = false
                end
                data.action()
            end
            return true
        end
        
        if data.disabledFunc and data.disabledFunc() then
            bg:Disable()
            bg.label:SetColor('ff777777')
        end
        
        return bg
    end
    local totHeight = 0
    local maxWidth = 0
    title.Height:Set(function() return title:GetFontHeight() end)
    title.Width:Set(function() return title:GetStringAdvance(playerName) end)
    UIUtil.SetupEditStd(title, "ffffffff", nil, "ffaaffaa", UIUtil.highlightColor, UIUtil.bodyFont, 14, 200)
    title:SetDropShadow(true)
    title:ShowBackground(true)
    title:SetText(playerName)
    LayoutHelpers.AtLeftTopIn(title, group)
    totHeight = totHeight + title.Height()
    maxWidth = math.max(maxWidth, title.Width())
    local itemControls = {}
    local prevControl = false
    for index, actionData in items do
        local i = index
        itemControls[i] = CreateItem(actionData)
        if prevControl then
            LayoutHelpers.Below(itemControls[i], prevControl)
        else
            LayoutHelpers.Below(itemControls[i], title)
        end
        totHeight = totHeight + itemControls[i].Height()
        maxWidth = math.max(maxWidth, itemControls[i].label.Width()+4)
        prevControl = itemControls[i]
    end
    for _, control in itemControls do
        control.Width:Set(maxWidth)
    end
    title.Width:Set(maxWidth)
    group.Height:Set(totHeight)
    group.Width:Set(maxWidth)
    LayoutHelpers.Below(group, button, 10)
    
    title.HandleEvent = function(self, event)
        Edit.HandleEvent(self, event)
        return true
    end
    title.OnEnterPressed = function(self, text)
    end
    
    local bg = CreateMenuBorder(group)
    
    group.HandleEvent = function(self, event)
		if event.Type == 'MouseExit' then
			
		end
        return true
    end
    menu = group
end

function CreateMenuBorder(group)
    local bg = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_m.dds'))
    bg.tl = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ul.dds'))
    bg.tm = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_horz_um.dds'))
    bg.tr = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ur.dds'))
    bg.l = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_vert_l.dds'))
    bg.r = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_vert_r.dds'))
    bg.bl = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ll.dds'))
    bg.bm = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_lm.dds'))
    bg.br = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_lr.dds'))
    
    LayoutHelpers.FillParent(bg, group)
    bg.Depth:Set(group.Depth)
    
    bg.tl.Bottom:Set(group.Top)
    bg.tl.Right:Set(group.Left)
    bg.tl.Depth:Set(group.Depth)
    
    bg.tm.Bottom:Set(group.Top)
    bg.tm.Right:Set(group.Right)
    bg.tm.Left:Set(group.Left)
    bg.tm.Depth:Set(group.Depth)
    
    bg.tr.Bottom:Set(group.Top)
    bg.tr.Left:Set(group.Right)
    bg.tr.Depth:Set(group.Depth)
    
    bg.l.Bottom:Set(group.Bottom)
    bg.l.Right:Set(group.Left)
    bg.l.Top:Set(group.Top)
    bg.l.Depth:Set(group.Depth)
    
    bg.r.Bottom:Set(group.Bottom)
    bg.r.Left:Set(group.Right)
    bg.r.Top:Set(group.Top)
    bg.r.Depth:Set(group.Depth)
    
    bg.bl.Top:Set(group.Bottom)
    bg.bl.Right:Set(group.Left)
    bg.bl.Depth:Set(group.Depth)
    
    bg.br.Top:Set(group.Bottom)
    bg.br.Left:Set(group.Right)
    bg.br.Depth:Set(group.Depth)
    
    bg.bm.Top:Set(group.Bottom)
    bg.bm.Right:Set(group.Right)
    bg.bm.Left:Set(group.Left)
    bg.bm.Depth:Set(group.Depth)
    
    return bg
end

function GetClientIdByName(playerName)
    local sessionClientsTable = GetSessionClients()
	for i, clientInfo in sessionClientsTable do
		if clientInfo.name == playerName then
			return clientInfo.uid
		end
	end
	return -1
end

function ReceiveLobbyManagerList(sender, msg)
	if listSender == '' and msg.data.Last == false then
		LOG('Received Initial Lobby Manager List Message')
		listSender = sender
		tempList = {}
		table.insert(tempList, msg.data)
	elseif listSender == sender and msg.data.Last == false then
		LOG('Received Subsequent Lobby Manager List Message')
		table.insert(tempList, msg.data)
	end
	
	if listSender == sender and msg.data.Last == true then
		LOG('Received Last Lobby Manager List Message')
		UIUtil.QuickDialog(panel, listSender.." has sent you their list of banned/probationary players.  Would you like to merge it with yours?", 
			"<LOC _Yes>", function()
				MergeList()
			end,
			"<LOC _No>", nil,
			nil, nil,
			true, 
			{worldCover = false, enterButton = 1, escapeButton = 2})
			
			LOG('Clearing List Sender Value')
			listSender = ''
	end
end

function SendLobbyManagerList(armyIndex)
	LOG('Sending Lobby Manager List')
    armyIndex = armyIndex
	local data = LobbyManager.LoadConfig()
	local bList = data.BannedPlayers
	local pList = data.ProbationaryPlayers
	for i, bPlayer in bList do
		local temp = bPlayer
		temp.Last = false
		temp.PlayerType = 'B'
		SessionSendChatMessage(armyIndex, {LobbyManagerList = true, data = temp})
	end
	
	for i, pPlayer in pList do
		local temp = pPlayer
		temp.Last = false
		temp.PlayerType = 'P'
		SessionSendChatMessage(armyIndex, {LobbyManagerList = true, data = temp})
	end
	
	local temp = {}
	temp.Last = true
	temp.PlayerType = 'E'
	SessionSendChatMessage(armyIndex, {LobbyManagerList = true, data = temp})
	LOG('Done Sending Lobby Manager List')
end

function MergeList()
	LOG('Beginning Lobby Manager List Merge')
	for i, listPlayer in tempList do
		if listPlayer.PlayerType == 'B' then
			local pData = LobbyManager.IsPlayerProbationary(listPlayer.UID)
			if pData.data == nil then
				LOG('Adding Banned Player: '..listPlayer.UID)
				LobbyManager.AddBannedPlayer(listPlayer.UID, listPlayer.BanReasons, listPlayer.Notes)
			else
				LOG('Skipped Banned Player Due to Conflict: '..listPlayer.UID)
			end
		elseif listPlayer.PlayerType == 'P' then
			local pData = LobbyManager.IsPlayerBanned(listPlayer.UID)
			if pData.data == nil then
				LOG('Adding Probationary Player: '..listPlayer.UID)
				LobbyManager.AddProbationaryPlayer(listPlayer.UID, listPlayer.BanReasons, listPlayer.Notes)
			else
				LOG('Skipped Probationary Player Due to Conflict: '..listPlayer.UID)
			end
		end
	end
	LOG('Finished Lobby Manager List Merge')
	LOG('Clearing TempList')
	tempList = {}
end