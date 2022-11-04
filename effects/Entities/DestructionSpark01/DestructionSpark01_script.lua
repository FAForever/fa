--
-- Fire Test Projectile Script
--
local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell

DestructionSpark01 = Class(NullShell) {
    FxImpactUnit = {},
    FxImpactLand = {},
    FxImpactWater = {},
    FxImpactUnderWater = {},
    FxImpactNone = {},
}
TypeClass = DestructionSpark01

