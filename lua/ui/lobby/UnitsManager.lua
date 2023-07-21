-- ==========================================================================================
-- * File       : lua/modules/ui/lobby/UnitsManager.lua
-- * Authors    : Gas Powered Games, FAF Community, HUSSAR
-- * Summary    : Contains UI for managing unit and enhancement restrictions
-- ==========================================================================================
local Mods     = import("/lua/mods.lua")
local UIUtil   = import("/lua/ui/uiutil.lua")
local Utils    = import("/lua/system/utils.lua")
local Tooltip  = import("/lua/ui/game/tooltip.lua")
local Group    = import("/lua/maui/group.lua").Group
local Popup    = import("/lua/ui/controls/popups/popup.lua").Popup
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local Bitmap   = import("/lua/maui/bitmap.lua").Bitmap
local Grid     = import("/lua/maui/grid.lua").Grid
local StatusBar = import("/lua/maui/statusbar.lua").StatusBar
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local UnitsAnalyzer   = import("/lua/ui/lobby/unitsanalyzer.lua")
local UnitsRestrictions = import("/lua/ui/lobby/unitsrestrictions.lua")

-- Stores unit blueprints for all factions
local blueprints = { All = {}, Original = {}, Modified = {}, Skipped = {} }

-- Stores unit blueprints per faction
local factions = {}

-- Stores info about preset restrictions
local presets = {}
presets.PerRow   = 35 -- Determines number of presets' icons per row
presets.Data     = UnitsRestrictions.GetPresetsData()
presets.Order    = UnitsRestrictions.GetPresetsOrder()

-- Stores all UI elements of the UnitsManager
local GUI = {
    bg = nil,
    popup = nil,
    title = nil,
    stats = nil,
    unitsGrid = nil,
    presetsGrid = nil,
    -- stores references to checkboxes for quick toggling of Presets and Units
    checkboxes = { Units = {}, Presets = {} }
}

-- Stores current IDs of units restricted by Presets and Custom selection
local restrictions = { Custom = {}, Presets = {}, Stats = {} }

local initFontSize = 13
local unitFontSize = 0 -- Calculated when dialog is created
local dialogMaxWidth = 1920  -- Used to determine scaling of icons/fonts
local dialogMaxHeight = 1200 -- Used to determine scaling of icons/fonts
local dialogWidth  = 0
local dialogHeight = 0
local dialogScrollWidth = 15
local factionsCount  = 0 -- Calculated when unit blueprints are loaded
local factionsGroups = 9 -- e.g. NAVAL, AIR, LAND, FACTORIES, ECO, SUPPORT, DEFENCES, COMMANDSER, enhancements
-- Defines order of faction units/icons counted from left to right, new factions are automatically appended to the right
local factionsOrder  = { SERAPHIM = 1, UEF = 2, CYBRAN = 3, AEON = 4, NOMADS = 5}
local cellMax  = 0 -- Calculated when unit blueprints are loaded
local cellSize = 0
local cellSpace = 0
local gridWidth  = 0
local gridMargin = 0
-- This table contains blueprint's categories or IDs for ordering units in grid columns, e.g.
-- Units matching first entry will be placed as first item in a column
-- If two units match the first entry then the next entry is used for comparing
local sortBy = {
    -- Order blueprints first by their TECH level and then WEAPON categories
    TECH = {
        'TECH1',
        'TECH2',
        'TECH3',
        'EXPERIMENTAL',
        'ORBITALSYSTEM',
        'SATELLITE',
        -- Additional sorting
        'SCOUT',
        'DIRECTFIRE',
        'BOMBER',
        'ANTIAIR',
        'GROUNDATTACK',
        'TRANSPORTATION',
        'ANTINAVY',
        'SUBMERSIBLE',
        'INDIRECTFIRE',
        'ARTILLERY',
        'BOT',
    },
    -- Order blueprints first by their WEAPON categories and then TECH level
    WEAPON = {
        'SCOUT',
        'MINE',
        'DIRECTFIRE',
        'ANTIAIR',
        'GROUNDATTACK',
        'TRANSPORTATION',
        'ANTINAVY',
        'BOMBER',
        'INDIRECTFIRE',
        'ARTILLERY',
        'TECH1',
        'TECH2',
        'TECH3',
        'EXPERIMENTAL',
        'SUBMERSIBLE',
        'TACTICALMISSILEPLATFORM',
        'ANTIMISSILE',
        'NUKE',
        'BOMB',
    },
    ENGINEERING = {
        'GATE',
        'SORTCONSTRUCTION',
        'NAVAL',
        'ORBITAL',
        'AIR',
        'LAND',
        'ENGINEERSTATION',
        'ENGINEER',
        'TECH1',
        'TECH2',
        'TECH3',
        'RESEARCH', -- FACTORY HQ
        'SUPPORTFACTORY',
        'POD',
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
        'SONAR',
        'RADAR',
        'OMNI',
        'OPTICS',
        'COUNTERINTELLIGENCE',
        'SHIELD',
        'WALL',
        'STEALTH',
        'STEALTHFIELD',
        'HEAVYWALL',
        'AIRSTAGINGPLATFORM',
    },
    UPGRADES = {
        'COMMAND',
        'SUBCOMMANDER',
        'UPGRADE', -- Created in UnitsAnalyzer
        'ISPREENHANCEDUNIT',
        -- NOTE this order ensure that ACU/SCU have similar upgrades next to each other
        'Overcharge',
        'EngineeringThroughput',
        'ResourceAllocation',
        'ResourceAllocationAdvanced',
        'Sacrifice',
        'SensorRangeEnhancer',
        'Teleporter',
        'SelfRepairSystem',
        'StealthGenerator',
        'FAF_SelfRepairSystem',
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
        'DamageStabilization',
        'DamageStabilizationAdvanced',
        'BlastAttack',
        'RateOfFire',
        'CoolingUpgrade',
        'AdvancedCoolingUpgrade',
        'EMPCharge',
        'FocusConvertor',
        'CrysalisBeam',
        'FAF_CrysalisBeamAdvanced',
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
    },
}

