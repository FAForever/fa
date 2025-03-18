--**********************************************************************************
--** Copyright (c) 2023 FAForever
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
--**********************************************************************************

local StructureUnit = import("/lua/sim/units/structureunit.lua").StructureUnit
local StructureUnitOnStopBeingBuilt = StructureUnit.OnStopBeingBuilt

---@class EnergyStorageUnit : StructureUnit
EnergyStorageUnit = ClassUnit(StructureUnit) {

    ---@param self EnergyStorageUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnitOnStopBeingBuilt(self, builder, layer)

        local brain = self.Brain
        brain:RegisterUnitEnergyStorage(self)
        self:OnEnergyStorageStateChange(brain.EnergyStorageState)
    end,

    --- Implemented at the unit (type) level
    ---@param self BlinkingLightsUnitComponent | StructureUnit
    ---@param state AIBrainEnergyStorageState
    OnEnergyStorageStateChange = function(self, state)
        if state == 'EconLowEnergyStore' then
            self:CreateBlinkingLights('Red')
        elseif state == 'EconMidEnergyStore' then
            self:CreateBlinkingLights('Yellow')
        elseif state == 'EconFullEnergyStore' then
            self:CreateBlinkingLights('Green')
        end
    end,

}
