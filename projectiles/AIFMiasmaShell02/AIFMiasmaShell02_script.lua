------------------------------------------------------------
--
--  File     :  /Projectiles/AIFMiasmaShell02/AIFMiasmaShell02_script.lua
--  Author(s):  Gordon Duclos
--
--  Summary  : Damage shell that is spawned when it's parent shell 
--				detonates above ground. This projectile causes damage, 
--				and destroy trees. 
--              Aeon T2 Artillery : uab2303
--
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------
local AMiasmaProjectile02 = import('/lua/aeonprojectiles.lua').AMiasmaProjectile02

AIFMiasmaShell02 = Class(AMiasmaProjectile02) {
    OnImpact = function(self, targetType, targetEntity) 
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        
		if targetType != 'Water' or targetType != 'UnitAir' or targetType != 'Shield' then
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )
        end
        
        AMiasmaProjectile02.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = AIFMiasmaShell02