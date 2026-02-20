--****************************************************************************
--**
--**  File     :  /units/XSA0303/XSA0303_script.lua
--**  Author(s):  Greg Kohne
--**
--**  Summary  :  Seraphim Air Superiority Fighter Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SAirUnit = import("/lua/seraphimunits.lua").SAirUnit
local SAALosaareAutoCannonWeapon = import("/lua/seraphimweapons.lua").SAALosaareAutoCannonWeaponAirUnit
local GetVectorLength = import("/lua/utilities.lua").GetVectorLength

---@class XSA0303 : SAirUnit
XSA0303 = ClassUnit(SAirUnit) {
    Weapons = {
        AutoCannon1 = ClassWeapon(SAALosaareAutoCannonWeapon) {
                        ---@param self SIFBombZhanaseeWeapon
            CreateProjectile = function(self, muzzlebone)
                local curSpeed = GetVectorLength(Vector(self.unit:GetVelocity())) * 10
                local maxSpeed = self.unit--[[@as XSA0303]] .SpeedMult * self.unit.Blueprint.Air.MaxAirspeed
                LOG(string.format("XSA0303 fired - speed %f out of %f max (%f%%)"
                    , curSpeed
                    , maxSpeed
                    , curSpeed / maxSpeed * 100
                ))
                return SAALosaareAutoCannonWeapon.CreateProjectile(self, muzzlebone)
            end,

        },
    },
    SpeedMult = 1,
    SetSpeedMult = function(self, mult)
        SAirUnit.SetSpeedMult(self, mult)
        self.SpeedMult = mult
    end,

}

TypeClass = XSA0303