-- File     :  /cdimage/units/XSS0203/XSS0203_script.lua
-- Summary  :  Seraphim Attack Sub Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local SSubUnit = import("/lua/seraphimunits.lua").SSubUnit
local SWeapons = import("/lua/seraphimweapons.lua")
local SANUallCavitationTorpedo = SWeapons.SANUallCavitationTorpedo
local SDFOhCannon = SWeapons.SDFOhCannon02
local SDFAjelluAntiTorpedoDefense = SWeapons.SDFAjelluAntiTorpedoDefense

---@class XSS0203 : SSubUnit
XSS0203 = ClassUnit(SSubUnit) {
    DeathThreadDestructionWaitTime = 0,
    Weapons = {
        Torpedo01 = ClassWeapon(SANUallCavitationTorpedo) {},
        Cannon = ClassWeapon(SDFOhCannon) {},
        AntiTorpedo = ClassWeapon(SDFAjelluAntiTorpedoDefense) {},
    },

    OnStopBeingBuilt = function(self, builder, layer)
        SSubUnit.OnStopBeingBuilt(self, builder, layer)
        if layer == 'Water' then
            ChangeState(self, self.CannonEnabled)
        else
            ChangeState(self, self.CannonDisabled)
        end
    end,

    OnLayerChange = function(self, new, old)
        SSubUnit.OnLayerChange(self, new, old)
        if new == 'Sub' then
            ChangeState(self, self.CannonDisabled)
        elseif new == 'Water' then
            ChangeState(self, self.CannonEnabled)
        end
    end,

    CannonEnabled = State() {
        Main = function(self)
            local cannonAnim = self.CannonAnim
            if not cannonAnim then
                cannonAnim = CreateAnimator(self)
                self.CannonAnim = cannonAnim
                self.Trash:Add(cannonAnim)
            end
            local bp = self.Blueprint
            cannonAnim:PlayAnim(bp.Display.CannonOpenAnimation)
            cannonAnim:SetRate(bp.Display.CannonOpenRate or 1)
            WaitFor(cannonAnim)
            self:SetWeaponEnabledByLabel('Cannon', true)
        end,
    },

    CannonDisabled = State() {
        Main = function(self)
            self:SetWeaponEnabledByLabel('Cannon', false)
            if self.CannonAnim then
                local bp = self.Blueprint
                self.CannonAnim:SetRate(-1 * (bp.Display.CannonOpenRate or 1))
                WaitFor(self.CannonAnim)
            end
        end,
    },
}
TypeClass = XSS0203
