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
local CConstructionTemplate = import('/lua/cybranunits.lua').CConstructionTemplate

-- CONSTRUCTION UNITS
---@class CConstructionUnit : ConstructionUnit, CConstructionTemplate
CConstructionUnit = ClassUnit(ConstructionUnit, CConstructionTemplate) {

    ---@param self CConstructionUnit
    OnCreate = function(self)
        ConstructionUnit.OnCreate(self)
        CConstructionTemplate.OnCreate(self)
    end,

    ---@param self CConstructionUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        ConstructionUnit.OnStopBeingBuilt(self, builder, layer)
        if self.Layer == 'Water' then
            self.TerrainLayerTransitionThread = self:ForkThread(self.TransformThread, true)
        end
    end,

    ---@param self CConstructionUnit
    DestroyAllBuildEffects = function(self)
        ConstructionUnit.DestroyAllBuildEffects(self)
        CConstructionTemplate.DestroyAllBuildEffects(self)
    end,

    ---@param self CConstructionUnit
    ---@param built boolean
    StopBuildingEffects = function(self, built)
        ConstructionUnit.StopBuildingEffects(self, built)
        CConstructionTemplate.StopBuildingEffects(self, built)
    end,

    ---@param self CConstructionUnit
    OnPaused = function(self)
        ConstructionUnit.OnPaused(self)
        CConstructionTemplate.OnPaused(self)
    end,

    ---@param self CConstructionUnit
    ---@param unitBeingBuilt Unit
    ---@param order number
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        CConstructionTemplate.CreateBuildEffects(self, unitBeingBuilt, order)
    end,

    ---@param self CConstructionUnit
    OnDestroy = function(self)
        ConstructionUnit.OnDestroy(self)
        CConstructionTemplate.OnDestroy(self)
    end,

    ---@param self CConstructionUnit
    ---@param new Layer
    ---@param old Layer
    LayerChangeTrigger = function(self, new, old)
        if self.Blueprint.Display.AnimationWater then
            if self.TerrainLayerTransitionThread then
                self.TerrainLayerTransitionThread:Destroy()
                self.TerrainLayerTransitionThread = nil
            end
            if old ~= 'None' then
                self.TerrainLayerTransitionThread = self:ForkThread(self.TransformThread, (new == 'Water'))
            end
        end
    end,

    ---@param self CConstructionUnit
    ---@param water boolean
    TransformThread = function(self, water)
        if not self.TransformManipulator then
            self.TransformManipulator = CreateAnimator(self)
            self.Trash:Add(self.TransformManipulator)
        end

        if water then
            self.TransformManipulator:PlayAnim(self.Blueprint.Display.AnimationWater)
            self.TransformManipulator:SetRate(1)
            self.TransformManipulator:SetPrecedence(0)
        else
            self.TransformManipulator:SetRate(-1)
            self.TransformManipulator:SetPrecedence(0)
            WaitFor(self.TransformManipulator)
            self.TransformManipulator:Destroy()
            self.TransformManipulator = nil
        end
    end,
}
