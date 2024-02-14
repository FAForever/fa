-- =========================================
-- ================ AIR DATA ===============
-- =========================================

local RemainingCategory = { 'RemainingCategory', }

-- === AIR CATEGORIES ===
local GroundAttackAir = (categories.AIR * categories.GROUNDATTACK) - categories.ANTIAIR
local TransportationAir = categories.AIR * categories.TRANSPORTATION - categories.GROUNDATTACK
local BomberAir = categories.AIR * categories.BOMBER
local AAAir = categories.AIR * categories.ANTIAIR
local AntiNavyAir = categories.AIR * categories.ANTINAVY
local IntelAir = categories.AIR * (categories.SCOUT + categories.RADAR)
local ExperimentalAir = categories.AIR * categories.EXPERIMENTAL
local EngineerAir = categories.AIR * categories.ENGINEER

-- === TECH LEVEL AIR CATEGORIES ===
AirCategories = {
    Ground1 = GroundAttackAir * categories.TECH1,
    Ground2 = GroundAttackAir * categories.TECH2,
    Ground3 = GroundAttackAir * categories.TECH3,

    Trans1 = TransportationAir * categories.TECH1,
    Trans2 = TransportationAir * categories.TECH2,
    Trans3 = TransportationAir * categories.TECH3,

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

    AEngineer = EngineerAir,

    RemainingCategory = categories.AIR -
        (
        GroundAttackAir + TransportationAir + BomberAir + AAAir + AntiNavyAir + IntelAir + ExperimentalAir + EngineerAir
        )
}

-- === SUB GROUP ORDERING ===
local GroundAttack = { 'Ground3', 'Ground2', 'Ground1', }
local Transports = { 'Trans3', 'Trans2', 'Trans1', }
local Bombers = { 'Bomb3', 'Bomb2', 'Bomb1', }
local T3Bombers = { 'Bomb3', }
local AntiAir = { 'AA3', 'AA2', 'AA1', }
local AntiNavy = { 'AN3', 'AN2', 'AN1', }
local Intel = { 'AIntel3', 'AIntel2', 'AIntel1', }
local ExperAir = { 'AExper', }
local EngAir = { 'AEngineer', }

-------------------------------------------------------------------------------
--#region Air attack chevron formation

local ChevronSlot = { AntiAir, ExperAir, AntiNavy, GroundAttack, Bombers, Intel, Transports, EngAir, RemainingCategory }
StratSlot = { T3Bombers }

AttackChevronBlock = {
    RepeatAllRows = false,
    HomogenousBlocks = true,
    { ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, }, -- 1 -> 3 at 20 units
    { ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, }, -- 3 -> 5 at 60 units
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, }, -- 5 -> 7 at 170 units
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, }, -- 7 -> 9 at 390 units
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot,
        ChevronSlot, ChevronSlot, }, -- 9 -> 11 at 760 units
}

GrowthChevronBlock = {
    RepeatAllRows = false,
    HomogenousBlocks = true,
    { ChevronSlot, },
    { ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, }, -- 1 -> 3 at 25 units
    { ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, }, -- 3 -> 5 at 95 units
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, }, -- 5 -> 7 at 255 units
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, },
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, }, -- 7 -> 9 at 545 units
}

--#endregion
