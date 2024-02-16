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

local LandFormationCategories = import("/lua/shared/Formations/LandFormationCategories.lua").LandFormationCategories

local Debug = true

if Debug then
    SPEW("Debug information for land formation preferences: ")
end

-- upvalue scope for performance
local EntityCategoryContains = EntityCategoryContains

local TableGetn = table.getn
local TableSetn = table.setn
local TableInsert = table.insert

-------------------------------------------------------------------------------
--#region Formation preferences

LandCommandFirst = {
    "LandFormationCategoriesCommand",
    "LandFormationCategoriesSupportCommand",
    "CategoriesAllUnits"
}

LandDirectFireFirst = {
    "LandFormationCategoriesDirectFire",
    "LandFormationCategoriesArtillery",
    "CategoriesAllUnits"
}

LandMissileFirst = {
    "LandFormationCategoriesMissile",
    "LandFormationCategoriesArtillery",
    "CategoriesAllUnits"
}

LandArtilleryFirst = {
    "LandFormationCategoriesArtillery",
    "LandFormationCategoriesMissile",
    "CategoriesAllUnits"
}

LandShieldFirst = {
    "LandFormationCategoriesShield",
    "LandFormationCategoriesScout",
    "CategoriesAllUnits"
}

LandSniperFirst = {
    "LandFormationCategoriesSniper",
    "LandFormationCategoriesMissile",
    "CategoriesAllUnits"
}

LandAntiAirFirst = {
    "LandFormationCategoriesAntiAir",
    "LandFormationCategoriesShield",
    "CategoriesAllUnits"
}

LandCounterintelligenceFirst = {
    "LandFormationCategoriesCounterintelligence",
    "LandFormationCategoriesScout",
    "CategoriesAllUnits"
}

LandIntelligenceFirst = {
    "LandFormationCategoriesScout",
    "LandFormationCategoriesShield",
    "CategoriesAllUnits"
}

LandEngineeringFirst = {
    "LandFormationCategoriesEngineeering",
    "LandFormationCategoriesSupportCommand",
    "CategoriesAllUnits"
}

LandFormationPreferences = {
    { Name = "LandCommandFirst", unpack(LandCommandFirst) },
    { Name = "LandDirectFireFirst", unpack(LandDirectFireFirst) },
    { Name = "LandMissileFirst", unpack(LandMissileFirst) },
    { Name = "LandArtilleryFirst", unpack(LandArtilleryFirst) },
    { Name = "LandShieldFirst", unpack(LandShieldFirst) },
    { Name = "LandSniperFirst", unpack(LandSniperFirst) },
    { Name = "LandAntiAirFirst", unpack(LandAntiAirFirst) },
    { Name = "LandCounterintelligenceFirst", unpack(LandCounterintelligenceFirst) },
    { Name = "LandIntelligenceFirst", unpack(LandIntelligenceFirst) },
    { Name = "LandEngineeringFirst", unpack(LandEngineeringFirst) },
}

if Debug then
    for k, landFormationPreference in LandFormationPreferences do
        SPEW(string.format(" - %s", k), table.getn(landFormationPreference))

        for l = 1, table.getn(landFormationPreference) do
            local landFormationCategory = landFormationPreference[l]
            if not LandFormationCategories[landFormationCategory] then
                WARN(
                    string.format(
                        "Invalid land formation category '%s' in land formation preference '%s'",
                        landFormationCategory, landFormationPreference.Name
                    )
                )
            end
        end
    end
end

--#endregion

-------------------------------------------------------------------------------
--#region Cached data structure

---@class CachedLandFormationPreferences

LandFormationPreferencesCache = {}

-- clean up prefererence table
for key, _ in LandFormationCategories do
    LandFormationPreferencesCache[key] = {}
end

---@param landFormationPreferencesCache CachedLandFormationPreferences
---@return CachedLandFormationPreferences
function CleanupLandFormationPreferences(landFormationPreferencesCache)
    for key, _ in LandFormationCategories do
        local landFormationPreference = landFormationPreferencesCache[key]
        for l = 1, TableGetn(landFormationPreference) do
            landFormationPreference[l] = nil
        end

        TableSetn(landFormationPreference, 0)
    end

    return landFormationPreferencesCache
end

---@param landFormationPreferencesCache CachedLandFormationPreferences
---@param blueprintListCache BlueprintId[]
---@param index number
---@return CachedLandFormationPreferences
function PopulateLandFormationPreferences(landFormationPreferencesCache, blueprintListCache, index)
    for _, blueprint in blueprintListCache do
        for k = 1, TableGetn(LandFormationPreferences) do
            local landFormationOrder = LandFormationPreferences[k]
            local landFormationKey = landFormationOrder[index]
            local landFormationCategory = LandFormationCategories[landFormationKey]

            if EntityCategoryContains(landFormationCategory, blueprint) then
                TableInsert(landFormationPreferencesCache[landFormationKey], blueprint)
                break
            end
        end
    end

    return landFormationPreferencesCache
end

--#endregion
