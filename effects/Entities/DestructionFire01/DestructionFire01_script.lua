local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell

DestructionFire01 = Class(NullShell) {
    FxImpactUnit = import("/lua/effecttemplates.lua").NoEffects,
    FxImpactLand = import("/lua/effecttemplates.lua").NoEffects,
    FxImpactWater = import("/lua/effecttemplates.lua").NoEffects,
    FxImpactNone = import("/lua/effecttemplates.lua").NoEffects,
}
TypeClass = DestructionFire01