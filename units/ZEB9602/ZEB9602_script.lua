--******************************************************************************************************
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
--******************************************************************************************************

local TAirFactoryUnit = import("/lua/terranunits.lua").TAirFactoryUnit
local TAirFactoryUnitStartArmsMoving = TAirFactoryUnit.StartArmsMoving
local TAirFactoryUnitMovingArmsThread = TAirFactoryUnit.MovingArmsThread
local TAirFactoryUnitStopArmsMoving = TAirFactoryUnit.StopArmsMoving

---@class ZEB9602 : TAirFactoryUnit
---@field CreatedBuildArms boolean
ZEB9602 = ClassUnit(TAirFactoryUnit) {

    StartArmsMoving = function(self)
        TAirFactoryUnitStartArmsMoving(self)

        if not self.CreatedBuildArms then
            local CreateSlider = CreateSlider
            local trash = self.Trash

            local armSlider1 = CreateSlider(self, 'Arm01')
            local armSlider2 = CreateSlider(self, 'Arm02')
            local armSlider3 = CreateSlider(self, 'Arm03')

            trash:Add(armSlider1)
            trash:Add(armSlider2)
            trash:Add(armSlider3)

            self.ArmSlider1 = armSlider1
            self.ArmSlider2 = armSlider2
            self.ArmSlider3 = armSlider3
        end

        self.CreatedBuildArms = true
    end,

    MovingArmsThread = function(self)
        TAirFactoryUnitMovingArmsThread(self)

        if not self.CreatedBuildArms then
            return
        end

        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2
        local armSlider3 = self.ArmSlider3

        -- local scope for performance
        local WaitFor = WaitFor
        local SetGoal = armSlider1.SetGoal
        local SetSpeed = armSlider1.SetSpeed

        local dir = 1
        while true do
            SetGoal(armSlider1, 0, -5, 0)
            SetGoal(armSlider2, 0, 2 * dir, 0)
            SetGoal(armSlider3, 0, 5, 0)
            SetSpeed(armSlider1, 20)
            SetSpeed(armSlider2, 10)
            SetSpeed(armSlider3, 20)
            WaitFor(armSlider3)

            SetGoal(armSlider1, 0, 0, 0)
            SetGoal(armSlider2, 0, 0, 0)
            SetGoal(armSlider3, 0, 0, 0)
            SetSpeed(armSlider1, 20)
            SetSpeed(armSlider2, 10)
            SetSpeed(armSlider3, 20)
            WaitFor(armSlider3)

            dir = dir * -1
        end
    end,

    StopArmsMoving = function(self)
        TAirFactoryUnitStopArmsMoving(self)

        if not self.CreatedBuildArms then
            return
        end

        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2
        local armSlider3 = self.ArmSlider3

        armSlider1:SetGoal(0, 0, 0)
        armSlider2:SetGoal(0, 0, 0)
        armSlider3:SetGoal(0, 0, 0)
        armSlider1:SetSpeed(40)
        armSlider2:SetSpeed(40)
        armSlider3:SetSpeed(40)
    end,
}

TypeClass = ZEB9602
