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

local SmallLandFormation = import('/lua/shared/Formations/AttackFormations/Land.lua').SmallLandFormation
local LandFormationOrders = import('/lua/shared/Formations/FormationGroups.lua').LandFormationOrders
local CategoriesLand = import("/lua/shared/Formations/FormationGroups.lua").CategoriesLand

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
AttackFormationLand = function(blueprintCountCache, blueprintListCache)

    -- clean up occupation data
    for o = 1, table.getn(oc) do
        oc[o] = false
    end

    local preference = {}

    for index = 1, 3 do

        -- clean up prefererence table
        for key, _  in CategoriesLand do
            preference[key] = preference[key] or {}
            for l = 1, table.getn(preference) do
                preference[key][l] = nil
            end
        end

        -- populate preference table
        for _, blueprint in blueprintListCache do
            for k = 1, table.getn(LandFormationOrders) do
                local landFormationOrder = LandFormationOrders[k]
                local landFormationKey = landFormationOrder[index]
                local landFormationCategory = CategoriesLand[ landFormationKey ]

                if EntityCategoryContains(landFormationCategory, blueprint) then
                    table.insert(preference[landFormationKey], blueprint)
                    break
                end
            end
        end

        -- choose a formation
        local formation = SmallLandFormation

        -- go through the formation to apply the preference
        local countRows = table.getn(formation)

        for ly = 1, countRows do
            local row = formation[ly]
            local countColumns = table.getn(row)
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
                    for k = 1, table.getn(firstPreferences) do
                        local blueprintId = firstPreferences[k]
                        local blueprintIdCount = blueprintCountCache[blueprintId]
                        if blueprintIdCount > 0 then
                            blueprintCountCache[blueprintId] = blueprintCountCache[blueprintId] - 1

                            oc[oi] = blueprintId
                            TacticalFormation[oi] = { lx - halfColumns, -1 * ly, categories[blueprintId], 0, true }
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
    -- clean up old formation data
    for k = 1, table.getn(TacticalFormation) do
        TacticalFormation[k] = nil
    end

    -- gather information about the units
    local blueprintLookup, blueprintList, unitCount = ToBlueprintLookup(units, BlueprintLookup, BlueprintList)
    local maximumFootprintSize = MaximumFootprint(blueprintLookup)

    return AttackFormationLand(blueprintLookup, blueprintList)

    -- -- choose a formation
    -- local formation = SmallLandFormation

    -- -- for each unit
    -- for blueprintId, count in blueprintLookup do

    --     local processed = 0
    --     -- go through each category layer
    --     for c = 1, table.getsize(CategoriesLand) do



    --         -- go through reach row
    --         local countRows = table.getn(formation)
    --         local halfRows = math.floor(0.5 * countRows)

    --         for ly = 1, countRows do
    --             local row = formation[ly]
    --             local countColumns = table.getn(row)
    --             local halfColumns = math.floor(0.5 * countColumns)

    --             -- go through reach column
    --             for lx = 1, countColumns do
    --                 local cell = row[lx]

    --                 local oi       = (ly - 1) * countColumns + lx
    --                 local occupied = oc[oi]

    --                 -- if this cell is not occupied
    --                 if not occupied then

    --                     -- and we fit the category, then we put ourselves there
    --                     local categoryIdentifier = cell[c]
    --                     if EntityCategoryContains(categoryIdentifier, blueprintId) then
    --                         TacticalFormation[oi] = { lx - halfColumns, -1 * ly, categories[blueprintId], 0, true }
    --                         oc[oi] = true

    --                         -- skip to the next category
    --                         processed = processed + 1
    --                         if processed >= count then
    --                             break
    --                         end
    --                     end
    --                 end
    --             end

    --             -- skip to the next category
    --             if processed >= count then
    --                 break
    --             end
    --         end

    --         -- skip to the next category
    --         if processed >= count then
    --             break
    --         end
    --     end
    -- end

    -- return TacticalFormation
end
