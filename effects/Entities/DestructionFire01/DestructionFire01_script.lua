--
-- Fire Test Projectile Script
--
local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell

DestructionFire01 = Class(NullShell) {
    FxImpactUnit = {},
    FxImpactLand = {},
    FxImpactWater = {},
    FxImpactUnderWater = {},
    FxImpactNone = {},
}


TypeClass = DestructionFire01

