--
-- Fire Plume Test Projectile Script
--
local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell

DestructionFirePlume01 = Class(NullShell) {
    FxImpactUnit = {},
    FxImpactLand = {},
    FxImpactWater = {},
    FxImpactUnderWater = {},
    FxImpactNone = {},
}

TypeClass = DestructionFirePlume01

