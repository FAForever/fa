--
-- Aeon T3 Mobile Artillery Projectile : ual0304
--
local AArtilleryProjectile = import('/lua/aeonprojectiles.lua').AArtilleryProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

AIFSonanceShell01 = Class(AArtilleryProjectile) {

    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius

        if targetType != 'Water' or targetType != 'UnitAir' or targetType != 'Shield' then
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )
        end
        
        AArtilleryProjectile.OnImpact(self, targetType, targetEntity)
    end,

    PolyTrail = '/effects/emitters/aeon_sonicgun_trail_emit.bp',
    
    FxTrails = EffectTemplate.ASonanceWeaponFXTrail01,
    
    FxImpactUnit =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactProp =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactLand =  EffectTemplate.ASonanceWeaponHit02,
}

TypeClass = AIFSonanceShell01