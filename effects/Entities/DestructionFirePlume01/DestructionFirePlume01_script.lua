local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell

DestructionFirePlume01 = Class(NullShell) {
    FxImpactUnit = { },
    FxImpactLand = { },
    FxImpactWater = { },
    FxImpactNone = { },
}
TypeClass = DestructionFirePlume01