local taskNotifier = import("/lua/ui/lobby/tasknotifier.lua").Create()
local timer = CreateTimer()
--==============================================================================
-- Create a dialog allowing the user to select categories of unit to disable
-- @param parent - Parent UI control to create the dialog inside.
-- @param initial - a list of keys from presetsData.lua for which the corresponding
--                  toggles in this popup should be initially selected.
-- @param OnOk - a function that will be passed the new set of selected keys
--               if the dialog is closed via the "OK" button.
-- @param OnCancel A function to be called if the dialog is canceled.
-- @param isHost If false, the control will be read-only.
--==============================================================================
function CreateDialog(parent, initial, OnOk, OnCancel, isHost)

    timer:Reset()
    timer:Start('UnitsManager...CreateDialog', true)

    presets.Selected = {}
    GUI.checkboxes = { Units = {}, Presets = {} }
    restrictions = {}
    restrictions.Editable = isHost -- Editable only if hosting
    restrictions.Custom = {}
    restrictions.Presets = {}
    restrictions.Stats = {}
    restrictions.Initial = initial

    -- Scaling dialog size based on window size
    dialogWidth = GetFrame(0).Width() - LayoutHelpers.ScaleNumber(40)
    dialogHeight = GetFrame(0).Height() - LayoutHelpers.ScaleNumber(40)

    GUI.bg = Group(parent)
    GUI.bg.Width:Set(dialogWidth)
    GUI.bg.Height:Set(dialogHeight)

    function doCancel()
        OnCancel()
        CloseDialog()
    end
    GUI.popup = Popup(parent, GUI.bg)
    GUI.popup.OnShadowClicked = doCancel
    GUI.popup.OnEscapePressed = doCancel


    timer:Start('CreateControls')
    CreateControls(OnOk, doCancel, isHost)
    timer:Stop('CreateControls')

    if not isHost then
        GUI.cancelBtn.label:SetText(LOC("<LOC _Close>"))
        GUI.resetBtn:Hide()
        GUI.okBtn:Hide()
    end

    GUI.content = Group(GUI.bg)
    LayoutHelpers.AtLeftIn(GUI.content, GUI.bg, 6)
    LayoutHelpers.AnchorToBottom(GUI.content, GUI.title, -2)
    GUI.content.Bottom:Set(GUI.resetBtn.Top)
    GUI.content.Width:Set(function() return GUI.bg.Width() - 12 end)
    GUI.content:DisableHitTest()

    GUI.progressBar = StatusBar(GUI.bg, 0, 1, false, false, nil, nil, true)
    GUI.progressBar._bar:SetSolidColor('DDC0C0C0') ----DDC0C0C0
    GUI.progressBar:SetTexture(UIUtil.UIFile('/game/unit-build-over-panel/healthbar_bg.dds'))
    GUI.progressBar:SetValue(0)
    LayoutHelpers.SetHeight(GUI.progressBar, 5)
    LayoutHelpers.AtLeftIn(GUI.progressBar, GUI.bg, 30)
    LayoutHelpers.AtRightIn(GUI.progressBar, GUI.bg, 30)
    LayoutHelpers.AtVerticalCenterIn(GUI.progressBar, GUI.bg)

    GUI.progressTxt = UIUtil.CreateText(GUI.bg, "Blueprints Loading ... ", 16, UIUtil.titleFont)
    GUI.progressTxt:SetColor('FFAEACAC') -- --FFAEACAC
    LayoutHelpers.Above(GUI.progressTxt, GUI.progressBar, 5)
    LayoutHelpers.AtHorizontalCenterIn(GUI.progressTxt, GUI.bg)

    table.insert(GUI.controls, GUI.progressBar)
    table.insert(GUI.controls, GUI.progressTxt)

    taskNotifier:Reset()
    taskNotifier.OnProgressCallback = OnBlueprintsProgress
    taskNotifier.OnCompleteCallback = OnBlueprintsLoaded

    import("/lua/ui/lobby/unitsanalyzer.lua").FetchBlueprints(Mods.GetGameMods(), false, taskNotifier)

