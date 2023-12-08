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

---@class CMassCollectionUnit : MassCollectionUnit
---@field AnimationManipulator moho.AnimationManipulator
CMassCollectionUnit = ClassUnit(MassCollectionUnit) {

    OnStartBuild = function(self, unitBeingBuilt, order)
        MassCollectionUnit.OnStartBuild(self, unitBeingBuilt, order)
        if not self.AnimationManipulator then return end
        self.AnimationManipulator:SetRate(0)
        self.AnimationManipulator:Destroy()
        self.AnimationManipulator = nil
    end,

    ---@param self CMassCollectionUnit
    PlayActiveAnimation = function(self)
        MassCollectionUnit.PlayActiveAnimation(self)

        local animationManipulator = self.AnimationManipulator
        if not animationManipulator then
            animationManipulator = CreateAnimator(self)
            self.Trash:Add(animationManipulator)
            self.AnimationManipulator = animationManipulator
        end

        animationManipulator:PlayAnim(self.Blueprint.Display.AnimationOpen, true)
    end,

    ---@param self CMassCollectionUnit
    OnProductionPaused = function(self)
        MassCollectionUnit.OnProductionPaused(self)
        local animationManipulator = self.AnimationManipulator
        if not animationManipulator then return end
        animationManipulator:SetRate(0)
    end,

    ---@param self CMassCollectionUnit
    OnProductionUnpaused = function(self)
        MassCollectionUnit.OnProductionUnpaused(self)
        local animationManipulator = self.AnimationManipulator
        if not animationManipulator then return end
        animationManipulator:SetRate(1)
    end,

}
