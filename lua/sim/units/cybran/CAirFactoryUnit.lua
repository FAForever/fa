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

local AirFactoryUnit = import('/lua/defaultunits.lua').AirFactoryUnit
local EffectUtil = import('/lua/effectutilities.lua')

-- AIR FACTORY STRUCTURES
---@class CAirFactoryUnit : AirFactoryUnit
---@field BuildEffectsBag TrashBag
---@field BuildAnimManip moho.AnimationManipulator
CAirFactoryUnit = ClassUnit(AirFactoryUnit) {

    ---@param self CAirFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string unused
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        if not unitBeingBuilt then return end
        WaitTicks(2)
        EffectUtil.CreateCybranFactoryBuildEffects(self, unitBeingBuilt, self:GetBlueprint().General.BuildBones, self.BuildEffectsBag)
    end,

    ---@param self CAirFactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildFx = function(self, unitBeingBuilt)
        if not unitBeingBuilt then return end

        -- Start build process
        if not self.BuildAnimManip then
            self.BuildAnimManip = CreateAnimator(self)
            self.BuildAnimManip:PlayAnim(self:GetBlueprint().Display.AnimationBuild, true):SetRate(0)
            self.Trash:Add(self.BuildAnimManip)
        end
        self.BuildAnimManip:SetRate(1)
    end,

    ---@param self CAirFactoryUnit
    StopBuildFx = function(self)
        if self.BuildAnimManip then
            self.BuildAnimManip:SetRate(0)
        end
    end,

    ---@param self CAirFactoryUnit
    OnPaused = function(self)
        AirFactoryUnit.OnPaused(self)
        self:StopBuildFx()
    end,

    ---@param self CAirFactoryUnit
    OnUnpaused = function(self)
        AirFactoryUnit.OnUnpaused(self)
        if self:IsUnitState('Building') then
            self:StartBuildFx(self:GetFocusUnit())
        end
    end,
}