
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

        LOG('Cell Size is '..self.CellSize)

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
                cell.TotalMass = 0
                cell.TotalEnergy = 0
                cell.ReclaimEngineerAssigned = false
                cell.AssignedScout = false
                cell.LastScouted = 0
                cell.TimeScouted = 0
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

        self.UpdateList = { }
        self.Brains = { }

        self:Update()
        --self:DebugUpdate()
    end,

    ---@param self AIGridIntel
    Update = function(self)
        ForkThread(
            self.UpdateThread,
            self
        )
    end,

    ---@param self AIGridIntel
    UpdateThread = function(self)
        while true do
            WaitTicks(50)
        end
    end,

    ---------------------
    -- Debug functions --

    --- Contains various debug logic
    ---@param self AIGridIntel
    DebugUpdate = function(self)
        ForkThread(
            self.DebugUpdateThread,
            self
        )
    end,

    --- Allows us to scan the map
    ---@param self AIGridIntel
    DebugUpdateThread = function(self)
        while true do
            WaitTicks(1)

            -- mouse scanning
            if Debug then
                local mouse = GetMouseWorldPos()
                local bx, bz = self:ToCellIndices(mouse[1], mouse[3])
                local cell = self.Cells[bx][bz]

                local totalMass = cell.TotalMass
                if totalMass and totalMass > 0 then
                    self:DrawCell(bx, bz, math.log(totalMass) - 1, '00610B')
                end

                local totalEnergy = cell.TotalEnergy
                if totalEnergy and totalEnergy > 0 then
                    self:DrawCell(bx, bz, math.log(totalEnergy) - 1, 'B4C400')
                end

                local totalTime = cell.TotalTime
                if totalTime and totalTime > 1 then
                    self:DrawCell(bx, bz, math.log(totalTime) - 1, '7F7F7D')
                end

                self:DrawCell(bx, bz, 0, 'ffffff')
            end
        end
    end,

    --- Debugging logic when a cell is updated
    ---@param self AIGridIntel
    ---@param bx number
    ---@param bz number
    DebugCellUpdate = function(self, bx, bz)
        if Debug then
            self:DrawCell(bx, bz, 1, '48FF00')
        end
    end,

    --- Debugging logic when a prop is destroyed
    ---@param self AIGridIntel
    ---@param prop Prop
    DebugPropDestroyed = function(self, prop)
        if Debug then
            DrawCircle(prop.CachePosition, 2, 'ff0000')
        end
    end,

    --- Debugging logic when a prop is updated
    ---@param self AIGridIntel
    ---@param prop Prop
    DebugPropUpdated = function(self, prop)
        if Debug then
            DrawCircle(prop.CachePosition, 2, '0000ff')
        end
    end,
}

---@type AIGridIntel
GridIntelInstance = false

---@param brain AIBrain
Setup = function(brain)
    if not GridIntelInstance then
        GridIntelInstance = GridIntel() --[[@as AIGridIntel]]
    end

    return GridIntelInstance.Cells
end
