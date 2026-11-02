local EffectTemplate = import("/lua/EffectTemplates.lua")

-- Cybran Anti Air Projectile
---@class CAAAutocannon03: CShellAAAutoCannonProjectile
CAAAutocannon03 = ClassProjectile(import("/lua/cybranprojectiles.lua").CShellAAAutoCannonProjectile) {
    FxAirUnitHitScale = 1.5,
    FxImpactAirUnit = EffectTemplate.CNanoDartUnitHit01,
 }
TypeClass = CAAAutocannon03