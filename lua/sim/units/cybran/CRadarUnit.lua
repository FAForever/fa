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

local RadarUnit = import('/lua/defaultunits.lua').RadarUnit
local RadarUnitOnCreate = RadarUnit.OnCreate
local RadarUnitOnIntelDisabled = RadarUnit.OnIntelDisabled
local RadarUnitOnIntelEnabled = RadarUnit.OnIntelEnabled

-- upvalue scope for performance
local KillThread = KillThread
local ForkThread = ForkThread
local WaitFor = WaitFor
local WaitTicks = WaitTicks
local Random = Random
local CreateRotator = CreateRotator

local TrashBagAdd = TrashBag.Add

local RotatorSetTargetSpeed = moho.RotateManipulator.SetTargetSpeed
local RotatorSetSpeed = moho.RotateManipulator.SetSpeed
local RotatorSetGoal = moho.RotateManipulator.SetGoal
local RotatorClearGoal = moho.RotateManipulator.ClearGoal
local RotatorSetAccel = moho.RotateManipulator.SetAccel

---@class CRadarUnit : RadarUnit
---@field Thread1 thread
---@field Thread2 thread
---@field Thread3 thread
---@field Dish1Rotator moho.RotateManipulator
---@field Dish2Rotator moho.RotateManipulator
---@field Dish3Rotator moho.RotateManipulator
CRadarUnit = ClassUnit(RadarUnit) {

    ---@param self CRadarUnit
    OnCreate = function(self)
        RadarUnitOnCreate(self)

        local trash = self.Trash
        if self:IsValidBone('Dish01') then
            self.Dish1Rotator = TrashBagAdd(trash, CreateRotator(self, 'Dish01', 'x'))
        end

        if self:IsValidBone('Dish02') then
            self.Dish2Rotator = TrashBagAdd(trash, CreateRotator(self, 'Dish02', 'x'))
        end

        if self:IsValidBone('Dish03') then
            self.Dish3Rotator = TrashBagAdd(trash, CreateRotator(self, 'Dish03', 'x'))
        end
    end,

    ---@param self CRadarUnit
    ---@param intel IntelType
    OnIntelDisabled = function(self, intel)
        RadarUnitOnIntelDisabled(self, intel)

        local dish1 = self.Dish1Rotator
        if dish1 then
            RotatorSetTargetSpeed(dish1, 0)
        end

        local dish2 = self.Dish2Rotator
        if dish2 then
            RotatorSetTargetSpeed(dish2, 0)
        end

        local dish3 = self.Dish3Rotator
        if dish3 then
            RotatorSetTargetSpeed(dish3, 0)
        end

        local thread = self.Thread1
        if (thread) then
            KillThread(thread)
            self.Thread1 = nil
        end

        local thread = self.Thread2
        if (thread) then
            KillThread(thread)
            self.Thread2 = nil
        end

        local thread = self.Thread3
        if (thread) then
            KillThread(thread)
            self.Thread3 = nil
        end
    end,

    ---@param self CRadarUnit
    ---@param intel IntelType
    OnIntelEnabled = function(self, intel)
        RadarUnitOnIntelEnabled(self, intel)

        local trash = self.Trash
        local dishBehavior = self.DishBehavior

        local dish1 = self.Dish1Rotator
        if dish1 and not self.Thread1 then
            self.Thread1 = TrashBagAdd(trash, ForkThread(dishBehavior, self, dish1, 1, 0.4))
        end

        local dish2 = self.Dish2Rotator
        if dish2 and not self.Thread2 then
            self.Thread2 = TrashBagAdd(trash, ForkThread(dishBehavior, self, dish2, 21, 0.5))
        end

        local dish3 = self.Dish3Rotator
        if dish3 and not self.Thread3 then
            self.Thread3 = TrashBagAdd(trash, ForkThread(dishBehavior, self, dish3, 51, 0.6))
        end
    end,

    ---@param self CRadarUnit
    ---@param rotator moho.RotateManipulator
    ---@param delay number
    ---@param chance number
    DishBehavior = function(self, rotator, delay, chance)
        -- local scope for performance
        local Random = Random
        local WaitFor = WaitFor
        local WaitTicks = WaitTicks

        local RotatorSetGoal = RotatorSetGoal
        local RotatorSetAccel = RotatorSetAccel
        local RotatorSetSpeed = RotatorSetSpeed
        local RotatorClearGoal = RotatorClearGoal
        local RotatorSetTargetSpeed = RotatorSetTargetSpeed

        -- initial setup
        RotatorSetSpeed(rotator, 5)
        RotatorSetGoal(rotator, 0)
        WaitFor(rotator)
        WaitTicks(delay)
        RotatorSetSpeed(rotator, 0)
        RotatorClearGoal(rotator)
        RotatorSetAccel(rotator, 5)

        -- radar animation
        while true do
            RotatorSetTargetSpeed(rotator, -15)
            WaitFor(rotator)
            RotatorSetTargetSpeed(rotator, 0)
            WaitFor(rotator)

            if (Random() < chance) then
                WaitTicks(11)
            end

            RotatorSetTargetSpeed(rotator, 15)
            WaitFor(rotator)
            RotatorSetTargetSpeed(rotator, 0)
            WaitFor(rotator)

            if (Random() < chance) then
                WaitTicks(11)
            end
        end
    end,
}
