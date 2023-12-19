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

local MassCollectionUnit = import('/lua/defaultunits.lua').MassCollectionUnit
local MassCollectionUnitOnCreate = MassCollectionUnit.OnCreate
local MassCollectionUnitPlayActiveAnimation = MassCollectionUnit.PlayActiveAnimation
local MassCollectionUnitOnProductionPaused = MassCollectionUnit.OnProductionPaused
local MassCollectionUnitOnProductionUnpaused = MassCollectionUnit.OnProductionUnpaused

-- upvalue scope for performance
local CreateAnimator = CreateAnimator

local AnimatorPlayAnim = moho.AnimationManipulator.PlayAnim
local AnimatorSetRate = moho.AnimationManipulator.SetRate

---@class CMassCollectionUnit : MassCollectionUnit
---@field AnimationManipulator moho.AnimationManipulator
CMassCollectionUnit = ClassUnit(MassCollectionUnit) {

    ---@param self CMassCollectionUnit
    OnCreate = function(self)
        MassCollectionUnitOnCreate(self)

        local buildAnimManip = CreateAnimator(self)
        AnimatorPlayAnim(buildAnimManip, self.Blueprint.Display.AnimationOpen, true)
        AnimatorSetRate(buildAnimManip, 0)
        self.AnimationManipulator = self.Trash:Add(buildAnimManip)
    end,

    ---@param self CMassCollectionUnit
    PlayActiveAnimation = function(self)
        MassCollectionUnitPlayActiveAnimation(self)
        AnimatorSetRate(self.AnimationManipulator, 1)
    end,

    ---@param self CMassCollectionUnit
    OnProductionPaused = function(self)
        MassCollectionUnitOnProductionPaused(self)
        AnimatorSetRate(self.AnimationManipulator, 0);
    end,

    ---@param self CMassCollectionUnit
    OnProductionUnpaused = function(self)
        MassCollectionUnitOnProductionUnpaused(self)
        AnimatorSetRate(self.AnimationManipulator, 1)
    end,
}
