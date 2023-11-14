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

local ConstructionUnit = import('/lua/defaultunits.lua').ConstructionUnit
local EffectUtil = import('/lua/effectutilities.lua')
local CreateBuilderArmController = import('/lua/effectutilities.lua').CreateBuilderArmController

-- Construction Units
---@class SConstructionUnit : ConstructionUnit
SConstructionUnit = ClassUnit(ConstructionUnit) {
    OnCreate = function(self)
        ConstructionUnit.OnCreate(self)
        if self.BuildingOpenAnim then
            if self.BuildArm2Manipulator then
                self.BuildArm2Manipulator:Disable()
            end
        end
    end,

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateSeraphimUnitEngineerBuildingEffects(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
    end,

    SetupBuildBones = function(self)
        ConstructionUnit.SetupBuildBones(self)

        local bp = self:GetBlueprint()
        local buildbones = bp.General.BuildBones
        if self.BuildArmManipulator then
            self.BuildArmManipulator:SetAimingArc(buildbones.YawMin or -180, buildbones.YawMax or 180, buildbones.YawSlew or 360, buildbones.PitchMin or -90, buildbones.PitchMax or 90, buildbones.PitchSlew or 360)
        end
        if bp.General.BuildBonesAlt1 then
            self.BuildArm2Manipulator = CreateBuilderArmController(self, bp.General.BuildBonesAlt1.YawBone or 0 , bp.General.BuildBonesAlt1.PitchBone or 0, bp.General.BuildBonesAlt1.AimBone or 0)
            self.BuildArm2Manipulator:SetAimingArc(bp.General.BuildBonesAlt1.YawMin or -180, bp.General.BuildBonesAlt1.YawMax or 180, bp.General.BuildBonesAlt1.YawSlew or 360, bp.General.BuildBonesAlt1.PitchMin or -90, bp.General.BuildBonesAlt1.PitchMax or 90, bp.General.BuildBonesAlt1.PitchSlew or 360)
            self.BuildArm2Manipulator:SetPrecedence(5)
            if self.BuildingOpenAnimManip and self.Build2ArmManipulator then
                self.BuildArm2Manipulator:Disable()
            end
            self.Trash:Add(self.BuildArm2Manipulator)
        end
    end,

    BuildManipulatorSetEnabled = function(self, enable)
        ConstructionUnit.BuildManipulatorSetEnabled(self, enable)
        if not self or self.Dead then return end
        if not self.BuildArm2Manipulator then return end
        if enable then
            self.BuildArm2Manipulator:Enable()
        else
            self.BuildArm2Manipulator:Disable()
        end
    end,

    WaitForBuildAnimation = function(self, enable)
        if self.BuildArmManipulator then
            WaitFor(self.BuildingOpenAnimManip)
            if enable then
                self:BuildManipulatorSetEnabled(enable)
            end
        end
    end,

    OnStopBuilderTracking = function(self)
        ConstructionUnit.OnStopBuilderTracking(self)
        if self.StoppedBuilding then
            self:BuildManipulatorSetEnabled(disable)
        end
    end,
}