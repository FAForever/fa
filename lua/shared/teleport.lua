-- All functions in this file (inside /lua/shared) should be:
-- - pure: they should only use the arguments provided, do not touch any global state.
-- - sim / ui proof: they should work for both sim code and ui code.

--- Formula to compute the energy and time cost of a teleport.

---@param unit Unit | UserUnit
---@param location Vector
TeleportCostFunction = function(unit, location)
    local bp = unit.Blueprint or unit:GetBlueprint()
    local pos = unit:GetPosition()
    local dist = VDist3(pos,location)
    local teleDelay = bp.General.TeleportDelay
    local bpEco = bp.Economy
    local energyCost, time
    
    --[[
    Old function here, for reference:
    if bpEco then
        local mass = (bpEco.TeleportMassCost or bpEco.BuildCostMass or 1) * (bpEco.TeleportMassMod or 0.01)
        local energy = (bpEco.TeleportEnergyCost or bpEco.BuildCostEnergy or 1) * (bpEco.TeleportEnergyMod or 0.01)
        energyCost = mass + energy
        time = energyCost * (bpEco.TeleportTimeMod or 0.01)
    end

    if teleDelay then
        energyCostMod = (time + teleDelay) / time
        time = time + teleDelay
        energyCost = energyCost * energyCostMod
    end
    ]]

    -- New function
    -- energy cost is dist^2
    -- time cost is natural log of dist
    energyCost = math.pow(dist, 2)
    time = math.log(dist)
    
    if time < teleDelay then
        time = teleDelay
    end

    return energyCost, time, teleDelay
end