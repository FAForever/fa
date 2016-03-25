-- ******************************************************************************************
-- * File		: lua/modules/ui/lobby/UnitsManager.lua 
-- * Authors	: Gas Powered Games, FAF Community, HUSSAR
-- * Summary  	: Contains UI for managing unit and enhancement restrictions
-- * 
-- ******************************************************************************************
local Mods     = import('/lua/mods.lua')	
local UIUtil   = import('/lua/ui/uiutil.lua')
local Utils    = import('/lua/system/utils.lua')
local Tooltip  = import('/lua/ui/game/tooltip.lua')
local Group    = import('/lua/maui/group.lua').Group
local Popup    = import('/lua/ui/controls/popups/popup.lua').Popup
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local Bitmap   = import('/lua/maui/bitmap.lua').Bitmap
local Grid     = import('/lua/maui/grid.lua').Grid 
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local UnitsAnalyzer   = import('/lua/ui/lobby/UnitsAnalyzer.lua')
local UnitsRestrictions = import('/lua/ui/lobby/UnitsRestrictions.lua')
local blueprints = {} 

-- stores info about preset restrictions 
local presets = {}
presets.PerRow   = 35 -- determines number of presets' icons per row
presets.Data     = UnitsRestrictions.GetPresetsData()
presets.Order    = UnitsRestrictions.GetPresetsOrder()
 
local factions = {} 
local unitsGrid = nil
local presetsGrid = nil

-- stores references to checkboxes for quick toggling of Presets and Units 
local checkboxes = { Units = {}, Presets = {} }
-- store current IDs of units restricted by Presets and Custom selection
local restrictions = { Custom = {}, Presets = {}, Stats = {} }
 
local statsText = nil 
local unitFontSize = 13
local dialogMaxWidth = 1920  -- used for determing scaling of icons/fonts
local dialogMaxHeight = 1200 -- used for determing scaling of icons/fonts
local dialogScrollWidth = 15
local factionsCount = 4  -- TODO increase when NOMADS added to FAF
local factionsGroups = 9 -- e.g. NAVAL, AIR, LAND, FACTORIES, ECO, SUPPORT, DEFENCES, COMMANDSER, enhancements
local cellMax  = (factionsCount * factionsGroups) + 1 
local cellSize = 0 -- calculated when dialog is created

-- this table contains blueprint's categories or IDs for ordering units in grid columns, e.g. 
-- units matching first entry will be placed as first item in a column
-- if two units match the first entry then the next entry is used for comparing
local sortBy = {
    -- order bluprints first by their TECH level and then WEAPON categories
    TECH = { 
         'TECH1', 
         'TECH2',
         'TECH3',
         'EXPERIMENTAL',
         'ORBITALSYSTEM',
         'SATELLITE',  
         -- Additional sorting
         'BOT', 
         'DIRECTFIRE', 
         'ANTIAIR',
         'TRANSPORTATION', 
         'GROUNDATTACK',
         'ANTINAVY',
         'SUBMERSIBLE',
         'INDIRECTFIRE',
         'ARTILLERY',
    },
    -- order bluprints first by their WEAPON categories and then TECH level
    WEAPON = {
         'DIRECTFIRE', 
         'ANTIAIR',
         'TRANSPORTATION',   
         'GROUNDATTACK',
         'ANTINAVY',
         'SUBMERSIBLE',
         'BOMBER',
         'TACTICALMISSILEPLATFORM',
         'ANTIMISSILE',
         'NUKE',
         'INDIRECTFIRE',
         'ARTILLERY',
         'TECH1', 
         'TECH2',
         'TECH3',
         'EXPERIMENTAL',
    },
    ENGINEERING = { 
     --'STRUCTURE',	
     'GATE',	
     'SORTCONSTRUCTION',
     'NAVAL',
     'AIR',  
     'LAND',
     'ENGINEERSTATION', 
     'ENGINEER',  
     'TECH1', 
     'TECH2',
     'TECH3',
     'RESEARCH', 	-- FACTORY HQ
     'SUPPORTFACTORY',
     'POD',
     --'FACTORY',	
    },
    ECO = { 
     'EXPERIMENTAL',
     'MASSFABRICATION', 
     'MASSEXTRACTION',
     'MASSSTORAGE',
     'ENERGYPRODUCTION',
     'ENERGYSTORAGE',
     'HYDROCARBON',
    },
    SUPPORT = { 
     'AIRSTAGINGPLATFORM',
     'SONAR',
     'RADAR',
     'OMNI',
     'OPTICS', 
     'COUNTERINTELLIGENCE',
     'WALL', 
     'SHIELD', 
    },
    UPGRADES = { 
     'COMMAND', 
     'SUBCOMMANDER', 
     'UPGRADE',             -- created in UnitsAnalyzer
     'ISPREENHANCEDUNIT',  
     --NOTE this order ensure that ACU/SCU have similar upgades next to each other
     'Overcharge',
     'EngineeringThroughput',
     'ResourceAllocation',
     'ResourceAllocationAdvanced',
     'Sacrifice',  
     'SensorRangeEnhancer',
     'Teleporter',
     'SelfRepairSystem',
     'StealthGenerator',
     'CloakingGenerator',  
     'ShieldHeavy',
     'ShieldGeneratorField', 
     'Shield',
     'RegenAura',
     'AdvancedRegenAura',
     'SystemIntegrityCompensator',   
     'HighExplosiveOrdnance', 
     'EnhancedSensors', 
     'Missile', 
     'TacticalMissile',
     'TacticalNukeMissile',
     'DamageStablization', -- TODO fix a typo in ACU/SCU blueprints
     'DamageStabilization',
     'DamageStabilizationAdvanced',
     'BlastAttack',
     'RateOfFire',
     'CoolingUpgrade',
     'AdvancedCoolingUpgrade',
     'EMPCharge',
     'FocusConvertor',
     'CrysalisBeam',
     'HeatSink',
     'HeavyAntiMatterCannon',
     'StabilitySuppressant',
     'NaniteTorpedoTube', 
     'MicrowaveLaserGenerator',  
     'RadarJammer',
     'NaniteMissileSystem',
     'ChronoDampener', 
     'EngineeringFocusingModule',
     'LeftPod',
     'RightPod',
     'Switchback',
     'AdvancedEngineering',
     'T3Engineering',
     'Pod', 
     --'ENGINEER', 
    },
}
 
