#****************************************************************************
#**
#**  File     :  /cdimage/units/URB0103/URB0103_script.lua
#**  Author(s):  David Tomandl
#**
#**  Summary  :  Cybran T1 Naval Factory Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CSeaFactoryUnit = import('/lua/cybranunits.lua').CSeaFactoryUnit
URB0103 = Class(CSeaFactoryUnit) {

    StartArmsMoving = function(self)
        CSeaFactoryUnit.StartArmsMoving(self)
        if not self.ArmSlider then
            self.ArmSlider = CreateSlider(self, 'Right_Arm03')
            self.Trash:Add(self.ArmSlider)
        end
        
    end,

    MovingArmsThread = function(self)
        CSeaFactoryUnit.MovingArmsThread(self)
        while true do
            if not self.ArmSlider then return end
            self.ArmSlider:SetGoal(40, 0, 0)
            self.ArmSlider:SetSpeed(40)
            WaitFor(self.ArmSlider)
            self.ArmSlider:SetGoal(-30, 0, 0)
            WaitFor(self.ArmSlider)
        end
    end,
    
    StopArmsMoving = function(self)
        CSeaFactoryUnit.StopArmsMoving(self)
        self.ArmSlider:SetGoal(0, 0, 0)
        self.ArmSlider:SetSpeed(40)
    end,
}

TypeClass = URB0103