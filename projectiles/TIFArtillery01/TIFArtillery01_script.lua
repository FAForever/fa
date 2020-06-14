--
-- UEF T2 Artillery projectile : ueb2303
--
local EffectTemplate = import('/lua/EffectTemplates.lua')
local TArtilleryProjectilePolytrail = import('/lua/terranprojectiles.lua').TArtilleryProjectilePolytrail
TIFArtillery01 = Class(TArtilleryProjectilePolytrail) {
	FxImpactTrajectoryAligned = false,
    PolyTrail = '/effects/emitters/default_polytrail_04_emit.bp',
    FxImpactUnit = EffectTemplate.TAPDSHitUnit01,
    FxImpactLand = EffectTemplate.TAPDSHit01,
    
    OnImpact = function(self, targetType, targetEntity)
		if targetType != 'Water' or targetType != 'UnitAir' or targetType != 'Shield' then
            local pos = self:GetPosition()
            local radius = self.DamageData.DamageRadius
        
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )
        end
    
        TArtilleryProjectilePolytrail.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TIFArtillery01