--local control = import('/lua/maui/control.lua').Control

--==============================================================================
--- Create a dialog allowing the user to select categories of unit to disable
-- @param parent - Parent UI control to create the dialog inside.
-- @param initial - a list of keys from presetsData.lua for which the corresponding
-- toggles in this popup should be initially selected.
-- @param OnOk - a function that will be passed the new set of selected keys 
-- if the dialog is closed via the "OK" button.
-- @param OnCancel A function to be called if the dialog is cancelled.
-- @param isHost If false, the control will be read-only.
--==============================================================================
function CreateDialog(parent, initial, OnOk, OnCancel, isHost)
	 
    --isHost = false -- uncomment to test this UI in non-host scenario

    presets.Selected = {}
	checkboxes = { Units = {}, Presets = {} }
	restrictions = {}
	restrictions.Editable = isHost -- Editable only if hosting
	restrictions.Custom = {}
	restrictions.Presets = {}
	restrictions.Stats = {}
	 	 
    -- scaling dialog size based on window size
    local dialogWidth = GetFrame(0).Width() - 40
    local dialogHeight = GetFrame(0).Height() - 40
    dialogWidth  = math.min(dialogWidth, dialogMaxWidth) 
    dialogHeight = math.min(dialogHeight, dialogMaxHeight) 
    -- scale cell size by ratio of dialog size and make space for scroll bar
    cellSize = math.ceil((dialogWidth - dialogScrollWidth - 10) / cellMax)  
    -- scale font size by ratio of dialog size
    unitFontSize = math.ceil(unitFontSize * (dialogWidth / dialogMaxWidth))  
    unitFontSize = math.max(unitFontSize, 8)  

    
    local dialogContent = Group(parent)
    dialogContent.Width:Set(dialogWidth)
    dialogContent.Height:Set(dialogHeight)  

    local popup = Popup(parent, dialogContent)
    function doCancel()
        OnCancel()
        popup:Close()
    end
     
    popup.OnShadowClicked = doCancel
    popup.OnEscapePressed = doCancel

    local title = UIUtil.CreateText(dialogContent, "<LOC restricted_units_dlg_0000>Unit Manager", 20, UIUtil.titleFont)
    LayoutHelpers.AtTopIn(title, dialogContent, 6)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent)

	statsText = UIUtil.CreateText(dialogContent, "", 14, UIUtil.bodyFont)
	statsText:SetColor('ff8C8C8C')
    LayoutHelpers.AtTopIn(statsText, dialogContent, 10)
    LayoutHelpers.AtRightIn(statsText, dialogContent, 10)
    Tooltip.AddControlTooltip(statsText, { 
        text = 'Current Restrictions', 
        body = 'Restrictions are set using Presets (first two rows), Custom restrictions (rest of rows), or combination of both - Presets and Custom restrictions \n\n'
        .. 'To minimize number of restrictions, first select custom restrictions and then preset restrictions.' } )
	    
	local cancelBtn = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Cancel>")
    LayoutHelpers.AtBottomIn(cancelBtn, dialogContent, 5)
    LayoutHelpers.AtHorizontalCenterIn(cancelBtn, dialogContent)
    
	local okBtn = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Ok>")
    okBtn.Left:Set(function() return cancelBtn.Left() - 120 end)
	LayoutHelpers.AtBottomIn(okBtn, dialogContent, 5)
     
    local resetBtn = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Reset>")
    resetBtn.Left:Set(function() return cancelBtn.Left() + 120 end)
	LayoutHelpers.AtBottomIn(resetBtn, dialogContent, 5) 
    Tooltip.AddButtonTooltip(resetBtn, 'options_reset_all')
        
    local buttonGroup = Group(dialogContent)
    LayoutHelpers.AtLeftIn(buttonGroup, dialogContent, 6) 
    buttonGroup.Top:Set(function() return title.Bottom() - 2 end)
    buttonGroup.Bottom:Set(resetBtn.Top)
    buttonGroup.Width:Set(function() return dialogContent.Width() - 12 end)
	buttonGroup:DisableHitTest()
      
    if not isHost then
        cancelBtn.label:SetText(LOC("<LOC _Close>"))
        resetBtn:Hide()
        okBtn:Hide()
    end
      
    factions = {} -- reset factions
    blueprints = UnitsAnalyzer.GetBlueprints(Mods.GetGameMods(), false)
    table.insert(factions, UnitsAnalyzer.GetUnitsGroups(blueprints.All, 'SERAPHIM')) 
    table.insert(factions, UnitsAnalyzer.GetUnitsGroups(blueprints.All, 'UEF')) 
    table.insert(factions, UnitsAnalyzer.GetUnitsGroups(blueprints.All, 'CYBRAN')) 
    table.insert(factions, UnitsAnalyzer.GetUnitsGroups(blueprints.All, 'AEON')) 
           
    TimerStart()
    --LOG('UM Creating Presets Grid... ' )
	presetsGrid = Grid(buttonGroup, cellSize, cellSize) 
	presetsGrid.Top:Set(function() return buttonGroup.Top() + 6 end)
	presetsGrid.Left:Set(function() return buttonGroup.Left() + 4 end) 
	presetsGrid.Height:Set(function() return cellSize * 2 end) 
    presetsGrid.Width:Set(function() return buttonGroup.Width() - 4 end) 
	presetsGrid:DeleteAndDestroyAll(true)	-- clear grid
	presetsGrid.rows = 2
	presetsGrid.cols = cellMax
	presetsGrid:AppendCols(presetsGrid.cols, true)
	presetsGrid:AppendRows(presetsGrid.rows, true)
	
	local index = 0 
	local lastRow = 0 
	local column = 1
	local row = 1
	for _, presetName in presets.Order do
		local preset = presets.Data[presetName]
		if presetName ~= "" and preset then  
           
		    row = math.floor(index / presets.PerRow) + 1 
		    column = math.mod(index, presets.PerRow) + 2  
		     	
		    local icon = CreatePresetIcon(presetsGrid, preset.key)
		    CreateGridCell(presetsGrid, icon, column, row)
		end

	    index = index + 1
	end
	presetsGrid:EndBatch()
    --LOG('UM Creating Presets Grid... '.. TimerStop())
     
    --LOG('UM Creating Units Grid... ' ) 
	unitsGrid = Grid(buttonGroup, cellSize, cellSize) 
	unitsGrid.Top:Set(function() return presetsGrid.Bottom() + 6 end)
	unitsGrid.Left:Set(function() return buttonGroup.Left() + 4 end) 
	unitsGrid.Bottom:Set(function() return buttonGroup.Bottom() - 2 end) 
    unitsGrid.Width:Set(function() return buttonGroup.Width() - 4 end) 
	unitsGrid:DeleteAndDestroyAll(true)	-- clear grid
	unitsGrid.rows = 25
	unitsGrid.cols = cellMax 
	unitsGrid:AppendCols(unitsGrid.cols, true)
	unitsGrid:AppendRows(unitsGrid.rows, true)
	unitsGrid.HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            local delta = event.WheelRotation > 0 and -1 or 1
            self:ScrollLines("Vert", delta) 
            return true
        end
        return false
    end
    local gridScrollbar = UIUtil.CreateLobbyVertScrollbar(unitsGrid, -dialogScrollWidth)
       
	column = 1
	for _, faction in factions do 
        name = faction.Name
		column = CreateGridColumn(name, faction.Units.NAVAL, column, sortBy.TECH)
		column = CreateGridColumn(name, faction.Units.AIR, column, sortBy.TECH)
		column = CreateGridColumn(name, faction.Units.LAND, column, sortBy.TECH)
		column = CreateGridColumn(name, faction.Bases.FACTORIES, column, sortBy.ENGINEERING)
		column = CreateGridColumn(name, faction.Bases.ECONOMIC, column, sortBy.ECO, true)
		column = CreateGridColumn(name, faction.Bases.SUPPORT, column,sortBy.SUPPORT)
		column = CreateGridColumn(name, faction.Bases.DEFENSES, column,sortBy.WEAPON)
		column = CreateGridColumn(name, faction.Units.SCU, column,sortBy.UPGRADES)
		column = CreateGridColumn(name, faction.Units.ACU, column,sortBy.UPGRADES)
		--column = CreateGridColumn(name, faction.UPGRADES, column)
	    --column = CreateGridColumn(name, faction.SUBCOMMANDERS, column)
    end
	unitsGrid:EndBatch()
	if not unitsGrid:IsScrollable("Vert") then
        gridScrollbar:Hide()
	end
    --LOG('UM Creating Units Grid... '.. TimerStop())
      	 	
    --LOG('UM Updating Restrictions... ')
    -- set initial restrictions if there are any
    if initial then
		--table.print(initial,'initial')
		UpdateRestrictionsUI(initial)
	end
	UpdateRestrictionsStats()

    cancelBtn.OnClick = doCancel
	
    okBtn.OnClick = function()
        local newRestrictions = {}
		-- read current restrictions and pass them to game options
		for key, isChecked in presets.Selected do
			if isChecked then
			    table.insert(newRestrictions, key) 
			end
		end
		for key, isChecked in restrictions.Custom do
			if isChecked then
			    table.insert(newRestrictions, key) 
			end
		end
        --table.print(newRestrictions,'new restrictions')
		OnOk(newRestrictions)
        popup:Close()
    end

    resetBtn.OnClick = function()
		TogglePresetCheckboxes(false)
		ToggleUnitCheckboxes(false)
		UpdateRestrictionsStats() 
    end

    --LOG('UM Updating Restrictions... '.. TimerStop())
