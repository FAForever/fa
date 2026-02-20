------------------------------------------------------------------
--  File     :  /units/XSA0304/XSA0304_script.lua
--  Author(s):  Drew Staltman, Greg Kohne, Gordon Duclos
--  Summary  :  Seraphim Strategic Bomber Script
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local SAirUnit = import("/lua/seraphimunits.lua").SAirUnit
local SIFBombZhanaseeWeapon = import("/lua/seraphimweapons.lua").SIFBombZhanaseeWeapon

local GetVectorLength = import("/lua/utilities.lua").GetVectorLength

---@class XSA0304 : SAirUnit
XSA0304 = ClassUnit(SAirUnit) {
    Weapons = {
        Bomb = ClassWeapon(SIFBombZhanaseeWeapon) {
            ---@param self SIFBombZhanaseeWeapon
            CreateProjectile = function(self, muzzlebone)
                local curSpeed = GetVectorLength(Vector(self.unit:GetVelocity())) * 10
                local maxSpeed = self.unit--[[@as XSA0304]] .SpeedMult * self.unit.Blueprint.Air.MaxAirspeed
                LOG(string.format("XSA0304 fired - speed %f out of %f max (%f%%)"
                    , curSpeed
                    , maxSpeed
                    , curSpeed / maxSpeed * 100
                ))
                return SIFBombZhanaseeWeapon.CreateProjectile(self, muzzlebone)
            end,

            CanWeaponFire = function(self)
                LOG(string.format("XSA0304 CanWeaponFire"
                ))
                return SIFBombZhanaseeWeapon.CanWeaponFire(self)
            end,
        },
    },

    SpeedMult = 1,
    SetSpeedMult = function(self, mult)
        SAirUnit.SetSpeedMult(self, mult)
        self.SpeedMult = mult
    end,

    OnDamage = function(self, instigator, amount, vector, damageType)
        if instigator and instigator.Blueprint.CategoriesHash.STRATEGICBOMBER and instigator.Army == self.Army then
            return
        end

        SAirUnit.OnDamage(self, instigator, amount, vector, damageType)
    end,
}
TypeClass = XSA0304
