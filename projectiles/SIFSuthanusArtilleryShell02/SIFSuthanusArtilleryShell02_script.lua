#****************************************************************************
#**
#**  File     :  /data/projectiles/SIFSuthanusArtilleryShell02/SIFSuthanusArtilleryShell02_script.lua
#**  Author(s):  Gordon Duclos, Aaron Lundquist
#**
#**  Summary  :  Suthanus Artillery Shell Projectile script, XSB2302
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SSuthanusArtilleryShell = import('/lua/seraphimprojectiles.lua').SSuthanusArtilleryShell
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

SIFSuthanusArtilleryShell02 = Class(SSuthanusArtilleryShell) {
	OnImpact = function(self, TargetType, TargetEntity)
		SSuthanusArtilleryShell.OnImpact(self, TargetType, TargetEntity)
		if TargetType != 'Shield' and TargetType != 'Water' and TargetType != 'UnitAir' then
			local rotation = RandomFloat(0,2*math.pi)
	        
			CreateDecal(self:GetPosition(), rotation, 'crater_radial01_normals', '', 'Alpha Normals', 10, 10, 300, 0, self:GetArmy())
			CreateDecal(self:GetPosition(), rotation, 'crater_radial01_albedo', '', 'Albedo', 12, 12, 300, 0, self:GetArmy())
		end
	end,
}

TypeClass = SIFSuthanusArtilleryShell02