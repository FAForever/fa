
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

local TableInsert = table.insert
local TableSort = table.sort

local WeakValue = { __mode = 'v' }

local Debug = false
function EnableDebugging()
    Debug = true
end

function DisableDebugging()
    Debug = false
end

---@type GridReclaimUIDebugCell
local DebugCellData = {
    ReclaimCount = -1,
    TotalEnergy = -1,
    TotalMass = -1,
    X = -1,
    Z = -1,
}

---@type GridReclaimUIDebugUpdate
local DebugUpdateData = {
    Processed = -1,
    Time = -1,
    Updates = -1,
}

---@param a AIGridReclaimCell
---@param b AIGridReclaimCell
---@return boolean
local function SortLambda (a, b)
    return a.TotalMass > b.TotalMass
end

---@class AIGridReclaimCell : AIGridCell
---@field Grid AIGridReclaim
---@field TotalMass number
---@field TotalEnergy number
---@field ReclaimCount number
---@field Reclaim table<EntityId, Prop>

---@class AIGridReclaim : AIGrid
---@field Cells AIGridReclaimCell[][]
---@field UpdateList table<string, AIGridReclaimCell>
---@field OrderedCells AIGridReclaimCell[]
---@field Brains table<number, AIBrain>
GridReclaim = Class(Grid) {

    ---@param self AIGridReclaim
    __init = function(self)
        Grid.__init(self)

        local cellCount = self.CellCount
        local cells = self.Cells
        local orderedCells = {}

        for k = 1, cellCount do
            for l = 1, cellCount do
                local cell = cells[k][l]
                cell.TotalMass = 0
                cell.TotalEnergy = 0
                cell.ReclaimCount = 0
                cell.Reclaim = setmetatable({}, WeakValue)

                TableInsert(orderedCells, cell)
            end
        end

        self.OrderedCells = orderedCells
        self.UpdateList = {}
        self.Brains = {}

        self:Update()
        self:DebugUpdate()
    end,

    --- Converts a world position to a cell
    ---@param self AIGrid
    ---@param wx number     # in world space
    ---@param wz number     # in world space
    ---@return AIGridReclaimCell
    ToCellFromWorldSpace = function(self, wx, wz)
        local gx, gz = self:ToGridSpace(wx, wz)
        return self.Cells[gx][gz]
    end,

    --- Converts a grid position to a cell
    ---@param self AIGridReclaim
    ---@param gx number     # in grid space
    ---@param gz number     # in grid space
    ---@return AIGridReclaimCell
    ToCellFromGridSpace = function(self, gx, gz)
        return self.Cells[gx][gz]
    end,

    ---@param self AIGridReclaim
    Update = function(self)
        ForkThread(
            self.UpdateThread,
            self
        )
    end,

    ---@param self AIGridReclaim
    ---@param cell AIGridReclaimCell
    UpdateCell = function(self, cell)
        local count = 0
        local totalMass = 0
        local totalEnergy = 0

        for id, reclaim in cell.Reclaim do
            count = count + 1
            local fraction = reclaim.ReclaimLeft or 0
            totalMass = totalMass + fraction * (reclaim.MaxMassReclaim or 0)
            totalEnergy = totalEnergy + fraction * (reclaim.MaxEnergyReclaim or 0)
        end

        cell.TotalMass = totalMass
        cell.TotalEnergy = totalEnergy
        cell.ReclaimCount = count

        if Debug then
            DebugUpdateData.Processed = DebugUpdateData.Processed + cell.ReclaimCount
            DebugUpdateData.Updates = DebugUpdateData.Updates + 1
            self:DebugCellUpdate(cell.X, cell.Z)
        end
    end,

    ---@param self AIGridReclaim
    UpdateCells = function(self, limit)
        local updates = 0
        for id, cell in self.UpdateList do
            -- only update up to 8 cells
            updates = updates + 1
            if updates > limit then
                break
            end

            self.UpdateList[id] = nil
            self:UpdateCell(cell)

            -- inform ai brains of changes
            for k, brain in self.Brains do
                if brain.OnReclaimUpdate then
                    brain:OnReclaimUpdate(self, cell)
                end
            end
        end

        -- sort the cells
        if updates > 0 then
            TableSort(self.OrderedCells, SortLambda)
        end
    end,

    ---@param self AIGridReclaim
    UpdateThread = function(self)
        while true do
            WaitTicks(6)

            local start
            if Debug then
                start = GetSystemTimeSecondsOnlyForProfileUse()

                -- reset accumulative fields
                DebugUpdateData.Processed = 0
                DebugUpdateData.Updates = 0
            end

            self:UpdateCells(8)

            if Debug then
                -- DebugUpdateData.Memory = import("/lua/system/utils.lua").ToBytes(self, { Reclaim = true }) / (1024 * 1024)
                DebugUpdateData.Time = GetSystemTimeSecondsOnlyForProfileUse() - start
                Sync.GridReclaimUIDebugUpdate = DebugUpdateData
            end
        end
    end,

    ---@param self AIGridReclaim   
    ---@param bx number             # in grid space
    ---@param bz number             # in grid space
    ---@param radius number         # in grid space
    ---@return AIGridReclaimCell    # most valuable cell in radius
    MaximumInRadius = function(self, bx, bz, radius)
        -- negative radius or a radius of 0
        local cells = self.Cells
        if radius <= 0 then
            return cells[bx][bz]
        end

        local candidate = nil
        local value = 0

        -- non-negative radius, search for most valuable cell
        for lx = -radius, radius do
            local column = cells[bx + lx]
            if column then
                for lz = -radius, radius do
                    local cell = column[bz + lz]
                    if cell then
                        -- any candidate is a good candidate
                        if not candidate then
                            candidate = cell
                            value = cell.TotalMass
                        -- compare if the cell we're evaluating is better
                        else
                            local alt = cell.TotalMass
                            if alt > value then
                                candidate = cell
                                value = alt
                            end
                        end
                    end
                end
            end
        end

        return candidate
    end,

    ---@param self AIGridReclaim   
    ---@param bx number                 # in grid space
    ---@param bz number                 # in grid space
    ---@param radius number             # in grid space
    ---@param threshold number          # 
    ---@param cache? table              # optional value, allows you to re-use memory in hot spots
    ---@return AIGridReclaimCell[]      # all cells that meet the threhsold
    ---@return number                   # number of cells found
    FilterInRadius = function(self, bx, bz, radius, threshold, cache)
        local candidates = cache or { }
        local head = 1
        local cells = self.Cells
        for lx = -radius, radius do
            local column = cells[bx + lx]
            if column then
                for lz = -radius, radius do
                    local cell = column[bz + lz]
                    if cell then
                        if cell.TotalMass >= threshold then
                            candidates[head] = cell
                            head = head + 1
                        end
                    end
                end
            end
        end

        return candidates, head - 1
    end,

    ---@param self AIGridReclaim   
    ---@param bx number                 # in grid space
    ---@param bz number                 # in grid space
    ---@param radius number             # in grid space
    ---@param threshold number          # 
    ---@param cache? table               # optional value, allows you to re-use memory in hot spots
    ---@return AIGridReclaimCell[]      # all cells that meet the threhsold
    ---@return number                   # number of cells found
    FilterAndSortInRadius = function(self, bx, bz, radius, threshold, cache)
        local filtered, count = self:FilterInRadius(bx, bz, radius, threshold, cache)
        TableSort(filtered, SortLambda)
        return filtered, count
    end,

    -------------------------------
    -- Reclaim related functions --

    --- Called by a prop as it is destroyed
    ---@param self AIGridReclaim
    ---@param prop Prop
    OnReclaimDestroyed = function(self, prop)
        local position = prop.CachePosition or prop:GetPosition()
        local bx, bz = self:ToGridSpace(position[1], position[3])

        local cell = self.Cells[bx][bz]
        cell.Reclaim[prop.EntityId] = nil

        self.UpdateList[cell.Identifier] = cell

        self:DebugPropDestroyed(prop)
    end,

    --- Called by a prop as the reclaim value is adjusted
    ---@param self AIGridReclaim
    ---@param prop Prop
    OnReclaimUpdate = function(self, prop)
        local position = prop.CachePosition or prop:GetPosition()
        local bx, bz = self:ToGridSpace(position[1], position[3])

        local cell = self.Cells[bx][bz]
        cell.Reclaim[prop.EntityId] = prop

        self.UpdateList[cell.Identifier] = cell

        self:DebugPropUpdated(prop)
    end,

    -------------------------------
    -- AIBrain related functions --

    --- Called by a brain to initialize logic that runs for just that brain
    ---@param self AIGridReclaim
    ---@param brain AIBrain
    RegisterBrain = function(self, brain)
        self.Brains[brain:GetArmyIndex()] = brain
    end,

    ---------------------
    -- Debug functions --

    --- Contains various debug logic
    ---@param self AIGridReclaim
    DebugUpdate = function(self)
        ForkThread(
            self.DebugUpdateThread,
            self
        )
    end,

    --- Allows us to scan the map
    ---@param self AIGridReclaim
    DebugUpdateThread = function(self)

        local ColorRGB = import("/lua/shared/color.lua").ColorRGB

        while true do
            WaitTicks(1)

            -- mouse scanning
            if Debug then
                local mouse = GetMouseWorldPos()
                local bx, bz = self:ToGridSpace(mouse[1], mouse[3])
                local cell = self.Cells[bx][bz]

                local totalMass = cell.TotalMass
                if totalMass and totalMass > 0 then
                    self:DrawCell(bx, bz, math.log(totalMass) - 1, '00610B')
                end

                local totalEnergy = cell.TotalEnergy
                if totalEnergy and totalEnergy > 0 then
                    self:DrawCell(bx, bz, math.log(totalEnergy) - 1, 'B4C400')
                end

                self:DrawCell(bx, bz, 0, 'ffffff')

                DrawCircle(self:ToWorldSpace(bx, bz), 4, '000000')

                DebugCellData.ReclaimCount = cell.ReclaimCount
                DebugCellData.TotalEnergy = cell.TotalEnergy
                DebugCellData.TotalMass = cell.TotalMass
                DebugCellData.X = cell.X
                DebugCellData.Z = cell.Z
                Sync.GridReclaimUIDebugCell = DebugCellData

                -- draw most valuable cells
                for k = 1, 8 do 
                    local cell = self.OrderedCells[k]
                    self:DrawCell(cell.X, cell.Z, 0, 'ff0000')
                end

                -- draw most valuable cell in range
                local maximum = self:MaximumInRadius(bx, bz, 1)
                self:DrawCell(maximum.X, maximum.Z, 1, '0000ff')

                -- draw filtered and sorted cells
                local filtered, count = self:FilterAndSortInRadius(bx, bz, 1, 500)
                for k, cell in filtered do
                    local factor = 1 - ((k - 1) / count)
                    local color = ColorRGB(factor, factor, factor)
                    self:DrawCell(cell.X, cell.Z, 2, color)
                    self:DrawCell(cell.X, cell.Z, 2.5, color)
                end
            end
        end
    end,

    --- Debugging logic when a cell is updated
    ---@param self AIGridReclaim
    ---@param bx number
    ---@param bz number
    DebugCellUpdate = function(self, bx, bz)
        if Debug then
            self:DrawCell(bx, bz, 1, '48FF00')
        end
    end,

    --- Debugging logic when a prop is destroyed
    ---@param self AIGridReclaim
    ---@param prop Prop
    DebugPropDestroyed = function(self, prop)
        if Debug then
            DrawCircle(prop.CachePosition, 2, 'ff0000')
        end
    end,

    --- Debugging logic when a prop is updated
    ---@param self AIGridReclaim
    ---@param prop Prop
    DebugPropUpdated = function(self, prop)
        if Debug then
            DrawCircle(prop.CachePosition, 2, '0000ff')
        end
    end,
}

---@type AIGridReclaim
GridReclaimInstance = false

---@param brain AIBrain
---@return AIGridReclaim
Setup = function(brain)
    if not GridReclaimInstance then
        GridReclaimInstance = GridReclaim() --[[@as AIGridReclaim]]
    end

    if brain then
        GridReclaimInstance:RegisterBrain(brain)
    end

    return GridReclaimInstance
end
