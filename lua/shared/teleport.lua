--******************************************************************************************************
--** Copyright (c) 2022  Charles "clyf" Lyford
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

-- All functions in this file (inside /lua/shared) should be:
-- - pure: they should only use the arguments provided, do not touch any global state.
-- - sim / ui proof: they should work for both sim code and ui code.

--- Formula to compute the energy and time cost of a teleport.

---@param unit Unit | UserUnit
---@param location Vector
---@return number energyCost
---@return number time
---@return number teleDelay
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