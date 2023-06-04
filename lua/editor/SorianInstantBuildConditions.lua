--****************************************************************************
--**
--**  File     :  /lua/SorianInstantBuildConditions.lua
--**  Author(s): Michael Robbins aka Sorian
--**
--**  Summary  : Generic AI Platoon Build Conditions
--**             Build conditions always return true or false
--**
--****************************************************************************
local AIUtils = import("/lua/ai/aiutilities.lua")
local SUtils = import("/lua/ai/sorianutilities.lua")

---@param aiBrain AIBrain
---@param locationType string
---@param locationRadius number
---@param category EntityCategory
---@param markerRadius number
---@param unitMax number
---@param threatMin number
---@param threatMax number
---@param threatRings number
---@param threatType string
---@return boolean
function DefensivePointNeedsStructure(aiBrain, locationType, locationRadius, category, markerRadius, unitMax, threatMin, threatMax, threatRings, threatType)
    local pos, name = AIUtils.AIFindDefensivePointNeedsStructureSorian(aiBrain, locationType, locationRadius, category, markerRadius, unitMax, threatMin, threatMax, threatRings, threatType)
    if pos then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param locationType string
---@param locationRadius number
---@param category EntityCategory
---@param markerRadius number
---@param unitMax number
---@param threatMin number
---@param threatMax number
---@param threatRings number
---@param threatType string
---@return boolean
function ExpansionPointNeedsStructure(aiBrain, locationType, locationRadius, category, markerRadius, unitMax, threatMin, threatMax, threatRings, threatType)
    local pos, name = AIUtils.AIFindExpansionPointNeedsStructure(aiBrain, locationType, locationRadius, category, markerRadius, unitMax, threatMin, threatMax, threatRings, threatType)
    if pos then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param threatThreshold number
---@return boolean
function AIThreatExists(aiBrain, threatThreshold)
    for k,v in aiBrain.BaseMonitor.AlertsTable do
        if v.Threat >= threatThreshold then
            return true
        end
    end
    return false
end

---@param aiBrain AIBrain
---@param locationType string
---@param num number
---@param unitCategory EntityCategory
---@param unitCategory2 EntityCategory
---@param unitCategory3 EntityCategory
---@return boolean
function FactoryRatioLessOrEqual(aiBrain, locationType, num, unitCategory, unitCategory2, unitCategory3)
    local factoryManager = aiBrain.BuilderManagers[locationType].FactoryManager
    local testCat = unitCategory
    if type(unitCategory) == 'string' then
        testCat = ParseEntityCategory(unitCategory)
    end
    local testCat2 = unitCategory2
    if type(unitCategory2) == 'string' then
        testCat2 = ParseEntityCategory(unitCategory2)
    end
    local testCat3 = unitCategory3
    if type(unitCategory3) == 'string' then
        testCat3 = ParseEntityCategory(unitCategory3)
    end
    if not factoryManager then
        WARN('*AI WARNING: FactoryComparisonAtLocation - Invalid location - ' .. locationType)
        return false
    end
    local numUnits = factoryManager:GetNumCategoryFactories(testCat)
    local numUnits2 = factoryManager:GetNumCategoryFactories(testCat2)
    local numUnits3 = factoryManager:GetNumCategoryFactories(testCat3)
    if numUnits == 0 and numUnits2 == 0 then
        return true
    elseif numUnits2 == 0 and (numUnits - numUnits2 <= num or numUnits3 < 1) then
        return true
    elseif numUnits2 > 0 and (numUnits / numUnits2 <= num or numUnits3 < 1) then
        return true
    else
        return false
    end
end

---@param aiBrain AIBrain
---@param health number
---@param shield number
---@return boolean
function CDRHealthGreaterThan(aiBrain, health, shield)
    local cdr = aiBrain:GetListOfUnits(categories.COMMAND, false)[1]
    if not cdr then return false end
    local cdrhealth = cdr:GetHealthPercent()
    local cdrshield
    if (cdr:HasEnhancement('Shield') or cdr:HasEnhancement('ShieldGeneratorField') or cdr:HasEnhancement('ShieldHeavy')) and cdr:ShieldIsOn() then
        cdrshield = (cdr.MyShield:GetHealth() / cdr.MyShield:GetMaxHealth())
    else
        cdrshield = 1
    end
    if cdrhealth >= health and cdrshield >= shield then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param numReq number
