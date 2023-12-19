--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB0103/UEB0103_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  UEF Tier 1 Naval Factory Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TSeaFactoryUnit = import("/lua/terranunits.lua").TSeaFactoryUnit

-- Upvalue for Perfomance
local TrashBadAdd = TrashBag.Add
local WaitFor = WaitFor

---@class UEB0103 : TSeaFactoryUnit
UEB0103 = ClassUnit(TSeaFactoryUnit) {
    StartArmsMoving = function(self)
        TSeaFactoryUnit.StartArmsMoving(self)
        local trash = self.Trash
        local armSlider = self.ArmSlider

        if not armSlider then
            armSlider = CreateSlider(self, 'Right_Arm')
            TrashBadAdd(trash,armSlider)
        end

    end,

    MovingArmsThread = function(self)
        TSeaFactoryUnit.MovingArmsThread(self)
        local armSlider = self.ArmSlider

        while true do
            if not armSlider then return end
            armSlider:SetGoal(0, 0, 40)
            armSlider:SetSpeed(40)
            WaitFor(armSlider)
            armSlider:SetGoal(0, 0, 0)
            WaitFor(armSlider)
        end
    end,

    StopArmsMoving = function(self)
        TSeaFactoryUnit.StopArmsMoving(self)
        local armSlider = self.ArmSlider

        if not armSlider then return end
        armSlider:SetGoal(0, 0, 0)
        armSlider:SetSpeed(40)
    end,

}

TypeClass = UEB0103
