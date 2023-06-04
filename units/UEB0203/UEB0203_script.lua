--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB0203/UEB0203_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  UEF Tier 2 Naval Factory Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TSeaFactoryUnit = import("/lua/terranunits.lua").TSeaFactoryUnit

---@class UEB0203 : TSeaFactoryUnit
UEB0203 = ClassUnit(TSeaFactoryUnit) {
    OnCreate = function(self)
        TSeaFactoryUnit.OnCreate(self)
        self.BuildPointSlider = CreateSlider(self, self:GetBlueprint().Display.BuildAttachBone or 0, -5, 0, 0, -1)
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
    end,

    MovingArmsThread = function(self)
        TSeaFactoryUnit.MovingArmsThread(self)
        if not self.ArmSlider1 then return end
        if not self.ArmSlider2 then return end
        self.ArmSlider1:SetGoal(0, 0, 0)
        self.ArmSlider1:SetSpeed(40)
        self.ArmSlider2:SetGoal(30, 0, 0)
        self.ArmSlider2:SetSpeed(40)
        WaitFor(self.ArmSlider1)
        while true do
            self.ArmSlider1:SetGoal(15, 0, 0)
            self.ArmSlider1:SetSpeed(40)
            self.ArmSlider2:SetGoal(15, 0, 0)
            self.ArmSlider2:SetSpeed(40)
            WaitFor(self.ArmSlider1)
            WaitFor(self.ArmSlider2)
            self.ArmSlider1:SetGoal(0, 0, 0)
            self.ArmSlider1:SetSpeed(40)
            self.ArmSlider2:SetGoal(30, 0, 0)
            self.ArmSlider2:SetSpeed(40)
            WaitFor(self.ArmSlider1)
            WaitFor(self.ArmSlider2)
        end
    end,

    StopArmsMoving = function(self)
        TSeaFactoryUnit.StopArmsMoving(self)
        if not self.ArmSlider1 then return end
        if not self.ArmSlider2 then return end
        self.ArmSlider1:SetGoal(0, 0, 0)
        self.ArmSlider2:SetGoal(0, 0, 0)
        self.ArmSlider1:SetSpeed(40)
        self.ArmSlider2:SetSpeed(40)
    end,


}

TypeClass = UEB0203