---@param category EntityCategory
---@param idleReq boolean
---@return boolean
function HaveGreaterThanUnitsWithCategory(aiBrain, numReq, category, idleReq)
    local numUnits
    local total = 0
    if type(category) == 'string' then
        category = ParseEntityCategory(category)
    end
    if not idleReq then
        numUnits = aiBrain:GetListOfUnits(category, false)
    else
        numUnits = aiBrain:GetListOfUnits(category, true)
    end
    for k,v in numUnits do
        if v:GetFractionComplete() == 1 then
            total = total + 1
            if total > numReq then
                return true
            end
        end
    end
    if total > numReq then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param numReq number
---@param category EntityCategory
---@param idleReq boolean
---@return boolean
function HaveLessThanUnitsWithCategory(aiBrain, numReq, category, idleReq)
    local numUnits
    local total = 0
    if type(category) == 'string' then
        category = ParseEntityCategory(category)
    end
    if not idleReq then
        numUnits = aiBrain:GetListOfUnits(category, false)
    else
        numUnits = aiBrain:GetListOfUnits(category, true)
    end
    for k,v in numUnits do
        if v:GetFractionComplete() == 1 then
            total = total + 1
            if total >= numReq then
                return false
            end
        end
    end
    if total >= numReq then
        return false
    end
    return true
end

---@param aiBrain AIBrain
---@param sizetable number
---@param category EntityCategory
---@param idleReq boolean
---@return boolean
function HaveLessThanUnitsForMapSize(aiBrain, sizetable, category, idleReq)
    local numUnits
    local total = 0
    local mapSizeX, mapSizeZ = GetMapSize()
    if not sizetable[mapSizeX] or not sizetable[mapSizeZ] then
        return false
    end
    local numReq = sizetable[mapSizeX] or sizetable[mapSizeZ]
    if type(category) == 'string' then
        category = ParseEntityCategory(category)
    end
    if not idleReq then
        numUnits = aiBrain:GetCurrentUnits(category)
    else
        numUnits = table.getn(aiBrain:GetListOfUnits(category, true))
    end
    if numUnits < numReq then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param numunits number
---@param category EntityCategory
---@return boolean
function HaveLessThanUnitsInCategoryBeingBuilt(aiBrain, numunits, category)
    if type(category) == 'string' then
        category = ParseEntityCategory(category)
    end

    local unitsBuilding = aiBrain:GetListOfUnits(categories.CONSTRUCTION, false)
    local numBuilding = 0
    for unitNum, unit in unitsBuilding do
        if not unit:BeenDestroyed() and unit:IsUnitState('Building') then
            local buildingUnit = unit.UnitBeingBuilt
            if buildingUnit and not buildingUnit.Dead and EntityCategoryContains(category, buildingUnit) then
                numBuilding = numBuilding + 1
            end
        end
        if numunits <= numBuilding then
            return false
        end
    end
    if numunits > numBuilding then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param numunits number
---@param category EntityCategory
---@return boolean
function HaveGreaterThanUnitsInCategoryBeingBuilt(aiBrain, numunits, category)
    if type(category) == 'string' then
        category = ParseEntityCategory(category)
    end

    local unitsBuilding = aiBrain:GetListOfUnits(categories.CONSTRUCTION, false)
    local numBuilding = 0
    for unitNum, unit in unitsBuilding do
        if not unit:BeenDestroyed() and unit:IsUnitState('Building') then
            local buildingUnit = unit.UnitBeingBuilt
            if buildingUnit and not buildingUnit.Dead and EntityCategoryContains(category, buildingUnit) then
                numBuilding = numBuilding + 1
            end
        end
        if numunits < numBuilding then
            return true
        end
    end
    return false
end

---@param aiBrain AIBrain
---@param mTrend number
---@param eTrend number
---@return boolean
function LessThanEconTrend(aiBrain, mTrend, eTrend)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, 'ENERGYPRODUCTION EXPERIMENTAL STRUCTURE') then
        --LOG('*AI DEBUG: Found Paragon')
        return false
    end
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    local cheatmult = tonumber(ScenarioInfo.Options.CheatMult) or 2
    if aiBrain.CheatEnabled and (econ.MassTrend < mTrend * cheatmult and econ.EnergyTrend < eTrend * cheatmult) then
        return true
    elseif not aiBrain.CheatEnabled and (econ.MassTrend < mTrend and econ.EnergyTrend < eTrend) then
        return true
    else
        return false
    end
end