end

function OnBlueprintsProgress(task)

     if GUI.progressBar and taskNotifier then
        GUI.progressBar:SetValue(taskNotifier.totalProgress)
     end

     if GUI.progressTxt and task and task.name then
        GUI.progressTxt:SetText(task.name .. ' ...')
     end
end

function OnBlueprintsLoaded()

    GUI.progressBar:Hide()
    GUI.progressTxt:Hide()

    blueprints = import("/lua/ui/lobby/unitsanalyzer.lua").GetBlueprintsList()
    local blueprintsCount = table.getsize(blueprints.All)

    if blueprintsCount > 0 then
        timer:Start('UnitsManager...UnitsGroupping')
        factions = {} -- reset factions blueprints
        -- find all factions without assuming there are only 4 factions (nomads support)
        for k, bp in blueprints.All do
            if bp.Faction then
               if not factions[bp.Faction] then
                    factions[bp.Faction] = {}
                    factions[bp.Faction].Name = bp.Faction
                    factions[bp.Faction].Blueprints = {}
                    if not factionsOrder[bp.Faction] then
                         factionsOrder[bp.Faction] = table.getsize(factionsOrder) + 1
                    end
               end
               table.insert(factions[bp.Faction].Blueprints, bp)
            end
        end
        factionsCount = table.getsize(factions)
        -- group units based on type and calculate number of grid columns
        cellMax = 0
        for name, faction in factions do
            UnitsAnalyzer.GetUnitsGroups(faction.Blueprints, faction)
            for group, units in faction.Units do
                if not table.empty(units) then
                    cellMax = cellMax + 1
                elseif group ~= 'CIVILIAN' then
                    WARN('UnitsManager detected '..name..' faction without any '..group..' units')
                end
            end
        end
        timer:Stop('UnitsManager...UnitsGroupping',true)

        -- scale cell size by dialog size and make space for scroll bar
        cellSpace = dialogWidth / LayoutHelpers.GetPixelScaleFactor() - dialogScrollWidth - 20
        cellSize = math.floor(cellSpace / cellMax)
        cellSize = math.min(cellSize, LayoutHelpers.ScaleNumber(55))
        -- calculate grid size and margin to ensure grids are centered
        gridWidth = cellSize * cellMax
        gridMargin = (cellSpace - gridWidth) / 2
        gridMargin = math.max(gridMargin, 4)
        -- scale font size by ratio of grid size and max dialog size
        unitFontSize = math.ceil(initFontSize * (gridWidth / dialogMaxWidth))
        unitFontSize = math.max(unitFontSize, 8)

        timer:Start('UnitsManager...CreatePresetsGrid')
        CreatePresetsGrid()
        timer:Stop('UnitsManager...CreatePresetsGrid', true)

        timer:Start('UnitsManager...CreateUnitsGrid')
        CreateUnitsGrid()
        timer:Stop('UnitsManager...CreateUnitsGrid',true)
    end

    -- Set initial restrictions if there are any
    if restrictions.Initial then
        UpdateRestrictionsUI()
    end
    UpdateRestrictionsStats()

    timer:Stop('UnitsManager...CreateDialog', true)
