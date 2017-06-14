-- ****************************************************************************
-- **
-- **  File     :  /cdimage/lua/formations.lua
-- **  Author(s):
-- **
-- **  Summary  :
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************
--
-- Basic create formation scripts


SurfaceFormations = {
    'AttackFormation',
    'GrowthFormation',
}

AirFormations = {
    'AttackFormation',
    'GrowthFormation',
}

ComboFormations = {
    'AttackFormation',
    'GrowthFormation',
}

local FormationPos = {} -- list to be returned
local LastFormation = nil
local LastUnits = {}
local LastUnitCount = 0

function CheckSameUnits(formationUnits)
    if table.getn(formationUnits) ~= LastUnitCount then
        return false
    end
    
    for i = 0, LastUnitCount - 1, 1 do -- These indices are 0-based.
        if LastUnits[i] ~= formationUnits[i] then
            return false
        end
    end
    return true
end

-- =========================================
-- ================ LAND DATA ==============
-- =========================================
local RemainingCategory = { 'RemainingCategory', }

-- === LAND CATEGORIES ===
local DirectFire = ((categories.DIRECTFIRE - categories.CONSTRUCTION)) * categories.LAND
local Artillery = ((categories.ARTILLERY + categories.INDIRECTFIRE)) * categories.LAND
local AntiAir = (categories.ANTIAIR - (categories.EXPERIMENTAL + categories.DIRECTFIRE + Artillery)) * categories.LAND
local Construction = ((categories.COMMAND + categories.CONSTRUCTION + categories.ENGINEER) - (DirectFire + Artillery)) * categories.LAND
local UtilityCat = (((categories.RADAR + categories.COUNTERINTELLIGENCE) - categories.DIRECTFIRE) + categories.SCOUT) * categories.LAND
local ShieldCat = categories.uel0307 + categories.ual0307 + categories.xsl0307

-- === TECH LEVEL LAND CATEGORIES ===
local LandCategories = {
    Shields = ShieldCat,
    
    Bot1 = (DirectFire * categories.TECH1) * categories.BOT - categories.SCOUT,
    Bot2 = (DirectFire * categories.TECH2) * categories.BOT - categories.SCOUT,
    Bot3 = (DirectFire * categories.TECH3) * categories.BOT - categories.SCOUT,
    Bot4 = (DirectFire * categories.EXPERIMENTAL) * categories.BOT - categories.SCOUT,

    Tank1 = (DirectFire * categories.TECH1) - categories.BOT - categories.SCOUT,
    Tank2 = (DirectFire * categories.TECH2) - categories.BOT - categories.SCOUT,
    Tank3 = (DirectFire * categories.TECH3) - categories.BOT - categories.SCOUT,
    Tank4 = (DirectFire * categories.EXPERIMENTAL) - categories.BOT - categories.SCOUT,

    Art1 = Artillery * categories.TECH1,
    Art2 = Artillery * categories.TECH2,
    Art3 = Artillery * categories.TECH3,
    Art4 = Artillery * categories.EXPERIMENTAL,

    AA1 = AntiAir * categories.TECH1,
    AA2 = AntiAir * categories.TECH2,
    AA3 = AntiAir * categories.TECH3,

    Com1 = Construction * categories.TECH1,
    Com2 = Construction * categories.TECH2,
    Com3 = Construction - (categories.TECH1 + categories.TECH2 + categories.EXPERIMENTAL),
    Com4 = Construction * categories.EXPERIMENTAL,

    Util1 = (UtilityCat * categories.TECH1) + categories.OPERATION,
    Util2 = UtilityCat * categories.TECH2,
    Util3 = UtilityCat * categories.TECH3,
    Util4 = UtilityCat * categories.EXPERIMENTAL,

    RemainingCategory = categories.LAND - (DirectFire + Construction + Artillery + AntiAir + UtilityCat + ShieldCat)
}

-- === SUB GROUP ORDERING ===
local Bots = { 'Bot4', 'Bot3', 'Bot2', 'Bot1', }
local Tanks = { 'Tank4', 'Tank3', 'Tank2', 'Tank1', }
local DF = { 'Tank4', 'Bot4', 'Tank3', 'Bot3', 'Tank2', 'Bot2', 'Tank1', 'Bot1', }
local Art = { 'Art4', 'Art3', 'Art2', 'Art1', }
local T1Art = { 'Art1', 'Art2', 'Art3', 'Art4', }
local AA = { 'AA3', 'AA2', 'AA1', }
local Util = { 'Util4', 'Util3', 'Util2', 'Util1', }
local Com = { 'Com4', 'Com3', 'Com2', 'Com1', }
local Shield = { 'Shields', }

-- === LAND BLOCK TYPES =
local DFFirst = { DF, T1Art, AA, Shield, Com, Util, RemainingCategory }
local TankFirst = { Tanks, Bots, Art, AA, Shield, Com, Util, RemainingCategory }
local ShieldFirst = { Shield, AA, T1Art, DF, Com, Util, RemainingCategory }
local AAFirst = { AA, DF, T1Art, Art, Shield, Com, Util, RemainingCategory }
local ArtFirst = { Art, AA, DF, Shield, Com, Util, RemainingCategory }
local T1ArtFirst = { T1Art, AA, DF, Shield, Com, Util, RemainingCategory }
local UtilFirst = { Util, AA, T1Art, DF, Shield, Com, RemainingCategory }


-- === LAND BLOCKS ===

-- === 3 Wide Attack Block / 3 Units ===
local ThreeWideAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, },
}

-- === 4 Wide Attack Block / 12 Units ===
local FourWideAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, },
    -- second row
    { UtilFirst, ShieldFirst, ShieldFirst, UtilFirst, },
    -- third Row
    { AAFirst, ArtFirst, ArtFirst, AAFirst,  },
}

-- === 5 Wide Attack Block ===
local FiveWideAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, },
    -- second row
    { DFFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, },
    -- third row
    { UtilFirst, ShieldFirst, DFFirst, ShieldFirst,  UtilFirst, },
    -- fourth row
    { AAFirst, DFFirst, ArtFirst, DFFirst, AAFirst, },
}

-- === 6 Wide Attack Block ===
local SixWideAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, },
    -- second row
    { DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, },
    -- third row
    { UtilFirst, AAFirst, DFFirst, DFFirst, AAFirst,  UtilFirst, },
    -- fourth row
    { AAFirst, ShieldFirst, ArtFirst, ArtFirst, ShieldFirst, AAFirst, },
    -- fifth row
    { DFFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, DFFirst, },
}

-- === 7 Wide Attack Block ===
local SevenWideAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, },
    -- second Row
    { DFFirst, ShieldFirst, DFFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, },
    -- third row
    { UtilFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, UtilFirst, },
    -- fourth row
    { AAFirst, ShieldFirst, AAFirst, T1ArtFirst, ShieldFirst, AAFirst, DFFirst, },
    -- fifth row
    { DFFirst, AAFirst, T1ArtFirst, T1ArtFirst, AAFirst, T1ArtFirst, DFFirst, },
    -- sixth row
    { UtilFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, UtilFirst, },
}

