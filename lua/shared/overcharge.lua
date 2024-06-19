
-- All functions in this file (inside /lua/shared) should be:
-- - pure: they should only use the arguments provided, do not touch any global state.
-- - sim / ui proof: they should work for both sim code and ui code.

--- Formula to compute the damage of an overcharge.
local energyRatio = 6

EnergyAsDamage = function(energy)
    return ((1/energyRatio) * energy)
end

--- Formula to compute the energy drain of an overcharge.
DamageAsEnergy = function(damage)
    return energyRatio * damage
end