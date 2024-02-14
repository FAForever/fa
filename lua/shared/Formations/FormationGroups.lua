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

-------------------------------------------------------------------------------
--#region General groups of units that we'll take into account

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

local CategoriesDirectFire = (DIRECTFIRE) - (SNIPER + WEAKDIRECTFIRE + COMMAND)
local CategoriesSniper = (SNIPER)
local CategoriesArtillery = (ARTILLERY + INDIRECTFIRE) - (WEAKINDIRECTFIRE)
local CategoriesMissile = (SILO) - (WEAKINDIRECTFIRE)
local CategoriesAntiAir = (ANTIAIR) - (WEAKANTIAIR)
local CategoriesShield = (SHIELD)
local CategoriesScout = (SCOUT) - (DIRECTFIRE + ANTIAIR + INDIRECTFIRE)
local CategoriesCounterintelligence = (COUNTERINTELLIGENCE) - (DIRECTFIRE + ANTIAIR + INDIRECTFIRE)
local CategoriesEngineering = (ENGINEER) - (COMMAND)

--#endregion

-------------------------------------------------------------------------------
--#region Other groups of units

if Debug then
    SPEW("Debug information for other formations: ")
end

CategoriesCommand = COMMAND
CategoriesSupportCommand = categories.SUBCOMMANDER
CategoriesAllUnits = categories.ALLUNITS

if Debug then
    SPEW(" - Command", repru(EntityCategoryGetUnitList(CategoriesCommand), 1000 * 1000))
    SPEW(" - SupportCommand", repru(EntityCategoryGetUnitList(CategoriesSupportCommand), 1000 * 1000))
end

--#endregion

-------------------------------------------------------------------------------
--#region  Groups of land units

if Debug then
    SPEW("Debug information for land formations: ")
end

local LAND = categories.LAND

CategoriesLandDirectFire = LAND * CategoriesDirectFire
CategoriesLandSniper = LAND * CategoriesSniper
CategoriesLandArtillery = LAND * CategoriesArtillery
CategoriesLandMissile = LAND * CategoriesMissile
CategoriesLandAntiAir = LAND * CategoriesAntiAir
CategoriesLandShield = LAND * CategoriesShield
CategoriesLandEngineering = LAND * CategoriesEngineering
CategoriesLandScout = LAND * CategoriesScout
CategoriesLandCounterintelligence = LAND * CategoriesCounterintelligence

CategoriesLand = {
    CategoriesCommand = CategoriesCommand,
    CategoriesSupportCommand = CategoriesSupportCommand,
    CategoriesLandEngineering = CategoriesLandEngineering,

    CategoriesLandDirectFire = CategoriesLandDirectFire,
    CategoriesLandSniper = CategoriesLandSniper,
    CategoriesLandArtillery = CategoriesLandArtillery,
    CategoriesLandMissile = CategoriesLandMissile,
    CategoriesLandAntiAir = CategoriesLandAntiAir,
    CategoriesLandShield = CategoriesLandShield,
    CategoriesLandScout = CategoriesLandScout,
    CategoriesLandCounterintelligence = CategoriesLandCounterintelligence,

    CategoriesAllUnits = CategoriesAllUnits,
}

if Debug then
    for k, v in CategoriesLand do
        SPEW(string.format(" - %s", k), repru(EntityCategoryGetUnitList(v), 1000 * 1000))
    end
end

LandCommandFirst = { "CategoriesCommand", "CategoriesSupportCommand", "CategoriesAllUnits" }
LandDirectFireFirst = { "CategoriesLandDirectFire", "CategoriesLandArtillery", "CategoriesAllUnits" }
LandMissileFirst = { "CategoriesLandMissile", "CategoriesLandArtillery", "CategoriesAllUnits" }
LandArtilleryFirst = { "CategoriesLandArtillery", "CategoriesLandMissile", "CategoriesAllUnits" }
LandShieldFirst = { "CategoriesLandShield", "CategoriesLandScout", "CategoriesAllUnits" }
LandSniperFirst = { "CategoriesLandSniper", "CategoriesLandMissile", "CategoriesAllUnits" }
LandAntiAirFirst = { "CategoriesLandAntiAir", "CategoriesLandShield", "CategoriesAllUnits" }
LandCounterintelligenceFirst = { "CategoriesLandCounterintelligence", "CategoriesLandScout", "CategoriesAllUnits" }
LandIntelligenceFirst = { "CategoriesLandScout", "CategoriesLandShield", "CategoriesAllUnits" }
LandEngineeringFirst = { "CategoriesLandEngineering", "CategoriesSupportCommand", "CategoriesAllUnits" }

