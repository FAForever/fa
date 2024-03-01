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

---@alias UnitFormations 'AttackFormation' | 'GrowthFormation' | 'NoFormation' | 'None' | 'none'


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
local FormationCache = {}
local MaxCacheSize = 30

---@param formationUnits Unit[]
---@param formationType UnitFormations
---@return boolean
function GetCachedResults(formationUnits, formationType)
    local cache = FormationCache[formationType]
    if not cache then
        return false
    end

    local unitCount = table.getn(formationUnits)
    for _, data in cache do
        if data.UnitCount == unitCount then
            local match = true
            for i = 0, unitCount - 1, 1 do -- These indices are 0-based.
                if data.Units[i] ~= formationUnits[i] then
                    match = false
                    break
                end
            end
            if match then
                return data.Results
            end
        end
    end

    return false
end

---@param results TLaserBotProjectile
---@param formationUnits Unit[]
---@param formationType UnitFormations
function CacheResults(results, formationUnits, formationType)
    if not FormationCache[formationType] then
        FormationCache[formationType] = {}
    end

    local cache = FormationCache[formationType]
    if table.getn(cache) >= MaxCacheSize then
        table.remove(cache)
    end
    table.insert(cache, 1, {Results = results, Units = formationUnits, UnitCount = table.getn(formationUnits)})
end

-- =========================================
-- ================ LAND DATA ==============
-- =========================================
local RemainingCategory = { 'RemainingCategory', }

-- === LAND CATEGORIES ===
local DirectFire = (categories.DIRECTFIRE - (categories.CONSTRUCTION + categories.SNIPER + categories.WEAKDIRECTFIRE)) * categories.LAND
local Sniper = categories.SNIPER * categories.LAND
local Artillery = (categories.ARTILLERY + categories.INDIRECTFIRE - categories.SNIPER) * categories.LAND
local AntiAir = (categories.ANTIAIR - (categories.EXPERIMENTAL + categories.DIRECTFIRE + categories.SNIPER + Artillery)) * categories.LAND
local Construction = ((categories.COMMAND + categories.CONSTRUCTION + categories.ENGINEER) - (DirectFire + Sniper + Artillery)) * categories.LAND
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

    Sniper1 = (Sniper * categories.TECH1) - categories.SCOUT,
    Sniper2 = (Sniper * categories.TECH2) - categories.SCOUT,
    Sniper3 = (Sniper * categories.TECH3) - categories.SCOUT,
    Sniper4 = (Sniper * categories.EXPERIMENTAL) - categories.SCOUT,

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

    RemainingCategory = categories.LAND - (DirectFire + Sniper + Construction + Artillery + AntiAir + UtilityCat + ShieldCat)
}

-- === SUB GROUP ORDERING ===
local Bots = { 'Bot4', 'Bot3', 'Bot2', 'Bot1', }
local Tanks = { 'Tank4', 'Tank3', 'Tank2', 'Tank1', }
local DF = { 'Tank4', 'Bot4', 'Tank3', 'Bot3', 'Tank2', 'Bot2', 'Tank1', 'Bot1', }
local Art = { 'Art4', 'Sniper4', 'Art3', 'Sniper3', 'Art2', 'Sniper2', 'Art1', 'Sniper1', }
local T1Art = { 'Sniper1', 'Art1', 'Sniper2', 'Art2', 'Sniper3', 'Art3', 'Sniper4', 'Art4', }
local AA = { 'AA3', 'AA2', 'AA1', }
local Util = { 'Util4', 'Util3', 'Util2', 'Util1', }
local Com = { 'Com4', 'Com3', 'Com2', 'Com1', }
local Shield = { 'Shields', }

-- === LAND BLOCK TYPES =
local DFFirst = { DF, T1Art, AA, Shield, Com, Util, RemainingCategory }
local ShieldFirst = { Shield, AA, DF, T1Art, Com, Util, RemainingCategory }
local AAFirst = { AA, DF, T1Art, Shield, Com, Util, RemainingCategory }
local ArtFirst = { Art, DF, AA, Shield, Com, Util, RemainingCategory }
local T1ArtFirst = { T1Art, DF, AA, Shield, Com, Util, RemainingCategory }
local UtilFirst = { Util, AA, Shield, DF, T1Art, Com, RemainingCategory }


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
    { DFFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, },
    -- third row
    { DFFirst, UtilFirst, AAFirst, DFFirst, AAFirst, UtilFirst, DFFirst, },
    -- fourth row
    { DFFirst, ShieldFirst, AAFirst, T1ArtFirst, AAFirst, ShieldFirst, DFFirst, },
    -- fifth row
    { DFFirst, T1ArtFirst, AAFirst, ShieldFirst, AAFirst, T1ArtFirst, DFFirst, },
    -- sixth row
    { ArtFirst, UtilFirst, ArtFirst, AAFirst, ArtFirst, UtilFirst, ArtFirst, },
}

-- === 8 Wide Attack Block ===
local EightWideAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, },
    -- second Row
    { DFFirst, ShieldFirst, DFFirst, ShieldFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, },
    -- third row
    { DFFirst, UtilFirst, AAFirst, DFFirst, DFFirst, AAFirst, UtilFirst, DFFirst, },
    -- fourth row
    { DFFirst, ShieldFirst, T1ArtFirst, AAFirst, AAFirst, T1ArtFirst, ShieldFirst, DFFirst, },
    -- fifth row
    { DFFirst, T1ArtFirst, AAFirst, T1ArtFirst, T1ArtFirst, AAFirst, T1ArtFirst, DFFirst, },
    -- sixth row
    { DFFirst, ShieldFirst, UtilFirst, ShieldFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst, },
    -- seventh row
    { DFFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, DFFirst, },
}

