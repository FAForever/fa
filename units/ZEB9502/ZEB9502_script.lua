-- File     :  /cdimage/units/ZEB9502/ZEB9502_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  UEF T2 Air Factory Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local TAirFactoryUnit = import("/lua/terranunits.lua").TAirFactoryUnit

---@class ZEB9502 : TAirFactoryUnit
ZEB9502 = ClassUnit(TAirFactoryUnit) {
    StartArmsMoving = function(self)
        local arm1 = self.ArmSlider1
        local arm2 = self.ArmSlider2
        local trash = self.Trash

        TAirFactoryUnit.StartArmsMoving(self)
        if not arm1 then
            arm1 = CreateSlider(self, 'Arm01')
            self.ArmSlider1 = arm1
            trash:Add(arm1)
        end
        if not arm2 then
            arm2 = CreateSlider(self, 'Arm02')
            self.ArmSlider2 = arm2
            trash:Add(arm2)
        end
    end,

    MovingArmsThread = function(self)
        TAirFactoryUnit.MovingArmsThread(self)
        local arm1 = self.ArmSlider1
        local arm2 = self.ArmSlider2

        while true do
            if not arm1 then return end
            if not arm2 then return end
            arm1:SetGoal(0, -6, 0)
            arm1:SetSpeed(20)
            arm2:SetGoal(0, 6, 0)
            arm2:SetSpeed(20)
            WaitFor(arm2)
            arm1:SetGoal(0, 0, 0)
            arm1:SetSpeed(20)
            arm2:SetGoal(0, 0, 0)
            arm2:SetSpeed(20)
            WaitFor(arm2)
        end
    end,

    StopArmsMoving = function(self)
        TAirFactoryUnit.StopArmsMoving(self)
        local arm1 = self.ArmSlider1
        local arm2 = self.ArmSlider2

        if not arm1 then return end
        if not arm2 then return end
        arm1:SetGoal(0, 0, 0)
        arm1:SetSpeed(40)
        arm2:SetGoal(0, 0, 0)
        arm2:SetSpeed(40)
    end,
}

TypeClass = ZEB9502
