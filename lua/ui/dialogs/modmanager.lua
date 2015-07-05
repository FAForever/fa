--*****************************************************************************
--* File: lua/modules/ui/dialogs/modmanager.lua
--* Author: Chris Blackwell
--* Summary: Allows you to choose mods
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local Scrollbar = import('/lua/maui/scrollbar.lua').Scrollbar
local Text = import('/lua/maui/text.lua').Text
local MultiLineText = import('/lua/maui/multilinetext.lua').MultiLineText
local Button = import('/lua/maui/button.lua').Button
local Group = import('/lua/maui/group.lua').Group
local MenuCommon = import('/lua/ui/menus/menucommon.lua')
local MainMenu = import('/lua/ui/menus/main.lua')
local Mods = import('/lua/mods.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local Prefs = import('/lua/user/prefs.lua')
local Edit = import('/lua/maui/edit.lua').Edit


local _InternalUpdateStatus


# This function can be called while the ModManager is active, to update changes to the selected mods on the fly.
# If called when the ModManger is -not- active, it is a no-op.
function UpdateClientModStatus(selectedModsFromHost)
    if _InternalUpdateStatus then
        _InternalUpdateStatus(selectedModsFromHost)
    end
end


function ClientModStatus(selectedModsFromHost)
    Mods.ClearCache() -- force reload of mod info to pick up changes on disk
    local my_all = Mods.AllSelectableMods()
    local my_sel = Mods.GetSelectedMods()
    local r = {}

    for uid, mod in my_all do

        if mod.ui_only then
            r[uid] = {
                checked = my_sel[uid],
                cantoggle = true,
                tooltip = nil,
				uionly = true
            }
        else
            r[uid] = {
                checked = (selectedModsFromHost[uid] or false),
                cantoggle = false,
                tooltip = 'modman_controlled_by_host',
				uionly = false
            }
        end
    end
    return r
end


function HostModStatus(availableMods)
    Mods.ClearCache() -- force reload of mod info to pick up changes on disk
    local my_all = Mods.AllSelectableMods()
    local my_sel = Mods.GetSelectedMods()
    local r = {}

    local function everyoneHas(uid)
        for peer,modset in availableMods do
            if not modset[uid] then
                return false
            end
        end
        return true
    end

    for uid,mod in my_all do
        if mod.ui_only or everyoneHas(uid) then
			if mod.ui_only then
				r[uid] = {
					checked = my_sel[uid],
					cantoggle = true,
					tooltip = nil,
					uionly = true
				}
			else
				r[uid] = {
					checked = my_sel[uid],
					cantoggle = true,
					tooltip = nil,
					uionly = false
				}
			end
        else
            r[uid] = {
                checked = false,
                cantoggle = false,
                tooltip = 'modman_some_missing',
				uionly = false
            }
        end
    end
    return r
end


function LocalModStatus()
    Mods.ClearCache() -- force reload of mod info to pick up changes on disk
    local my_all = Mods.AllSelectableMods()
    local my_sel = Mods.GetSelectedMods()
    local r = {}

    for uid,mod in my_all do
		if mod.ui_only then
			r[uid] = {
				checked = my_sel[uid],
				cantoggle = true,
				tooltip = nil,
				uionly = true
			}
        else
			r[uid] = {
				checked = my_sel[uid],
				cantoggle = true,
				tooltip = nil,
				uionly = false
			}
		end
    end
    return r
end

local function IsModExclusive(uid)
    local my_all = Mods.AllSelectableMods()
    if my_all[uid] and my_all[uid].exclusive then
        return true
    end
    return false
end

local function CreateDependsDialog(parent, text, yesFunc)
    local dialog = Group(parent)
    local background = Bitmap(dialog, UIUtil.SkinnableFile('/dialogs/dialog/panel_bmp_m.dds'))
    background:SetTiled(true)
    LayoutHelpers.FillParent(background, dialog)

    dialog.Width:Set(background.Width)
    dialog.Height:Set(300)

    local backgroundTop = Bitmap(dialog, UIUtil.SkinnableFile('/dialogs/dialog/panel_bmp_T.dds'))
    LayoutHelpers.Above(backgroundTop, dialog)
    local backgroundBottom = Bitmap(dialog, UIUtil.SkinnableFile('/dialogs/dialog/panel_bmp_b.dds'))
    LayoutHelpers.Below(backgroundBottom, dialog)
    
    local textBox = UIUtil.CreateTextBox(background)
    LayoutHelpers.AtLeftTopIn(textBox, dialog, 30, 5)
    LayoutHelpers.AtRightIn(textBox, dialog, 64)
    LayoutHelpers.AtBottomIn(textBox, dialog, 5)
    
    local yesButton = UIUtil.CreateButtonStd( backgroundBottom, '/widgets/small', "<LOC _Yes>", 12, 0)
    LayoutHelpers.AtLeftIn(yesButton, backgroundBottom, 50)
    LayoutHelpers.AtTopIn(yesButton, backgroundBottom, 20)
    yesButton.OnClick = function(self)
        yesFunc()
        dialog:Destroy()
    end

    local noButton = UIUtil.CreateButtonStd( backgroundBottom, '/widgets/small', "<LOC _No>", 12, 0)
    LayoutHelpers.AtRightIn(noButton, backgroundBottom, 50)
    LayoutHelpers.AtTopIn(noButton, backgroundBottom, 20)
    noButton.OnClick = function(self)
        dialog:Destroy()
    end
    
    LayoutHelpers.AtCenterIn(dialog, parent:GetRootFrame())
    textBox:SetFont(UIUtil.bodyFont, 18)
    UIUtil.SetTextBoxText(textBox, text)
    UIUtil.CreateWorldCover(dialog)
end

local function CreateLoadPresetDialog(parent, scrollGroup)
    local dialog = Group(parent)
	dialog.Depth:Set(function() return parent.Depth() + 5 end)
    local background = Bitmap(dialog, UIUtil.SkinnableFile('/dialogs/dialog/panel_bmp_m.dds'))
    background:SetTiled(true)
    LayoutHelpers.FillParent(background, dialog)

    dialog.Width:Set(background.Width)
    dialog.Height:Set(300)

    local backgroundTop = Bitmap(dialog, UIUtil.SkinnableFile('/dialogs/dialog/panel_bmp_T.dds'))
    LayoutHelpers.Above(backgroundTop, dialog)
    local backgroundBottom = Bitmap(dialog, UIUtil.SkinnableFile('/dialogs/dialog/panel_bmp_b.dds'))
    LayoutHelpers.Below(backgroundBottom, dialog)
    
    local presets = ItemList(dialog)
	presets:SetFont(UIUtil.bodyFont, 16)
	presets:SetColors(UIUtil.fontColor(), "Black", "Black", "Gainsboro", "Black", "Gainsboro")
	LayoutHelpers.DepthOverParent(presets, dialog, 10)
    LayoutHelpers.AtLeftTopIn(presets, dialog, 30, 5)
    LayoutHelpers.AtRightIn(presets, dialog, 64)
    LayoutHelpers.AtBottomIn(presets, dialog, 5)
	presetsScroll = UIUtil.CreateVertScrollbarFor(presets)
	
	local userPresets = Prefs.GetFromCurrentProfile('UserPresets')
	
	local function fillPresetList()
		presets:DeleteAllItems()
		if userPresets then
			for k,v in userPresets do
				presets:AddItem(k)
			end
		end
	end
	
    local yesButton = UIUtil.CreateButtonStd( backgroundBottom, '/widgets/small', "<LOC _Load>Load", 12, 0)
    LayoutHelpers.AtLeftIn(yesButton, backgroundBottom, 0)
    LayoutHelpers.AtTopIn(yesButton, backgroundBottom, 20)
    yesButton.OnClick = function(self)
		local index = presets:GetSelection()
		if index and index >= 0 then
			local name = presets:GetItem(index)
			local presetMods = userPresets[name]
			for index, control in scrollGroup.controlList do
				if presetMods[control.modInfo.uid] and not control.active then
					control:Toggle()
				elseif not presetMods[control.modInfo.uid] and control.active then
					control:Toggle()
				end
			end
			dialog:Destroy()
		else
			UIUtil.ShowInfoDialog(dialog, "<LOC lobui_0593>You have not selected a preset to load.", "<LOC _OK>OK")
		end
    end
	
    local deleteButton = UIUtil.CreateButtonStd( backgroundBottom, '/widgets/small', "<LOC _Delete>Delete", 12, 0)
    LayoutHelpers.AtCenterIn(deleteButton, backgroundBottom)
    LayoutHelpers.AtTopIn(deleteButton, backgroundBottom, 20)
    deleteButton.OnClick = function(self)
		local index = presets:GetSelection()
		if index and index >= 0 then
			local name = presets:GetItem(index)
			UIUtil.QuickDialog(dialog, "<LOC lobui_0594>Are you sure you want to delete this preset?",
				"<LOC _Yes>", function()
					#table.remove(userPresets, index + 1)
					userPresets[name] = nil
					Prefs.SetToCurrentProfile('UserPresets', userPresets)
					fillPresetList()
				end,
				"<LOC _No>", nil,
				nil, nil, 
				true, {worldCover = false, enterButton = 1, escapeButton = 2})
		else
			UIUtil.ShowInfoDialog(dialog, "<LOC lobui_0595>You have not selected a preset to delete.", "<LOC _OK>OK")
		end
    end

    local noButton = UIUtil.CreateButtonStd( backgroundBottom, '/widgets/small', "<LOC _Cancel>Cancel", 12, 0)
    LayoutHelpers.AtRightIn(noButton, backgroundBottom, 0)
    LayoutHelpers.AtTopIn(noButton, backgroundBottom, 20)
    noButton.OnClick = function(self)
		dialog:Destroy()
    end
    
	fillPresetList()
		
    LayoutHelpers.AtCenterIn(dialog, parent:GetRootFrame())
    UIUtil.CreateWorldCover(dialog)
end

local function CreateSavePresetDialog(parent, scrollGroup)
    local dialog = Group(parent)
	dialog.Depth:Set(function() return parent.Depth() + 5 end)
    local background = Bitmap(dialog, UIUtil.SkinnableFile('/dialogs/dialog/panel_bmp_m.dds'))
    background:SetTiled(true)
    LayoutHelpers.FillParent(background, dialog)

    dialog.Width:Set(background.Width)
    dialog.Height:Set(60)

    local backgroundTop = Bitmap(dialog, UIUtil.SkinnableFile('/dialogs/dialog/panel_bmp_T.dds'))
    LayoutHelpers.Above(backgroundTop, dialog)
    local backgroundBottom = Bitmap(dialog, UIUtil.SkinnableFile('/dialogs/dialog/panel_bmp_b.dds'))
    LayoutHelpers.Below(backgroundBottom, dialog)
	
    local title = UIUtil.CreateText(dialog, '<LOC lobui_0596>Name this preset', 18)
    LayoutHelpers.AtTopIn(title, dialog, 10)
    LayoutHelpers.AtHorizontalCenterIn(title, dialog)
    
	local nameEdit = Edit(dialog)
	nameEdit.Width:Set(function() return background.Width() - 80 end)
	nameEdit.Height:Set(function() return nameEdit:GetFontHeight() end)
    LayoutHelpers.AtTopIn(nameEdit, dialog, 30)
    LayoutHelpers.AtHorizontalCenterIn(nameEdit, dialog)
	UIUtil.SetupEditStd(nameEdit, UIUtil.fontColor, "00569FFF", UIUtil.highlightColor, "880085EF", UIUtil.bodyFont, 18, 30)
	nameEdit:AcquireFocus()
    
    local yesButton = UIUtil.CreateButtonStd( backgroundBottom, '/widgets/small', "<LOC _Save>Save", 12, 0)
    LayoutHelpers.AtLeftIn(yesButton, backgroundBottom, 50)
    LayoutHelpers.AtTopIn(yesButton, backgroundBottom, 20)
    yesButton.OnClick = function(self)
        local name = nameEdit:GetText()
		local presets = Prefs.GetFromCurrentProfile('UserPresets')
		if not presets then presets = {} end
        if name == "" then
            nameEdit:AbandonFocus()
            UIUtil.ShowInfoDialog(dialog, "<LOC lobui_0597>Please fill in a preset name", "<LOC _OK>OK", function() nameEdit:AcquireFocus() end)
            return
		elseif presets[name] then
            nameEdit:AbandonFocus()
            UIUtil.QuickDialog(dialog, "<LOC lobui_0598>A preset with that name already exists. Do you want to overwrite it?", 
				"<LOC _Yes>", function()
					local selMods = {}
					for index, control in scrollGroup.controlList do
						if control.active then
							selMods[control.modInfo.uid] = true
						end
					end
					presets[name] = selMods
					Prefs.SetToCurrentProfile('UserPresets', presets)
					nameEdit:AcquireFocus()
				end,
				"<LOC _No>", function() nameEdit:AcquireFocus() end,
				nil, nil, 
				true, {worldCover = false, enterButton = 1, escapeButton = 2})
			return
		else
			local selMods = {}
			for index, control in scrollGroup.controlList do
				if control.active then
					selMods[control.modInfo.uid] = true
				end
			end
			presets[name] = selMods
			Prefs.SetToCurrentProfile('UserPresets', presets)
		end
        dialog:Destroy()
    end

    local noButton = UIUtil.CreateButtonStd(backgroundBottom, '/widgets/small', "<LOC _Cancel>Cancel", 12, 0)
    LayoutHelpers.AtRightIn(noButton, backgroundBottom, 50)
    LayoutHelpers.AtTopIn(noButton, backgroundBottom, 20)
    noButton.OnClick = function(self)
        dialog:Destroy()
    end
    
    LayoutHelpers.AtCenterIn(dialog, parent:GetRootFrame())
    UIUtil.CreateWorldCover(dialog)
end

function CreateDialog(over, inLobby, exitBehavior, useCover, modStatus)

    ---------------------------------------------------------------------------
    -- fill in default args
    ---------------------------------------------------------------------------
    modStatus = modStatus or LocalModStatus()

    local exclusiveModSelected = nil

    ---------------------------------------------------------------------------
    -- basic layout and operation of dialog
    ---------------------------------------------------------------------------

	local parent = over

    local panel = Bitmap(parent, UIUtil.UIFile('/scx_menu/mod-manager/panel_bmp.dds'))
    LayoutHelpers.AtCenterIn(panel, parent)
    
    panel.brackets = UIUtil.CreateDialogBrackets(panel, 38, 24, 38, 24)
    
    local title = UIUtil.CreateText(panel, LOC("<LOC _Mod_Manager>Mod Manager"), 24)
    LayoutHelpers.AtTopIn(title, panel, 31)
    LayoutHelpers.AtHorizontalCenterIn(title, panel)
    
    panel.Depth:Set(GetFrame(over:GetRootFrame():GetTargetHead()):GetTopmostDepth() + 1)
    
    local worldCover = nil
    if useCover then
    	worldCover = UIUtil.CreateWorldCover(panel)
    end
    
    local dlgLabel = UIUtil.CreateText(panel, "<LOC uimod_0001>Click to select or deselect", 20, 'Arial Bold')
    LayoutHelpers.AtTopIn(dlgLabel, panel, 80)
    LayoutHelpers.AtHorizontalCenterIn(dlgLabel, panel)
	
    ---------------------------------------------------------------------------
    -- Mod list control
    ---------------------------------------------------------------------------
    local numElementsPerPage = 5
    
    local scrollGroup = Group(panel)
    scrollGroup.Width:Set(635)
    scrollGroup.Height:Set(372)
    
    LayoutHelpers.AtLeftTopIn(scrollGroup, panel, 25, 118)
    UIUtil.CreateVertScrollbarFor(scrollGroup)
    
    scrollGroup.controlList = {}
    scrollGroup.top = 1
    
    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    scrollGroup.GetScrollValues = function(self, axis)
        return 1, table.getn(self.controlList), self.top, math.min(self.top + numElementsPerPage - 1, table.getn(scrollGroup.controlList))
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    scrollGroup.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    scrollGroup.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * numElementsPerPage)
    end

    -- called when the scrollbar wants to set a new visible top line
    scrollGroup.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        self.top = math.max(math.min(table.getn(self.controlList) - numElementsPerPage + 1 , top), 1)
        self:CalcVisible()
    end

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    scrollGroup.IsScrollable = function(self, axis)
        return true
    end
    
    -- determines what controls should be visible or not, and hide/show appropriately
    scrollGroup.CalcVisible = function(self)
        local top = self.top
        local bottom = self.top + numElementsPerPage
        for index, control in ipairs(self.controlList) do
            if index < top or index >= bottom then
                control:Hide()
            else
                control:Show()
                control.Left:Set(self.Left)
                local lIndex = index
                local lControl = control
                control.Top:Set(function() return self.Top() + ((lIndex - top) * lControl.Height()) end)
            end
        end
    end
    
    -- return all the currently selected controls
    local function GetCurrentlyListedMods()
        local ret = nil
        for index, control in scrollGroup.controlList do
            if not ret then ret = {} end
            ret[control.modInfo.uid] = control
        end
        return ret
    end

    ---------------------------------------------------------------------------
    -- Mod list element
    ---------------------------------------------------------------------------
    local function CreateListElement(parent, modInfo)
        local bg = Bitmap(parent, UIUtil.UIFile('/dialogs/mod_btn/mod-d_btn_up.dds'))
        bg.Height:Set(function() return parent.Height() / numElementsPerPage  end)
        bg.Width:Set(parent.Width)
        bg.modInfo = modInfo
        
        local icon = Bitmap(bg, modInfo.icon)
        icon.Height:Set(56)
        icon.Width:Set(56)
        LayoutHelpers.AtLeftTopIn(icon, bg, 12, 12)
        
        local name = UIUtil.CreateText(bg, modInfo.name, 14, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(name, bg, 92, 12)
        name:SetDropShadow(true)
        
        local activecheck = Checkbox(bg, 
            UIUtil.UIFile('/dialogs/check-box_btn/radio-d_btn_up.dds'), 
            UIUtil.UIFile('/dialogs/check-box_btn/radio-s_btn_up.dds'), 
            UIUtil.UIFile('/dialogs/check-box_btn/radio-d_btn_over.dds'), 
            UIUtil.UIFile('/dialogs/check-box_btn/radio-s_btn_over.dds'), 
            UIUtil.UIFile('/dialogs/check-box_btn/radio-d_btn_dis.dds'), 
            UIUtil.UIFile('/dialogs/check-box_btn/radio-s_btn_dis.dds'))
        LayoutHelpers.AtRightTopIn(activecheck, bg, 5, 6)
        activecheck:DisableHitTest()
        
        local desc = MultiLineText(bg, UIUtil.bodyFont, 14, UIUtil.fontColor)
        LayoutHelpers.AtLeftTopIn(desc, bg, 92, 34)
        desc.Height:Set(40)
        desc.Width:Set(460)
        desc:SetText(modInfo.description)

        icon:DisableHitTest()
        name:DisableHitTest()
        desc:DisableHitTest()

        if modStatus[modInfo.uid].checked then
            activecheck:SetCheck(true)
			if not modStatus[modInfo.uid].uionly then
				bg:SetTexture(UIUtil.UIFile('/dialogs/mod_btn/mod-t_btn_up.dds'))
			else
				bg:SetTexture(UIUtil.UIFile('/dialogs/mod_btn/mod-s_btn_up.dds'))
			end
            bg.active = true
            if IsModExclusive(modInfo.uid) then
                exclusiveModSelected = bg
            end
        else
            activecheck:SetCheck(false)
			if not modStatus[modInfo.uid].uionly then
				bg:SetTexture(UIUtil.UIFile('/dialogs/mod_btn/mod-b_btn_up.dds'))
			else
				bg:SetTexture(UIUtil.UIFile('/dialogs/mod_btn/mod-d_btn_up.dds'))
			end
            bg.active = false
        end

        bg:Hide()
        
        function bg:Toggle()
            if self.active then
                activecheck:SetCheck(false)
                if not modStatus[modInfo.uid].uionly then
					bg:SetTexture(UIUtil.UIFile('/dialogs/mod_btn/mod-b_btn_up.dds'))
				else
					bg:SetTexture(UIUtil.UIFile('/dialogs/mod_btn/mod-d_btn_up.dds'))
				end
                self.active = false
            else
                activecheck:SetCheck(true)
                if not modStatus[modInfo.uid].uionly then
					bg:SetTexture(UIUtil.UIFile('/dialogs/mod_btn/mod-t_btn_up.dds'))
				else
					bg:SetTexture(UIUtil.UIFile('/dialogs/mod_btn/mod-s_btn_up.dds'))
				end
                self.active = true
            end
        end

        local function HandleExclusiveClick(bg)
            local function DoExclusiveBehavior()
                exclusiveModSelected = bg
                bg:Toggle()
                for index, control in scrollGroup.controlList do
                    if control != bg and control.active then
                        control:Toggle()
                    end
                end
            end
            
            UIUtil.QuickDialog(
                parent, 
                "<LOC uimod_0010>The mod you have requested is marked as exclusive. If you select this mod, all other mods will be disabled. Do you wish to enable this mod?",
                "<LOC _Yes>", DoExclusiveBehavior,
                "<LOC _No>")
        end
        
        local function HandleExclusiveActive(bg, normalClickFunc)
            UIUtil.QuickDialog(
                parent,
                "<LOC uimod_0011>You currently have an exclusive mod selected, do you wish to deselect it?",
                "<LOC _Yes>", function()
                    exclusiveModSelected:Toggle()
                    exclusiveModSelected = nil
                    normalClickFunc(bg)
                end,
                "<LOC _No>")
        end

        local function HandleNormalClick(bg)
            if not bg.active then
                local curListed = GetCurrentlyListedMods()
                local depends = Mods.GetDependencies(bg.modInfo.uid)
                
                if depends.missing then
                    local boxText = LOC("<LOC uimod_0012>The requested mod can not be enabled as it requires the following mods that you don't currently have installed:\n\n")
                    for uid, v in depends.missing do
                        local name
                        if bg.modInfo.requiresNames and bg.modInfo.requiresNames[uid] then
                            name = bg.modInfo.requiresNames[uid]
                        else
                            name = uid
                        end
                        boxText = boxText .. name .. "\n"
                    end
                    UIUtil.QuickDialog(parent, boxText, "<LOC _Ok>")
                else
                    if depends.requires or depends.conflicts then
                        local needsRequiredActivated = false
                        local needsConflictsDisabled = false
                        
                        if depends.requires then
                            for uid, v in depends.requires do
                                if curListed[uid] and not curListed[uid].active then
                                    needsRequiredActivated = true
                                    break
                                end
                            end
                        end
                        
                        if depends.conflicts then
                            for uid, v in depends.conflicts do
                                if curListed[uid] and curListed[uid].active then
                                    needsConflictsDisabled = true
                                    break
                                end
                            end
                        end
                        
                        if (needsRequiredActivated == true) or (needsConflictsDisabled == true) then
                            local allMods = Mods.AllMods()
                            local boxText = ""
                            
                            if needsRequiredActivated == true then
                                boxText = boxText .. LOC("<LOC uimod_0013>The requested mod requires the following mods be enabled:\n\n")
                                for uid, v in depends.requires do
                                    if curListed[uid] and not curListed[uid].active then
                                        boxText = boxText .. allMods[uid].name .. "\n"
                                    end
                                end
                                boxText = boxText .. "\n"
                            end
                            if needsConflictsDisabled == true then
                                boxText = boxText .. LOC("<LOC uimod_0014>The requested mod requires the following mods be disabled:\n\n")
                                for uid, v in depends.conflicts do
                                    if curListed[uid] and curListed[uid].active then
                                        boxText = boxText .. allMods[uid].name .. "\n"
                                    end
                                end
                                boxText = boxText .. "\n"
                            end
                            boxText = boxText .. LOC("<LOC uimod_0015>Would you like to enable the requested mod? Selecting Yes will enable all required mods, and disable all conflicting mods.")
                            CreateDependsDialog(parent, boxText, function()
                                bg:Toggle()
                                if depends.requires then
                                    for uid, v in depends.requires do
                                        if curListed[uid] and not curListed[uid].active then
                                            curListed[uid]:Toggle()
                                        end
                                    end
                                end
                                if depends.conflicts then
                                    for uid, v in depends.conflicts do
                                        if curListed[uid] and curListed[uid].active then
                                            curListed[uid]:Toggle()
                                        end
                                    end
                                end
                            end)
                        else
                            bg:Toggle()
                        end                            
                    else
                        bg:Toggle()
                    end
                end
            else
                bg:Toggle()
            end
        end
        
        bg.HandleEvent = function(self, event)
            if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
                if modStatus[modInfo.uid].cantoggle then
                    if IsModExclusive(modInfo.uid) and not self.active then
                        HandleExclusiveClick(bg)                                    
                    else
                        if exclusiveModSelected then
                            HandleExclusiveActive(self, HandleNormalClick)
                        else
                            HandleNormalClick(self)
                        end
                    end
                end
                local sound = Sound({Cue = "UI_Mod_Select", Bank = "Interface",})
                PlaySound(sound)
            end
        end

        if modStatus[modInfo.uid].tooltip then
            Tooltip.AddControlTooltip(bg, modStatus[modInfo.uid].tooltip, .2)
        end

        return bg
    end
    
    ---------------------------------------------------------------------------
    -- Mod list element
    ---------------------------------------------------------------------------
    local allmods = Mods.AllSelectableMods()
	local selmods = Mods.GetSelectedMods()
	
    local modNamesTable = {}
    for k,v in allmods do 
        table.insert(modNamesTable, v)
    end
	
    table.sort(modNamesTable, function(a,b) 
			if selmods[a.uid] and selmods[b.uid] then
				return a.name < b.name
			elseif selmods[a.uid] or selmods[b.uid] then
				return selmods[a.uid] or false
			else
				return a.name < b.name
			end
		end)
	
    for k,v in modNamesTable do 
        local uid = v.uid
        local status = modStatus[uid]
		if inLobby and uid == "F14E58B6-E7F3-11DD-88AB-418A55D89593" then
			status.cantoggle = false
		end
        table.insert(scrollGroup.controlList, CreateListElement(scrollGroup, allmods[uid], status))
    end

    _InternalUpdateStatus = function(selectedModsFromHost)
        for index, control in scrollGroup.controlList do
            local uid = control.modInfo.uid
            if not modStatus[uid].cantoggle then
                if control.active != (selectedModsFromHost[uid] or false) then
                    control:Toggle()
                end
            end
        end
    end

    scrollGroup:CalcVisible()

    ---------------------------------------------------------------------------
    -- OK and cancel button behaviors
    ---------------------------------------------------------------------------
    local function KillDialog(cancel)
        local selectedMods
        if not cancel then
            selectedMods = {}
            
            for index, control in scrollGroup.controlList do
                if control.active then
                    selectedMods[control.modInfo.uid] = true
                end
            end
        end

        # clear out the module var '_InternalUpdateStatus' to disable background updates
        _InternalUpdateStatus = nil

        if over then
            panel:Destroy()
        else
            parent:Destroy()
        end

        (exitBehavior or Mods.SetSelectedMods)(selectedMods)
    end
	
    local loadBtn = UIUtil.CreateButtonStd(panel, '/widgets/small', "<LOC _Load>Load", 12, 2)
    LayoutHelpers.AtLeftTopIn(loadBtn, panel, 30, 75)
    loadBtn.OnClick = function(self, modifiers)
		CreateLoadPresetDialog(panel, scrollGroup)
    end
	
    local saveBtn = UIUtil.CreateButtonStd(panel, '/widgets/small', "<LOC _Save>Save", 12, 2)
    LayoutHelpers.AtRightTopIn(saveBtn, panel, 30, 75)
    saveBtn.OnClick = function(self, modifiers)
		CreateSavePresetDialog(panel, scrollGroup)
    end

    local cancelBtn = UIUtil.CreateButtonStd(panel, '/scx_menu/small-btn/small', "<LOC _Cancel>", 16, nil, nil, "UI_Menu_Cancel_02")
    LayoutHelpers.AtRightTopIn(cancelBtn, panel, 30, 505)
    cancelBtn.OnClick = function(self, modifiers)
        KillDialog(true)
    end
    
    local okBtn = UIUtil.CreateButtonStd(panel, '/scx_menu/small-btn/small', "<LOC _Ok>", 16, nil, nil, nil, "UI_Opt_Yes_No")
    LayoutHelpers.LeftOf(okBtn, cancelBtn)
    okBtn.OnClick = function(self, modifiers)
        KillDialog(false)
    end
	
    local disableBtn = UIUtil.CreateButtonStd(panel, '/scx_menu/small-btn/small', "<LOC lobui_0599>Disable All", 16, 2)
    LayoutHelpers.AtLeftTopIn(disableBtn, panel, 30, 505)
	Tooltip.AddButtonTooltip(disableBtn, 'lob_disable_allmods')
    disableBtn.OnClick = function(self, modifiers)
		for index, control in scrollGroup.controlList do
			if control.active then
				control:Toggle()
			end
		end
    end

    UIUtil.MakeInputModal(panel, function() okBtn.OnClick(okBtn) end, function() cancelBtn.OnClick(cancelBtn) end)
end