
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

local WeakValue = { __mode = 'v' }

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
---@field AssignedScouts { LAND: table<EntityId, Unit>, AIR: table<EntityId, Unit> } 
---@field LastScouted number
---@field ScoutPriority number
---@field MustScout boolean
---@field IntelCoverage boolean

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
                cell.EngineersReclaiming = setmetatable({}, WeakValue)
                cell.AssignedScouts =  {
                    OTHER = setmetatable({}, WeakValue),
                    AIR = setmetatable({}, WeakValue),
                }

                cell.AssignedAirScouts = setmetatable({}, WeakValue)
                cell.LastScouted = 0
                cell.ScoutPriority = 0
                cell.MustScout = false
                cell.IntelCoverage = false
            end
        end

        --self:Update()
        --self:DebugUpdate()
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

    --- Registers a scout in a given cell
    ---@param self AIGridBrain
    ---@param scout Unit
    AddAssignedScout = function(self, scout)
        -- determine cell
        local px, _, pz = scout:GetPositionXYZ()
        local cell = self:ToCellFromWorldSpace(px, pz)

        -- determine layer
        local layer = scout.Blueprint.LayerCategory
        if layer != 'AIR' then
            layer = 'LAND'
        end

        cell.AssignedScouts[layer][scout.EntityId] = scout
    end,

    --- Unregisters a scout in a given cell
    ---@param self AIGridBrain
    ---@param scout Unit
    RemoveAssignedScout = function(self, scout)
        -- determine cell
        local px, _, pz = scout:GetPositionXYZ()
        local cell = self:ToCellFromWorldSpace(px, pz)

        -- determine layer
        local layer = scout.Blueprint.LayerCategory
        if layer != 'AIR' then
            layer = 'LAND'
        end

        cell.AssignedScouts[layer][scout.EntityId] = nil
    end,

    --- Counts the number of scouts assigned to a cell
    ---@param self AIGridBrain
    ---@param layer 'LAND' | 'AIR'
    ---@return number | nil
    CountAssignedScouts = function(self, position, layer)
        if not (layer == 'LAND' or layer == 'AIR') then 
            WARN('GridBrain: unable to get scout count, invalid layer')
            return
        end

        -- determine cell
        local cell = self:ToCellFromWorldSpace(position[1], position[3])

        return table.getsize(cell.AssignedScouts[layer])
    end,
}

---@return AIGridBrain
Setup = function()
    return GridBrain()
end
