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

local CreateDefaultBuildBeams = import('/lua/EffectUtilities.lua').CreateDefaultBuildBeams

local AirFactoryUnit = import('/lua/defaultunits.lua').AirFactoryUnit
local AirFactoryUnitOnPaused = AirFactoryUnit.OnPaused
local AirFactoryUnitOnUnpaused = AirFactoryUnit.OnUnpaused
local AirFactoryUnitOnStartBuild = AirFactoryUnit.OnStartBuild
local AirFactoryUnitOnStopBuild = AirFactoryUnit.OnStopBuild
local AirFactoryUnitOnFailedToBuild = AirFactoryUnit.OnFailedToBuild

-- upvalue scope for performance
local WaitTicks = WaitTicks
local ForkThread = ForkThread
local CreateAttachedEmitter = CreateAttachedEmitter

-- precomputed categories for performance
local CategoriesALLUNITS = categories.ALLUNITS

---@class TAirFactoryUnit : AirFactoryUnit
TAirFactoryUnit = ClassUnit(AirFactoryUnit) {

    ---@param self TAirFactoryUnit
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

    ---@param self TAirFactoryUnit
    OnPaused = function(self)
        AirFactoryUnitOnPaused(self)
        self:StopArmsMoving()
    end,

    ---@param self TAirFactoryUnit
    OnUnpaused = function(self)
        AirFactoryUnitOnUnpaused(self)
        if self:GetNumBuildOrders(CategoriesALLUNITS) > 0 and not self:IsUnitState('Upgrading') then
            self:StartArmsMoving()
        end
    end,

    ---@param self TAirFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        AirFactoryUnitOnStartBuild(self, unitBeingBuilt, order)
        if order ~= 'Upgrade' then
            self:StartArmsMoving()
        end
    end,

    ---@param self TAirFactoryUnit
    ---@param unitBuilding Unit
    OnStopBuild = function(self, unitBuilding)
        AirFactoryUnitOnStopBuild(self, unitBuilding)
        self:StopArmsMoving()
    end,

    ---@param self TAirFactoryUnit
    OnFailedToBuild = function(self)
        AirFactoryUnitOnFailedToBuild(self)
        self:StopArmsMoving()
    end,

    ---@param self TAirFactoryUnit
    StartArmsMoving = function(self)
        if not self.ArmsThread then
            self.ArmsThread = self.Trash:Add(ForkThread(self.MovingArmsThread, self))
        end
    end,

    ---@param self TAirFactoryUnit
    MovingArmsThread = function(self)
    end,

    ---@param self TAirFactoryUnit
    StopArmsMoving = function(self)
        local armsThread = self.ArmsThread
        if armsThread then
            KillThread(armsThread)
            self.ArmsThread = nil
        end
    end,
}
