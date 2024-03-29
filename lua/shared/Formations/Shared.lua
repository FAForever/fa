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

-- upvalue scope for performance
local __blueprints = __blueprints
local EntityCategoryContains = EntityCategoryContains

local TableSort = table.sort
local TableSetn = table.setn
local TableGetn = table.getn
local TableInsert = table.insert

---@class FormationScaleParametersOfLayer
---@field GridSizeFraction number
---@field GridSizeAbsolute number
---@field MinSeparationFraction number

---@class FormationScaleParameters
---@field Land FormationScaleParametersOfLayer
---@field Air FormationScaleParametersOfLayer
---@field Naval FormationScaleParametersOfLayer
---@field Submersible FormationScaleParametersOfLayer

-- preferences for land
local LandGeneralPreferences = import("/lua/shared/Formations/FormationLandPreferences.lua").LandGeneralPreferences
local LandShieldPreferences = import("/lua/shared/Formations/FormationLandPreferences.lua").LandShieldPreferences
local LandCounterIntelligencePreferences = import("/lua/shared/Formations/FormationLandPreferences.lua").LandCounterIntelligencePreferences
local LandAntiAirPreferences = import("/lua/shared/Formations/FormationLandPreferences.lua").LandAntiAirPreferences
local LandCounterScoutPreferences = import("/lua/shared/Formations/FormationLandPreferences.lua").LandCounterScoutPreferences

--- Sorts the list of blueprint ids first by tech level and then by (footprint) size
---@param a BlueprintId
---@param b BlueprintId
---@return boolean
local FormationSortLambda = function(a, b)
    return __blueprints[a].Formation.SortingIndex > __blueprints[b].Formation.SortingIndex
end

--- Lookup table to retrieve the count of a given unit type.
---@alias FormationBlueprintCount table<BlueprintId, number>

---@class FormationBlueprintListLand
---@field General BlueprintId[][]
---@field AntiAir BlueprintId[]
---@field Shield BlueprintId[]
---@field Scout BlueprintId[]
---@field CounterIntelligence BlueprintId[]

---@class FormationBlueprintListNaval
---@field General BlueprintId[][]
---@field AntiAir BlueprintId[]
---@field Shield BlueprintId[]
---@field CounterIntelligence BlueprintId[]

--- Lookup table to retrieve the unit types that belong in a formation layer.
---@class FormationBlueprintList
---@field Land FormationBlueprintListLand
---@field Air BlueprintId[]
---@field Naval BlueprintId[]
---@field Submersible BlueprintId[]

---@type FormationBlueprintList
FormationBlueprintListCache = {
    Land = {
        General = {},
        AntiAir = {},
        Shield = {},
        Scout = {},
        CounterIntelligence = {},
    },
    Air = {},
    Naval = {},
    Submersible = {}
}

for k = 1, TableGetn(LandGeneralPreferences) do
    TableInsert(FormationBlueprintListCache.Land.General, {})
end