end
function UpdateRestrictionsUI(newRestrictions)
    -- order of updating restrictions is important and 
    -- custom restrictions must be set first
    -- then preset restrictions or state of checkboxes will be wrong
    --LOG('setting restrictions... ')
    for _, restriction in newRestrictions do
	    if checkboxes.Units[restriction] then
		    restrictions.Custom[restriction] = true
		    for _, chkbox in checkboxes.Units[restriction] do
			    chkbox:SetCheck(true, false)
		    end
	    end
        if presets.Data[restriction] then
		    presets.Selected[restriction] = true
		    if checkboxes.Presets[restriction] then
		       checkboxes.Presets[restriction]:SetCheck(true, false)
		    end
	    end
    end
     
    ProcessRestrictions()
end
function UpdateRestrictionsStats() 
	  
    restrictions.Stats = {}
	restrictions.Stats.Total = 0
	restrictions.Stats.Custom = 0
	restrictions.Stats.Presets = 0
	restrictions.Stats.Units = 0
	  
	for key, isRestricted in restrictions.Custom do
		if isRestricted then
			restrictions.Stats.Custom = restrictions.Stats.Custom + 1
		end
	end
	restrictions.Stats.Total = restrictions.Stats.Custom

	for key, isRestricted in restrictions.Presets do
		if isRestricted then
			restrictions.Stats.Units = restrictions.Stats.Units + 1
		end
	end
	 
	for name, active in presets.Selected do
		if active then
			restrictions.Stats.Total = restrictions.Stats.Total + 1
			restrictions.Stats.Presets = restrictions.Stats.Presets + 1
		end
	end  

	local info = restrictions.Stats.Total .. ' Restrictions = ' ..
				 restrictions.Stats.Custom .. ' Custom + ' ..
				 restrictions.Stats.Presets .. ' Presets (' .. restrictions.Stats.Units .. ')'
			      
	statsText:SetText(info)  
	    
	return restrictions.Stats
