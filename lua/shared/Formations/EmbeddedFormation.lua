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
local UpdateFormationLandCategories = import('/lua/shared/Formations/shared.lua').UpdateFormationLandCategories

local FormationScaleParameters = import('/lua/shared/Formations/FormationScale.lua').FormationScaleParameters
local ComputeFormationScale = import('/lua/shared/Formations/FormationScale.lua').ComputeFormationScale

local ComputeFootprintData = import('/lua/shared/Formations/FormationFootprints.lua').ComputeFootprintData

local GetFormationEntry = import('/lua/shared/Formations/Formation.lua').GetFormationEntry

local TableGetn = table.getn
local TableSetn = table.setn
local TableSort = table.sort
local TableInsert = table.insert

--- Returns the first blueprint identifier that is still available in the formationBlueprintCountCache.
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

---@param tacticalFormation Formation
---@param blueprintCountCache FormationBlueprintCount
---@param blueprintListCache BlueprintId[]  
---@param offsets number[] # { lx, lz, lx, lz, ... }
---@param cx number
---@param cz number
ComputeEmbeddedFormation = function(tacticalFormation, blueprintCountCache, blueprintListCache, offsets, cx, cz)
    for k = 0, 0.5 * TableGetn(offsets) - 1 do
        local lox = offsets[2 * k + 1]
        local loz = offsets[2 * k + 2]

        local blueprintId = GetCachedFormationSpecificCategory(blueprintCountCache, blueprintListCache)
        if blueprintId then
            local formationIndex = TableGetn(tacticalFormation) + 1
            local formation = GetFormationEntry(formationIndex)
            formation[1] = cx + lox
            formation[2] = cz + loz
            formation[3] = categories[blueprintId]
            formation[4] = 0
            formation[5] = false
            TableInsert(tacticalFormation, formation)

            -- we've consumed a unit, reduce the relevant counter
            blueprintCountCache[blueprintId] = blueprintCountCache[blueprintId] - 1
        end
    end
end