-- === 8 Wide Attack Block ===
local EightWideAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, },
    -- second Row
    { DFFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, },
    -- third row
    { UtilFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, UtilFirst, },
    -- fourth row
    { DFFirst, AAFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, AAFirst, DFFirst, },
    -- fifth row
    { DFFirst, T1ArtFirst, AAFirst, T1ArtFirst, T1ArtFirst, AAFirst, T1ArtFirst, DFFirst, },
    -- sixth row
    { UtilFirst, AAFirst, ShieldFirst, ArtFirst, ArtFirst, ShieldFirst, AAFirst, UtilFirst, },
    -- seventh row
    { DFFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, DFFirst, },
}

-- === Travelling Block ===
local TravelSlot = { Bots, Tanks, AA, Art, Shield, Util, Com }
local TravelFormationBlock = {
    HomogenousRows = true,
    UtilBlocks = true,
    RowBreak = 0.5,
    { TravelSlot, TravelSlot, },
    { TravelSlot, TravelSlot, },
    { TravelSlot, TravelSlot, },
    { TravelSlot, TravelSlot, },
    { TravelSlot, TravelSlot, },
}

-- === 2 Row Attack Block - 8 units wide ===
local TwoRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { UtilFirst, AAFirst, ShieldFirst, ArtFirst, ArtFirst, ShieldFirst, AAFirst, UtilFirst },
}

-- === 3 Row Attack Block - 10 units wide ===
local ThreeRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { UtilFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, AAFirst, ShieldFirst, UtilFirst },
    -- third row
    { DFFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, ArtFirst, AAFirst, DFFirst },
}

-- === 4 Row Attack Block - 12 units wide ===
local FourRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst },
    -- third row
    { DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst },
    -- fourth row
    { AAFirst, ShieldFirst, AAFirst, ArtFirst, ShieldFirst, ArtFirst, ArtFirst, ShieldFirst, ArtFirst, AAFirst, ShieldFirst, AAFirst },
}

-- === 5 Row Attack Block - 14 units wide ===
local FiveRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst },
    -- third row
    { DFFirst, AAFirst, DFFirst, AAFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, AAFirst, DFFirst, AAFirst, DFFirst },
    -- fourth row
    { AAFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, AAFirst },
    -- five row
    { ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst },
}

-- === 6 Row Attack Block - 16 units wide ===
local SixRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst },
    -- third row
    { DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst },
    -- fourth row
    { AAFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, AAFirst, ShieldFirst, DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, AAFirst },
    -- fifth row
    { UtilFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, UtilFirst },
    -- sixth row
    { AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst },
}

-- === 7 Row Attack Block - 18 units wide ===
local SevenRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst },
    -- third row
    { DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst },
    -- fourth row
    { AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst },
    -- fifth row
    { UtilFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, UtilFirst },
    -- sixth row
    { AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst },
    -- seventh row
    { ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst },
}

-- === 8 Row Attack Block - 18 units wide ===
local EightRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst },
    -- third row
    { DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst },
    -- fourth row
    { AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, AAFirst },
    -- fifth row
    { UtilFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, AAFirst, UtilFirst },
    -- sixth row
    { AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, AAFirst },
    -- seventh row
    { DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, DFFirst, DFFirst, DFFirst },
    -- eight row
    { AAFirst, ShieldFirst, ArtFirst, AAFirst, ShieldFirst, ArtFirst, AAFirst, ShieldFirst, ArtFirst, ShieldFirst, AAFirst, ArtFirst, ShieldFirst, AAFirst, ArtFirst, ShieldFirst, AAFirst, ArtFirst, ShieldFirst, AAFirst },
}

-- === 9 Row Attack Block - 18+ units wide ===
local NineRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst },
    -- third row
    { DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst },
    -- fourth row
    { AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, AAFirst },
    -- fifth row
    { UtilFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, AAFirst, UtilFirst },
    -- sixth row
    { AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, AAFirst },
    -- seventh row
    { DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, DFFirst, DFFirst, DFFirst },
    -- eight row
    { AAFirst, ShieldFirst, ArtFirst, AAFirst, ShieldFirst, ArtFirst, AAFirst, ShieldFirst, ArtFirst, ShieldFirst, AAFirst, ArtFirst, ShieldFirst, AAFirst, ArtFirst, ShieldFirst, AAFirst, ArtFirst, ShieldFirst, AAFirst },
}
-- =========================================
-- ================ AIR DATA ===============
-- =========================================

-- === AIR CATEGORIES ===
local GroundAttackAir = (categories.AIR * categories.GROUNDATTACK) - categories.ANTIAIR
local TransportationAir = categories.AIR * categories.TRANSPORTATION - categories.GROUNDATTACK
local BomberAir = categories.AIR * categories.BOMBER
local AAAir = categories.AIR * categories.ANTIAIR
local AntiNavyAir = categories.AIR * categories.ANTINAVY
local IntelAir = categories.AIR * (categories.SCOUT + categories.RADAR)
local ExperimentalAir = categories.AIR * categories.EXPERIMENTAL

-- === TECH LEVEL AIR CATEGORIES ===
local AirCategories = {
    Ground1 = GroundAttackAir * categories.TECH1,
    Ground2 = GroundAttackAir * categories.TECH2,
    Ground3 = GroundAttackAir * categories.TECH3,

    Trans1 = TransportationAir * categories.TECH1,
    Trans2 = TransportationAir * categories.TECH2,
    Trans3 = TransportationAir* categories.TECH3,

    Bomb1 = BomberAir * categories.TECH1,
    Bomb2 = BomberAir * categories.TECH2,
    Bomb3 = BomberAir * categories.TECH3,

    AA1 = AAAir * categories.TECH1,
    AA2 = AAAir * categories.TECH2,
    AA3 = AAAir * categories.TECH3,

    AN1 = AntiNavyAir * categories.TECH1,
    AN2 = AntiNavyAir * categories.TECH2,
    AN3 = AntiNavyAir * categories.TECH3,

    AIntel1 = IntelAir * categories.TECH1,
    AIntel2 = IntelAir * categories.TECH2,
    AIntel3 = IntelAir * categories.TECH3,

    AExper = ExperimentalAir,

    RemainingCategory = categories.AIR
}

-- === SUB GROUP ORDERING ===
local GroundAttack = { 'Ground3', 'Ground2', 'Ground1', }
local Transports = { 'Trans3', 'Trans2', 'Trans1', }
local Bombers = { 'Bomb3', 'Bomb2', 'Bomb1', }
local AntiAir = { 'AA3', 'AA2', 'AA1', }
local AntiNavy = { 'AN3', 'AN2', 'AN1', }
local Intel = { 'AIntel3', 'AIntel2', 'AIntel1', }
local ExperAir = { 'AExper', }

-- === Air Block Arrangement ===
local ChevronSlot = { AntiAir, ExperAir, AntiNavy, GroundAttack, Bombers, Intel, Transports, RemainingCategory }
local InitialChevronBlock = {
    RepeatAllRows = false,
    HomogenousBlocks = true,
    ChevronSize = 3,
    { ChevronSlot },
    { ChevronSlot, ChevronSlot },
}

local StaggeredChevronBlock = {
    RepeatAllRows = true,
    HomogenousBlocks = true,
    { ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, },
}



-- =========================================
-- ============== NAVAL DATA ===============
-- =========================================

