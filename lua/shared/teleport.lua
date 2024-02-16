--******************************************************************************************************
--** Copyright (c) 2022  clyf
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

-- Local performance upvalues
local VDist3 = VDist3
local MathPow = math.pow
local MathSqrt = math.sqrt

---@param unit Unit | UserUnit
---@param location Vector
---@return number energyCost
---@return number time
---@return number? teleDelay
TeleportCostFunction = function(unit, location)
    local bp = unit:GetBlueprint()

    -- use unit position by default
    local pos = unit:GetPosition()

    -- or, if queuing commands, use the position of the last teleport/move command
    local queue = unit:GetCommandQueue() --[[@as (UICommandInfo[])]]
    if table.getn(queue) > 0 then
        for k = 1, table.getn(queue) do
            local command = queue[k]

            -- this if statement can only be true in the UI code, so IsKeyDown works
            if command.type == 'Teleport' or command.type == 'Move' then
                if IsKeyDown('Shift') then
                    pos = command.position
                end
            end
        end
    end

    local dist = VDist3(pos, location)
    local teleDelay = bp.General.TeleportDelay
    local bpEco = bp.Economy
    local energyCost, time

    if bpEco.UseVariableTeleportCosts then
        -- New function
        -- energy cost is dist^2
        -- time cost is natural log of dist
        energyCost = MathPow(dist, 1.8)
        time = MathSqrt(dist)

        -- clamp time to teleDelay
        if teleDelay and time < teleDelay then
            time = teleDelay
        end
        -- make sure the teleport destination effects appear on time
        teleDelay = time * 0.4
    else
        -- original cost function
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
    end

    return energyCost, time, teleDelay
end
