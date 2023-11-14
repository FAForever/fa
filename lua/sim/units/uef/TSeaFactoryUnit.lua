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

---@class TSeaFactoryUnit : SeaFactoryUnit
TSeaFactoryUnit = ClassUnit(SeaFactoryUnit) {
    ---@param self TSeaFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        WaitSeconds(0.1)
        for _, v in self.BuildEffectBones do
            self.BuildEffectsBag:Add(CreateAttachedEmitter(self, v, self.Army, '/effects/emitters/flashing_blue_glow_01_emit.bp'))
            self.BuildEffectsBag:Add(self:ForkThread(EffectUtil.CreateDefaultBuildBeams, unitBeingBuilt, {v}, self.BuildEffectsBag))
        end
    end,

    ---@param self TSeaFactoryUnit
    OnPaused = function(self)
        SeaFactoryUnit.OnPaused(self)
        self:StopArmsMoving()
    end,

    ---@param self TSeaFactoryUnit
    OnUnpaused = function(self)
        SeaFactoryUnit.OnUnpaused(self)
        if self:GetNumBuildOrders(categories.ALLUNITS) > 0 and not self:IsUnitState('Upgrading') then
            self:StartArmsMoving()
        end
    end,

    ---@param self TSeaFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        SeaFactoryUnit.OnStartBuild(self, unitBeingBuilt, order)
        if order  ~= 'Upgrade' then
            self:StartArmsMoving()
        end
    end,

    ---@param self TSeaFactoryUnit
    ---@param unitBuilding boolean
    OnStopBuild = function(self, unitBuilding)
        SeaFactoryUnit.OnStopBuild(self, unitBuilding)
        self:StopArmsMoving()
    end,

    ---@param self TSeaFactoryUnit
    OnFailedToBuild = function(self)
        SeaFactoryUnit.OnFailedToBuild(self)
        self:StopArmsMoving()
    end,

    ---@param self TSeaFactoryUnit
    StartArmsMoving = function(self)
        if not self.ArmsThread then
            self.ArmsThread = self:ForkThread(self.MovingArmsThread)
        end
    end,

    ---@param self TSeaFactoryUnit
    MovingArmsThread = function(self)
    end,

    ---@param self TSeaFactoryUnit
    StopArmsMoving = function(self)
        if self.ArmsThread then
            KillThread(self.ArmsThread)
            self.ArmsThread = nil
        end
    end,
}