local LightAttackNaval = categories.LIGHTBOAT
local FrigateNaval = categories.FRIGATE
local SubNaval = categories.T1SUBMARINE + categories.T2SUBMARINE + categories.xss0304 -- TODO: Deal with categories instead of hard-coding xss0304
local DestroyerNaval = categories.DESTROYER
local CruiserNaval = categories.CRUISER
local BattleshipNaval = categories.BATTLESHIP
local CarrierNaval = categories.NAVALCARRIER
local NukeSubNaval = categories.NUKESUB - categories.xss0304 -- TODO: See above
local MobileSonar = categories.MOBILESONAR
local DefensiveBoat = categories.DEFENSIVEBOAT
local RemainingNaval = categories.NAVAL - (LightAttackNaval + FrigateNaval + SubNaval + DestroyerNaval + CruiserNaval + BattleshipNaval +
                        CarrierNaval + NukeSubNaval + DefensiveBoat + MobileSonar)

-- Naval formation blocks 
local NavalSpacing = 1.2
local StandardNavalBlock = {
    { { {0, 0}, }, { 'Carriers', 'Battleships', 'Cruisers', 'Destroyers', 'Frigates', 'Submarines' }, },
    { { {-1, 1.5}, {1, 1.5}, }, { 'Destroyers', 'Cruisers', 'Frigates', 'Submarines'}, },
    { { {-2.5, 0}, {2.5, 0}, }, { 'Cruisers', 'Battleships', 'Destroyers', 'Frigates', 'Submarines' }, },
    { { {-1, -1.5}, {1, -1.5}, }, { 'Frigates', 'Battleships', 'Submarines' }, },
    { { {-3, 2}, {3, 2}, {-3, 0}, {3, 0}, }, { 'Submarines', }, },
}

-- === TECH LEVEL LAND CATEGORIES ===
local NavalCategories = {
    LightCount = LightAttackNaval,
    FrigateCount = FrigateNaval,

    CruiserCount = CruiserNaval,
    DestroyerCount = DestroyerNaval,

    BattleshipCount = BattleshipNaval,
    CarrierCount = CarrierNaval,

    NukeSubCount = NukeSubNaval,
    MobileSonarCount = MobileSonar + DefensiveBoat,

    RemainingCategory = RemainingNaval,
}

local SubCategories = {
    SubCount = SubNaval,
}

-- === SUB GROUP ORDERING ===
local Frigates = { 'FrigateCount', 'LightCount', }
local Destroyers = { 'DestroyerCount', }
local Cruisers = { 'CruiserCount', }
local Battleships = { 'BattleshipCount', }
local Subs = { 'SubCount', }
local NukeSubs = { 'NukeSubCount', }
local Carriers = { 'CarrierCount', }
local Sonar = {'MobileSonarCount', }

-- === LAND BLOCK TYPES =
local FrigatesFirst = { Frigates, Destroyers, Battleships, Cruisers, Carriers, NukeSubs, Sonar, RemainingCategory }
local DestroyersFirst = { Destroyers, Frigates, Battleships, Cruisers, Carriers, NukeSubs, Sonar, RemainingCategory }
local CruisersFirst = { Cruisers, Carriers, Battleships, Destroyers, Frigates, NukeSubs, Sonar, RemainingCategory }
local BattleshipsFirst = { Battleships, Destroyers, Frigates, Cruisers, Carriers, NukeSubs, Sonar, RemainingCategory }
local CarriersFirst = { Carriers, Cruisers, Battleships, Destroyers, Frigates, NukeSubs, Sonar, RemainingCategory }
local Subs = { Subs, NukeSubs, RemainingCategory }
local SonarFirst = { Sonar, Carriers, Cruisers, Battleships, Destroyers, Frigates, NukeSubs, Sonar, RemainingCategory }

-- === LAND BLOCKS ===

-- === Three Naval Growth Formation Block ==
local ThreeNavalGrowthFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, },
    -- second row
    { DestroyersFirst, SonarFirst, DestroyersFirst, },
    -- third row
    { DestroyersFirst, CruisersFirst, DestroyersFirst, },
}

-- === Five Naval Growth Formation Block ==
local FiveNavalGrowthFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst },
    -- second row
    { FrigatesFirst, SonarFirst, DestroyersFirst, SonarFirst, FrigatesFirst },
    -- third row
    { DestroyersFirst, SonarFirst, BattleshipsFirst, SonarFirst, DestroyersFirst },
    -- fourth row
    { DestroyersFirst, SonarFirst, CarriersFirst, SonarFirst, DestroyersFirst },
    -- fifth row
    { DestroyersFirst, SonarFirst, CarriersFirst, SonarFirst, DestroyersFirst },

}

-- === Seven Naval Growth Formation Block ==
local SevenNavalGrowthFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst },
    -- second row
    { FrigatesFirst, FrigatesFirst, SonarFirst, DestroyersFirst, SonarFirst, FrigatesFirst, FrigatesFirst },
    -- third row
    { DestroyersFirst, DestroyersFirst, SonarFirst, BattleshipsFirst, SonarFirst, DestroyersFirst, DestroyersFirst },
    -- fourth row
    { DestroyersFirst, BattleshipsFirst, SonarFirst, CarriersFirst, SonarFirst, BattleshipsFirst, DestroyersFirst },
    -- fifth row
    { DestroyersFirst, CruisersFirst, SonarFirst, BattleshipsFirst, SonarFirst, CruisersFirst, DestroyersFirst },
    -- sixth row
    { DestroyersFirst, CruisersFirst, SonarFirst, CarriersFirst, SonarFirst, CruisersFirst, DestroyersFirst },
    -- seventh row
    { DestroyersFirst, CruisersFirst, SonarFirst, CarriersFirst, SonarFirst, CruisersFirst, DestroyersFirst },
}

-- ==============================================
-- ============ Naval Attack Formation===========
-- ==============================================

-- === Five Wide Naval Attack Formation Block ==
local FiveWideNavalAttackFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst},
    -- second row
    { DestroyersFirst, SonarFirst, CarriersFirst, SonarFirst, DestroyersFirst},
}

-- === Seven Wide Naval Attack Formation Block ==
local SevenWideNavalAttackFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, },
    -- second row
    { DestroyersFirst, BattleshipsFirst, SonarFirst, BattleshipsFirst, SonarFirst, BattleshipsFirst, DestroyersFirst},
        -- third row
    { DestroyersFirst, CruisersFirst, CarriersFirst, CarriersFirst, CruisersFirst, CruisersFirst, DestroyersFirst},
}

-- === Nine Wide Naval Attack Formation Block ==
local NineWideNavalAttackFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst },
    -- second row
    { DestroyersFirst, DestroyersFirst, SonarFirst, BattleshipsFirst, BattleshipsFirst, BattleshipsFirst, SonarFirst, DestroyersFirst, DestroyersFirst },
    -- third row
    { DestroyersFirst, CruisersFirst, SonarFirst, CarriersFirst, CarriersFirst, CarriersFirst, SonarFirst, CruisersFirst, DestroyersFirst },
}

-- ==============================================
-- ============ Sub Growth Formation===========
-- ==============================================
-- === Four Wide Growth Subs Formation ===
local FourWideSubGrowthFormation = {
    LineBreak = 0.5,
    { Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs },
}

-- === Six Wide Subs Formation ===
local SixWideSubGrowthFormation = {
    LineBreak = 0.5,
    { Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs },
}


