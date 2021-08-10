#****************************************************************************
#**
#**  File     :  /cdimage/units/URB3104/URB3104_script.lua
#**  Author(s):  David Tomandl
#**
#**  Summary  :  Cybran Omni Sensor Suite Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CRadarUnit = import('/lua/cybranunits.lua').CRadarUnit

URB3104 = Class(CRadarUnit) {

    OnStopBeingBuilt = function(self,builder,layer)
        CRadarUnit.OnStopBeingBuilt(self,builder,layer)

        # move the dishes about
    end,

    OnIntelDisabled = function(self)
        CRadarUnit.OnIntelDisabled(self)
        if (self.Thread1) then
            KillThread(self.Thread1)
            self.Thread1 = nil
        end
        if (self.Thread2) then
            KillThread(self.Thread2)
            self.Thread2 = nil
        end
        if (self.Thread3) then
            KillThread(self.Thread3)
            self.Thread3 = nil
        end
        self.Dish1Rotator:SetTargetSpeed(0)
        self.Dish2Rotator:SetTargetSpeed(0)
        self.Dish3Rotator:SetTargetSpeed(0)
        self.MainRotator:SetTargetSpeed(0)
        self.MainRotator:SetAccel(1)
    end,


    OnIntelEnabled = function(self)
        CRadarUnit.OnIntelEnabled(self)
        if not self.MainRotator then
            self.MainRotator = CreateRotator(self, 'Spinner', 'z')
            self.Trash:Add(self.MainRotator)
        end

        self.Thread1 = self:ForkThread(self.Dish1Behavior)
        self.Thread2 = self:ForkThread(self.Dish2Behavior)
        self.Thread3 = self:ForkThread(self.Dish3Behavior)
        self.MainRotator:SetTargetSpeed(3)
        self.MainRotator:SetAccel(0.1)
    end,

    Dish1Behavior = function(self)
        if not self.Dish1Rotator then
            self.Dish1Rotator = CreateRotator(self, 'Dish01', 'x')
            self.Trash:Add(self.Dish1Rotator)
        end
        self.Dish1Rotator:SetSpeed(5):SetGoal(0)
        WaitFor(self.Dish1Rotator)
        self.Dish1Rotator:SetSpeed(0)
        self.Dish1Rotator:ClearGoal()
        self.Dish1Rotator:SetAccel(5)
        while true do
            self.Dish1Rotator:SetTargetSpeed(-15)
            WaitFor(self.Dish1Rotator)
            self.Dish1Rotator:SetTargetSpeed(0)
            WaitFor(self.Dish1Rotator)
            if (Random() < 0.5) then WaitSeconds(1) end
            self.Dish1Rotator:SetTargetSpeed(15)
            WaitFor(self.Dish1Rotator)
            self.Dish1Rotator:SetTargetSpeed(0)
            WaitFor(self.Dish1Rotator)
            if (Random() < 0.5) then WaitSeconds(1) end
        end
    end,

    Dish2Behavior = function(self)
        if not self.Dish2Rotator then
            self.Dish2Rotator = CreateRotator(self, 'Dish02', 'x')
            self.Trash:Add(self.Dish2Rotator)
        end
        self.Dish2Rotator:SetSpeed(5):SetGoal(0)
        WaitFor(self.Dish2Rotator)
        WaitSeconds(2)
        self.Dish2Rotator:SetSpeed(0)
        self.Dish2Rotator:ClearGoal()
        self.Dish2Rotator:SetAccel(5)
        while true do
            self.Dish2Rotator:SetTargetSpeed(-15)
            WaitFor(self.Dish2Rotator)
            self.Dish2Rotator:SetTargetSpeed(0)
            WaitFor(self.Dish2Rotator)
            if (Random() < 0.4) then WaitSeconds(1) end
            self.Dish2Rotator:SetTargetSpeed(15)
            WaitFor(self.Dish2Rotator)
            self.Dish2Rotator:SetTargetSpeed(0)
            WaitFor(self.Dish2Rotator)
            if (Random() < 0.4) then WaitSeconds(1) end
        end
    end,

    Dish3Behavior = function(self)
        if not self.Dish3Rotator then
            self.Dish3Rotator = CreateRotator(self, 'Dish03', 'x')
            self.Trash:Add(self.Dish3Rotator)
        end
        self.Dish3Rotator:SetSpeed(5):SetGoal(0)
        WaitFor(self.Dish3Rotator)
        WaitSeconds(5)
        self.Dish3Rotator:SetSpeed(0)
        self.Dish3Rotator:ClearGoal()
        self.Dish3Rotator:SetAccel(5)
        while true do
            self.Dish3Rotator:SetTargetSpeed(-15)
            WaitFor(self.Dish3Rotator)
            self.Dish3Rotator:SetTargetSpeed(0)
            WaitFor(self.Dish3Rotator)
            if (Random() < 0.6) then WaitSeconds(1) end
            self.Dish3Rotator:SetTargetSpeed(15)
            WaitFor(self.Dish3Rotator)
            self.Dish3Rotator:SetTargetSpeed(0)
            WaitFor(self.Dish3Rotator)
            if (Random() < 0.6) then WaitSeconds(1) end
        end
    end,
}

TypeClass = URB3104