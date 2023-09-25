-- This file contains key bindable actions that don't fit elsewhere

local Prefs = import("/lua/user/prefs.lua")
local SelectionUtils = import("/lua/ui/game/selection.lua")

local lockZoomEnable = false
function lockZoom()
    if lockZoomEnable then
        local options = Prefs.GetFromCurrentProfile('options')
        value = options.wheel_sensitivity
        ConExecute("cam_ZoomAmount " .. tostring(value / 100))

        lockZoomEnable = false
    else
        ConExecute("cam_ZoomAmount 0")
        lockZoomEnable = true
    end
end

function airNoTransports()
    UISelectionByCategory("AIR + MOBILE", false, false, false, false)
    SelectUnits(EntityCategoryFilterDown(categories.ALLUNITS - categories.TRANSPORTATION, GetSelectedUnits()))
end

function airTransports()
    UISelectionByCategory("TRANSPORTATION", false, false, false, false)
end

function ToggleRepeatBuild()
    local selection = GetSelectedUnits()
    if selection then
        local allFactories = true
        local currentInfiniteQueueCheckStatus = false
        for _, v in selection do
            if v:IsRepeatQueue() then
                currentInfiniteQueueCheckStatus = true
            end

            if not v:IsInCategory('FACTORY') then
                allFactories = false
            end
        end

        if allFactories then
            for _, v in selection do
                if currentInfiniteQueueCheckStatus then
                    v:ProcessInfo('SetRepeatQueue', 'false')
                else
                    v:ProcessInfo('SetRepeatQueue', 'true')
                end
            end
        end
    end
end

-- Function to toggle things like shields etc
-- Unit toggle rules copied from orders.lua, used for converting to the numbers needed for the togglescriptbit function
unitToggleRules = {
    Shield = 0,
    Weapon = 1,
    Jamming = 2,
    Intel = 3,
    Production = 4,
    Stealth = 5,
    Generic = 6,
    Special = 7,
    Cloak = 8,
}

function toggleScript(name)
    local selection = GetSelectedUnits()
    local number = unitToggleRules[name]
    local currentBit = GetScriptBit(selection, number)
    ToggleScriptBit(selection, number, currentBit)
end

function toggleAllScript()
    local selection = GetSelectedUnits()
    for i = 0, 8 do
        local currentBit = GetScriptBit(selection, i)
        ToggleScriptBit(selection, i, currentBit)
    end
end

local FILTERS = {
    Military = { "defense", "antinavy", "miscellaneous", "antiair", "directfire", "indirectfire" },
    Intel = { "counterintel", "omni", "radar", "sonar" }
}

function toggleOverlay(type)
    local currentFilters = Prefs.GetFromCurrentProfile('activeFilters') or {}
    local filterSet = FILTERS[type]

    -- Determine if any of the filters from the selected filter set are active.
    local filtersAreActive = false
    for _, filter in filterSet do
        if currentFilters[filter] then
            filtersAreActive = true
            break
        end
    end

    -- If any filters are active, turn them all off. Otherwise turn them all on.
    for _, filter in filterSet do
        if filtersAreActive then
            currentFilters[filter] = nil
        else
            currentFilters[filter] = true
        end
    end

    Prefs.SetToCurrentProfile('activeFilters', currentFilters)
    import("/lua/ui/game/multifunction.lua").UpdateActiveFilters()
end

--- Function builder for "Get next factory of type" functions
-- @param factoryType The type of factory (LAND, AIR, NAVAL) for which a cycling function is wanted.
function getGetNextFactory(factoryType)
    local currentFactoryIndex = 1
    local categoryFilter = "FACTORY * " .. factoryType

    return function()
        UISelectionByCategory(categoryFilter, false, false, false, false)
        local factoryList = GetSelectedUnits()
        if factoryList then
            local nextFac = factoryList[currentFactoryIndex] or factoryList[1]
            currentFactoryIndex = currentFactoryIndex + 1
            if currentFactoryIndex > table.getn(factoryList) then
                currentFactoryIndex = 1
            end
            SelectUnits({ nextFac })
        end
    end
end

