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

--- Various parameters based on the behavior of the engine when there are units of different sizes in a formation.
---@class FormationScaleParametersOfLayer
FormationScaleParameters = {
    Land = {
        GridSizeFraction = 2.75,
        GridSizeAbsolute = 2,
        MinSeparationFraction = 2.25,
    },

    Air = {
        GridSizeFraction = 1.3,
        GridSizeAbsolute = 2,
        MinSeparationFraction = 1,
    },

    Naval = {
        GridSizeFraction = 1.75,
        GridSizeAbsolute = 4,
        MinSeparationFraction = 1.15,
    },

    Submersible = {
        GridSizeFraction = 1.75,
        GridSizeAbsolute = 4,
        MinSeparationFraction = 1.15,
    },
}

--- Computes the scale of the formation to compensate for the behavior of the engine.
---@param formationScaleParametersOfLayer FormationScaleParametersOfLayer
---@param footprintMaximum number
ComputeFormationScale = function(formationScaleParametersOfLayer, footprintMinimum, footprintMaximum)

    -- A distance of 1 in formation coordinates translates to (largestFootprint + 2) in world coordinates.
    -- Unfortunately the engine separates land/naval units from air units and calls the formation function separately for both groups.
    -- That means if a CZAR and some light tanks are selected together, the tank formation will be scaled by the CZAR's size and we can't compensate.

    local gridSize = math.max(
        footprintMinimum * formationScaleParametersOfLayer.GridSizeFraction,
        footprintMinimum + formationScaleParametersOfLayer.GridSizeAbsolute
    )

    local gridScale = gridSize / (footprintMaximum + 2)

    return gridScale
end

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

--- Lookup table to retrieve the count of a given unit type.
---@alias FormationBlueprintCount table<BlueprintId, number>

--- Lookup table to retrieve the unit types that belong in a formation layer.
---@class FormationBlueprintList
---@field Land BlueprintId[]
---@field Air BlueprintId[]
---@field Naval BlueprintId[]
---@field Submersible BlueprintId[]

--- Transforms a list of units into a lookup datastructure to make them computationally cheaper to work with.
---@param units (Unit[] | UserUnit[])
---@param blueprintCountCache FormationBlueprintCount
---@param blueprintListCache FormationBlueprintList
---@return FormationBlueprintCount
---@return FormationBlueprintList
---@return number # total number of units
ComputeFormationProperties = function(units, blueprintCountCache, blueprintListCache)
    blueprintCountCache = blueprintCountCache or {}
    blueprintListCache = blueprintListCache or { Land = {}, Air = {}, Naval = {}, Submersible = {} }

    -- clear the cache
    for blueprintId, count in blueprintCountCache do
        blueprintCountCache[blueprintId] = nil
    end

    -- clear the cache
    for layer, blueprintIds in blueprintListCache do
        TableSetn(blueprintIds, 0)
    end

    -- populate the cache
    for k, unit in units do
        local unitBlueprint = unit:GetBlueprint() --[[@as UnitBlueprint]]
        local unitBlueprintId = unitBlueprint.BlueprintId
        local unitblueprintFormationLayer = unitBlueprint.FormationLayer
        if not blueprintCountCache[unitBlueprintId] then
            blueprintCountCache[unitBlueprintId] = 1
            TableInsert(blueprintListCache[unitblueprintFormationLayer], unitBlueprintId)
        else
            blueprintCountCache[unitBlueprintId] = blueprintCountCache[unitBlueprintId] + 1
        end
    end

    -- count all the entries in the cache
    local blueprintTotalCount = 0
    for _, unitCount in blueprintCountCache do
        blueprintTotalCount = blueprintTotalCount + unitCount
    end

    -- sort the lists by tech level, this way we always get the most advanced units first
    TableSort(blueprintListCache.Air, SortByTech)
    TableSort(blueprintListCache.Land, SortByTech)
    TableSort(blueprintListCache.Naval, SortByTech)
    TableSort(blueprintListCache.Submersible, SortByTech)

    return blueprintCountCache, blueprintListCache, blueprintTotalCount
end

--- Updates the lookup datastructures to reflect the current state.
---@param blueprintCountCache FormationBlueprintCount
---@param blueprintListCache FormationBlueprintList
---@return FormationBlueprintCount
---@return FormationBlueprintList
---@return number # total number of units
UpdateFormationProperties = function(blueprintCountCache, blueprintListCache)
    for layer, blueprintIds in blueprintListCache do

        -- retrieve the original count and reset it
        local count = TableGetn(blueprintListCache)
        TableSetn(blueprintIds, 0)

        -- only re-insert blueprint ids that we still have units of
        for k = 1, count do
            local blueprintId = blueprintIds[k]
            if blueprintCountCache[blueprintId] > 0 then
                TableInsert(blueprintIds, blueprintId)
            else
                blueprintCountCache[blueprintId] = nil
            end
        end

        -- remove any excess entries, this isn't strictly necessary but it makes debugging easier
        for k = TableGetn(blueprintIds) + 1, count do
            blueprintIds[k] = nil
        end
    end

    -- count all the entries in the cache
    local blueprintTotalCount = 0
    for _, unitCount in blueprintCountCache do
        blueprintTotalCount = blueprintTotalCount + unitCount
    end

    return blueprintCountCache, blueprintListCache, blueprintTotalCount
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
