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

local ComputeFormationProperties = import('/lua/shared/Formations/shared.lua').ComputeFormationProperties
local ComputeFootprintData = import('/lua/shared/Formations/shared.lua').ComputeFootprintData

local GetFormationEntry = import('/lua/shared/Formations/Formation.lua').GetFormationEntry

-- preferences for land
local LandGeneralPreferences = import("/lua/shared/Formations/LandFormationPreferences.lua").LandGeneralPreferences
local LandShieldPreferences = import("/lua/shared/Formations/LandFormationPreferences.lua").LandShieldPreferences
local LandCounterIntelligencePreferences = import("/lua/shared/Formations/LandFormationPreferences.lua").LandCounterIntelligencePreferences
local LandAntiAirPreferences = import("/lua/shared/Formations/LandFormationPreferences.lua").LandAntiAirPreferences
local LandCounterScoutPreferences = import("/lua/shared/Formations/LandFormationPreferences.lua").LandCounterScoutPreferences

--- A table that contains the blueprint lookups that we can re-use.
---@type FormationBlueprintCount
local FormationBlueprintCountCacheA = {}

---@type FormationBlueprintCount
local FormationBlueprintCountCacheB = {}

---@type FormationBlueprintList
local FormationBlueprintListCache = {
    Land = {},
    Air = {},
    Naval = {},
    Submersible = {}
}

---@type number[]
local FormationColumnOccupied = {}

--- A table that contains the tactical formation that we can re-use.
---@type Formation
local TacticalFormation = {}

-- upvalue scope for performance
local EntityCategoryContains = EntityCategoryContains

local MathSqrt = math.sqrt
local MathCeil = math.ceil
local MathMod = math.mod

local TableGetn = table.getn
local TableSetn = table.setn
local TableInsert = table.insert

--- Computes a square-shaped formation for the given unit count.
---@param unitCount number
---@return number   # rows
---@return number   # columns
local ComputeDimensions = function(unitCount)
    local sqrt = MathSqrt(unitCount)
    local ceil = MathCeil(sqrt)

    if MathMod(ceil, 2) == 0 then
        return ceil - 1, ceil + 1
    else
        return ceil, ceil
    end
end

---@param formationBlueprintCountCache FormationBlueprintCount
---@param formationBlueprintListCache BlueprintId[]
---@param preferences EntityCategory[]
---@return BlueprintId?
local GetFormationCategory = function(formationBlueprintCountCache, formationBlueprintListCache, preferences)
    for k = 1, TableGetn(preferences) do
        local category = preferences[k]
        for l = 1, TableGetn(formationBlueprintListCache) do
            local blueprintId = formationBlueprintListCache[l]
            if formationBlueprintCountCache[blueprintId] > 0 and EntityCategoryContains(category, blueprintId) then
                return blueprintId
            end
        end
    end

    return nil
end