GetNextLandFactory = getGetNextFactory("LAND")
GetNextAirFactory = getGetNextFactory("AIR")
GetNextNavalFactory = getGetNextFactory("NAVAL")

function GetNearestIdleLTMex()
    local tech = 1
    while tech < 4 do
        ConExecute('UI_SelectByCategory +nearest +idle +inview MASSEXTRACTION TECH' .. tech)
        tech = tech + 1
        local tempList = GetSelectedUnits()
        if tempList ~= nil and not table.empty(tempList) then
            break
        end
    end
end

function toggleCloakJammingStealthScript()
    toggleScript("Cloak")
    toggleScript("Jamming")
    toggleScript("Stealth")
end

function toggleIntelShieldScript()
    toggleScript("Intel")
    toggleScript("Shield")
end

-- This function might be too slow in larger games, needs testing
function GetSimilarUnits()
    local enhance = import("/lua/enhancementcommon.lua")
    local curSelection = GetSelectedUnits()
    if curSelection then
        -- Find out what enhancements the current unit has
        local curUnitId = curSelection[1]:GetEntityId()
        local curUnitEnhancements = enhance.GetEnhancements(curUnitId)

        -- Select all similar units by category
        local bp = curSelection[1]:GetBlueprint()
        local catString = table.concatkeys(bp.CategoriesHash, " * ")
        UISelectionByCategory(catString, false, false, false, false)

        -- Get enhancements on each unit and filter down to only those with the same as the first unit
        local newSelection = GetSelectedUnits()
        local tempSelectionTable = {}
        for _, unit in newSelection do
            local unitId = unit:GetEntityId()
            local unitEnhancements = enhance.GetEnhancements(unitId)
            if curUnitEnhancements and unitEnhancements then
                if table.equal(unitEnhancements, curUnitEnhancements) then
                    table.insert(tempSelectionTable, unit)
                end
            elseif curUnitEnhancements == nil and unitEnhancements == nil then
                table.insert(tempSelectionTable, unit)
            end
        end
        SelectUnits(tempSelectionTable)

    end
end

local lastACUSelectionTime = 0
function ACUSelectCG()
    local curTime = GetSystemTimeSeconds()
    local diffTime = curTime - lastACUSelectionTime
    if diffTime > 1.0 then
        ConExecute('UI_SelectByCategory +nearest COMMAND')
    else
        ConExecute('UI_SelectByCategory +nearest +goto COMMAND')
    end

    lastACUSelectionTime = curTime
end

function ACUAppendCG()
    local selection = GetSelectedUnits() or {}
    ACUSelectCG()
    AddSelectUnits(selection)
end

local GetDistanceBetweenTwoVectors = import("/lua/utilities.lua").GetDistanceBetweenTwoVectors
function GetNearestIdleEngineerNotACU()
    local idleEngineers = GetIdleEngineers()
    if not idleEngineers then
        return
    end

    local mousePos = GetMouseWorldPos()
    local nearestIndex = 1
    local nearestDist = GetDistanceBetweenTwoVectors(mousePos, idleEngineers[nearestIndex]:GetPosition())
    for index, unit in idleEngineers do
        local dist = GetDistanceBetweenTwoVectors(mousePos, unit:GetPosition())
        if dist < nearestDist then
            nearestIndex = index
            nearestDist = dist
        end
    end

    SelectUnits({ idleEngineers[nearestIndex] })
end

function AddNearestIdleEngineersSeq()
    local allIdleEngineers = GetIdleEngineers() or {}
    local currentSelection = GetSelectedUnits() or {}

    -- Check if current selection contains only idle engineers
    local idleEngineers = allIdleEngineers
    for _, unit in currentSelection do
        local key = table.find(idleEngineers, unit)
        if key then
            table.remove(idleEngineers, key)
        else
            -- Not an idle engineer, clear selection
            SelectUnits(nil)
            currentSelection = {}
            idleEngineers = allIdleEngineers
            break
        end
    end

    if table.empty(idleEngineers) then
        return
    end

    -- Get nearest in list of unselected, idle
    local mousePos = GetMouseWorldPos()
    local nearestIndex = 1
    local nearestDist = GetDistanceBetweenTwoVectors(mousePos, idleEngineers[nearestIndex]:GetPosition())
    for index, unit in idleEngineers do
        local dist = GetDistanceBetweenTwoVectors(mousePos, unit:GetPosition())
        if dist < nearestDist then
            nearestIndex = index
            nearestDist = dist
        end
    end

    AddSelectUnits({ idleEngineers[nearestIndex] })
