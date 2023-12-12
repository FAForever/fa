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

---@class Cybran3BuildArmComponent
---@field ArmSlider1 moho.SlideManipulator
---@field ArmSlider3 moho.SlideManipulator
---@field ArmSlider2 moho.SlideManipulator
Cybran3BuildArmComponent = ClassSimple {

    ArmBone1 = false,
    ArmBone2 = false,
    ArmBone3 = false,

    ---@param self BuildArmComponent | Unit
    OnCreate = function(self)
        local trash = self.Trash

        self.ArmSlider1 = TrashBagAdd(trash, CreateSlider(self, self.ArmBone1))
        self.ArmSlider2 = TrashBagAdd(trash, CreateSlider(self, self.ArmBone2))
        self.ArmSlider3 = TrashBagAdd(trash, CreateSlider(self, self.ArmBone3))
    end,

    ---@param self BuildArmComponent | Unit
    StartArmsMoving = function(self)
        -- do nothing
    end,

    ---@param self BuildArmComponent | Unit
    MovingArmsThread = function(self)
        local direction = 1

        -- local scope for performance
        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2
        local armSlider3 = self.ArmSlider3

        SliderSetGoal(armSlider1, -10, 0, 0)
        SliderSetSpeed(armSlider1, 40)
        SliderSetGoal(armSlider2, 20, 0, 0)
        SliderSetSpeed(armSlider2, 40)
        SliderSetGoal(armSlider3, 50, 0, 0)
        SliderSetSpeed(armSlider3, 60)
        WaitFor(armSlider1)
        while true do
            SliderSetGoal(armSlider1, 0, 0, 0)
            SliderSetSpeed(armSlider1, 40)
            SliderSetGoal(armSlider2, 0, 0, 0)
            SliderSetSpeed(armSlider2, 40)
            SliderSetGoal(armSlider3, 0, 0, 0)
            SliderSetSpeed(armSlider3, 40)
            WaitFor(armSlider3)
            SliderSetGoal(armSlider1, -10, 0, 0)
            SliderSetSpeed(armSlider1, 40)
            SliderSetGoal(armSlider2, 20 + 30 * direction, 0, 0)
            SliderSetSpeed(armSlider2, 60)
            SliderSetGoal(armSlider3, 50, 0, 0)
            SliderSetSpeed(armSlider3, 60)
            WaitFor(armSlider3)
            direction = direction * -1
        end
    end,

    ---@param self BuildArmComponent | Unit
    StopArmsMoving = function(self)
        -- local scope for performance
        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2
        local armSlider3 = self.ArmSlider3

        SliderSetGoal(armSlider1, 0, 0, 0)
        SliderSetSpeed(armSlider1, 40)
        SliderSetGoal(armSlider2, 0, 0, 0)
        SliderSetSpeed(armSlider2, 40)
        SliderSetGoal(armSlider3, 0, 0, 0)
        SliderSetSpeed(armSlider3, 40)
    end,
}
