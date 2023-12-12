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

-- upvalue scope for performance
local CreateSlider = CreateSlider
local TrashBagAdd = TrashBag.Add

local SliderSetGoal = moho.SlideManipulator.SetGoal
local SliderSetSpeed = moho.SlideManipulator.SetSpeed

---@class Cybran2BuildArmComponent
---@field ArmSlider1 moho.SlideManipulator
---@field ArmSlider2 moho.SlideManipulator
Cybran2BuildArmComponent = ClassSimple {

    ArmBone1 = false,
    ArmBone2 = false,

    ---@param self BuildArmComponent | Unit
    OnCreate = function(self)
        local trash = self.Trash

        self.ArmSlider1 = TrashBagAdd(trash, CreateSlider(self, self.ArmBone1))
        self.ArmSlider2 = TrashBagAdd(trash, CreateSlider(self, self.ArmBone2))
    end,

    ---@param self BuildArmComponent | Unit
    StartArmsMoving = function(self)
        -- do nothing
    end,

    ---@param self BuildArmComponent | Unit
    MovingArmsThread = function(self)
        -- local scope for performance
        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2

        while true do
            SliderSetGoal(armSlider1, 20, 0, 0)
            SliderSetSpeed(armSlider1, 40)
            SliderSetGoal(armSlider2, -20, 0, 0)
            SliderSetSpeed(armSlider2, 40)
            WaitFor(armSlider2)
            SliderSetGoal(armSlider1, -10, 0, 0)
            SliderSetSpeed(armSlider1, 40)
            SliderSetGoal(armSlider2, 0, 0, 0)
            SliderSetSpeed(armSlider2, 60)
            WaitFor(armSlider2)
        end
    end,

    ---@param self BuildArmComponent | Unit
    StopArmsMoving = function(self)
        -- local scope for performance
        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2

        SliderSetGoal(armSlider1, 0, 0, 0)
        SliderSetSpeed(armSlider1, 40)
        SliderSetGoal(armSlider2, 0, 0, 0)
        SliderSetSpeed(armSlider2, 40)
    end,
}
