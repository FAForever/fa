--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB0303/UEB0303_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  UEF Tier 3 Naval Factory Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TSeaFactoryUnit = import("/lua/terranunits.lua").TSeaFactoryUnit

---@class UEB0303 : TSeaFactoryUnit
UEB0303 = ClassUnit(TSeaFactoryUnit) {
    OnCreate = function(self)
        TSeaFactoryUnit.OnCreate(self)
        self.BuildPointSlider = CreateSlider(self, self:GetBlueprint().Display.BuildAttachBone or 0, -15, 0, 0, -1)
        self.Trash:Add(self.BuildPointSlider)
    end,


    StartArmsMoving = function(self)
        TSeaFactoryUnit.StartArmsMoving(self)
        if not self.ArmSlider1 then
            self.ArmSlider1 = CreateSlider(self, 'Right_Arm')
            self.Trash:Add(self.ArmSlider1)
        end
        if not self.ArmSlider2 then
            self.ArmSlider2 = CreateSlider(self, 'Center_Arm')
            self.Trash:Add(self.ArmSlider2)
        end
        if not self.ArmSlider3 then
            self.ArmSlider3 = CreateSlider(self, 'Left_Arm')
            self.Trash:Add(self.ArmSlider3)
        end
    end,

    MovingArmsThread = function(self)
        TSeaFactoryUnit.MovingArmsThread(self)
        local dir = 1
        if not self.ArmSlider1 then return end
        if not self.ArmSlider2 then return end
        self.ArmSlider1:SetGoal(0, 0, 0)
        self.ArmSlider1:SetSpeed(40)
        self.ArmSlider2:SetGoal(10, 0, 0)
        self.ArmSlider2:SetSpeed(40)
        self.ArmSlider3:SetGoal(20, 0, 0)
        self.ArmSlider3:SetSpeed(40)
        WaitFor(self.ArmSlider1)
        while true do
            self.ArmSlider1:SetGoal(0, 0, 0)
            self.ArmSlider1:SetSpeed(40)
            self.ArmSlider2:SetGoal(8 + 5 * dir, 0, 0)
            self.ArmSlider2:SetSpeed(40)
            self.ArmSlider3:SetGoal(10, 0, 0)
            self.ArmSlider3:SetSpeed(40)
            WaitFor(self.ArmSlider3)
            self.ArmSlider1:SetGoal(10, 0, 0)
            self.ArmSlider1:SetSpeed(40)
            self.ArmSlider2:SetGoal(10, 0, 0)
            self.ArmSlider2:SetSpeed(40)
            self.ArmSlider3:SetGoal(20, 0, 0)
            self.ArmSlider3:SetSpeed(40)
            WaitFor(self.ArmSlider3)
            dir = dir * -1
        end
    end,

    StopArmsMoving = function(self)
        TSeaFactoryUnit.StopArmsMoving(self)
        self.ArmSlider1:SetGoal(0, 0, 0)
        self.ArmSlider2:SetGoal(0, 0, 0)
        self.ArmSlider3:SetGoal(0, 0, 0)
        self.ArmSlider1:SetSpeed(40)
        self.ArmSlider2:SetSpeed(40)
        self.ArmSlider3:SetSpeed(40)
    end,
}

TypeClass = UEB0303
