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
local SeaFactoryUnitOnPaused = SeaFactoryUnit.OnPaused
local SeaFactoryUnitOnUnpaused = SeaFactoryUnit.OnUnpaused
local SeaFactoryUnitOnStartBuild = SeaFactoryUnit.OnStartBuild
local SeaFactoryUnitOnStopBuild = SeaFactoryUnit.OnStopBuild
local SeaFactoryUnitOnFailedToBuild = SeaFactoryUnit.OnFailedToBuild

-- pre-import for performance
local CreateDefaultBuildBeams = import('/lua/effectutilities.lua').CreateDefaultBuildBeams

-- upvalue scope for performance
local WaitTicks = WaitTicks
local ForkThread = ForkThread
local CreateAttachedEmitter = CreateAttachedEmitter

-- precomputed categories for performance
local CategoriesALLUNITS = categories.ALLUNITS

---@class TSeaFactoryUnit : SeaFactoryUnit
TSeaFactoryUnit = ClassUnit(SeaFactoryUnit) {

    ---@param self TSeaFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        WaitTicks(1)

        local army = self.Army
        local buildEffectsBag = self.BuildEffectsBag
        local buildEffectBones = self.BuildEffectBones

        -- create the beams and move the beams around
        buildEffectsBag:Add(ForkThread(CreateDefaultBuildBeams, self, unitBeingBuilt, buildEffectBones, buildEffectsBag))

        -- create a sparkle-like effect at the muzzles
        for _, v in buildEffectBones do
            buildEffectsBag:Add(CreateAttachedEmitter(self, v, army, '/effects/emitters/flashing_blue_glow_01_emit.bp'))
        end
    end,

    ---@param self TSeaFactoryUnit
    OnPaused = function(self)
        SeaFactoryUnitOnPaused(self)
        self:StopArmsMoving()
    end,

    ---@param self TSeaFactoryUnit
    OnUnpaused = function(self)
        SeaFactoryUnitOnUnpaused(self)
        if self:GetNumBuildOrders(CategoriesALLUNITS) > 0 and not self:IsUnitState('Upgrading') then
            self:StartArmsMoving()
        end
    end,

    ---@param self TSeaFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        SeaFactoryUnitOnStartBuild(self, unitBeingBuilt, order)
        if order ~= 'Upgrade' then
            self:StartArmsMoving()
        end
    end,

    ---@param self TSeaFactoryUnit
    ---@param unitBuilding Unit
    OnStopBuild = function(self, unitBuilding)
        SeaFactoryUnitOnStopBuild(self, unitBuilding)
        self:StopArmsMoving()
    end,

    ---@param self TSeaFactoryUnit
    OnFailedToBuild = function(self)
        SeaFactoryUnitOnFailedToBuild(self)
        self:StopArmsMoving()
    end,

    ---@param self TSeaFactoryUnit
    StartArmsMoving = function(self)
        if not self.ArmsThread then
            self.ArmsThread = self.Trash:Add(ForkThread(self.MovingArmsThread, self))
        end
    end,

    ---@param self TSeaFactoryUnit
    MovingArmsThread = function(self)
    end,

    ---@param self TSeaFactoryUnit
    StopArmsMoving = function(self)
        local armsThread = self.ArmsThread
        if armsThread then
            KillThread(armsThread)
            self.ArmsThread = nil
        end
    end,
}
