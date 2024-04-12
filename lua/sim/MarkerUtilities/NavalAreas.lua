
--******************************************************************************************************
--** Copyright (c) 2023  Willem 'Jip' Wijnia
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

---@class MarkerNavalArea : MarkerData
---@field PartOf MarkerExpansion
---@field Name string
---@field Size number

--- Global file state, that represents all generated markers
---@type MarkerNavalArea[]
local Markers = { }

--- Global file state, represents the number of markers
---@type number
local MarkerCount = 0

local Generated = false
function IsGenerated()
    return Generated
end

---@param expansion MarkerExpansion
---@param distance number
---@param thresholdSize number
---@param thresholdArea number
local function GenerateForExpansion(expansion, distance, thresholdSize, thresholdArea)
    -- local imports to make debugging easier
    local NavUtils = import("/lua/sim/navutils.lua")

    local position = expansion.position
    local points, count = NavUtils.GetPositionsInRadius('Water', position, distance, thresholdSize, { })
    if points then
        for k = 1, count do
            local point = points[k]

            local label = NavUtils.GetLabel('Water', point)
            if not label then
                continue
            end

            local labelMeta = NavUtils.GetLabelMetadata(label)
            if not labelMeta then
                continue
            end

            if labelMeta.Area <= thresholdArea then
                continue
            end


            ---@type MarkerNavalArea
            local marker = {
                -- legacy properties
                position = point,
                size = 4,
                color = 'ffffff',
                type = 'Naval Area',

                -- modern properties
                PartOf = expansion,
                Name = string.format("Naval Area %00d", MarkerCount + 1),
                Size = points[4],
                Type = 'Naval Area',
            }

            -- keep track of the marker
            MarkerCount = MarkerCount + 1
            Markers[MarkerCount] = marker
        end
    end
end

function Generate()

    -- we are generated previously
    if IsGenerated() then
        return
    end

    -- requires a navigational mesh
    import("/lua/sim/navutils.lua").Generate()

    -- requires expansion markers
    import("/lua/sim/markerutilities/expansions.lua").Generate()

    local spawns, spawnCount = import("/lua/sim/markerutilities.lua").GetMarkersByType('Spawn') --[[@as (MarkerExpansion[])]]
    local largeExpansions, largeExpansionCount = import("/lua/sim/markerutilities.lua").GetMarkersByType('Large Expansion Area') --[[@as (MarkerExpansion[])]]
    local smallExpansions, smallExpansionCount = import("/lua/sim/markerutilities.lua").GetMarkersByType('Expansion Area') --[[@as (MarkerExpansion[])]]

    if (largeExpansionCount == 0) and (smallExpansionCount == 0) and (spawnCount == 0) then
        WARN("Unable to generate naval area markers without expansion markers")
        import("/lua/sim/markerutilities.lua").OverwriteMarkerByType('Naval Area', Markers)
        return
    end

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local mapSize = math.max(ScenarioInfo.size[1], ScenarioInfo.size[2])

    --- Threshold for the size of the navigational cell
    local thresholdSize = 16
    if mapSize >= 1024 then
        thresholdSize = 32
    end

    --- Threshold for the size of the area of the label
    local thresholdArea = 2
    if mapSize >= 1024 then
        thresholdArea = 10
    end

    -- generate for small expansions
    for k = 1, smallExpansionCount do
        local thresholdDistance = 20
        if mapSize > 1024 then
            thresholdDistance = 30
        end
        GenerateForExpansion(smallExpansions[k], thresholdDistance, thresholdSize, thresholdArea)
    end

    -- generate for large expansions
    for k = 1, largeExpansionCount do
        local thresholdDistance = 30
        if mapSize > 1024 then
            thresholdDistance = 50
        end
        GenerateForExpansion(largeExpansions[k], thresholdDistance, thresholdSize, thresholdArea)
    end

    -- generate for spawn locations
    for k = 1, spawnCount do
        local thresholdDistance = 40
        if mapSize > 1024 then
            thresholdDistance = 50
        end
        GenerateForExpansion(spawns[k], thresholdDistance, thresholdSize, thresholdArea)
    end

    import("/lua/sim/markerutilities.lua").OverwriteMarkerByType('Naval Area', Markers)

    SPEW(string.format("Generated naval area markers in %.2f miliseconds", 1000 * (GetSystemTimeSecondsOnlyForProfileUse() - start)))
end
