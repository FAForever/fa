--
-- Fire Test Projectile Script
--
local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell

DestructionSpark01 = Class(NullShell) {
    FxImpactUnit = import("/lua/effecttemplates.lua").NoEffects,
    FxImpactLand = import("/lua/effecttemplates.lua").NoEffects,
    FxImpactWater = import("/lua/effecttemplates.lua").NoEffects,
    FxImpactNone = import("/lua/effecttemplates.lua").NoEffects,
}
TypeClass = DestructionSpark01

