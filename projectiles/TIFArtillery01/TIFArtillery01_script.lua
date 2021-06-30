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

            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', radius*2, radius*2, 200, 100, army)
        end
    
        TArtilleryProjectilePolytrail.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TIFArtillery01