end

local categoryTable = { 'LAND', 'AIR', 'NAVAL' }
local curFacIndex = 1
function CycleIdleFactories()
    local idleFactories = GetIdleFactories()
    if not idleFactories then
        return
    end

    local sortedFactories = {}
    for i, cat in categoryTable do
        sortedFactories[i] = {}
        sortedFactories[i][1] = EntityCategoryFilterDown(categories.TECH1 * categories[cat], idleFactories)
        sortedFactories[i][2] = EntityCategoryFilterDown(categories.TECH2 * categories[cat], idleFactories)
        sortedFactories[i][3] = EntityCategoryFilterDown(categories.TECH3 * categories[cat], idleFactories)
    end

    local factoriesList = {}
    local i = 3
    while i > 0 do
        for curCat = 1, 3 do
            if not table.empty(sortedFactories[curCat][i]) then
                for _, unit in sortedFactories[curCat][i] do
                    table.insert(factoriesList, unit)
                end
            end
        end
        i = i - 1
    end

    local selection = GetSelectedUnits() or {}
    if table.equal(selection, { factoriesList[curFacIndex] }) then
        curFacIndex = curFacIndex + 1
        if not factoriesList[curFacIndex] then
            curFacIndex = 1
        end
    else
        curFacIndex = 1
    end

    SelectUnits({ factoriesList[curFacIndex] })
end

local unitTypes = {
    categories.LAND * categories.MOBILE - categories.ENGINEER + categories.COMMAND,
    categories.NAVAL * categories.MOBILE,
    categories.AIR * categories.MOBILE,
}
local sortedUnits = {}
local unitCurType = false

function CycleUnitTypesInSel()
    local selection = GetSelectedUnits()
    if not selection then
        return
    end

    local isNewSel = false
    if sortedUnits[unitCurType] then
        for _, unit in selection do
            if not table.find(sortedUnits[unitCurType], unit) then
                isNewSel = true
                break
            end
        end
    else
        isNewSel = true
    end

    if isNewSel then
        -- Sort units
        sortedUnits = {}
        for i, cat in ipairs(unitTypes) do
            local units = EntityCategoryFilterDown(cat, selection)
            if not table.empty(units) then
                table.insert(sortedUnits, units)
            end
        end

        -- First type should be selected
        if not table.empty(sortedUnits) then
            unitCurType = 1
        else
            unitCurType = nil
            return
        end
    else
        -- Next type should be selected
        unitCurType = unitCurType + 1
        if not sortedUnits[unitCurType] then
            unitCurType = 1
        end
    end

    SelectUnits(sortedUnits[unitCurType])
end

function CreateTemplateFactory()
    local currentCommandQueue
    local selection = GetSelectedUnits()
    if selection and table.getn(selection) == 1 and selection[1]:IsInCategory('FACTORY') then
        currentCommandQueue = SetCurrentFactoryForQueueDisplay(selection[1])
    end
    import("/lua/ui/templates_factory.lua").CreateBuildTemplate(currentCommandQueue)
end

--- Creates a sim callback to set the priorities of the selected units
---@param prioritiesString string A string of categories
---@param name string Name of the priority set, used when printing on screen
---@param exclusive boolean ??
function SetWeaponPriorities(prioritiesString, name, exclusive)
    local priotable
    if type(prioritiesString) == 'string' then
        priotable = prioritiesString
    end
    local units = GetSelectedUnits()
    local unitIds = {}

    for _, unit in units or {} do
        table.insert(unitIds, unit:GetEntityId())
    end

    SimCallback({ Func = 'WeaponPriorities',
        Args = { SelectedUnits = unitIds, prioritiesTable = priotable, name = name, exclusive = exclusive or false } })
end

