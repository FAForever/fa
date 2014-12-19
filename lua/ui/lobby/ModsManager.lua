--*****************************************************************************
--* File: lua/modules/ui/lobby/lobby.lua
--* Author: Xinnony
--* Summary: Mods Manager GUI
--*****************************************************************************

local Mods = import('/lua/mods.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local MultiLineText = import('/lua/maui/multilinetext.lua').MultiLineText
local Prefs = import('/lua/user/prefs.lua')

local GUI_OPEN = false

function UpdateClientModStatus(mod_selec)
	if GUI_OPEN then
		IsHost = false
		modstatus = mod_selec
		Refresh_Mod_List(false, true, true, IsHost, modstatus, false)
	end
end

function HostModStatus(availableMods)
    Mods.ClearCache() -- force reload of mod info to pick up changes on disk
    local my_all = Mods.AllSelectableMods()
    local my_sel = Mods.GetSelectedMods()
    local r = {}

    local function everyoneHas(uid)
        for peer, modset in availableMods do
            if not modset[uid] then
                return false
            end
        end
        return true
    end

    for uid,mod in my_all do
        if mod.ui_only or everyoneHas(uid) then
			if mod.ui_only then
				r[uid] = true
			else
				r[uid] = true
			end
        else
            r[uid] = false
        end
    end
    return r
end

function NEW_MODS_GUI(parent, IsHost, modstatus, availableMods)
	GUI = parent
	if IsHost then modstatus = false end
	GUI_ModsManager = Group(GUI)
        LayoutHelpers.AtCenterIn(GUI_ModsManager, GUI)
		--GUI_ModsManager.Depth:Set(GUI:GetTopmostDepth() + 100)
		GUI_ModsManager.Depth:Set(GetFrame(parent:GetRootFrame():GetTargetHead()):GetTopmostDepth() + 1)
		--LayoutHelpers.DepthOverParent(GUI_ModsManager, GUI, 10)
        --GUI_ModsManager.Depth:Set(998) -- :GetTopmostDepth() + 1
    local background = Bitmap(GUI_ModsManager, UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/Mod_Lobby.png'))
        GUI_ModsManager.Width:Set(background.Width)
        GUI_ModsManager.Height:Set(background.Height)
        LayoutHelpers.FillParent(background, GUI_ModsManager)
    local dialog2 = Group(GUI_ModsManager)
        dialog2.Width:Set(537)
        dialog2.Height:Set(548)
        LayoutHelpers.AtCenterIn(dialog2, GUI_ModsManager)
	-----------
    -- Title --
    local text0 = UIUtil.CreateText(dialog2, 'Mods Manager (Player)', 17, 'Arial')
        if IsHost then
			text0:SetText('Mods Manager (Host)')
		else
			text0:SetText('Mods Manager (Player)')
		end
		text0:SetColor('B9BFB9') -- 808080
        text0:SetDropShadow(true)
        LayoutHelpers.AtHorizontalCenterIn(text0, dialog2, 0)
        LayoutHelpers.AtTopIn(text0, dialog2, 10)
	---------------
    -- SubTitle --
    local text1 = UIUtil.CreateText(dialog2, '', 12, 'Arial')
        text1:SetColor('B9BFB9') -- 808080
        text1:SetDropShadow(true)
        LayoutHelpers.AtHorizontalCenterIn(text1, dialog2, 0)
        LayoutHelpers.AtTopIn(text1, dialog2, 26)
	--------------------
    -- SAVE button --
	local SaveButton = UIUtil.CreateButtonWithDropshadow(dialog2, '/BUTTON/medium/', "Ok", -1)
        LayoutHelpers.AtLeftIn(SaveButton, dialog2, 0)
        LayoutHelpers.AtBottomIn(SaveButton, dialog2, 10)
    -- SAVE LIST button --
	local SaveListButton = UIUtil.CreateButtonWithDropshadow(dialog2, '/BUTTON/small/', "Save List", -1)
        LayoutHelpers.AtRightIn(SaveListButton, dialog2, 0)
        LayoutHelpers.AtTopIn(SaveListButton, dialog2, 10)
		Tooltip.AddCheckboxTooltip(SaveListButton, {text='Save List', body='Save the currents selecteds Mods in a List'})
		SaveListButton:Disable()
	--------------------------
    -- LOAD LIST button --
	local LoadListButton = UIUtil.CreateButtonWithDropshadow(dialog2, '/BUTTON/small/', "Load List", -1)
        LayoutHelpers.AtLeftTopIn(LoadListButton, dialog2, 0, 10)
		Tooltip.AddCheckboxTooltip(LoadListButton, {text='Load List', body='Load a List of Mods'})
		LoadListButton:Disable()
	-------------------------------------
	-- CHECKBOX UI MOD FILTER --
	local cbox_UI = UIUtil.CreateCheckboxStdPNG(dialog2, '/RADIOBOX/radio')
        LayoutHelpers.AtLeftIn(cbox_UI, dialog2, 20+130+10)
		LayoutHelpers.AtBottomIn(cbox_UI, dialog2, 16)
        Tooltip.AddCheckboxTooltip(cbox_UI, {text='UI Mods', body='Hide or Show the UI Mods (actived UI Mods is always showed)'})
		cbox_UI_TEXT = UIUtil.CreateText(cbox_UI, 'UI Mods', 14, 'Arial')
            cbox_UI_TEXT:SetColor('B9BFB9')
            cbox_UI_TEXT:SetDropShadow(true)
            LayoutHelpers.AtLeftIn(cbox_UI_TEXT, cbox_UI, 25)
            LayoutHelpers.AtVerticalCenterIn(cbox_UI_TEXT, cbox_UI)
			cbox_UI:SetCheck(true, true)--isChecked, skipEvent)
	-----------------------------------------
	-- CHECKBOX GAME MOD FILTER --
	local cbox_GAME = UIUtil.CreateCheckboxStdPNG(dialog2, '/RADIOBOX/radio')
        LayoutHelpers.AtLeftIn(cbox_GAME, dialog2, 20+130+100)
		LayoutHelpers.AtBottomIn(cbox_GAME, dialog2, 16)
        Tooltip.AddCheckboxTooltip(cbox_GAME, {text='GAME Mods', body='Hide or Show the GAME Mods (actived GAME Mods is always showed)'})
		cbox_GAME_TEXT = UIUtil.CreateText(cbox_GAME, 'GAME Mods', 14, 'Arial')
            cbox_GAME_TEXT:SetColor('B9BFB9')
            cbox_GAME_TEXT:SetDropShadow(true)
            LayoutHelpers.AtLeftIn(cbox_GAME_TEXT, cbox_GAME, 25)
            LayoutHelpers.AtVerticalCenterIn(cbox_GAME_TEXT, cbox_GAME)
			cbox_GAME:SetCheck(false, true)--isChecked, skipEvent)
	----------------------------------------------
	-- CHECKBOX HIDE UNSELECTABLE MOD --
	local cbox_Act = UIUtil.CreateCheckboxStdPNG(dialog2, '/CHECKBOX/radio')
        LayoutHelpers.AtLeftIn(cbox_Act, dialog2, 20+130+120+100)
		LayoutHelpers.AtBottomIn(cbox_Act, dialog2, 23)
        Tooltip.AddCheckboxTooltip(cbox_Act, {text='Hide Unselectable', body='Hide all mods cannot be enabled because is unselectable or other player(s) not have the mod'})
		cbox_Act_TEXT = UIUtil.CreateText(cbox_Act, 'Hide Unselectable', 14, 'Arial')
            cbox_Act_TEXT:SetColor('B9BFB9')
            cbox_Act_TEXT:SetDropShadow(true)
            LayoutHelpers.AtLeftIn(cbox_Act_TEXT, cbox_Act, 25)
            LayoutHelpers.AtVerticalCenterIn(cbox_Act_TEXT, cbox_Act)
			cbox_Act:SetCheck(true, true)--isChecked, skipEvent)
	----------------------------------------------
	-- CHECKBOX LITTLE VIEW MOD LIST --
	local cbox_Act2 = UIUtil.CreateCheckboxStdPNG(dialog2, '/CHECKBOX/radio')
        LayoutHelpers.AtLeftIn(cbox_Act2, dialog2, 20+130+120+100)
		LayoutHelpers.AtBottomIn(cbox_Act2, dialog2, 6)
        Tooltip.AddCheckboxTooltip(cbox_Act2, {text='Little View', body='See another mod list display'})
		cbox_Act_TEXT2 = UIUtil.CreateText(cbox_Act2, 'Little View', 14, 'Arial')
            cbox_Act_TEXT2:SetColor('B9BFB9')
            cbox_Act_TEXT2:SetDropShadow(true)
            LayoutHelpers.AtLeftIn(cbox_Act_TEXT2, cbox_Act2, 25)
            LayoutHelpers.AtVerticalCenterIn(cbox_Act_TEXT2, cbox_Act2)
			local XinnoModsManagerLittleView = Prefs.GetFromCurrentProfile('XinnoModsManagerLittleView') or false
			if XinnoModsManagerLittleView then
				cbox_Act2:SetCheck(true, true)--isChecked, skipEvent)
			else
				cbox_Act2:SetCheck(false, true)--isChecked, skipEvent)
			end
	--
	--
	if IsHost then
		cbox_GAME:Enable()
		cbox_Act:Enable()
	else
		cbox_GAME:Disable()
		cbox_Act:Disable()
		cbox_GAME_TEXT:Disable()
		cbox_Act_TEXT:Disable()
		cbox_GAME:SetCheck(false, true)
		cbox_Act:SetCheck(false, true)
		cbox_GAME_TEXT:SetColor('5C5F5C')
		cbox_Act_TEXT:SetColor('5C5F5C')
	end
	cbox_GAME.OnCheck = function(self, checked)
		if checked then
			cbox_UI:SetCheck(false, true)
			if IsHost then
				save_mod()
				swiffer()
				Refresh_Mod_List(checked, cbox_UI:IsChecked(), cbox_Act:IsChecked(), IsHost, modstatus, cbox_Act2:IsChecked())
			end
		else
			cbox_GAME:SetCheck(true, true)
		end
	end
	cbox_UI.OnCheck = function(self, checked)
		if checked then
			cbox_GAME:SetCheck(false, true)
			save_mod()
			swiffer()
			Refresh_Mod_List(cbox_GAME:IsChecked(), checked, cbox_Act:IsChecked(), IsHost, modstatus, cbox_Act2:IsChecked())
		else
			cbox_UI:SetCheck(true, true)
		end
	end
	cbox_Act.OnCheck = function(self, checked)
		if IsHost then
			save_mod()
			swiffer()
			Refresh_Mod_List(cbox_GAME:IsChecked(), cbox_UI:IsChecked(), checked, IsHost, modstatus, cbox_Act2:IsChecked())
		end
	end
	cbox_Act2.OnCheck = function(self, checked)
		save_mod()
		swiffer()
		Refresh_Mod_List(cbox_GAME:IsChecked(), cbox_UI:IsChecked(), cbox_Act:IsChecked(), IsHost, modstatus, checked)
		Prefs.SetToCurrentProfile('XinnoModsManagerLittleView', checked)
	end
	-------------
    -- Credit --
    local text99 = UIUtil.CreateText(dialog2, 'Xinnony', 9, 'Arial')
        text99:SetColor('808080')
        text99:SetDropShadow(true)
        LayoutHelpers.AtRightIn(text99, dialog2, 0)
        LayoutHelpers.AtBottomIn(text99, dialog2, 2)
	-----------------
    -- MOD LIST --
	local scrollGroup = Group(dialog2)
    scrollGroup.Width:Set(519)
    scrollGroup.Height:Set(450)
    LayoutHelpers.AtLeftTopIn(scrollGroup, dialog2, 0, 47)
    UIUtil.CreateVertScrollbarFor2(scrollGroup)
	---
	---
	scrollGroup.controlList = {}
	scrollGroup.top = 1
	numElementsPerPage = 6
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
	SaveButton.OnClick = function(self)
		save_mod()
		GUI_OPEN = false
		import('/lua/ui/lobby/lobby.lua').OnModsChanged(selectedMods)
		GUI_ModsManager:Destroy()
		return selectedMods
	end
	--
	function count_mod_UI_actived()
		count_ui = 0
		for k, v in scrollGroup.controlList do
			if v.actived and v.modInfo.ui_only then
				count_ui = count_ui + 1
			end
		end
		--LOG('Count UI : '..count_ui)
		return count_ui
	end
	function count_mod_SIM_actived()
		count_sim = 0
		for k, v in scrollGroup.controlList do
			if v.actived and not v.modInfo.ui_only then
				count_sim = count_sim + 1
			end
		end
		--LOG('Count SIM : '..count_sim)
		return count_sim
	end
	function swiffer()
		for k, v in scrollGroup.controlList do
			v:Destroy()
		end
	end
	function save_mod()
		selectedMods = {}
        for index, control in scrollGroup.controlList do
            if control.actived then
                --LOG('Save : '..control.modInfo.name)
				selectedMods[control.modInfo.uid] = true
			end
		end
		import('/lua/mods.lua').SetSelectedMods(selectedMods)
	end
	--
	function Refresh_Mod_List(cbox_GAME, cbox_UI, cbox_Act, IsHost, modstatus, cbox_Act2)
		index = 0
		exclusiveMod = false
		current_list = {}
		scrollGroup.controlList = {}
		local allmods = Mods.AllSelectableMods()
		local selmods = Mods.GetSelectedMods()
		local unselmods = Mods.GetUnSelectedMods()
		local GetUI_Activedmods = Mods.GetUiMods() -- Active UI
		local GetUI_Unactivedmods = Mods.GetUiMods(unselmods) -- Active + Unactive UI
		local GetSIM_Activedmods = Mods.GetGameMods() -- Active SIM
		local GetSIM_Unactivedmods = Mods.GetGameMods(unselmods) -- Active + Unactive SIM
		
		--local function tablelength(T)
			--local count = 0
			--for _ in pairs(T) do count = count + 1 end
			--return count
		--end
		--LOG('MOD1> '..tablelength(allmods)..' < All Mods')
		--LOG('MOD2> '..tablelength(selmods)..' < Selected Mod')
		--LOG('MOD3> '..tablelength(unselmods)..' < UnSelected Mod')
		--LOG('MOD4> '..table.getn(GetSIM_Activedmods)..' < Sim ActiveMod')
		--LOG('MOD5> '..table.getn(GetSIM_Unactivedmods)..' < Sim UnActiveMod')
		--LOG('MOD6> '..table.getn(GetUI_Activedmods)..' < Ui ActiveMod')
		--LOG('MOD7> '..table.getn(GetUI_Unactivedmods)..' < Ui UnActiveMod')
		
		-- CREE UNE LIST TEMPORAIRE
		if not IsHost then
			for k, v in allmods do
				if modstatus[v.uid] then
					table.insert(current_list, v)
				end
			end
			for k, v in GetUI_Activedmods do
				table.insert(current_list, v)
			end
			if cbox_UI then
				--LOG('>> cbox_UI = TRUE')
				for k, v in GetUI_Unactivedmods do
					--if v.hidden != true then
						table.insert(current_list, v)
					--end
				end
			end
		else -- IF IS HOST
			for k, v in GetSIM_Activedmods do
				table.insert(current_list, v)
			end
			for k, v in GetUI_Activedmods do
				table.insert(current_list, v)
			end
			if cbox_GAME and IsHost then
				for k, v in GetSIM_Unactivedmods do
					--if v.hidden != true then
					table.insert(current_list, v)
				end
			end
			if cbox_UI then
				for k, v in GetUI_Unactivedmods do
					--if v.hidden != true then
					--LOG('Mod : '..v.modInfo.name..', selectable : '..tostring(v.modInfo.selectable))
					table.insert(current_list, v)
				end
			end
		end
		
		-- Remove Unselectable and mod not available with all players
		-- BUG ? (cause an error line 364 "return a.name < b.name")
		if cbox_Act then
			for i, v in current_list do
				if not v.selectable or availableMods[v.uid] == v.uid then
					table.remove(current_list, i)
					i = i - 1 -- For sure check the next mod
				end
			end
		end
		
		-- Remove Selected Mods
		--if cbox_Act2 then
			--table.insert(current_list, 1)
			--for i, v in current_list do
				--LOG('>> '..i..' > '..tostring(v.uid)..' == '..tostring(selmods[v.uid])..' ('..v.name..')')
				--if selmods[v.uid] then
					--LOG('>> Finded '..i..' ('..v.name..')')
					--table.remove(current_list, i)
					--i = i - 1 -- For sure check the next mod
				--end
				--LOG('>> End '..i..' ('..v.name..')')
			--end
			--table.remove(current_list, 1)
		--end
		
		-- TRIE LES MOD ACTIFS EN HAUT ET LE RESTE ALPHABETIQUEMENT
		table.sort(current_list, function(a,b) 
			if selmods[a.uid] and selmods[b.uid] then
				return a.name < b.name
			elseif selmods[a.uid] or selmods[b.uid] then
				return selmods[a.uid] or false
			else
				return a.name < b.name
			end
		end)
		
		-- CREE LES MOD DANS LA GUI ET SELEC LES ACTIFS
		for k, v in current_list do
			if not cbox_Act2 then
				table.insert(scrollGroup.controlList, CreateListElementtt(scrollGroup, v, k, false))
			else
				table.insert(scrollGroup.controlList, CreateListElementtt(scrollGroup, v, k, true))
			end
			if IsHost and selmods[v.uid] then
				scrollGroup.controlList[k].actived = true
				scrollGroup.controlList[k].type:SetColor('101010') -- Noir
				if v.ui_only then
					scrollGroup.controlList[k].type:SetText('UI MOD ACTIVED')
					scrollGroup.controlList[k].bg:SetTexture('/textures/ui/common/MODS/enable_ui.png')
				else
					scrollGroup.controlList[k].type:SetText('GAME MOD ACTIVED')
					scrollGroup.controlList[k].bg:SetTexture('/textures/ui/common/MODS/enable_game.png')
				end
			elseif not IsHost and modstatus[v.uid] and not v.ui_only then
				scrollGroup.controlList[k].actived = true
				scrollGroup.controlList[k].type:SetColor('101010') -- Noir
				scrollGroup.controlList[k].type:SetText('GAME MOD ACTIVED')
				scrollGroup.controlList[k].bg:SetTexture('/textures/ui/common/MODS/enable_game.png')
			elseif not IsHost and selmods[v.uid] and v.ui_only then
				scrollGroup.controlList[k].actived = true
				scrollGroup.controlList[k].type:SetColor('101010') -- Noir
				scrollGroup.controlList[k].type:SetText('UI MOD ACTIVED')
				scrollGroup.controlList[k].bg:SetTexture('/textures/ui/common/MODS/enable_ui.png')
			end
			if scrollGroup.controlList[k].modInfo.exclusive and selmods[v.uid] then
				exclusiveMod = true
				scrollGroup.controlList[k].actived = true
				scrollGroup.controlList[k].type:SetColor('101010') -- Noir
				scrollGroup.controlList[k].type:SetText('EXCLUSIF MOD ACTIVED')
				scrollGroup.controlList[k].bg:SetTexture('/textures/ui/common/MODS/enable_excusif.png')
			end
		end
		
		text1:SetText(count_mod_SIM_actived()..' GAME Mods and '..count_mod_UI_actived()..' UI Mods actived')
		
		--function refresh_item() -- Not work for the moment
			--for i, c in scrollGroup.controlList do
				--if not c.modInfo.ui_only then
					--c:Destroy()
					--c = nil
				--end
			--end
		--end
		--refresh_item()
		
		local function UNActiveMod(the_mod)
			the_mod.actived = false
			the_mod.type:SetColor('B9BFB9') -- Gris
			the_mod.bg:SetTexture('/textures/none.png')
			the_mod.bg0:SetTexture('/textures/none.png')
			if the_mod.ui then -- IF UI MOD
				the_mod.type:SetText('UI MOD')
			else
				the_mod.type:SetText('GAME MOD')
			end
		end
		
		local function ActiveExclusifMod(the_exclusif_mod)
			local function FUNC_RUN()
				LOG('>> ActiveExclusifMod')
				exclusiveMod = true
				for index, control in scrollGroup.controlList do
					if control.actived and control != the_exclusif_mod then
						UNActiveMod(control)
					end
				end
				the_exclusif_mod.actived = true
				the_exclusif_mod.type:SetColor('101010') -- Noir
				the_exclusif_mod.type:SetText('EXCLUSIF MOD ACTIVED')
				the_exclusif_mod.bg:SetTexture('/textures/ui/common/MODS/enable_excusif.png')
				PlaySound(Sound({Cue = "UI_Mod_Select", Bank = "Interface",}))
				text1:SetText(count_mod_SIM_actived()..' GAME Mods and '..count_mod_UI_actived()..' UI Mods actived')
			end
			UIUtil.QuickDialog(GUI_ModsManager, 
				"<LOC uimod_0010>The mod you have requested is marked as exclusive. If you select this mod, all other mods will be disabled. Do you wish to enable this mod?",
				"<LOC _Yes>", FUNC_RUN,
				"<LOC _No>")
		end
		
		local function ActiveMod(the_mod)
			local depends = Mods.GetDependencies(the_mod.modInfo.uid)
			local skipExit = false
			local allMods = Mods.AllMods()
			
			if depends.missing then -- DEPENDENCIE : MOD NOT EXIST
				--LOG('MISSING Dependencies')
				local boxText = LOC("<LOC uimod_0012>The requested mod can not be enabled as it requires the following mods that you don't currently have installed:\n\n")
				for uid, v in depends.missing do
					local name
					if the_mod.modInfo.requiresNames and the_mod.modInfo.requiresNames[uid] then
						name = the_mod.modInfo.requiresNames[uid]
					else
						name = uid
					end
					boxText = boxText .. name .. "\n"
					--LOG('Mod missing : '..name)
				end
				UIUtil.QuickDialog(GUI_ModsManager, boxText, "<LOC _Ok>")
				skipExit = true
			
			elseif depends.requires then -- DEPENDENCIE : MOD EXIST
				--LOG('REQUIRES Dependencies')
				local Tname = {}
				for uid, v in depends.requires do
					local name
					if the_mod.modInfo.requiresNames and the_mod.modInfo.requiresNames[uid] then
						table.insert(Tname, uid)
						name = the_mod.modInfo.requiresNames[uid]
					else
						table.insert(Tname, uid)
						name = uid
					end
					--LOG('Mod requires : '..name)
				end
				for i, c in Tname do -- Check if the Mod is listed in the GUI
					exist = false
					for index, control in scrollGroup.controlList do -- Enable dependencies mod
						if control.modInfo.uid == c then
							exist = true
							--LOG('-> '..control.modInfo.name)
							control.actived = true
							if control.ui then -- IF UI MOD
								control.type:SetColor('101010') -- Noir
								control.type:SetText('UI MOD ACTIVED')
								control.bg:SetTexture('/textures/ui/common/MODS/enable_ui.png')
							else -- IF SIM MOD
								control.type:SetColor('101010') -- Noir
								control.type:SetText('GAME MOD ACTIVED')
								control.bg:SetTexture('/textures/ui/common/MODS/enable_game.png')
							end
						end
					end
					if not exist then -- IF The mod is not listed in the GUI, Create the mod in the list
						--LOG('Try add hidden mod : '..allMods[c].name)
						--table.insert(scrollGroup.controlList, CreateListElementtt(scrollGroup, allMods[c], table.getn(scrollGroup.controlList)+1))
						table.insert(scrollGroup.controlList, the_mod.pos+1, CreateListElementtt(scrollGroup, allMods[c], the_mod.pos, false))
						control = scrollGroup.controlList[the_mod.pos+1]
						--LOG('Try enable hidden mod : '..control.modInfo.name)
						--control.modInfo.hidden = false
						control.actived = true
						if control.ui then -- IF UI MOD
							control.type:SetColor('101010') -- Noir
							control.type:SetText('UI MOD ACTIVED')
							control.bg:SetTexture('/textures/ui/common/MODS/enable_ui.png')
						else -- IF SIM MOD
							control.type:SetColor('101010') -- Noir
							control.type:SetText('GAME MOD ACTIVED')
							control.bg:SetTexture('/textures/ui/common/MODS/enable_game.png')
						end
						EVENT_Click()
						scrollGroup:CalcVisible()
					end
				end
			
			elseif depends.conflicts then -- DEPENDENCIE : MOD CONFLICTS
				--LOG('CONFLICTS Dependencies')
				local boxText = LOC("You can't enable this Mod because you need disable this mods for prevent conflict :\n")
				local conflict = false
				local Tname = {}
				for uid, v in depends.conflicts do
					local name
					if the_mod.modInfo.requiresNames and the_mod.modInfo.requiresNames[uid] then
						table.insert(Tname, uid)
						name = the_mod.modInfo.requiresNames[uid]
					else
						table.insert(Tname, uid)
						name = uid
					end
					--LOG('Mod conflicts : '..name)
				end
				for i, c in Tname do -- Get name of the conflict mod ### Normalement on peut toujours get le name du mod, a virée ?
					if allMods[c].name then
						boxText = boxText .. allMods[c].name .. '\n'
					else
						boxText = boxText .. '- '.. c .. '\n'
					end
				end
				for index, control in scrollGroup.controlList do -- Check if the conflict mod is actived or not
					for i, c in Tname do
						if control.modInfo.uid == c and control.actived then
							conflict = true
						end
					end
				end
				--
				if conflict then -- Mod conflict is actived, warning !
					UIUtil.QuickDialog(GUI_ModsManager, boxText, "<LOC _Ok>")
					skipExit = true
				else -- Mod conflict is not actived, don't worries !
					-- LE MOD EN CONFLICT N'EST PAS ACTIVER, PAS DE CONFLICT ALORS
				end
			end
			
			if not skipExit then
				the_mod.actived = true
				if the_mod.ui then -- IF UI MOD
					the_mod.type:SetColor('101010') -- Noir
					the_mod.type:SetText('UI MOD ACTIVED')
					the_mod.bg:SetTexture('/textures/ui/common/MODS/enable_ui.png')
				else -- IF SIM MOD
					the_mod.type:SetColor('101010') -- Noir
					the_mod.type:SetText('GAME MOD ACTIVED')
					the_mod.bg:SetTexture('/textures/ui/common/MODS/enable_game.png')
				end
			end
		end
		
		local function ActiveModAndRemoveExclusifMod(the_mod)
			local function FUNC_RUN()
				LOG('>> ActiveModAndRemoveExclusifMod')
				exclusiveMod = false
				for index, control in scrollGroup.controlList do
					if control.actived and control.modInfo.exclusive then
						UNActiveMod(control)
					end
				end
				ActiveMod(the_mod)
				PlaySound(Sound({Cue = "UI_Mod_Select", Bank = "Interface",}))
				text1:SetText(count_mod_SIM_actived()..' GAME Mods and '..count_mod_UI_actived()..' UI Mods actived')
			end
			UIUtil.QuickDialog(GUI_ModsManager,
				"<LOC uimod_0011>You currently have an exclusive mod selected, do you wish to deselect it?",
				"<LOC _Yes>", FUNC_RUN,
				"<LOC _No>")
		end
		
		-- EVENT LORS D'UN CLICK SUR MOD
		function EVENT_Click()
			for i, v in scrollGroup.controlList do
				v.HandleEvent = function(self, event)
					if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
						--LOG('CLICK ON '..self.pos..' ('..tostring(self.actived)..')')
						if not IsHost and not self.ui then
							-- You can't enable Game Mod if you not the Host
						else
							if not self.modInfo.selectable then
								self.type:SetColor('B9BFB9') -- Gris
								self.type:SetText('The MOD is not Selectable')
								self.bg:SetTexture('/textures/ui/common/MODS/enable_not.png')
							elseif not availableMods[self.modInfo.uid] and not self.ui then
								-- If other player not have the mod
								self.type:SetColor('B9BFB9') -- Gris
								self.type:SetText('Player(s) not have this MOD')
								self.bg:SetTexture('/textures/ui/common/MODS/enable_not.png')
							else
								-- If all player have the mod
								if self.actived then
									-- If mod is actived
									UNActiveMod(self)
								else
									-- If mod is unactived
									if self.modInfo.exclusive then
										-- If the mod is exclusif
										ActiveExclusifMod(self)
									else
										-- If the mod is not exclusif
										if exclusiveMod then 
											-- If one mod exclusif is actived, remove this exclusive mod.
											ActiveModAndRemoveExclusifMod(self)
										else
											-- Active the mod normaly
											ActiveMod(self)
										end
									end
								end
								PlaySound(Sound({Cue = "UI_Mod_Select", Bank = "Interface",}))
								text1:SetText(count_mod_SIM_actived()..' GAME Mods and '..count_mod_UI_actived()..' UI Mods actived')
							end
						end
					elseif event.Type == 'MouseEnter' then
						if self.actived then
							self.bg0:SetTexture('/textures/ui/common/MODS/line_black.png')
						else
							self.bg0:SetTexture('/textures/ui/common/MODS/line_blank.png')
						end
					elseif event.Type == 'MouseExit' then
						self.bg0:SetTexture('/textures/none.png')
					end
				end
			end
		end
		EVENT_Click()
		
		-- REFRESH SCROLL
		scrollGroup.top = 1
		scrollGroup:CalcVisible()
	end
	Refresh_Mod_List(false, true, true, IsHost, modstatus, cbox_Act2:IsChecked())
	--
	scrollGroup.HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            local lines = 1
            if event.WheelRotation > 0 then
                lines = -1
            end
            self:ScrollLines(nil, lines)
        end
    end
	--
	GUI_OPEN = true
