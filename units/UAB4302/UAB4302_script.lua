-- File     :  /cdimage/units/UAB4302/UAB4302_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Aeon Strategic Missile Defense Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit
local AAMSaintWeapon = import("/lua/aeonweapons.lua").AAMSaintWeapon
local nukeFiredOnGotTarget = false

---@class UAB4302 : AStructureUnit
UAB4302 = ClassUnit(AStructureUnit) {
    Weapons = {
        MissileRack = ClassWeapon(AAMSaintWeapon) {
            IdleState = State(AAMSaintWeapon.IdleState) {
                OnGotTarget = function(self)
                    local bp = self.Blueprint
                    if (bp.WeaponUnpackLockMotion != true or (bp.WeaponUnpackLocksMotion == true and not self.unit:IsUnitState('Moving'))) then
                        if (bp.CountedProjectile == false) or self:CanFire() then
                             nukeFiredOnGotTarget = true
                        end
                    end
                    AAMSaintWeapon.IdleState.OnGotTarget(self)
                end,
                OnFire = function(self)
                    if not nukeFiredOnGotTarget then
                        AAMSaintWeapon.IdleState.OnFire(self)
                    end
                    nukeFiredOnGotTarget = false
                    
                    self.Trash:Add(ForkThread(function()
                        self.unit:SetBusy(true)
                        WaitSeconds(1/self.unit.Blueprint.Weapon[1].RateOfFire + .2)
                        self.unit:SetBusy(false)
                    end))
                end,
            },
        },
    },
}

TypeClass = UAB4302