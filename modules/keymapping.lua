local Prefs = import('/lua/user/prefs.lua')

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
UISelectionByCategory("AIR + MOBILE", false,false,false,false) SelectUnits(EntityCategoryFilterDown(categories.ALLUNITS - categories.TRANSPORTATION, GetSelectedUnits()))
end

function airTransports()
UISelectionByCategory("TRANSPORTATION", false,false,false,false)
end

function ToggleRepeatBuild()
    local selection = GetSelectedUnits()
    if selection then
        local allFactories = true
        local currentInfiniteQueueCheckStatus = false
        for i,v in selection do
            if v:IsRepeatQueue() then
                currentInfiniteQueueCheckStatus = true
            end
            if not v:IsInCategory('FACTORY') then
                allFactories = false
            end
        end
        if allFactories then
            for i,v in selection do
                if currentInfiniteQueueCheckStatus then
                    v:ProcessInfo('SetRepeatQueue', 'false')
                else
                    v:ProcessInfo('SetRepeatQueue', 'true')
                end
            end
        end
    end
end

--function to toggle things like shields etc
-- Unit toggle rules copied from orders.lua, used for converting to the numbers needed for the togglescriptbit function
unitToggleRules = {
    Shield =  0,
    Weapon = 1,
    Jamming = 2,
    Intel = 3,
    Production = 4,
    Stealth = 5,
    Generic = 6,
    Special = 7,
Cloak = 8,}

function toggleScript(name)
    local selection = GetSelectedUnits()
    local number = unitToggleRules[name]
    local currentBit = GetScriptBit(selection, number)
    ToggleScriptBit(selection, number, currentBit)
end

function toggleAllScript(name)
    local selection = GetSelectedUnits()
    for i = 0,8 do
        local currentBit = GetScriptBit(selection, i)
        ToggleScriptBit(selection, i, currentBit)
    end
end

local MilitaryFilters = {"Defense","AntiNavy","Miscellaneous","AntiAir","DirectFire","IndirectFire"}
local IntelFilters = {"CounterIntel", "Omni", "Radar", "Sonar"}

function toggleOverlay(type)
    local currentFilters = Prefs.GetFromCurrentProfile('activeFilters') or {}
    local tempFilters = {}
    local MilitaryActive = false
    local IntelActive = false
    for i, filter in MilitaryFilters do
        if currentFilters[string.lower(filter)] then
            MilitaryActive = true
        end
    end
    for i, filter in IntelFilters do
        if currentFilters[string.lower(filter)] then
            IntelActive = true
        end
    end

    local function toggleFilters(filterTable, active)
        for i, filter in filterTable do
            if active then
                currentFilters[string.lower(filter)] = nil
            else
                currentFilters[string.lower(filter)] = true
                table.insert(tempFilters, filter)
            end
        end
    end

    if type == 'Military' then
        toggleFilters(MilitaryFilters, MilitaryActive)
        if IntelActive then
            for i, filter in IntelFilters do
                table.insert(tempFilters, filter)
            end
        end
    end

    if type == 'Intel' then
        toggleFilters(IntelFilters, IntelActive)
        if MilitaryActive then
            for i, filter in MilitaryFilters do
                table.insert(tempFilters, filter)
            end
        end
    end

    Prefs.SetToCurrentProfile('activeFilters', currentFilters)
    import('/lua/ui/game/multifunction.lua').UpdateActiveFilters()
end

local currentLandFactoryIndex = 1
local currentAirFactoryIndex = 1
local currentNavalFactoryIndex = 1


function GetNextLandFactory()
    UISelectionByCategory("FACTORY * LAND", false, false, false, false)
    local FactoryList = GetSelectedUnits()
    if FactoryList then
        local nextFac = FactoryList[currentLandFactoryIndex] or FactoryList[1]
        currentLandFactoryIndex = currentLandFactoryIndex + 1
        if currentLandFactoryIndex > table.getn(FactoryList) then
            currentLandFactoryIndex = 1
        end
        SelectUnits({nextFac})
    end
end

function GetNextAirFactory()
    UISelectionByCategory("FACTORY * AIR", false, false, false, false)
    local FactoryList = GetSelectedUnits()
    if FactoryList then
        local nextFac = FactoryList[currentAirFactoryIndex] or FactoryList[1]
        currentAirFactoryIndex = currentAirFactoryIndex + 1
        if currentAirFactoryIndex > table.getn(FactoryList) then
            currentAirFactoryIndex = 1
        end
        SelectUnits({nextFac})
    end
end

function GetNextNavalFactory()
    UISelectionByCategory("FACTORY * NAVAL", false, false, false, false)
    local FactoryList = GetSelectedUnits()
    if FactoryList then
        local nextFac = FactoryList[currentNavalFactoryIndex] or FactoryList[1]
        currentNavalFactoryIndex = currentNavalFactoryIndex + 1
        if currentNavalFactoryIndex > table.getn(FactoryList) then
            currentNavalFactoryIndex = 1
        end
        SelectUnits({nextFac})
    end
