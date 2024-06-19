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

local FindNearestUnit = import("/lua/sim/commands/shared.lua").FindNearestUnit
local SortOffsetsByDistanceToPoint = import("/lua/sim/commands/shared.lua").SortOffsetsByDistanceToPoint

-- upvalue scope for performance
local IssueGuard = IssueGuard
local GetTerrainHeight = GetTerrainHeight
local EntityCategoryFilterDown = EntityCategoryFilterDown
local IssueBuildAllMobile = IssueBuildAllMobile

-- cached for performance
local CacheX1 = {}
local CacheZ1 = {}
local CacheX2 = {}
local CacheZ2 = {}

local BuildLocation = {}
local EmptyTable = {}

-- Scan and gather build skirts in the surrounding area. This is used as an alternative 
-- to relying on `brain:CanBuildStructureAt(...)` as it returns false positives.
---@param cx number
---@param cz number
---@param skirtSize number
---@param cx1 number[]  # re-useable array
---@param cz1 number[]  # re-useable array
---@param cx2 number[]  # re-useable array
---@param cz2 number[]  # re-useable array
---@return number[]
---@return number[]
---@return number[]
---@return number[]
---@return number
function FindBuildingSkirts(cx, cz, skirtSize, cx1, cz1, cx2, cz2)

    local x1 = cx - (skirtSize + 10)
    local z1 = cz - (skirtSize + 10)
    local x2 = cx + (skirtSize + 10)
    local z2 = cz + (skirtSize + 10)

    -- clear out the cache
    for k = 1, table.getn(cx1) do
        cx1[k] = nil
        cz1[k] = nil
        cx2[k] = nil
        cz2[k] = nil
    end

    -- find all units that may prevent us from building
    local structures = GetUnitsInRect(x1, z1, x2, z2)
    if not structures then
        return cx1, cz1, cx2, cz2, 0
    end

    structures = EntityCategoryFilterDown(categories.STRUCTURE + categories.EXPERIMENTAL, structures)

    -- populate the skirts to check
    local buildingSkirtCount = 0
    for k, unit in structures do
        local blueprint = unit:GetBlueprint()
        local px, _, pz = unit:GetPositionXYZ()
        local sx, sz = 0.5 * blueprint.Physics.SkirtSizeX, 0.5 * blueprint.Physics.SkirtSizeZ
        cx1[k] = px - sx
        cz1[k] = pz - sz
        cx2[k] = px + sz
        cz2[k] = pz + sz
        buildingSkirtCount = buildingSkirtCount + 1
    end

    return cx1, cz1, cx2, cz2, buildingSkirtCount
end

---@param target Unit
---@param engineers Unit[]
---@param offsets { [1]: number, [2]: number }[]
---@param blueprintId UnitId
function RingUnit(target, engineers, offsets, blueprintId)
    local faction = engineers[1].Blueprint.FactionCategory
    local engineersOfFaction = EntityCategoryFilterDown(categories[faction], engineers)
    local engineersOther = EntityCategoryFilterDown(categories.ALLUNITS - categories[faction], engineers)

    ---------------------------------------------------------------------------
    -- determine all units in surroundings that may block construction

    local blueprint = target:GetBlueprint()
    local skirtSize = blueprint.Physics.SkirtSizeX
    local cx, _, cz = target:GetPositionXYZ()
    local cx1, cz1, cx2, cz2, buildingSkirtCount = FindBuildingSkirts(cx, cz, skirtSize, CacheX1, CacheZ1, CacheX2,
        CacheZ2)

    ---------------------------------------------------------------------------
    -- filter engineers and sort offsets

    local nearestEngineer = FindNearestUnit(engineersOfFaction, cx, cz)
    if nearestEngineer then
        local ex, _, ez = nearestEngineer:GetPositionXYZ()
        SortOffsetsByDistanceToPoint(offsets, cx, cz, ex, ez)
    end

    ---------------------------------------------------------------------------
    -- issue the build orders

    local buildLocation = BuildLocation
    local emptyTable = EmptyTable
    for k, offset in offsets do
        local bx = cx + offset[1]
        local bz = cz + offset[2]

        buildLocation[1] = bx
        buildLocation[3] = bz
        buildLocation[2] = GetTerrainHeight(bx, bz)

        -- determine if location is free to build
        local freeToBuild = engineers[1]:GetAIBrain():CanBuildStructureAt(blueprintId, buildLocation)
        if freeToBuild then
            for k = 1, buildingSkirtCount do
                if bx > cx1[k] and bx < cx2[k] then
                    if bz > cz1[k] and bz < cz2[k] then
                        freeToBuild = false
                        break
                    end
                end
            end
        end

        if freeToBuild then
            IssueBuildAllMobile(engineersOfFaction, buildLocation, blueprintId, emptyTable)
        end
    end

    ---------------------------------------------------------------------------
    -- issue assist orders for remaining engineers

    IssueGuard(engineersOther, engineersOfFaction[1])
end
