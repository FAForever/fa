
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

local Debug = false
function EnableDebugging()
    Debug = true
end

function DisableDebugging()
    Debug = false
end

---@type GridReconUIDebugCell
local DebugCellData = {
    LossOfRecon = -1,
    LossOfRadar = -1,
    LossOfSonar = -1,
    LossOfOmni = -1,
    LossOfLOSNow = -1,
}

local DebugUpdateData = {
    Time = -1
}

---@param a AIGridReconCell
---@param b AIGridReconCell
---@return boolean
local function SortLambda(a, b)
    return a.LossOfRecon > b.LossOfRecon
end

---@param a AIGridReconCell
---@param b AIGridReconCell
---@return boolean
local function SortRadarLambda(a, b)
    return a.LossOfReconType.Radar > b.LossOfReconType.Radar
end

---@param a AIGridReconCell
---@param b AIGridReconCell
---@return boolean
local function SortSonarLambda(a, b)
    return a.LossOfReconType.Sonar > b.LossOfReconType.Sonar
end

---@param a AIGridReconCell
---@param b AIGridReconCell
---@return boolean
local function SortOmniLambda(a, b)
    return a.LossOfReconType.Omni > b.LossOfReconType.Omni
end

---@param a AIGridReconCell
---@param b AIGridReconCell
---@return boolean
local function SortLOSNowLambda(a, b)
    return a.LossOfReconType.LOSNow > b.LossOfReconType.LOSNow
end

---@class AIGridReconCell : AIGridCell
---@field Grid AIGridRecon
---@field LossOfRecon number
---@field LossOfReconType { Radar: number, Sonar: number, Omni: number, LOSNow: number }

