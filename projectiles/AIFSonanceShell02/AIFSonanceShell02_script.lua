#
# Aeon Artillery Projectile
#
local AArtilleryProjectile = import('/lua/aeonprojectiles.lua').AArtilleryProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

AIFSonanceShell02 = Class(AArtilleryProjectile) {
    
    FxTrails = EffectTemplate.ASonanceWeaponFXTrail02,
    
    FxImpactUnit =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactProp =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactLand =  EffectTemplate.ASonanceWeaponHit02,
    
    OnImpact = function(self, TargetType, targetEntity)
        local rotation = RandomFloat(0,2*math.pi)
        
        CreateDecal(self:GetPosition(), rotation, 'crater_radial01_normals', '', 'Alpha Normals', 10, 10, 300, 0, self:GetArmy())
        CreateDecal(self:GetPosition(), rotation, 'crater_radial01_albedo', '', 'Albedo', 12, 12, 300, 0, self:GetArmy())
 
        AArtilleryProjectile.OnImpact( self, TargetType, targetEntity )
    end,
}

TypeClass = AIFSonanceShell02