end

function GetTooltip(bp)
    return UnitsAnalyzer.GetTooltip(bp)  
end

local UnitsTooltip = import('/lua/ui/lobby/UnitsTooltip.lua')


function CreateUnitIcon(parent, bp, faction)
	
	local colors = {}
	 		 	
	local control = Bitmap(parent)
	control.bp = bp -- save blueprint reference for later
	control.Height:Set(cellSize)
	control.Width:Set(cellSize)
	control:SetSolidColor('FF000000')
	    
	local imagePath = UnitsAnalyzer.GetImagePath(bp, faction)

	bp.ImagePath = imagePath
	
	local fill = Bitmap(control)
	fill.Height:Set(cellSize-1)
	fill.Width:Set(cellSize-1) 
	fill:DisableHitTest()
	LayoutHelpers.AtVerticalCenterIn(fill, control)
	LayoutHelpers.AtHorizontalCenterIn(fill, control)
		
	local hover = Bitmap(control)
	hover.Height:Set(cellSize)
	hover.Width:Set(cellSize) 
	hover:DisableHitTest()
	LayoutHelpers.AtVerticalCenterIn(hover, control)
	LayoutHelpers.AtHorizontalCenterIn(hover, control)
		
	local checkbox = Checkbox(control,  
		  imagePath, --up.dds'),  	 
		  imagePath, --over.dds'),   	
		  imagePath, --down.dds'),   	
		  imagePath, --down.dds'),   	
		  imagePath, --dis.dds'),    
		  imagePath, --dis.dds'),    
		  'UI_Tab_Click_01', 'UI_Tab_Rollover_01')
	checkbox.Height:Set(cellSize-6)
	checkbox.Width:Set(cellSize-6) 
	checkbox:DisableHitTest()
	LayoutHelpers.AtLeftTopIn(checkbox, control, 5, 5) 
	
    if not bp.Categories.UPGRADE and
          (bp.Categories.COMMAND or bp.Categories.SUBCOMMANDER) then

        imagePath = '/textures/ui/icons_strategic/commander_generic.dds'
		local position = cellSize - unitFontSize - 2
		local typeIcon = Bitmap(control)
        typeIcon.Height:Set(unitFontSize)
		typeIcon.Width:Set(unitFontSize) 
		typeIcon:SetTexture(imagePath)
		typeIcon:DisableHitTest()
		LayoutHelpers.AtLeftTopIn(typeIcon, control, position, 3)
    end
    	 
	local techUI = UIUtil.CreateText(control, '', unitFontSize, UIUtil.bodyFont)
	techUI:DisableHitTest()
	LayoutHelpers.AtLeftTopIn(techUI, control, 0, -1)
	
    local modPosition = cellSize - unitFontSize
	local modFill = Bitmap(control)
	modFill.Height:Set(unitFontSize+1)
	modFill.Width:Set(unitFontSize+1) 
	modFill:SetSolidColor('00ffffff')
	modFill:DisableHitTest()
	LayoutHelpers.AtLeftTopIn(modFill, control, modPosition-2, modPosition-2)
	 
	local modText = UIUtil.CreateText(control, '', unitFontSize, UIUtil.bodyFont)
	modText:DisableHitTest()
	modText:SetColor('ffffffff')
	LayoutHelpers.AtLeftTopIn(modText, control, modPosition, modPosition-3)
	 
	if bp.Mod then
		modFill:SetSolidColor('ffAA00FF') 
		modText:SetText('M')  
		modText:SetColor('ffffffff')
	end
	
	local overlay = Bitmap(control)
	overlay.Height:Set(cellSize)
	overlay.Width:Set(cellSize) 
	overlay:SetSolidColor('00ffffff')
	overlay:DisableHitTest()
	LayoutHelpers.AtVerticalCenterIn(overlay, control)
	LayoutHelpers.AtHorizontalCenterIn(overlay, control)
	 
	if bp.Type == 'UPGRADE' or
       bp.Categories.ISPREENHANCEDUNIT	then	
		colors.TextChecked = 'ffffffff'
		colors.TextUncheck = 'ffffffff'
		colors.FillChecked = 'ad575757' -- 'a8141414'
		colors.FillUncheck = '003e3d3d'
		
		checkbox.selector = overlay 
		checkbox.Height:Set(cellSize)
		checkbox.Width:Set(cellSize)  
		LayoutHelpers.AtVerticalCenterIn(checkbox, control)
		LayoutHelpers.AtHorizontalCenterIn(checkbox, control)
		
		overlay:SetSolidColor(colors.FillUncheck) 
				 
		techUI:SetColor(colors.TextUncheck)
		
		if bp.Categories.ISPREENHANCEDUNIT then
			techUI:SetText(bp.Tech or '') 
            LayoutHelpers.AtLeftTopIn(techUI, control, 2, 2)
		else
            --LOG(bp.Faction .. ' ' .. bp.ID)
			--techUI:SetText(string.sub(bp.Slot, 1, 1))  
		end
	else
		colors.TextChecked = 'ffC0C0C0'
		colors.TextUncheck = 'ff000000'
		colors.FillChecked = 'ff575757'  
		colors.FillUncheck = bp.Color or 'ff524A3E'
		
		fill:SetSolidColor(colors.FillUncheck)
		techUI:SetColor(colors.TextUncheck)
		techUI:SetText(bp.Tech or '') 
		checkbox.selector = fill

        --TODO add startegic icons on top of unit icons
        --imagePath = nil
        --if bp.Tech == 'T1' then
        --    imagePath = '/textures/ui/common/icons/tags/t1.dds'
        --elseif bp.Tech == 'T2' then
        --    imagePath = '/textures/ui/common/icons/tags/t2.dds'
        --elseif bp.Tech == 'T3' then
        --    imagePath = '/textures/ui/common/icons/tags/t3.dds'
        --elseif bp.Tech == 'T4' then
        --    imagePath = '/textures/ui/common/icons/tags/t4.dds'
        --end
        --if imagePath then
        --    local techIcon = Bitmap(control)
		--    techIcon.Height:Set(unitFontSize+5)
		--    techIcon.Width:Set(unitFontSize+5) 
		--    techIcon:SetTexture(imagePath)
		--    techIcon:DisableHitTest()
		--    LayoutHelpers.AtLeftTopIn(techIcon, control, 1, 1)
        --end 
	end 
     
	LayoutHelpers.AtVerticalCenterIn(overlay, control)
	LayoutHelpers.AtHorizontalCenterIn(overlay, control)
		
	checkbox:DisableHitTest()
	checkbox.bp = bp
	
	-- some enhancements/units might be shared between factions so
	-- collect similar checkboxes in the same table using their ID as table key
	if not checkboxes.Units[bp.ID] then
		checkboxes.Units[bp.ID] = {}
	end
	table.insert(checkboxes.Units[bp.ID], checkbox)
	
	control.HandleEvent = function(self, event)
		--LOG('overlay ' .. event.Type)
		if event.Type == 'WheelRotation' then 
			return false -- allows grid scrolling 
		elseif event.Type == 'MouseEnter' then
                 
			PlaySound(Sound({ Cue = "UI_MFD_Rollover", Bank = "Interface" }))
			UnitsTooltip.Create(self, self.bp)
            
			if self.bp.Type == 'UPGRADE' then	
				hover:SetSolidColor('ff7F7F7F')
			else
				hover:SetSolidColor('7F'..string.sub(colors.FillChecked,3,8))
			end
            return true
		elseif event.Type == 'MouseExit' then
			 
            UnitsTooltip.Destroy()

			hover:SetSolidColor('00000000')
            return true
		elseif event.Type == 'ButtonPress' then
		
			if not restrictions.Editable then return true end
			 
			-- switching to custom restrictions
			TogglePresetCheckboxes(false)
			
			for ID, isRestricted in restrictions.Presets do 
			   	if isRestricted then
			   	  	restrictions.Custom[ID] = true
			   	  	restrictions.Presets[ID] = false
			   	end 
			end
			if restrictions.Custom[self.bp.ID] then
			   restrictions.Custom[self.bp.ID] = false
			else
			   restrictions.Custom[self.bp.ID] = true
			end
			-- update checkboxes with the same blueprint IDs, e.g. Teleporter
			if checkboxes.Units[self.bp.ID] then
				for _, chkbox in checkboxes.Units[self.bp.ID] do
					chkbox:HandleEvent(event)
				end
			end
			UpdateRestrictionsStats()  
			return true 
		end
		return true  
    end	 
	 
	checkbox.OnCheck = function(self, checked)
		local fillColor = checked and colors.FillChecked or colors.FillUncheck
		local textColor = checked and colors.TextChecked or colors.TextUncheck
		self.selector:SetSolidColor(fillColor)
		techUI:SetColor(textColor) 
	end 
	
	return control  
