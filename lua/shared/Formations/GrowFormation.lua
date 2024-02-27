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
local GetFormationEntry = import('/lua/shared/Formations/Formation.lua').GetFormationEntry

-- preferences for land
local LandGeneralFirst = import("/lua/shared/Formations/LandFormationPreferences.lua").LandGeneralFirst
local LandColumnPreferences = import("/lua/shared/Formations/LandFormationPreferences.lua").LandColumnPreferences

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
                formationBlueprintCountCache[blueprintId] = formationBlueprintCountCache[blueprintId] - 1
                return blueprintId
            end
        end
    end

    return nil
end

---@param formationBlueprintCountCache FormationBlueprintCount
---@param formationBlueprintListCache BlueprintId[]
---@param preferences EntityCategory[]
---@return BlueprintId?
local GetFormationColumnCategory = function(formationBlueprintCountCache, formationBlueprintListCache, preferences, index)
    local category = preferences[index]
    for l = 1, TableGetn(formationBlueprintListCache) do
        local blueprintId = formationBlueprintListCache[l]
        if formationBlueprintCountCache[blueprintId] > 0 and EntityCategoryContains(category, blueprintId) then
            formationBlueprintCountCache[blueprintId] = formationBlueprintCountCache[blueprintId] - 1
            return blueprintId
        end
    end

    return nil
end

---@param units (Unit[] | UserUnit[])
---@return Formation
ComputeFormation = function(units)

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
    local equal = true
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

    -- formation is not the same, re-compute it!
    TableSetn(tacticalFormation, 0)

    local formationRows, formationColumns = ComputeDimensions(unitCount)

    local sparsityMultiplier = 1.25
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
            -- that may make sense, such as shields and anti-air units.

            local blueprintId
            local columnMod = MathMod(offset, TableGetn(LandColumnPreferences) + 1)
            if ly == 1 or columnMod == 0 then
                blueprintId = GetFormationCategory(
                    formationBlueprintCountCache,
                    formationBlueprintListCache["Land"],
                    LandGeneralFirst
                )
            else
                blueprintId = GetFormationColumnCategory(
                    formationBlueprintCountCache,
                    formationBlueprintListCache["Land"],
                    LandColumnPreferences,
                    columnMod
                )
            end

            -------------------------------------------------------------------
            -- this should never happen, but life's full of surprises.

            if not blueprintId then
                for k = 1, TableGetn(formationBlueprintListCache["Land"]) do
                    local remainingBlueprintId = formationBlueprintListCache["Land"][k]
                    if formationBlueprintCountCache[remainingBlueprintId] > 0 then
                        formationBlueprintCountCache[remainingBlueprintId] = formationBlueprintCountCache[
                            remainingBlueprintId] - 1
                        blueprintId = remainingBlueprintId
                        break
                    end
                end
            end

            -------------------------------------------------------------------
            -- add the formation entry.

            local formationIndex = TableGetn(tacticalFormation) + 1
            local formation = GetFormationEntry(formationIndex)
            formation[1] = horizontalOffset + sparsityMultiplier * ox
            formation[2] = sparsityMultiplier * (-1 * ly)
            formation[3] = categories[blueprintId]
            TableInsert(tacticalFormation, formation)
        end

        -- break if we have no units left
        if unitsRemainingCount > formationColumns then
            unitsRemainingCount = unitsRemainingCount - formationColumns
        else
            break
        end
    end

    -- clean up remaining entries
    for k = unitCount + 1, TableGetn(tacticalFormation) do
        tacticalFormation[k] = nil
    end

    return tacticalFormation
end
