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
local ConstructionUnitOnCreate = ConstructionUnit.OnCreate
local ConstructionUnitSetupBuildBones = ConstructionUnit.SetupBuildBones
local ConstructionUnitBuildManipulatorSetEnabled = ConstructionUnit.BuildManipulatorSetEnabled

local CreateSeraphimUnitEngineerBuildingEffects = import('/lua/effectutilities.lua').CreateSeraphimUnitEngineerBuildingEffects
local CreateBuilderArmController                = import('/lua/effectutilities.lua').CreateBuilderArmController

---@class SConstructionUnit : ConstructionUnit
---@field BuildArm2Manipulator moho.BuilderArmManipulator
SConstructionUnit = ClassUnit(ConstructionUnit) {

    ---@param self SConstructionUnit
    OnCreate = function(self)
        ConstructionUnitOnCreate(self)

        -- is overwritten to add support for the second build arm manipulator
        if self.BuildingOpenAnim then
            local buildArmManipulator = self.BuildArm2Manipulator
            if buildArmManipulator then
                buildArmManipulator:Disable()
            end
        end
    end,

    ---@param self SConstructionUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        CreateSeraphimUnitEngineerBuildingEffects(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
    end,

    ---@param self SConstructionUnit
    SetupBuildBones = function(self)
        ConstructionUnitSetupBuildBones(self)

        -- is overwritten to add support for the second build arm manipulator
        local buildbones = self.Blueprint.General.BuildBonesAlt1
        if buildbones then
            buildArmManipulator = CreateBuilderArmController(self,
                buildbones.YawBone or 0,
                buildbones.PitchBone or 0,
                buildbones.AimBone or 0
            )
            buildArmManipulator:SetAimingArc(-180, 180, 360, -90, 90, 360)
            buildArmManipulator:SetPrecedence(5)
            self.BuildArm2Manipulator = self.Trash:Add(buildArmManipulator)
        end
    end,

    ---@param self SConstructionUnit
    ---@param enable boolean
    BuildManipulatorSetEnabled = function(self, enable)
        ConstructionUnitBuildManipulatorSetEnabled(self, enable)

        -- is overwritten to add support for the second build arm manipulator
        if IsDestroyed(self) then
            return
        end

        local buildArmManipulator = self.BuildArm2Manipulator
        if buildArmManipulator then
            return
        end

        if enable then
            buildArmManipulator:Enable()
        else
            buildArmManipulator:Disable()
        end
    end,
}