end
function CreatePresetIcon(parent, presetName)
	
	local preset = presets.Data[presetName]
	local colors = {}
	colors.FillChecked = 'ff575757'  --#ff575757
	colors.FillUncheck = '00000000'  --#00000000
	colors.HoverEnter  = '7F7F7F7F'  --#7F7F7F7F
	colors.HoverExit   = '00ffffff'  --#00ffffff
	 		 	
	local control = Bitmap(parent)
	control.preset = preset					 
	control.presetName = presetName					 
	control.Height:Set(cellSize)
	control.Width:Set(cellSize)
	control:SetSolidColor(colors.FillUncheck)
	    
	local imagePath = UnitsAnalyzer.GetImagePath(preset, '')
	   	
	local fill = Bitmap(control)
	fill.Height:Set(cellSize-1)
	fill.Width:Set(cellSize-1) 
	fill:SetSolidColor(colors.FillUncheck)
	fill:DisableHitTest()
	LayoutHelpers.AtVerticalCenterIn(fill, control)
	LayoutHelpers.AtHorizontalCenterIn(fill, control)
		
	local hover = Bitmap(control)
	hover.Height:Set(cellSize)
	hover.Width:Set(cellSize) 
	hover:SetSolidColor('00ffffff') --#00ffffff
	hover:DisableHitTest()
	LayoutHelpers.AtVerticalCenterIn(hover, control)
	LayoutHelpers.AtHorizontalCenterIn(hover, control)
		
	local checkbox = Checkbox(control,  
		  imagePath, --up.dds'),  	 
		  imagePath, --over.dds'),   	
		  imagePath, --down.dds'),   	
		  imagePath, --down.dds'),   	
		  imagePath, --dis.dds'),    
		  imagePath, --dis.dds'),    
		  'UI_Tab_Click_01', 'UI_Tab_Rollover_01')
	checkbox.Height:Set(cellSize-2)
	checkbox.Width:Set(cellSize-2)  
	checkbox:DisableHitTest()
	LayoutHelpers.AtVerticalCenterIn(checkbox, control)
	LayoutHelpers.AtHorizontalCenterIn(checkbox, control)
	   		 
	checkboxes.Presets[presetName] = checkbox
	
	local presetTooltip = { 
		text = preset.name,
		body = preset.tooltip  
	}
	
	control.HandleEvent = function(self, event)
		if event.Type == 'WheelRotation' then 
			return false
		elseif event.Type == 'MouseEnter' then
			PlaySound(Sound({ Cue = "UI_MFD_Rollover", Bank = "Interface" }))
			Tooltip.CreateMouseoverDisplay(self, presetTooltip, nil, true)
			hover:SetSolidColor(colors.HoverEnter)
			 
		elseif event.Type == 'MouseExit' then
			Tooltip.DestroyMouseoverDisplay()
			hover:SetSolidColor(colors.HoverExit)
		elseif event.Type == 'ButtonPress' then
		
			if not restrictions.Editable then return true end
			
			if presets.Selected[self.presetName] then
			   presets.Selected[self.presetName] = false
			else
			   presets.Selected[self.presetName] = true
			end
			
			checkboxes.Presets[self.presetName]:HandleEvent(event)
			
			ProcessRestrictions()
		
			return true 
		end
		return true  
    end	 
	 
	checkbox.OnCheck = function(self, checked)
		local fillColor = checked and colors.FillChecked or colors.FillUncheck
		fill:SetSolidColor(fillColor)
	end 
	 
	return control  
