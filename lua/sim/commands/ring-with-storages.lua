
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
local FindBuildingSkirts = import("/lua/sim/commands/shared.lua").FindBuildingSkirts
local SortOffsetsByDistanceToPoint = import("/lua/sim/commands/shared.lua").SortOffsetsByDistanceToPoint

-- upvalue scope for performance
local IssueGuard = IssueGuard
local GetTerrainHeight = GetTerrainHeight
local EntityCategoryFilterDown = EntityCategoryFilterDown
local IssueBuildAllMobile = IssueBuildAllMobile

-- cached for performance
local CacheX1 = { }
local CacheZ1 = { }
local CacheX2 = { }
local CacheZ2 = { }

local BuildLocation = { }
local EmptyTable = { }

local BuildOffsets = { { 2, 0 }, { 0, 2 }, { -2, 0 }, { 0, -2 } }

---@param extractor Unit
---@param engineers Unit[]
RingExtractor = function(extractor, engineers)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

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
    local cx1, cz1, cx2, cz2, buildingSkirtCount = FindBuildingSkirts(cx, cz, skirtSize, CacheX1, CacheZ1, CacheX2, CacheZ2)

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

    local buildLocation = BuildLocation
    local emptyTable = EmptyTable

    for k, offset in offsets do
        local bx = cx + offset[1]
        local bz = cz + offset[2]

        -- determine if location is free to build
        local freeToBuild = true
        for k = 1, buildingSkirtCount do
            if bx > cx1[k] and bx < cx2[k] then
                if bz > cz1[k] and bz < cz2[k] then
                    freeToBuild = false
                    break
                end
            end
        end

        if freeToBuild then
            buildLocation[1] = bx
            buildLocation[3] = bz
            buildLocation[2] = GetTerrainHeight(bx, bz)
            IssueBuildAllMobile(engineersOfFaction, buildLocation, storage, emptyTable)
        end
    end

    ---------------------------------------------------------------------------
    -- issue assist orders for remaining engineers

    IssueGuard(engineersOther, engineersOfFaction[1])
end