-- ==============================================
-- ============ Sub Attack Formation===========
-- ==============================================

-- === Four Wide Subs Formation ===
local FourWideSubAttackFormation = {
    LineBreak = 0.5,
    { Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs },
}

-- === Six Wide Subs Formation ===
local SixWideSubAttackFormation = {
    LineBreak = 0.5,
    { Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs },
}

-- === Eight Wide Subs Formation ===
local EightWideSubAttackFormation = {
    LineBreak = 0.5,
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
}

local EightNavalFormation = {
    LineBreak = 0.5,
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst },
    -- second row
    { DestroyersFirst, CruisersFirst, CruisersFirst, BattleshipsFirst, BattleshipsFirst, CruisersFirst, CruisersFirst, DestroyersFirst },
    -- third row
    { DestroyersFirst, BattleshipsFirst, CruisersFirst, CruisersFirst, CruisersFirst, CruisersFirst, BattleshipsFirst, DestroyersFirst },
    -- fourth row
    { DestroyersFirst, CruisersFirst, CarriersFirst, CarriersFirst, CarriersFirst, CarriersFirst, CruisersFirst, DestroyersFirst },
}

local EightNavalSubFormation = {
    LineBreak = 0.5,
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs },
}

-- ============ Formation Pickers ============
function PickBestTravelFormationIndex(typeName, distance)
    if typeName == 'AirFormations' then
        return 0;
    else
        return 1;
    end
end

function PickBestFinalFormationIndex(typeName, distance)
    return -1;
end


-- ================ THE GUTS ====================
-- ============ Formation Functions =============
-- ==============================================
function AttackFormation(formationUnits)
    if LastFormation == 'AttackFormation' and CheckSameUnits(formationUnits) then
        return FormationPos
    end
    
    FormationPos = {}
    LastFormation = 'AttackFormation'
    LastUnits = formationUnits
    LastUnitCount = table.getn(formationUnits)

    local unitsList = CategorizeUnits(formationUnits)
    local landUnitsList = unitsList.Land
    local landBlock
    if landUnitsList.AreaTotal <= 16 then -- 8 wide
        landBlock = TwoRowAttackFormationBlock
    elseif landUnitsList.AreaTotal <= 30 then -- 10 wide
        landBlock = ThreeRowAttackFormationBlock
    elseif landUnitsList.AreaTotal <= 48 then -- 12 wide
        landBlock = FourRowAttackFormationBlock
    elseif landUnitsList.AreaTotal <= 70 then -- 14 wide
        landBlock = FiveRowAttackFormationBlock
    elseif landUnitsList.AreaTotal <= 96 then -- 16 wide
        landBlock = SixRowAttackFormationBlock
    elseif landUnitsList.AreaTotal <= 126 then -- 18 wide
        landBlock = SevenRowAttackFormationBlock
    elseif landUnitsList.AreaTotal <= 160 then -- 20 wide
        landBlock = EightRowAttackFormationBlock
    else
        landBlock = NineRowAttackFormationBlock
    end
    BlockBuilderLand(landUnitsList, landBlock, LandCategories, 1)

    local seaUnitsList = unitsList.Naval
    local seaBlock
    local subBlock
    local subUnitsList = unitsList.Subs
    local seaArea = math.max(seaUnitsList.AreaTotal, subUnitsList.AreaTotal)
    if seaArea <= 10 then
        seaBlock = FiveWideNavalAttackFormation
        subBlock = FourWideSubAttackFormation
    elseif seaArea <= 25 then
        seaBlock = SevenWideNavalAttackFormation
        subBlock = SixWideSubAttackFormation
    elseif seaArea <= 50 then
        seaBlock = NineWideNavalAttackFormation
        subBlock = EightWideSubAttackFormation
    else
        seaBlock = NineWideNavalAttackFormation
        subBlock = EightWideSubAttackFormation
    end
    BlockBuilderLand(seaUnitsList, seaBlock, NavalCategories, 1)
    BlockBuilderLand(subUnitsList, subBlock, SubCategories, 1)

    local airUnitsList = CategorizeAirUnits(formationUnits)
    BlockBuilderAir(airUnitsList, StaggeredChevronBlock)

    return FormationPos
end

function GrowthFormation(formationUnits)
    if LastFormation == 'GrowthFormation' and CheckSameUnits(formationUnits) then
        return FormationPos
    end
    
    FormationPos = {}
    LastFormation = 'GrowthFormation'
    LastUnits = formationUnits
    LastUnitCount = table.getn(formationUnits)

    local unitsList = CategorizeUnits(formationUnits)
    local landUnitsList = unitsList.Land
    local landBlock
    if landUnitsList.AreaTotal <= 3 then
        landBlock = ThreeWideAttackFormationBlock
    elseif landUnitsList.AreaTotal <= 12 then
        landBlock = FourWideAttackFormationBlock
    elseif landUnitsList.AreaTotal <= 20 then
        landBlock = FiveWideAttackFormationBlock
    elseif landUnitsList.AreaTotal <= 30 then
        landBlock = SixWideAttackFormationBlock
    elseif landUnitsList.AreaTotal <= 42 then
        landBlock = SevenWideAttackFormationBlock
    elseif landUnitsList.AreaTotal <= 56 then
        landBlock = EightWideAttackFormationBlock
    else
        landBlock = EightWideAttackFormationBlock
    end
    BlockBuilderLand(landUnitsList, landBlock, LandCategories, 1)

    local seaUnitsList = unitsList.Naval
    local seaBlock
    local subBlock
    local subUnitsList = unitsList.Subs
    local seaArea = math.max(seaUnitsList.AreaTotal, subUnitsList.AreaTotal)
    if seaArea <= 9 then
        seaBlock = ThreeNavalGrowthFormation
        subBlock = FourWideSubGrowthFormation
    elseif seaArea <= 25 then
        seaBlock = FiveNavalGrowthFormation
        subBlock = FourWideSubGrowthFormation
    elseif seaArea <= 49 then
        seaBlock = SevenNavalGrowthFormation
        subBlock = SixWideSubGrowthFormation
    else
        seaBlock = SevenNavalGrowthFormation
        subBlock = SixWideSubGrowthFormation
    end
    BlockBuilderLand(seaUnitsList, seaBlock, NavalCategories, 1)
    BlockBuilderLand(subUnitsList, subBlock, SubCategories, 1)

    local airUnitsList = CategorizeAirUnits(formationUnits)
    BlockBuilderAir(airUnitsList, StaggeredChevronBlock)

    return FormationPos
end

