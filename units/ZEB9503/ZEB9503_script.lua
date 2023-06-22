-- File     :  /cdimage/units/ZEB9503/ZEB9503_script.lua
-- Author(s):  David Tomandl
-- Summary  :  UEF Tier 2 Naval Factory Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local TSeaFactoryUnit = import("/lua/terranunits.lua").TSeaFactoryUnit

---@class ZEB9503 : TSeaFactoryUnit
ZEB9503 = ClassUnit(TSeaFactoryUnit) {
    OnCreate = function(self)
        TSeaFactoryUnit.OnCreate(self)
        self.BuildPointSlider = CreateSlider(self, self.Blueprint.Display.BuildAttachBone or 0, -5, 0, 0, -1)
        self.Trash:Add(self.BuildPointSlider)
    end,

    StartArmsMoving = function(self)
        TSeaFactoryUnit.StartArmsMoving(self)
        local arm1 = self.ArmSlider1
        local arm2 = self.ArmSlider2
        local Trash = self.Trash

        if not arm1 then
            arm1 = CreateSlider(self, 'Right_Arm')
            self.ArmSlider1 = arm1
            Trash:Add(arm1)
        end
        if not arm2 then
            arm2 = CreateSlider(self, 'Center_Arm')
            self.ArmSlider2 = arm2
            Trash:Add(arm2)
        end
    end,

    MovingArmsThread = function(self)
        TSeaFactoryUnit.MovingArmsThread(self)
        local arm1 = self.ArmSlider1
        local arm2 = self.ArmSlider2

        if not arm1 then return end
        if not arm2 then return end
        arm1:SetGoal(0, 0, 0)
        arm1:SetSpeed(40)
        arm2:SetGoal(30, 0, 0)
        arm2:SetSpeed(40)
        WaitFor(arm1)
        while true do
            arm1:SetGoal(15, 0, 0)
            arm1:SetSpeed(40)
            arm2:SetGoal(15, 0, 0)
            arm2:SetSpeed(40)
            WaitFor(arm1)
            WaitFor(arm2)
            arm1:SetGoal(0, 0, 0)
            arm1:SetSpeed(40)
            arm2:SetGoal(30, 0, 0)
            arm2:SetSpeed(40)
            WaitFor(arm1)
            WaitFor(arm2)
        end
    end,

    StopArmsMoving = function(self)
        TSeaFactoryUnit.StopArmsMoving(self)
        local arm1 = self.ArmSlider1
        local arm2 = self.ArmSlider2

        if not arm1 then return end
        if not arm2 then return end
        arm1:SetGoal(0, 0, 0)
        arm2:SetGoal(0, 0, 0)
        arm1:SetSpeed(40)
        arm2:SetSpeed(40)
    end,


}

TypeClass = ZEB9503
