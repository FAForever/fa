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

-- upvalue for perfomance
local TrashBadAdd = TrashBag.Add
local CreateSlider = CreateSlider
local WaitFor = WaitFor


---@class UEB0203 : TSeaFactoryUnit
UEB0203 = ClassUnit(TSeaFactoryUnit) {
    OnCreate = function(self)
        TSeaFactoryUnit.OnCreate(self)
        local trash = self.Trash
        local bp = self.Blueprint

        self.BuildPointSlider = CreateSlider(self, bp.Display.BuildAttachBone or 0, -5, 0, 0, -1)
        TrashBadAdd(trash,self.BuildPointSlider)
    end,

    StartArmsMoving = function(self)
        TSeaFactoryUnit.StartArmsMoving(self)
        local trash = self.Trash
        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2

        if not armSlider1 then
            armSlider1 = CreateSlider(self, 'Right_Arm')
            TrashBadAdd(trash,armSlider1)
        end
        if not armSlider2 then
            armSlider2 = CreateSlider(self, 'Center_Arm')
            TrashBadAdd(trash,armSlider2)
        end
    end,

    MovingArmsThread = function(self)
        TSeaFactoryUnit.MovingArmsThread(self)
        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2

        if not armSlider1 then return end
        if not armSlider2 then return end
        armSlider1:SetGoal(0, 0, 0)
        armSlider1:SetSpeed(40)
        armSlider2:SetGoal(30, 0, 0)
        armSlider2:SetSpeed(40)
        WaitFor(armSlider1)
        while true do
            armSlider1:SetGoal(15, 0, 0)
            armSlider1:SetSpeed(40)
            armSlider2:SetGoal(15, 0, 0)
            armSlider2:SetSpeed(40)
            WaitFor(armSlider1)
            WaitFor(armSlider2)
            armSlider1:SetGoal(0, 0, 0)
            armSlider1:SetSpeed(40)
            armSlider2:SetGoal(30, 0, 0)
            armSlider2:SetSpeed(40)
            WaitFor(armSlider1)
            WaitFor(armSlider2)
        end
    end,

    StopArmsMoving = function(self)
        TSeaFactoryUnit.StopArmsMoving(self)
        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2

        if not armSlider1 then return end
        if not armSlider2 then return end
        armSlider1:SetGoal(0, 0, 0)
        armSlider2:SetGoal(0, 0, 0)
        armSlider1:SetSpeed(40)
        armSlider2:SetSpeed(40)
    end,


}

TypeClass = UEB0203