---@param aiBrain AIBrain
---@param MassEfficiency number
---@param EnergyEfficiency number
---@return boolean
function GreaterThanEconEfficiencyOverTimeExp(aiBrain, MassEfficiency, EnergyEfficiency)
    local unitsBuilding = aiBrain:GetListOfUnits(categories.CONSTRUCTION, false)
    local numBuilding = 0
    for unitNum, unit in unitsBuilding do
        if not unit:BeenDestroyed() and unit:IsUnitState('Building') then
            local buildingUnit = unit.UnitBeingBuilt
            if buildingUnit and not buildingUnit.Dead and EntityCategoryContains(categories.EXPERIMENTAL, buildingUnit) then
                numBuilding = numBuilding + 1
            end
        end
    end

    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassEfficiencyOverTime >= MassEfficiency + (numBuilding * .2) and econ.EnergyEfficiencyOverTime >= EnergyEfficiency + (numBuilding * .2)) then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param MassIncome number
---@param EnergyIncome number
---@return boolean
function GreaterThanEconIncome(aiBrain, MassIncome, EnergyIncome)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, 'ENERGYPRODUCTION EXPERIMENTAL STRUCTURE') then
        --LOG('*AI DEBUG: Found Paragon')
        return true
    end
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassIncome >= MassIncome and econ.EnergyIncome >= EnergyIncome) then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param MassIncome number
---@param EnergyIncome number
---@return boolean
function LessThanEconIncome(aiBrain, MassIncome, EnergyIncome)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, 'ENERGYPRODUCTION EXPERIMENTAL STRUCTURE') then
        --LOG('*AI DEBUG: Found Paragon')
        return false
    end
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassIncome < MassIncome and econ.EnergyIncome < EnergyIncome) then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param MassIncome number
---@param EnergyIncome number
---@return boolean
function GreaterThanEconIncomeOverTime(aiBrain, MassIncome, EnergyIncome)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassIncomeOverTime >= MassIncome and econ.EnergyIncomeOverTime >= EnergyIncome) then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param MassEfficiency number
---@param EnergyEfficiency number
---@return boolean
function GreaterThanEconEfficiency(aiBrain, MassEfficiency, EnergyEfficiency)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, 'ENERGYPRODUCTION EXPERIMENTAL STRUCTURE') then
        --LOG('*AI DEBUG: Found Paragon')
        return true
    end
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassEfficiency >= MassEfficiency and econ.EnergyEfficiency >= EnergyEfficiency) then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param MassEfficiency number
---@param EnergyEfficiency number
---@return boolean
function LessThanEconEfficiency(aiBrain, MassEfficiency, EnergyEfficiency)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, 'ENERGYPRODUCTION EXPERIMENTAL STRUCTURE') then
        --LOG('*AI DEBUG: Found Paragon')
        return false
    end
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassEfficiency <= MassEfficiency and econ.EnergyEfficiency <= EnergyEfficiency) then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param MassEfficiency number
---@param EnergyEfficiency number
---@return boolean
function GreaterThanEconEfficiencyOverTime(aiBrain, MassEfficiency, EnergyEfficiency)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, 'ENERGYPRODUCTION EXPERIMENTAL STRUCTURE') then
        --LOG('*AI DEBUG: Found Paragon')
        return true
    end
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassEfficiencyOverTime >= MassEfficiency and econ.EnergyEfficiencyOverTime >= EnergyEfficiency) then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param MassEfficiency number
---@param EnergyEfficiency number
---@return boolean
function LessThanEconEfficiencyOverTime(aiBrain, MassEfficiency, EnergyEfficiency)
    if HaveGreaterThanUnitsWithCategory(aiBrain, 0, 'ENERGYPRODUCTION EXPERIMENTAL STRUCTURE') then
        --LOG('*AI DEBUG: Found Paragon')
        return false
    end
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassEfficiencyOverTime <= MassEfficiency and econ.EnergyEfficiencyOverTime <= EnergyEfficiency) then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param MassIncome number
---@param EnergyIncome number
---@return boolean
function LessThanEconIncomeOverTime(aiBrain, MassIncome, EnergyIncome)
    local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
    if (econ.MassIncomeOverTime < MassIncome and econ.EnergyIncomeOverTime < EnergyIncome) then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@param doesbool boolean
---@param locationType string
---@param category EntityCategory
---@return boolean
function EngineerNeedsAssistance(aiBrain, doesbool, locationType, category)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    if not engineerManager then
        return false
    end
    local numFound = 0
    for _,cat in category do
        local bCategory = ParseEntityCategory(cat)

        local engs = engineerManager:GetEngineersBuildingCategory(bCategory, categories.ALLUNITS)
        for k,v in engs do
            if v.DesiresAssist == true then
                if v.MinNumAssistees and SUtils.GetGuards(aiBrain, v) < v.MinNumAssistees then
                    numFound = numFound + 1
                end
            end
            if numFound > 0 and doesbool then return true end
        end

        engs = engineerManager:GetEngineersBuildQueue(cat)
        for k,v in engs do
            if v.DesiresAssist == true then
                if v.MinNumAssistees and SUtils.GetGuards(aiBrain, v) < v.MinNumAssistees then
                    numFound = numFound + 1
                end
            end
            if numFound > 0 and doesbool then return true end
        end
    end

    if numFound == 0 and not doesbool then return true end
    return false