-- === 2 Row Attack Block - 8 units wide ===
local TwoRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { AAFirst, UtilFirst, ShieldFirst, ArtFirst, ArtFirst, ShieldFirst, UtilFirst, AAFirst },
}

-- === 3 Row Attack Block - 10 units wide ===
local ThreeRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { AAFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst, ShieldFirst, AAFirst },
    -- third row
    { DFFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, DFFirst },
}

-- === 4 Row Attack Block - 12 units wide ===
local FourRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { DFFirst, ShieldFirst, DFFirst, UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst, DFFirst, ShieldFirst, DFFirst },
    -- third row
    { DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst },
    -- fourth row
    { AAFirst, ShieldFirst, DFFirst, ArtFirst, ShieldFirst, ArtFirst, ArtFirst, ShieldFirst, ArtFirst, DFFirst, ShieldFirst, AAFirst },
}

-- === 5 Row Attack Block - 14 units wide ===
local FiveRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { UtilFirst, ShieldFirst, DFFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst, ShieldFirst, UtilFirst },
    -- third row
    { DFFirst, AAFirst, DFFirst, AAFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, AAFirst, DFFirst, AAFirst, DFFirst },
    -- fourth row
    { AAFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, ShieldFirst, AAFirst, AAFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, ShieldFirst, AAFirst },
    -- five row
    { ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst },
}

-- === 6 Row Attack Block - 16 units wide ===
local SixRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { UtilFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst, DFFirst, ShieldFirst, DFFirst, ShieldFirst, UtilFirst },
    -- third row
    { DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst },
    -- fourth row
    { AAFirst, ShieldFirst, AAFirst, DFFirst, AAFirst, AAFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, AAFirst, AAFirst, DFFirst, AAFirst, ShieldFirst, AAFirst },
    -- fifth row
    { DFFirst, AAFirst, DFFirst, UtilFirst, ShieldFirst, DFFirst, DFFirst, AAFirst, AAFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst, DFFirst, AAFirst, DFFirst },
    -- sixth row
    { AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst },
}

-- === 7 Row Attack Block - 18 units wide ===
local SevenRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { UtilFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, ShieldFirst, UtilFirst },
    -- third row
    { DFFirst, DFFirst, AAFirst, DFFirst, AAFirst, DFFirst, DFFirst, DFFirst, AAFirst, AAFirst, DFFirst, DFFirst, DFFirst, AAFirst, DFFirst, AAFirst, DFFirst, DFFirst },
    -- fourth row
    { DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst },
    -- fifth row
    { UtilFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, UtilFirst },
    -- sixth row
    { DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, UtilFirst, DFFirst, ShieldFirst, AAFirst, AAFirst, ShieldFirst, DFFirst, UtilFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst },
    -- seventh row
    { ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst },
}

-- === 8 Row Attack Block - 20 units wide ===
local EightRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { DFFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst },
    -- third row
    { DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst },
    -- fourth row
    { DFFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, ShieldFirst, AAFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, AAFirst, ShieldFirst, DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, DFFirst },
    -- fifth row
    { DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, AAFirst, AAFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst },
    -- sixth row
    { UtilFirst, ShieldFirst, ArtFirst, ShieldFirst, ArtFirst, UtilFirst, ShieldFirst, ArtFirst, ShieldFirst, AAFirst, AAFirst, ShieldFirst, ArtFirst, ShieldFirst, UtilFirst, ArtFirst, ShieldFirst, ArtFirst, ShieldFirst, UtilFirst },
    -- seventh row
    { DFFirst, AAFirst, DFFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, DFFirst, AAFirst, DFFirst },
    -- eight row
    { AAFirst, ShieldFirst, ArtFirst, AAFirst, ShieldFirst, ArtFirst, ShieldFirst, AAFirst, ShieldFirst, ArtFirst, ArtFirst, ShieldFirst, AAFirst, ShieldFirst, ArtFirst, ShieldFirst, AAFirst, ArtFirst, ShieldFirst, AAFirst },
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
local EngineerAir = categories.AIR * categories.ENGINEER

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

    AEngineer = EngineerAir,

    RemainingCategory = categories.AIR - (GroundAttackAir + TransportationAir + BomberAir + AAAir + AntiNavyAir + IntelAir + ExperimentalAir + EngineerAir)
}

-- === SUB GROUP ORDERING ===
local GroundAttack = { 'Ground3', 'Ground2', 'Ground1', }
local Transports = { 'Trans3', 'Trans2', 'Trans1', }
local Bombers = { 'Bomb3', 'Bomb2', 'Bomb1', }
local T3Bombers = {'Bomb3',}
local AntiAir = { 'AA3', 'AA2', 'AA1', }
local AntiNavy = { 'AN3', 'AN2', 'AN1', }
local Intel = { 'AIntel3', 'AIntel2', 'AIntel1', }
local ExperAir = { 'AExper', }
local EngAir = { 'AEngineer', }

-- === Air Block Arrangement ===
local ChevronSlot = { AntiAir, ExperAir, AntiNavy, GroundAttack, Bombers, Intel, Transports, EngAir, RemainingCategory }
local StratSlot = { T3Bombers }

