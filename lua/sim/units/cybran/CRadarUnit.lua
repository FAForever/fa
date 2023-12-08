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

---@class CRadarUnit : RadarUnit
---@field Thread1 thread
---@field Thread2 thread
---@field Thread3 thread
---@field Dish1Rotator moho.RotateManipulator
---@field Dish2Rotator moho.RotateManipulator
---@field Dish3Rotator moho.RotateManipulator
CRadarUnit = ClassUnit(RadarUnit) {

    ---@param self CRadarUnit
    ---@param intel IntelType
    OnIntelDisabled = function(self, intel)
        RadarUnit.OnIntelDisabled(self, intel)

        local rotator, thread

        thread = self.Thread1
        if (thread) then
            KillThread(thread)
            self.Thread1 = nil

        end

        rotator = self.Dish1Rotator
        if rotator then
            rotator:SetTargetSpeed(0)
        end

        thread = self.Thread2
        if (thread) then
            KillThread(thread)
            self.Thread2 = nil
        end

        rotator = self.Dish2Rotator
        if rotator then
            rotator:SetTargetSpeed(0)
        end

        thread = self.Thread3
        if (thread) then
            KillThread(thread)
            self.Thread3 = nil
        end

        rotator = self.Dish3Rotator
        if rotator then
            rotator:SetTargetSpeed(0)
        end
    end,

    ---@param self CRadarUnit
    ---@param intel IntelType
    OnIntelEnabled = function(self, intel)
        RadarUnit.OnIntelEnabled(self, intel)

        local thread
        local trash = self.Trash

        thread = self.Thread1
        if not thread then
            thread = ForkThread(self.Dish1Behavior, self)
            self.Thread1 = thread
            trash:Add(thread)
        end

        thread = self.Thread2
        if not thread then
            thread = ForkThread(self.Dish2Behavior, self)
            self.Thread2 = thread
            trash:Add(thread)
        end

        thread = self.Thread3
        if not thread then
            thread = ForkThread(self.Dish3Behavior, self)
            self.Thread3 = thread
            trash:Add(thread)
        end
    end,

    ---@param self CRadarUnit
    Dish1Behavior = function(self)
        local rotator = self.Dish1Rotator
        if not rotator then
            rotator = CreateRotator(self, 'Dish01', 'x')
            self.Dish1Rotator = rotator
            self.Trash:Add(rotator)
        end

        -- local scope for performance
        local WaitFor = WaitFor
        local WaitTicks = WaitTicks
        local Random = Random

        rotator:SetSpeed(5):SetGoal(0)
        WaitFor(rotator)
        rotator:SetSpeed(0)
        rotator:ClearGoal()
        rotator:SetAccel(5)

        while true do
            rotator:SetTargetSpeed(-15)
            WaitFor(rotator)
            rotator:SetTargetSpeed(0)
            WaitFor(rotator)

            if (Random() < 0.5) then
                WaitTicks(11)
            end

            rotator:SetTargetSpeed(15)
            WaitFor(rotator)
            rotator:SetTargetSpeed(0)
            WaitFor(rotator)

            if (Random() < 0.5) then
                WaitTicks(11)
            end
        end
    end,

    ---@param self CRadarUnit
    Dish2Behavior = function(self)
        local rotator = self.Dish2Rotator
        if not rotator then
            rotator = CreateRotator(self, 'Dish02', 'x')
            self.Dish2Rotator = rotator
            self.Trash:Add(rotator)
        end

        -- local scope for performance
        local WaitFor = WaitFor
        local WaitTicks = WaitTicks
        local Random = Random

        rotator:SetSpeed(5):SetGoal(0)
        WaitFor(rotator)
        WaitTicks(21)
        rotator:SetSpeed(0)
        rotator:ClearGoal()
        rotator:SetAccel(5)

        while true do
            rotator:SetTargetSpeed(-15)
            WaitFor(rotator)
            rotator:SetTargetSpeed(0)
            WaitFor(rotator)

            if (Random() < 0.4) then
                WaitTicks(11)
            end

            rotator:SetTargetSpeed(15)
            WaitFor(rotator)
            rotator:SetTargetSpeed(0)
            WaitFor(rotator)

            if (Random() < 0.4) then
                WaitTicks(11)
            end
        end
    end,

    ---@param self CRadarUnit
    Dish3Behavior = function(self)
        local rotator = self.Dish3Rotator
        if not rotator then
            rotator = CreateRotator(self, 'Dish03', 'x')
            self.Dish3Rotator = rotator
            self.Trash:Add(rotator)
        end

        -- local scope for performance
        local WaitFor = WaitFor
        local WaitTicks = WaitTicks
        local Random = Random

        rotator:SetSpeed(5):SetGoal(0)
        WaitFor(rotator)
        WaitTicks(51)
        rotator:SetSpeed(0)
        rotator:ClearGoal()
        rotator:SetAccel(5)

        while true do
            rotator:SetTargetSpeed(-15)
            WaitFor(rotator)
            rotator:SetTargetSpeed(0)
            WaitFor(rotator)

            if (Random() < 0.6) then
                WaitTicks(11)
            end

            rotator:SetTargetSpeed(15)
            WaitFor(rotator)
            rotator:SetTargetSpeed(0)
            WaitFor(rotator)

            if (Random() < 0.6) then
                WaitTicks(11)
            end
        end
    end,
}
