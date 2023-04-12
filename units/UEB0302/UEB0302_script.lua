-- File     :  /cdimage/units/UEB0302/UEB0302_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  UEF T3 Air Factory Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local TAirFactoryUnit = import("/lua/terranunits.lua").TAirFactoryUnit

---@class UEB0302 : TAirFactoryUnit
UEB0302 = ClassUnit(TAirFactoryUnit) {

    StartArmsMoving = function(self)
        TAirFactoryUnit.StartArmsMoving(self)
        local arm1 = self.ArmSlider1
        local arm2 = self.ArmSlider2
        local arm3 = self.ArmSlider3
        local Trash = self.Trash

        if not arm1 then
            arm1 = CreateSlider(self, 'Arm01')
            Trash:Add(arm1)
        end
        if not arm2 then
            arm2 = CreateSlider(self, 'Arm02')
            Trash:Add(arm2)
        end
        if not arm3 then
            arm3 = CreateSlider(self, 'Arm03')
            Trash:Add(arm3)
        end
    end,

    MovingArmsThread = function(self)
        TAirFactoryUnit.MovingArmsThread(self)
        local dir = 1
        local arm1 = self.ArmSlider1
        local arm2 = self.ArmSlider2
        local arm3 = self.ArmSlider3

        while true do
            if not arm1 then return end
            if not arm1 then return end
            if not arm3 then return end
            arm1:SetGoal(0, -5, 0)
            arm1:SetSpeed(20)
            arm1:SetGoal(0, 2 * dir, 0)
            arm1:SetSpeed(10)
            arm3:SetGoal(0, 5, 0)
            arm3:SetSpeed(20)
            WaitFor(arm3)
            arm1:SetGoal(0, 0, 0)
            arm1:SetSpeed(20)
            arm1:SetGoal(0, 0, 0)
            arm1:SetSpeed(10)
            arm3:SetGoal(0, 0, 0)
            arm3:SetSpeed(20)
            WaitFor(arm3)
            dir = dir * -1
        end
    end,

    StopArmsMoving = function(self)
        TAirFactoryUnit.StopArmsMoving(self)
        local arm1 = self.ArmSlider1
        local arm2 = self.ArmSlider2
        local arm3 = self.ArmSlider3

        arm1:SetGoal(0, 0, 0)
        arm2:SetGoal(0, 0, 0)
        arm3:SetGoal(0, 0, 0)
        arm1:SetSpeed(40)
        arm2:SetSpeed(40)
        arm3:SetSpeed(40)
    end,
}
TypeClass = UEB0302