LandFormationOrders = {
     { Name = "LandCommandFirst", unpack (LandCommandFirst) },
     { Name = "LandDirectFireFirst", unpack (LandDirectFireFirst) },
     { Name = "LandMissileFirst", unpack (LandMissileFirst) },
     { Name = "LandArtilleryFirst", unpack (LandArtilleryFirst) },
     { Name = "LandShieldFirst", unpack (LandShieldFirst) },
     { Name = "LandSniperFirst", unpack (LandSniperFirst) },
     { Name = "LandAntiAirFirst", unpack (LandAntiAirFirst) },
     { Name = "LandCounterintelligenceFirst", unpack (LandCounterintelligenceFirst) },
     { Name = "LandIntelligenceFirst", unpack (LandIntelligenceFirst)  },
     { Name = "LandEngineeringFirst", unpack (LandEngineeringFirst) },
}

if Debug then
    for k, v in LandFormationOrders do
        SPEW(string.format(" - %s", k), table.getn(v))
    end
end

--#endregion

-------------------------------------------------------------------------------
--#region Groups of naval/hover units

if Debug then
    SPEW("Debug information for naval/hover formations: ")
end

local AMPHIBIOUS = categories.AMPHIBIOUS
local HOVER = categories.HOVER
local NAVAL = categories.NAVAL
local SUBMERSIBLE = categories.SUBMERSIBLE
local STRATEGIC = categories.STRATEGIC

CategoriesNavalDirectFire = (NAVAL) * (CategoriesDirectFire)
CategoriesNavalArtillery = (NAVAL) * (CategoriesArtillery)
CategoriesNavalMissile = (NAVAL) * (CategoriesMissile)
CategoriesNavalAntiAir = (NAVAL) * (CategoriesAntiAir)
CategoriesNavalShield = (NAVAL) * (CategoriesShield)
CategoriesNavalScout = (NAVAL) * (CategoriesScout)
CategoriesNavalCounterIntelligence = (NAVAL) * (CategoriesCounterintelligence)
CategoriesNavalSubmarine = (SUBMERSIBLE) - (STRATEGIC)
CategoriesNavalAmphibious = (AMPHIBIOUS)
CategoriesNavalStrategicSubmarine = (SUBMERSIBLE * STRATEGIC)
CategoriesNavalEngineering = (NAVAL + AMPHIBIOUS) * (CategoriesEngineering)

CategoriesNaval = {
    CategoriesNavalDirectFire = CategoriesNavalDirectFire,
    CategoriesNavalArtillery = CategoriesNavalArtillery,
    CategoriesNavalMissile = CategoriesNavalMissile,
    CategoriesNavalAntiAir = CategoriesNavalAntiAir,
    CategoriesNavalShield = CategoriesNavalShield,
    CategoriesNavalScout = CategoriesNavalScout,
    CategoriesNavalCounterIntelligence = CategoriesNavalCounterIntelligence,
    CategoriesNavalSubmarine = CategoriesNavalSubmarine,
    CategoriesNavalAmphibious = CategoriesNavalAmphibious,
    CategoriesNavalStrategicSubmarine = CategoriesNavalStrategicSubmarine,
    CategoriesNavalEngineering = CategoriesNavalEngineering,

    CategoriesSupportCommand = CategoriesSupportCommand,
    CategoriesCommand = CategoriesCommand
}

CategoriesHoverDirectFire = (HOVER) * (CategoriesDirectFire)
CategoriesHoverAntiAir = (HOVER) * (CategoriesAntiAir)
CategoriesHoverShield = (HOVER) * (CategoriesShield)
CategoriesHoverOther = (HOVER) - (CategoriesDirectFire + CategoriesAntiAir + CategoriesShield)

