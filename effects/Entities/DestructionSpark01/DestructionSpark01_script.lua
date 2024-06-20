local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell

--- Fire Test Projectile Script
---@class DestructionSpark01 : NullShell
DestructionSpark01 = Class(NullShell) {
    FxImpactUnit = { },
    FxImpactLand = { },
    FxImpactWater = { },
    FxImpactNone = { },
}
TypeClass = DestructionSpark01