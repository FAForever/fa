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

local FormationBlueprintListCache = import('/lua/shared/Formations/shared.lua').FormationBlueprintListCache
local ComputeFormationProperties = import('/lua/shared/Formations/shared.lua').ComputeFormationProperties
local UpdateFormationLandProperties = import('/lua/shared/Formations/shared.lua').UpdateFormationLandProperties
local ComputeFootprintData = import('/lua/shared/Formations/shared.lua').ComputeFootprintData

local FormationScaleParameters = import('/lua/shared/Formations/FormationScale.lua').FormationScaleParameters
local ComputeFormationScale = import('/lua/shared/Formations/FormationScale.lua').ComputeFormationScale

local GetFormationEntry = import('/lua/shared/Formations/Formation.lua').GetFormationEntry

--- A table that contains the blueprint lookups that we can re-use.
---@type FormationBlueprintCount
local FormationBlueprintCountCacheA = {}

---@type FormationBlueprintCount
local FormationBlueprintCountCacheB = {}

---@type number[]
local FormationColumnOccupied = {}

--- A table that contains the tactical formation that we can re-use.
---@type Formation
local TacticalFormation = {}

local MathSqrt = math.sqrt
local MathCeil = math.ceil
local MathMod = math.mod
local MathFloor = math.floor

local TableGetn = table.getn
local TableSetn = table.setn
local TableInsert = table.insert

---@param formationBlueprintCountCache FormationBlueprintCount
---@param formationBlueprintListCache BlueprintId[]
---@return BlueprintId?
local GetCachedFormationSpecificCategory = function(formationBlueprintCountCache, formationBlueprintListCache)
    for k = 1, TableGetn(formationBlueprintListCache) do
        local blueprintId = formationBlueprintListCache[k]
        if formationBlueprintCountCache[blueprintId] > 0 then
            return blueprintId
        end
    end
end

---@param formationBlueprintCountCache FormationBlueprintCount
---@param formationBlueprintListCache BlueprintId[][]
local GetCachedFormationGeneralCategory = function(formationBlueprintCountCache, formationBlueprintListCache)
    for k = 1, TableGetn(formationBlueprintListCache) do
        local blueprintIds = formationBlueprintListCache[k]
        for b = 1, TableGetn(blueprintIds) do
            local blueprintId = blueprintIds[b]
            if formationBlueprintCountCache[blueprintId] > 0 then
                return blueprintId
            end
        end
    end
end