--- Sets selected units to target the unit (and similar units) that is hovered over
function SetWeaponPrioritiesToUnitType()
    local info = GetRolloverInfo()
    if info and info.blueprintId ~= "unknown" then

        local bpId = info.blueprintId
        local text = LOC(__blueprints[bpId].General.UnitName)
        if not text then
            text = LOC(__blueprints[bpId].Interface.HelpText)
        end

        SetWeaponPriorities(findPriority(bpId), text, false)
    end
end

--- Sets selected units to their default target priority
function SetDefaultWeaponPriorities()
    SetWeaponPriorities(0, "Default", false)
end

local categoriesToCheck = {
    ['tech'] = { "TECH1", "TECH2", "TECH3", "EXPERIMENTAL", 'COMMAND' },
    ['faction'] = { "CYBRAN", "UEF", "AEON", "SERAPHIM" },
    ['type'] = { "FACTORY", 'SCOUT', "DIRECTFIRE", 'INDIRECTFIRE', 'DEFENSE', "ANTIAIR", 'TRANSPORTATION', "ENGINEER", },
    ['layer'] = { "NAVAL", "AIR", "LAND", "STRUCTURE" },
}

--- Creates a target priority that includes the tech, faction, type, and layer of a unit
---@param bpId string The ID of the unit which is to be targetted
function findPriority(bpID)

    local bp = __blueprints[bpID]
    if bp then

        local categories = bp.CategoriesHash
        local tech, faction, unitType, layer

        for _, c in categoriesToCheck['tech'] do
            if categories[c] then tech = c end
        end

        for _, c in categoriesToCheck['faction'] do
            if categories[c] then faction = c end
        end

        for _, c in categoriesToCheck['type'] do
            if categories[c] then unitType = c end
        end

        for _, c in categoriesToCheck['layer'] do
            if categories[c] then layer = c end
        end

        if not (tech and faction and unitType and layer) then
            return string.format("{categories.%s}", bpID)
        end

        local a = string.format("categories.%s * categories.%s * categories.%s * categories.%s", tech, faction, unitType
            , layer)
        local b = string.format("categories.%s * categories.%s * categories.%s", tech, unitType, layer)
        local c = string.format("categories.%s * categories.%s", unitType, layer)
        local d = string.format("categories.%s", layer)

        local priorities = string.format("{categories.%s, %s, %s, %s, %s}", bpID, a, b, c, d)
        return priorities
    else
        -- go to defaults, not sure what happened here but unit id is unknown
        return nil
    end
end

function SelectAllUpgradingExtractors()

    -- by default, hide playing the selection sound
    SelectionUtils.EnableSelectionSound(false)

    -- try and find extractors
    local oldSelection = GetSelectedUnits()
    UISelectionByCategory("MASSEXTRACTION", false, false, false, false)
    local selection = GetSelectedUnits()
    if selection then

        -- try and find extractors that are upgrading
        local upgrading = {}
        for k, unit in selection do
            if unit:GetWorkProgress() > 0 then
                table.insert(upgrading, unit)
            end
        end

        if next(upgrading) then
            SelectionUtils.EnableSelectionSound(true)
            SelectUnits(upgrading)
        end
    else
        SelectUnits(oldSelection)
    end

    SelectionUtils.EnableSelectionSound(true)
end

local hardMoveEnabled = false
function ToggleHardMove()
    ---@type WorldView
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    if hardMoveEnabled then
        import('/lua/ui/game/commandmode.lua').RestoreCommandMode()
        view:SetDefaultSelectTolerance()
        view:DefaultCursor()
        hardMoveEnabled = false
    else
        import('/lua/ui/game/commandmode.lua').CacheAndClearCommandMode()
        view:SetIgnoreSelectTolerance()
        view:OverrideCursor('RULEUCC_Move')
        hardMoveEnabled = true
    end
end

-- untoggle hard move when we have no units selected
import("/lua/ui/game/gamemain.lua").ObserveSelection:AddObserver(
    function(selectionInfo)
        if hardMoveEnabled and table.getn(selectionInfo.newSelection) == 0 then
            ToggleHardMove()
        end
    end,
    'KeyActionHardMove'
)

LoadIntoTransports = function(clearCommands)
    print("Load units into transports")
    SimCallback({ Func = 'LoadIntoTransports', Args = { ClearCommands = clearCommands or false } }, true)
