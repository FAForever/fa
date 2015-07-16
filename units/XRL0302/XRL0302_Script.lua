----------------------------------------------------------------
-- File     :  /data/units/XRL0302/XRL0302_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Mobile Bomb Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local CMobileKamikazeBombWeapon = import('/lua/cybranweapons.lua').CMobileKamikazeBombWeapon

XRL0302 = Class(CWalkingLandUnit) {

    Weapons = {        
        Suicide = Class(CMobileKamikazeBombWeapon) {},
    },

    -- Allow the trigger button to blow the weapon
	OnProductionPaused = function(self)
        local wep = self:GetWeapon(1)
        wep.OnFire(wep)
    end,
	
	OnKilled = function(self, instigator, type, overkillRatio)
        CWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)
		if instigator then -- Firing the Suicide weapon (Button, CRTL-K, Attacking) kills us with no instigator
			self:GetWeaponByLabel('Suicide'):FireWeapon()
		end
    end,
}
TypeClass = XRL0302
