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

local CStructureUnit = import('/lua/cybranunits.lua').CStructureUnit
local CStructureUnitOnCreate = CStructureUnit.OnCreate
local CStructureUnitDestroyAllBuildEffects = CStructureUnit.DestroyAllBuildEffects
local CStructureUnitStopBuildingEffects = CStructureUnit.StopBuildingEffects
local CStructureUnitOnPaused = CStructureUnit.OnPaused
local CStructureUnitOnUnpaused = CStructureUnit.OnUnpaused
local CStructureUnitOnDestroy = CStructureUnit.OnDestroy
local CStructureUnitOnStartBuild = CStructureUnit.OnStartBuild
local CStructureUnitOnStopBuild = CStructureUnit.OnStopBuild

local CConstructionTemplate = import('/lua/cybranunits.lua').CConstructionTemplate
local CConstructionTemplateOnCreate = CConstructionTemplate.OnCreate
local CConstructionTemplateDestroyAllBuildEffects = CConstructionTemplate.DestroyAllBuildEffects
local CConstructionTemplateStopBuildingEffects = CConstructionTemplate.StopBuildingEffects
local CConstructionTemplateOnPaused = CConstructionTemplate.OnPaused
local CConstructionTemplateCreateBuildEffects = CConstructionTemplate.CreateBuildEffects
local CConstructionTemplateOnDestroy = CConstructionTemplate.OnDestroy

-- upvalue scope for performance
local CreateAnimator = CreateAnimator

local AnimatorPlayAnim = moho.AnimationManipulator.PlayAnim
local AnimatorSetRate = moho.AnimationManipulator.SetRate

---@class CConstructionStructureUnit : CStructureUnit, CConstructionTemplate
---@field AnimationManipulator moho.AnimationManipulator
---@field BuildingUnit boolean
---@field UnitBuildOrder? string
---@field UnitBeingBuilt? Unit
---@field BuildArmManipulator moho.manipulator_methods
---@field BuildingOpenAnimManip moho.AnimationManipulator
CConstructionStructureUnit = ClassUnit(CStructureUnit, CConstructionTemplate) {

    ---@param self CConstructionStructureUnit
    OnCreate = function(self)
        CStructureUnitOnCreate(self)
        CConstructionTemplateOnCreate(self)

        local blueprint = self.Blueprint

        -- Save build effect bones for faster access when creating build effects
        self.BuildEffectBones = blueprint.General.BuildBones.BuildEffectBones

        local animationManipulator = CreateAnimator(self)
        AnimatorPlayAnim(animationManipulator, blueprint.Display.AnimationOpen)
        AnimatorSetRate(animationManipulator, 0)
        self.AnimationManipulator = self.Trash:Add(animationManipulator)

        self:SetupBuildBones()
    end,

    ---@param self CConstructionStructureUnit
    DestroyAllBuildEffects = function(self)
        CStructureUnitDestroyAllBuildEffects(self)
        CConstructionTemplateDestroyAllBuildEffects(self)
    end,

    ---@param self CConstructionStructureUnit
    ---@param built Unit
    StopBuildingEffects = function(self, built)
        CStructureUnitStopBuildingEffects(self, built)
        CConstructionTemplateStopBuildingEffects(self, built)
    end,

    ---@param self CConstructionStructureUnit
    OnPaused = function(self)
        CStructureUnitOnPaused(self)
        CConstructionTemplateOnPaused(self, 0)

        local unitBeingBuilt = self.UnitBeingBuilt
        if unitBeingBuilt then
            self:StopBuildingEffects(unitBeingBuilt)

            -- slowly close the hive
            AnimatorSetRate(self.AnimationManipulator, -0.25)
        end
    end,

    ---@param self CConstructionStructureUnit
    OnUnpaused = function(self)
        CStructureUnitOnUnpaused(self)

        local unitBeingBuilt = self.UnitBeingBuilt
        local unitBuildOrder = self.UnitBuildOrder

        if unitBeingBuilt and unitBuildOrder then
            self:StartBuildingEffects(unitBeingBuilt, unitBuildOrder)

            -- quickly open the hive
            self.AnimationManipulator:SetRate(1)
        end
    end,

    ---@param self CConstructionStructureUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        CConstructionTemplateCreateBuildEffects(self, unitBeingBuilt, order, true)
    end,

    ---@param self CConstructionStructureUnit
    OnDestroy = function(self)
        CStructureUnitOnDestroy(self)
        CConstructionTemplateOnDestroy(self)
    end,

    ---@param self CConstructionStructureUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        CStructureUnitOnStartBuild(self, unitBeingBuilt, order)

        -- quickly open the hive
        AnimatorSetRate(self.AnimationManipulator, 1)

        -- keep track of who we are building
        self.UnitBeingBuilt = unitBeingBuilt
        self.UnitBuildOrder = order
        self.BuildingUnit = true
    end,

    --- This will only be called if not in StructureUnit's upgrade state
    ---@param self CConstructionStructureUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStopBuild = function(self, unitBeingBuilt, order)
        CStructureUnitOnStopBuild(self, unitBeingBuilt, order)

        -- slowly close the hive
        self.AnimationManipulator:SetRate(-0.25)

        -- lose track of who we are building
        self.UnitBeingBuilt = nil
        self.UnitBuildOrder = nil
        self.BuildingUnit = false
    end,
}
