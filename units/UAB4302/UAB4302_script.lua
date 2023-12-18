-- File     :  /cdimage/units/UAB4302/UAB4302_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Aeon Strategic Missile Defense Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit
local AAMSaintWeapon = import("/lua/aeonweapons.lua").AAMSaintWeapon
local nukeFiredOnGotTarget = false

-- upvalue for perfomance
local WaitSeconds = WaitSeconds
local ForkThread = ForkThread
local TrashBagAdd = TrashBag.Add

---@class UAB4302 : AStructureUnit
UAB4302 = ClassUnit(AStructureUnit) {
    Weapons = {
        MissileRack = ClassWeapon(AAMSaintWeapon) {
            IdleState = State(AAMSaintWeapon.IdleState) {

                OnGotTarget = function(self)
                    local bp = self.Blueprint
                    local unit = self.unit

                    if (bp.WeaponUnpackLockMotion != true or (bp.WeaponUnpackLocksMotion == true and not unit:IsUnitState('Moving'))) then
                        if (bp.CountedProjectile == false) or self:CanFire() then
                             nukeFiredOnGotTarget = true
                        end
                    end
                    AAMSaintWeapon.IdleState.OnGotTarget(self)
                end,

                OnFire = function(self)
                    local unit = self.unit
                    local bp = unit.Blueprint
                    local trash = self.Trash

                    if not nukeFiredOnGotTarget then
                        AAMSaintWeapon.IdleState.OnFire(self)
                    end
                    nukeFiredOnGotTarget = false

                    TrashBagAdd(trash,ForkThread(function()
                        unit:SetBusy(true)
                        WaitSeconds(1/bp.Weapon[1].RateOfFire + .2)
                        unit:SetBusy(false)
                    end,self))
                end,
            },
        },
    },
}

TypeClass = UAB4302