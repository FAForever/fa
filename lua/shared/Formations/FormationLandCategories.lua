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
    SPEW("Debug information for land formation categories: ")
end

-------------------------------------------------------------------------------
--#region Basic categories

local LAND = categories.LAND
local ANTIAIR = categories.ANTIAIR
local ARTILLERY = categories.ARTILLERY
local COMMAND = categories.COMMAND
local COUNTERINTELLIGENCE = categories.COUNTERINTELLIGENCE
local DIRECTFIRE = categories.DIRECTFIRE
local ENGINEER = categories.ENGINEER
local INDIRECTFIRE = categories.INDIRECTFIRE
local SCOUT = categories.SCOUT
local SHIELD = categories.SHIELD
local SILO = categories.SILO
local SNIPER = categories.SNIPER
local WEAKANTIAIR = categories.WEAKANTIAIR
local WEAKDIRECTFIRE = categories.WEAKDIRECTFIRE
local WEAKINDIRECTFIRE = categories.WEAKINDIRECTFIRE

--#endregion

-------------------------------------------------------------------------------
--#region Formation categories

local CategoriesAllUnits = categories.ALLUNITS

local LandFormationCategoriesCommand = COMMAND
local LandFormationCategoriesSupportCommand = categories.SUBCOMMANDER

local LandFormationCategoriesDirectFire = (DIRECTFIRE) - (SNIPER + WEAKDIRECTFIRE + COMMAND + SCOUT)
local LandFormationCategoriesSniper = (SNIPER)
local LandFormationCategoriesArtillery = (ARTILLERY + INDIRECTFIRE) - (WEAKINDIRECTFIRE)
local LandFormationCategoriesMissile = (SILO) - (WEAKINDIRECTFIRE)
local LandFormationCategoriesAntiAir = (ANTIAIR) - (WEAKANTIAIR)
local LandFormationCategoriesShield = (SHIELD)
local LandFormationCategoriesEngineering = (ENGINEER) - (COMMAND)
local LandFormationCategoriesScout = (SCOUT)
local LandFormationCategoriesCounterintelligence = (COUNTERINTELLIGENCE) - (DIRECTFIRE + ANTIAIR + INDIRECTFIRE)
local LandFormationCategoriesEngineeering = (ENGINEER) - (DIRECTFIRE + ANTIAIR + INDIRECTFIRE)

LandFormationCategories = {
    CategoriesAllUnits = CategoriesAllUnits,

    LandFormationCategoriesCommand = LAND * LandFormationCategoriesCommand,
    LandFormationCategoriesSupportCommand = LAND * LandFormationCategoriesSupportCommand,
    LandFormationCategoriesEngineering = LAND * LandFormationCategoriesEngineering,

    LandFormationCategoriesDirectFire = LAND * LandFormationCategoriesDirectFire,
    LandFormationCategoriesSniper = LAND * LandFormationCategoriesSniper,
    LandFormationCategoriesArtillery = LAND * LandFormationCategoriesArtillery,
    LandFormationCategoriesMissile = LAND * LandFormationCategoriesMissile,
    LandFormationCategoriesAntiAir = LAND * LandFormationCategoriesAntiAir,
    LandFormationCategoriesShield = LAND * LandFormationCategoriesShield,
    LandFormationCategoriesScout = LAND * LandFormationCategoriesScout,
    LandFormationCategoriesCounterintelligence = LAND * LandFormationCategoriesCounterintelligence,
    LandFormationCategoriesEngineeering = LAND * LandFormationCategoriesEngineeering,
}

if Debug then
    for k, v in LandFormationCategories do
        SPEW(string.format(" - %s", k), repru(EntityCategoryGetUnitList(v), 1000 * 1000))
    end
end

--#endregion
