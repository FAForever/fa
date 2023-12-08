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
local AirFactoryUnitOnCreate = AirFactoryUnit.OnCreate
local AirFactoryUnitOnPaused = AirFactoryUnit.OnPaused
local AirFactoryUnitOnUnpaused = AirFactoryUnit.OnUnpaused

-- pre-import for performance
local CreateCybranFactoryBuildEffects = import('/lua/effectutilities.lua').CreateCybranFactoryBuildEffects

-- upvalue scope for performance
local WaitTicks = WaitTicks
local CreateAnimator = CreateAnimator

local AnimatorPlayAnim = moho.AnimationManipulator.PlayAnim
local AnimatorSetRate = moho.AnimationManipulator.SetRate

---@class CAirFactoryUnit : AirFactoryUnit
---@field BuildEffectsBag TrashBag
---@field BuildAnimManip moho.AnimationManipulator
CAirFactoryUnit = ClassUnit(AirFactoryUnit) {

    ---@param self AirFactoryUnit
    OnCreate = function(self)
        AirFactoryUnitOnCreate(self)

        local buildAnimManip = CreateAnimator(self)
        AnimatorPlayAnim(buildAnimManip, self.Blueprint.Display.AnimationBuild, true)
        AnimatorSetRate(buildAnimManip, 0)
        self.BuildAnimManip = self.Trash:Add(buildAnimManip)
    end,

    ---@param self CAirFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string unused
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        if not unitBeingBuilt then
            return
        end

        WaitTicks(2)
        CreateCybranFactoryBuildEffects(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
    end,

    ---@param self CAirFactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildFx = function(self, unitBeingBuilt)
        if not unitBeingBuilt then
            return
        end

        AnimatorSetRate(self.BuildAnimManip, 1)
    end,

    ---@param self CAirFactoryUnit
    StopBuildFx = function(self)
        AnimatorSetRate(self.BuildAnimManip, 0);
    end,

    ---@param self CAirFactoryUnit
    OnPaused = function(self)
        AirFactoryUnitOnPaused(self)
        self:StopBuildFx()
    end,

    ---@param self CAirFactoryUnit
    OnUnpaused = function(self)
        AirFactoryUnitOnUnpaused(self)
        if self:IsUnitState('Building') then
            self:StartBuildFx(self:GetFocusUnit())
        end
    end,
}
