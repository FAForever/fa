-- File     :  /cdimage/units/XSB4302/XSB4302_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix, Matt Vainio
-- Summary  :  Seraphim Strategic Missile Defense Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------
local SStructureUnit = import("/lua/seraphimunits.lua").SStructureUnit
local SIFHuAntiNukeWeapon = import("/lua/seraphimweapons.lua").SIFHuAntiNukeWeapon
local nukeFiredOnGotTarget = false

---@class XSB4302 : SStructureUnit
XSB4302 = ClassUnit(SStructureUnit) {

    Weapons = {
        MissileRack = ClassWeapon(SIFHuAntiNukeWeapon) {

            IdleState = State(SIFHuAntiNukeWeapon.IdleState) {

                OnGotTarget = function(self)
                    local bp = self.Blueprint
                    if (bp.WeaponUnpackLockMotion != true or (bp.WeaponUnpackLocksMotion == true and not self.unit:IsUnitState('Moving'))) then
                        if (bp.CountedProjectile == false) or self:CanFire() then
                             nukeFiredOnGotTarget = true
                        end
                    end
                    SIFHuAntiNukeWeapon.IdleState.OnGotTarget(self)
                end,

                OnFire = function(self)
                    if not nukeFiredOnGotTarget then
                        SIFHuAntiNukeWeapon.IdleState.OnFire(self)
                    end
                    nukeFiredOnGotTarget = false

                    self.Trash:Add(ForkThread(function()
                        self.unit:SetBusy(true)
                        WaitSeconds(1/self.unit.Blueprint.Weapon[1].RateOfFire + .2)
                        self.unit:SetBusy(false)
                    end,self))
                end,
            },
        },
    },
}

TypeClass = XSB4302