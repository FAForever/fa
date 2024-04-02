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

local MobileUnit = import("/lua/sim/units/mobileunit.lua").MobileUnit
local MobileUnitOnMotionHorzEventChange = MobileUnit.OnMotionHorzEventChange

-- upvalue scope for performance
local CreateAnimator = CreateAnimator
local AnimationManipulatorPlayAnim = moho.AnimationManipulator.PlayAnim
local AnimationManipulatorSetRate = moho.AnimationManipulator.SetRate

---@class WalkingLandUnit : MobileUnit
---@field Animator? moho.AnimationManipulator
WalkingLandUnit = ClassUnit(MobileUnit) {

    ---@param self WalkingLandUnit
    ---@param new HorizontalMovementState
    ---@param old HorizontalMovementState
    OnMotionHorzEventChange = function(self, new, old)
        MobileUnitOnMotionHorzEventChange(self, new, old)

        local animator = self.Animator

        if old == 'Stopped' then
            -- create the animation if it doesn't exist
            if not animator then
                animator = CreateAnimator(self, true)
                self.Animator = self.Trash:Add(animator)
            end

            -- load in the animation and the animation rate
            local blueprintDisplay = self.Blueprint.Display
            local animationWalk = blueprintDisplay.AnimationWalk
            local animationWalkRate = blueprintDisplay.AnimationWalkRate or 1
            if animationWalk then
                AnimationManipulatorPlayAnim(animator, animationWalk, true)
                AnimationManipulatorSetRate(animator, animationWalkRate)
            end

        elseif new == 'Stopped' then
            -- remove the animation
            if animator then
                animator:Destroy()
                self.Animator = nil
            end
        end
    end,
}