CategoriesHover = {
    CategoriesHoverDirectFire = CategoriesHoverDirectFire,
    CategoriesHoverAntiAir = CategoriesHoverAntiAir,
    CategoriesHoverShield = CategoriesHoverShield,
    CategoriesHoverOther = CategoriesHoverOther,
}

if Debug then
    for k, v in CategoriesNaval do
        SPEW(string.format(" - %s", k), repru(EntityCategoryGetUnitList(v), 1000 * 1000))
    end

    for k, v in CategoriesHover do
        SPEW(string.format(" - %s", k), repru(EntityCategoryGetUnitList(v), 1000 * 1000))
    end
end

NavalDirectFireFirst = {
    "CategoriesNavalDirectFire", "CategoriesHoverDirectFire", "CategoriesHoverShield", "CategoriesNavalScout",
    "CategoriesNavalAntiAir", "CategoriesHoverAntiAir", "CategoriesNavalMissile", "CategoriesNavalArtillery",
    "CategoriesNavalShield", "CategoriesNavalCounterIntelligence", "CategoriesHoverOther", "CategoriesNavalEngineering"
}

NavalMissileFirst = {
    "CategoriesNavalMissile", "CategoriesNavalArtillery", "CategoriesNavalScout", "CategoriesNavalDirectFire",
    "CategoriesHoverDirectFire", "CategoriesNavalAntiAir", "CategoriesHoverAntiAir", "CategoriesNavalShield",
    "CategoriesHoverShield", "CategoriesNavalCounterIntelligence", "CategoriesHoverOther", "CategoriesNavalEngineering"
}

NavalArtilleryFirst = {
    "CategoriesNavalArtillery", "CategoriesNavalMissile", "CategoriesNavalScout", "CategoriesNavalDirectFire",
    "CategoriesHoverDirectFire", "CategoriesNavalAntiAir", "CategoriesHoverAntiAir", "CategoriesNavalShield",
    "CategoriesNavalCounterIntelligence", "CategoriesHoverOther", "CategoriesNavalEngineering"
}

NavalShieldFirst = {
    "CategoriesNavalShield", "CategoriesNavalScout", "CategoriesNavalDirectFire", "CategoriesHoverDirectFire",
    "CategoriesNavalAntiAir", "CategoriesHoverAntiAir", "CategoriesNavalMissile", "CategoriesNavalArtillery",
    "CategoriesNavalCounterIntelligence", "CategoriesHoverOther", "CategoriesNavalEngineering"
}

NavalAntiAirFirst = {
    "CategoriesNavalAntiAir", "CategoriesHoverAntiAir", "CategoriesNavalScout", "CategoriesNavalShield",
    "CategoriesNavalDirectFire", "CategoriesHoverDirectFire", "CategoriesNavalArtillery", "CategoriesNavalMissile",
    "CategoriesNavalCounterIntelligence", "CategoriesHoverOther", "CategoriesNavalEngineering"
}

NavalCounterintelligenceFirst = {
    "CategoriesNavalCounterIntelligence", "CategoriesNavalScout", "CategoriesNavalDirectFire",
    "CategoriesHoverDirectFire", "CategoriesNavalAntiAir", "CategoriesHoverAntiAir", "CategoriesNavalMissile",
    "CategoriesNavalArtillery", "CategoriesNavalShield", "CategoriesHoverOther", "CategoriesNavalEngineering"
}

NavalIntelligenceFirst = {
    "CategoriesNavalScout", "CategoriesNavalCounterIntelligence", "CategoriesNavalDirectFire",
    "CategoriesHoverDirectFire", "CategoriesNavalAntiAir", "CategoriesHoverAntiAir", "CategoriesNavalMissile",
    "CategoriesNavalArtillery", "CategoriesNavalShield", "CategoriesHoverOther", "CategoriesNavalEngineering"
}

NavalEngineeringFirst = {
    "CategoriesNavalEngineering", "CategoriesNavalScout", "CategoriesNavalCounterIntelligence",
    "CategoriesNavalDirectFire", "CategoriesHoverDirectFire", "CategoriesNavalAntiAir", "CategoriesHoverAntiAir",
    "CategoriesNavalMissile", "CategoriesNavalArtillery", "CategoriesNavalShield", "CategoriesHoverOther",
}

