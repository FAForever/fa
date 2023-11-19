local EmitterProjectile = import("/lua/sim/defaultprojectiles.lua").EmitterProjectile
local EffectTemplate = import("/lua/EffectTemplates.lua")

--- UEFNukeFlavorPlume01
---@class UEFNukeFlavorPlume01 : EmitterProjectile
UEFNukeFlavorPlume01 = Class(EmitterProjectile) {
    FxTrails = EffectTemplate.TNukeFlavorPlume01,
    FxImpactUnit = { },
    FxImpactLand = { },
    FxImpactWater = { },
    FxImpactNone = { },
}
TypeClass = UEFNukeFlavorPlume01