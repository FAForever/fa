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
        self:CalculateScoutLocations()
        LOG('Total Mass Count '..massCount)
        LOG('Team Count '..self.TeamCount)
        LOG('StartPositions '..repr(self.StartPositions))
        LOG('Ally Count '..self.AllyCount)
        LOG('Enemy Count '..self.EnemyCount)
        LOG('Team Mass Share '..self.TeamMassShare)
        LOG('Player Mass Share '..self.PlayerMassShare)
        LOG('IntelGrid '..repr(self.IntelGrid))
    end,

    CalculateScoutLocations = function(self)
        -- This will generate initial scouting locations based on known information
        local GetMarkersByType = import("/lua/sim/markerutilities.lua").GetMarkersByType
        for _, v in self.StartPositions do
            if not v.Ally and v.StartPosition[1] then
                local cx, cz = self.IntelGrid:ToCellIndices(v.StartPosition[1], v.StartPosition[3])
                self.IntelGrid.Cells[cx][cz].ScoutPriority = 100
                self.IntelGrid.Cells[cx][cz].MustScout = true
            end
        end
        local startLocations = GetMarkersByType('Start Location')
        for _, v in startLocations do
            local cx, cz = self.IntelGrid:ToCellIndices(v.position[1], v.position[3])
            if self.IntelGrid.Cells[cx][cz].ScoutPriority < 100 then
                self.IntelGrid.Cells[cx][cz].ScoutPriority = 75
            end
        end
        local largeExpansionLocations = GetMarkersByType('Large Expansion Area')
        for _, v in largeExpansionLocations do
            local cx, cz = self.IntelGrid:ToCellIndices(v.position[1], v.position[3])
            if self.IntelGrid.Cells[cx][cz].ScoutPriority < 75 then
                self.IntelGrid.Cells[cx][cz].ScoutPriority = 50
            end
        end
        local expansionLocations = GetMarkersByType('Expansion Area')
        for _, v in expansionLocations do
            local cx, cz = self.IntelGrid:ToCellIndices(v.position[1], v.position[3])
            if self.IntelGrid.Cells[cx][cz].ScoutPriority < 50 then
                self.IntelGrid.Cells[cx][cz].ScoutPriority = 25
            end
        end
    end,
}

Setup = function(brain)
    return IntelFramework(brain)
end