end

function GetNearestIdleLTMex()
    local tech = 1
    while (tech < 4) do
        ConExecute('UI_SelectByCategory +nearest +idle +inview MASSEXTRACTION TECH' .. tech)
        tech = tech + 1
        local tempList = GetSelectedUnits()
        if (tempList ~= nil) and (table.getn(tempList) > 0) then
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

--this function might be too slow in larger games, needs testing
function GetSimilarUnits()
    local enhance = import('/lua/enhancementcommon.lua')
    local curSelection = GetSelectedUnits()
    if curSelection then
        --find out what enhancements the current unit has
        local curUnitId = curSelection[1]:GetEntityId()
        local curUnitEnhancements = enhance.GetEnhancements(curUnitId)

        --select all similar units by category
        local bp = curSelection[1]:GetBlueprint()
        local bpCats = bp.Categories
        local catString = ""
        for i, cat in bpCats do
            if i == 1 then
                catString = cat
            else
                catString = catString.." * " ..cat
            end
        end
        UISelectionByCategory(catString, false, false, false, false)

        --get enhancements on each unit and filter down to only those with the same as the first unit
        local newSelection = GetSelectedUnits()
        local tempSelectionTable = {}
        for i, unit in newSelection do
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

-- by norem
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

local GetDistanceBetweenTwoVectors = import('/lua/utilities.lua').GetDistanceBetweenTwoVectors

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

    SelectUnits({idleEngineers[nearestIndex]})
end

function AddNearestIdleEngineersSeq()
    local allIdleEngineers = GetIdleEngineers() or {}
    local currentSelection = GetSelectedUnits() or {}

    -- check if current selection contains only idle engineers
    local idleEngineers = allIdleEngineers
    for i, unit in currentSelection do
        local key = table.find(idleEngineers, unit)
        if key then
            table.remove(idleEngineers, key)
        else
            -- not an idle engineer, clear selection
            SelectUnits(nil)
            currentSelection = {}
            idleEngineers = allIdleEngineers
            break
        end
    end
    if table.empty(idleEngineers) then
        return
    end

    -- get nearest in list of unselected, idle
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

    -- compare nearest with already selected
    -- if it is closer than any of them, select it and deselect the others
    -- can be confusing in some situations
    --[[for i, unit in currentSelection do
    if GetDistanceBetweenTwoVectors(mousePos, unit:GetPosition()) > nearestDist then
        SelectUnits({idleEngineers[nearestIndex]})
        return
    end
end]]

AddSelectUnits({idleEngineers[nearestIndex]})
end

local categoryTable = {'LAND','AIR','NAVAL'}
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
            if table.getn(sortedFactories[curCat][i]) > 0 then
                for _, unit in sortedFactories[curCat][i] do
                    table.insert(factoriesList, unit)
                end
            end
        end
        i = i - 1
    end

    local selection = GetSelectedUnits() or {}
    if table.equal(selection, {factoriesList[curFacIndex]}) then
        curFacIndex = curFacIndex + 1
        if not factoriesList[curFacIndex] then
            curFacIndex = 1
        end
    else
        curFacIndex = 1
    end

    SelectUnits({factoriesList[curFacIndex]})
end

local unitTypes = {
    categories.LAND * categories.MOBILE - categories.ENGINEER + categories.COMMAND,
    categories.NAVAL * categories.MOBILE,
    categories.AIR * categories.MOBILE,
}
local sortedUnits = {}
local unitCurType = nil

function CycleUnitTypesInSel()
    local selection = GetSelectedUnits()
    if not selection then
        return
    end

    local isNewSel = false
    if sortedUnits[unitCurType] then
        for i, unit in selection do
            if not table.find(sortedUnits[unitCurType], unit) then
                isNewSel = true
                break
            end
        end
    else
        isNewSel = true
    end

    if isNewSel then
        -- sort units
        sortedUnits = {}
        for i, cat in ipairs(unitTypes) do
            local units = EntityCategoryFilterDown(cat, selection)
            if not table.empty(units) then
                table.insert(sortedUnits, units)
            end
        end

        -- first type should be selected
        if not table.empty(sortedUnits) then
            unitCurType = 1
        else
            unitCurType = nil
            return
        end
    else
        -- next type should be selected
        unitCurType = unitCurType + 1
        if not sortedUnits[unitCurType] then
            unitCurType = 1
        end
    end

    SelectUnits(sortedUnits[unitCurType])
end

function CreateTemplateFactory()
    local currentCommandQueue = nil
    local selection = GetSelectedUnits()
    if selection and table.getn(selection) == 1 and selection[1]:IsInCategory('FACTORY') then
        currentCommandQueue = SetCurrentFactoryForQueueDisplay(selection[1])
    end
    import('/modules/templates_factory.lua').CreateBuildTemplate(currentCommandQueue)
end

-- end by norem