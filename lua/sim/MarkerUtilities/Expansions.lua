
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

local Stack = import("/lua/sim/navdatastructures.lua").Stack
local NavUtils = import("/lua/sim/NavUtils.lua")

local Generated = false

---@class MarkerExpansion : MarkerData
---@field RallyPoints MarkerRallyPoint[]

function IsGenerated()
    return Generated
end

function Generate()
    if Generated then
        return
    end

    Generated = true

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    ---@class ExtractorNode 
    ---@field Identifier number
    ---@field Extractor MarkerResource
    ---@field Seen boolean
    ---@field Neighbors ExtractorNode[]
    ---@field Candidates ExtractorNode[]

    local mapSize = math.max(ScenarioInfo.size[1], ScenarioInfo.size[2])
    local mapFactor = 16 / (mapSize)
    local threshold = 400 + mapSize

    local function ComputeBlock(px, pz)
        local bx = math.floor(px * mapFactor) + 1
        local bz = math.floor(pz * mapFactor) + 1
        return bx, bz
    end

    ---@type ExtractorNode[]
    local structuredExtractorData = { }

    ---------------------------------------------------
    -- Create and populate a temporarily grid to easen
    -- the complexity of grouping the extractors

    ---@type { Extractors: ExtractorNode[] }[][]
    local grid = {}
    for z = 1, 16 do
        grid[z] = {}
        for x = 1, 16 do
            grid[z][x] = {
                Extractors = { }
            }
        end
    end

    local extractors = import("/lua/sim/markerutilities.lua").GetMarkersByType('Mass')
    for k, extractor in extractors do
        local p = extractor.position
        local px, pz = p[1], p[3]

        local bx, bz = ComputeBlock(px, pz)
        local cell = grid[bz][bx]
        if cell then
            local node = {
                Extractor = extractor,
                Identifier = k,
                Seen = false,
                Neighbors = { },
                Candidates = { },
            }

            table.insert(structuredExtractorData, node)
            table.insert(cell.Extractors, node)
        end

    end

    ---------------------------------------------------
    -- find neighbouring extractors

    for k = 1, table.getn(structuredExtractorData) do
        local instance = structuredExtractorData[k]
        local extractor = instance.Extractor
        local px,pz = extractor.position[1], extractor.position[3]
        local bx, bz = ComputeBlock(px, pz)

        -- loop over neighboring cells
        for lz = -2, 2 do
            for lx = -2, 2 do
                local cell = grid[bz + lz][bx + lx]
                if cell then
                    for k = 1, table.getn(cell.Extractors) do
                        local neighbor = cell.Extractors[k]
                        if neighbor != instance and neighbor.Extractor.NavLabel == instance.Extractor.NavLabel then
                            local dx = px - neighbor.Extractor.position[1]
                            local dz = pz - neighbor.Extractor.position[3]
                            local d = dx * dx + dz * dz
                            if d < threshold then
                                instance.Neighbors[neighbor.Identifier] = neighbor
                            elseif d < 1.5 * threshold then
                                instance.Candidates[neighbor.Identifier] = neighbor
                            end
                        end
                    end
                end
            end
        end

        -- local numberOfNeighbors = table.getsize(instance.Neighbors)
        -- local numberOfCandidates = table.getsize(instance.Candidates)

        -- if numberOfNeighbors <= 1 and numberOfCandidates >= 2 then
        --     for id, neighbor in instance.Candidates do
        --         instance.Neighbors[id] = neighbor
        --     end
        -- end
    end

    ---------------------------------------------------
    -- Compute the expansion points based on the   
    -- neighboring extractors that we found. The center
    -- of those extractors is used as the location of
    -- the marker

    local startLocations, startLocationCount = import("/lua/sim/markerutilities.lua").GetMarkersByType('Start Location')

    ---@type Stack
    local stack = Stack()

    ---@type MarkerExpansion[]
    local largeExpansions = { }
    local largeExpansionCount = 0

    ---@type MarkerExpansion[]
    local smallExpansions = { }
    local smallExpansionsCount = 0

    for k = 1, table.getn(structuredExtractorData) do
        stack:Clear()
        stack:Push(structuredExtractorData[k])

        ---@type MarkerResource[]
        local extractors = { }

        while not stack:Empty() do
            ---@type ExtractorNode
            local instance = stack:Pop()
            table.insert(extractors, instance.Extractor)
            for _, neighbor in instance.Neighbors do
                if not neighbor.Marked then
                    neighbor.Marked = true
                    stack:Push(neighbor)
                end
            end
        end

        local numberOfExtractors = table.getn(extractors)
        local center = { 0, 0, 0 }
        for _, extractor in extractors do
            local position = extractor.position
            center[1] = center[1] + position[1]
            center[3] = center[3] + position[3]
        end

        center[1] = center[1] / numberOfExtractors
        center[3] = center[3] / numberOfExtractors
        center[2] = GetSurfaceHeight(center[1], center[3])

        -- find nearest spawn location
        local nearestStartLocation
        local nearestStartLocationDistance
        for k = 1, startLocationCount do 
            local startLocation = startLocations[k]
            local dx = startLocation.position[1] - center[1]
            local dz = startLocation.position[3] - center[3]
            local startLocationDistance = dx * dx + dz * dz
            if not nearestStartLocation then
                nearestStartLocation = startLocation
                nearestStartLocationDistance = startLocationDistance
            else
                if startLocationDistance <  nearestStartLocationDistance then
                    nearestStartLocation = startLocation
                    nearestStartLocationDistance = startLocationDistance
                end
            end
        end

        -- skip those that are too close to a spawn location
        if nearestStartLocationDistance > 40 then
            ---@type MarkerExpansion
            local expansionMarker = {
                position = center,
                Extractors = extractors,
                Hydrocarbons = { },
                RallyPoints = { },
                NavLabel = NavUtils.GetLabel('Land', center),
            }

            if numberOfExtractors > 3 then
                expansionMarker.size = 20
                expansionMarker.type = 'Large Expansion Area'
                largeExpansions[string.format("Large Expansion Area %d", largeExpansionCount + 1)] = expansionMarker
                largeExpansionCount = largeExpansionCount + 1
            elseif numberOfExtractors > 1 then
                expansionMarker.size = 10
                expansionMarker.type = 'Expansion Area'
                smallExpansions[string.format("Expansion Area %d", smallExpansionsCount + 1)] = expansionMarker
                smallExpansionsCount = smallExpansionsCount + 1
            end
        end
    end

    ---------------------------------------------------
    -- And at last, populate the information   
    -- neighboring extractors that we found. The center
    -- of those extractors is used as the location of
    -- the marker

    import("/lua/sim/markerutilities.lua").OverwriteMarkerByType('Large Expansion Area', largeExpansions)
    import("/lua/sim/markerutilities.lua").OverwriteMarkerByType('Expansion Area', smallExpansions)

    SPEW(string.format("Generated rally point markers in %.2f miliseconds", 1000 * (GetSystemTimeSecondsOnlyForProfileUse() - start)))
end