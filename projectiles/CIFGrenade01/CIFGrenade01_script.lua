--
-- Cybran T1 Artillery EMP Grenade : url0103
--
local CArtilleryProjectile = import('/lua/cybranprojectiles.lua').CArtilleryProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

CIFGrenade01 = Class(CArtilleryProjectile) {
    FxImpactUnit = EffectTemplate.CEMPGrenadeHit01,
    FxImpactProp = EffectTemplate.CEMPGrenadeHit01,
    FxImpactLand = EffectTemplate.CEMPGrenadeHit01,
}

TypeClass = CIFGrenade01