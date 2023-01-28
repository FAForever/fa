-- File     :  /cdimage/units/URB4302/URB4302_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Strategic Missile Defense Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit
local CAMEMPMissileWeapon = import("/lua/cybranweapons.lua").CAMEMPMissileWeapon
local EffectTemplate = import("/lua/effecttemplates.lua")
local nukeFiredOnGotTarget = false

---@class URB4302 : CStructureUnit
URB4302 = ClassUnit(CStructureUnit) {
    Weapons = {
        MissileRack = ClassWeapon(CAMEMPMissileWeapon) {
            FxMuzzleFlash = EffectTemplate.CAntiNukeLaunch01,

            IdleState = State(CAMEMPMissileWeapon.IdleState) {
                OnGotTarget = function(self)
                    local bp = self.Blueprint
                    if (bp.WeaponUnpackLockMotion != true or (bp.WeaponUnpackLocksMotion == true and not self.unit:IsUnitState('Moving'))) then
                        if (bp.CountedProjectile == false) or self:CanFire() then
                             nukeFiredOnGotTarget = true
                        end
                    end
                    CAMEMPMissileWeapon.IdleState.OnGotTarget(self)
                end,

                OnFire = function(self)
                    if not nukeFiredOnGotTarget then
                        CAMEMPMissileWeapon.IdleState.OnFire(self)
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

TypeClass = URB4302