end
  	
function TogglePresetCheckboxes(isChecked)
	for name, _ in presets.Selected do
		presets.Selected[name] = isChecked
		checkboxes.Presets[name]:SetCheck(isChecked)
	end
end   	

function ToggleUnitCheckboxes(isChecked)
  	for ID, _ in restrictions.Custom do
		restrictions.Custom[ID] = isChecked
	end
	
	for ID, _ in restrictions.Presets do
		restrictions.Presets[ID] = isChecked
	end
	
	for _, chkboxes in checkboxes.Units do
		for __, chkbox in chkboxes do
			chkbox:SetCheck(isChecked)
		end
	end
end   
 
function ProcessRestrictions()
    local categories  = {}
	local enhancements = {}
	local expressions = nil
	
	local presetsInfo = {}
	 
	-- combine all selected restriction presets
	for name, active in presets.Selected do
		if active then
			local info = ''
			local preset = presets.Data[name]
		    if preset.categories then
				categories[preset.categories] = true
				info = info .. preset.categories  
			end
			if preset.enhancements then
				for _, enh in preset.enhancements do
					enhancements[enh] = true
				end
                
				info = info .. " (" .. table.concat(preset.enhancements, ' + ') .. ')'
			end
			presetsInfo[name] = info
		end
	end
			 
	-- create expression from unified categories
	for category, _ in categories do
		if expressions then
			expressions = expressions .. " + (" .. category .. ")"
		else
			expressions = "(" .. category .. ")"
		end
	end
	-- NOTE for debugging
    --if table.getsize(presetsInfo) > 0 then
    --    LOG('----------------------------------------------')
	--    table.print(presetsInfo, 'presets selected') 
	--end		 

	for bpID, chkboxes in checkboxes.Units do
		local unit = blueprints.All[bpID]
		 
		local isRestricted = false 
		if UnitsAnalyzer.Contains(unit, expressions) then
			isRestricted = true
		elseif enhancements[bpID] then
			isRestricted = true
		end
		
		for _, checkbox in chkboxes do
			if restrictions.Custom[bpID] then  
				if isRestricted then
					restrictions.Custom[bpID] = false 
					restrictions.Presets[bpID] = true
					checkbox:SetCheck(true)
				else
					if restrictions.Presets[bpID] then 
						restrictions.Custom[bpID] = false 
						checkbox:SetCheck(false)
					else
						checkbox:SetCheck(true)
					end 
				end
			else
				if isRestricted then 
					checkbox:SetCheck(true)
				else
					checkbox:SetCheck(false)
				end
			end
		end 
		restrictions.Presets[bpID] = isRestricted
	end
	
	UpdateRestrictionsStats()
	
