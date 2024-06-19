-- File     :  /cdimage/units/UAA0203/UAA0203_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Aeon Gunship Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local AAirUnit = import("/lua/aeonunits.lua").AAirUnit
local ADFLaserLightWeapon = import("/lua/aeonweapons.lua").ADFLaserLightWeapon

---@class UAA0203 : AAirUnit
UAA0203 = ClassUnit(AAirUnit) {
    Weapons = {
        Turret = ClassWeapon(ADFLaserLightWeapon) {
            FxChassisMuzzleFlash = { '/effects/emitters/aeon_gunship_body_illumination_01_emit.bp', },

            PlayFxMuzzleSequence = function(self, muzzle)
                local unit = self.unit
                local army = self.Army
                for k, v in self.FxMuzzleFlash do
                    CreateAttachedEmitter(unit, muzzle, army, v)
                end

                for k, v in self.FxChassisMuzzleFlash do
                    CreateAttachedEmitter(unit, -1, army, v)
                end
            end,
        },
    },
}

TypeClass = UAA0203
