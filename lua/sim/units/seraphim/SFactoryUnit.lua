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

-- pre-import for performance
local TrashAdd = TrashBag.Add
local CreateSeraphimFactoryBuildingEffects = import('/lua/EffectUtilities.lua').CreateSeraphimFactoryBuildingEffects

-- upvalue scope for performance
local ForkThread = ForkThread

---@class SFactoryUnit : FactoryUnit
---@field Rotator1? moho.RotateManipulator
---@field Rotator2? moho.RotateManipulator
---@field Rotator3? moho.RotateManipulator
SFactoryUnit = ClassUnit(FactoryUnit) {
    ---@param self SFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        local trashBag = self.Trash
        local buildEffectsBag = self.BuildEffectsBag
        local buildEffectBones = self.BuildEffectBones

        local thread = ForkThread(CreateSeraphimFactoryBuildingEffects, self, unitBeingBuilt, buildEffectBones,
            'Attachpoint', buildEffectsBag)
        TrashAdd(trashBag, thread)
        TrashAdd(buildEffectsBag, thread)
    end,

    ---@param self SFactoryUnit
    ---@param unitBeingBuilt SFactoryUnit
    SyncRotators = function(self, unitBeingBuilt)
        -- retrieve all rotators
        local rotator1 = self.Rotator1
        local rotator2 = self.Rotator2
        local otherRotator1 = unitBeingBuilt.Rotator1
        local otherRotator2 = unitBeingBuilt.Rotator2
        local otherRotator3 = unitBeingBuilt.Rotator3

        -- inherit rotation
        if rotator1 and otherRotator1 then
            local savedAngle = rotator1:GetCurrentAngle()
            rotator1:SetGoal(savedAngle)

            otherRotator1:SetCurrentAngle(savedAngle)
            otherRotator1:SetGoal(savedAngle)
        end

        if otherRotator2 then
            otherRotator2:SetCurrentAngle(0)
            otherRotator2:SetGoal(0)
        end

        -- inherit rotation
        if rotator2 and otherRotator2 then
            local savedAngle = rotator2:GetCurrentAngle()
            rotator2:SetGoal(savedAngle)
            otherRotator2:SetCurrentAngle(savedAngle)
            otherRotator2:SetGoal(savedAngle)
        end

        if otherRotator3 then
            otherRotator3:SetCurrentAngle(0)
            otherRotator3:SetGoal(0)
        end
    end,

    ---@param self SFactoryUnit
    ---@param unitBeingBuilt SFactoryUnit
    StartRotators = function(self, unitBeingBuilt)
        local otherRotator1 = unitBeingBuilt.Rotator1
        local otherRotator2 = unitBeingBuilt.Rotator2
        local otherRotator3 = unitBeingBuilt.Rotator3

        if otherRotator1 then
            otherRotator1:ClearGoal()
        end

        if otherRotator2 then
            otherRotator2:ClearGoal()
        end

        if otherRotator3 then
            otherRotator3:ClearGoal()
        end
    end,

    ---@param self SFactoryUnit
    RestartRotators = function(self)
        local rotator1 = self.Rotator1
        local rotator2 = self.Rotator2

        -- Failed to build, so resume rotators
        if rotator1 then
            rotator1:ClearGoal()
            rotator1:SetSpeed(5)
        end

        if rotator2 then
            rotator2:ClearGoal()
            rotator2:SetSpeed(5)
        end
    end,
}
