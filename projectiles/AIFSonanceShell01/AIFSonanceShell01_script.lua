--
-- Aeon Artillery Projectile
--
local AArtilleryProjectile = import('/lua/aeonprojectiles.lua').AArtilleryProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

AIFSonanceShell01 = Class(AArtilleryProjectile) {
    PolyTrail = '/effects/emitters/aeon_sonicgun_trail_emit.bp',
    
    FxTrails = EffectTemplate.ASonanceWeaponFXTrail01,
    
    FxImpactUnit =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactProp =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactLand =  EffectTemplate.ASonanceWeaponHit02,
}

TypeClass = AIFSonanceShell01