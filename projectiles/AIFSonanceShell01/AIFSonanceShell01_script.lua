--
-- Aeon T3 Mobile Artillery Projectile : ual0304
--

local AArtilleryProjectile = import('/lua/aeonprojectiles.lua').AArtilleryProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

AIFSonanceShell01 = Class(AArtilleryProjectile) {

    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly
        if radius == 0 then
            local FriendlyFire = false
        end
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            local army = self.Army
            
            CreateDecal(pos, rotation, 'crater_radial01_albedo', '', 'Albedo', radius+2, radius+2, 200, 150, army)
        end
        
        self:ShakeCamera( 20, 1, 0, 1 )

        AArtilleryProjectile.OnImpact(self, targetType, targetEntity)
    end,

    PolyTrail = '/effects/emitters/aeon_sonicgun_trail_emit.bp',
    
    FxTrails = EffectTemplate.ASonanceWeaponFXTrail01,
    
    FxImpactUnit =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactProp =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactLand =  EffectTemplate.ASonanceWeaponHit02,
}

TypeClass = AIFSonanceShell01