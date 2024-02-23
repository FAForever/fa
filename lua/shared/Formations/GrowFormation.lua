--******************************************************************************************************
--** Copyright (c) 2024 FAForever
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

local ToBlueprintLookup = import('/lua/shared/Formations/shared.lua').ToBlueprintLookup
local MaximumFootprint = import('/lua/shared/Formations/shared.lua').MaximumFootprint
local GetFormationEntry = import('/lua/shared/Formations/Formation.lua').GetFormationEntry

local LandFormations = import('/lua/shared/Formations/AttackFormations/Land.lua').LandFormations

local LandFormationPreferencesCache = import("/lua/shared/Formations/LandFormationPreferences.lua").LandFormationPreferencesCache
local CleanupLandFormationPreferences = import("/lua/shared/Formations/LandFormationPreferences.lua").CleanupLandFormationPreferences
local PopulateLandFormationPreferences = import("/lua/shared/Formations/LandFormationPreferences.lua").PopulateLandFormationPreferences

--- A table that contains the blueprint lookups that we can re-use.
---@type BlueprintLookupTable
local BlueprintLookup = {}

---@type Blueprint[]
local BlueprintList = {}

--- A table that contains the tactical formation that we can re-use.
---@type Formation
local TacticalFormation = {}

-- upvalue scope for performance
local MathSqrt = math.sqrt
local MathCeil = math.ceil

--- Computes a square-shaped formation for the given unit count.
---@param unitCount number
---@return number   # rows
---@return number   # columns
local ComputeDimensions = function(unitCount)
    local sqrt = MathSqrt(unitCount)
    local ceil = MathCeil(sqrt)

    if math.mod(ceil,2) == 0 then
        return ceil -1, ceil + 1
    else
        return ceil, ceil
    end
end

---@param units (Unit[] | UserUnit[])
---@return Formation
ComputeFormation = function(units)

    -- local scope for performance
    local tacticalFormation = TacticalFormation

    -- gather information about the units
    local blueprintLookup, blueprintList, unitCount = ToBlueprintLookup(units, BlueprintLookup, BlueprintList)
    local maximumFootprintSize = MaximumFootprint(blueprintLookup)

    local formationRows, formationColumns = ComputeDimensions(unitCount)
    local formationCenter = math.ceil(0.5 * formationColumns)

    local sparsityMultiplier = 1.25
    local unitsRemainingCount = unitCount

    -- populate the formation
    for ly = 1, formationRows do

        -- offset for the last row
        local horizontalOffset = 0
        if unitsRemainingCount < formationColumns then
            horizontalOffset = sparsityMultiplier * 0.5 * (formationColumns - unitsRemainingCount)
            LOG(horizontalOffset)
        end

        -- from center to the right
        for lx = formationCenter, formationColumns do
            local oi = (ly - 1) * formationColumns + lx - 1

            local unit = units[oi]
            if unit then
                local formation = GetFormationEntry(oi)
                formation[1] = horizontalOffset + sparsityMultiplier * (lx - formationCenter)
                formation[2] = sparsityMultiplier * (-1 * ly)
                formation[3] = categories[unit:GetBlueprint().BlueprintId]
                tacticalFormation[oi] = formation
            end
        end

        -- from center to the left
        for lx = formationCenter, 1, -1 do
            local oi = (ly - 1) * formationColumns + lx - 1

            local unit = units[oi]
            if unit then
                local formation = GetFormationEntry(oi)
                formation[1] = horizontalOffset + sparsityMultiplier * (lx - formationCenter)
                formation[2] = sparsityMultiplier * (-1 * ly)
                formation[3] = categories[unit:GetBlueprint().BlueprintId]
                tacticalFormation[oi] = formation
            end
        end

        if unitsRemainingCount > formationColumns then
            unitsRemainingCount = unitsRemainingCount - formationColumns
        else
            break
        end
    end

    -- clean up remaining entries
    for k = unitCount, table.getn(tacticalFormation) do
        tacticalFormation[k] = nil
    end

    return tacticalFormation
end