---@class AIGridRecon : AIGrid
---@field Brain moho.aibrain_methods
---@field Cells AIGridReconCell[][]
---@field ReconOrder AIGridReconCell[]
---@field ReconRadarOrder AIGridReconCell[]
---@field ReconSonarOrder AIGridReconCell[]
---@field ReconOmniOrder AIGridReconCell[]
---@field ReconLOSNowOrder AIGridReconCell[]
GridRecon = Class(Grid) {

    ---@param self AIGridRecon
    ---@param brain moho.aibrain_methods
    __init = function(self, brain)
        Grid.__init(self)

        self.Brain = brain

        local cellCount = self.CellCount
        local cells = self.Cells
        local reconOrder = {}
        local reconRadarOrder = {}
        local reconSonarOrder = {}
        local reconOmniOrder = {}
        local reconLOSNowOrder = {}

        for k = 1, cellCount do
            for l = 1, cellCount do
                local cell = cells[k][l]
                cell.LossOfRecon = 0
                cell.LossOfReconType = {
                    Radar = 0,
                    Sonar = 0,
                    Omni = 0,
                    LOSNow = 0,
                }

                TableInsert(reconOrder, cell)
                TableInsert(reconRadarOrder, cell)
                TableInsert(reconSonarOrder, cell)
                TableInsert(reconOmniOrder, cell)
                TableInsert(reconLOSNowOrder, cell)
            end
        end

        self.ReconOrder = reconOrder
        self.ReconRadarOrder = reconRadarOrder
        self.ReconSonarOrder = reconSonarOrder
        self.ReconOmniOrder = reconOmniOrder
        self.ReconLOSNowOrder = reconLOSNowOrder

        self:Update()
        self:DebugUpdate()
    end,

    --- Converts a world position to a cell
    ---@param self AIGrid
    ---@param wx number     # in world space
    ---@param wz number     # in world space
    ---@return AIGridReconCell
    ToCellFromWorldSpace = function(self, wx, wz)
        local gx, gz = self:ToGridSpace(wx, wz)
        return self.Cells[gx][gz]
    end,

    --- Converts a grid position to a cell
    ---@param self AIGridRecon
    ---@param gx number     # in grid space
    ---@param gz number     # in grid space
    ---@return AIGridReconCell
    ToCellFromGridSpace = function(self, gx, gz)
        return self.Cells[gx][gz]
    end,

    ---@param self AIGridRecon
    Update = function(self)
        ForkThread(
            self.UpdateThread,
            self
        )
    end,

    ---@param self AIGridRecon
    ---@param cell AIGridReconCell
    UpdateCell = function(self, cell)
        -- add decay
        cell.LossOfRecon = 0.96 * cell.LossOfRecon
        local lossOfReconType = cell.LossOfReconType
        lossOfReconType.Radar = 0.96 * lossOfReconType.Radar
        lossOfReconType.Sonar = 0.96 * lossOfReconType.Sonar
        lossOfReconType.Omni = 0.96 * lossOfReconType.Omni
        lossOfReconType.LOSNow = 0.96 * lossOfReconType.LOSNow
    end,

    ---@param self AIGridRecon
    UpdateCells = function(self, limit)
        local cellCount = self.CellCount
        local cells = self.Cells
        for k = 1, cellCount do
            for l = 1, cellCount do
                local cell = cells[k][l]
                self:UpdateCell(cell)
            end
        end

        -- sort the cells
        TableSort(self.ReconOrder, SortLambda)
        TableSort(self.ReconRadarOrder, SortRadarLambda)
        TableSort(self.ReconSonarOrder, SortSonarLambda)
        TableSort(self.ReconOmniOrder, SortOmniLambda)
        TableSort(self.ReconLOSNowOrder, SortLOSNowLambda)
    end,

    ---@param self AIGridRecon
    UpdateThread = function(self)
        while true do
            WaitTicks(11)

            local start
            if Debug then
                start = GetSystemTimeSecondsOnlyForProfileUse()
            end

            self:UpdateCells()

            if Debug then
                DebugUpdateData.Time = GetSystemTimeSecondsOnlyForProfileUse() - start
                Sync.GridReconUIDebugUpdate = DebugUpdateData
            end
        end
    end,

    ---@param self AIGridRecon
    ---@param wx number
    ---@param wz number
    ---@param reconType ReconTypes
    ---@param val boolean
    OnIntelChange = function(self, wx, wz, reconType, val)
        local cell = self:ToCellFromWorldSpace(wx, wz)

        if not val then
            cell.LossOfRecon = cell.LossOfRecon + 1
            local lossOfReconType = cell.LossOfReconType
            lossOfReconType[reconType] = lossOfReconType[reconType] + 1
        end
    end,

    ---------------------
    -- Debug functions --

    --- Contains various debug logic
    ---@param self AIGridRecon
    DebugUpdate = function(self)
        ForkThread(
            self.DebugUpdateThread,
            self
        )
    end,

    --- Allows us to scan the map
    ---@param self AIGridRecon
    DebugUpdateThread = function(self)
        while true do
            WaitTicks(1)

            if Debug and GetFocusArmy() == self.Brain:GetArmyIndex() then
                local mouse = GetMouseWorldPos()
                local bx, bz = self:ToGridSpace(mouse[1], mouse[3])
                local cell = self.Cells[bx][bz]

                DebugCellData.LossOfLOSNow = cell.LossOfReconType.LOSNow
                DebugCellData.LossOfOmni = cell.LossOfReconType.Omni
                DebugCellData.LossOfRadar = cell.LossOfReconType.Radar
                DebugCellData.LossOfRecon = cell.LossOfRecon
                DebugCellData.LossOfSonar = cell.LossOfReconType.Sonar
                Sync.GridReconUIDebugCell = DebugCellData

                self:DrawCell(bx, bz, 0, 'ffffff')

                -- draw loss of general recon
                local lossOfRecon = cell.LossOfRecon
                if lossOfRecon and lossOfRecon > 1 then
                    self:DrawCell(bx, bz, math.sqrt(lossOfRecon), '999999')
                end

                for k = 1, 8 do
                    local cell = self.ReconOrder[k]
                    if cell.LossOfRecon > 0 then
                        self:DrawCell(cell.X, cell.Z, math.sqrt(cell.LossOfRecon), '999999')
                    end
                end

                -- draw loss of recon type radar
                local lossOfReconRadar = cell.LossOfReconType.Radar
                if lossOfReconRadar and lossOfReconRadar > 1 then
                    self:DrawCell(bx, bz, math.sqrt(lossOfReconRadar), '156f79')
                end

                for k = 1, 8 do
                    local cell = self.ReconRadarOrder[k]
                    if cell.LossOfReconType.Radar > 0 then
                        self:DrawCell(cell.X, cell.Z, math.sqrt(cell.LossOfReconType.Radar), '156f79')
                    end
                end

                -- draw loss of recon type sonar
                local lossOfReconSonar = cell.LossOfReconType.Sonar
                if lossOfReconSonar and lossOfReconSonar > 1 then
                    self:DrawCell(bx, bz, math.sqrt(lossOfReconSonar), '3d7915')
                end

                for k = 1, 8 do
                    local cell = self.ReconSonarOrder[k]
                    if cell.LossOfReconType.Sonar > 0 then
                        self:DrawCell(cell.X, cell.Z, math.sqrt(cell.LossOfReconType.Sonar), '3d7915')
                    end
                end

                -- draw loss of recon type omni
                local lossOfReconOmni = cell.LossOfReconType.Omni
                if lossOfReconOmni and lossOfReconOmni > 1 then
                    self:DrawCell(bx, bz, math.sqrt(lossOfReconOmni), '801616')
                end

                for k = 1, 8 do
                    local cell = self.ReconOmniOrder[k]
                    if cell.LossOfReconType.Omni > 0 then
                        self:DrawCell(cell.X, cell.Z, math.sqrt(cell.LossOfReconType.Omni), '801616')
                    end
                end

                -- draw loss of recon type line of sight
                local lossOfReconLOSNow = cell.LossOfReconType.LOSNow
                if lossOfReconLOSNow and lossOfReconLOSNow > 1 then
                    self:DrawCell(bx, bz, math.sqrt(lossOfReconLOSNow), '000000')
                end

                for k = 1, 8 do
                    local cell = self.ReconLOSNowOrder[k]
                    if cell.LossOfReconType.LOSNow > 0 then
                        self:DrawCell(cell.X, cell.Z, math.sqrt(cell.LossOfReconType.LOSNow), '000000')
                    end
                end
            end
        end
    end,
}

---@return AIGridRecon
---@param brain moho.aibrain_methods
Setup = function(brain)
    return GridRecon(brain)
end
