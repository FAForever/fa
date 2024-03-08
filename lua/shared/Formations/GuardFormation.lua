--******************************************************************************************************
--** Copyright (c) 2024 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local ComputeEmbeddedFormation = import('/lua/shared/Formations/EmbeddedFormation.lua').ComputeEmbeddedFormation
local GetFormationEntry = import('/lua/shared/Formations/Formation.lua').GetFormationEntry

--- A table that contains the blueprint lookups that we can re-use.
---@type FormationBlueprintCount
local FormationBlueprintCountCacheA = {}

---@type FormationBlueprintCount
local FormationBlueprintCountCacheB = {}

--- A table that contains the tactical formation that we can re-use.
---@type Formation
local TacticalFormation = {}

local MathSqrt = math.sqrt
local MathCeil = math.ceil
local MathMod = math.mod
local MathFloor = math.floor

local TableGetn = table.getn
local TableSetn = table.setn
local TableSort = table.sort
local TableInsert = table.insert

local categoriesAntiAir = categories.ANTIAIR
local categoriesShield = categories.SHIELD
local categoriesCounterIntelligence = categories.COUNTERINTELLIGENCE
local categoriesDummy = categories.DUMMYUNIT + categories.INSIGNIFICANTUNIT
local categoriesRemaining = categories.ALLUNITS -
    (categoriesAntiAir + categoriesShield + categoriesCounterIntelligence + categoriesDummy)

---@class FormationGuardBlueprintList
---@field General BlueprintId[]
---@field AntiAir BlueprintId[]
---@field Shield BlueprintId[]
---@field CounterIntelligence BlueprintId[]
---@field Dummy BlueprintId[]

---@type FormationGuardBlueprintList
FormationBlueprintListCache = {
    General = {},
    AntiAir = {},
    Shield = {},
    CounterIntelligence = {},
    Dummy = {}
}

--- Sorts the list of blueprint ids first by tech level and then by (footprint) size
---@param a BlueprintId
---@param b BlueprintId
---@return boolean
local SortByTech = function(a, b)
    ---@type UnitBlueprint
    local ba = __blueprints[a]

    ---@type UnitBlueprint
    local bb = __blueprints[b]

    return (ba.FormationTechIndex + 0.01 * ba.Footprint.SizeX) > (bb.FormationTechIndex + 0.01 * bb.Footprint.SizeX)
end

--- Returns the first blueprint identifier that is still available in the formationBlueprintCountCache.
---@param formationBlueprintCountCache FormationBlueprintCount
---@param formationBlueprintListCache BlueprintId[]
---@return BlueprintId?
local GetCachedFormationSpecificCategory = function(formationBlueprintCountCache, formationBlueprintListCache)
    for k = 1, TableGetn(formationBlueprintListCache) do
        local blueprintId = formationBlueprintListCache[k]
        if formationBlueprintCountCache[blueprintId] > 0 then
            return blueprintId
        end
    end
end

--- Transforms a list of units into a lookup datastructure to make them computationally cheaper to work with.
---@param units (Unit[] | UserUnit[])
---@param blueprintCountCache FormationBlueprintCount
---@param blueprintListCache FormationGuardBlueprintList
---@return FormationBlueprintCount
---@return FormationGuardBlueprintList
---@return number # total number of units
TransformUnits = function(units, blueprintCountCache, blueprintListCache)

    -- local scope for performance
    local TableSort = TableSort
    local TableSetn = TableSetn
    local TableGetn = TableGetn
    local TableInsert = TableInsert

    local EntityCategoryContains = EntityCategoryContains

    -- clear the count cache
    for blueprintId, count in blueprintCountCache do
        blueprintCountCache[blueprintId] = nil
    end

    -- clear land list cache
    TableSetn(blueprintListCache, 0)
    TableSetn(blueprintListCache.AntiAir, 0)
    TableSetn(blueprintListCache.Shield, 0)
    TableSetn(blueprintListCache.CounterIntelligence, 0)

    -- populate the general cache
    for k, unit in units do
        local unitBlueprint = unit:GetBlueprint() --[[@as UnitBlueprint]]
        local unitBlueprintId = unitBlueprint.BlueprintId
        if not blueprintCountCache[unitBlueprintId] then
            blueprintCountCache[unitBlueprintId] = 1
            TableInsert(blueprintListCache, unitBlueprintId)
        else
            blueprintCountCache[unitBlueprintId] = blueprintCountCache[unitBlueprintId] + 1
        end
    end

    -- sort the lists by tech level, this way we always get the most advanced units first
    TableSort(blueprintListCache, SortByTech)

    LOG(repru(blueprintListCache))

    -- populate land list cache
    for k = 1, TableGetn(blueprintListCache) do
        local blueprintId = blueprintListCache[k]
        LOG(blueprintId)
        if EntityCategoryContains(categoriesShield, blueprintId) then
            TableInsert(blueprintListCache.Shield, blueprintId)
        elseif EntityCategoryContains(categoriesCounterIntelligence, blueprintId) then
            TableInsert(blueprintListCache.CounterIntelligence, blueprintId)
        elseif EntityCategoryContains(categoriesAntiAir, blueprintId) then
            TableInsert(blueprintListCache.AntiAir, blueprintId)
        elseif EntityCategoryContains(categoriesAntiAir, blueprintId) then
            TableInsert(blueprintListCache.Dummy, blueprintId)
        elseif EntityCategoryContains(categoriesRemaining, blueprintId) then
            TableInsert(blueprintListCache.General, blueprintId)
        end
    end

    -- count all the entries in the cache
    local blueprintTotalCount = 0
    for _, unitCount in blueprintCountCache do
        blueprintTotalCount = blueprintTotalCount + unitCount
    end

    return blueprintCountCache, blueprintListCache, blueprintTotalCount