function BlockFormation(formationUnits)
    LOG("BlockFormation")
    if LastFormation == 'BlockFormation' and CheckSameUnits(formationUnits) then
        return FormationPos
    end
    
    FormationPos = {}
    LastFormation = 'BlockFormation'
    LastUnits = formationUnits
    LastUnitCount = table.getn(formationUnits)
    
    local rotate = true
    local smallUnitsList = {}
    local largeUnitsList = {}
    local smallUnits = 0
    local largeUnits = 0

    for i, u in formationUnits do
        local footPrintSize = u:GetFootPrintSize()
        if footPrintSize > 3  then
            largeUnitsList[largeUnits] = { u }
            largeUnits = largeUnits + 1
        else
            smallUnitsList[smallUnits] = { u }
            smallUnits = smallUnits + 1
        end
    end

    local n = smallUnits + largeUnits
    local width = math.ceil(math.sqrt(n))
    local length = n / width

    -- Put small units (Size 1 through 3) in front of the formation
    for i in smallUnitsList do
        local offsetX = ((math.mod(i, width)  - math.floor(width/2)) * 2) + 1
        local offsetY = (math.floor(i/width) - math.floor(length/2)) * 2
        local delay = 0.1 + (math.floor(i/width) * 3)
        table.insert(FormationPos, { offsetX, -offsetY, categories.ALLUNITS, delay, rotate })
    end

    -- Put large units (Size >= 4) in the back of the formation
    for i in largeUnitsList do
        local adjIndex = smallUnits + i
        local offsetX = ((math.mod(adjIndex, width)  - math.floor(width/2)) * 2) + 1
        local offsetY = (math.floor(adjIndex/width) - math.floor(length/2)) * 2
        local delay = 0.1 + (math.floor(adjIndex/width) * 3)
        table.insert(FormationPos, { offsetX, -offsetY, categories.ALLUNITS, delay, rotate })
    end

    return FormationPos
end

-- local function for performing lerp
local function lerp(alpha, a, b)
    return a + ((b-a) * alpha)
end

function CircleFormation(formationUnits)
    LOG("CircleFormation")
    if LastFormation == 'CircleFormation' and CheckSameUnits(formationUnits) then
        return FormationPos
    end
    
    FormationPos = {}
    LastFormation = 'CircleFormation'
    LastUnits = formationUnits
    LastUnitCount = table.getn(formationUnits)
    
    local rotate = false
    local numUnits = table.getn(formationUnits)
    local sizeMult = 2.0 + math.max(1.0, numUnits / 3.0)

    -- make circle around center point
    for i in formationUnits do
        offsetX = sizeMult * math.sin(lerp(i/numUnits, 0.0, math.pi * 2.0))
        offsetY = sizeMult * math.cos(lerp(i/numUnits, 0.0, math.pi * 2.0))
        table.insert(FormationPos, { offsetX, offsetY, categories.ALLUNITS, 0, rotate })
    end

    return FormationPos
end

function GuardFormation(formationUnits)
    -- Not worth checking the last formation because GuardFormation is almost never called repeatedly with the same units.
    FormationPos = {}
    LastFormation = 'GuardFormation'
    LastUnits = formationUnits
    LastUnitCount = table.getn(formationUnits)
    
    local shieldCategory = ShieldCat
    local nonShieldCategory = categories.ALLUNITS - shieldCategory
    local blueprints = {}
    local remainingShields = 0
    for _, u in formationUnits do
        if EntityCategoryContains(ShieldCat, u) then
            remainingShields = remainingShields + 1
        end
    
        local bp = u:GetBlueprint()
        if not blueprints[bp.BlueprintId] then
            blueprints[bp.BlueprintId] = bp
        end
    end
    
    local largestFootprint = 0
    for _, bp in blueprints do
        largestFootprint = math.max(largestFootprint, math.max(bp.Footprint.SizeX, bp.Footprint.SizeZ))
    end
    
    local scale = 3 / math.min(largestFootprint + 2, 8) -- A distance of 1 in formation coordinates is translated to (largestFootprint + 2) world units.
    local rotate = false
    local sizeMult = 0.4
    local remainingUnits = table.getn(formationUnits)
    local ringChange = 0
    local ringCount = 0
    local unitCount = 1
    local shieldsInRing = 0
    local unitsPerShield = 0
    local nextShield = 0

    -- Form concentric circles around the assisted unit
    -- Most of the numbers after this point are arbitrary. Don't go looking for the significance of 0.19 or the like because there is none.
    while remainingUnits > 0 do
        if unitCount > ringChange then
            ringChange = ringChange + 6
            if remainingUnits < ringChange * 1.33 then
                ringChange = remainingUnits
            end
            
            ringCount = ringCount + 1
            sizeMult = sizeMult + math.max(2 - ringCount / 5, 1) * scale
            
            unitCount = 1
            
            if ringCount == 1 then
                shieldsInRing = math.min(ringChange, remainingShields)
            elseif remainingShields >= (remainingUnits + ringChange + 6) * 0.19 then
                shieldsInRing = math.min(ringChange / 2, remainingShields)
            elseif remainingShields >= (remainingUnits + ringChange + 6) * 0.13 then
            shieldsInRing = math.min(ringChange / 3, remainingShields)
            else
                shieldsInRing = 0
            end
            shieldsInRing = math.max(shieldsInRing, remainingShields - (remainingUnits - ringChange))
            
            if shieldsInRing > 0 then
                unitsPerShield = ringChange / shieldsInRing
                nextShield = unitsPerShield - 0.01 -- Rounding error could result in missing a shield if nextShield is supposed to equal ringChange.
            end
        end
        local ringFraction = unitCount/ringChange
        offsetX = sizeMult * math.sin(lerp(ringFraction, 0.0, math.pi * 2.0))
        offsetY = -sizeMult * math.cos(lerp(ringFraction, 0.0, math.pi * 2.0))
        -- LOG('*FORMATION DEBUG: X=' .. offsetX .. ', Y=' .. offsetY)
        if shieldsInRing > 0 and unitCount >= nextShield then
            table.insert(FormationPos, { offsetX, offsetY, ShieldCat, 0, rotate })
            remainingShields = remainingShields - 1
            nextShield = nextShield + unitsPerShield
        else
            table.insert(FormationPos, { offsetX, offsetY, nonShieldCategory, 0, rotate })
        end
        unitCount = unitCount + 1
        remainingUnits = remainingUnits - 1
    end

    return FormationPos
end