end

function CreateGridColumn(faction, units, col, sortCategories, sortReversed)
	 
	local unitsCount = table.getsize(units) or 0
	if unitsCount == 0 then return col end
	
	local unitsSorted = SortUnits(units, sortCategories, sortReversed)
	local row = 1  
	for unitID, unit in unitsSorted do
  
		local unitIcon = CreateUnitIcon(unitsGrid, unit, faction)
		CreateGridCell(unitsGrid, unitIcon, col, row) 
		row = row + 1 
	end 
	col = col + 1
		
	return col
end
-- adds safely an icon to specified grid and increases grid size if needed 
function CreateGridCell(targetGrid, icon, col, row)

	targetGrid.rows = targetGrid.rows or 0
	targetGrid.cols = targetGrid.cols or 0
	
	-- make sure we have enough rows in the grid
	while targetGrid.rows < row do
		targetGrid.rows = targetGrid.rows  + 1
		targetGrid:AppendRows(1, true)
	end
	-- make sure we have enough columns in the grid
	while targetGrid.cols < col do
		targetGrid.cols = targetGrid.cols  + 1
		targetGrid:AppendCols(1, true)
	end
		
	if targetGrid:GetItem(col, row) then
		WARN('Grid already has an item in cell ' .. col .. ',' .. row)
	else
		targetGrid:SetItem(icon, col, row, true)
	end
	
	targetGrid.cells = targetGrid.rows * targetGrid.cols
	