end

-- Creates a grid with buttons representing all restriction presets defined in UnitsRestrictions.lua
function CreatePresetsGrid()
    local rowMax = 4
    GUI.presetsGrid = CreateGrid(GUI.content, cellSize, cellSize, cellMax, rowMax)
    LayoutHelpers.AtLeftTopIn(GUI.presetsGrid, GUI.content, gridMargin, 6)
    LayoutHelpers.SetHeight(GUI.presetsGrid, cellSize * rowMax)
    GUI.presetsGrid.Width:Set(function() return GUI.content.Width() - gridMargin end)

    local index = 0
    local column = 1
    local row = 1
    for _, presetName in presets.Order do
        local preset = presets.Data[presetName]

        if presetName ~= "" and preset then
            local icon = CreatePresetIcon(GUI.presetsGrid, preset.key)
            CreateGridCell(GUI.presetsGrid, icon, column, row)
            row = row + 1
        else
            row = 1
            column = column + 1
        end

        if row > rowMax then
           row = 1
           column = column + 1
        end
        index = index + 1
    end
    GUI.presetsGrid:EndBatch()
end
-- Creates a grid with buttons representing all original units and modded units (if game mods are enabled)
function CreateUnitsGrid()
    GUI.unitsGrid = CreateGrid(GUI.content, cellSize, cellSize, cellMax, 25)
    LayoutHelpers.AnchorToBottom(GUI.unitsGrid, GUI.presetsGrid, 6)
    LayoutHelpers.AtLeftIn(GUI.unitsGrid, GUI.content, gridMargin)
    LayoutHelpers.AtBottomIn(GUI.unitsGrid, GUI.content, 2)
    GUI.unitsGrid.Width:Set(function() return GUI.content.Width() - gridMargin end)

    GUI.unitsGrid.HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            local delta = event.WheelRotation > 0 and -1 or 1
            self:ScrollLines("Vert", delta)
            return true
        end
        return false
    end

    local column = 1
    local order = table.inverse(factionsOrder)
    for order, name in order do
        local faction = factions[name]
        column = CreateGridColumn(name, faction.Units.NAVAL, column, sortBy.TECH)
        column = CreateGridColumn(name, faction.Units.AIR, column, sortBy.TECH)
        column = CreateGridColumn(name, faction.Units.LAND, column, sortBy.TECH)
        column = CreateGridColumn(name, faction.Units.CONSTRUCT, column, sortBy.ENGINEERING)
        column = CreateGridColumn(name, faction.Units.ECONOMIC, column, sortBy.ECO, true)
        column = CreateGridColumn(name, faction.Units.SUPPORT, column,sortBy.SUPPORT)
        column = CreateGridColumn(name, faction.Units.DEFENSES, column,sortBy.WEAPON)
        column = CreateGridColumn(name, faction.Units.CIVILIAN, column,sortBy.TECH)
        column = CreateGridColumn(name, faction.Units.SCU, column,sortBy.UPGRADES)
        column = CreateGridColumn(name, faction.Units.ACU, column,sortBy.UPGRADES)
    end
    GUI.unitsGrid:EndBatch()

    GUI.scrollbar = UIUtil.CreateLobbyVertScrollbar(GUI.unitsGrid, -dialogScrollWidth)
    if not GUI.unitsGrid:IsScrollable("Vert") then
        GUI.scrollbar:Hide()
    end
end