NavalSubmarineFirst = {
    "CategoriesNavalSubmarine", "CategoriesNavalAmphibious", "CategoriesNavalStrategicSubmarine",
}

NavalAmphibiousFirst = {
    "CategoriesNavalAmphibious", "CategoriesNavalSubmarine", "CategoriesNavalStrategicSubmarine"
}

NavalFormationOrders = {
    NavalDirectFireFirst = NavalDirectFireFirst,
    NavalMissileFirst = NavalMissileFirst,
    NavalArtilleryFirst = NavalArtilleryFirst,
    NavalShieldFirst = NavalShieldFirst,
    NavalAntiAirFirst = NavalAntiAirFirst,
    NavalCounterintelligenceFirst = NavalCounterintelligenceFirst,
    NavalIntelligenceFirst = NavalIntelligenceFirst,
    NavalEngineeringFirst = NavalEngineeringFirst,
    NavalSubmarineFirst = NavalSubmarineFirst,
    NavalAmphibiousFirst = NavalAmphibiousFirst,
}

if Debug then
    for k, v in NavalFormationOrders do
        SPEW(string.format(" - %s", k), table.getn(v))

        for _, entry in v do
            if not (CategoriesNaval[entry] or CategoriesHover[entry]) then
                WARN(string.format("   - %s is not a valid category", entry))
            end
        end
    end
end

--#endregion

-------------------------------------------------------------------------------
--#region Groups of air units

if Debug then
    SPEW("Debug information for air formations: ")
end

local AIR = categories.AIR
local BOMBER = categories.BOMBER
local GROUNDATTACK = categories.GROUNDATTACK
local TRANSPORTATION = categories.TRANSPORTATION

CategoriesAirAntiAir = (AIR) * (CategoriesAntiAir)
CategoriesAirGunship = (AIR) * (GROUNDATTACK)
CategoriesAirBomber = (AIR) * (BOMBER)
CategoriesAirTransport = (AIR) * (TRANSPORTATION - GROUNDATTACK)
CategoriesAirScout = (AIR) * (CategoriesScout)

CategoriesAir = {
    CategoriesAirAntiAir = CategoriesAirAntiAir,
    CategoriesAirGunship = CategoriesAirGunship,
    CategoriesAirBomber = CategoriesAirBomber,
    CategoriesAirTransport = CategoriesAirTransport,
    CategoriesAirScout = CategoriesAirScout,
}

if Debug then
    for k, v in CategoriesAir do
        SPEW(string.format(" - %s", k), repru(EntityCategoryGetUnitList(v), 1000 * 1000))
    end
end

AirAntiAirFirst = {
    "CategoriesAirAntiAir", "CategoriesAirScout", "CategoriesAirGunship", "CategoriesAirBomber", "CategoriesAirTransport"
}

AirGunshipFirst = {
    "CategoriesAirGunship", "CategoriesAirBomber", "CategoriesAirScout", "CategoriesAirAntiAir", "CategoriesAirTransport"
}

AirBomberFirst = {
    "CategoriesAirBomber", "CategoriesAirGunship", "CategoriesAirScout", "CategoriesAirAntiAir", "CategoriesAirTransport"
}

AirTransportFirst = {
    "CategoriesAirTransport", "CategoriesAirAntiAir", "CategoriesAirScout", "CategoriesAirGunship", "CategoriesAirBomber",
}

AirScoutFirst = {
    "CategoriesAirScout", "CategoriesAirAntiAir", "CategoriesAirGunship", "CategoriesAirBomber", "CategoriesAirTransport"
}

AirFormationOrders = {
    AirAntiAirFirst = AirAntiAirFirst,
    AirGunshipFirst = AirGunshipFirst,
    AirBomberFirst = AirBomberFirst,
    AirTransportFirst = AirTransportFirst,
    AirScoutFirst = AirScoutFirst,
}

if Debug then
    for k, v in AirFormationOrders do
        SPEW(string.format(" - %s", k), table.getn(v))

        for _, entry in v do
            if not (CategoriesAir[entry]) then
                WARN(string.format("   - %s is not a valid category", entry))
            end
        end
    end
end

--#endregion
