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
local ConstructionUnitOnStopBeingBuilt = ConstructionUnit.OnStopBeingBuilt

-- pre-import for performance
local CreateUEFBuildSliceBeams = import('/lua/effectutilities.lua').CreateUEFBuildSliceBeams
local CreateDefaultBuildBeams = import('/lua/effectutilities.lua').CreateDefaultBuildBeams

-- upvalue scope for performance
local WaitFor = WaitFor
local ForkThread = ForkThread

---@class TConstructionUnit : ConstructionUnit
---@field TerrainLayerTransitionThread? thread
---@field TransformManipulator moho.AnimationManipulator
TConstructionUnit = ClassUnit(ConstructionUnit) {

    ---@param self TConstructionUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        ConstructionUnitOnStopBeingBuilt(self, builder, layer)

        if layer == 'Water' then
            self.TerrainLayerTransitionThread = self.Trash:Add(ForkThread(self.TransformThread, self, true))
        end
    end,

    ---@param self TConstructionUnit
    ---@param unitBeingBuilt Unit | { BuildingCube : boolean }
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)

        local buildEffectBones = self.BuildEffectBones
        local buildEffectsBag = self.BuildEffectsBag

        -- Different effect if we have building cube
        if unitBeingBuilt.BuildingCube then
            CreateUEFBuildSliceBeams(self, unitBeingBuilt, buildEffectBones, buildEffectsBag)
        else
            CreateDefaultBuildBeams(self, unitBeingBuilt, buildEffectBones, buildEffectsBag)
        end
    end,

    ---@param self TConstructionUnit
    ---@param new Layer
    ---@param old Layer
    LayerChangeTrigger = function(self, new, old)
        if self.Blueprint.Display.AnimationWater then
            local layerTransitionThread = self.TerrainLayerTransitionThread
            if layerTransitionThread then
                KillThread(layerTransitionThread)
                self.TerrainLayerTransitionThread = nil
            end

            if (old ~= 'None') then
                self.TerrainLayerTransitionThread = self.Trash:Add(ForkThread(self.TransformThread, self, (new == 'Water')))
            end
        end
    end,

    ---@param self TConstructionUnit
    ---@param water boolean
    TransformThread = function(self, water)
        local transformManipulator = self.TransformManipulator
        if not transformManipulator then
            transformManipulator = CreateAnimator(self)
            self.TransformManipulator = self.Trash:Add(transformManipulator)
        end

        if water then
            transformManipulator:PlayAnim(self.Blueprint.Display.AnimationWater)
            transformManipulator:SetRate(1)
            transformManipulator:SetPrecedence(0)
        else
            transformManipulator:SetRate(-1)
            transformManipulator:SetPrecedence(0)
            WaitFor(transformManipulator)
            transformManipulator:Destroy()
            self.TransformManipulator = nil
        end
    end,
}
