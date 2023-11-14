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

local FactoryUnit = import('/lua/defaultunits.lua').FactoryUnit
local CreateAeonFactoryBuildingEffects = import('/lua/effectutilities.lua').CreateAeonFactoryBuildingEffects

--- FACTORIES
---@class AFactoryUnit : FactoryUnit
---@field BuildEffectsBag TrashBag
AFactoryUnit = ClassUnit(FactoryUnit) {

    ---@param self AFactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildFx = function(self, unitBeingBuilt)
        local thread = self:ForkThread(CreateAeonFactoryBuildingEffects, unitBeingBuilt, self.BuildEffectBones, 'Attachpoint', self.BuildEffectsBag)
        unitBeingBuilt.Trash:Add(thread)
    end,

    ---@param self AFactoryUnit
    OnPaused = function(self)
        FactoryUnit.OnPaused(self)

        -- stop the building fx
        local unitBeingBuilt = self.UnitBeingBuilt
        if unitBeingBuilt and self:IsUnitState('Building') and (not IsDestroyed(unitBeingBuilt)) then
            FactoryUnit.StopBuildingEffects(self, unitBeingBuilt)
            self:StopUnitAmbientSound('ConstructLoop')
        end
    end,

    ---@param self AFactoryUnit
    OnUnpaused = function(self)
        FactoryUnit.OnUnpaused(self)

        -- start the building fx
        local unitBeingBuilt = self.UnitBeingBuilt
        if unitBeingBuilt and self:IsUnitState('Building') and (not IsDestroyed(unitBeingBuilt)) then
            FactoryUnit.StopBuildingEffects(self, unitBeingBuilt)
            self:StartBuildFx(self:GetFocusUnit())
        end
    end,
}
