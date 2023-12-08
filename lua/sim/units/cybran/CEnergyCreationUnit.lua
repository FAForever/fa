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

local EnergyCreationUnit = import('/lua/defaultunits.lua').EnergyCreationUnit
local EnergyCreationUnitOnStopBeingBuilt = EnergyCreationUnit.OnStopBeingBuilt

local EffectTemplate = import('/lua/effecttemplates.lua')

-- upvalue scope for performance
local CreateAttachedEmitter = CreateAttachedEmitter

---@class CEnergyCreationUnit : EnergyCreationUnit
CEnergyCreationUnit = ClassUnit(EnergyCreationUnit) {

    AmbientEffects = false,

    ---@param self CEnergyCreationUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        EnergyCreationUnitOnStopBeingBuilt(self, builder, layer)

        local army = self.Army
        local ambientEffects = self.AmbientEffects
        if ambientEffects then
            for k, v in EffectTemplate[ambientEffects] do
                CreateAttachedEmitter(self, 0, army, v)
            end
        end
    end,
}