end

AssignPlatoonBehaviorSilo = function()
    SimCallback({ Func = 'AIPlatoonSiloTacticalBehavior', Args = { Behavior = 'AIBehaviorTacticalSimple' } }, true)
end

AIPlatoonSimpleRaidBehavior = function()
    SimCallback({ Func = 'AIPlatoonSimpleRaidBehavior', Args = {} }, true)
end

AIPlatoonSimpleStructureBehavior = function()
    SimCallback({ Func = 'AIPlatoonSimpleStructureBehavior', Args = {} }, true)
end

StoreCameraPosition = function()
    local camera = GetCamera('WorldCamera')
    local settings = camera:SaveSettings()
    Prefs.SetToCurrentProfile('DebugCameraPosition', settings)
end

RestoreCameraPosition = function()
    -- ConExecute('cam_Free 1')
    local camera = GetCamera('WorldCamera')
    local settings = Prefs.GetFromCurrentProfile('DebugCameraPosition') --[[@as UserCameraSettings]]
    camera:MoveTo(settings.Focus, { settings.Heading, settings.Pitch, 0 }, settings.Zoom, 0)
end

local function SeparateDiveStatus(units)
    local dummyUnitTable = {}
    local categoriesSubmersible = categories.SUBMERSIBLE

    local submergedUnits = {}
    local surfacedUnits = {}

    for k, unit in units do
        dummyUnitTable[1] = unit
        local status = GetIsSubmerged(dummyUnitTable)
        if status == -1 then
            table.insert(submergedUnits, unit)
        elseif status == 1 then
            table.insert(surfacedUnits, unit)
        end
    end

    return submergedUnits, surfacedUnits
end

DiveAll = function()
    print("Dive all")
    local submergedUnits, surfacedUnits = SeparateDiveStatus(GetSelectedUnits())
    if not table.empty(surfacedUnits) then
        IssueUnitCommand(surfacedUnits, "UNITCOMMAND_Dive")
    end
end

SurfaceAll = function()
    print("Surface all")
    local submergedUnits, surfacedUnits = SeparateDiveStatus(GetSelectedUnits())
    if not table.empty(submergedUnits) then
        IssueUnitCommand(submergedUnits, "UNITCOMMAND_Dive")
    end
end

---@param onscreen boolean
SelectAllBuildingEngineers = function(onscreen)
    -- make sure it is always a boolean
    onscreen = onscreen or false

    -- select engineers
    UISelectionByCategory('ENGINEER', false, onscreen, false, false)

    -- filter them in-place
    local units = GetSelectedUnits()
    local unitCount = table.getn(units)
    local unitSelectedHead = 1
    for k = 1, unitCount do
        local unit = units[k]
        local eco = unit:GetEconData()
        if (eco.energyRequested > 0) or (eco.massRequested > 0) then
            units[unitSelectedHead] = unit
            unitSelectedHead = unitSelectedHead + 1
        end
    end

    -- remove empty entries
    for k = unitSelectedHead, unitCount do
        units[k] = nil
    end

    SelectUnits(units)
end


---@param onscreen boolean
SelectAllResourceConsumers = function(onscreen)
    -- make sure it is always a boolean
    onscreen = onscreen or false

    -- select units
    UISelectionByCategory("SHOWQUEUE", false, onscreen, false, false)
    UISelectionByCategory("SILO", true, onscreen, false, false)
    UISelectionByCategory("REPAIR", true, onscreen, false, false)

    -- filter them in-place
    local units = GetSelectedUnits()
    local unitCount = table.getn(units)
    local unitSelectedHead = 1
    for k = 1, unitCount do
        local unit = units[k]
        local eco = unit:GetEconData()
        if (eco.energyRequested > 0) or (eco.massRequested > 0) then
            units[unitSelectedHead] = unit
            unitSelectedHead = unitSelectedHead + 1
        end
    end

    -- remove empty entries
    for k = unitSelectedHead, unitCount do
        units[k] = nil
    end

    SelectUnits(units)
end

TogglePerformanceMetricsWindow = function()
    local instance = import("/lua/ui/lobby/sim-performance-popup.lua").OpenWindow()
end
