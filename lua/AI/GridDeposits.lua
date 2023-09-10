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
---@field MassDeposits { Marker: MarkerResource, NavAmphLayer: number }
---@field HydroDeposits { Marker: MarkerResource, NavAmphLayer: number }

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
                cell.MassDeposits = {}
                cell.HydroDeposits = {}
            end
        end

        --self:Update()
        --self:DebugUpdate()
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
        table.insert(cell.MassDeposits, { Marker = deposit })
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
        table.insert(cell.HydroDeposits, { Marker = deposit })
    end,

    ---@param self AIGridDeposits
    ---@param position Vector
    ---@param distance number
    GetResourcesWithinDistance = function(self, depositType, position, distance)
    end,

    ---@param self AIGridDeposits
    ---@param position Vector
    ---@param distance number
    GetResourcesWithinRadius = function(self, depositType, position, distance)
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
