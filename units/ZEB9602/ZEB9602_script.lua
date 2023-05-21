-- File     :  /cdimage/units/ZEB9602/ZEB9602_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  UEF T3 Air Factory Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local TAirFactoryUnit = import("/lua/terranunits.lua").TAirFactoryUnit

---@class ZEB9602 : TAirFactoryUnit
ZEB9602 = ClassUnit(TAirFactoryUnit) {

    StartArmsMoving = function(self)
        TAirFactoryUnit.StartArmsMoving(self)


        if not self.ArmSlider1 then
            self.ArmSlider1 = CreateSlider(self, 'Arm01')
            self.Trash:Add(self.ArmSlider1)
        end
        if not self.ArmSlider2 then
            self.ArmSlider2 = CreateSlider(self, 'Arm02')
            self.Trash:Add(self.ArmSlider2)
        end
        if not self.ArmSlider3 then
            self.ArmSlider3 = CreateSlider(self, 'Arm03')
            self.Trash:Add(self.ArmSlider3)
        end
    end,

    MovingArmsThread = function(self)
        TAirFactoryUnit.MovingArmsThread(self)
        local dir = 1
        while true do
            if not self.ArmSlider1 then return end
            if not self.ArmSlider2 then return end
            if not self.ArmSlider3 then return end
            self.ArmSlider1:SetGoal(0, -5, 0)
            self.ArmSlider1:SetSpeed(20)
            self.ArmSlider2:SetGoal(0, 2 * dir, 0)
            self.ArmSlider2:SetSpeed(10)
            self.ArmSlider3:SetGoal(0, 5, 0)
            self.ArmSlider3:SetSpeed(20)
            WaitFor(self.ArmSlider3)
            self.ArmSlider1:SetGoal(0, 0, 0)
            self.ArmSlider1:SetSpeed(20)
            self.ArmSlider2:SetGoal(0, 0, 0)
            self.ArmSlider2:SetSpeed(10)
            self.ArmSlider3:SetGoal(0, 0, 0)
            self.ArmSlider3:SetSpeed(20)
            WaitFor(self.ArmSlider3)
            dir = dir * -1
        end
    end,

    StopArmsMoving = function(self)
        TAirFactoryUnit.StopArmsMoving(self)
        self.ArmSlider1:SetGoal(0, 0, 0)
        self.ArmSlider2:SetGoal(0, 0, 0)
        self.ArmSlider3:SetGoal(0, 0, 0)
        self.ArmSlider1:SetSpeed(40)
        self.ArmSlider2:SetSpeed(40)
        self.ArmSlider3:SetSpeed(40)
    end,
}

TypeClass = ZEB9602
