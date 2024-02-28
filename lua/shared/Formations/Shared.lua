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
local TableInsert = table.insert
local TableSetn = table.setn
local TableGetn = table.getn

--- Lookup table to retrieve the count of a given unit type.
---@alias FormationBlueprintCount table<BlueprintId, number>

--- Lookup table to retrieve the unit types that belong in a formation layer.
---@alias FormationBlueprintList table<FormationCategory, BlueprintId[]>

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

    -- (re-)populate the cache
    for k, unit in units do
        local unitBlueprint = unit:GetBlueprint() --[[@as UnitBlueprint]]
        local unitBlueprintId = unitBlueprint.BlueprintId
        local unitblueprintFormationCategory = unitBlueprint.FormationCategory
        if not blueprintCountCache[unitBlueprintId] then
            blueprintCountCache[unitBlueprintId] = 1
            TableInsert(blueprintListCache[unitblueprintFormationCategory], unitBlueprintId)
        else
            blueprintCountCache[unitBlueprintId] = blueprintCountCache[unitBlueprintId] + 1
        end
    end

    -- count all the entries in the cache
    local blueprintTotalCount = 0
    for _, unitCount in blueprintCountCache do
        blueprintTotalCount = blueprintTotalCount + unitCount
    end

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
