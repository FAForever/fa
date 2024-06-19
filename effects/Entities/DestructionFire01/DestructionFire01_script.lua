local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell

---@class DestructionFire01 : NullShell
DestructionFire01 = Class(NullShell) {
    FxImpactUnit = { },
    FxImpactLand = { },
    FxImpactWater = { },
    FxImpactNone = { },
}
TypeClass = DestructionFire01