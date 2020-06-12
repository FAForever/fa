------------------------------------------------------------
--
--  File     :  /data/projectiles/SIFSuthanusArtilleryShell02/SIFSuthanusArtilleryShell02_script.lua
--  Author(s):  Gordon Duclos, Aaron Lundquist
--
--  Summary  :  Suthanus Artillery Shell Projectile script
--              Seraphim T3 Static Artillery : XSB2302
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

local SSuthanusArtilleryShell = import('/lua/seraphimprojectiles.lua').SSuthanusArtilleryShell
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

SIFSuthanusArtilleryShell02 = Class(SSuthanusArtilleryShell) {
    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local army = self.Army
        
        if targetType == 'Shield' and self.Data then
            DamageArea(self, pos, radius, self.DamageData.DamageAmount, self.DamageData.DamageType, self.DamageData.DamageFriendly)
            self.DamageData.DamageAmount = self.Data - self.DamageData.DamageAmount
            radius = 0
        end

		if targetType != 'Shield' and targetType != 'Water' and targetType != 'UnitAir' then
			local rotation = RandomFloat(0,2*math.pi)
	        
			CreateDecal(pos, rotation, 'crater_radial01_normals', '', 'Alpha Normals', 10, 10, 300, 0, army)
			CreateDecal(pos, rotation, 'crater_radial01_albedo', '', 'Albedo', 12, 12, 300, 0, army)
            
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )
		end
        
        SSuthanusArtilleryShell.OnImpact(self, targetType, targetEntity)
	end,
}

TypeClass = SIFSuthanusArtilleryShell02