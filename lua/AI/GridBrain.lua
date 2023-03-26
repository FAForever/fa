local Grid = import("/lua/ai/grid.lua").Grid

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

---@class AIGridBrainCell : AIGridCell
---@field EngineersReclaiming table<EntityId, Unit>

---@class AIGridBrain : AIGrid
---@field Cells AIGridBrainCell[][]
GridBrain = Class(Grid) {

    ---@param self AIGridReclaim
    __init = function(self)
        Grid.__init(self)

        local cellCount = self.CellCount
        local cells = self.Cells

        for k = 1, cellCount do
            for l = 1, cellCount do
                local cell = cells[k][l]
                cell.EngineersReclaiming = { }
            end
        end

        self:Update()
        self:DebugUpdate()
    end,

    --- Converts a world position to a cell
    ---@param self AIGridBrain
    ---@param wx number     # in world space
    ---@param wz number     # in world space
    ---@return AIGridBrainCell
    ToCellFromWorldSpace = function(self, wx, wz)
        local gx, gz = self:ToGridSpace(wx, wz)
        return self.Cells[gx][gz]
    end,

    --- Converts a grid position to a cell
    ---@param self AIGridBrain
    ---@param gx number     # in grid space
    ---@param gz number     # in grid space
    ---@return AIGridBrainCell
    ToCellFromGridSpace = function(self, gx, gz)
        return self.Cells[gx][gz]
    end,

    --- Registers an engineer reclaiming in the given cell
    ---@param self AIGridBrain
    ---@param cell AIGridBrainCell
    ---@param engineer Unit
    AddReclaimingEngineer = function(self, cell, engineer)
        cell.EngineersReclaiming[engineer.EntityId] = engineer
    end,

    --- Unregisters an engineer reclaiming in a given cell
    ---@param self AIGridBrain
    ---@param cell AIGridBrainCell
    ---@param engineer Unit
    RemoveReclaimingEngineer = function(self, cell, engineer)
        cell.EngineersReclaiming[engineer.EntityId] = nil
    end,

    --- Counts the number of engineers reclaiming in a cell
    ---@param self AIGridBrain
    ---@param cell AIGridBrainCell
    CountReclaimingEngineers = function(self, cell)
        return table.getsize(cell.EngineersReclaiming)
    end,
}

---@return AIGridBrain
Setup = function()
    return GridBrain()
end
