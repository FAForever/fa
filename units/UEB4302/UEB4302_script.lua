--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB4302/UEB4302_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Strategic Missile Defense Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit
local TAMInterceptorWeapon = import("/lua/terranweapons.lua").TAMInterceptorWeapon
local nukeFiredOnGotTarget = false

-- upvalue for performance
local WaitSeconds = WaitSeconds
local ForkThread = ForkThread
local TrashBagAdd = TrashBag.Add



---@class UEB4302 : TStructureUnit
UEB4302 = ClassUnit(TStructureUnit) {
    Weapons = {
        AntiNuke = ClassWeapon(TAMInterceptorWeapon) {
            IdleState = State(TAMInterceptorWeapon.IdleState) {
                OnGotTarget = function(self)
                    local bp = self.Blueprint
                    local unit = self.unit
                    --only say we've fired if the parent fire conditions are met
                    if (bp.WeaponUnpackLockMotion != true or (bp.WeaponUnpackLocksMotion == true and not unit:IsUnitState('Moving'))) then
                        if (bp.CountedProjectile == false) or self:CanFire() then
                             nukeFiredOnGotTarget = true
                        end
                    end
                    TAMInterceptorWeapon.IdleState.OnGotTarget(self)
                end,
                -- uses OnGotTarget, so we shouldn't do this.
                OnFire = function(self)
                    local bp = self.Blueprint
                    local unit = self.unit
                    local trash = self.Trash

                    if not nukeFiredOnGotTarget then
                        TAMInterceptorWeapon.IdleState.OnFire(self)
                    end
                    nukeFiredOnGotTarget = false

                    TrashBagAdd(trash,ForkThread(function()
                        unit:SetBusy(true)
                        WaitSeconds(1/unit.bp.Weapon[1].RateOfFire + .2)
                        unit:SetBusy(false)
                    end,self))
                end,
            },
        },
    },
}

TypeClass = UEB4302