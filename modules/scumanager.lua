local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local Button = import('/lua/maui/button.lua').Button
local ToolTip = import('/lua/ui/game/tooltip.lua')
local Prefs = import('/lua/user/prefs.lua')
local Grid = import('/lua/maui/grid.lua').Grid
local Combo = import('/lua/ui/controls/combo.lua').Combo
local Dragger = import('/lua/maui/dragger.lua').Dragger

local TooltipInfo = {
	Combat = {
		title = '<LOC SCUMAN_0001>Combat Upgrade Path',
		description = '<LOC SCUMAN_0002>Upgrades all idle unupgraded SCUs along the combat path. Right click to configure (select an SCU first!).',
	},
	Engineer = {
		title = '<LOC SCUMAN_0003>Engineer Upgrade Path',
		description = '<LOC SCUMAN_0004>Upgrades all idle unupgraded SCUs along the engineer path. Right click to configure (select an SCU first!).',
	},
}
	
local upgradeDefaultTable = {
	UEF = {
		Engineer = {
			'ResourceAllocation',
			'Shield',
			'ShieldGeneratorField'
		},
		Combat = {
			'HighExplosiveOrdnance',
			'AdvancedCoolingUpgrade',
			'Shield',
			'ShieldGeneratorField'
		},
	},
	CYBRAN = {
		Engineer = {
			'Switchback',
			'ResourceAllocation',
			'NaniteMissileSystem'
		},
		Combat = {
			'FocusConvertor',
			'EMPCharge',
			'SelfRepairSystem'
		},
	},
	AEON = {
		Engineer = {
			'EngineeringFocusingModule',
			'ResourceAllocation'
		},
		Combat = {
			'StabilitySuppressant',
			'Shield',
			'ShieldHeavy'
		},
	},
	SERAPHIM = {
		Combat = {
			'DamageStabilization',
			'Missile',
			'Overcharge'
		},
		Engineer = {
			'EngineeringThroughput',
			'Shield'
		}
	},
}
local upgradeTable = {}
--button container, for positioning externally
buttonGroup = false
local markerTable = {}

function Init()
	--add beat function to display markers
	import('/lua/ui/game/gamemain.lua').AddBeatFunction(ShowMarkers)
	--get the table of upgrades to use from prefs, or use default if prefs isn't available
	upgradeTable = Prefs.GetFromCurrentProfile("SCU_Manager_settings") or upgradeDefaultTable
	--create the button container
	buttonGroup = Group(GetFrame(0))
	LayoutHelpers.AtRightTopIn(buttonGroup, GetFrame(0))
	buttonGroup.Height:Set(10)
	buttonGroup.Width:Set(10)
	buttonGroup.Depth:Set(500)
	buttonGroup:DisableHitTest()
	--create the button for combat upgrades
	local combatButton = Button(buttonGroup, UIUtil.UIFile('/SCUManager/combat_up.dds'), UIUtil.UIFile('/SCUManager/combat_down.dds'), UIUtil.UIFile('/SCUManager/combat_over.dds'), UIUtil.UIFile('/SCUManager/combat_up.dds'), "UI_Menu_MouseDown_Sml", "UI_Menu_MouseDown_Sml")
	LayoutHelpers.AtRightTopIn(combatButton, buttonGroup)
	combatButton.Type = 'Combat'
	combatButton.HandleEvent = UpgradeClickFunc
	--create the button for engineer upgrades
	local EngineerButton = Button(buttonGroup, UIUtil.UIFile('/SCUManager/engineer_up.dds'), UIUtil.UIFile('/SCUManager/engineer_down.dds'), UIUtil.UIFile('/SCUManager/engineer_over.dds'), UIUtil.UIFile('/SCUManager/engineer_up.dds'), "UI_Menu_MouseDown_Sml", "UI_Menu_MouseDown_Sml")
	LayoutHelpers.Below(EngineerButton, combatButton)
	EngineerButton.Type = 'Engineer'
	EngineerButton.HandleEvent = UpgradeClickFunc
	buttonGroup:Hide()