---@param units (Unit[] | UserUnit[])
---@return Formation
ComputeFormation = function(units)

    local start = 0
    local getSystemTimeSecondsOnlyForProfileUse = rawget(_G, 'GetSystemTimeSecondsOnlyForProfileUse')
    if getSystemTimeSecondsOnlyForProfileUse then
        start = getSystemTimeSecondsOnlyForProfileUse()
    end

    -- local scope for performance
    local tacticalFormation = TacticalFormation
    local formationBlueprintCountCacheA = FormationBlueprintCountCacheA
    local formationBlueprintCountCacheB = FormationBlueprintCountCacheB

    -- gather information about the units
    local formationBlueprintCountCache, formationBlueprintListCache, unitCount = ComputeFormationProperties(
        units,
        FormationBlueprintCountCacheA,
        FormationBlueprintListCache
    )

    -- check if the formation is the same as the last one to avoid duplicate computations
    local equal = false
    for blueprintId, count in pairs(formationBlueprintCountCacheA) do
        if formationBlueprintCountCacheB[blueprintId] ~= count then
            equal = false
            break
        end
    end

    if equal then
        return tacticalFormation
    else
        for blueprintId, _ in formationBlueprintCountCacheB do
            formationBlueprintCountCacheB[blueprintId] = nil
        end

        for blueprintId, count in pairs(formationBlueprintCountCacheA) do
            formationBlueprintCountCacheB[blueprintId] = count
        end
    end

    -- clean up old entries
    for k = 1, TableGetn(tacticalFormation) do
        tacticalFormation[k] = nil
    end

    -- formation is not the same, re-compute it!
    TableSetn(tacticalFormation, 0)

    local footprintTotalLength, footprintMaximum = ComputeFootprintData(
        formationBlueprintCountCache,
        formationBlueprintListCache.Land
    )

    LOG(footprintTotalLength, footprintMaximum)
    local formationRows, formationColumns = ComputeDimensions(unitCount)

    local sparsityMultiplier = 1.5
    local unitsRemainingCount = unitCount

    -- populate the formation
    for ly = 1, formationRows do
        -- offset for the last row a tiny bit when the number of units is uneven
        local horizontalOffset = 0
        if unitsRemainingCount < formationColumns then
            if MathMod(unitsRemainingCount, 2) == 0 then
                horizontalOffset = -0.5 * sparsityMultiplier
            end
        end

        for lx = 0, formationColumns - 1 do

            -------------------------------------------------------------------
            -- pattern that allows us to grow from the center, as an example for
            -- 7 units the results look like:
            --
            -- - 0  -1  1   -2  2   -3  3
            --
            -- which is exactly what we want!

            local offset = MathCeil(0.5 * lx)
            local ox = offset
            if MathMod(lx, 2) == 0 then
                ox = -1 * offset
            end

            -------------------------------------------------------------------
            -- the category magic part where we try to find a pattern for the
            -- unit categories that looks decent. The first row is always the
            -- the general category, this garantees that if we have direct fire
            -- units that they end up in the front row. From the second row
            -- onwards we use a simple modulus to put categories in between
            -- that may make sense, such as shields and anti-air units

            local blueprintId

            if ly > 1 then

                local rowMod4 = MathMod(ly, 4)
                local columnMod3 = MathMod(offset, 3)

                if (rowMod4 == 0 or rowMod4 == 2) and columnMod3 == 2 then
                    -- we'd like a shield here
                    blueprintId = GetFormationCategory(
                        formationBlueprintCountCache,
                        formationBlueprintListCache["Land"],
                        LandShieldPreferences
                    )
                elseif rowMod4 == 3 and columnMod3 == 2 then
                    -- we'd like counter intelligence or a scout here
                    blueprintId = GetFormationCategory(
                        formationBlueprintCountCache,
                        formationBlueprintListCache["Land"],
                        LandCounterIntelligencePreferences
                    )
                elseif rowMod4 == 3 and columnMod3 == 1 then
                    -- we'd like a scout here
                    blueprintId = GetFormationCategory(
                        formationBlueprintCountCache,
                        formationBlueprintListCache["Land"],
                        LandCounterScoutPreferences
                    )
                elseif rowMod4 == 0 and (columnMod3 == 0 or columnMod3 == 1) then
                    -- we'd like anti air here
                    blueprintId = GetFormationCategory(
                        formationBlueprintCountCache,
                        formationBlueprintListCache["Land"],
                        LandAntiAirPreferences
                    )
                end
            end

            -- find a general category if we have no specific category

            if not blueprintId then
                blueprintId = GetFormationCategory(
                    formationBlueprintCountCache,
                    formationBlueprintListCache["Land"],
                    LandGeneralPreferences
                )
            end

            if blueprintId then

                -- decrease the count of the blueprint
                formationBlueprintCountCache[blueprintId] = formationBlueprintCountCache[blueprintId] - 1

                -------------------------------------------------------------------
                -- add the formation entry

                local formationIndex = TableGetn(tacticalFormation) + 1
                local formation = GetFormationEntry(formationIndex)
                formation[1] = horizontalOffset + sparsityMultiplier * ox
                formation[2] = sparsityMultiplier * (-1 * ly)
                formation[3] = categories[blueprintId]
                formation[4] = 0
                formation[5] = true
                TableInsert(tacticalFormation, formation)
            end
        end

        -- break if we have no units left
        if unitsRemainingCount > formationColumns then
            unitsRemainingCount = unitsRemainingCount - formationColumns
        else
            break
        end
    end

    if getSystemTimeSecondsOnlyForProfileUse then
        SPEW("Formation computation took " ..
            (getSystemTimeSecondsOnlyForProfileUse() - start) .. " seconds for " .. unitCount .. " units.")
    end

    return tacticalFormation
end