end
function CreateGrid(parent, cellSize, cellSize, cols, rows)
	local grid = Grid(parent, cellSize, cellSize)
	grid.rows = 0 
	grid.cols = 0 
		 
	if cols > 0 then
	    grid.rows = cols 
		grid:AppendCols(grid.cols, true)
		LOG('adding cols '.. grid.cols.. ' - '.. cols)
	end
	if rows > 0 then
        grid.rows = rows 
		grid:AppendRows(grid.rows, true)
	    LOG('adding rows '.. grid.rows.. ' - '.. rows)
	end
	grid.cells = grid.rows * grid.cols
	
	return grid
end
 
-- compares two variables of any type
function CompareUnitsBy(a, b)
	local typeA, typeB = type(a), type(b)
	if typeA ~= typeB then -- order by type
		return typeA < typeB
	elseif typeA == "number" and typeB == "number" then
		if math.abs(a - b) < 0.0001 then
			return 0
		else
			return a > b -- numbers in decreasing order
		end
	elseif typeA == "string" or typeB == "string" then
		local A, B = string.upper(a), string.upper(b)
		if A == B then 
			return 0
		else 
			return A > B
		end
	elseif typeA == "boolean" and typeB == "boolean" then
		return a == true
	else
		return tostring(a) < tostring(b) -- order by address
	end
end  
--- compares two units using their categories
--- @param a - first blueprint
--- @param b - second blueprint
--- @param sortCategories - table with sort catergories
--- @param sortReversed - optional boolean for sorting in revers of order specified in sortCategories
function CompareUnitsOrder(a, b, sortCategories, sortReversed, depth, item)	 
	--LOG('Compare ' .. a.Name .. ' ' .. b.Name)
	if depth and depth > 15 then
		--LOG('Compare depth MAX ' .. depth .. ' ' .. (item or ''))
		return 0
	end

	if table.getsize(sortCategories) == 0 then
		return 0
	end
	
	local orderA = nil
	local orderB = nil
	local categoryA = nil
	local categoryB = nil
		
	-- find sorting index using units' Categories or IDs
    for orderIndex, category in sortCategories do 
        local isMatching = a.Categories[category] or a.ID == category
		if not orderA and isMatching then
			orderA = orderIndex
			categoryA = category
		end
		local isMatching = b.Categories[category] or b.ID == category
		if not orderB and isMatching then
			orderB = orderIndex
			categoryB = category
		end
	end 
	if (categoryA or categoryB) and categoryA == categoryB then
		local target = categoryA or categoryB
		if not depth then
			depth = 1
		else 
			depth = depth + 1
		end
		local sortCopy = table.copy(sortCategories)
		--LOG('sortCopy ' .. depth.. ' ' .. categoryA .. ' --- ' .. table.concat(sortCopy,', '))
		table.removeByValue(sortCopy, target)
		--LOG('Compare depth ' .. depth .. ' ' .. target) -- .. ' --- '.. table.concat(sortCopy,', '))
		return CompareUnitsOrder(a, b, sortCopy, sortReversed, depth, target)	 
	end
	
	if orderA == orderB then
		return 0
	end
	if sortReversed then
	    return orderA < orderB 
    else 
    	return orderA > orderB 
    end
end

function SortUnits(unitsByID, sortCategories, sortReversed)
    if not sortCategories then 
       sortCategories = sortBy.TECH
    end
	if table.getsize(unitsByID) == 0 then
		return unitsByID
	end
	local sortedUnits = table.indexize(unitsByID)

	table.sort(sortedUnits, function(a,b)
		local order = CompareUnitsOrder(a,b, sortCategories, sortReversed)
		if order == 0 then
			order = CompareUnitsBy(a.Tech, b.Tech)
			if order == 0 then
				return tostring(a.ID) > tostring(b.ID)  
			else
				return order
			end
		else
			return order
		end		
	end)	
	return table.reverse(sortedUnits)
end
 
