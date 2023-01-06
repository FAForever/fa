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

---@class UEB0103 : TSeaFactoryUnit
UEB0103 = ClassUnit(TSeaFactoryUnit) {
    StartArmsMoving = function(self)
        TSeaFactoryUnit.StartArmsMoving(self)
        if not self.ArmSlider then
            self.ArmSlider = CreateSlider(self, 'Right_Arm')
            self.Trash:Add(self.ArmSlider)
        end

    end,

    MovingArmsThread = function(self)
        TSeaFactoryUnit.MovingArmsThread(self)
        while true do
            if not self.ArmSlider then return end
            self.ArmSlider:SetGoal(0, 0, 40)
            self.ArmSlider:SetSpeed(40)
            WaitFor(self.ArmSlider)
            self.ArmSlider:SetGoal(0, 0, 0)
            WaitFor(self.ArmSlider)
        end
    end,

    StopArmsMoving = function(self)
        TSeaFactoryUnit.StopArmsMoving(self)
        if not self.ArmSlider then return end
        self.ArmSlider:SetGoal(0, 0, 0)
        self.ArmSlider:SetSpeed(40)
    end,

}

TypeClass = UEB0103
