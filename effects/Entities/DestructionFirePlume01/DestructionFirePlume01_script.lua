local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell

---@class DestructionFire01 : NullShell
DestructionFirePlume01 = Class(NullShell) {
    FxImpactUnit = { },
    FxImpactLand = { },
    FxImpactWater = { },
    FxImpactNone = { },
}
TypeClass = DestructionFirePlume01