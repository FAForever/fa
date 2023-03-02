--
-- Terran T1 Artillery Fragmentation/Sensor Shells : uel0103
--
local TArtilleryProjectile = import("/lua/terranprojectiles.lua").TArtilleryProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")

TIFFragmentationSensorShell02 = Class(TArtilleryProjectile) {    
    FxTrails     = EffectTemplate.TFragmentationSensorShellTrail,
    FxImpactUnit = EffectTemplate.TFragmentationSensorShellHit,
    FxImpactLand = EffectTemplate.TFragmentationSensorShellHit,
}

TypeClass = TIFFragmentationSensorShell02