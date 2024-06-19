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
local SeaFactoryUnitOnCreate = SeaFactoryUnit.OnCreate
local SeaFactoryUnitOnPaused = SeaFactoryUnit.OnPaused
local SeaFactoryUnitOnUnpaused = SeaFactoryUnit.OnUnpaused
local SeaFactoryUnitOnStartBuild = SeaFactoryUnit.OnStartBuild
local SeaFactoryUnitOnStopBuild = SeaFactoryUnit.OnStopBuild
local SeaFactoryUnitOnFailedToBuild = SeaFactoryUnit.OnFailedToBuild

-- pre-import for performance
local CreateCybranFactoryBuildEffects = import('/lua/effectutilities.lua').CreateCybranFactoryBuildEffects

-- upvalue scope for performance
local WaitTicks = WaitTicks
local ForkThread = ForkThread
local IsDestroyed = IsDestroyed

local TrashBagAdd = TrashBag.Add

local CreateAnimator = CreateAnimator

local AnimatorPlayAnim = moho.AnimationManipulator.PlayAnim
local AnimatorSetRate = moho.AnimationManipulator.SetRate


---@class CSeaFactoryUnit : SeaFactoryUnit
---@field BuildEffectsBag TrashBag
CSeaFactoryUnit = ClassUnit(SeaFactoryUnit) {

    ---@param self CSeaFactoryUnit
    OnCreate = function(self)
        SeaFactoryUnitOnCreate(self)

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

    ---@param self CSeaFactoryUnit
    OnPaused = function(self)
        SeaFactoryUnitOnPaused(self)
        self:StopBuildFx()
        self:StopArmsMoving()
    end,

    ---@param self CSeaFactoryUnit
    OnUnpaused = function(self)
        SeaFactoryUnitOnUnpaused(self)

        -- re-introduce the build effects
        local unitBeingBuilt = self.UnitBeingBuilt --[[@as Unit]]
        if self:IsUnitState('Building') and (not IsDestroyed(unitBeingBuilt)) then
            self:StartBuildFx(unitBeingBuilt)
            self:StartArmsMoving()
        end
    end,

    ---@param self CAirFactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildFx = function(self, unitBeingBuilt)
        if not unitBeingBuilt then
            return
        end

        AnimatorSetRate(self.BuildAnimManip, 0.5)
    end,

    ---@param self CAirFactoryUnit
    StopBuildFx = function(self)
        AnimatorSetRate(self.BuildAnimManip, 0);
    end,

    ---@param self CSeaFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        SeaFactoryUnitOnStartBuild(self, unitBeingBuilt, order)
        if order ~= 'Upgrade' then
            self:StartArmsMoving()
        end
    end,

    ---@param self CSeaFactoryUnit
    ---@param unitBuilding Unit
    ---@param order string
    OnStopBuild = function(self, unitBuilding, order)
        SeaFactoryUnitOnStopBuild(self, unitBuilding, order)
        if not self.Dead and self:GetFractionComplete() == 1 then
            self:StopArmsMoving()
        end
    end,

    ---@param self CSeaFactoryUnit
    OnFailedToBuild = function(self)
        SeaFactoryUnitOnFailedToBuild(self)
        if not self.Dead and self:GetFractionComplete() == 1 then
            self:StopArmsMoving()
        end
    end,

    ---@param self CSeaFactoryUnit
    StartArmsMoving = function(self)
        self.ArmsThread = TrashBagAdd(self.Trash, ForkThread(self.MovingArmsThread, self))
    end,

    ---@param self CSeaFactoryUnit
    MovingArmsThread = function(self)
    end,

    ---@param self CSeaFactoryUnit
    StopArmsMoving = function(self)
        local armsThread = self.ArmsThread
        if armsThread then
            KillThread(armsThread)
            self.ArmsThread = nil
        end
    end,
}