function CreateControls(OnOk, OnCancel, isHost)

    GUI.title = UIUtil.CreateText(GUI.bg, "<LOC restricted_units_dlg_0000>Unit Manager", 20, UIUtil.titleFont)
    LayoutHelpers.AtTopIn(GUI.title, GUI.bg, 6)
    LayoutHelpers.AtHorizontalCenterIn(GUI.title, GUI.bg)

    GUI.stats = UIUtil.CreateText(GUI.bg, "", 14, UIUtil.bodyFont)
    GUI.stats:SetColor('ff8C8C8C') -- --ff8C8C8C
    LayoutHelpers.AtTopIn(GUI.stats, GUI.bg, 10)
    LayoutHelpers.AtRightIn(GUI.stats, GUI.bg, 10)
    Tooltip.AddControlTooltip(GUI.stats, {
        text = '<LOC restricted_units_dlg_0001>Current Restrictions',
        body = '<LOC restricted_units_dlg_0002>Restrictions are set using Presets (first four rows), Custom restrictions (rest of rows), or combination of both - Presets and Custom restrictions \n\n'
            .. 'To minimize number of restrictions, first select custom restrictions and then preset restrictions.' })

    GUI.cancelBtn = UIUtil.CreateButtonWithDropshadow(GUI.bg, '/BUTTON/medium/', "<LOC _Cancel>")
    LayoutHelpers.AtBottomIn(GUI.cancelBtn, GUI.bg, 5)
    LayoutHelpers.AtHorizontalCenterIn(GUI.cancelBtn, GUI.bg)

    GUI.okBtn = UIUtil.CreateButtonWithDropshadow(GUI.bg, '/BUTTON/medium/', "<LOC _Ok>")
    LayoutHelpers.AtLeftIn(GUI.okBtn, GUI.cancelBtn, -120)
    LayoutHelpers.AtBottomIn(GUI.okBtn, GUI.bg, 5)

    GUI.resetBtn = UIUtil.CreateButtonWithDropshadow(GUI.bg, '/BUTTON/medium/', "<LOC _Reset>")
    LayoutHelpers.AtLeftIn(GUI.resetBtn, GUI.cancelBtn, 120)
    LayoutHelpers.AtBottomIn(GUI.resetBtn, GUI.bg, 5)
    Tooltip.AddButtonTooltip(GUI.resetBtn, 'options_reset_all')

    GUI.cancelBtn.OnClick = doCancel

    GUI.okBtn.OnClick = function()
        local newRestrictions = {}
        -- Read current restrictions and pass them to game options
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

        OnOk(newRestrictions)
        CloseDialog()
    end

    GUI.resetBtn.OnClick = function()
        TogglePresetCheckboxes(false)
        ToggleUnitCheckboxes(false)
        UpdateRestrictionsStats()
    end

    GUI.controls = {}
    table.insert(GUI.controls, GUI.title)
    table.insert(GUI.controls, GUI.stats)
    table.insert(GUI.controls, GUI.cancelBtn)
    table.insert(GUI.controls, GUI.okBtn)
    table.insert(GUI.controls, GUI.resetBtn)

end

-- Closes dialog and cleans up its UI elements
function CloseDialog()

    -- stop loading of blueprints in case they are still loading
    import("/lua/ui/lobby/unitsanalyzer.lua").StopBlueprints()

    for id, control in GUI.controls or {} do
        if control then
           control:Destroy()
        end
    end
    GUI.controls = nil

    for _, checkbox in GUI.checkboxes.Units or {} do
        if checkbox then
           checkbox = nil
        end
    end
    for _, checkbox in GUI.checkboxes.Presets or {} do
        if checkbox then
           checkbox = nil
        end
    end
    GUI.checkboxes = { Units = {}, Presets = {} }

    if GUI.popup then
       GUI.popup:Close()
    end
end


