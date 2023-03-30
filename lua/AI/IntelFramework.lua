local GridIntel = import("/lua/ai/gridintel.lua")
local AIUtils = import("/lua/ai/aiutilities.lua")

---@class AIGrid
---@field Cells table[][]
---@field CellCount number
---@field CellSize number
IntelFramework = ClassSimple {

    ---@param self AIBrain
    __init = function(self, brain)
        self.IntelGrid = GridIntel.Setup()
        self.PlayableArea = ScenarioInfo.MapData.PlayableRect or {0, 0, ScenarioInfo.size[1], ScenarioInfo.size[2]}
        self.StartPosition = brain:GetStartVector3f()
        local massPoints, massCount = import("/lua/sim/markerutilities.lua").GetMarkersByType('Mass')
        local teamCount, teamStarts, allyCount, enemyCount = AIUtils.CalculateTeamdata(brain)
        self.TeamCount = teamCount
        self.StartPositions = teamStarts
        self.AllyCount = allyCount
        self.EnemyCount = enemyCount
        if massCount > 0 and enemyCount > 0 then
            self.TeamMassShare = math.floor(massCount / teamCount)
        else
            self.TeamMassShare = massCount
        end
        if allyCount > 0 and enemyCount > 0 and massCount > 0 then
            self.PlayerMassShare = math.floor(massCount / (allyCount + enemyCount))
        else
            self.PlayerMassShare = massCount
        end
        self:CalculateScoutLocations(massPoints)
        LOG('Total Mass Count '..massCount)
        LOG('Team Count '..self.TeamCount)
        LOG('StartPositions '..repr(self.StartPositions))
        LOG('Ally Count '..self.AllyCount)
        LOG('Enemy Count '..self.EnemyCount)
        LOG('Team Mass Share '..self.TeamMassShare)
        LOG('Player Mass Share '..self.PlayerMassShare)
        LOG('IntelGrid '..repr(self.IntelGrid))
    end,

    CalculateScoutLocations = function(self, massPoints)
        -- This will generate initial scouting locations based on known information
        local GetMarkersByType = import("/lua/sim/markerutilities.lua").GetMarkersByType
        for _, v in self.StartPositions do
            if not v.Ally and v.StartPosition[1] then
                local cx, cz = self.IntelGrid:ToCellIndices(v.StartPosition[1], v.StartPosition[3])
                self.IntelGrid.Cells[cx][cz].ScoutPriority = 1000
                self.IntelGrid.Cells[cx][cz].MustScout = true
            end
        end
        local startLocations = GetMarkersByType('Start Location')
        for _, v in startLocations do
            local cx, cz = self.IntelGrid:ToCellIndices(v.position[1], v.position[3])
            if self.IntelGrid.Cells[cx][cz].ScoutPriority < 1000 then
                self.IntelGrid.Cells[cx][cz].ScoutPriority = 750
            end
        end
        local largeExpansionLocations = GetMarkersByType('Large Expansion Area')
        for _, v in largeExpansionLocations do
            local cx, cz = self.IntelGrid:ToCellIndices(v.position[1], v.position[3])
            if self.IntelGrid.Cells[cx][cz].ScoutPriority < 750 then
                self.IntelGrid.Cells[cx][cz].ScoutPriority = 500
            end
        end
        local expansionLocations = GetMarkersByType('Expansion Area')
        for _, v in expansionLocations do
            local cx, cz = self.IntelGrid:ToCellIndices(v.position[1], v.position[3])
            if self.IntelGrid.Cells[cx][cz].ScoutPriority < 500 then
                self.IntelGrid.Cells[cx][cz].ScoutPriority = 250
            end
        end
        for _, v in massPoints do
            local cx, cz = self.IntelGrid:ToCellIndices(v.position[1], v.position[3])
            if self.IntelGrid.Cells[cx][cz].ScoutPriority < 250 then
                self.IntelGrid.Cells[cx][cz].ScoutPriority = 25
            end
        end
    end,
    
    QueryScoutLocation = function(self, aiBrain, scout)
        local maxmapdimension = math.max(ScenarioInfo.size[1],ScenarioInfo.size[2])
        local bestPosition
        local maxCells
        if maxmapdimension <= 256 then maxCells = 8 else maxCells = 16 end
        local currentPosition = scout:GetPosition()
        --local enemy = aiBrain:GetCurrentEnemy()
        local bx, bz = self.IntelGrid:ToCellIndices(currentPosition[1], currentPosition[3])
        local cells = self.IntelGrid.Cells
        local candidate = nil
        local value = 0
        for lx = -maxCells, maxCells do
            local column = cells[bx + lx]
            if column then
                for lz = -maxCells, maxCells do
                    local cell = column[bz + lz]
                    if cell and cell.ScoutPriority > 0 then
                        if self.IntelGrid:CountAssignedScouts(cell, 1) < 1 then
                            -- any candidate is a good candidate
                            if not candidate then
                                candidate = cell
                                value = cell.ScoutPriority * VDist2(self.StartPosition[1], self.StartPosition[3], currentPosition[1], currentPosition[3])
                            -- compare if the cell we're evaluating is better
                            else
                                local alt = cell.ScoutPriority * VDist2(self.StartPosition[1], self.StartPosition[3], currentPosition[1], currentPosition[3])
                                if alt > value then
                                    candidate = cell
                                    value = alt
                                end
                            end
                        end
                    end
                end
            end
        end
        if value then
            return candidate
        else
            WARN('No scout query location returned')
            return false
        end
    end,
}

Setup = function(brain)
    return IntelFramework(brain)
end

