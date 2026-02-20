--****************************************************************************
--**
--**  File     :  /data/units/XSA0103/XSA0103_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  Seraphim Bomber Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SAirUnit = import("/lua/seraphimunits.lua").SAirUnit
local SDFBombOtheWeapon = import("/lua/seraphimweapons.lua").SDFBombOtheWeapon
local GetVectorLength = import("/lua/utilities.lua").GetVectorLength

---@class XSA0103 : SAirUnit
XSA0103 = ClassUnit(SAirUnit) {
    Weapons = {
        Bomb = ClassWeapon(SDFBombOtheWeapon) {
            CreateProjectile = function(self, muzzlebone)
                local curSpeed = GetVectorLength(Vector(self.unit:GetVelocity())) * 10
                local maxSpeed = self.unit--[[@as XSA0304]] .SpeedMult * self.unit.Blueprint.Air.MaxAirspeed
                LOG(string.format("XSA0304 fired - speed %f out of %f max (%f%%)"
                    , curSpeed
                    , maxSpeed
                    , curSpeed / maxSpeed * 100
                ))
                return SDFBombOtheWeapon.CreateProjectile(self, muzzlebone)
            end,


        },
    },

    SpeedMult = 1,
    SetSpeedMult = function(self, mult)
        SAirUnit.SetSpeedMult(self, mult)
        self.SpeedMult = mult
    end,

}

TypeClass = XSA0103