-- File     :  /cdimage/units/XRA0105/XRA0105_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Gunship Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local CAirUnit = import("/lua/cybranunits.lua").CAirUnit
local CDFLaserHeavyWeapon = import("/lua/cybranweapons.lua").CDFLaserHeavyWeapon02

---@class URA0203 : CAirUnit
URA0203 = ClassUnit(CAirUnit) {
    Weapons = {
        MainGun = ClassWeapon(CDFLaserHeavyWeapon) {}
    },

    DestructionPartsChassisToss = { 'XRA0105', },

    OnStopBeingBuilt = function(self, builder, layer)
        CAirUnit.OnStopBeingBuilt(self, builder, layer)
    end,

    OnMotionVertEventChange = function(self, new, old)
        CAirUnit.OnMotionVertEventChange(self, new, old)

        if (new == 'Down') then
            self:PlayUnitAmbientSound('AmbientMove')
        end

        if new == 'Bottom' then
            self:StopUnitAmbientSound('AmbientMove')
        end
    end,
}

TypeClass = URA0203
