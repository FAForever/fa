-- File     :  /cdimage/units/UEB0303/UEB0303_script.lua
-- Author(s):  David Tomandl
-- Summary  :  UEF Tier 3 Naval Factory Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local TSeaFactoryUnit = import("/lua/terranunits.lua").TSeaFactoryUnit

---@class UEB0303 : TSeaFactoryUnit
UEB0303 = ClassUnit(TSeaFactoryUnit) {
    OnCreate = function(self)
        TSeaFactoryUnit.OnCreate(self)
        self.BuildPointSlider = CreateSlider(self, self.Blueprint.Display.BuildAttachBone or 0, -15, 0, 0, -1)
        self.Trash:Add(self.BuildPointSlider)
    end,

    StartArmsMoving = function(self)
        TSeaFactoryUnit.StartArmsMoving(self)
        local arm1 = self.ArmSlider1
        local arm2 = self.ArmSlider2
        local arm3 = self.ArmSlider3
        local Trash = self.Trash

        if not arm1 then
            arm1 = CreateSlider(self, 'Right_Arm')
            Trash:Add(arm1)
        end
        if not arm2 then
            arm2 = CreateSlider(self, 'Center_Arm')
            Trash:Add(arm2)
        end
        if not arm3 then
            arm3 = CreateSlider(self, 'Left_Arm')
            Trash:Add(arm3)
        end
    end,

    MovingArmsThread = function(self)
        TSeaFactoryUnit.MovingArmsThread(self)
        local dir = 1
        local arm1 = self.ArmSlider1
        local arm2 = self.ArmSlider2
        local arm3 = self.ArmSlider3
        local WaitFor = WaitFor

        if not arm1 then return end
        if not arm2 then return end
        arm1:SetGoal(0, 0, 0)
        arm1:SetSpeed(40)
        arm2:SetGoal(10, 0, 0)
        arm2:SetSpeed(40)
        arm3:SetGoal(20, 0, 0)
        arm3:SetSpeed(40)
        WaitFor(arm1)
        while true do
            arm1:SetGoal(0, 0, 0)
            arm1:SetSpeed(40)
            arm2:SetGoal(8 + 5 * dir, 0, 0)
            arm2:SetSpeed(40)
            arm3:SetGoal(10, 0, 0)
            arm3:SetSpeed(40)
            WaitFor(arm3)
            arm1:SetGoal(10, 0, 0)
            arm1:SetSpeed(40)
            arm2:SetGoal(10, 0, 0)
            arm2:SetSpeed(40)
            arm3:SetGoal(20, 0, 0)
            arm3:SetSpeed(40)
            WaitFor(arm3)
            dir = dir * -1
        end
    end,

    StopArmsMoving = function(self)
        TSeaFactoryUnit.StopArmsMoving(self)
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

TypeClass = UEB0303
