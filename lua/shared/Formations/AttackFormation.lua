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

local TableGetn = table.getn

--- A table that contains the blueprint lookups that we can re-use.
local BlueprintLookup = {}
local BlueprintList = {}

--- A table that contains the tactical formation that we can re-use.
---@type FormationPosition[]
local TacticalFormation = {}

---@type BlueprintId[]
local oc = {}

-- pre-populate the first 2048 cells
for k = 1, 2048 do
    oc[k] = nil
    TacticalFormation[k] = nil
end

---@param blueprintCountCache BlueprintLookupTable
---@param blueprintListCache BlueprintId[]
---@param unitCount number
AttackFormationLand = function(blueprintCountCache, blueprintListCache, unitCount)

    -- clean up occupation data
    for o = 1, TableGetn(oc) do
        oc[o] = nil
    end

    -- choose a formation that best matches the unit count
    local formation = LandFormations[1]
    for k = 1, TableGetn(LandFormations) do
        if LandFormations[k].Count > unitCount then
            formation = LandFormations[k]
            break
        end
    end

    local spacingMultiplier = formation.SpacingMultiplier

    local preference = LandFormationPreferencesCache

    for index = 1, 3 do

        CleanupLandFormationPreferences(preference)
        PopulateLandFormationPreferences(preference, blueprintListCache, index)

        -- go through the formation to apply the preference
        local countRows = TableGetn(formation)

        for ly = 1, countRows do
            local row = formation[ly]
            local countColumns = TableGetn(row)
            local halfColumns = math.floor(0.5 * countColumns)

            -- go through reach column
            for lx = 1, countColumns do
                local cell = row[lx]

                -- map two dimensional index to one dimensional array
                local oi       = (ly - 1) * countColumns + lx
                local occupied = oc[oi]

                -- if this cell is not occupied
                if not occupied then

                    -- and we fit the category, then we put ourselves there
                    local categoryIdentifier = cell[index]
                    local firstPreferences = preference[categoryIdentifier]

                    for k = 1, TableGetn(firstPreferences) do
                        local blueprintId = firstPreferences[k]
                        local blueprintIdCount = blueprintCountCache[blueprintId]
                        if blueprintIdCount > 0 then
                            blueprintCountCache[blueprintId] = blueprintCountCache[blueprintId] - 1

                            oc[oi] = blueprintId
                            TacticalFormation[oi] = { spacingMultiplier * (lx - halfColumns), spacingMultiplier * (-1 * ly), categories[blueprintId], row.Delay, true }
                            break
                        end
                    end
                end
            end
        end

        -- bijwerken van de lijst aan blueprints
        blueprintListCache = UpdateBlueprintListCache(blueprintCountCache, blueprintListCache)
    end

    return TacticalFormation
end

---@param units (Unit[] | UserUnit[])
---@return TacticalFormation
AttackFormation = function(units)

    LOG("AttackFormation")

    -- clean up old formation data
    for k = 1, TableGetn(TacticalFormation) do
        TacticalFormation[k] = nil
    end

    -- gather information about the units
    local blueprintLookup, blueprintList, unitCount = ToBlueprintLookup(units, BlueprintLookup, BlueprintList)
    local maximumFootprintSize = MaximumFootprint(blueprintLookup)

    return AttackFormationLand(blueprintLookup, blueprintList, unitCount)
end
