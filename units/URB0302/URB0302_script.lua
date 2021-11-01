-- Automatically upvalued moho functions for performance
local CAnimationManipulatorMethods = _G.moho.AnimationManipulator
local CAnimationManipulatorMethodsSetRate = CAnimationManipulatorMethods.SetRate

local EntityMethods = _G.moho.entity_methods
local EntityMethodsDetachAll = EntityMethods.DetachAll
local EntityMethodsDetachFrom = EntityMethods.DetachFrom

local UnitMethods = _G.moho.unit_methods
local UnitMethodsSetBlockCommandQueue = UnitMethods.SetBlockCommandQueue
local UnitMethodsSetBusy = UnitMethods.SetBusy
-- End of automatically upvalued moho functions

#****************************************************************************
#**
#**  File     :  /cdimage/units/URB0302/URB0302_script.lua
#**  Author(s):  David Tomandl
#**
#**  Summary  :  Cybran Tier 3 Air Unit Factory Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local CAirFactoryUnit = import('/lua/cybranunits.lua').CAirFactoryUnit

URB0302 = Class(CAirFactoryUnit)({
    PlatformBone = 'B01',

    --Overwrite FinishBuildThread to speed up platform lowering rate

    FinishBuildThread = function(self, unitBeingBuilt, order)
        UnitMethodsSetBusy(self, true)
        UnitMethodsSetBlockCommandQueue(self, true)
        local bp = self:GetBlueprint()
        local bpAnim = bp.Display.AnimationFinishBuildLand
        if bpAnim and EntityCategoryContains(categories.LAND, unitBeingBuilt) then
            --Change: SetRate(4)
            self.RollOffAnim = CreateAnimator(self):PlayAnim(bpAnim):SetRate(40)
            self.Trash:Add(self.RollOffAnim)
            WaitTicks(1)
            WaitFor(self.RollOffAnim)
        end
        if unitBeingBuilt and not unitBeingBuilt.Dead then
            EntityMethodsDetachFrom(unitBeingBuilt, true)
        end
        EntityMethodsDetachAll(self, bp.Display.BuildAttachBone or 0)
        self:DestroyBuildRotator()
        if order ~= 'Upgrade' then
            ChangeState(self, self.RollingOffState)
        else
            UnitMethodsSetBusy(self, false)
            UnitMethodsSetBlockCommandQueue(self, false)
        end
    end,

    --Overwrite PlayFxRollOffEnd to speed up platform raising rate

    PlayFxRollOffEnd = function(self)
        if self.RollOffAnim then
            --Change: SetRate(-4)
            CAnimationManipulatorMethodsSetRate(self.RollOffAnim, 40)
            WaitFor(self.RollOffAnim)
            self.RollOffAnim:Destroy()
            self.RollOffAnim = nil
        end
    end,
})

TypeClass = URB0302
