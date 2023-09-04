
--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
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

local SortUnitsByTech = import("/lua/sim/commands/shared.lua").SortUnitsByTech
local FindNearestUnit = import("/lua/sim/commands/shared.lua").FindNearestUnit
local SortOffsetsByDistanceToPoint = import("/lua/sim/commands/shared.lua").SortOffsetsByDistanceToPoint

local BuildOffsets = { { 2, 0 }, { 0, 2 }, { -2, 0 }, { 0, -2 } }

-- upvalue scope for performance
local IssueGuard = IssueGuard
local GetUnitsInRect = GetUnitsInRect
local GetTerrainHeight = GetTerrainHeight
local EntityCategoryFilterDown = EntityCategoryFilterDown
local IssueBuildAllMobile = IssueBuildAllMobile

---@param extractor Unit
---@param engineers Unit[]
RingExtractor = function(extractor, engineers)

    ---------------------------------------------------------------------------
    -- defensive programming

    -- confirm we have an extractor
    if (not extractor) or (IsDestroyed(extractor)) then
        return
    end

    -- confirm that we have one engineer that can build the unit
    SortUnitsByTech(engineers)
    local storage = engineers[1].Blueprint.BlueprintId:sub(1, 2) .. 'b1106'
    if (not __blueprints[storage]) or
        (not engineers[1]:CanBuild(storage))
    then
        return
    end

    ---------------------------------------------------------------------------
    -- determine all units in surroundings that may block construction

    local blueprint = extractor:GetBlueprint()
    local skirtSize = blueprint.Physics.SkirtSizeX
    local cx, _, cz = extractor:GetPositionXYZ()

    -- we manually scan for build skirts in the surrounding area. The function brain:CanBuildStructureAt(...) does
    -- not always return correct results: it may end up returning true after factories upgraded

    local x1 = cx - (skirtSize + 10)
    local z1 = cz - (skirtSize + 10)
    local x2 = cx + (skirtSize + 10)
    local z2 = cz + (skirtSize + 10)

    -- find all units that may prevent us from building
    local structures = GetUnitsInRect(x1, z1, x2, z2)
    if not structures then
        return
    end

    structures = EntityCategoryFilterDown(categories.STRUCTURE + categories.EXPERIMENTAL, structures)

    -- populate the skirts to check
    local skirts = {}
    for k, unit in structures do
        local blueprint = unit:GetBlueprint()
        local px, _, pz = unit:GetPositionXYZ()
        local sx, sz = 0.5 * blueprint.Physics.SkirtSizeX, 0.5 * blueprint.Physics.SkirtSizeZ
        local rect = {
            px - sx, -- top left
            pz - sz, -- top left
            px + sx, -- bottom right
            pz + sz -- bottom right
        }

        skirts[k] = rect
    end

    ---------------------------------------------------------------------------
    -- filter engineers and sort offsets

    local faction = engineers[1].Blueprint.FactionCategory
    local engineersOfFaction = EntityCategoryFilterDown(categories[faction], engineers)
    local engineersOther = EntityCategoryFilterDown(categories.ALLUNITS - categories[faction], engineers)

    local offsets = BuildOffsets
    local nearestEngineer = FindNearestUnit(engineersOfFaction, cx, cz)
    if nearestEngineer then
        local ex, _, ez = nearestEngineer:GetPositionXYZ()
        SortOffsetsByDistanceToPoint(offsets, cx, cz, ex, ez)
    end

    ---------------------------------------------------------------------------
    -- issue the build orders

    local buildLocation = {}
    local emptyTable = {}

    -- loop over build locations in given layer
    for k, location in BuildOffsets do
        buildLocation[1] = cx + location[1]
        buildLocation[3] = cz + location[2]
        buildLocation[2] = GetTerrainHeight(buildLocation[1], buildLocation[3])

        local freeToBuild = true
        for _, skirt in skirts do
            if buildLocation[1] > skirt[1] and buildLocation[1] < skirt[3] then
                if buildLocation[3] > skirt[2] and buildLocation[3] < skirt[4] then
                    freeToBuild = false
                    break
                end
            end
        end

        if freeToBuild then
            IssueBuildAllMobile(engineersOfFaction, buildLocation, storage, emptyTable)
        end
    end

    ---------------------------------------------------------------------------
    -- issue assist orders for remaining engineers

    IssueGuard(engineersOther, engineersOfFaction[1])
end