--- Constructs a land formation for the given blueprint identifiers.
---@param formationBlueprintCountCache FormationBlueprintCount
---@param formationBlueprintListLand FormationBlueprintListLand
ComputeLandFormation = function(formationBlueprintCountCache, formationBlueprintListLand, formationScaleParameters)
    -- local scope for performance
    local tacticalFormation = TacticalFormation
    local formationColumnOccupied = FormationColumnOccupied

    local formationBlueprintListLandGeneral = formationBlueprintListLand.General
    local formationBlueprintListLandShield = formationBlueprintListLand.Shield
    local formationBlueprintListLandCounterIntelligence = formationBlueprintListLand.CounterIntelligence
    local formationBlueprintListLandScout = formationBlueprintListLand.Scout
    local formationBlueprintListLandAntiAir = formationBlueprintListLand.AntiAir

    -- compute total land unit count
    local unitsToProcess = 0
    for k = 1, TableGetn(formationBlueprintListLand) do
        local blueprintId = formationBlueprintListLand[k]
        unitsToProcess = unitsToProcess + formationBlueprintCountCache[blueprintId]
    end

    -- compute length of each row
    local footprintTotalLength, footprintMinimum, footprintMaximum = ComputeFootprintData(
        formationBlueprintCountCache,
        formationBlueprintListLand
    )

    local formationScale = ComputeFormationScale(formationScaleParameters, footprintMinimum, footprintMaximum)
    local formationRowLengthHalf = MathCeil(MathSqrt(footprintTotalLength))
    local formationRowLength = 2 * formationRowLengthHalf

    local sparsityMultiplier = 1.25

    local lx = 0
    local ly = 0

    for k = 1, formationRowLength do
        formationColumnOccupied[k] = 0
    end

    -- process rows
    while unitsToProcess > 0 do

        lx = 1
        ly = ly + 1

        -- we decrease the columns one as we move a row backwards the rows
        for k = 1, TableGetn(formationColumnOccupied) do
            formationColumnOccupied[k] = formationColumnOccupied[k] - 1
        end

        -- process columns (of a row)
        while (unitsToProcess > 0) and (lx < formationRowLength) do

            -------------------------------------------------------------------
            -- pattern that allows us to grow from the center, as an example for
            -- 7 units the results look like:
            --
            -- - 0  -1  1   -2  2   -3  3

            local offset = MathCeil(0.5 * (lx - 1))
            local ox = offset
            if MathMod(lx, 2) == 0 then
                ox = -1 * offset
            end

            -- skip if the column on this row is occupied
            if formationColumnOccupied[ox + formationRowLengthHalf + 1] > 0 then
                lx = lx + 1
                continue
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
                    blueprintId = GetCachedFormationSpecificCategory(
                        formationBlueprintCountCache,
                        formationBlueprintListLandShield
                    )
                elseif rowMod4 == 3 and columnMod3 == 2 then
                    -- we'd like counter intelligence or a scout here
                    blueprintId = GetCachedFormationSpecificCategory(
                        formationBlueprintCountCache,
                        formationBlueprintListLandCounterIntelligence
                    )
                elseif rowMod4 == 3 and columnMod3 == 1 then
                    -- we'd like a scout here
                    blueprintId = GetCachedFormationSpecificCategory(
                        formationBlueprintCountCache,
                        formationBlueprintListLandScout
                    )
                elseif rowMod4 == 0 and (columnMod3 == 0 or columnMod3 == 1) then
                    -- we'd like anti air here
                    blueprintId = GetCachedFormationSpecificCategory(
                        formationBlueprintCountCache,
                        formationBlueprintListLandAntiAir
                    )
                end
            end

            -- find a general category if we have no specific category

            if not blueprintId then
                blueprintId = GetCachedFormationGeneralCategory(
                    formationBlueprintCountCache,
                    formationBlueprintListLandGeneral
                )
            end

            if blueprintId then

                -- decrease the total unit count
                unitsToProcess = unitsToProcess - 1

                -- decrease the blueprint unit count
                formationBlueprintCountCache[blueprintId] = formationBlueprintCountCache[blueprintId] - 1

                local blueprintFootprint = __blueprints[blueprintId].Footprint
                local blueprintFootprintSizeX = blueprintFootprint.SizeX
                local blueprintFootprintSizeZ = blueprintFootprint.SizeZ

                -- occupy the next few rows for the current columns to make space for this unit
                local lower = MathCeil(-0.5 * blueprintFootprintSizeX / sparsityMultiplier)
                local upper = MathFloor(0.5 * blueprintFootprintSizeX / sparsityMultiplier)
                for k = lower, upper do
                    local index = ox + formationRowLengthHalf + k + 1
                    if index > 0 and index <= formationRowLength then
                        formationColumnOccupied[index] = MathCeil(blueprintFootprintSizeZ / sparsityMultiplier)
                    end
                end

                -- increase the current formation length
                lx = lx + 1

                -------------------------------------------------------------------
                -- add the formation entry

                local formationIndex = TableGetn(tacticalFormation) + 1
                local formation = GetFormationEntry(formationIndex)
                formation[1] = sparsityMultiplier * (formationScale * ox)
                formation[2] = sparsityMultiplier * (formationScale * (-1 * (ly - 1) - 0.5 * blueprintFootprintSizeZ))
                formation[3] = categories[blueprintId]
                formation[4] = 0
                formation[5] = true
                TableInsert(tacticalFormation, formation)
            else
                LOG("No blueprint!", lx, unitsToProcess, formationRowLength, ly, formationColumnOccupied[lx])
                lx = lx + 1
                unitsToProcess = unitsToProcess - 1
            end
        end

        -- update the lookup data for the next row
        UpdateFormationLandProperties(formationBlueprintCountCache, formationBlueprintListLand)
    end
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

    ComputeLandFormation(formationBlueprintCountCache, formationBlueprintListCache.Land, FormationScaleParameters.Land)

    return tacticalFormation
end
