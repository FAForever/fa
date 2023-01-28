--
-- UEF Nuke Flavor Plume effect
--
local EmitterProjectile = import("/lua/sim/defaultprojectiles.lua").EmitterProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")

UEFNukeFlavorPlume01 = Class(EmitterProjectile) {
    FxTrails = EffectTemplate.TNukeFlavorPlume01,
    FxImpactUnit = import("/lua/effecttemplates.lua").NoEffects,
    FxImpactLand = import("/lua/effecttemplates.lua").NoEffects,
    FxImpactWater = import("/lua/effecttemplates.lua").NoEffects,
    FxImpactNone = import("/lua/effecttemplates.lua").NoEffects,
}

TypeClass = UEFNukeFlavorPlume01

