local Grid = import("/lua/ai/grid.lua").Grid

local WeakValue = { __mode = 'v' }

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
---@field EngineersReclaiming table<EntityId, Unit>
---@field AssignedScouts { LAND: table<EntityId, Unit>, AIR: table<EntityId, Unit> } 
---@field LastScouted number
---@field ScoutPriority number
---@field MustScout boolean
---@field IntelCoverage boolean

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

    RegisterExtractorDeposit = function(self, deposit)

    end,

    RegisterHydrocarbonDeposit = function(self, deposit)

    end,

    ---@param self AIGridDeposits
    ---@param position Vector
    ---@param distance number
    GetResourcesWithinDistance = function (self, depositType, position, distance)
    end,

    ---@param self AIGridDeposits
    ---@param position Vector
    ---@param distance number
    GetResourcesWithinRadius = function (self, depositType, position, distance)
    end,
}

---@type AIGridDeposits
GridDepositsInstance = false

---@return AIGridDeposits
Setup = function()
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
