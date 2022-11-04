--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB0102/UEB0102_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  UEF T1 Air Factory Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TAirFactoryUnit = import("/lua/terranunits.lua").TAirFactoryUnit

---@class UEB0102 : TAirFactoryUnit
UEB0102 = Class(TAirFactoryUnit) {
    
    StartArmsMoving = function(self)
        TAirFactoryUnit.StartArmsMoving(self)
        --local unitBldg = self.UnitBeingBuilt
        if not self.ArmSlider then
            self.ArmSlider = CreateSlider(self, 'Arm01')
            self.Trash:Add(self.ArmSlider)
        end
        
    end,

    MovingArmsThread = function(self)
        TAirFactoryUnit.MovingArmsThread(self)
        while true do
            if not self.ArmSlider then return end
            self.ArmSlider:SetGoal(0, 6, 0)
            self.ArmSlider:SetSpeed(20)
            WaitFor(self.ArmSlider)
            self.ArmSlider:SetGoal(0, -6, 0)
            WaitFor(self.ArmSlider)
        end
    end,
    
    StopArmsMoving = function(self)
        TAirFactoryUnit.StopArmsMoving(self)
        if not self.ArmSlider then return end
        self.ArmSlider:SetGoal(0, 0, 0)
        self.ArmSlider:SetSpeed(40)
    end,


--Overwrite FinishBuildThread to speed up platform lowering rate

    FinishBuildThread = function(self, unitBeingBuilt, order)
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        local bp = self:GetBlueprint()
        local bpAnim = bp.Display.AnimationFinishBuildLand
        if bpAnim and EntityCategoryContains(categories.LAND, unitBeingBuilt) then
            self.RollOffAnim = CreateAnimator(self):PlayAnim(bpAnim):SetRate(10)        --Change: SetRate(4)
            self.Trash:Add(self.RollOffAnim)
            WaitTicks(1)
            WaitFor(self.RollOffAnim)
        end
        if unitBeingBuilt and not unitBeingBuilt.Dead then
            unitBeingBuilt:DetachFrom(true)
        end
        self:DetachAll(bp.Display.BuildAttachBone or 0)
        self:DestroyBuildRotator()
        if order != 'Upgrade' then
            ChangeState(self, self.RollingOffState)
        else
            self:SetBusy(false)
            self:SetBlockCommandQueue(false)
        end
    end,

--Overwrite PlayFxRollOffEnd to speed up platform raising rate

    PlayFxRollOffEnd = function(self)
        if self.RollOffAnim then
            self.RollOffAnim:SetRate(10)                                            --Change: SetRate(-4)
            WaitFor(self.RollOffAnim)
            self.RollOffAnim:Destroy()
            self.RollOffAnim = nil
        end
    end,
}

TypeClass = UEB0102