end





-- HAUTEUR DUN MOD = 75 * 6
-- Pour 2 article de plus, rajouter +150pixel au Skin UI
-- AJOUTER UN CBOX Favorites, qui permetera de montrer les Favoris (les favoris sont ajoutable grace a une petite etoile sur chaque Mod)



function CreateListElementtt(parent, modInfo, Pos, little)
	local group = Group(parent)
		if little then
			numElementsPerPage = 22
			--group.Height:Set(20)
			--group.Height:Set(function() return parent.Height() / numElementsPerPage  end)
			group.Height:Set(20)
		else
			numElementsPerPage = 6
			group.Height:Set(function() return parent.Height() / numElementsPerPage  end)
		end
		group.Width:Set(parent.Width)
		LayoutHelpers.AtLeftTopIn(group, parent, 0, group.Height()*(Pos-1))
	--
	group.pos = Pos
	group.modInfo = modInfo
	group.actived = false
	--
	group.bg = Bitmap(group, '/textures/none.png')
		group.bg.Height:Set(group.Height())
		group.bg.Width:Set(group.Width())
		LayoutHelpers.AtLeftTopIn(group.bg, group, 0, 0)--group.bg.Height()*(Pos-1))
	--
	group.bg0 = Bitmap(group, '/textures/none.png')
		group.bg0.Height:Set(group.Height())
		group.bg0.Width:Set(group.Width())
		LayoutHelpers.AtLeftTopIn(group.bg0, group, 0, 0)--group.bg.Height()*(Pos-1))
	--
	group.icon = Bitmap(group, modInfo.icon)
		if little then
			group.icon.Height:Set(20)
			group.icon.Width:Set(20)
			LayoutHelpers.AtLeftTopIn(group.icon, group, 0, 0)
		else
			group.icon.Height:Set(56)
			group.icon.Width:Set(56)
			LayoutHelpers.AtLeftTopIn(group.icon, group, 10, 10)
		end
	--
	group.name = UIUtil.CreateText(group, modInfo.name, 14, UIUtil.bodyFont)
		group.name:SetColor('B9BFB9') -- Gris
		if little then
			LayoutHelpers.AtLeftTopIn(group.name, group, 30, 1)
		else
			LayoutHelpers.AtLeftTopIn(group.name, group, 80, 10)
		end
		group.name:SetDropShadow(true)
	--
	if not little then
		group.desc = MultiLineText(group, UIUtil.bodyFont, 12, 'B9BFB9')--UIUtil.fontColor)
			LayoutHelpers.AtLeftTopIn(group.desc, group, 80, 30)
			group.desc.Height:Set(40) -- 40
			group.desc.Width:Set(group.Width()-86)
			group.desc:SetText(modInfo.description)
	end
	--
	group.type = UIUtil.CreateText(group, '', 10, 'Arial Narrow Bold')--'Arial Black')--UIUtil.fontColor)
		group.type:SetColor('B9BFB9') -- Gris
		if modInfo.ui_only then
			group.type:SetText('UI MOD')
			--group.type:SetColor('101010') -- Noir
			group.type:SetFont('Arial Black', 11)
			group.ui = true
		else
			group.type:SetText('GAME MOD')
			--group.type:SetColor('101010')
			group.type:SetFont('Arial Black', 11)
			group.ui = false
		end
		if little then
			LayoutHelpers.AtRightTopIn(group.type, group, 12, 2)
		else
			LayoutHelpers.AtRightTopIn(group.type, group, 12, 4)
		end
		--group.type:SetDropShadow(true)
	--
	if little then
		Tooltip.AddControlTooltip(group.bg, {text=modInfo.name, body=modInfo.description})
	end
	--
	return group
end