-- =========== LAND BLOCK BUILDING =================
function BlockBuilderLand(unitsList, formationBlock, categoryTable, spacing)
    spacing = (spacing or 1) * unitsList.Scale
    local numRows = table.getn(formationBlock)
    local i = 1
    local whichRow = 1
    local whichCol = 1
    local currRowLen = table.getn(formationBlock[whichRow])
    local evenRowLen = math.mod(currRowLen, 2) == 0
    local rowType = false
    local formationLength = 0
    local inserted = false
    local occupiedSpaces = {}

    while unitsList.UnitTotal >= i do
        if whichCol > currRowLen then
            if whichRow == numRows then
                whichRow = 1
                formationLength = formationLength + 1 + (formationBlock.RowBreak or 0) + (formationBlock.LineBreak or 0)
            else
                whichRow = whichRow + 1
                formationLength = formationLength + 1 + (formationBlock.LineBreak or 0)
            end
            whichCol = 1
            rowType = false
            currRowLen = table.getn(formationBlock[whichRow])
            evenRowLen = math.mod(currRowLen, 2) == 0
        end
        
        if occupiedSpaces[formationLength] and occupiedSpaces[formationLength][whichCol] then
            whichCol = whichCol + 1
            continue
        end
        
        local currColSpot = GetColSpot(currRowLen, whichCol) -- Translate whichCol to correct spot in row
        local currSlot = formationBlock[whichRow][currColSpot]
        for numType, type in currSlot do
            if inserted then
                break
            end
            for numGroup, group in type do
                if not formationBlock.HomogenousRows or (rowType == false or rowType == type) then
                    local fs = 0
                    local size = 0
                    local evenSize = true
                    local groupData = nil
                    for k, v in unitsList[group] do
                        size = unitsList.FootprintSizes[k]
                        evenSize = math.mod(size, 2) == 0
                        if v.Count > 0 then --and (whichCol + (size - 1) * 2 <= currRowLen or currRowLen < size * 2) then
                            if size > 1 then
                                if whichCol == 1 and not evenRowLen and evenSize then -- Don't put an even-sized unit in the middle of an odd-length row
                                    continue
                                end
                                local blocked = false
                                for y = 0, size - 1, 1 do
                                    local yPos = formationLength + y + y * (formationBlock.LineBreak or 0)
                                    if not occupiedSpaces[yPos] then
                                        continue
                                    end
                                    for x = 0, size - 1, 1 do
                                        if occupiedSpaces[yPos][whichCol + x * 2] then
                                            blocked = true
                                            break
                                        end
                                    end
                                    if blocked then
                                        break
                                    end
                                end
                                if blocked then
                                    continue
                                end
                            end
                            fs = k
                            groupData = v
                            break
                        end
                    end
                    if groupData then
                        local offsetX = 0
                        local offsetY = 0
                        
                        if size > 1 then
                            if whichCol == 1 and evenRowLen and evenSize then
                                offsetX = -0.5
                            else
                                offsetX = (size - 1) / 2
                            end
                            offsetY = (size - 1) / 2 * (1 + (formationBlock.LineBreak or 0))
                            for y = 0, size - 1, 1 do
                                local yPos = formationLength + y + y * (formationBlock.LineBreak or 0)
                                if not occupiedSpaces[yPos] then
                                    occupiedSpaces[yPos] = {}
                                end
                                if whichCol == 1 and evenRowLen == evenSize then
                                    for x = 0, size - 1, 1 do
                                        occupiedSpaces[yPos][whichCol + x] = true
                                    end
                                else
                                    for x = 0, (size - 1) * 2, 2 do
                                        occupiedSpaces[yPos][whichCol + x] = true
                                    end
                                end
                            end
                        end
                        
                        local xPos
                        if evenRowLen then
                            xPos = math.ceil(whichCol/2) - .5 + offsetX
                            if not (math.mod(whichCol, 2) == 0) then
                                xPos = xPos * -1
                            end
                        else
                            if whichCol == 1 then
                                xPos = 0
                            else
                                xPos = math.ceil(((whichCol-1) /2)) + offsetX
                                if not (math.mod(whichCol, 2) == 0) then
                                    xPos = xPos * -1
                                end
                            end
                        end
        
                        if formationBlock.HomogenousRows and not rowType then
                            rowType = type
                        end
                        
                        table.insert(FormationPos, {xPos * spacing, (-formationLength - offsetY) * spacing, categoryTable[group], formationLength, true})
                        inserted = true
                        
                        groupData.Count = groupData.Count - 1
                        if groupData.Count <= 0 then
                            unitsList[group][fs] = nil
                        end
                        break
                    end
                end
            end
        end
        if inserted then
            i = i + 1
            inserted = false
        end
        whichCol = whichCol + 1
    end

    return FormationPos
end

function GetColSpot(rowLen, col)
    local len = rowLen
    if math.mod(rowLen, 2) == 1 then
        len = rowLen + 1
    end
    local colType = 'left'
    if math.mod(col, 2) == 0 then
        colType = 'right'
    end
    local colSpot = math.floor(col / 2)
    local halfSpot = len/2
    if colType == 'left' then
        return halfSpot - colSpot
    else
        return halfSpot + colSpot
    end
end





-- ============ AIR BLOCK BUILDING =============
function BlockBuilderAir(unitsList, airBlock)
    local numRows = table.getn(airBlock)
    local i = 1
    local whichRow = 1
    local whichCol = 1
    local chevronPos = 1
    local currRowLen = table.getn(airBlock[whichRow])
    local longestRow = 1
    local longestLength = 0
    local chevronSize = airBlock.ChevronSize or 5
    while i < numRows do
        if table.getn(airBlock[i]) > longestLength then
            longestLength = table.getn(airBlock[i])
            longestRow = i
        end
        i = i + 1
    end
    local chevronType = false
    local formationLength = 0
    local spacing = 1

    if unitsList.AExper > 0 then
        spacing = 2
    end

    i = 1
    while unitsList.UnitTotal >= i do
        if chevronPos > chevronSize then
            chevronPos = 1
            chevronType = false
            if whichCol == currRowLen then
                if whichRow == numRows then
                    if airBlock.RepeatAllRows then
                        whichRow = 1
                        currRowLen = table.getn(airBlock[whichRow])
                    end
                else
                    whichRow = whichRow + 1
                    currRowLen = table.getn(airBlock[whichRow])
                end
                formationLength = formationLength + 1
                whichCol = 1
            else
                whichCol = whichCol + 1
            end
        end
        local currSlot = airBlock[whichRow][whichCol]
        local inserted = false
        for numType, type in currSlot do
            if inserted then
                break
            end
            for numGroup, group in type do
                if not airBlock.HomogenousBlocks or chevronType == false or chevronType == type then
                    if unitsList[group] > 0 then
                        local xPos, yPos = GetChevronPosition(chevronPos, whichCol, currRowLen, formationLength)
                        if airBlock.HomogenousBlocks and not chevronType then
                            chevronType = type
                        end
                        table.insert(FormationPos, {xPos*spacing, yPos*spacing, AirCategories[group], yPos, true})
                        unitsList[group] = unitsList[group] - 1
                        inserted = true
                        break
                    end
                end
            end
        end
        if inserted then
            i = i + 1
        end
        chevronPos = chevronPos + 1
    end
    return FormationPos
end

function GetChevronPosition(chevronPos, currCol, currRowLen, formationLen)
    local offset = math.floor(chevronPos/2) * .375
    local xPos = offset
    if math.mod(chevronPos, 2) == 0 then
        xPos = -1 * offset
    end
    local yPos = -offset
    yPos = yPos + (formationLen * -1.5)
    local firstBlockOffset = -2
    if math.mod(currRowLen, 2) == 1 then
        firstBlockOffset = -1
    end
    local blockOff = math.floor(currCol/2) * 2
    if math.mod(currCol, 2) == 1 then
        blockOff = -blockOff
    end
    xPos = xPos + blockOff + firstBlockOffset
    return xPos, yPos
end





