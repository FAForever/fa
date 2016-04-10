#****************************************************************************
#**
#**  File     :  /data/units/XRL0302/XRL0302_script.lua
#**  Author(s):  Jessica St. Croix, Gordon Duclos
#**
#**  Summary  :  Cybran Mobile Bomb Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local CMobileKamikazeBombWeapon = import('/lua/cybranweapons.lua').CMobileKamikazeBombWeapon
local CMobileKamikazeBombDeathWeapon = import('/lua/cybranweapons.lua').CMobileKamikazeBombDeathWeapon


XRL0302 = Class(CWalkingLandUnit) {
    Weapons = {

        DeathWeapon = Class(CMobileKamikazeBombDeathWeapon) {},
        
        Suicide = Class(CMobileKamikazeBombWeapon) {   
			OnFire = function(self)		
				self.unit:SetDeathWeaponEnabled(false)
				CMobileKamikazeBombWeapon.OnFire(self)
			end,
        },
    },

	OnProductionPaused = function(self)
        local wep = self:GetWeapon(1)
        wep.OnFire(wep)
    end,
	
	OnKilled = function(self, instigator, type, overkillRatio)
        CWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)
		if not instigator and self.DeathWeaponEnabled != false then
			self:GetWeaponByLabel('Suicide'):FireWeapon()
		end
    end,

    OnLayerChange = function(self, new, old)
        CWalkingLandUnit:OnLayerChange(new, old)
        self:SetDeathWeaponEnabled(new == "Seabed" or new == "Land")
    end
}
TypeClass = XRL0302