--- Transforms a list of units into a lookup datastructure to make them computationally cheaper to work with.
---@param units (Unit[] | UserUnit[])
---@param blueprintCountCache FormationBlueprintCount
---@param blueprintListCache FormationBlueprintList
---@return FormationBlueprintCount
---@return FormationBlueprintList
---@return number # total number of units
ComputeFormationProperties = function(units, blueprintCountCache, blueprintListCache)

    -- local scope for performance
    local TableSort = table.sort
    local TableSetn = table.setn
    local TableGetn = table.getn
    local TableInsert = table.insert

    local EntityCategoryContains = EntityCategoryContains

    -- clear the count cache
    for blueprintId, count in blueprintCountCache do
        blueprintCountCache[blueprintId] = nil
    end

    -- clear land list cache
    local blueprintListCacheLand = blueprintListCache.Land
    TableSetn(blueprintListCacheLand, 0)
    TableSetn(blueprintListCacheLand.AntiAir, 0)
    TableSetn(blueprintListCacheLand.Shield, 0)
    TableSetn(blueprintListCacheLand.Scout, 0)
    TableSetn(blueprintListCacheLand.CounterIntelligence, 0)
    for k = 1, TableGetn(blueprintListCacheLand.General) do
        TableSetn(blueprintListCacheLand.General[k], 0)
    end

    -- clear air list cache
    local blueprintListCacheAir = blueprintListCache.Air
    TableSetn(blueprintListCacheAir, 0)

    -- clear naval list cache
    local blueprintListCacheNaval = blueprintListCache.Naval
    TableSetn(blueprintListCacheNaval, 0)

    -- clear submersible list cache
    local blueprintListCacheSubmersible = blueprintListCache.Submersible
    TableSetn(blueprintListCacheSubmersible, 0)

    -- populate the general cache
    for k, unit in units do
        local unitBlueprint = unit:GetBlueprint() --[[@as UnitBlueprint]]
        local unitBlueprintId = unitBlueprint.BlueprintId
        local unitblueprintFormationLayer = unitBlueprint.Formation.Layer
        if not blueprintCountCache[unitBlueprintId] then
            blueprintCountCache[unitBlueprintId] = 1
            TableInsert(blueprintListCache[unitblueprintFormationLayer], unitBlueprintId)
        else
            blueprintCountCache[unitBlueprintId] = blueprintCountCache[unitBlueprintId] + 1
        end
    end

    -- sort the lists by tech level, this way we always get the most advanced units first
    TableSort(blueprintListCache.Air, FormationSortLambda)
    TableSort(blueprintListCache.Land, FormationSortLambda)
    TableSort(blueprintListCache.Naval, FormationSortLambda)
    TableSort(blueprintListCache.Submersible, FormationSortLambda)

    -- populate land list cache
    for k = 1, TableGetn(blueprintListCacheLand) do
        local blueprintId = blueprintListCacheLand[k]

        for c = 1, TableGetn(LandShieldPreferences) do
            if EntityCategoryContains(LandShieldPreferences[c], blueprintId) then
                TableInsert(blueprintListCacheLand.Shield, blueprintId)
                break
            end
        end

        for c = 1, TableGetn(LandCounterIntelligencePreferences) do
            if EntityCategoryContains(LandCounterIntelligencePreferences[c], blueprintId) then
                TableInsert(blueprintListCacheLand.CounterIntelligence, blueprintId)
                break
            end
        end

        for c = 1, TableGetn(LandAntiAirPreferences) do
            if EntityCategoryContains(LandAntiAirPreferences[c], blueprintId) then
                TableInsert(blueprintListCacheLand.AntiAir, blueprintId)
                break
            end
        end

        for c = 1, TableGetn(LandCounterScoutPreferences) do
            if EntityCategoryContains(LandCounterScoutPreferences[c], blueprintId) then
                TableInsert(blueprintListCacheLand.Scout, blueprintId)
                break
            end
        end

        for c = 1, TableGetn(LandGeneralPreferences) do
            if EntityCategoryContains(LandGeneralPreferences[c], blueprintId) then
                TableInsert(blueprintListCacheLand.General[c], blueprintId)
                break
            end
        end
    end

    -- count all the entries in the cache
    local blueprintTotalCount = 0
    for _, unitCount in blueprintCountCache do
        blueprintTotalCount = blueprintTotalCount + unitCount
    end

    return blueprintCountCache, blueprintListCache, blueprintTotalCount
end

--- Updates the lookup datastructures to reflect the current state by removing blueprint ids that have no units left.
---@param blueprintCountCache FormationBlueprintCount
---@param blueprintIds BlueprintId[]
UpdateFormationCategories = function(blueprintCountCache, blueprintIds)
    local head = 1
    for k = 1, TableGetn(blueprintIds) do
        local blueprintId = blueprintIds[k]
        if blueprintCountCache[blueprintId] > 0 then
            blueprintIds[head] = blueprintId
            head = head + 1
        end
    end

    -- remove lingering entries
    for k = head, TableGetn(blueprintIds) do
        blueprintIds[k] = nil
    end

    TableSetn(blueprintIds, head - 1)
end

--- Updates the lookup datastructures for land formations to reflect the current state.
---@param blueprintCountCache FormationBlueprintCount
---@param blueprintListCacheLand FormationBlueprintListLand
UpdateFormationLandCategories = function(blueprintCountCache, blueprintListCacheLand)

    UpdateFormationCategories(blueprintCountCache, blueprintListCacheLand.Shield)
    UpdateFormationCategories(blueprintCountCache, blueprintListCacheLand.CounterIntelligence)
    UpdateFormationCategories(blueprintCountCache, blueprintListCacheLand.AntiAir)
    UpdateFormationCategories(blueprintCountCache, blueprintListCacheLand.Scout)

    local blueprintListCacheLandGeneral = blueprintListCacheLand.General
    for k = 1, TableGetn(blueprintListCacheLandGeneral) do
        UpdateFormationCategories(blueprintCountCache, blueprintListCacheLandGeneral[k])
    end
end

--- Computes the footprint data of a formation.
---@param blueprintCountCache FormationBlueprintCount
---@param blueprintIds BlueprintId[]
---@return number # all size-x footprints combined
---@return number # the smallest size-z footprint
---@return number # the largest size-z footprint
ComputeFootprintData = function(blueprintCountCache, blueprintIds)
    -- local scope for performance
    local __blueprints = __blueprints

    local footprintMinimum = 1000
    local footprintMaximum = 0
    local footprintTotalLength = 0
    for k = 1, TableGetn(blueprintIds) do
        local blueprintId            = blueprintIds[k]
        local blueprintCount         = blueprintCountCache[blueprintId]
        local blueprintFootprintSize = __blueprints[blueprintId].Footprint.SizeX

        if blueprintCount > 0 then
            footprintTotalLength = footprintTotalLength + blueprintCount * blueprintFootprintSize

            if blueprintFootprintSize > footprintMaximum then
                footprintMaximum = blueprintFootprintSize
            end

            if blueprintFootprintSize < footprintMinimum then
                footprintMinimum = blueprintFootprintSize
            end
        end
    end

    return footprintTotalLength, footprintMinimum, footprintMaximum
end
