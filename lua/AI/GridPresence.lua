local Grid = import("/lua/ai/grid.lua").Grid
local MarkerUtilities = import("/lua/sim/MarkerUtilities.lua")
local NavUtils = import("/lua/sim/NavUtils.lua")

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

---@class AIGridPresenceCell : AIGridCell
---@field Labels table<number, boolean>         # <label, boolean>
---@field Inferred table<number, 'Allied' | 'Hostile' | 'Contested' | 'Unoccupied'>     # <label, status>
---@field StatusQuo table<number, 'Allied' | 'Hostile' | 'Contested' | 'Unoccupied'>    # <label, status>
---@field CountHostile table<number, number>    # <label, count>
---@field CountAllied table<number, number>     # <label, count>

---@class AIGridPresence : AIGrid
---@field Brain moho.aibrain_methods        # Brain we compute presence for
---@field Labels table<number, boolean>     # <label, boolean>
---@field Cells AIGridPresenceCell[][]
GridPresence = Class(Grid) {

    ---@param self AIGridPresence
    __init = function(self, brain)
        Grid.__init(self)

        self.Brain = brain
        self.Labels = { }

        local cellCount = self.CellCount
        local cells = self.Cells

        for gx = 1, cellCount do
            for gz = 1, cellCount do
                local cell = cells[gx][gz]
                cell.Labels = NavUtils.GetLabelsofIMAP('Hover', gz, gx) or { }

                cell.Inferred = { }
                for label, _ in cell.Labels do
                    cell.Inferred[label] = 'Unoccupied'
                end

                cell.StatusQuo = { }
                for label, _ in cell.Labels do
                    cell.StatusQuo[label] = 'Unoccupied'
                end

                cell.CountAllied = { }
                for label, _ in cell.Labels do
                    cell.CountAllied[label] = 0
                end

                cell.CountHostile = { }
                for label, _ in cell.Labels do
                    cell.CountHostile[label] = 0
                end
            end
        end

        self:Update()
        self:DebugUpdate()
    end,

    ---@param self AIGridPresence
    Update = function(self)
        ForkThread(
            self.UpdateThread,
            self
        )
    end,

    ---@param self AIGridPresence
    UpdateThread = function(self)
        local cellCount = self.CellCount
        local cells = self.Cells
        local brain = self.Brain

        ---@type AIGridPresenceCell[]
        local iterationA = { }

        ---@type AIGridPresenceCell[]
        local iterationB = { }

        while true do

            -- counting of extractors
            local massMarkers, extractorCount = MarkerUtilities.GetMarkersByType('Mass')
            for k = 1, extractorCount do
                local massMarker = massMarkers[k]
                local position = massMarker.position

                -- compute hostile / allied units
                local countHostile = table.getn(brain:GetUnitsAroundPoint(categories.STRUCTURE, position, 6, 'Enemy'))
                local countAllied = table.getn(brain:GetUnitsAroundPoint(categories.STRUCTURE, position, 6, 'Ally'))

                -- update status quo
                local label = NavUtils.GetLabel('Hover', position)
                if label and label > 0 then
                    local cell = self:ToCellFromWorldSpace(position[1], position[3])
                    cell.CountAllied[label] = (cell.CountAllied[label] or 0) + countAllied
                    cell.CountHostile[label] = (cell.CountHostile[label] or 0) + countHostile

                    self.Labels[label] = true
                end
            end

            WaitTicks(1)

            -- initial status quo
            for k = 1, cellCount do
                for l = 1, cellCount do
                    local cell = cells[k][l]

                    for label, _ in cell.Labels do
                        local allied = cell.CountAllied[label]
                        local hostile = cell.CountHostile[label]
                        if allied and hostile then
                            if allied > hostile then
                                cell.StatusQuo[label] = 'Allied'
                            elseif hostile > allied then
                                cell.StatusQuo[label] = 'Hostile'
                            elseif hostile == allied and hostile > 0 then
                                cell.StatusQuo[label] = 'Contested'
                            else
                                cell.StatusQuo[label] = 'Unoccupied'
                            end
                        else
                            cell.StatusQuo[label] = 'Unoccupied'
                        end

                        cell.CountAllied[label] = 0
                        cell.CountHostile[label] = 0
                    end
                end
            end

            -- initial inferred
            for k = 1, cellCount do
                for l = 1, cellCount do
                    local cell = cells[k][l]

                    for label, _ in cell.Labels do
                        cell.Inferred[label] = 'Unoccupied'
                    end
                end
            end

            -- use status quo to populate inferred fields
            for label, _ in self.Labels do

                local headA = 1

                -- first iteration to populate initial inferred fields
                for k = 1, cellCount do
                    for l = 1, cellCount do
                        local cell = cells[k][l]
                        if cell.Labels[label] and cell.StatusQuo[label] != 'Unoccupied' then
                            cell.Inferred[label] = cell.StatusQuo[label]
                            iterationA[headA] = cell
                            headA = headA + 1
                        end
                    end
                end

                -- consecutive iterations until all inferred fields are populated
                repeat

                    -- shuffle the order
                    for k = headA - 1, 1, -1 do

                        local j = (Random() * (k - 1) + 1) ^ 0;
                        local value = iterationA[j];
                        iterationA[j] = iterationA[k];
                        iterationA[k] = value;
                    end

                    -- expand
                    local headB = 1
                    for k = 1, headA - 1 do
                        local cell = iterationA[k]
                        for lx = -1, 1 do
                            for lz = -1, 1 do
                                local neighbor = cells[cell.X + lx][cell.Z + lz]
                                if neighbor and neighbor != cell then
                                    if neighbor.Labels[label] then
                                        if (neighbor.Inferred[label] == 'Unoccupied') then
                                            neighbor.Inferred[label] = cell.Inferred[label]
                                            iterationB[headB] = neighbor
                                            headB = headB + 1
                                        end
                                    end
                                end
                            end
                        end
                    end

                    -- switch them up
                    local iterationT = iterationA
                    iterationA = iterationB
                    iterationB = iterationT
                    headA = headB

                    WaitTicks(1)

                until headA <= 1
            end

            WaitTicks(1)

            -- use status quo to populate status quo fields
            for label, _ in self.Labels do
                for k = 1, cellCount do
                    for l = 1, cellCount do
                        local cell = cells[k][l]
                        cell.StatusQuo[label] = cell.Inferred[label]
                    end
                end
            end

            WaitTicks(1)

            -- use status quo to finalize the inferred fields
            for label, _ in self.Labels do
                for k = 1, cellCount do
                    for l = 1, cellCount do
                        local cell = cells[k][l]

                        if cell.Labels[label] then
                            for lx = -1, 1 do
                                for lz = -1, 1 do
                                    local neighbor = cells[cell.X + lx][cell.Z + lz]
                                    if neighbor and neighbor != cell and neighbor.Labels[label] then
                                        if cell.StatusQuo[label] != neighbor.StatusQuo[label] then
                                            cell.Inferred[label] = 'Contested'
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            WaitTicks(1)
        end
    end,

    --- Converts a world position to a cell
    ---@param self AIGridPresence
    ---@param wx number     # in world space
    ---@param wz number     # in world space
    ---@return AIGridPresenceCell
    ToCellFromWorldSpace = function(self, wx, wz)
        local gx, gz = self:ToGridSpace(wx, wz)
        return self.Cells[gx][gz]
    end,

    --- Converts a grid position to a cell
    ---@param self AIGridPresence
    ---@param gx number     # in grid space
    ---@param gz number     # in grid space
    ---@return AIGridPresenceCell
    ToCellFromGridSpace = function(self, gx, gz)
        return self.Cells[gx][gz]
    end,

    --- Contains various debug logic
    ---@param self AIGridPresence
    DebugUpdate = function(self)
        ForkThread(
            self.DebugUpdateThread,
            self
        )
    end,

    --- Allows us to scan the map
    ---@param self AIGridPresence
    DebugUpdateThread = function(self)

        local cellCount = self.CellCount
        local cells = self.Cells
        local brain = self.Brain

        while true do
            for k = 1, cellCount do
                for l = 1, cellCount do
                    local cell = cells[k][l]
                    for label, _ in cell.Labels do
                        if cell.Inferred[label] == 'Allied' then
                            self:DrawCell(cell.X, cell.Z, math.sqrt(label), '00ff00')
                        elseif cell.Inferred[label] == 'Hostile' then
                            self:DrawCell(cell.X, cell.Z, math.sqrt(label), 'ff0000')
                        elseif cell.Inferred[label] == 'Contested' then
                            self:DrawCell(cell.X, cell.Z, math.sqrt(label), 'FFD900')
                        else
                            self:DrawCell(cell.X, cell.Z, math.sqrt(label), 'A0FFFFFF')
                        end
                    end
                end
            end

            WaitTicks(1)
        end
    end,
}

---@param brain moho.aibrain_methods
---@return AIGridPresence
Setup = function(brain)
    return GridPresence(brain)
end