-- =========== NAVAL UNIT BLOCKS ============
function NavalBlocks(unitsList, navyType)
    local Carriers = true
    local Battleships = true
    local Cruisers = true
    local Destroyers = true
    local unitNum = 1
    for i, v in navyType do
        for k, u in v[2] do
            if u == 'Carriers' and Carriers and unitsList.CarrierCount > 0 then
                for j, coord in v[1] do
                    if unitsList.CarrierCount ~= 0 then
                        table.insert(FormationPos, { coord[1]*NavalSpacing, coord[2]*NavalSpacing, categories.NAVAL * categories.AIRSTAGINGPLATFORM * (categories.TECH3 + categories.EXPERIMENTAL), 0, true })
                        unitsList.CarrierCount = unitsList.CarrierCount - 1
                        unitNum = unitNum + 1
                    end
                end
                Carriers = false
                break
            elseif u == 'Battleships' and Battleships and unitsList.BattleshipCount > 0 then
                for j, coord in v[1] do
                    if unitsList.BattleshipCount ~= 0 then
                        table.insert(FormationPos, { coord[1]*NavalSpacing, coord[2]*NavalSpacing, BattleshipNaval, 0, true })
                        unitsList.BattleshipCount = unitsList.BattleshipCount - 1
                        unitNum = unitNum + 1
                    end
                end
                Battleships = false
                break
            elseif u == 'Cruisers' and Cruisers and unitsList.CruiserCount > 0 then
                for j, coord in v[1] do
                    if unitsList.CruiserCount ~= 0 then
                        table.insert(FormationPos, { coord[1]*NavalSpacing, coord[2]*NavalSpacing, CruiserNaval, 0, true })
                        unitNum = unitNum + 1
                        unitsList.CruiserCount = unitsList.CruiserCount - 1
                    end
                end
                Cruisers = false
                break
            elseif u == 'Destroyers' and Destroyers and unitsList.DestroyerCount > 0 then
                for j, coord in v[1] do
                    if unitsList.DestroyerCount > 0 then
                        table.insert(FormationPos, { coord[1]*NavalSpacing, coord[2]*NavalSpacing, DestroyerNaval, 0, true })
                        unitNum = unitNum + 1
                        unitsList.DestroyerCount = unitsList.DestroyerCount - 1
                    end
                end
                Destroyers = false
                break
            elseif u == 'Frigates' and unitsList.FrigateCount > 0 then
                for j, coord in v[1] do
                    if unitsList.FrigateCount > 0 then
                        table.insert(FormationPos, { coord[1]*NavalSpacing, coord[2]*NavalSpacing, FrigateNaval, 0, true })
                        unitNum = unitNum + 1
                        unitsList.FrigateCount = unitsList.FrigateCount - 1
                    end
                end
                break
            elseif u == 'Frigates' and unitsList.LightCount > 0 then
                for j, coord in v[1] do
                    if unitsList.LightCount > 0 then
                        table.insert(FormationPos, { coord[1]*NavalSpacing, coord[2]*NavalSpacing, LightAttackNaval, 0, true })
                        unitNum = unitNum + 1
                        unitsList.LightCount = unitsList.LightCount - 1
                    end
                end
                break
            elseif u == 'Submarines' and unitsList.SubCount > 0 then
                for j, coord in v[1] do
                    if (unitsList.SubCount + unitsList.NukeSubCount) > 0 then
                        table.insert(FormationPos, { coord[1]*NavalSpacing, coord[2]*NavalSpacing, SubNaval + NukeSubNaval, 0, true })
                        unitNum = unitNum + 1
                        unitsList.SubCount = unitsList.SubCount - 1
                    end
                end
                break
            end
        end
    end

    local sideTable = { 0, -2, 2 }
    local sideIndex = 1
    local length = -3

    i = unitNum

    -- Figure out how many left we have to assign
    local numLeft = unitsList.UnitTotal - i + 1
    if numLeft == 2 then
        sideIndex = 2
    end

    while i <= unitsList.UnitTotal do
        if unitsList.CarrierCount > 0 then
            table.insert(FormationPos, { sideTable[sideIndex]*NavalSpacing, length*NavalSpacing, categories.NAVAL * categories.AIRSTAGINGPLATFORM * (categories.TECH3 + categories.EXPERIMENTAL), 0, true  })
            unitNum = unitNum + 1
            unitsList.CarrierCount = unitsList.CarrierCount - 1
        elseif unitsList.BattleshipCount > 0 then
            table.insert(FormationPos, { sideTable[sideIndex]*NavalSpacing, length*NavalSpacing, BattleshipNaval, 0, true })
            unitNum = unitNum + 1
            unitsList.BattleshipCount = unitsList.BattleshipCount - 1
        elseif unitsList.CruiserCount > 0 then
            table.insert(FormationPos, { sideTable[sideIndex]*NavalSpacing, length*NavalSpacing, CruiserNaval, 0, true })
            unitNum = unitNum + 1
            unitsList.CruiserCount = unitsList.CruiserCount - 1
        elseif unitsList.DestroyerCount > 0 then
            table.insert(FormationPos, { sideTable[sideIndex]*NavalSpacing, length*NavalSpacing, DestroyerNaval, 0, true })
            unitNum = unitNum + 1
            unitsList.DestroyerCount = unitsList.DestroyerCount - 1
        elseif unitsList.FrigateCount > 0 then
            table.insert(FormationPos, { sideTable[sideIndex]*NavalSpacing, length*NavalSpacing, FrigateNaval, 0, true })
            unitNum = unitNum + 1
            unitsList.FrigateCount = unitsList.FrigateCount - 1
        elseif unitsList.LightCount > 0 then
            table.insert(FormationPos, { sideTable[sideIndex]*NavalSpacing, length*NavalSpacing, LightAttackNaval, 0, true })
            unitNum = unitNum + 1
            unitsList.LightCount = unitsList.LightCount - 1
        elseif (unitsList.SubCount + unitsList.NukeSubCount) > 0 then
            table.insert(FormationPos, { sideTable[sideIndex]*NavalSpacing, length*NavalSpacing, SubNaval + NukeSubNaval, 0, true })
            unitNum = unitNum + 1
            unitsList.SubCount = unitsList.SubCount - 1
        elseif (unitsList.MobileSonarCount) > 0 then
            table.insert(FormationPos, { sideTable[sideIndex]*NavalSpacing, length*NavalSpacing, MobileSonar + DefensiveBoat, 0, true })
            unitNum = unitNum + 1
            unitsList.MobileSonarCount = unitsList.MobileSonarCount - 1
        elseif (unitsList.RemainingCategory) > 0 then
            table.insert(FormationPos, { sideTable[sideIndex]*NavalSpacing, length*NavalSpacing, NavalCategories.RemainingCategory, 0, true })
            unitNum = unitNum + 1
            unitsList.RemainingCategory = unitsList.RemainingCategory - 1
        end

        -- Figure out the next viable location for the naval unit
        numLeft = numLeft - 1
        sideIndex = sideIndex + 1
        if sideIndex == 4 then
            length = length - 2
            if numLeft == 2 then
                sideIndex = 2
            else
                sideIndex = 1
            end
        end

        i = i + 1
    end
    return FormationPos
end



-- ========= UNIT SORTING ==========
function CategorizeAirUnits(formationUnits)
    local unitsList = {
        -- Air Lists
        Ground1 = 0, Ground2 = 0, Ground3 = 0,
        Trans1 = 0, Trans2 = 0, Trans3 = 0,
        Bomb1 = 0, Bomb2 = 0, Bomb3 = 0,
        AA1 = 0, AA2 = 0, AA3 = 0,
        AN1 = 0, AN2 = 0, AN3 = 0,
        AIntel1 = 0, AIntel2 = 0, AIntel3 = 0,
        AExper = 0,
        RemainingCategory = 0,
        UnitTotal = 0,
    }
    for i, u in formationUnits do
        for aircat, _ in AirCategories do
            if EntityCategoryContains(AirCategories[aircat], u) then
                unitsList[aircat] = unitsList[aircat] + 1
                if aircat == "RemainingCategory" then
                    WARN('*FORMATION DEBUG: Missed unit: ' .. u:GetUnitId())
                end
                unitsList.UnitTotal = unitsList.UnitTotal + 1
                break
            end
        end
    end
    -- LOG('UnitsList=', repr(unitsList))
    return unitsList
