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
local ConstructionUnitOnStopBeingBuilt = ConstructionUnit.OnStopBeingBuilt
local ConstructionUnitDestroyAllBuildEffects = ConstructionUnit.DestroyAllBuildEffects
local ConstructionUnitStopBuildingEffects = ConstructionUnit.StopBuildingEffects
local ConstructionUnitOnPaused = ConstructionUnit.OnPaused
local ConstructionUnitOnDestroy = ConstructionUnit.OnDestroy

local CConstructionTemplate = import('/lua/cybranunits.lua').CConstructionTemplate
local CConstructionTemplateOnCreate = CConstructionTemplate.OnCreate
local CConstructionTemplateDestroyAllBuildEffects = CConstructionTemplate.DestroyAllBuildEffects
local CConstructionTemplateStopBuildingEffects = CConstructionTemplate.StopBuildingEffects
local CConstructionTemplateOnPaused = CConstructionTemplate.OnPaused
local CConstructionTemplateCreateBuildEffects = CConstructionTemplate.CreateBuildEffects
local CConstructionTemplateOnDestroy = CConstructionTemplate.OnDestroy

-- upvalue scope for performance
local WaitFor = WaitFor
local ForkThread = ForkThread
local KillThread = KillThread
local CreateAnimator = CreateAnimator

local TrashBagAdd = TrashBag.Add

local AnimatorPlayAnim = moho.AnimationManipulator.PlayAnim
local AnimatorSetRate = moho.AnimationManipulator.SetRate
local AnimatorSetPrecedence = moho.AnimationManipulator.SetPrecedence

---@class CConstructionUnit : ConstructionUnit, CConstructionTemplate
---@field TerrainLayerTransitionThread thread
CConstructionUnit = ClassUnit(ConstructionUnit, CConstructionTemplate) {

    ---@param self CConstructionUnit
    OnCreate = function(self)
        ConstructionUnitOnCreate(self)
        CConstructionTemplateOnCreate(self)
    end,

    ---@param self CConstructionUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        ConstructionUnitOnStopBeingBuilt(self, builder, layer)

        if self.Layer == 'Water' then
            self.TerrainLayerTransitionThread = TrashBagAdd(self.Trash, ForkThread(self.TransformThread, self, true))
        end
    end,

    ---@param self CConstructionUnit
    DestroyAllBuildEffects = function(self)
        ConstructionUnitDestroyAllBuildEffects(self)
        CConstructionTemplateDestroyAllBuildEffects(self)
    end,

    ---@param self CConstructionUnit
    ---@param unitBeingBuilt Unit
    StopBuildingEffects = function(self, unitBeingBuilt)
        ConstructionUnitStopBuildingEffects(self, unitBeingBuilt)
        CConstructionTemplateStopBuildingEffects(self, unitBeingBuilt)
    end,

    ---@param self CConstructionUnit
    OnPaused = function(self)
        ConstructionUnitOnPaused(self)
        CConstructionTemplateOnPaused(self)
    end,

    ---@param self CConstructionUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        CConstructionTemplateCreateBuildEffects(self, unitBeingBuilt, order, false)
    end,

    ---@param self CConstructionUnit
    OnDestroy = function(self)
        ConstructionUnitOnDestroy(self)
        CConstructionTemplateOnDestroy(self)
    end,

    ---@param self CConstructionUnit
    ---@param new Layer
    ---@param old Layer
    LayerChangeTrigger = function(self, new, old)

        local trash = self.Trash
        local terrainLayerTransitionThread = self.TerrainLayerTransitionThread
        if terrainLayerTransitionThread then
            KillThread(terrainLayerTransitionThread)
        end

        if old ~= 'None' then
            self.TerrainLayerTransitionThread = TrashBagAdd(trash, ForkThread(self.TransformThread, self, true))
        end
    end,

    ---@param self CConstructionUnit
    ---@param water boolean
    TransformThread = function(self, water)
        local transformManipulator = self.TransformManipulator
        local animation = self.Blueprint.Display.AnimationWater
        if not animation then
            return
        end

        if not transformManipulator then
            transformManipulator = CreateAnimator(self)
            self.TransformManipulator = TrashBagAdd(self.Trash, transformManipulator)
        end

        if water then
            AnimatorPlayAnim(transformManipulator, self.Blueprint.Display.AnimationWater)
            AnimatorSetRate(transformManipulator, 1)
            AnimatorSetPrecedence(transformManipulator, 0)
        else
            AnimatorSetRate(transformManipulator, -1)
            AnimatorSetPrecedence(transformManipulator, 0)
            WaitFor(transformManipulator)
            transformManipulator:Destroy()
            self.TransformManipulator = nil
        end
    end,
}