function UpdateRestrictionsUI()
    -- Order of updating restrictions is important and
    -- custom restrictions must be set first
    -- then preset restrictions or state of checkboxes will be wrong
    for _, restriction in restrictions.Initial do
        if GUI.checkboxes.Units[restriction] then
            restrictions.Custom[restriction] = true
            for _, chkbox in GUI.checkboxes.Units[restriction] do
                chkbox:SetCheck(true, false)
            end
        end
        if presets.Data[restriction] then
            presets.Selected[restriction] = true
            if GUI.checkboxes.Presets[restriction] then
               GUI.checkboxes.Presets[restriction]:SetCheck(true, false)
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

    local info = LOCF('<LOC restricted_units_dlg_0003>%s Restrictions = %s Custom + %s Presets (%s)',
        restrictions.Stats.Total, restrictions.Stats.Custom, restrictions.Stats.Presets, restrictions.Stats.Units)
    GUI.stats:SetText(info)

    return restrictions.Stats
end

local UnitsTooltip = import("/lua/ui/lobby/unitstooltip.lua")

function CreateUnitIcon(parent, bp, faction)
    local colors = {}

    local control = Bitmap(parent)
    control.bp = bp -- Save blueprint reference for later
    LayoutHelpers.SetDimensions(control, cellSize, cellSize)
    control:SetSolidColor('FF000000')

    local imagePath = UnitsAnalyzer.GetImagePath(bp, faction)
    bp.ImagePath = imagePath

    local fill = Bitmap(control)
    LayoutHelpers.SetDimensions(fill, cellSize - 1, cellSize - 1)
    fill:DisableHitTest()
    LayoutHelpers.AtVerticalCenterIn(fill, control)
    LayoutHelpers.AtHorizontalCenterIn(fill, control)

    local hover = Bitmap(control)
    LayoutHelpers.SetDimensions(hover, cellSize, cellSize)
    hover:DisableHitTest()
    LayoutHelpers.AtVerticalCenterIn(hover, control)
    LayoutHelpers.AtHorizontalCenterIn(hover, control)

    local checkbox = Checkbox(control,
          imagePath, -- up.dds'),
          imagePath, -- over.dds'),
          imagePath, -- down.dds'),
          imagePath, -- down.dds'),
          imagePath, -- dis.dds'),
          imagePath, -- dis.dds'),
          'UI_Tab_Click_01', 'UI_Tab_Rollover_01')
    LayoutHelpers.SetDimensions(checkbox, cellSize - 6, cellSize - 6)
    checkbox:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(checkbox, control, 5, 5)

    if not bp.CategoriesHash.UPGRADE and
          (bp.CategoriesHash.COMMAND or bp.CategoriesHash.SUBCOMMANDER) then

        imagePath = '/textures/ui/icons_strategic/commander_generic.dds'
        local position = cellSize - unitFontSize - 2
        local typeIcon = Bitmap(control)
        LayoutHelpers.SetDimensions(typeIcon, unitFontSize, unitFontSize)
        typeIcon:SetTexture(imagePath)
        typeIcon:DisableHitTest()
        LayoutHelpers.AtLeftTopIn(typeIcon, control, position, 3)
    end

    local techUI = UIUtil.CreateText(control, '', unitFontSize, UIUtil.bodyFont)
    techUI:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(techUI, control, 0, -1)

    local modPosition = cellSize - unitFontSize
    local modFill = Bitmap(control)
    LayoutHelpers.SetDimensions(modFill, unitFontSize + 1, unitFontSize + 1)
    modFill:SetSolidColor('00ffffff')
    modFill:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(modFill, control, modPosition - 2, modPosition - 2)

    local modText = UIUtil.CreateText(control, '', unitFontSize, UIUtil.bodyFont)
    modText:DisableHitTest()
    modText:SetColor('ffffffff')
    LayoutHelpers.AtLeftTopIn(modText, control, modPosition, modPosition - 3)

    if bp.Mod then
        modFill:SetSolidColor('ffAA00FF')-- --ffAA00FF'
        modText:SetText('M')
        modText:SetColor('ffffffff')
    end

    local overlay = Bitmap(control)
    LayoutHelpers.SetDimensions(overlay, cellSize, cellSize)
    overlay:SetSolidColor('00ffffff')
    overlay:DisableHitTest()
    LayoutHelpers.AtVerticalCenterIn(overlay, control)
    LayoutHelpers.AtHorizontalCenterIn(overlay, control)

    if bp.Type == 'UPGRADE' or
       bp.CategoriesHash.ISPREENHANCEDUNIT then
        colors.TextChecked = 'ffffffff'  -- --ffffffff'
        colors.TextUncheck = 'ffffffff'  -- --ffffffff'
        colors.FillChecked = 'ad575757'  -- --ad575757'
        colors.FillUncheck = '003e3d3d'  -- --003e3d3d'

        checkbox.selector = overlay
        LayoutHelpers.SetDimensions(checkbox, cellSize, cellSize)
        LayoutHelpers.AtVerticalCenterIn(checkbox, control)
        LayoutHelpers.AtHorizontalCenterIn(checkbox, control)

        overlay:SetSolidColor(colors.FillUncheck)
        techUI:SetColor(colors.TextUncheck)

        if bp.CategoriesHash.ISPREENHANCEDUNIT then
            techUI:SetText(bp.Tech or '')
            LayoutHelpers.AtLeftTopIn(techUI, control, 2, 2)
        end
    else
        colors.TextChecked = 'ffC0C0C0' ----ffC0C0C0
        colors.TextUncheck = 'ff000000' ----ff000000
        colors.FillChecked = 'ff575757' ----ff575757
        colors.FillUncheck = bp.Color or 'ff524A3E' ----ff524A3E

        fill:SetSolidColor(colors.FillUncheck)
        techUI:SetColor(colors.TextUncheck)
        techUI:SetText(bp.Tech or '')
        checkbox.selector = fill
    end

    LayoutHelpers.AtVerticalCenterIn(overlay, control)
    LayoutHelpers.AtHorizontalCenterIn(overlay, control)

    checkbox:DisableHitTest()
    checkbox.bp = bp

    -- Some enhancements/units might be shared between factions so
    -- collect similar checkboxes in the same table using their ID as table key
    if not GUI.checkboxes.Units[bp.ID] then
        GUI.checkboxes.Units[bp.ID] = {}
    end
    table.insert(GUI.checkboxes.Units[bp.ID], checkbox)

    control.HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            return false -- Allows grid scrolling
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

            -- Switching to custom restrictions
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

            -- Update checkboxes with the same blueprint IDs, e.g. Teleporter
            if GUI.checkboxes.Units[self.bp.ID] then
                for _, chkbox in GUI.checkboxes.Units[self.bp.ID] do
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
    colors.FillChecked = 'ff575757'
    colors.FillUncheck = '00000000'
    colors.HoverEnter  = '7F7F7F7F'
    colors.HoverExit   = '00ffffff'

    local control = Bitmap(parent)
    control.preset = preset
    control.presetName = presetName
    LayoutHelpers.SetDimensions(control, cellSize, cellSize)
    control:SetSolidColor(colors.FillUncheck)

    local imagePath = UnitsAnalyzer.GetImagePath(preset, '')

    local fill = Bitmap(control)
    LayoutHelpers.SetDimensions(fill, cellSize - 1, cellSize - 1)
    fill:SetSolidColor(colors.FillUncheck)
    fill:DisableHitTest()
    LayoutHelpers.AtVerticalCenterIn(fill, control)
    LayoutHelpers.AtHorizontalCenterIn(fill, control)

    local hover = Bitmap(control)
    LayoutHelpers.SetDimensions(hover, cellSize, cellSize)
    hover:SetSolidColor('00ffffff')
    hover:DisableHitTest()
    LayoutHelpers.AtVerticalCenterIn(hover, control)
    LayoutHelpers.AtHorizontalCenterIn(hover, control)

    local checkbox = Checkbox(control,
          imagePath, -- up.dds'),
          imagePath, -- over.dds'),
          imagePath, -- down.dds'),
          imagePath, -- down.dds'),
          imagePath, -- dis.dds'),
          imagePath, -- dis.dds'),
          'UI_Tab_Click_01', 'UI_Tab_Rollover_01')
    LayoutHelpers.SetDimensions(checkbox, cellSize - 2, cellSize - 2)
    checkbox:DisableHitTest()
    LayoutHelpers.AtVerticalCenterIn(checkbox, control)
    LayoutHelpers.AtHorizontalCenterIn(checkbox, control)
    GUI.checkboxes.Presets[presetName] = checkbox

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
            GUI.checkboxes.Presets[self.presetName]:HandleEvent(event)
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
        GUI.checkboxes.Presets[name]:SetCheck(isChecked)
    end
