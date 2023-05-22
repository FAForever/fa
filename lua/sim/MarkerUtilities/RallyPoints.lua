
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

local NavUtils = import("/lua/sim/NavUtils.lua")

---@class MarkerRallyPoint : MarkerData
---@field PartOf MarkerExpansion
---@field Name string

local Generated = false

function IsGenerated()
    return Generated
end

---@type MarkerRallyPoint[]
local RallyPoints = { }

---@type number
local RallyPointCount = 0

---@param expansion MarkerExpansion
local function GenerateForExpansion(expansion, layer, distance, threshold)
    local position = expansion.position
    local rallyPoints = expansion.RallyPoints
    local points, count = NavUtils.DirectionsFrom(layer, position, distance, threshold)
    if points then
        for k = 1, count do
            local point = points[k]

            ---@type MarkerRallyPoint
            local rallyPoint = {
                -- legacy properties
                position = point,
                size = 4,
                color = 'ffffff',

                -- modern properties
                PartOf = expansion,
                Name = string.format("Rally Point %00d", RallyPointCount + 1)
            }

            -- add rally point to expansion
            table.insert(rallyPoints, rallyPoint)

            -- keep track of all rally points
            RallyPoints[RallyPointCount + 1] = rallyPoint
            RallyPointCount = RallyPointCount + 1
        end
    end
end

function Generate()

    -- verify that we have what we need
    if not import("/lua/sim/markerutilities/Expansions.lua").IsGenerated() then
        WARN("Unable to generate rally point markers without expansion markers")
    end

    if not import("/lua/sim/NavUtils.lua").IsGenerated() then
        WARN("Unable to generate rally point markers without navigational mesh")
    end

    local largeExpansions = import("/lua/sim/markerutilities.lua").GetMarkersByType('Large Expansion Area') --[[@as (MarkerExpansion[])]]
    local largeExpansionCount = table.getn(largeExpansions)

    local smallExpansions = import("/lua/sim/markerutilities.lua").GetMarkersByType('Expansion Area') --[[@as (MarkerExpansion[])]]
    local smallExpansionCount = table.getn(smallExpansions)

    if largeExpansionCount == 0 and smallExpansionCount == 0 then
        WARN("Unable to generate rally point markers without expansion markers")
    end

    -- verify that we didn't generate already
    if Generated then
        return
    end

    Generated = true

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, smallExpansionCount do
        GenerateForExpansion(smallExpansions[k], 'Land', 30, 8)
    end

    for k = 1, largeExpansionCount do
        GenerateForExpansion(largeExpansions[k], 'Land', 50, 16)
    end

    import("/lua/sim/markerutilities.lua").OverwriteMarkerByType('Rally Point', RallyPoints)

    SPEW(string.format("Generated rally point markers in %.2f miliseconds", 1000 * (GetSystemTimeSecondsOnlyForProfileUse() - start)))
end

function Log()
    LOG("Rally point markers: ")
    for k = 1, RallyPointCount do
        local marker = RallyPoints[k]
        LOG(string.format(" - { %s, %s, (%.2f, %.2f, %.2f)}", marker.Name, marker.PartOf.Name, marker.position[1], marker.position[2], marker.position[3]))
    end
end

function Draw()

end