local AttackChevronBlock = {
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
    { ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, ChevronSlot, }, -- 9 -> 11 at 760 units
}

local GrowthChevronBlock = {
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



-- =========================================
-- ============== NAVAL DATA ===============
-- =========================================

local LightAttackNaval = categories.LIGHTBOAT
local FrigateNaval = categories.FRIGATE
local SubNaval = categories.T1SUBMARINE + categories.T2SUBMARINE + (categories.NUKESUB * categories.ANTINAVY - categories.NUKE)
local DestroyerNaval = categories.DESTROYER
local CruiserNaval = categories.CRUISER
local BattleshipNaval = categories.BATTLESHIP
local CarrierNaval = categories.NAVALCARRIER
local NukeSubNaval = categories.NUKESUB - SubNaval
local MobileSonar = categories.MOBILESONAR
local DefensiveBoat = categories.DEFENSIVEBOAT
local RemainingNaval = categories.NAVAL - (LightAttackNaval + FrigateNaval + SubNaval + DestroyerNaval + CruiserNaval + BattleshipNaval +
                        CarrierNaval + NukeSubNaval + DefensiveBoat + MobileSonar)


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

-- === NAVAL BLOCK TYPES =
local FrigatesFirst = { Frigates, Destroyers, Battleships, Cruisers, Carriers, NukeSubs, Sonar, RemainingCategory }
local DestroyersFirst = { Destroyers, Frigates, Battleships, Cruisers, Carriers, NukeSubs, Sonar, RemainingCategory }
local CruisersFirst = { Cruisers, Carriers, Battleships, Destroyers, Frigates, NukeSubs, Sonar, RemainingCategory }
local LargestFirstDF = { Battleships, Carriers, Destroyers, Cruisers, Frigates, NukeSubs, Sonar, RemainingCategory }
local SmallestFirstDF = { Frigates, Destroyers, Cruisers, Sonar, Battleships, Carriers, NukeSubs, RemainingCategory }
local LargestFirstAA = { Carriers, Battleships, Cruisers, Destroyers, Frigates, NukeSubs, Sonar, RemainingCategory }
local SmallestFirstAA = { Cruisers, Frigates, Destroyers, Sonar, Carriers, Battleships, NukeSubs, RemainingCategory }
local Subs = { Subs, NukeSubs, RemainingCategory }
local SonarFirst = { Sonar, Carriers, Cruisers, Battleships, Destroyers, Frigates, NukeSubs, Sonar, RemainingCategory }

-- === NAVAL BLOCKS ===

-- === Three Naval Growth Formation Block ==
local ThreeNavalGrowthFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst },
    -- second row
    { LargestFirstDF, SonarFirst, LargestFirstDF },
    -- third row
    { DestroyersFirst, CruisersFirst, DestroyersFirst },
}

-- === Five Naval Growth Formation Block ==
local FiveNavalGrowthFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst },
    -- second row
    { FrigatesFirst, LargestFirstDF, DestroyersFirst, LargestFirstDF, FrigatesFirst },
    -- third row
    { DestroyersFirst, SmallestFirstDF, SonarFirst, SmallestFirstDF, DestroyersFirst },
    -- fourth row
    { DestroyersFirst, LargestFirstAA, CruisersFirst, LargestFirstAA, DestroyersFirst },
    -- fifth row
    { DestroyersFirst, SmallestFirstAA, CruisersFirst, SmallestFirstAA, DestroyersFirst },

}

-- === Seven Naval Growth Formation Block ==
local SevenNavalGrowthFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst },
    -- second row
    { FrigatesFirst, SmallestFirstDF, DestroyersFirst, DestroyersFirst, DestroyersFirst, SmallestFirstDF, FrigatesFirst },
    -- third row
    { DestroyersFirst, DestroyersFirst, LargestFirstDF, SonarFirst, LargestFirstDF, DestroyersFirst, DestroyersFirst },
    -- fourth row
    { DestroyersFirst, SmallestFirstAA, SmallestFirstAA, CruisersFirst, SmallestFirstAA, SmallestFirstAA, DestroyersFirst },
    -- fifth row
    { DestroyersFirst, CruisersFirst, LargestFirstAA, DestroyersFirst, LargestFirstAA, CruisersFirst, DestroyersFirst },
    -- sixth row
    { DestroyersFirst, SmallestFirstAA, SmallestFirstAA, SonarFirst, SmallestFirstAA, SmallestFirstAA, DestroyersFirst },
    -- seventh row
    { DestroyersFirst, CruisersFirst, LargestFirstDF, CruisersFirst, LargestFirstDF, CruisersFirst, DestroyersFirst },
}

-- === Nine Naval Growth Formation Block ==
local NineNavalGrowthFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst },
    -- second row
    { FrigatesFirst, LargestFirstDF, SonarFirst, LargestFirstDF, DestroyersFirst, LargestFirstDF, SonarFirst, LargestFirstDF, FrigatesFirst },
    -- third row
    { SmallestFirstDF, DestroyersFirst, SmallestFirstAA, SmallestFirstAA, SonarFirst, SmallestFirstAA, SmallestFirstAA, DestroyersFirst, SmallestFirstDF },
    -- fourth row
    { DestroyersFirst, LargestFirstAA, CruisersFirst, LargestFirstAA, CruisersFirst, LargestFirstAA, CruisersFirst, LargestFirstAA, DestroyersFirst },
    -- fifth row
    { DestroyersFirst, DestroyersFirst, SmallestFirstAA, SmallestFirstAA, CruisersFirst, SmallestFirstAA, SmallestFirstAA, DestroyersFirst, DestroyersFirst },
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
    { DestroyersFirst, LargestFirstDF, CruisersFirst, LargestFirstDF, DestroyersFirst},
}

