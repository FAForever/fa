local TArtilleryProjectile = import("/lua/terranprojectiles.lua").TArtilleryProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")

--- Terran T1 Artillery Fragmentation Shell : uel0103
---@class TIFFragmentationShell01: TArtilleryProjectile
TIFFragmentationSensorShell02 = ClassProjectile(TArtilleryProjectile) {
    FxTrails     = EffectTemplate.TFragmentationSensorShellTrail,
    FxImpactUnit = EffectTemplate.TFragmentationSensorShellHit,
    FxImpactLand = EffectTemplate.TFragmentationSensorShellHit,
}
TypeClass = TIFFragmentationSensorShell02