--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB0302/UEB0302_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  UEF T3 Air Factory Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TAirFactoryUnit = import("/lua/terranunits.lua").TAirFactoryUnit

-- upvalue for perfomance
local CreateSlider = CreateSlider
local WaitFor = WaitFor
local TrashBagAdd = TrashBag.Add


---@class UEB0302 : TAirFactoryUnit
UEB0302 = ClassUnit(TAirFactoryUnit) {

    RollOffAnimationRate = 12,

    StartArmsMoving = function(self)
        TAirFactoryUnit.StartArmsMoving(self)
        local trash = self.Trash
        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2
        local armSlider3 = self.ArmSlider3

        if not armSlider1 then
            armSlider1 = CreateSlider(self, 'Arm01')
            TrashBagAdd(trash, armSlider1)
        end
        if not armSlider2 then
            armSlider2 = CreateSlider(self, 'Arm02')
            TrashBagAdd(trash, armSlider2)
        end
        if not armSlider3 then
            armSlider3 = CreateSlider(self, 'Arm03')
            TrashBagAdd(trash, armSlider3)
        end
    end,

    MovingArmsThread = function(self)
        TAirFactoryUnit.MovingArmsThread(self)
        local dir = 1
        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2
        local armSlider3 = self.ArmSlider3

        while true do
            if not armSlider1 then return end
            if not armSlider2 then return end
            if not armSlider3 then return end
            armSlider1:SetGoal(0, -5, 0)
            armSlider1:SetSpeed(20)
            armSlider2:SetGoal(0, 2 * dir, 0)
            armSlider2:SetSpeed(10)
            armSlider3:SetGoal(0, 5, 0)
            armSlider3:SetSpeed(20)
            WaitFor(armSlider3)
            armSlider1:SetGoal(0, 0, 0)
            armSlider1:SetSpeed(20)
            armSlider2:SetGoal(0, 0, 0)
            armSlider2:SetSpeed(10)
            armSlider3:SetGoal(0, 0, 0)
            armSlider3:SetSpeed(20)
            WaitFor(armSlider3)
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

TypeClass = UEB0302