-- === Seven Wide Naval Attack Formation Block ==
local SevenWideNavalAttackFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst },
    -- second row
    { DestroyersFirst, SonarFirst, LargestFirstDF, DestroyersFirst, LargestFirstDF, SonarFirst, DestroyersFirst },
    -- third row
    { SmallestFirstDF, SmallestFirstAA, SmallestFirstDF, CruisersFirst, SmallestFirstDF, SmallestFirstAA, SmallestFirstDF },
}

-- === Nine Wide Naval Attack Formation Block ==
local NineWideNavalAttackFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst },
    -- second row
    { DestroyersFirst, LargestFirstDF, SonarFirst, LargestFirstDF, DestroyersFirst, LargestFirstDF, SonarFirst, LargestFirstDF, DestroyersFirst },
    -- third row
    { SmallestFirstDF, DestroyersFirst, SmallestFirstAA, SmallestFirstAA, SonarFirst, SmallestFirstAA, SmallestFirstAA, DestroyersFirst, SmallestFirstDF },
    -- fourth row
    { DestroyersFirst, SmallestFirstDF, CruisersFirst, LargestFirstAA, CruisersFirst, LargestFirstAA, CruisersFirst, SmallestFirstDF, DestroyersFirst },
}

-- === Eleven Wide Naval Attack Formation Block ==
local ElevenWideNavalAttackFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst },
    -- second row
    { DestroyersFirst, DestroyersFirst, LargestFirstDF, SmallestFirstDF, LargestFirstDF, DestroyersFirst, LargestFirstDF, SmallestFirstDF, LargestFirstDF, DestroyersFirst, DestroyersFirst },
    -- third row
    { SmallestFirstDF, DestroyersFirst, SmallestFirstAA, SmallestFirstAA, SmallestFirstAA, SonarFirst, SmallestFirstAA, SmallestFirstAA, SmallestFirstAA, DestroyersFirst, SmallestFirstDF },
    -- fourth row
    { DestroyersFirst, SmallestFirstAA, LargestFirstDF, SonarFirst, LargestFirstAA, CruisersFirst, LargestFirstAA, SonarFirst, LargestFirstDF, SmallestFirstAA, DestroyersFirst },
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