end

---@param units (Unit[] | UserUnit[])
---@return Formation
function ComputeFormation(units)

    -- local scope for performance
    local tacticalFormation = TacticalFormation
    local formationBlueprintCountCacheA = FormationBlueprintCountCacheA
    local formationBlueprintCountCacheB = FormationBlueprintCountCacheB

    -- gather information about the units
    local formationBlueprintCountCache, formationBlueprintListCache, unitCount = TransformUnits(
        units,
        FormationBlueprintCountCacheA,
        FormationBlueprintListCache
    )

    local formationBlueprintListCacheShield = formationBlueprintListCache.Shield
    local formationBlueprintListCacheCounterIntelligence = formationBlueprintListCache.CounterIntelligence
    local formationBlueprintListCacheAntiAir = formationBlueprintListCache.AntiAir
    local formationBlueprintListCacheDummy = formationBlueprintListCache.Dummy

    -- check if the formation is the same as the last one to avoid duplicate computations
    local equal = false
    for blueprintId, count in pairs(formationBlueprintCountCacheA) do
        if formationBlueprintCountCacheB[blueprintId] ~= count then
            equal = false
            break
        end
    end

    if equal then
        return tacticalFormation
    else
        for blueprintId, _ in formationBlueprintCountCacheB do
            formationBlueprintCountCacheB[blueprintId] = nil
        end

        for blueprintId, count in pairs(formationBlueprintCountCacheA) do
            formationBlueprintCountCacheB[blueprintId] = count
        end
    end

    -- clean up old entries
    for k = 1, TableGetn(tacticalFormation) do
        tacticalFormation[k] = nil
    end

    -- formation is not the same, re-compute it!
    TableSetn(tacticalFormation, 0)

    -- dummy/insignificant units should not even be here, but they are so we get those going immediately
    for k = 1, TableGetn(formationBlueprintListCacheDummy) do
        local blueprintId = formationBlueprintListCacheDummy[k]
        for l = 1, formationBlueprintCountCache[blueprintId] do
            local formationIndex = TableGetn(tacticalFormation) + 1
            local formation = GetFormationEntry(formationIndex)
            formation[1] = 0
            formation[2] = 0
            formation[3] = categoriesDummy
            formation[4] = 0
            formation[5] = false
            TableInsert(tacticalFormation, formation)
        end
    end

    -- in a guard formation there has to be a unit that we're guarding

    ---@type Unit
    local guardedunit = units[0]:GetGuardedUnit()

    ---@type UnitBlueprint
    local guardedBlueprint = guardedunit:GetBlueprint().Formation
    if guardedBlueprint.Embedded then
        ComputeEmbeddedFormation(
            tacticalFormation,
            formationBlueprintCountCache,
            formationBlueprintListCache.Shield,
            guardedBlueprint,
            0, 0
        )
    end

    local circleOffset = 2
    local circleMultiplier = 0.2
    local circleUnitCount = 12
    for k = 0, unitCount - 1 do

        local blueprintId
        local blueprintCategoryType

        local mod4 = MathMod(k, 4)
        if (mod4 == 0 or mod4 == 2) then
            -- we'd like a shield here
            blueprintId = GetCachedFormationSpecificCategory(
                formationBlueprintCountCache,
                formationBlueprintListCacheShield
            )

            if blueprintId then
                blueprintCategoryType = categoriesShield
            end
        elseif (mod4 == 1) then
            -- we'd like anti air here
            blueprintId = GetCachedFormationSpecificCategory(
                formationBlueprintCountCache,
                formationBlueprintListCacheAntiAir
            )

            if blueprintId then
                blueprintCategoryType = categoriesAntiAir
            end
        elseif (mod4 == 3) then
            -- we'd like anti air here
            blueprintId = GetCachedFormationSpecificCategory(
                formationBlueprintCountCache,
                formationBlueprintListCacheCounterIntelligence
            )

            if blueprintId then
                blueprintCategoryType = categoriesCounterIntelligence
            end
        end

        -- Find a general category if we have no specific category

        if not blueprintId then
            blueprintId = GetCachedFormationSpecificCategory(
                formationBlueprintCountCache,
                formationBlueprintListCache
            )
        end

        if blueprintId then

            -- we're consuming a unit, reduce the relevant counter
            formationBlueprintCountCache[blueprintId] = formationBlueprintCountCache[blueprintId] - 1

            circleUnitCount = circleUnitCount + 0.1

            local radians = k / circleUnitCount * math.pi * 2.0 + 0.5 * math.pi
            local ox = ((circleOffset + circleMultiplier * k) * math.sin(radians))
            local oz = ((circleOffset + circleMultiplier * k) * math.cos(radians))

            local formationIndex = TableGetn(tacticalFormation) + 1
            local formation = GetFormationEntry(formationIndex)
            formation[1] = ox
            formation[2] = oz
            formation[3] = blueprintCategoryType or categories[blueprintId]
            formation[4] = 0
            formation[5] = false
            TableInsert(tacticalFormation, formation)
        end
    end

    reprsl(tacticalFormation)

    return tacticalFormation
end
