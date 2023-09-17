local Grid = import("/lua/ai/grid.lua").Grid
local NavUtils = import("/lua/sim/navutils.lua")

local Debug = false
function EnableDebugging()
    if ScenarioInfo.GameHasAIs or CheatsEnabled() then
        Debug = true
    end
end

function DisableDebugging()
    if ScenarioInfo.GameHasAIs or CheatsEnabled() then
        Debug = false
    end
end

---@class AIGridDepositsCell : AIGridCell
---@field Deposits { Marker: MarkerResource, NavAmphLayer: number, Type: 'Mass' | 'Hydrocarbon', Position: Vector }[]

---@class AIGridDeposits : AIGrid
---@field Cells AIGridDepositsCell[][]
GridDeposits = Class(Grid) {

    ---@param self AIGridDeposits
    __init = function(self)
        Grid.__init(self)

        local cellCount = self.CellCount
        local cells = self.Cells

        for k = 1, cellCount do
            for l = 1, cellCount do
                local cell = cells[k][l]
                cell.Deposits = {}
            end
        end

        -- self:Update()
        -- self:DebugUpdate()
    end,

    --- Converts a world position to a cell
    ---@param self AIGridDeposits
    ---@param wx number     # in world space
    ---@param wz number     # in world space
    ---@return AIGridDepositsCell
    ToCellFromWorldSpace = function(self, wx, wz)
        local gx, gz = self:ToGridSpace(wx, wz)
        return self.Cells[gx][gz]
    end,

    --- Converts a grid position to a cell
    ---@param self AIGridDeposits
    ---@param gx number     # in grid space
    ---@param gz number     # in grid space
    ---@return AIGridDepositsCell
    ToCellFromGridSpace = function(self, gx, gz)
        return self.Cells[gx][gz]
    end,

    ---@param self AIGridDeposits
    ---@param deposit MarkerResource
    RegisterExtractorDeposit = function(self, deposit)
        local isResource = deposit.resource or deposit.Resource
        if not (isResource) then
            return
        end

        local isExtractor = (deposit.type or deposit.Type) == 'Mass'
        if not isExtractor then
            return
        end

        local position = deposit.position or deposit.Position
        if not position then
            return
        end

        local cell = self:ToCellFromWorldSpace(position[1], position[3])
        table.insert(cell.Deposits, { Marker = deposit, Type = 'Mass', Position = position })
    end,

    ---@param self AIGridDeposits
    ---@param deposit MarkerResource
    RegisterHydrocarbonDeposit = function(self, deposit)
        local isResource = deposit.resource or deposit.Resource
        if not (isResource) then
            return
        end

        local isHydrocarbon = (deposit.type or deposit.Type) == 'Hydrocarbon'
        if not isHydrocarbon then
            return
        end

        local position = deposit.position or deposit.Position
        if not position then
            return
        end

        local cell = self:ToCellFromWorldSpace(position[1], position[3])
        table.insert(cell.Deposits, { Marker = deposit, Type = 'Hydrocarbon', Position = position })
    end,

    --- Retrieves all resources that are within a given pathing distance to the provided position
    ---@param self AIGridDeposits
    ---@param depositType 'Mass' | 'Hydrocarbon'
    ---@param position Vector
    ---@param distance number
    ---@param layer NavLayers
    ---@param cache? MarkerResource[]
    ---@return MarkerResource[]
    ---@return number
    GetResourcesWithinDistance = function(self, depositType, position, distance, layer, cache)
        local head = 1
        local resources = cache or { }

        local navLabel = NavUtils.GetLabel(layer, position)

        local gx, gz = self:ToGridSpace(position[1], position[3])
        local gridDistance = NavUtils.ToGridDistance(distance)
        for lx = -gridDistance, gridDistance do
            local x = gx + lx
            for lz = -gridDistance, gridDistance do
                local z = gz + lz
                local cell = self.Cells[x][z]

                -- cell is outside of map
                if not cell then
                    continue
                end

                local deposits = cell.Deposits
                for k = 1, table.getn(deposits) do
                    local deposit = deposits[k]
                    local markerPosition = deposit.Position

                    local dx = position[1] - markerPosition[1]
                    local dz = position[3] - markerPosition[3]
                    local distanceToMarker = dx * dx + dz * dz

                    -- flat distance is too far away, pathing won't bring it closer
                    if distanceToMarker > (distance * distance) then
                        continue
                    end

                    -- wrong type of resource deposit
                    if not deposit.Type == depositType then
                        continue
                    end

                    local label = NavUtils.GetLabel(layer, markerPosition)

                    -- wrong type of label, we can't possibly compute a distance
                    if navLabel != label then
                        continue
                    end

                    local path, count, pathDistance = NavUtils.PathTo(layer, position, markerPosition)

                    -- apparently we can't reach this marker
                    if not pathDistance then
                        continue
                    end

                    if pathDistance <= distance then
                        resources[head] = deposit.Marker
                        head = head + 1
                    end
                end
            end
        end

        -- remove remainder of the cache
        for k = head, table.getn(resources) do
            resources[k] = nil
        end

        return resources, head - 1
    end,

    --- Retrieves all resources that are within a given radius, ignoring all other factors
    ---@param self AIGridDeposits
    ---@param depositType 'Mass' | 'Hydrocarbon'
    ---@param position Vector
    ---@param distance number
    ---@param cache? MarkerResource[]
    ---@return MarkerResource[]
    ---@return number
    GetResourcesWithinRadius = function(self, depositType, position, distance, cache)
        local head = 1
        local resources = cache or { }

        local gx, gz = self:ToGridSpace(position[1], position[3])
        local gridDistance = NavUtils.ToGridDistance(distance)
        for lx = -gridDistance, gridDistance do
            local x = gx + lx
            for lz = -gridDistance, gridDistance do
                local z = gz + lz
                local cell = self.Cells[x][z]

                -- cell is outside of map
                if not cell then
                    continue
                end

                local deposits = cell.Deposits
                for k = 1, table.getn(deposits) do
                    local deposit = deposits[k]

                    -- wrong type of resource deposit
                    if not deposit.Type == depositType then
                        continue
                    end

                    -- compute squared distance
                    local dx = position[1] - deposit.Position[1]
                    local dz = position[3] - deposit.Position[3]
                    local distanceToMarker = dx * dx + dz * dz

                    if distanceToMarker <= (distance * distance) then
                        resources[head] = deposit.Marker
                        head = head + 1
                    end
                end
            end
        end

        -- remove remainder of the cache
        for k = head, table.getn(resources) do
            resources[k] = nil
        end

        return resources, head - 1
    end,

    ---------------------------------------------------------------------------
    --#region Debugging

    ---@param self AIGridDeposits
    DebugUpdateThread = function(self)
        local cache = { }
        while true do

            local position = GetMouseWorldPos()
            local start = GetSystemTimeSecondsOnlyForProfileUse()
            local resources = self:GetResourcesWithinDistance('Mass' , position, 50, 'Amphibious', cache)
            local duration = GetSystemTimeSecondsOnlyForProfileUse() - start

            if duration > 0.001 then
                SPEW("Long time: " .. tostring(duration))
            end

            for k, resource in resources do
                DrawLinePop(position, resource.Position, 'ffffff')
            end

            WaitTicks(1)
        end
    end,

    ---@param self AIGridDeposits
    DebugUpdate = function(self)
        ForkThread(self.DebugUpdateThread, self)
    end,
}

---@type AIGridDeposits
GridDepositsInstance = false

---@return AIGridDeposits
Setup = function()

    -- requires the navigational mesh
    NavUtils.Generate()

    if not GridDepositsInstance then
        GridDepositsInstance = GridDeposits() --[[@as AIGridDeposits]]

        local markerUtilities = import("/lua/sim/MarkerUtilities.lua")

        local extractors, extractorCount = markerUtilities.GetMarkersByType('Mass')
        for k = 1, extractorCount do
            GridDepositsInstance:RegisterExtractorDeposit(extractors[k])
        end

        local hydrocarbons, hydrocarbonCount = markerUtilities.GetMarkersByType('Hydrocarbon')
        for k = 1, hydrocarbonCount do
            GridDepositsInstance:RegisterExtractorDeposit(hydrocarbons[k])
        end
    end

    return GridDepositsInstance
end