end

function CalculateSizes(unitsList)
    local largestFootprint = 1
    local smallestFootprints = {}
    
    local types = {
        Land = {
            GridSizeFraction = 2.75,
            GridSizeAbsolute = 2,
            MinSeparationFraction = 2.25,
        },
        
        Air = {
            GridSizeFraction = 0,
            GridSizeAbsolute = 2,
            MinSeparationFraction = 1,
        },
        
        Naval = {
            GridSizeFraction = 2,
            GridSizeAbsolute = 2,
            MinSeparationFraction = 1.25,
        },
        
        Subs = {
            GridSizeFraction = 2,
            GridSizeAbsolute = 2,
            MinSeparationFraction = 1.25,
        },
    }
    
    for type in types do
        local largestForType = 1
        local numSizes = 0
        for fs, _ in unitsList[type].FootprintCounts do
            largestFootprint = math.max(largestFootprint, fs)
            largestForType = math.min(largestForType, fs)
            numSizes = numSizes + 1
        end
        if numSizes > 0 then
            local minCount = unitsList[type].UnitTotal / numSizes
            
            for fs, count in unitsList[type].FootprintCounts do
                if count >= minCount then
                    smallestFootprints[type] = math.min(smallestFootprints[type] or 99999, fs)
                end
            end
        end
        smallestFootprints[type] = smallestFootprints[type] or largestForType
    end
    
    LOG("Largest: "..largestFootprint..", Smallest: "..repr(smallestFootprints))
    
    -- This bit is so surface naval units and subs have the same grid size.
    local navalGridSize = math.max(smallestFootprints.Naval * types.Naval.GridSizeFraction, smallestFootprints.Naval + types.Naval.GridSizeAbsolute)
    local subGridSize = math.max(smallestFootprints.Subs * types.Subs.GridSizeFraction, smallestFootprints.Subs + types.Subs.GridSizeAbsolute)
    local seaGridSize = math.max(navalGridSize, subGridSize)
    local gridSizes = {Naval = seaGridSize, Subs = seaGridSize}
    
    for type, spacing in types do
        local unitData = unitsList[type]
        local gridSize = gridSizes[type] or math.max(smallestFootprints[type] * spacing.GridSizeFraction, smallestFootprints[type] + spacing.GridSizeAbsolute)
        
         -- A distance of 1 in formation coordinates translates to (largestFootprint + 2) in world coordinates.
         -- Unfortunately the engine separates land/naval units from air units and calls the formation function separately for both groups.
         -- That means if a CZAR and some light tanks are selected together, the tank formation will be scaled by the CZAR's size and we can't compensate.
        unitData.Scale = gridSize / (largestFootprint + 2)
        if unitData.UnitTotal > 0 then
            LOG(type.." Scale = "..unitData.Scale)
        end
        
        for fs, count in unitData.FootprintCounts do
            local size = math.ceil(fs * spacing.MinSeparationFraction / gridSize)
            unitData.FootprintSizes[fs] = size
            LOG(fs.."="..size)
            unitData.AreaTotal = unitData.AreaTotal + count * size * size
        end
    end
    
    return unitsList
end

function CategorizeUnits(formationUnits)
    local unitsList = {
        Land = {
            Bot1 = {}, Bot2 = {}, Bot3 = {}, Bot4 = {},
            Tank1 = {}, Tank2 = {}, Tank3 = {}, Tank4 = {},
            Art1 = {}, Art2 = {}, Art3 = {}, Art4 = {},
            AA1 = {}, AA2 = {}, AA3 = {},
            Com1 = {}, Com2 = {}, Com3 = {}, Com4 = {},
            Util1 = {}, Util2 = {}, Util3 = {}, Util4 = {},
            Shields = {},
            RemainingCategory = {},
            
            UnitTotal = 0,
            AreaTotal = 0,
            FootprintCounts = {},
            FootprintSizes = {},
        },
        
        Air = {
            Ground1 = {}, Ground2 = {}, Ground3 = {},
            Trans1 = {}, Trans2 = {}, Trans3 = {},
            Bomb1 = {}, Bomb2 = {}, Bomb3 = {},
            AA1 = {}, AA2 = {}, AA3 = {},
            AN1 = {}, AN2 = {}, AN3 = {},
            AIntel1 = {}, AIntel2 = {}, AIntel3 = {},
            AExper = {},
            RemainingCategory = {},
            
            UnitTotal = 0,
            AreaTotal = 0,
            FootprintCounts = {},
            FootprintSizes = {},
        },
        
        Naval = {
            CarrierCount = {},
            BattleshipCount = {},
            DestroyerCount = {},
            CruiserCount = {},
            FrigateCount = {},
            LightCount = {},
            NukeSubCount = {},
            MobileSonarCount = {},
            RemainingCategory = {},
            
            UnitTotal = 0,
            AreaTotal = 0,
            FootprintCounts = {},
            FootprintSizes = {},
        },
        
        Subs = {
            SubCount = {},
            
            UnitTotal = 0,
            AreaTotal = 0,
            FootprintCounts = {},
            FootprintSizes = {},
        },
    }
    
    local categoryTables = {Land = LandCategories, Air = AirCategories, Naval = NavalCategories, Subs = SubCategories}
    
    -- Loop through each unit to get its category and size
    for _, u in formationUnits do
        local identified = false
        for type, table in categoryTables do
            for cat, _ in table do
                if EntityCategoryContains(table[cat], u) then
                    local bp = u:GetBlueprint()
                    local fs = math.max(bp.Footprint.SizeX, bp.Footprint.SizeZ)
                    local id = bp.BlueprintId
                    
                    if not unitsList[type][cat][fs] then
                        unitsList[type][cat][fs] = {Count = 0, Categories = {}}
                    end
                    unitsList[type][cat][fs].Count = unitsList[type][cat][fs].Count + 1
                    unitsList[type][cat][fs].Categories[id] = categories[id]
                    unitsList[type].FootprintCounts[fs] = (unitsList[type].FootprintCounts[fs] or 0) + 1
                    
                    if cat == "RemainingCategory" then
                        LOG('*FORMATION DEBUG: Missed unit: ' .. u:GetUnitId())
                    end
                    unitsList[type].UnitTotal = unitsList[type].UnitTotal + 1
                    identified = true
                    break
                end
            end
            
            if identified then
                break
            end
        end
        if not identified then
            WARN('*FORMATION DEBUG: Unable to determine unit type: ' .. u:GetUnitId())
        end
    end
    
    --LOG(repr(unitsList))
    
    -- Loop through each category and combine the types within into a single filter category for each size
    for type, table in categoryTables do
        for cat, _ in table do
            if unitsList[type][cat] then
                for fs, data in unitsList[type][cat] do
                    local filter = nil
                    for _, category in data.Categories do
                        if not filter then
                            filter = category
                        else
                            filter = filter + category
                        end
                    end
                    unitsList[type][cat][fs] = {Count = data.Count, Filter = filter}
                end
            end
        end
    end
    
    --LOG(repr(unitsList))
    
    CalculateSizes(unitsList)
    
    return unitsList
end
