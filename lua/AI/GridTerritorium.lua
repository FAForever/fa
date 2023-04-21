local Grid = import("/lua/ai/grid.lua").Grid
local MarkerUtilities = import("/lua/sim/MarkerUtilities.lua")

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

local WeakValues = { __mode = 'v' }

---@class AIGridTerritoriumExpansion
---@field Marker MarkerExpansion
---@field Position Vector
---@field Size number
---@field Structures table<Army, table<EntityId, Unit>>
---@field OwnedBy Army

---@class GridTerritoriumCell : AIGridCell
---@field Structures table<Army, Unit[]>
---@field OwnedBy Army

---@class GridTerritorium : AIGrid
---@field Cells GridTerritoriumCell[][]
---@field Expansions AIGridTerritoriumExpansion[]
GridTerritorium = Class(Grid) {

    ---@param self GridTerritorium
    __init = function(self)
        Grid.__init(self)

        local cellCount = self.CellCount
        local cells = self.Cells

        for k = 1, cellCount do
            for l = 1, cellCount do
                local cell = cells[k][l]
                cell.OwnedBy = -1
                cell.Expansions = {}
            end
        end

        self.Expansions = {}

        ForkThread(
            function()
                WaitTicks(10)

                local expansionMarkers, count
                expansionMarkers, count = MarkerUtilities.GetMarkersByType('Expansion Area')
                self:RegisterExpansions(expansionMarkers, count, 15)

                expansionMarkers, count = MarkerUtilities.GetMarkersByType('Large Expansion Area')
                self:RegisterExpansions(expansionMarkers, count, 30)

                LOG(table.getn(self.Expansions))
            end
        )


        ForkThread(self.UpdateThread, self)
        ForkThread(self.UpdateDebugThread, self)
    end,

    ---@param self GridTerritorium
    ---@param markers MarkerExpansion[]
    ---@param count number
    RegisterExpansions = function(self, markers, count, size)
        for k = 1, count do
            local marker = markers[k]

            -- structures for each army
            local structures = {}
            for army, _ in ArmyBrains do
                structures[army] = setmetatable({}, WeakValues)
            end

            table.insert(
                self.Expansions,
                {
                    Marker = marker,
                    Position = marker.position,
                    Size = size,
                    Structures = structures,
                    OwnedBy = -1,
                }
            )
        end
    end,

    ---@param self GridTerritorium
    UpdateThread = function(self)
        -- local scope for performance
        local GetUnitsInRect = GetUnitsInRect
        local ArmyBrains = ArmyBrains
        local EntityCategoryFilterDown = EntityCategoryFilterDown
        local WaitTicks = WaitTicks

        local TableGetn = table.getn
        local TableGetSize = table.getsize

        -- pre-computed for performance
        local cats = categories.STRUCTURE - (categories.WALL + categories.DEFENSE)

        while true do
            local expansions = self.Expansions
            local expansionCount = table.getn(self.Expansions)
            for k = 1, expansionCount do
                local expansionInfo = expansions[k]
                local position = expansionInfo.Position
                local size = expansionInfo.Size

                local lx = position[1] - 0.8 * size
                local rx = position[1] + 0.8 * size
                local tz = position[3] - 0.8 * size
                local bz = position[3] + 0.8 * size

                local units = GetUnitsInRect(lx, tz, rx, bz)

                if units then
                    -- keep track of the units at the center of the expansion
                    local structures = EntityCategoryFilterDown(cats, units)
                    local numberOfStructures = TableGetn(structures)
                    for l = 1, numberOfStructures do
                        local structure = structures[l]
                        expansionInfo.Structures[structure.Army][structure.EntityId] = structure
                    end

                    -- check who owns this expansion
                    local ownedBy = -1
                    local count = 0
                    for army, _ in ArmyBrains do
                        local n = TableGetSize(expansionInfo.Structures[army])
                        if n > count then
                            ownedBy = army
                            count = n
                        end
                    end

                    expansionInfo.OwnedBy = ownedBy
                else
                    -- nobody owns this expansion
                    expansionInfo.OwnedBy = -1
                end

                WaitTicks(1)
            end
            WaitTicks(1)
        end
    end,

    ---@param self GridTerritorium
    UpdateDebugThread = function(self)

        local ArmyBrains = ArmyBrains


        while true do

            local expansions = self.Expansions
            local expansionCount = table.getn(expansions)

            for k = 1, expansionCount do
                local expansionInfo = expansions[k]
                DrawCircle(expansionInfo.Position, expansionInfo.Size, 'ffffff')
                DrawCircle(expansionInfo.Position, 1, 'ffffff')

                for _, structures in expansionInfo.Structures do
                    for _, structure in structures do
                        DrawLinePop(structure:GetPosition(), expansionInfo.Position, 'ffffff')
                    end
                end
            end

            WaitTicks(1)
        end
    end,

    --- Converts a world position to a cell
    ---@param self GridTerritorium
    ---@param wx number     # in world space
    ---@param wz number     # in world space
    ---@return GridTerritoriumCell
    ToCellFromWorldSpace = function(self, wx, wz)
        local gx, gz = self:ToGridSpace(wx, wz)
        return self.Cells[gx][gz]
    end,

    --- Converts a grid position to a cell
    ---@param self GridTerritorium
    ---@param gx number     # in grid space
    ---@param gz number     # in grid space
    ---@return GridTerritoriumCell
    ToCellFromGridSpace = function(self, gx, gz)
        return self.Cells[gx][gz]
    end,
}

---@type GridTerritorium
GridTerritoriumInstance = false

---@return GridTerritorium
Setup = function()
    if not GridTerritoriumInstance then
        GridTerritoriumInstance = GridTerritorium() --[[@as GridTerritorium]]
    end

    return GridTerritoriumInstance
end
