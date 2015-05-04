--*****************************************************************************
--* File: lua/LobbyManager_BanProbation.lua
--* Author: Chris Blackwell (Modified by Duck42 for use as a UI mod panel)
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
local Edit = import('/lua/maui/edit.lua').Edit
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup

local peerName
local peerId
local actionType

function CreateDialog(parent, initialOptions, OnOk, OnCancel, isHost)
    
	peerName = initialOptions.pName
	peerId = initialOptions.pId
	actionType = initialOptions.action
	
	--Dialog setup
	local dialogContent = Group(parent)
    dialogContent.Width:Set(450)
    dialogContent.Height:Set(650)

    local dialog = Popup(parent, dialogContent)
    
	--Title
    local title = UIUtil.CreateText(dialogContent, "", 20, UIUtil.titleFont)
	if actionType == 'ban' then
		title:SetText('Ban Player')
	elseif actionType == 'warn' then
		title:SetText('Warn Player')
    elseif actionType == 'note' then
		title:SetText('Notes About Player')
	end
    LayoutHelpers.AtTopIn(title, dialogContent, 12)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent)
	
	--Player Name/ID
	local playerInfo = UIUtil.CreateText(dialogContent, "Player Name: "..peerName .. "  ID: "..peerId, 16, UIUtil.titleFont)
    LayoutHelpers.Below(playerInfo, title)
    LayoutHelpers.AtHorizontalCenterIn(playerInfo, dialogContent)
		
	--Reason List and Scroll Bar
	local numElementsPerPage = 13
	
    local scrollGroup = Group(dialogContent)
    LayoutHelpers.AtLeftTopIn(scrollGroup, dialogContent, 33, 80)	
    scrollGroup.Width:Set(function() return dialogContent.Width() - 66 end)
	scrollGroup.Height:Set(325)
	
	UIUtil.SurroundWithBorder(scrollGroup, '/scx_menu/lan-game-lobby/frame/')

    UIUtil.CreateLobbyVertScrollbar(scrollGroup, -15)

    scrollGroup.controlList = {}
    scrollGroup.top = 1
    
    scrollGroup.GetScrollValues = function(self, axis)
        return 1, table.getn(self.controlList), self.top, math.min(self.top + numElementsPerPage - 1, table.getn(scrollGroup.controlList))
    end

    scrollGroup.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    scrollGroup.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * numElementsPerPage)
    end

    scrollGroup.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        self.top = math.max(math.min(table.getn(self.controlList) - numElementsPerPage + 1 , top), 1)
        self:CalcVisible()
    end

    scrollGroup.IsScrollable = function(self, axis)
        return true
    end
    
    scrollGroup.CalcVisible = function(self)
        local top = self.top
        local bottom = self.top + numElementsPerPage
        for index, control in ipairs(self.controlList) do
            if index < top or index >= bottom then
                control:Hide()
                control.Top:Set(function() return self.Top() end)
            else
                control:Show()
                control.Left:Set(self.Left)
                local lIndex = index
                local lControl = control
                control.Top:Set(function() return self.Top() + ((lIndex - top) * lControl.Height()) end)
            end
        end
    end
	
	-- Note Area
	local notesTitle = UIUtil.CreateText(dialogContent, "Notes", 16, UIUtil.titleFont)
	LayoutHelpers.Below(notesTitle, scrollGroup, 40)
    LayoutHelpers.AtLeftIn(notesTitle, dialogContent, 33)
	
	local noteEditArea = Group(dialogContent)
	noteEditArea.Width:Set(function() return dialogContent.Width() - 66 end)
    noteEditArea.Height:Set(100)
	LayoutHelpers.Below(noteEditArea, notesTitle, 5)
	LayoutHelpers.AtLeftIn(noteEditArea, dialogContent, 33)
	
	local notesEdit = Edit(noteEditArea)
    LayoutHelpers.AtTopIn(notesEdit, noteEditArea, 2)
	LayoutHelpers.AtLeftIn(notesEdit, noteEditArea, 2)
    notesEdit.Width:Set(function() return noteEditArea.Width() -4 end)
    notesEdit.Height:Set(function() return noteEditArea.Height() -4 end)
    notesEdit:SetFont(UIUtil.bodyFont, 16)
    notesEdit:SetForegroundColor(UIUtil.fontColor)
    notesEdit:SetHighlightBackgroundColor('cccccc00')
    notesEdit:SetHighlightForegroundColor(UIUtil.fontColor)
    notesEdit:ShowBackground(true)
	--notesEdit:SetText('Original Name: '..peerName)
	
	notesEdit:SetMaxChars(200)
    notesEdit.OnCharPressed = function(self, charcode)
        if charcode == UIUtil.VK_TAB then
            return true
        end
        local charLim = self:GetMaxChars()
        if STR_Utf8Len(self:GetText()) >= charLim then
            local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
            PlaySound(sound)
        end
    end
	
	UIUtil.SurroundWithBorder(noteEditArea, '/scx_menu/lan-game-lobby/frame/')

    --notesEdit.OnLoseKeyboardFocus = function(self)
        --notesEdit:AcquireFocus()
    --end

    notesEdit.OnEnterPressed = function(self, text)
    end

    notesEdit.OnNonTextKeyPressed = function(self, keyCode)
    end
	
	--Buttons	
	local halfWidth = dialogContent.Width() / 2
	local distanceFromCenter = 30
		
	local okBtn = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Ok>")
	LayoutHelpers.Below(okBtn, noteEditArea, 20)
	okBtn.Left:Set(function() return dialogContent.Left() + halfWidth - (okBtn.Width() + distanceFromCenter) end)
	okBtn.label:SetText(LOC("<LOC _Ok>"))
	
	local cancelBtn = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Close>")
	LayoutHelpers.Below(cancelBtn, noteEditArea, 20)
	cancelBtn.Left:Set(function() return dialogContent.Left() + halfWidth + distanceFromCenter end)
    cancelBtn.label:SetText(LOC("<LOC _Cancel>"))	
	
    local function CreateListElement(parentControl, urKey, idx)
        local textures = {up = UIUtil.UIFile('/scx_menu/restrict_units/bg_up.dds'),
            over = UIUtil.UIFile('/scx_menu/restrict_units/bg_over.dds'),
            sel_up = UIUtil.UIFile('/scx_menu/restrict_units/bg_sel_up.dds'),
            sel_over = UIUtil.UIFile('/scx_menu/restrict_units/bg_sel_over.dds')}
            
        local bg = Bitmap(parentControl, textures.up)
        bg.urKey = idx
        
        local label = UIUtil.CreateText(bg, idx.. ' - '..urKey, 14, UIUtil.bodyFont)
        LayoutHelpers.AtLeftIn(label, bg, 34)
        LayoutHelpers.AtVerticalCenterIn(label, bg)
        label:DisableHitTest()

        bg.active = false
        bg:SetTexture(textures.up)

        bg.Toggle = function(self)
            self.active = not self.active  
            if self.active then
                self:SetTexture(textures.sel_up)
            else
                self:SetTexture(textures.up)
            end
        end

        bg.Clear = function(self)
            self.active = false
            self:SetTexture(textures.up)
        end
        bg.IsHost = isHost
        bg.HandleEvent = function(self, event)
			if event.Type == 'MouseEnter' then
				if self.active then
					bg:SetTexture(textures.sel_over)
				else
					bg:SetTexture(textures.over)
				end   
				local sound = Sound({Cue = "UI_Tab_Rollover_01", Bank = "Interface",})
				PlaySound(sound)
			elseif event.Type == 'MouseExit' then
				if self.active then
					bg:SetTexture(textures.sel_up)
				else
					bg:SetTexture(textures.up)
				end    
			elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
				self:Toggle()
				local sound = Sound({Cue = "UI_Tab_Click_01", Bank = "Interface",})
				PlaySound(sound)
			end
        end

        bg:Hide()
        return bg
    end
	
	local reasonList = import('/lua/ui/lobby/lobbymanager/LobbyManager.lua').reasonTable
    if actionType == 'ban' or actionType == 'warn' then
        for index, reason in reasonList do
            table.insert(scrollGroup.controlList, CreateListElement(scrollGroup, reason, index))
        end
    end

    scrollGroup.HandleEvent = function(control, event)
        if event.Type == 'WheelRotation' then
            local lines = 1
            if event.WheelRotation > 0 then
                lines = -1
            end
            control:ScrollLines(nil, lines)
        end
    end
    scrollGroup:CalcVisible()

    local function KillDialog()
        dialog:Destroy()
    end

    cancelBtn.OnClick = function(self, modifiers)
        OnCancel()
        KillDialog()
    end
    
    
	okBtn.OnClick = function(self, modifiers)
		--Save Ban/Probation Data
		local rsn = {}
		local rsnCount = 0
		for index, control in scrollGroup.controlList do
			if control.active == true then
				table.insert(rsn, control.urKey)
				rsnCount = rsnCount + 1
			end
		end
		if rsnCount == 0 then
			table.insert(rsn, 10) --Unspecified
		end
        local aData = {}
        aData.data = {UID = peerId, BanReasons = rsn, Notes = notesEdit:GetText(), OriginalName = peerName}
		if actionType == 'ban' then
            aData.code = 'banned'
			LobbyManager.AddBannedPlayer(peerId, rsn, notesEdit:GetText(), peerName)
		elseif actionType == 'warn' then
            aData.code = 'probation'
			LobbyManager.AddProbationaryPlayer(peerId, rsn, notesEdit:GetText(), peerName)
        elseif actionType == 'note' then
            aData.code = 'note'
			LobbyManager.AddNotedPlayer(peerId, rsn, notesEdit:GetText(), peerName)
		end
        OnOk(aData)
		KillDialog()
	end    

    UIUtil.MakeInputModal(dialog, function() okBtn.OnClick(okBtn) end, function() cancelBtn.OnClick(cancelBtn) end)
    --UIUtil.CreateWorldCover(dialog)
	
	if initialOptions.isEdit == true then
		for index, reason in initialOptions.editData.BanReasons do
			if scrollGroup.controlList[reason] then
				--Turn Option On
				scrollGroup.controlList[reason]:Toggle()
			end
		end
		notesEdit:SetText(initialOptions.editData.Notes)
	end
end