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

---@alias BlueprintLookupTable table<BlueprintId, number>

--- Converts a list of units into a blueprint-based lookup table.
---@param units (Unit[] | UserUnit[])
---@param blueprintListCache BlueprintId[]
---@param blueprintCountCache BlueprintLookupTable
---@return BlueprintLookupTable
---@return BlueprintId[]
---@return number # total number of units
ToBlueprintLookup = function(units, blueprintListCache, blueprintCountCache)
    blueprintCountCache = blueprintCountCache or {}
    blueprintListCache = blueprintListCache or {}
    local blueprintTotalCount = 0
    local blueprintListCount = 0

    -- clean the cache
    for unitBlueprintId, _ in blueprintCountCache do
        blueprintCountCache[unitBlueprintId] = nil
    end

    -- clean the cache
    for k = 1, table.getn(blueprintListCache) do
        blueprintListCache[k] = nil
    end

    -- (re-)populate the cache
    for k, unit in units do
        local unitBlueprint = unit:GetBlueprint()
        local unitBlueprintId = unitBlueprint.BlueprintId
        if not blueprintCountCache[unitBlueprintId] then
            blueprintCountCache[unitBlueprintId] = 1

            blueprintListCount = blueprintListCount + 1
            blueprintListCache[blueprintListCount] = unitBlueprintId
        else
            blueprintCountCache[unitBlueprintId] = blueprintCountCache[unitBlueprintId] + 1
        end
    end

    -- count all the entries in the cache
    for _, unitCount in blueprintCountCache do
        blueprintTotalCount = blueprintTotalCount + unitCount
    end

    return blueprintCountCache, blueprintListCache, blueprintTotalCount
end

--- Returns the maximum footprint size of all unit types in the lookup table.
---@param lookup BlueprintLookupTable
---@return number
MaximumFootprint = function(lookup)
    local maximumFootprint = 0

    for unitBlueprintId, _ in lookup do
        local unitBlueprint = __blueprints[unitBlueprintId] --[[@as UnitBlueprint]]
        local unitSize = math.max(unitBlueprint.Footprint.SizeX or 1, unitBlueprint.Footprint.SizeZ or 1)
        if unitSize and unitSize > maximumFootprint then
            maximumFootprint = unitSize
        end
    end

    return maximumFootprint
end

---@param blueprintCountCache BlueprintLookupTable
---@param blueprintListCache BlueprintId[]
---@return BlueprintId[]
UpdateBlueprintListCache = function(blueprintCountCache, blueprintListCache)
    local head  = 1
    local count = table.getn(blueprintListCache)
    for k = 1, count do
        if blueprintCountCache[ blueprintListCache[k] ] > 0 then
            blueprintListCache[head] = blueprintListCache[k]
            head = head + 1
        end
    end

    -- clean up remaining entries
    for k = head, count do
        blueprintListCache[k] = nil
    end

    return blueprintListCache
end

--- A table that contains formation positions that we can re-use.

---@type FormationPosition[]
local FormationPositions = {}

---@param index number
---@return FormationPosition
GetFormationPosition = function(index)
    local formation = FormationPositions[index] --[[@as FormationPosition]]
    if not formation then
        formation = {
            0, 0, categories.ALLUNITS, 0, true
        }
        FormationPositions[index] = formation
    end

    return formation
end
