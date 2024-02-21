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

-- upvalue for perfomance
local CreateSlider = CreateSlider
local WaitFor = WaitFor
local TrashBagAdd = TrashBag.Add


---@class UEB0303 : TSeaFactoryUnit
UEB0303 = ClassUnit(TSeaFactoryUnit) {
    OnCreate = function(self)
        TSeaFactoryUnit.OnCreate(self)
        local trash = self.Trash
        local bp = self.Blueprint

        self.BuildPointSlider = CreateSlider(self, bp.Display.BuildAttachBone or 0, -15, 0, 0, -1)
        TrashBagAdd(trash,self.BuildPointSlider)
    end,


    StartArmsMoving = function(self)
        TSeaFactoryUnit.StartArmsMoving(self)
        local trash = self.Trash
        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2
        local armSlider3 = self.ArmSlider3

        if not armSlider1 then
            armSlider1 = CreateSlider(self, 'Right_Arm')
            TrashBagAdd(trash,armSlider1)
        end
        if not armSlider2 then
            armSlider2 = CreateSlider(self, 'Center_Arm')
            TrashBagAdd(trash,armSlider2)
        end
        if not armSlider3 then
            armSlider3 = CreateSlider(self, 'Left_Arm')
            TrashBagAdd(trash,armSlider3)
        end
    end,

    MovingArmsThread = function(self)
        TSeaFactoryUnit.MovingArmsThread(self)
        local dir = 1
        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2
        local armSlider3 = self.ArmSlider3

        if not armSlider1 then return end
        if not armSlider2 then return end
        armSlider1:SetGoal(0, 0, 0)
        armSlider1:SetSpeed(40)
        armSlider2:SetGoal(10, 0, 0)
        armSlider2:SetSpeed(40)
        armSlider3:SetGoal(20, 0, 0)
        armSlider3:SetSpeed(40)
        WaitFor(armSlider1)
        while true do
            armSlider1:SetGoal(0, 0, 0)
            armSlider1:SetSpeed(40)
            armSlider2:SetGoal(8 + 5 * dir, 0, 0)
            armSlider2:SetSpeed(40)
            armSlider3:SetGoal(10, 0, 0)
            armSlider3:SetSpeed(40)
            WaitFor(armSlider3)
            armSlider1:SetGoal(10, 0, 0)
            armSlider1:SetSpeed(40)
            armSlider2:SetGoal(10, 0, 0)
            armSlider2:SetSpeed(40)
            armSlider3:SetGoal(20, 0, 0)
            armSlider3:SetSpeed(40)
            WaitFor(armSlider3)
            dir = dir * -1
        end
    end,

    StopArmsMoving = function(self)
        TSeaFactoryUnit.StopArmsMoving(self)
        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2
        local armSlider3 = self.ArmSlider3

        armSlider1:SetGoal(0, 0, 0)
        armSlider2:SetGoal(0, 0, 0)
        armSlider3:SetGoal(0, 0, 0)
        armSlider1:SetSpeed(40)
        armSlider2:SetSpeed(40)
        armSlider3:SetSpeed(40)
    end,
}

TypeClass = UEB0303
