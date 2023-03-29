
local Grid = import("/lua/ai/grid.lua").Grid

local Debug = true
function SetDebug(value)
    Debug = value
end

---@class AIGridIntelCell : AIGridCell
---@field TotalMass number
---@field TotalEnergy number
---@field TotalTime number
---@field IntelCount number
---@field Intel table<EntityId, Prop>

---@class AIGridIntelm : AIGrid
---@field Cells AIGridIntelCell[][]
---@field UpdateList table<string, AIGridIntelCell>
---@field Brains table<number, AIBrain>
GridIntel = Class (Grid) {

    ---@param self AIGridIntel
    __init = function(self)
        Grid.__init(self)

        local cellCount = self.CellCount
        local cells = self.Cells
        local playableArea = ScenarioInfo.MapData.PlayableRect or {0, 0, ScenarioInfo.size[1], ScenarioInfo.size[2]}
        local startingGridx = 256
        local endingGridx = 1
        local startingGridz = 256
        local endingGridz = 1

        for k = 1, cellCount do
            for l = 1, cellCount do
                local cell = cells[k][l]
                cell.LandScoutsAssigned = { }
                cell.AirScoutsAssigned = { }
                cell.LastScouted = 0
                cell.MustScout = false
                cell.ScoutPriority = 0
                cell.IntelCoverage = false
                local cx = self.CellSize * (k - 0.5)
                local cz = self.CellSize * (l - 0.5)
                cell.Position = {cx, GetTerrainHeight(cx, cz), cz}
                if cx < playableArea[1] or cz < playableArea[2] or cx > playableArea[3] or cz > playableArea[4] then
                    continue
                end
                cell.Water = GetTerrainHeight(cx, cz) < GetSurfaceHeight(cx, cz)
                startingGridx = math.min(k, startingGridx)
                startingGridz = math.min(l, startingGridz)
                endingGridx = math.max(k, endingGridx)
                endingGridz = math.max(l, endingGridz)
            end
        end
        self.IntelGridSize = self.CellSize
        self.IntelGridXMin = startingGridx
        self.IntelGridXMax = endingGridx
        self.IntelGridZMin = startingGridz
        self.IntelGridZMax = endingGridz
        local gridSizeX, gridSizeZ = self:ToCellIndices((playableArea[3] - 16), (playableArea[4] - 16))
        self.IntelGridXRes = gridSizeX
        self.IntelGridZRes = gridSizeZ
    end,

    --- Registers a scout in a given cell
    ---@param self AIGridBrain
    ---@param cell AIGridBrainCell
    ---@param scout Unit
    AddAssignedScout = function(self, cell, scout, type)
        if type == 1 then
            cell.LandScoutsAssigned[scout.EntityId] = scout
        elseif type == 2 then
            cell.AirScoutsAssigned[scout.EntityId] = scout
        else
            WARN('IntelFramework unable to assign scout, invalid type')
        end
    end,

    --- Unregisters a scout in a given cell
    ---@param self AIGridBrain
    ---@param cell AIGridBrainCell
    ---@param scout Unit
    RemoveAssignedScout = function(self, cell, scout, type)
        if type == 1 then
            cell.LandScoutsAssigned[scout.EntityId] = nil
        elseif type == 2 then
            cell.AirScoutsAssigned[scout.EntityId] = nil
        else
            WARN('IntelFramework unable to unassign scout, invalid type')
        end
    end,

    --- Counts the number of scouts assigned to a cell
    ---@param self AIGridBrain
    ---@param cell AIGridBrainCell
    CountAssignedScouts = function(self, cell, type)
        if type == 1 then
            return table.getsize(cell.LandScoutsAssigned)
        elseif type == 2 then
            return table.getsize(cell.AirScoutsAssigned)
        else
            WARN('IntelFramework unable to get scout count, invalid type')
        end
    end,
}

Setup = function()
    return GridIntel()
end
