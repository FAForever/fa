
--- Formula to compute the damage of an overcharge.
EnergyAsDamage = function(energy)
    return 0.25 * energy
end

--- Formula to compute the energy drain of an overcharge.
DamageAsEnergy = function(damage)
    return 4 * damage
end