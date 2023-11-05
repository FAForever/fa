------------------------------------------------------------------------------
-- File     :  /data/projectiles/CDFProtonCannon05/CDFProtonCannon05_script.lua
-- Author(s):  Gordon Duclos, Matt Vainio
-- Summary  :  Cybran Proton Artillery projectile script, XRL0403
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------
local CDFHvyProtonCannonProjectile = import("/lua/cybranprojectiles.lua").CDFHvyProtonCannonProjectile

-- Cybran Proton Artillery projectile script, XRL0403
---@class CDFProtonCannon05 : CDFHvyProtonCannonProjectile
CDFProtonCannon05 = ClassProjectile(CDFHvyProtonCannonProjectile) {

	---@param self CDFProtonCannon05
	---@param TargetType string
	---@param TargetEntity Prop|Unit
	OnImpact = function(self, TargetType, TargetEntity) 
		self:ShakeCamera( 15, 0.25, 0, 0.2 )
		CDFHvyProtonCannonProjectile.OnImpact (self, TargetType, TargetEntity)
	end,
}
TypeClass = CDFProtonCannon05