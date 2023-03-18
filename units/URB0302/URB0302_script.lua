--****************************************************************************
--**
--**  File     :  /cdimage/units/URB0302/URB0302_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  Cybran Tier 3 Air Unit Factory Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local CAirFactoryUnit = import("/lua/cybranunits.lua").CAirFactoryUnit

---@class URB0302 : CAirFactoryUnit
URB0302 = Class(CAirFactoryUnit) {
    PlatformBone = 'B01',

    FinishBuildThread = function(self, unitBeingBuilt, order)
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        local bp = self.Blueprint
        local bpAnim = bp.Display.AnimationFinishBuildLand
        if bpAnim and EntityCategoryContains(categories.LAND, unitBeingBuilt) then
            self.RollOffAnim = CreateAnimator(self):PlayAnim(bpAnim):SetRate(40)
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

    PlayFxRollOffEnd = function(self)
        if self.RollOffAnim then
            self.RollOffAnim:SetRate(40)
            WaitFor(self.RollOffAnim)
            self.RollOffAnim:Destroy()
            self.RollOffAnim = nil
        end
    end,
}

TypeClass = URB0302
