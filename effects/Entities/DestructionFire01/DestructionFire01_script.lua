local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell

DestructionFire01 = Class(NullShell) {
    FxImpactUnit = { },
    FxImpactLand = { },
    FxImpactWater = { },
    FxImpactNone = { },
}
TypeClass = DestructionFire01