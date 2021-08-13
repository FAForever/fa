-------------------------------------------------------------------------------
--
--  File     :  /data/projectiles/AIFGuidedMissile02/AIFGuidedMissile02_script.lua
--  Author(s):  Gordon Duclos
--
--  Summary  :  Aeon Guided Split Missile, DAA0206
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------

local AGuidedMissileProjectile = import('/lua/aeonprojectiles.lua').AGuidedMissileProjectile
local DefaultExplosion = import('/lua/defaultexplosions.lua')

AIFGuidedMissile02 = Class(AGuidedMissileProjectile) {
	-- FxTrailScale = 0.5,

    OnCreate = function(self)
		AGuidedMissileProjectile.OnCreate(self)
		self:ForkThread( self.MovementThread )
    end,
    
	MovementThread = function(self)
		WaitSeconds(0.6)
		self:TrackTarget(true)
	end,
    
    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            local army = self.Army

            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', radius*3, radius*3, 200, 70, army)
        end
        
        AGuidedMissileProjectile.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = AIFGuidedMissile02

