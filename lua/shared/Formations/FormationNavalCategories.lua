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

local Debug = true

if Debug then
    SPEW("Debug information for naval formation categories: ")
end

-------------------------------------------------------------------------------
--#region Formation categories

local CategoriesAllUnits = categories.ALLUNITS

local NavalFormationCategoriesLightBoat = categories.LIGHTBOAT
local NavalFormationCategoriesFrigate = categories.FRIGATE
local NavalFormationCategoriesDestroyer = categories.DESTROYER + (categories.DIRECTFIRE - (categories.FRIGATE + categories.WEAKDIRECTFIRE))
local NavalFormationCategoriesCruiser = (categories.CRUISER + categories.ANTIAIR) - categories.FRIGATE
local NavalFormationCategoriesBombardment = categories.BATTLESHIP + categories.INDIRECTFIRE
local NavalFormationCategoriesCarrier = categories.CARRIER
local NavalFormationCategoriesSonar = categories.SONAR
local NavalFormationCategoriesShield = categories.SHIELD
local NavalFormationCategoriesCounterIntelligence = categories.COUNTERINTELLIGENCE

NavalFormationCategories = {
    CategoriesAllUnits = categories.NAVAL * CategoriesAllUnits,

    NavalFormationCategoriesLightBoat = categories.NAVAL * NavalFormationCategoriesLightBoat,
    
    NavalFormationCategoriesFrigate = categories.NAVAL * NavalFormationCategoriesFrigate,
    NavalFormationCategoriesDestroyer = categories.NAVAL * NavalFormationCategoriesDestroyer,

    NavalFormationCategoriesCruiser = categories.NAVAL * NavalFormationCategoriesCruiser,
    NavalFormationCategoriesSonar = categories.NAVAL * NavalFormationCategoriesSonar,
    NavalFormationCategoriesBombardment = categories.NAVAL * NavalFormationCategoriesBombardment,
    NavalFormationCategoriesCarrier = categories.NAVAL * NavalFormationCategoriesCarrier,
    navalFormationCategoriesShield = categories.NAVAL * NavalFormationCategoriesShield,
    NavalFormationCategoriesCounterIntelligence = categories.NAVAL * NavalFormationCategoriesCounterIntelligence,
}

if Debug then
    for k, v in NavalFormationCategories do
        SPEW(string.format(" - %s", k), repru(EntityCategoryGetUnitList(v), 1000 * 1000))
    end
end

--#endregion
