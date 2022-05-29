#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB4302/UAB4302_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Aeon Strategic Missile Defense Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AStructureUnit = import('/lua/aeonunits.lua').AStructureUnit
local AAMSaintWeapon = import('/lua/aeonweapons.lua').AAMSaintWeapon
local nukeFiredOnGotTarget = false

UAB4302 = Class(AStructureUnit) {

    Weapons = {
        MissileRack = Class(AAMSaintWeapon) {
            IdleState = State(AAMSaintWeapon.IdleState) {
                OnGotTarget = function(self)
                    local bp = self:GetBlueprint()
                    #only say we've fired if the parent fire conditions are met
                    if (bp.WeaponUnpackLockMotion != true or (bp.WeaponUnpackLocksMotion == true and not self.unit:IsUnitState('Moving'))) then
                        if (bp.CountedProjectile == false) or self:CanFire() then
                             nukeFiredOnGotTarget = true
                        end
                    end
                    AAMSaintWeapon.IdleState.OnGotTarget(self)
                end,
                # uses OnGotTarget, so we shouldn't do this.
                OnFire = function(self)
                    if not nukeFiredOnGotTarget then
                        AAMSaintWeapon.IdleState.OnFire(self)
                    end
                    nukeFiredOnGotTarget = false
                    
                    self:ForkThread(function()
                        self.unit:SetBusy(true)
                        WaitSeconds(1/self.unit:GetBlueprint().Weapon[1].RateOfFire + .2)
                        self.unit:SetBusy(false)
                    end)
                end,
            },
        },
    },
}

TypeClass = UAB4302