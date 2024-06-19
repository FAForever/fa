
--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local Grid = import("/lua/ai/grid.lua").Grid
local MarkerUtilities = import("/lua/sim/MarkerUtilities.lua")
local NavUtils = import("/lua/sim/navutils.lua")

-- upvalue scope for performance
local TableGetn = table.getn

local Debug = false
function EnableDebugging()
    Debug = true
end

function DisableDebugging()
    Debug = false
end

---@type GridPresenceUIDebugCell
local DebugCellData = {
    Label = 0,
    Inferred = 'Unoccupied',
}

---@type GridPresenceUIDebugUpdate
local DebugUpdateData = {
    ResourcePointsTime = 0,
    ResourcePointsTick = 0,
    InferredTime = 0,
    InferredTick = 0,
}

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
                cell.Labels = NavUtils.GetLabelsofIMAP('Hover', gx, gz) or { }

                cell.Inferred = { }
                cell.StatusQuo = { }
                cell.CountAllied = { }
                cell.CountHostile = { }

                for label, _ in cell.Labels do
                    cell.Inferred[label] = 'Unoccupied'
                    cell.StatusQuo[label] = 'Unoccupied'
                    cell.CountAllied[label] = 0
                    cell.CountHostile[label] = 0
                    self.Labels[label] = true
                end
            end
        end

        self:Update()
        self:DebugUpdate()
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

    ---@param self AIGridPresence
    Update = function(self)
        ForkThread(
            self.UpdateThread,
            self
        )
    end,

    ---@param self AIGridPresence
    UpdateThread = function(self)

        -- local scope for performance
        local cellCount = self.CellCount
        local cells = self.Cells
        local brain = self.Brain

        local GetUnitsAroundPoint = brain.GetUnitsAroundPoint
        local GetLabel = NavUtils.GetLabel
        local ToCellFromWorldSpace = self.ToCellFromWorldSpace

        local TableGetn = TableGetn
        local cSTRUCTURE = categories.STRUCTURE
        local Random = Random

        ---@type AIGridPresenceCell[]
        local iterationA = { }

        ---@type AIGridPresenceCell[]
        local iterationB = { }

        while true do

            local start = GetSystemTimeSecondsOnlyForProfileUse()

            -- counting of extractors
            local massMarkers, extractorCount = MarkerUtilities.GetMarkersByType('Mass')
            for k = 1, extractorCount do
                local massMarker = massMarkers[k]
                local position = massMarker.position

                -- compute hostile / allied units
                local countHostile = TableGetn(GetUnitsAroundPoint(brain, cSTRUCTURE, position, 6, 'Enemy'))
                local countAllied = TableGetn(GetUnitsAroundPoint(brain, cSTRUCTURE, position, 6, 'Ally'))

                -- update status quo
                local label = GetLabel('Hover', position)
                if label and label > 0 then
                    local cell = ToCellFromWorldSpace(self, position[1], position[3])
                    cell.CountAllied[label] = cell.CountAllied[label] + countAllied
                    cell.CountHostile[label] = cell.CountHostile[label] + countHostile
                end
            end

            -- only show debugging information of the focus army
            if Debug and GetFocusArmy() == brain:GetArmyIndex() then
                DebugUpdateData.ResourcePointsTick = GetGameTick()
                DebugUpdateData.ResourcePointsTime = GetSystemTimeSecondsOnlyForProfileUse() - start
                Sync.GridPresenceUIDebugUpdate = DebugUpdateData
            end

            WaitTicks(1)

            start = GetSystemTimeSecondsOnlyForProfileUse()

            -- initial status quo and inferred values
            for k = 1, cellCount do
                for l = 1, cellCount do
                    local cell = cells[k][l]
                    local countAllied = cell.CountAllied
                    local countHostile = cell.CountHostile
                    for label, _ in cell.Labels do
                        -- we have not inferred anything yet
                        cell.Inferred[label] = 'Unoccupied'

                        -- compute initial status quo
                        local allied = countAllied[label]
                        local hostile = countHostile[label]
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

                        countAllied[label] = 0
                        countHostile[label] = 0
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
                        local j = math.floor(Random() * (k - 1) + 1);
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

                until headA <= 1
            end

            -- switch inferred to status quo to re-use memory
            for label, _ in self.Labels do
                for k = 1, cellCount do
                    for l = 1, cellCount do
                        local cell = cells[k][l]
                        cell.StatusQuo[label] = cell.Inferred[label]
                    end
                end
            end

            -- compute final values of inferred
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

            -- only show debugging information of the focus army
            if Debug and GetFocusArmy() == brain:GetArmyIndex() then
                DebugUpdateData.InferredTick = GetGameTick()
                DebugUpdateData.InferredTime = GetSystemTimeSecondsOnlyForProfileUse() - start
                Sync.GridPresenceUIDebugUpdate = DebugUpdateData
            end

            WaitTicks(29)
        end
    end,

    ---@param self AIGridPresence
    ---@param position Vector
    ---@return ('Allied' | 'Hostile' | 'Contested' | 'Unoccupied')?
    GetInferredStatus = function(self, position)
        local cell = self:ToCellFromWorldSpace(position[1], position[3])
        local label = NavUtils.GetLabel('Hover', position)
        if label then
            return cell.Inferred[label]
        end
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
        local cells = self.Cells
        local brain = self.Brain

        while true do

            -- only show debugging information of the focus army
            if Debug and GetFocusArmy() == brain:GetArmyIndex() then
                local mouse = GetMouseWorldPos()
                local cell = self:ToCellFromWorldSpace(mouse[1], mouse[3])

                local label = NavUtils.GetLabel('Hover', mouse)
                if label then
                    DebugCellData.Inferred = cell.Inferred[label]
                    DebugCellData.Label = label
                    Sync.GridPresenceUIDebugCell = DebugCellData

                    if cell.Inferred[label] == 'Allied' then
                        self:DrawCell(cell.X, cell.Z, math.log(label) + 0.075, '00ff00')
                        self:DrawCell(cell.X, cell.Z, math.log(label) - 0.075, '00ff00')
                    elseif cell.Inferred[label] == 'Hostile' then
                        self:DrawCell(cell.X, cell.Z, math.log(label) + 0.075, 'ff0000')
                        self:DrawCell(cell.X, cell.Z, math.log(label) - 0.075, 'ff0000')
                    elseif cell.Inferred[label] == 'Contested' then
                        self:DrawCell(cell.X, cell.Z, math.log(label) + 0.075, 'FFD900')
                        self:DrawCell(cell.X, cell.Z, math.log(label) - 0.075, 'FFD900')
                    else
                        self:DrawCell(cell.X, cell.Z, math.log(label) + 0.075, 'A0FFFFFF')
                        self:DrawCell(cell.X, cell.Z, math.log(label) - 0.075, 'A0FFFFFF')
                    end
                end

                -- draw the status of the cells
                for lx = -1, 1 do
                    for lz = -1, 1 do 
                        local alt = cells[cell.X + lx][cell.Z + lz]
                        if alt then
                            for label, _ in alt.Labels do

                                if alt.Inferred[label] == 'Allied' then
                                    self:DrawCell(alt.X, alt.Z, math.log(label), '00ff00')
                                elseif alt.Inferred[label] == 'Hostile' then
                                    self:DrawCell(alt.X, alt.Z, math.log(label), 'ff0000')
                                elseif alt.Inferred[label] == 'Contested' then
                                    self:DrawCell(alt.X, alt.Z, math.log(label), 'FFD900')
                                else
                                    self:DrawCell(alt.X, alt.Z, math.log(label), 'A0FFFFFF')
                                end
                            end


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

    -- requires the navigational mesh
    NavUtils.Generate()

    return GridPresence(brain)
end
