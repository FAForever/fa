
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
---@field Extractors MarkerResource[]
---@field RallyPoints MarkerRallyPoint[]

function IsGenerated()
    return Generated
end

---@return MarkerExpansion[]
---@return integer
local function GenerateExpansionMarkers ()

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
    end

    ---------------------------------------------------
    -- Compute the expansion points based on the   
    -- neighboring extractors that we found. The center
    -- of those extractors is used as the location of
    -- the marker

    ---@type Stack
    local stack = Stack()

    ---@type MarkerExpansion[]
    local expansions = { }
    local expansionCount = 0

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



        ---@type MarkerExpansion
        local expansionMarker = {
            position = center,
            Position = center,
            Extractors = extractors,
            RallyPoints = { },
            NavLabel = NavUtils.GetLabel('Land', center),
        }

        expansions[expansionCount + 1] = expansionMarker
        expansionCount = expansionCount + 1
    end

    return expansions, expansionCount

end

---@param expansions MarkerExpansion[]
---@param expansionCount integer
---@return MarkerExpansion[]
---@return integer
local function AssimilateExpansionMarkers(expansions, expansionCount)

    local startLocations, startLocationCount = import("/lua/sim/markerutilities.lua").GetMarkersByType('Start Location')
    local mapSize = math.max(ScenarioInfo.size[1], ScenarioInfo.size[2])
    local threshold = 30 + 0.02 * mapSize

    ---------------------------------------------------------------------------
    -- prepare the start locations

    for k = 1, startLocationCount do
        local startLocation = startLocations[k]
        startLocation.Extractors = { }
        startLocation.RallyPoints = { }
    end

    ---------------------------------------------------------------------------
    -- assimilate expansions

    local head = 1
    for k = 1, expansionCount do
        local expansion = expansions[k]
        local center = expansion.Position

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

        -- assimilate it into the spawn location
        if math.sqrt(nearestStartLocationDistance) < threshold then
            local extractors = nearestStartLocation.Extractors
            for k, extractor in expansion.Extractors do
                table.insert(extractors, extractor)
            end
        else
            expansions[head] = expansion
            head = head + 1
        end
    end

    ---------------------------------------------------------------------------
    -- clean up remaining expansions

    for k = head, expansionCount do
        expansions[k] = nil
    end

    return expansions, head - 1
end

function Generate()
    if Generated then
        return
    end

    Generated = true

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    ---------------------------------------------------------------------------
    -- Generate the expansions and assimilate them into spawns

    local expansions, expansionCount = GenerateExpansionMarkers()
    local remainingExpansions, remainingExpansionCount = AssimilateExpansionMarkers(expansions, expansionCount)

    ---------------------------------------------------------------------------
    -- Divide expansions into small and large expansions

    local smallExpansions = { }
    local smallExpansionsHead = 1

    local largeExpansions = { }
    local largeExpansionsHead = 1

    for k = 1, remainingExpansionCount do
        local expansion = remainingExpansions[k]

        local extractorCount = table.getn(expansion.Extractors)
        if extractorCount > 3 then
            expansion.Type = 'Large Expansion Area'
            expansion.Name = string.format("Large Expansion Area %d", largeExpansionsHead)
            expansion.Size = 20

            -- legacy entries
            expansion.type = expansion.Type
            expansion.name = expansion.Name
            expansion.size = expansion.Size

            largeExpansions[largeExpansionsHead] = expansion
            largeExpansionsHead = largeExpansionsHead + 1
        elseif extractorCount > 1 then

            expansion.Type = 'Expansion Area'
            expansion.Name = string.format("Expansion Area %d", largeExpansionsHead)
            expansion.Size = 10

            -- legacy entries
            expansion.type = expansion.Type
            expansion.name = expansion.Name
            expansion.size = expansion.Size

            smallExpansions[smallExpansionsHead] = expansion
            smallExpansionsHead = smallExpansionsHead + 1
        end
    end

    ---------------------------------------------------------------------------
    -- And at last, populate the information neighboring extractors that we 
    -- found. The center of those extractors is used as the location of the 
    -- marker

    import("/lua/sim/markerutilities.lua").OverwriteMarkerByType('Large Expansion Area', largeExpansions)
    import("/lua/sim/markerutilities.lua").OverwriteMarkerByType('Expansion Area', smallExpansions)

    SPEW(string.format("Generated rally point markers in %.2f miliseconds", 1000 * (GetSystemTimeSecondsOnlyForProfileUse() - start)))
end