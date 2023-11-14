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
local StructureUnit = import('/lua/defaultunits.lua').StructureUnit

local CreateSeraphimFactoryBuildingEffects = import('/lua/EffectUtilities.lua').CreateSeraphimFactoryBuildingEffects

-- FACTORIES
---@class SFactoryUnit : FactoryUnit
SFactoryUnit = ClassUnit(FactoryUnit) {
    StartBuildFx = function(self, unitBeingBuilt)
        local BuildBones = self.BuildEffectBones
        local thread = self:ForkThread(CreateSeraphimFactoryBuildingEffects, unitBeingBuilt, BuildBones, 'Attachpoint', self.BuildEffectsBag)
        self.BuildEffectsBag:Add(thread)
    end,

    StartBuildFxUnpause = function(self, unitBeingBuilt)
        local BuildBones = self.BuildEffectBones
        local thread = self:ForkThread(CreateSeraphimFactoryBuildingEffects, unitBeingBuilt, BuildBones, 'Attachpoint', self.BuildEffectsBag)
        self.BuildEffectsBag:Add(thread)
    end,

    OnPaused = function(self)
        StructureUnit.OnPaused(self)
        -- When factory is paused take some action
        if self:IsUnitState('Building') and self.UnitBeingBuilt then
            self:StopUnitAmbientSound('ConstructLoop')
            self:StopBuildingEffects(self, self.UnitBeingBuilt)
        end
    end,

    OnUnpaused = function(self)
        FactoryUnit.OnUnpaused(self)
        if self:IsUnitState('Building') and self.UnitBeingBuilt then
            self:StartBuildFxUnpause(self:GetFocusUnit())
        end
    end,
}