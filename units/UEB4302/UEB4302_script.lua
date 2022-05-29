#****************************************************************************
#**
#**  File     :  /cdimage/units/UEB4302/UEB4302_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  UEF Strategic Missile Defense Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local TStructureUnit = import('/lua/terranunits.lua').TStructureUnit
local TAMInterceptorWeapon = import('/lua/terranweapons.lua').TAMInterceptorWeapon
local nukeFiredOnGotTarget = false

UEB4302 = Class(TStructureUnit) {
    Weapons = {
        AntiNuke = Class(TAMInterceptorWeapon) {
            IdleState = State(TAMInterceptorWeapon.IdleState) {
                OnGotTarget = function(self)
                    local bp = self:GetBlueprint()
                    #only say we've fired if the parent fire conditions are met
                    if (bp.WeaponUnpackLockMotion != true or (bp.WeaponUnpackLocksMotion == true and not self.unit:IsUnitState('Moving'))) then
                        if (bp.CountedProjectile == false) or self:CanFire() then
                             nukeFiredOnGotTarget = true
                        end
                    end
                    TAMInterceptorWeapon.IdleState.OnGotTarget(self)
                end,
                # uses OnGotTarget, so we shouldn't do this.
                OnFire = function(self)
                    if not nukeFiredOnGotTarget then
                        TAMInterceptorWeapon.IdleState.OnFire(self)
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

TypeClass = UEB4302