end

function UpgradeClickFunc(self, event)
    if event.Type == 'MouseEnter' then
        if not self.tooltip then
            self.tooltip = ToolTip.CreateExtendedToolTip(self, TooltipInfo[self.Type].title, TooltipInfo[self.Type].description)
            LayoutHelpers.LeftOf(self.tooltip, self)
            self.tooltip:SetAlpha(0, true)
            self.tooltip:SetNeedsFrameUpdate(true)
            self.tooltip.OnFrame = function(self, deltaTime)
                self:SetAlpha(math.min(self:GetAlpha() + (deltaTime * 3), 1), true)
                if self:GetAlpha() == 1 then
                    self:SetNeedsFrameUpdate(false)
                end
            end
        end
    elseif event.Type == 'MouseExit' then
        if self.tooltip then
            self.tooltip:Destroy()
            self.tooltip = nil
        end
    elseif event.Type == 'ButtonPress' then
		if event.Modifiers.Left then
			ApplyUpgrades(self.Type)
		elseif event.Modifiers.Right then
			ConfigureUpgrades()
		end
	end
end

--configuration window
function ConfigureUpgrades()
	local window = Bitmap(GetFrame(0))
	window:SetTexture('/textures/ui/common/SCUManager/configwindow.dds')
	LayoutHelpers.AtRightTopIn(window, GetFrame(0), 100, 100)
	window.Depth:Set(1000)
	local buttonGrid = Grid(window, 48, 48)
	LayoutHelpers.AtLeftTopIn(buttonGrid, window, 10, 30)
	buttonGrid.Right:Set(function() return window.Right() - 10 end)
	buttonGrid.Bottom:Set(function() return window.Bottom() - 32 end)
	buttonGrid.Depth:Set(window.Depth() + 10)

	local factionChooser = Combo(window, 14, 4, nil, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
	--create the buttons for choosing acu type
	local combatButton = Checkbox(window, '/textures/ui/common/SCUManager/combat_up.dds', '/textures/ui/common/SCUManager/combat_sel.dds', '/textures/ui/common/SCUManager/combat_over.dds', '/textures/ui/common/SCUManager/combat_over.dds', '/textures/ui/common/SCUManager/combat_up.dds', '/textures/ui/common/SCUManager/combat_up.dds', "UI_Menu_MouseDown_Sml", "UI_Menu_MouseDown_Sml")
	local EngineerButton = Checkbox(window, '/textures/ui/common/SCUManager/engineer_up.dds', '/textures/ui/common/SCUManager/engineer_sel.dds', '/textures/ui/common/SCUManager/engineer_over.dds', '/textures/ui/common/SCUManager/engineer_over.dds', '/textures/ui/common/SCUManager/engineer_up.dds', '/textures/ui/common/SCUManager/engineer_up.dds', "UI_Menu_MouseDown_Sml", "UI_Menu_MouseDown_Sml")
	combatButton:SetCheck(true)
	
	LayoutHelpers.AtLeftTopIn(factionChooser, window, 6, 6)
	factionChooser.Width:Set(100)
	factionChooser:AddItems({'Aeon', 'Cybran', 'UEF', 'Seraphim'})
	factionChooser.OnClick = function(self, index, text)
		if combatButton:IsChecked() then
			LayoutGrid(buttonGrid, text, 'Combat')
		else
			LayoutGrid(buttonGrid, text, 'Engineer')
		end
	end
	
	
	
	LayoutHelpers.AtLeftTopIn(combatButton, window, 108, 6)
	LayoutHelpers.RightOf(EngineerButton, combatButton)
	combatButton.OnClick = function(self, modifiers)
		EngineerButton:SetCheck(false)
		combatButton:SetCheck(true)
		local index, fact = factionChooser:GetItem()
		LayoutGrid(buttonGrid, fact, 'Combat')
	end
	EngineerButton.OnClick = function(self, modifiers)
		combatButton:SetCheck(false)
		EngineerButton:SetCheck(true)
		local index, fact = factionChooser:GetItem()
		LayoutGrid(buttonGrid, fact, 'Engineer')
	end

	--the 6 icons showing which upgrades the scu will recieve
	buttonGrid.QueuedUpgrades = {}
	for i = 1, 6 do
		local index = i
		buttonGrid.QueuedUpgrades[index] = Bitmap(buttonGrid)
		buttonGrid.QueuedUpgrades[index]:SetTexture('/textures/ui/common/SCUManager/queueborder.dds')
		if index == 1 then
			LayoutHelpers.AtLeftTopIn(buttonGrid.QueuedUpgrades[index], window, 150, 4)
		else
			LayoutHelpers.RightOf(buttonGrid.QueuedUpgrades[index], buttonGrid.QueuedUpgrades[index-1])
		end
	end

	local okButton = UIUtil.CreateButtonStd(window, '/widgets/small', 'OK', 16)
	LayoutHelpers.AtLeftTopIn(okButton, window, 160, 123)
	okButton.OnClick = function(self)
		Prefs.SetToCurrentProfile("SCU_Manager_settings", upgradeTable)
		Prefs.SavePreferences()
		window:Destroy()
	end
	local cancelButton = UIUtil.CreateButtonStd(window, '/widgets/small', 'Cancel', 16)
	LayoutHelpers.AtLeftTopIn(cancelButton, window, 8, 123)
	cancelButton.OnClick = function(self)
		upgradeTable = Prefs.GetFromCurrentProfile("SCU_Manager_settings") or upgradeDefaultTable
		window:Destroy()
	end

	if GetSelectedUnits() then
		local faction = GetSelectedUnits()[1]:GetBlueprint().General.FactionName
		FactionIndexTable = {Aeon = 1, Cybran = 2, UEF = 3, Seraphim = 4}
		if FactionIndexTable[faction] then
			factionChooser:SetItem(FactionIndexTable[faction])
			LayoutGrid(buttonGrid, faction, 'Combat')
		else
			LayoutGrid(buttonGrid, 'Aeon', 'Combat')
		end
	else
		LayoutGrid(buttonGrid, 'Aeon', 'Combat')
	end
end

--shows available and current enhancements for an scu type
function LayoutGrid(buttonGrid, faction, scuType)
	--get the enhancements available to whichever scu is being edited
	local bpid = 'ual0301'
	if faction == 'Cybran' then
		bpid = 'url0301'
	elseif faction == 'UEF' then
		bpid = 'uel0301'
	elseif faction == 'Seraphim' then
		bpid = 'xsl0301'
	end
	local bp = __blueprints[bpid]
	local availableEnhancements = bp["Enhancements"]

	--clear the current enhancements, and add the new ones
	for i, v in buttonGrid.QueuedUpgrades do
		if v.Icon then
			v.Icon:Destroy()
			v.Icon = false
		end
		if upgradeTable[string.upper(faction)][scuType][i] then
			local enhancementName = upgradeTable[string.upper(faction)][scuType][i]
			v.Icon = CreateEnhancementButton(v, enhancementName, availableEnhancements[enhancementName], bpid, 22, faction, scuType, buttonGrid)
			v.Icon.enhancementName = enhancementName
			v.Icon.Index = i
			LayoutHelpers.AtCenterIn(v.Icon, v)
		end
	end

	--make a table of available enhancements, not showing any that are already owned, any that need a non queued prerequisite, or any where the slot is already used
	buttonGrid:DeleteAndDestroyAll(true)
	local visCols, visRows = buttonGrid:GetVisible()
	local currentRow = 1
	local currentCol = 1
	buttonGrid:AppendCols(visCols, true)
	buttonGrid:AppendRows(1, true)
	local index = 0
	local tempAvailableButtons = {}
	for name, data in availableEnhancements do
		local alreadyOwns = false
		for i, v in buttonGrid.QueuedUpgrades do
			if v.Icon.enhancementName then
				if v.Icon.enhancementName == name then
					alreadyOwns = true
				end
			end
		end
		if not alreadyOwns then
			if data['Slot'] and not string.find(name, 'Remove') then
				if data['Prerequisite'] then
					for i, v in buttonGrid.QueuedUpgrades do
						if v.Icon.enhancementName then
							if v.Icon.enhancementName == data['Prerequisite'] then
								table.insert(tempAvailableButtons, {Name = name, Enhancement = data})
							end
						end
					end
				else
					local slotUsed = false
					for i, v in buttonGrid.QueuedUpgrades do
						if v.Icon.enhancementName then
							if availableEnhancements[v.Icon.enhancementName].Slot == data['Slot'] then
								slotUsed = true
							end
						end
					end
					if not slotUsed then
						table.insert(tempAvailableButtons, {Name = name, Enhancement = data})
					end
				end
			end
		end
	end
	table.sort(tempAvailableButtons, function(up1, up2) return (up1.Enhancement.Slot .. up1.Name) <= (up2.Enhancement.Slot .. up2.Name) end)
	for i, data in tempAvailableButtons do
		local button = CreateEnhancementButton(buttonGrid, data.Name, data.Enhancement, bpid, 46, faction, scuType, buttonGrid)
		buttonGrid:SetItem(button, currentCol, currentRow, true)
		if currentCol < visCols then
			currentCol = currentCol + 1
		else
			currentCol = 1
			currentRow = currentRow + 1
			buttonGrid:AppendRows(1, true)
		end
	end
	buttonGrid:EndBatch()
end

function GetEnhancementPrefix(unitID, iconID)
    local prefix = ''
    if string.sub(unitID, 2, 2) == 'a' then
        prefix = '/game/aeon-enhancements/'..iconID
    elseif string.sub(unitID, 2, 2) == 'e' then
        prefix = '/game/uef-enhancements/'..iconID
    elseif string.sub(unitID, 2, 2) == 'r' then
        prefix = '/game/cybran-enhancements/'..iconID
    elseif string.sub(unitID, 2, 2) == 's' then
        prefix = '/game/seraphim-enhancements/'..iconID
    end
    return prefix
end

function CreateEnhancementButton(parent, enhancementName, enhancement, bpid, size, faction, scuType, buttonGrid)
    local tempBmpName = ""

    tempBmpName = GetEnhancementPrefix(bpid, enhancement.Icon)

    local button = false
	if( string.find( enhancementName, 'Remove' ) ) then
        button = Button(parent,
            UIUtil.UIFile(tempBmpName .. '_btn_sel.dds'),
            UIUtil.UIFile(tempBmpName .. '_btn_over.dds'),
            UIUtil.UIFile(tempBmpName .. '_btn_down.dds'),
            UIUtil.UIFile(tempBmpName .. '_btn_up.dds'),
            "UI_Enhancements_Click", "UI_Enhancements_Rollover")
    else
        button = Button(parent,
            UIUtil.UIFile(tempBmpName .. '_btn_up.dds'),
            UIUtil.UIFile(tempBmpName .. '_btn_over.dds'),
            UIUtil.UIFile(tempBmpName .. '_btn_down.dds'),
            UIUtil.UIFile(tempBmpName .. '_btn_sel.dds'),
            "UI_Enhancements_Click", "UI_Enhancements_Rollover")
    end
    button.Width:Set(size)
    button.Height:Set(size)

    button.OnClick = function(self, modifiers)
		if size == 46 then
			--if it's a main button, find the last free queue space and add the enhancement to the queue
			local nextfree = false
			for i, space in	parent.QueuedUpgrades do
				if not space.Icon then
					nextfree = i
					break
				end
			end
			if nextfree then
				parent.QueuedUpgrades[nextfree].Icon = CreateEnhancementButton(parent.QueuedUpgrades[nextfree], enhancementName, enhancement, bpid, 22, faction)
				LayoutHelpers.AtCenterIn(parent.QueuedUpgrades[nextfree].Icon, parent.QueuedUpgrades[nextfree])
				parent.QueuedUpgrades[nextfree].Icon.enhancementName = enhancementName
				parent.QueuedUpgrades[nextfree].Icon.Index = nextfree
				upgradeTable[string.upper(faction)][scuType][nextfree] = enhancementName
			end
		else
			--if not a main button then remove it from the queue and shift all the higher ones down a spot
			upgradeTable[string.upper(faction)][scuType][parent.Icon.Index] = nil
			local firstnil = false
			parent.Icon:Destroy()
			parent.Icon = false
			for i, v in buttonGrid.QueuedUpgrades do
				if firstnil then
					if v.Icon then
						buttonGrid.QueuedUpgrades[i-1].Icon = buttonGrid.QueuedUpgrades[i].Icon
						buttonGrid.QueuedUpgrades[i-1].Icon.Index = i-1
						upgradeTable[string.upper(faction)][scuType][i] = nil
						upgradeTable[string.upper(faction)][scuType][i-1] = buttonGrid.QueuedUpgrades[i].Icon.enhancementName
						buttonGrid.QueuedUpgrades[i].Icon:Destroy()
						buttonGrid.QueuedUpgrades[i].Icon = false
					end
				end
				if not v.Icon then
					firstnil = true
				end
			end
		end
		LayoutGrid(buttonGrid, faction, scuType)
    end

	--if there's a selection then show info for the enhancement
	local testUnit = GetSelectedUnits()
    button.HandleEvent = function(self, event)
		if testUnit then
	        if event.Type == 'MouseEnter' then
	            import('/lua/ui/game/unitviewDetail.lua').ShowEnhancement(enhancement, bpid, enhancement.Icon, GetEnhancementPrefix(bpid, enhancement.Icon), testUnit[1])
	        end
		end
		if event.Type == 'MouseExit' then
			import('/lua/ui/game/unitviewDetail.lua').Hide()
		end
        Button.HandleEvent(self, event)
    end
    button:UseAlphaHitTest(false)

    return button
end

--check what enhancements are already on the unit
function GetEnhancements(unit)
	local tempEntityID = unit:GetEntityId()
	local existingEnhancements = import('/lua/enhancementcommon.lua').GetEnhancements(tempEntityID)
	return existingEnhancements
end

--get any idle scu that isn't already a combat or engineer scu
function GetIdleSCUs()
	local idleEngineers = GetIdleEngineers()
	if idleEngineers then
		local idleSCUs = EntityCategoryFilterDown(categories.SUBCOMMANDER, idleEngineers)
		local returnTable = {}
		for i, unit in idleSCUs do
			--LOG(repr(unit:GetPosition()))
			if not GetEnhancements(unit) then
				table.insert(returnTable, unit)
			end
		end
		return returnTable
	else
		return false
	end
end

--check for idle scus, then start the relevant upgrade on them
function ApplyUpgrades(type)
	local SCUList = GetIdleSCUs()
	if SCUList then
		for i, v in SCUList do
			UpgradeSCU(v, type)
		end
	end
end

--tell the scu what type it now is, and upgrade it
function UpgradeSCU(unit, upgType)
	local faction = false
	if unit:IsInCategory('UEF') then
		faction = 'UEF'
	elseif unit:IsInCategory('AEON') then
		faction = 'AEON'
	elseif unit:IsInCategory('CYBRAN') then
		faction = 'CYBRAN'
	elseif unit:IsInCategory('SERAPHIM') then
		faction = 'SERAPHIM'
	end
	if faction then
		local upgList = upgradeTable[faction][upgType]
		if table.getsize(upgList) == 0 then
			return
		end
		for i, upgrade in upgList do
			--LOG('issuing ' ..upgrade)
			--get current command mode since issuing a unit command will cancel it so we need to reissue it
			local commandmode = import('/lua/ui/game/commandmode.lua')
			local currentCommand = commandmode.GetCommandMode()
			local orderData = {
				TaskName = "EnhanceTask",
				Enhancement = upgrade,
			}
			IssueUnitCommand({unit}, "UNITCOMMAND_Script", orderData, false)
			commandmode.StartCommandMode(currentCommand[1], currentCommand[2])
		end
		unit.SCUType = upgType
	end
end


--AUTOMATIC UPGRADE MARKER FUNCTIONS
--to stop show/hide being used constantly (may or may not be a bad thing...
local showing = false
--beat function to show all active markers
function ShowMarkers()
	if IsKeyDown('Shift') then
		if not showing then
			showing = true
			for i, marker in markerTable do
				marker:Show()
				marker:SetNeedsFrameUpdate(true)
			end
		end
	else
		if showing then
			showing = false
			for i, marker in markerTable do
				marker:Hide()
				marker:SetNeedsFrameUpdate(false)
			end
		end
	end
end

--create the dialog to choose upgrade marker type
local dialog = false
function CreateMarker()
	local position = GetMouseWorldPos()
	if not dialog then
		dialog = UIUtil.QuickDialog(GetFrame(0), 'Choose your upgrade type',  "Combat", function() PlaceMarker('Combat', position) dialog:Destroy() dialog = false end, "Engineer", function() PlaceMarker('Engineer', position) dialog:Destroy() dialog = false end, nil, nil, false)
	end
end

--create the marker
local index = 1
function PlaceMarker(upgradeType, position)
	local worldview = import('/lua/ui/game/worldview.lua').viewLeft
	markerTable[index] = Bitmap(GetFrame(0))
	markerTable[index]:SetTexture('/textures/ui/common/SCUManager/'..upgradeType..'_up.dds')
	markerTable[index].Depth:Set(100)
	markerTable[index].Left:Set(100)
	markerTable[index].Top:Set(100)
	markerTable[index].Index = index
	markerTable[index].position = position
	markerTable[index].upgradeType = upgradeType
	--move and destroy code
	markerTable[index].HandleEvent = function(self, event)
		if event.Type == 'ButtonPress' then
			if event.Modifiers.Right and event.Modifiers.Ctrl then
				KillThread(self.checkThread)
				local removeIndex = self.Index
				self:Destroy()
				self = false
				markerTable[removeIndex] = nil
			elseif event.Modifiers.Left then
				self:SetNeedsFrameUpdate(false)
				self.drag = Dragger()
				local moved = false
				GetCursor():SetTexture(UIUtil.GetCursor('MOVE_WINDOW'))
				self.drag.OnMove = function(dragself, x, y)
					self.Left:Set(function() return  (x - (self.Width()/2)) end)
					self.Top:Set(function() return  (y - (self.Height()/2)) end)
					moved = true
					dragself.x = x
					dragself.y = y
				end
				self.drag.OnRelease = function(dragself)
					self:SetNeedsFrameUpdate(true)
					if moved then
						self.position = GetMouseWorldPos()
					end
				end
				self.drag.OnCancel = function(dragself)
					self:SetNeedsFrameUpdate(true)
					self:EnableHitTest()
				end
				PostDragger(self:GetRootFrame(), event.KeyCode, self.drag)
				return true
			end
		end
	end
	--position each frame to keep same world position
	markerTable[index].OnFrame = function(self)
		self.Left:Set(function() return worldview:Project(self.position)[1]  - (self.Width()/2) +worldview.Left() end)
		self.Top:Set(function() return worldview:Project(self.position)[2] - (self.Height()/2) +worldview.Top() end)
	end
	markerTable[index]:Hide()
	markerTable[index].checkThread = ForkThread(UpgradeSCUAroundPoint, markerTable[index])
	index = index+1
end

function UpgradeSCUAroundPoint(marker)
	while true do
		local idleEngineers = GetIdleEngineers()
		if idleEngineers then
			local idleSCUs = EntityCategoryFilterDown(categories.SUBCOMMANDER, idleEngineers)
			for i, unit in idleSCUs do
				if not GetEnhancements(unit) then
					if VDist3(marker.position, unit:GetPosition()) < 11 then
						UpgradeSCU(unit, marker.upgradeType)
					end
				end
			end
		end
		WaitSeconds(4)
	end
end