end

---@param aiBrain AIBrain
---@return boolean
function LessThanExpansionBases(aiBrain)
    local expBaseCount = 0
    local numberofAIs = SUtils.GetNumberOfAIs(aiBrain)
    local startX, startZ = aiBrain:GetArmyStartPos()
    local isWaterMap = false
    local checkNum = tonumber(ScenarioInfo.Options.LandExpansionsAllowed) or 5
    local navalMarker = AIUtils.AIGetClosestMarkerLocation(aiBrain, 'Naval Area', startX, startZ)
    if navalMarker then
        isWaterMap = true
    end
    expBaseCount = aiBrain:GetManagerCount('Start Location')
    expBaseCount = expBaseCount + aiBrain:GetManagerCount('Expansion Area')
    checkNum = checkNum - numberofAIs
    if isWaterMap and expBaseCount < checkNum then
        return true
    elseif not isWaterMap and expBaseCount < checkNum + 1 then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@return boolean
function GreaterThanExpansionBases(aiBrain)
    return not LessThanExpansionBases(aiBrain)
end

---@param aiBrain AIBrain
---@return boolean
function LessThanNavalBases(aiBrain)
    local expBaseCount = 0
    local checkNum = tonumber(ScenarioInfo.Options.NavalExpansionsAllowed) or 4
    local isIsland = import("/lua/editor/sorianbuildconditions.lua").IsIslandMap(aiBrain)
    expBaseCount = aiBrain:GetManagerCount('Naval Area')
    --LOG('*AI DEBUG: '.. aiBrain.Nickname ..' LessThanNavalBases Total = '..expBaseCount)
    if isIsland and expBaseCount < checkNum then
        return true
    elseif not isIsland and expBaseCount < checkNum - 2 then
        return true
    end
    return false
end

---@param aiBrain AIBrain
---@return boolean
function GreaterThanNavalBases(aiBrain)
    return not LessThanNavalBases(aiBrain)
end

---@param aiBrain AIBrain
---@return boolean
function T4BuildingCheck(aiBrain)
    if aiBrain.T4Building then
        return false
    end
    return true
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@param compareType string
---@return boolean
function HavePoolUnitComparisonAtLocationExp(aiBrain, locationType, unitCount, unitCategory, compareType)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    local testCat = unitCategory
    if type(unitCategory) == 'string' then
        testCat = ParseEntityCategory(unitCategory)
    end
    if not engineerManager then
        WARN('*AI WARNING: HavePoolUnitComparisonAtLocation - Invalid location - ' .. locationType)
        return false
    end
    local poolPlatoon = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    local numUnits = poolPlatoon:GetNumCategoryUnits(testCat, engineerManager:GetLocationCoords(), engineerManager.Radius * 2.5)
    return CompareBody(numUnits, unitCount, compareType)
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@return boolean
function PoolLessAtLocationExp(aiBrain, locationType, unitCount, unitCategory)
    return HavePoolUnitComparisonAtLocationExp(aiBrain, locationType, unitCount, unitCategory, '<')
end

---@param aiBrain AIBrain
---@param locationType string
---@param unitCount number
---@param unitCategory EntityCategory
---@return boolean
function PoolGreaterAtLocationExp(aiBrain, locationType, unitCount, unitCategory)
    return HavePoolUnitComparisonAtLocationExp(aiBrain, locationType, unitCount, unitCategory, '>')
end

---@param numOne number
---@param numTwo number
---@param compareType string
---@return boolean
function CompareBody(numOne, numTwo, compareType)
    if compareType == '>' then
        if numOne > numTwo then
            return true
        end
    elseif compareType == '<' then
        if numOne < numTwo then
            return true
        end
    elseif compareType == '>=' then
        if numOne >= numTwo then
            return true
        end
    elseif compareType == '<=' then
        if numOne <= numTwo then
            return true
        end
    else
        error('*AI ERROR: Invalid compare type: ' .. compareType)
        return false
    end
    return false
end


-- Moved Unused Imports to bttom fro mod support

local ScenarioFramework = import("/lua/scenarioframework.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local Utils = import("/lua/utilities.lua")