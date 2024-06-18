--******************************************************************************************************
--** Copyright (c) 2024 Willem 'Jip' Wijnia
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

---@class StatManagerBrainComponent
---@field UnitStats table<UnitId, table<string, number>>
StatManagerBrainComponent = ClassSimple {

    ---@param self StatManagerBrainComponent | AIBrain
    CreateBrainShared = function(self)
        self.UnitStats = {}
    end,

    ---@param self AIBrain
    ---@param unitId UnitId
    ---@param statName string
    ---@param value number
    AddUnitStat = function(self, unitId, statName, value)
        if self.UnitStats[unitId] == nil then
            self.UnitStats[unitId] = {}
        end

        if self.UnitStats[unitId][statName] == nil then
            self.UnitStats[unitId][statName] = value
        else
            self.UnitStats[unitId][statName] = self.UnitStats[unitId][statName] + value
        end
    end,

    ---@param self AIBrain
    ---@param unitId EntityId
    ---@param statName string
    ---@param value number
    SetUnitStat = function(self, unitId, statName, value)
        if self.UnitStats[unitId] == nil then
            self.UnitStats[unitId] = {}
        end

        self.UnitStats[unitId][statName] = value
    end,

    ---@param self AIBrain
    ---@param unitId EntityId
    ---@param statName string
    ---@return number
    GetUnitStat = function(self, unitId, statName)
        if self.UnitStats[unitId] == nil or self.UnitStats[unitId][statName] == nil then
            return 0
        end

        return self.UnitStats[unitId][statName]
    end,

    ---@param self AIBrain
    GetUnitStats = function(self)
        return self.UnitStats
    end,
}
