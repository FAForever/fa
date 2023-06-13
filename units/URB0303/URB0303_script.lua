--****************************************************************************
--**
--**  File     :  /cdimage/units/URB0303/URB0303_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Cybran T3 Naval Factory Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CSeaFactoryUnit = import("/lua/cybranunits.lua").CSeaFactoryUnit


---@class URB0303 : CSeaFactoryUnit
URB0303 = ClassUnit(CSeaFactoryUnit) {
    StartArmsMoving = function(self)
        CSeaFactoryUnit.StartArmsMoving(self)
        if not self.ArmSlider1 then
            self.ArmSlider1 = CreateSlider(self, 'Right_Arm03')
            self.Trash:Add(self.ArmSlider1)
        end
        if not self.ArmSlider2 then
            self.ArmSlider2 = CreateSlider(self, 'Right_Arm02')
            self.Trash:Add(self.ArmSlider2)
        end
        if not self.ArmSlider3 then
            self.ArmSlider3 = CreateSlider(self, 'Right_Arm01')
            self.Trash:Add(self.ArmSlider3)
        end
    end,

    MovingArmsThread = function(self)
        CSeaFactoryUnit.MovingArmsThread(self)
        if not self.ArmSlider1 then return end
        if not self.ArmSlider2 then return end
        if not self.ArmSlider3 then return end
        local dir = 1
        self.ArmSlider1:SetGoal(-10, 0, 0)
        self.ArmSlider1:SetSpeed(40)
        self.ArmSlider2:SetGoal(20, 0, 0)
        self.ArmSlider2:SetSpeed(40)
        self.ArmSlider3:SetGoal(50, 0, 0)
        self.ArmSlider3:SetSpeed(60)
        WaitFor(self.ArmSlider1)
        while true do
            self.ArmSlider1:SetGoal(0, 0, 0)
            self.ArmSlider1:SetSpeed(40)
            self.ArmSlider2:SetGoal(0, 0, 0)
            self.ArmSlider2:SetSpeed(40)
            self.ArmSlider3:SetGoal(0, 0, 0)
            self.ArmSlider3:SetSpeed(40)
            WaitFor(self.ArmSlider3)
            self.ArmSlider1:SetGoal(-10, 0, 0)
            self.ArmSlider1:SetSpeed(40)
            self.ArmSlider2:SetGoal(20 + 30 * dir, 0, 0)
            self.ArmSlider2:SetSpeed(60)
            self.ArmSlider3:SetGoal(50, 0, 0)
            self.ArmSlider3:SetSpeed(60)
            WaitFor(self.ArmSlider3)
            dir = dir * -1
        end
    end,

    StopArmsMoving = function(self)
        CSeaFactoryUnit.StopArmsMoving(self)
        if not self.ArmSlider1 then return end
        if not self.ArmSlider2 then return end
        if not self.ArmSlider3 then return end

        self.ArmSlider1:SetGoal(0, 0, 0)
        self.ArmSlider2:SetGoal(0, 0, 0)
        self.ArmSlider3:SetGoal(0, 0, 0)
        self.ArmSlider1:SetSpeed(40)
        self.ArmSlider2:SetSpeed(40)
        self.ArmSlider3:SetSpeed(40)
    end,
}

TypeClass = URB0303