end

function ToggleUnitCheckboxes(isChecked)
      for ID, _ in restrictions.Custom do
        restrictions.Custom[ID] = isChecked
    end

    for ID, _ in restrictions.Presets do
        restrictions.Presets[ID] = isChecked
    end

    for _, chkboxes in GUI.checkboxes.Units do
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

    -- Combine all selected restriction presets
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

    -- Create expression from unified categories
    for category, _ in categories do
        if expressions then
            expressions = expressions .. " + (" .. category .. ")"
        else
            expressions = "(" .. category .. ")"
        end
    end

    for bpID, chkboxes in GUI.checkboxes.Units do
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

    timer:Start('SortUnits', false)
    local unitsSorted = SortUnits(units, sortCategories, sortReversed)
    timer:Stop('SortUnits', false)

    local row = 1
    for unitID, unit in unitsSorted do
        local unitIcon = CreateUnitIcon(GUI.unitsGrid, unit, faction)
        CreateGridCell(GUI.unitsGrid, unitIcon, col, row)
        row = row + 1
    end
    col = col + 1

    return col
end

-- Adds safely an icon to specified grid and increases grid size if needed
function CreateGridCell(targetGrid, icon, col, row)
    targetGrid.rows = targetGrid.rows or 0
    targetGrid.cols = targetGrid.cols or 0

    -- Make sure we have enough rows in the grid
    while targetGrid.rows < row do
        targetGrid.rows = targetGrid.rows  + 1
        targetGrid:AppendRows(1, true)
    end

    -- Make sure we have enough columns in the grid
    while targetGrid.cols < col do
        targetGrid.cols = targetGrid.cols  + 1
        targetGrid:AppendCols(1, true)
    end

    if targetGrid:GetItem(col, row) then
        WARN('Grid already has an item in cell ' .. col .. ',' .. row)
    else
        targetGrid:SetItem(icon, col, row, true)
    end
    targetGrid.icons = targetGrid.icons + 1
    targetGrid.cells = targetGrid.rows * targetGrid.cols
