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
local GetFormationPosition = import('/lua/shared/Formations/shared.lua').GetFormationPosition
local UpdateBlueprintListCache = import('/lua/shared/Formations/shared.lua').UpdateBlueprintListCache

local LandFormations = import('/lua/shared/Formations/AttackFormations/Land.lua').LandFormations

local LandFormationPreferencesCache = import("/lua/shared/Formations/LandFormationPreferences.lua").LandFormationPreferencesCache
local CleanupLandFormationPreferences = import("/lua/shared/Formations/LandFormationPreferences.lua").CleanupLandFormationPreferences
local PopulateLandFormationPreferences = import("/lua/shared/Formations/LandFormationPreferences.lua").PopulateLandFormationPreferences

---@class AttackFormationRow
---@field Delay number
---@field [1] EntityCategory[]
---@field [2] EntityCategory[]
---@field [3] EntityCategory[]
---@field [4] EntityCategory[]
---@field [5] EntityCategory[]
---@field [6] EntityCategory[]
---@field [7] EntityCategory[]
---@field [8] EntityCategory[]
---@field [9] EntityCategory[]
---@field [10] EntityCategory[]

---@class AttackFormation
---@field Count number
---@field Rows number
---@field Columns number
---@field FootprintSizeXMultiplier number
---@field FootprintSizeZMultiplier number
---@field [1] AttackFormationRow
---@field [2] AttackFormationRow
---@field [3] AttackFormationRow
---@field [4] AttackFormationRow
---@field [5] AttackFormationRow
---@field [6] AttackFormationRow
---@field [7] AttackFormationRow
---@field [8] AttackFormationRow
---@field [9] AttackFormationRow
---@field [10] AttackFormationRow

local TableGetn = table.getn

--- A table that contains the blueprint lookups that we can re-use.
local BlueprintLookup = {}
local BlueprintList = {}

--- A table that contains the tactical formation that we can re-use.
---@type FormationPosition[]
local TacticalFormation = {}

---@type BlueprintId[]
local OccupationCache = {}
local FootprintCache = {}

---@param blueprintCountCache BlueprintLookupTable
---@param blueprintListCache BlueprintId[]
---@param unitCount number
---@param occupationCache Blueprint[]
---@param footprintCache number[]
---@return AttackFormation  # formation rows
---@return Blueprint[]      # occupation cache
---@return number[]         # footprint cache
AttackFormationLand = function(blueprintCountCache, blueprintListCache, unitCount, occupationCache, footprintCache)

    -- choose a formation that best matches the unit count
    local formation = LandFormations[1]
    for k = 1, TableGetn(LandFormations) do
        if LandFormations[k].Count > unitCount then
            formation = LandFormations[k]
            break
        end
    end

    -- local scope for quick access
    local formationCount = formation.Count
    local formationRows = formation.Rows
    local formationColumns = formation.Columns
    local landFormationPreferencesCache = LandFormationPreferencesCache

    ---------------------------------------------------------------------------
    --#region Clean up caches
    for o = 1, formationCount do
        occupationCache[o] = nil
    end

    for ly = 1, formationRows do
        footprintCache[ly] = 0
    end

    --#endregion

    for index = 1, 3 do

        -- prepare this iteration
        CleanupLandFormationPreferences(landFormationPreferencesCache)
        PopulateLandFormationPreferences(landFormationPreferencesCache, blueprintListCache, index)

        -- populate the formation
        for ly = 1, formationRows do
            local formationRow = formation[ly]
            local formationRowDelay = formationRow.Delay

            -- go through reach column
            for lx = 1, formationColumns do
                local cell = formationRow[lx]

                -- map two dimensional index to one dimensional array
                local oi       = (ly - 1) * formationColumns + lx
                local occupied = occupationCache[oi]

                -- if this cell is not occupied
                if not occupied then

                    -- and we fit the category, then we put ourselves there
                    local categoryIdentifier = cell[index]
                    local firstPreferences = landFormationPreferencesCache[categoryIdentifier]

                    for k = 1, TableGetn(firstPreferences) do
                        local blueprintId = firstPreferences[k]
                        local blueprintIdCount = blueprintCountCache[blueprintId]
                        if blueprintIdCount > 0 then
                            blueprintCountCache[blueprintId] = blueprintCountCache[blueprintId] - 1

                            -- update occupation cache
                            occupationCache[oi] = blueprintId

                            -- update footprint cache
                            local blueprintFootprintSizeZ = __blueprints[blueprintId].Footprint.SizeZ
                            if (footprintCache[ly]) < blueprintFootprintSizeZ then
                                footprintCache[ly] = blueprintFootprintSizeZ
                            end

                            break
                        end
                    end
                end
            end
        end

        -- bijwerken van de lijst aan blueprints
        blueprintListCache = UpdateBlueprintListCache(blueprintCountCache, blueprintListCache)
    end

    return formation, occupationCache, footprintCache
end

---@param units (Unit[] | UserUnit[])
---@return TacticalFormation
AttackFormation = function(units)
    -- local scope for performance
    local occupationCache = OccupationCache
    local footprintCache = FootprintCache
    local tacticalFormation = TacticalFormation

    -- gather information about the units
    local blueprintLookup, blueprintList, unitCount = ToBlueprintLookup(units, BlueprintLookup, BlueprintList)
    local maximumFootprintSize = MaximumFootprint(blueprintLookup)

    do -- create land/amphibious formations
        local formation, occupationCache, footprintCache = AttackFormationLand(
            blueprintLookup, blueprintList, unitCount, occupationCache, footprintCache)

        -- retrieve information
        local formationCount = formation.Count
        local formationRows = formation.Rows
        local formationColumns = formation.Columns
        local formationHalfColumns = 0.5 * formationColumns
        local formationFootprintSizeXMultiplier = formation.FootprintSizeXMultiplier
        local formationFootprintSizeZMultiplier = formation.FootprintSizeZMultiplier

        for ly = 1, formationRows do
            local formationRow = formation[ly]
            local formationRowDelay = formationRow.Delay
            local formationRowFootprintSizeZ = footprintCache[ly]

            for lx = 1, formationColumns do
                -- map two dimensional index to one dimensional array
                local oi       = (ly - 1) * formationColumns + lx
                local occupied = occupationCache[oi]

                if occupied then
                    tacticalFormation[oi] = {
                        formationFootprintSizeXMultiplier * (lx - formationHalfColumns),
                        formationFootprintSizeZMultiplier * (-1 * ly),
                        categories[occupied], formationRowDelay, true
                    }
                end
            end
        end
    end

    do -- create air formations

    end

    do -- create water formations

    end

    do -- create submarine formations

    end

    return tacticalFormation
end