-- === Eight Wide Subs Formation ===
local EightWideSubGrowthFormation = {
    LineBreak = 0.5,
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
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

-- === Ten Wide Subs Formation ===
local TenWideSubAttackFormation = {
    LineBreak = 0.5,
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
}

-- ============ Formation Pickers ============
---@param typeName string
---@param distance Vector
---@return number
function PickBestTravelFormationIndex(typeName, distance)
    if typeName == 'AirFormations' then
        return 0;
    else
        return 1;
    end
end

---@param typeName string
---@param distance Vector
---@return number
function PickBestFinalFormationIndex(typeName, distance)
    return -1;
end

-- ================ THE GUTS ====================
-- ============ Formation Functions =============
-- ==============================================
---@param formationUnits Unit[]
---@return table
function AttackFormation(formationUnits)
    local cachedResults = GetCachedResults(formationUnits, 'AttackFormation')
    if cachedResults then
        return cachedResults
    end

    FormationPos = {}

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
    else -- 20 wide
        landBlock = EightRowAttackFormationBlock
    end
    BlockBuilderLand(landUnitsList, landBlock, LandCategories, 1)

    local seaUnitsList = unitsList.Naval
    local subUnitsList = unitsList.Subs
    local seaArea = seaUnitsList.AreaTotal
    local subArea = subUnitsList.AreaTotal
    local seaBlock
    local subBlock

    if seaArea <= 10 and subArea <= 8 then
        seaBlock = FiveWideNavalAttackFormation
        subBlock = FourWideSubAttackFormation
    elseif seaArea <= 21 and subArea <= 18 then
        seaBlock = SevenWideNavalAttackFormation
        subBlock = SixWideSubAttackFormation
    elseif seaArea <= 36 and subArea <= 32 then
        seaBlock = NineWideNavalAttackFormation
        subBlock = EightWideSubAttackFormation
    else
        seaBlock = ElevenWideNavalAttackFormation
        subBlock = TenWideSubAttackFormation
    end
    BlockBuilderLand(seaUnitsList, seaBlock, NavalCategories, 1)
    BlockBuilderLand(subUnitsList, subBlock, SubCategories, 1)
    BlockBuilderAir(unitsList.Air, AttackChevronBlock, 1)

    CacheResults(FormationPos, formationUnits, 'AttackFormation')
    return FormationPos
end

---@param formationUnits Unit[]
---@return table
function GrowthFormation(formationUnits)
    local cachedResults = GetCachedResults(formationUnits, 'GrowthFormation')
    if cachedResults then
        return cachedResults
    end

    FormationPos = {}

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
    else
        landBlock = EightWideAttackFormationBlock
    end
    BlockBuilderLand(landUnitsList, landBlock, LandCategories, 1)

    local seaUnitsList = unitsList.Naval
    local subUnitsList = unitsList.Subs
    local seaArea = seaUnitsList.AreaTotal
    local subArea = subUnitsList.AreaTotal
    local seaBlock
    local subBlock

    if seaArea <= 9 and subArea <= 12 then
        seaBlock = ThreeNavalGrowthFormation
        subBlock = FourWideSubGrowthFormation
    elseif seaArea <= 25 and subArea <= 20 then
        seaBlock = FiveNavalGrowthFormation
        subBlock = FourWideSubGrowthFormation
    elseif seaArea <= 49 and subArea <= 42 then
        seaBlock = SevenNavalGrowthFormation
        subBlock = SixWideSubGrowthFormation
    else
        seaBlock = NineNavalGrowthFormation
        subBlock = EightWideSubGrowthFormation
    end
    BlockBuilderLand(seaUnitsList, seaBlock, NavalCategories, 1)
    BlockBuilderLand(subUnitsList, subBlock, SubCategories, 1)

    if unitsList.Air.Bomb3[1] then
        local count = unitsList.Air.Bomb3[1].Count
        local oldAirArea = unitsList.Air.AreaTotal
        local oldUnitTotal = unitsList.Air.UnitTotal

        unitsList.Air.AreaTotal = count
        unitsList.Air.UnitTotal = count

        BlockBuilderAirT3Bombers(unitsList.Air, 1.5) --strats formation

        --strats are already in formation so we remove them from table and adjust all parameters.
        unitsList.Air.Bomb3 = {}
        unitsList.Air.AreaTotal = oldAirArea - count
        unitsList.Air.UnitTotal = oldUnitTotal - count

        BlockBuilderAir(unitsList.Air, GrowthChevronBlock, 1)
    else
        BlockBuilderAir(unitsList.Air, GrowthChevronBlock, 1)
    end


    CacheResults(FormationPos, formationUnits, 'GrowthFormation')
    return FormationPos
end

---@param formationUnits Unit[]
---@return table
function GuardFormation(formationUnits)
    -- Not worth caching GuardFormation because it's almost never called repeatedly with the same units.
    local FormationPos = {}

    local shieldCategory = ShieldCat
    local nonShieldCategory = categories.ALLUNITS - shieldCategory
    local footprintCounts = {}
    local remainingUnits = table.getn(formationUnits)
    local remainingShields = 0
    for _, u in formationUnits do
        if EntityCategoryContains(ShieldCat, u) then
            remainingShields = remainingShields + 1
        end

        local fs = u:GetBlueprint().Footprint.SizeMax
        footprintCounts[fs] = (footprintCounts[fs] or 0) + 1
    end

    local numSizes = 0
    for _ in footprintCounts do
        numSizes = numSizes + 1
    end

    local largestFootprint = 0
    local smallestFootprint = 9999
    local minCount = remainingUnits / numSizes -- This could theoretically divide by 0, but it wouldn't be a problem because the result would never be used.
    for fs, count in footprintCounts do
        largestFootprint = math.max(largestFootprint, fs)
        if count >= minCount then
            smallestFootprint = math.min(smallestFootprint, fs)
        end
    end

    local ringSpacing = (smallestFootprint + 2) / (largestFootprint + 2) -- A distance of 1 in formation coordinates is translated to (largestFootprint + 2) world units.
    local rotate = false
    local sizeMult = 0
    local ringChange = 0
    local ringCount = 1
    local unitCount = 1
    local shieldsInRing = 0
    local unitsPerShield = 0
    local nextShield = 0

    -- Form concentric circles around the assisted unit
    -- Most of the numbers after this point are arbitrary. Don't go looking for the significance of 0.19 or the like because there is none.
    while remainingUnits > 0 do
        if unitCount > ringChange then
            unitCount = 1
            ringCount = ringCount + 1
            sizeMult = ringCount * ringSpacing
            ringChange = ringCount * 6
            if remainingUnits < ringChange * 1.167 then
                ringChange = remainingUnits -- It looks better to squeeze a few more units into the last ring than add a ring with only one or two units.
            end

            if ringCount == 2 or remainingShields >= (remainingUnits + ringChange + 6) * 0.19 then
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
        local ringPosition = unitCount / ringChange * math.pi * 2.0
        offsetX = sizeMult * math.sin(ringPosition)
        offsetY = -sizeMult * math.cos(ringPosition)
        if shieldsInRing > 0 and unitCount >= nextShield then
            table.insert(FormationPos, { offsetX, offsetY, shieldCategory, 0, rotate })
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
---@param unitsList table
---@param formationBlock any
---@param categoryTable EntityCategory[]
---@param spacing? number defaults to 1
---@return table
function BlockBuilderLand(unitsList, formationBlock, categoryTable, spacing)
    spacing = (spacing or 1) * unitsList.Scale
    local numRows = table.getn(formationBlock)
    local rowNum = 1
    local whichRow = 1
    local whichCol = 1
    local currRowLen = table.getn(formationBlock[whichRow])
    local rowModifier = GetLandRowModifer(unitsList, categoryTable, currRowLen)
    currRowLen = currRowLen - rowModifier
    local evenRowLen = math.mod(currRowLen, 2) == 0
    local rowType = false
    local formationLength = 0
    local inserted = false
    local occupiedSpaces = {}

    while unitsList.UnitTotal > 0 do
        if whichCol > currRowLen then
            rowNum = rowNum + 1
            if whichRow == numRows then
                whichRow = 1
            else
                whichRow = whichRow + 1
            end
            formationLength = formationLength + 1 + (formationBlock.LineBreak or 0)
            whichCol = 1
            rowType = false
            currRowLen = table.getn(formationBlock[whichRow])
            if occupiedSpaces[rowNum] then
                rowModifier = 0
            else
                rowModifier = GetLandRowModifer(unitsList, categoryTable, currRowLen)
            end
            currRowLen = currRowLen - rowModifier
            evenRowLen = math.mod(currRowLen, 2) == 0
        end

        if occupiedSpaces[rowNum] and occupiedSpaces[rowNum][whichCol] then
            whichCol = whichCol + 1
            continue
        end

        local currColSpot = GetColSpot(currRowLen + rowModifier, whichCol + rowModifier) -- Translate whichCol to correct spot in row
        local currSlot = formationBlock[whichRow][currColSpot]
        for _, type in currSlot do
            if inserted then
                break
            end
            for _, group in type do
                if not formationBlock.HomogenousRows or (rowType == false or rowType == type) then
                    local fs = 0
                    local size = 0
                    local evenSize = true
                    local groupData = nil
                    for k, v in unitsList[group] do
                        size = unitsList.FootprintSizes[k]
                        evenSize = math.mod(size, 2) == 0
                        if v.Count > 0 then
                            if size > 1 and IsLandSpaceOccupied(occupiedSpaces, size, rowNum, whichCol, currRowLen, unitsList.UnitTotal) then
                                continue
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

                            OccupyLandSpace(occupiedSpaces, size, rowNum, whichCol, currRowLen)
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

                        table.insert(FormationPos, {xPos * spacing, (-formationLength - offsetY) * spacing, groupData.Filter, formationLength, true})
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
            unitsList.UnitTotal = unitsList.UnitTotal - 1
            inserted = false
        end
        whichCol = whichCol + 1
    end

    return FormationPos
end

---@param unitsList table
---@param categoryTable EntityCategory[]
---@param currRowLen number
---@return number
function GetLandRowModifer(unitsList, categoryTable, currRowLen)
    if unitsList.UnitTotal >= currRowLen or math.mod(unitsList.UnitTotal, 2) == math.mod(currRowLen, 2) then
        return 0
    end

    local sizeTotal = 0
    for group, _ in categoryTable do
        for fs, data in unitsList[group] do
            sizeTotal = sizeTotal + unitsList.FootprintSizes[fs] * data.Count
        end
    end
    if sizeTotal < currRowLen then -- This doesn't allow for large units hanging over the sides, but it's too hard to handle that correctly.
        return 1
    else
        return 0
    end
end

---@param occupiedSpaces boolean[][]
---@param size number
---@param rowNum number
---@param whichCol number
---@param currRowLen number
---@param remainingUnits number
---@return boolean
function IsLandSpaceOccupied(occupiedSpaces, size, rowNum, whichCol, currRowLen, remainingUnits)
    local evenRowLen = math.mod(currRowLen, 2) == 0
    local evenSize = math.mod(size, 2) == 0

    if whichCol == 1 and (not evenRowLen) and evenSize and remainingUnits > 1 then -- Don't put an even-sized unit in the middle of an odd-length row unless it's the last unit
        return true
    end
    if whichCol > currRowLen - math.floor(size / 2) * 2 and size <= math.floor(currRowLen / 2) then -- Don't put a large unit at the end of a row unless the row is too narrow
        return true
    end
    for y = 0, size - 1, 1 do
        local yPos = rowNum + y
        if not occupiedSpaces[yPos] then
            continue
        end
        if whichCol == 1 and evenRowLen == evenSize then
            for x = 0, size - 1, 1 do
                if occupiedSpaces[yPos][whichCol + x] then
                    return true
                end
            end
        else
            for x = 0, (size - 1) * 2, 2 do
                if occupiedSpaces[yPos][whichCol + x] then
                    return true
                end
            end
        end
    end
    return false
end

---@param occupiedSpaces boolean[][]
---@param size number
---@param rowNum number
---@param whichCol number
---@param currRowLen number
function OccupyLandSpace(occupiedSpaces, size, rowNum, whichCol, currRowLen)
    local evenRowLen = math.mod(currRowLen, 2) == 0
    local evenSize = math.mod(size, 2) == 0

    for y = 0, size - 1, 1 do
        local yPos = rowNum + y
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

---@param rowLen number
---@param col number
---@return number
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
---@param unitsList table
---@param airBlock any
---@param spacing? number defaults to 1
---@return table
function BlockBuilderAir(unitsList, airBlock, spacing)
    spacing = (spacing or 1) * unitsList.Scale
    local numRows = table.getn(airBlock)
    local whichRow = 1
    local whichCol = 1
    local chevronPos = 1
    local currRowLen = table.getn(airBlock[whichRow])
    local chevronSize = airBlock.ChevronSize or 5
    local chevronType = false
    local formationLength = 0

    if unitsList.AreaTotal > unitsList.UnitTotal then -- If there are any units of size > 1 deal with them here
        local largeUnitPositions = GetLargeAirPositions(unitsList, airBlock)
        for _, data in largeUnitPositions do
            local currSlot = airBlock[data.row][data.col]
            for _, type in currSlot do
                for _, group in type do
                    for fs, groupData in unitsList[group] do
                        size = unitsList.FootprintSizes[fs]
                        if groupData.Count > 0 and size == data.size then
                            table.insert(FormationPos, {data.xPos * spacing, data.yPos * spacing, groupData.Filter, 0, true})
                            groupData.Count = groupData.Count - 1
                            if groupData.Count <= 0 then
                                unitsList[group][fs] = nil
                            end
                            unitsList.UnitTotal = unitsList.UnitTotal - 1
                            break
                        end
                    end
                end
            end
        end
    end

    if unitsList.UnitTotal < chevronSize and math.mod(unitsList.UnitTotal, 2) == 0 then
        chevronPos = 2
    end

    while unitsList.UnitTotal > 0 do
        if chevronPos > chevronSize then
            if unitsList.UnitTotal < chevronSize and math.mod(unitsList.UnitTotal, 2) == 0 then
                chevronPos = 2
            else
                chevronPos = 1
            end
            chevronType = false
            if whichCol >= currRowLen or unitsList.UnitTotal < chevronSize or unitsList.UnitTotal < chevronSize * 2 and math.mod(whichCol, 2) == 1 then
                if whichRow >= numRows then
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
        for _, type in currSlot do
            if inserted then
                break
            end
            for _, group in type do
                if not airBlock.HomogenousBlocks or chevronType == false or chevronType == type then
                    local fs = 0
                    local groupData = nil
                    for k, v in unitsList[group] do
                        if v.Count > 0 then
                            fs = k
                            groupData = v
                            break
                        end
                    end
                    if groupData then
                        local xPos, yPos = GetChevronPosition(chevronPos, whichCol, formationLength)
                        if airBlock.HomogenousBlocks and not chevronType then
                            chevronType = type
                        end
                        table.insert(FormationPos, {xPos * spacing, yPos * spacing, groupData.Filter, 0, true})
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
            unitsList.UnitTotal = unitsList.UnitTotal - 1
        end
        chevronPos = chevronPos + 1
    end
    return FormationPos
end

---@param unitsList table
---@param spacing number? number defaults to 1
---@return table
function BlockBuilderAirT3Bombers(unitsList, spacing)
    --This is modified copy of BlockBuilderAir(). This function is used only for t3 bombers.
    --Some parts can be improved, but I just want stable and working version, so I did minimum adjustments and that's it.

    spacing = (spacing or 1) * unitsList.Scale
    local airBlock = {}

    if unitsList.Bomb3[1].Count > 20 then
        airBlock = {
            RepeatAllRows = false,
            HomogenousBlocks = true,
            {StratSlot}, --flight leader
            {StratSlot,StratSlot,StratSlot}, -- 3 lines
        }
    else
        airBlock = {
            RepeatAllRows = false,
            HomogenousBlocks = true,
            {StratSlot}, --flight leader
            {StratSlot,StratSlot}, -- 2 lines
        }
    end

    local numRows = table.getn(airBlock)
    local whichRow = 1
    local whichCol = 1
    local chevronPos = 1
    local currRowLen = table.getn(airBlock[whichRow])
    local chevronSize = 1
    local chevronType = false
    local formationLength = 0


    if unitsList.UnitTotal < chevronSize and math.mod(unitsList.UnitTotal, 2) == 0 then
        chevronPos = 2
    end

    while unitsList.UnitTotal > 0 do
        if chevronPos > chevronSize then
            if unitsList.UnitTotal < chevronSize and math.mod(unitsList.UnitTotal, 2) == 0 then
                chevronPos = 2
            else
                chevronPos = 1
            end
            chevronType = false
            if whichCol >= currRowLen or unitsList.UnitTotal < chevronSize or unitsList.UnitTotal < chevronSize * 2 and math.mod(whichCol, 2) == 1 then
                if whichRow >= numRows then
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
        for _, type in currSlot do
            if inserted then
                break
            end
            for _, group in type do
                if not airBlock.HomogenousBlocks or chevronType == false or chevronType == type then
                    local fs = 0
                    local groupData = nil
                    for k, v in unitsList[group] do
                        if v.Count > 0 then
                            fs = k
                            groupData = v
                            break
                        end
                    end
                    if groupData then
                        local xPos, yPos = GetChevronPosition(chevronPos, whichCol, formationLength)
                        if airBlock.HomogenousBlocks and not chevronType then
                            chevronType = type
                        end
                        table.insert(FormationPos, {xPos * spacing, yPos * spacing, groupData.Filter, 0, true})
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
            unitsList.UnitTotal = unitsList.UnitTotal - 1
        end
        chevronPos = chevronPos + 1
    end
    return FormationPos
end

---@param unitsList table
---@param airBlock any
---@return table
function GetLargeAirPositions(unitsList, airBlock)
    local sizeCounts = {}
    for fs, count in unitsList.FootprintCounts do
        local size = unitsList.FootprintSizes[fs]
        if size > 1 then
            sizeCounts[size] = (sizeCounts[size] or 0) + count
        end
    end

    local numRows = table.getn(airBlock)
    local whichRow = 0
    local whichCol = 0
    local currRowLen = 0
    local wideRow = false
    local formationLength = -1
    local results = {}
    local numResults = 0
    for size, count in sizeCounts do
        local radius = size / 2
        while count > 0 do
            if whichCol >= currRowLen or count == 1 then
                if whichRow >= numRows then
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
                local x, y = GetChevronPosition(1, currRowLen, formationLength)
                wideRow = math.abs(x) >= radius
            else
                whichCol = whichCol + 2
            end

            if count == 2 and whichCol == 1 and wideRow then
                continue
            end

            local xPos, yPos = GetChevronPosition(1, whichCol, formationLength)
            if whichCol ~= 1 and math.abs(xPos) < radius then
                continue
            end

            -- Exponential complexity isn't fun but this should run in under 0.03 seconds on a slow CPU with 500 CZARs.
            local blocked = false
            for i = numResults, 1, -1 do -- Don't change this to a simple forward loop or it can take 15x as long with large numbers.
                local data = results[i]
                if VDist2(xPos, yPos, data.xPos, data.yPos) < radius + data.size / 2 then
                    blocked = true
                    break
                end
            end
            if not blocked then
                table.insert(results, {row = whichRow, col = whichCol, xPos = xPos, yPos = yPos, size = size})
                count = count - 1
                numResults = numResults + 1
                if whichCol ~= 1 then
                    table.insert(results, {row = whichRow, col = whichCol - 1, xPos = -xPos, yPos = yPos, size = size})
                    count = count - 1
                    numResults = numResults + 1
                end
            end
        end
    end
    return results
end

---@param chevronPos Vector
---@param currCol number
---@param formationLen number
---@return number xPos
---@return number yPos
function GetChevronPosition(chevronPos, currCol, formationLen)
    local offset = math.floor(chevronPos / 2)
    local xPos = offset * 0.5
    if math.mod(chevronPos, 2) == 0 then
        xPos = -xPos
    end
    local column = math.floor(currCol / 2)
    local yPos = (-offset + column * column) * 0.86603
    yPos = yPos - formationLen * 1.73205
    local blockOff = math.floor(currCol / 2) * 2.5
    if math.mod(currCol, 2) == 1 then
        blockOff = -blockOff
    end
    xPos = xPos + blockOff
    return xPos, yPos
end

-- ========= UNIT SORTING ==========
---@param unitsList table
---@return any
function CalculateSizes(unitsList)
    local largestFootprint = 1
    local smallestFootprints = {}

    local typeGroups = {
        Land = {
            GridSizeFraction = 2.75,
            GridSizeAbsolute = 2,
            MinSeparationFraction = 2.25,
            Types = {'Land'}
        },

        Air = {
            GridSizeFraction = 1.3,
            GridSizeAbsolute = 2,
            MinSeparationFraction = 1,
            Types = {'Air'}
        },

        Sea = {
            GridSizeFraction = 1.75,
            GridSizeAbsolute = 4,
            MinSeparationFraction = 1.15,
            Types = {'Naval', 'Subs'}
        },
    }

    for group, data in typeGroups do
        local groupFootprintCounts = {}
        local largestForGroup = 1
        local numSizes = 0
        local unitTotal = 0
        for _, type in data.Types do
            unitTotal = unitTotal + unitsList[type].UnitTotal
            for fs, count in unitsList[type].FootprintCounts do
                groupFootprintCounts[fs] = (groupFootprintCounts[fs] or 0) + count
                largestFootprint = math.max(largestFootprint, fs)
                largestForGroup = math.max(largestForGroup, fs)
                numSizes = numSizes + 1
            end
        end

        smallestFootprints[group] = largestForGroup
        if numSizes > 0 then
            local minCount = unitTotal / 2
            local smallerUnitCount = 0
            for fs, count in groupFootprintCounts do
                smallerUnitCount = smallerUnitCount + count
                if smallerUnitCount >= minCount then
                    smallestFootprints[group] = fs -- Base the grid size on the median unit size to avoid a few small units shrinking a formation of large untis
                    break
                end
            end
        end
    end

    for group, data in typeGroups do
        local gridSize = math.max(smallestFootprints[group] * data.GridSizeFraction, smallestFootprints[group] + data.GridSizeAbsolute)
        for _, type in data.Types do
            local unitData = unitsList[type]

             -- A distance of 1 in formation coordinates translates to (largestFootprint + 2) in world coordinates.
             -- Unfortunately the engine separates land/naval units from air units and calls the formation function separately for both groups.
             -- That means if a CZAR and some light tanks are selected together, the tank formation will be scaled by the CZAR's size and we can't compensate.
            unitData.Scale = gridSize / (largestFootprint + 2)

            for fs, count in unitData.FootprintCounts do
                local size = math.ceil(fs * data.MinSeparationFraction / gridSize)
                unitData.FootprintSizes[fs] = size
                unitData.AreaTotal = unitData.AreaTotal + count * size * size
            end
        end
    end

    return unitsList
end

---@param formationUnits Unit[]
---@return table
function CategorizeUnits(formationUnits)
    local unitsList = {
        Land = {
            Bot1 = {}, Bot2 = {}, Bot3 = {}, Bot4 = {},
            Tank1 = {}, Tank2 = {}, Tank3 = {}, Tank4 = {},
            Sniper1 = {}, Sniper2 = {}, Sniper3 = {}, Sniper4 = {},
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
            AEngineer = {},
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
                        LOG('*FORMATION DEBUG: Unit ' .. repr(u:GetBlueprint().BlueprintId) .. ' does not match any ' .. type .. ' categories.')
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
            WARN('*FORMATION DEBUG: Unit ' .. u.UnitId .. ' was excluded from the formation because its layer could not be determined.')
        end
    end

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

    CalculateSizes(unitsList)

    return unitsList
end