--
-- Aeon T1 Artillery Mortar : ual0103
--
local AArtilleryProjectile = import("/lua/aeonprojectiles.lua").AArtilleryProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")

---@class AIFMortar01: AArtilleryProjectile
AIFMortar01 = ClassProjectile(AArtilleryProjectile) {   
    FxImpactLand = EffectTemplate.ALightMortarHit01,
    FxImpactProp = EffectTemplate.ALightMortarHit01,
    FxImpactUnit = EffectTemplate.ALightMortarHit01,
}

TypeClass = AIFMortar01