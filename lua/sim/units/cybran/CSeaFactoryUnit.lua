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

local SeaFactoryUnit = import('/lua/defaultunits.lua').SeaFactoryUnit
local EffectUtil = import('/lua/effectutilities.lua')
local StructureUnit = import('/lua/defaultunits.lua').StructureUnit

-- SEA FACTORY STRUCTURES
---@class CSeaFactoryUnit : SeaFactoryUnit
---@field BuildEffectsBag TrashBag
CSeaFactoryUnit = ClassUnit(SeaFactoryUnit) {

    ---@param self CSeaFactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildingEffects = function(self, unitBeingBuilt)
        local thread = self:ForkThread(EffectUtil.CreateCybranBuildBeamsOpti, nil, unitBeingBuilt, self.BuildEffectsBag, false)
        unitBeingBuilt.Trash:Add(thread)
    end,

    ---@param self CSeaFactoryUnit
    OnPaused = function(self)
        StructureUnit.OnPaused(self)
        if not self.Dead and self:GetFractionComplete() == 1 then
            self:StopUnitAmbientSound('ConstructLoop')
            StructureUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
            self:StopArmsMoving()
        end
    end,

    ---@param self CSeaFactoryUnit
    OnUnpaused = function(self)
        StructureUnit.OnUnpaused(self)
        if self:GetNumBuildOrders(categories.ALLUNITS) > 0 and not self:IsUnitState('Upgrading') and self:IsUnitState('Building') then
            self:PlayUnitAmbientSound('ConstructLoop')
            self:StartBuildingEffects(self.UnitBeingBuilt)
            self:StartArmsMoving()
        end
    end,

    ---@param self CSeaFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order boolean|string
    OnStartBuild = function(self, unitBeingBuilt, order)
        SeaFactoryUnit.OnStartBuild(self, unitBeingBuilt, order)
        if order ~= 'Upgrade' then
            self:StartArmsMoving()
        end
    end,

    ---@param self CSeaFactoryUnit
    ---@param unitBuilding Unit
    OnStopBuild = function(self, unitBuilding)
        SeaFactoryUnit.OnStopBuild(self, unitBuilding)
        if not self.Dead and self:GetFractionComplete() == 1 then
            self:StopArmsMoving()
        end
    end,

    ---@param self CSeaFactoryUnit
    OnFailedToBuild = function(self)
        SeaFactoryUnit.OnFailedToBuild(self)
        if not self.Dead and self:GetFractionComplete() == 1 then
            self:StopArmsMoving()
        end
    end,

    ---@param self CSeaFactoryUnit
    StartArmsMoving = function(self)
        self.ArmsThread = self:ForkThread(self.MovingArmsThread)
    end,

    ---@param self CSeaFactoryUnit
    MovingArmsThread = function(self)
    end,

    ---@param self CSeaFactoryUnit
    StopArmsMoving = function(self)
        if self.ArmsThread then
            KillThread(self.ArmsThread)
            self.ArmsThread = nil
        end
    end,
}