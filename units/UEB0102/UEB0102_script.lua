--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB0102/UEB0102_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  UEF T1 Air Factory Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TAirFactoryUnit = import("/lua/terranunits.lua").TAirFactoryUnit

-- Upvalue for Performance
local TrashBagAdd = TrashBag.Add
local WaitFor = WaitFor

---@class UEB0102 : TAirFactoryUnit
UEB0102 = ClassUnit(TAirFactoryUnit) {

    StartArmsMoving = function(self)
        TAirFactoryUnit.StartArmsMoving(self)
        local armSlider = self.ArmSlider
        local trash = self.Trash

        if not armSlider then
            armSlider = CreateSlider(self, 'Arm01')
            TrashBagAdd(trash,armSlider)
        end
    end,

    MovingArmsThread = function(self)
        TAirFactoryUnit.MovingArmsThread(self)
        local armSlider = self.ArmSlider

        while true do
            if not armSlider then return end
            armSlider:SetGoal(0, 6, 0)
            armSlider:SetSpeed(20)
            WaitFor(armSlider)
            armSlider:SetGoal(0, -6, 0)
            WaitFor(armSlider)
        end
    end,

    StopArmsMoving = function(self)
        TAirFactoryUnit.StopArmsMoving(self)
        local armSlider = self.ArmSlider

        if not armSlider then return end
        armSlider:SetGoal(0, 0, 0)
        armSlider:SetSpeed(40)
    end,
}

TypeClass = UEB0102