end

function CreateGrid(parent, cellSize, cellSize, cols, rows)
    local grid = Grid(parent, cellSize, cellSize)
    grid.rows = 0
    grid.cols = 0
    grid.icons = 0

    if cols > 0 then
        grid.cols = cols
        grid:AppendCols(grid.cols, true)
    end

    if rows > 0 then
        grid.rows = rows
        grid:AppendRows(grid.rows, true)
    end
    grid.cells = grid.rows * grid.cols

    return grid
end

-- Compares two variables of any type
function CompareUnitsBy(a, b)
    local typeA, typeB = type(a), type(b)
    if typeA ~= typeB then -- Order by type
        return typeA < typeB
    elseif typeA == "number" and typeB == "number" then
        if math.abs(a - b) < 0.0001 then
            return 0
        else
            return a > b -- Numbers in decreasing order
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
        return tostring(a) < tostring(b) -- Order by address
    end
end

-- Compares two units using their categories
-- @param a - first blueprint
-- @param b - second blueprint
-- @param sortCategories - table with sort categories
-- @param sortReversed - optional boolean for sorting in revers of order specified in sortCategories
function CompareUnitsOrder(a, b, sortCategories, sortReversed)

    if table.empty(sortCategories) then
        return 0
    end

    local orderA = nil
    local orderB = nil
    local categoryA = nil
    local categoryB = nil

    -- Find sorting index using units' Categories or IDs
    for orderIndex, category in sortCategories do
        local isMatching = a.CategoriesHash[category] or a.ID == category
        if not orderA and isMatching then
            orderA = orderIndex
            categoryA = category
        end
        local isMatching = b.CategoriesHash[category] or b.ID == category
        if not orderB and isMatching then
            orderB = orderIndex
            categoryB = category
        end
        -- check if found unique order indexes
        if orderA and orderB then
            if orderA == orderB then
                orderA = nil
                orderB = nil
            else
                break
            end
        end
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

    if table.empty(unitsByID) then
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
