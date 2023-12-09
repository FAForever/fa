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

local LandFactoryUnit = import('/lua/defaultunits.lua').LandFactoryUnit
local LandFactoryUnitOnCreate = LandFactoryUnit.OnCreate
local LandFactoryUnitOnPaused = LandFactoryUnit.OnPaused
local LandFactoryUnitOnUnpaused = LandFactoryUnit.OnUnpaused

-- pre-import for performance
local CreateCybranFactoryBuildEffects = import('/lua/effectutilities.lua').CreateCybranFactoryBuildEffects

-- upvalue scope for performance
local WaitTicks = WaitTicks
local CreateAnimator = CreateAnimator

local AnimatorPlayAnim = moho.AnimationManipulator.PlayAnim
local AnimatorSetRate = moho.AnimationManipulator.SetRate

---@class CLandFactoryUnit : LandFactoryUnit
---@field BuildEffectsBag TrashBag
---@field BuildAnimManip moho.AnimationManipulator
CLandFactoryUnit = ClassUnit(LandFactoryUnit) {

    ---@param self AirFactoryUnit
    OnCreate = function(self)
        LandFactoryUnitOnCreate(self)

        local buildAnimManip = CreateAnimator(self)
        AnimatorPlayAnim(buildAnimManip, self.Blueprint.Display.AnimationBuild, true)
        AnimatorSetRate(buildAnimManip, 0)
        self.BuildAnimManip = self.Trash:Add(buildAnimManip)
    end,

    ---@param self CLandFactoryUnit
    ---@param unitBeingBuilt Unit
    CreateBuildEffects = function(self, unitBeingBuilt)
        if not unitBeingBuilt then
            return
        end

        WaitTicks(2)
        CreateCybranFactoryBuildEffects(self, unitBeingBuilt, self.Blueprint.General.BuildBones, self.BuildEffectsBag)
    end,

    ---@param self CLandFactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildFx = function(self, unitBeingBuilt)
        if not unitBeingBuilt then
            return
        end

        AnimatorSetRate(self.BuildAnimManip, 1)
    end,

    ---@param self CLandFactoryUnit
    StopBuildFx = function(self)
        AnimatorSetRate(self.BuildAnimManip, 0);
    end,

    ---@param self CLandFactoryUnit
    OnPaused = function(self)
        LandFactoryUnitOnPaused(self)
        self:StopBuildFx()
    end,

    ---@param self CLandFactoryUnit
    OnUnpaused = function(self)
        LandFactoryUnitOnUnpaused(self)

        local unitBeingBuilt = self.UnitBeingBuilt
        if unitBeingBuilt and self:IsUnitState('Building') then
            self:StartBuildFx(unitBeingBuilt)
        end
    end,
}
