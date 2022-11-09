--****************************************************************************
--**
--**  File     :  /cdimage/units/ZRB9502/ZRB9502_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  Cybran Tier 2 Air Unit Factory Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local CAirFactoryUnit = import("/lua/cybranunits.lua").CAirFactoryUnit

---@class ZRB9502 : CAirFactoryUnit
ZRB9502 = Class(CAirFactoryUnit) {
    PlatformBone = 'B01',
    UpgradeRevealArm1 = 'Arm03',
    UpgradeRevealArm2 = 'Arm06',
    UpgradeBuilderArm1 = 'Arm03_B02',
    UpgradeBuilderArm2 = 'Arm04_B02',

--Overwrite FinishBuildThread to speed up platform lowering rate

    FinishBuildThread = function(self, unitBeingBuilt, order)
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        local bp = self:GetBlueprint()
        local bpAnim = bp.Display.AnimationFinishBuildLand
        if bpAnim and EntityCategoryContains(categories.LAND, unitBeingBuilt) then
            self.RollOffAnim = CreateAnimator(self):PlayAnim(bpAnim):SetRate(40)        --Change: SetRate(4)
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
            self.RollOffAnim:SetRate(40)                                            --Change: SetRate(-4)
            WaitFor(self.RollOffAnim)
            self.RollOffAnim:Destroy()
            self.RollOffAnim = nil
        end
    end,
}
TypeClass = ZRB9502
