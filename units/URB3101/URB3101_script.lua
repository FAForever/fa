-- File     :  /cdimage/units/URB3101/URB3101_script.lua
-- Author(s):  David Tomandl
-- Summary  :  Cybran Light Radar Tower Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local CRadarUnit = import("/lua/cybranunits.lua").CRadarUnit

---@class URB3101 : CRadarUnit
---@field Thread1 thread
---@field Thread2 thread
---@field Thread3 thread
---@field Dish1Rotator moho.RotateManipulator
---@field Dish2Rotator moho.RotateManipulator
---@field Dish3Rotator moho.RotateManipulator
URB3101 = ClassUnit(CRadarUnit) {

    ---@param self URB3101
    ---@param intel IntelType
    OnIntelDisabled = function(self, intel)
        CRadarUnit.OnIntelDisabled(self, intel)

        local thread1 = self.Thread1
        if (thread1) then
            KillThread(thread1)
            self.Thread1 = nil
            self.Dish1Rotator:SetTargetSpeed(0)
        end

        local thread2 = self.Thread2
        if (thread2) then
            KillThread(thread2)
            self.Thread2 = nil
            self.Dish2Rotator:SetTargetSpeed(0)
        end

        local thread3 = self.Thread3
        if (thread3) then
            KillThread(thread3)
            self.Thread3 = nil
            self.Dish3Rotator:SetTargetSpeed(0)
        end
    end,

    ---@param self URB3101
    OnIntelEnabled = function(self)
        CRadarUnit.OnIntelEnabled(self)

        local thread
        local trash = self.Trash

        thread = ForkThread(self.Dish1Behavior, self)
        self.Thread1 = thread
        trash:Add(thread)

        thread = ForkThread(self.Dish2Behavior, self)
        self.Thread2 = thread
        trash:Add(thread)

        thread = ForkThread(self.Dish3Behavior, self)
        self.Thread3 = thread
        trash:Add(thread)
    end,

    ---@param self URB3101
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

    ---@param self URB3101
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

    ---@param self URB3101
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

TypeClass = URB3101
