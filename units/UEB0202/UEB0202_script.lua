--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB0202/UEB0202_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  UEF T2 Air Factory Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TAirFactoryUnit = import("/lua/terranunits.lua").TAirFactoryUnit

-- Upvalue for Performance
local TrashBagAdd = TrashBag.Add
local WaitFor = WaitFor


---@class UEB0202 : TAirFactoryUnit
UEB0202 = ClassUnit(TAirFactoryUnit) {

    StartArmsMoving = function(self)
        TAirFactoryUnit.StartArmsMoving(self)
        local trash = self.Trash
        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2

        if not armSlider1 then
            armSlider1 = CreateSlider(self, 'Arm01')
            TrashBagAdd(trash,armSlider1)
        end
        if not armSlider2 then
            armSlider2 = CreateSlider(self, 'Arm02')
            TrashBagAdd(trash,armSlider2)
        end
    end,

    MovingArmsThread = function(self)
        TAirFactoryUnit.MovingArmsThread(self)
        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2

        while true do
            if not armSlider1 then return end
            if not armSlider2 then return end
            armSlider1:SetGoal(0, -6, 0)
            armSlider1:SetSpeed(20)
            armSlider2:SetGoal(0, 6, 0)
            armSlider2:SetSpeed(20)
            WaitFor(armSlider2)
            armSlider1:SetGoal(0, 0, 0)
            armSlider1:SetSpeed(20)
            armSlider2:SetGoal(0, 0, 0)
            armSlider2:SetSpeed(20)
            WaitFor(armSlider2)
        end
    end,

    StopArmsMoving = function(self)
        TAirFactoryUnit.StopArmsMoving(self)
        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2

        if not armSlider1 then return end
        if not armSlider2 then return end
        armSlider1:SetGoal(0, 0, 0)
        armSlider1:SetSpeed(40)
        armSlider2:SetGoal(0, 0, 0)
        armSlider2:SetSpeed(40)
    end,
}

TypeClass = UEB0202
