local UBC = '/lua/editor/UvesoBuildConditions.lua'
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local EBC = '/lua/editor/EconomyBuildConditions.lua'
local IBC = '/lua/editor/InstantBuildConditions.lua'
local MIBC = '/lua/editor/MiscBuildConditions.lua'
local TBC = '/lua/editor/ThreatBuildConditions.lua'

local ExperimentalCount = 3
local mapSizeX, mapSizeZ = GetMapSize()
local BaseMilitaryZone = math.max( mapSizeX-50, mapSizeZ-50 ) / 2 -- Half the map
local BasePanicZone = BaseMilitaryZone / 2
BasePanicZone = math.max( 40, BasePanicZone )
BasePanicZone = math.min( 120, BasePanicZone )

-- ===================================================-======================================================== --
-- ==                                 Air Fighter/Bomber T1 T2 T3 Builder                                    == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'AntiAirBuilders Uveso',
    BuildersType = 'FactoryBuilder',
    -- ============ --
    --    TECH 1    --
    -- ============ --
    Builder {
        BuilderName = 'U1 Interceptors Minimum',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.MOBILE * categories.AIR * categories.ANTIAIR }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.MOBILE * categories.ENGINEER}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.LAND * categories.FACTORY * categories.TECH1 }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconStorageRatio', { 0.00, 0.00}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.3, 'MOBILE AIR', '<=', 'MOBILE AIR' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.STRUCTURE *categories.FACTORY * categories.AIR * categories.TECH3 }},
        },
        BuilderType = 'Air',
    },

    Builder {
        BuilderName = 'U1 Interceptors',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.MOBILE * categories.ENGINEER}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.LAND * categories.FACTORY * categories.TECH1 }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconStorageRatio', { 0.00, 0.00}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.3, 'MOBILE AIR', '<=', 'MOBILE AIR' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.STRUCTURE *categories.FACTORY * categories.AIR * categories.TECH3 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U1 Gunship',
        PlatoonTemplate = 'T1Gunship',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, categories.MOBILE * categories.AIR  * categories.GROUNDATTACK }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.MOBILE * categories.ENGINEER}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.LAND * categories.FACTORY * categories.TECH1 }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.00, 0.00}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.3, 'MOBILE AIR', '<=', 'MOBILE AIR' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.STRUCTURE *categories.FACTORY * categories.AIR * categories.TECH3 }},
            { UBC, 'HaveUnitRatio', { 1.0, 'MOBILE AIR GROUNDATTACK', '<','MOBILE AIR HIGHALTAIR ANTIAIR' } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U1 Bomber',
        PlatoonTemplate = 'T1AirBomber',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, categories.MOBILE * categories.AIR  * categories.BOMBER }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.MOBILE * categories.ENGINEER}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.LAND * categories.FACTORY * categories.TECH1 }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.00, 0.00}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.3, 'MOBILE AIR', '<=', 'MOBILE AIR' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.STRUCTURE *categories.FACTORY * categories.AIR * categories.TECH3 }},
            { UBC, 'HaveUnitRatio', { 1.0, 'MOBILE AIR BOMBER', '<','MOBILE AIR HIGHALTAIR ANTIAIR' } },
        },
        BuilderType = 'Air',
    },
    -- ============ --
    --    TECH 2    --
    -- ============ --
    Builder {
        BuilderName = 'U2 FighterBomber < 20',
        PlatoonTemplate = 'T2FighterBomber',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.LAND * categories.FACTORY * categories.TECH2 }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.3, 'MOBILE AIR', '<=', 'MOBILE AIR' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.STRUCTURE *categories.FACTORY * categories.AIR * categories.TECH3 }},
            { UBC, 'HaveUnitRatio', { 1.0, 'MOBILE AIR ANTIAIR BOMBER', '<','MOBILE AIR HIGHALTAIR ANTIAIR'} },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U2 Air Gunship < 20',
        PlatoonTemplate = 'T2AirGunship',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveLessThanUnitsWithCategory', { 20, categories.MOBILE * categories.AIR * categories.GROUNDATTACK * categories.TECH2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, categories.MOBILE * categories.AIR  * categories.GROUNDATTACK }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.LAND * categories.FACTORY * categories.TECH2 }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.3, 'MOBILE AIR', '<=', 'MOBILE AIR' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.STRUCTURE *categories.FACTORY * categories.AIR * categories.TECH3 }},
            { UBC, 'HaveUnitRatio', { 1.0, 'MOBILE AIR GROUNDATTACK', '<','MOBILE AIR HIGHALTAIR ANTIAIR' } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U2 TorpedoBomber PANIC',
        PlatoonTemplate = 'T2AirTorpedoBomber',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveLessThanUnitsWithCategory', { 5, categories.MOBILE * categories.AIR * categories.ANTINAVY * categories.TECH2 }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.MOBILE * categories.ENGINEER}},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.0, 'MOBILE NAVAL', '<=', 'NAVAL' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UBC, 'HaveUnitRatio', { 1.0, 'MOBILE AIR ANTINAVY', '<','MOBILE AIR HIGHALTAIR ANTIAIR' } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U2 TorpedoBomber < 20',
        PlatoonTemplate = 'T2AirTorpedoBomber',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveLessThanUnitsWithCategory', { 20, categories.MOBILE * categories.AIR * categories.ANTINAVY * categories.TECH2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, categories.MOBILE * categories.AIR  * categories.ANTINAVY }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.LAND * categories.FACTORY * categories.TECH2 }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.0, 'MOBILE NAVAL', '<=', 'NAVAL' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.STRUCTURE *categories.FACTORY * categories.AIR * categories.TECH3 }},
            { UBC, 'HaveUnitRatio', { 1.0, 'MOBILE AIR ANTINAVY', '<','MOBILE AIR HIGHALTAIR ANTIAIR' } },
        },
        BuilderType = 'Air',
    },
    -- ============ --
    --    TECH 3    --
    -- ============ --
    Builder {
        BuilderName = 'U3 Air Scouts',
        PlatoonTemplate = 'T3AirScout',
        Priority = 1000,
        BuilderConditions = {
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.INTELLIGENCE * categories.AIR * categories.TECH3 }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.INTELLIGENCE * categories.AIR } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U3 Air Fighter Enemy',
        PlatoonTemplate = 'T3AirFighter',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.0, 'MOBILE AIR HIGHALTAIR ANTIAIR', '<=', 'MOBILE AIR HIGHALTAIR ANTIAIR' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.05, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U3 Air Fighter < 60',
        PlatoonTemplate = 'T3AirFighter',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveLessThanUnitsWithCategory', { 60, categories.MOBILE * categories.AIR  * categories.HIGHALTAIR * categories.ANTIAIR * categories.TECH3 }},
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconStorageRatio', { -0.01, 0.50}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U3 Air Gunship PANIC',
        PlatoonTemplate = 'T3AirGunship',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveLessThanUnitsWithCategory', { 15, categories.MOBILE * categories.AIR * categories.GROUNDATTACK * categories.TECH3 }},
            -- Do we need additional conditions to build it ?
            { UBC, 'EnemyUnitsGreaterAtLocationRadius', {  BaseMilitaryZone, 'MAIN', 0, categories.MOBILE * categories.LAND * categories.EXPERIMENTAL}}, -- radius, LocationType, unitCount, categoryEnemy
            -- Have we the eco to build it ?
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UBC, 'HaveUnitRatio', { 1.0, 'MOBILE AIR GROUNDATTACK', '<','MOBILE AIR HIGHALTAIR ANTIAIR' } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U3 Air Gunship < 60',
        PlatoonTemplate = 'T3AirGunship',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveLessThanUnitsWithCategory', { 60, categories.MOBILE * categories.AIR * categories.GROUNDATTACK * categories.TECH3 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, categories.MOBILE * categories.AIR  * categories.GROUNDATTACK }},
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.05, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UBC, 'HaveUnitRatio', { 1.0, 'MOBILE AIR GROUNDATTACK', '<','MOBILE AIR HIGHALTAIR ANTIAIR' } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U3 Air Bomber < 60',
        PlatoonTemplate = 'T3AirBomber',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveLessThanUnitsWithCategory', { 60, categories.MOBILE * categories.AIR * categories.BOMBER }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, categories.MOBILE * categories.AIR  * categories.BOMBER }},
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.05, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UBC, 'HaveUnitRatio', { 1.0, 'MOBILE AIR BOMBER', '<','MOBILE AIR HIGHALTAIR ANTIAIR' } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U3 TorpedoBomber < 20',
        PlatoonTemplate = 'T3TorpedoBomber',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveLessThanUnitsWithCategory', { 20, categories.MOBILE * categories.AIR * categories.ANTINAVY }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, categories.MOBILE * categories.AIR  * categories.ANTINAVY }},
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.05, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UBC, 'HaveUnitRatio', { 1.0, 'MOBILE AIR ANTINAVY', '<','MOBILE AIR HIGHALTAIR ANTIAIR' } },
        },
        BuilderType = 'Air',
    },
}
-- ===================================================-======================================================== --
-- ==                                   AirTransport T1 T2 T3 Builder                                        == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'Air Transport Builder Uveso',
    BuildersType = 'FactoryBuilder',
    -- ============= --
    --    AllMaps    --
    -- ============= --
    Builder {
        BuilderName = 'U1 Air Transport 1st',
        PlatoonTemplate = 'T1AirTransport',
        Priority = 1000, 
        DelayEqualBuildPlattons = {'Transporter', 5},
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS }},
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconStorageRatio', { 0.00, 0.90}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'Transporter' }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U1 Air Transport minimum',
        PlatoonTemplate = 'T1AirTransport',
        Priority = 1000, 
        DelayEqualBuildPlattons = {'Transporter', 5},
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS * categories.TECH1 }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MOBILE * categories.AIR * categories.ANTIAIR }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconStorageRatio', { 0.00, 0.90}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'Transporter' }},
            { UBC, 'HaveUnitRatioVersusEnemy', { 0.7, 'MOBILE AIR ANTIAIR', '>','MOBILE AIR' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 4, categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS - categories.uea0203 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U2 Air Transport minimum',
        PlatoonTemplate = 'T2AirTransport',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS * categories.TECH2 }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MOBILE * categories.AIR * categories.ANTIAIR }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }},
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 0.7, 'MOBILE AIR ANTIAIR', '>','MOBILE AIR' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 4, categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS - categories.uea0203 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U3 Air Transport minimum',
        PlatoonTemplate = 'T3AirTransport',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS * categories.TECH3 }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MOBILE * categories.AIR * categories.ANTIAIR }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 3.5, 132.0 } }, -- relative income 10,60
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }},
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 0.7, 'MOBILE AIR ANTIAIR', '>','MOBILE AIR' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 4, categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS - categories.uea0203 }},
        },
        BuilderType = 'Air',
    },
    -- ============== --
    --    NoIsland    --
    -- ============== --
    Builder {
        BuilderName = 'U1 Air Transport NoIsland',
        PlatoonTemplate = 'T1AirTransport',
        Priority = 1000, 
        BuilderConditions = {
            -- When do we want to build this ?
            { MIBC, 'ArmyNeedsTransports', {} },
            -- Do we need additional conditions to build it ?
            { MIBC, 'IsIsland', { false } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MOBILE * categories.AIR * categories.ANTIAIR }},
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }},
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 0.7, 'MOBILE AIR ANTIAIR', '>','MOBILE AIR' } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'TRANSPORTFOCUS TECH1' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 6, categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS - categories.uea0203 }},
            { UCBC, 'UnitCapCheckLess', { 0.90 } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U2 Air Transport NoIsland',
        PlatoonTemplate = 'T2AirTransport',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { MIBC, 'ArmyNeedsTransports', {} },
            -- Do we need additional conditions to build it ?
            { MIBC, 'IsIsland', { false } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MOBILE * categories.AIR * categories.ANTIAIR }},
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }},
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 0.7, 'MOBILE AIR ANTIAIR', '>','MOBILE AIR' } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'TRANSPORTFOCUS TECH2' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 6, categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS - categories.uea0203 }},
            { UCBC, 'UnitCapCheckLess', { 0.90 } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U3 Air Transport NoIsland',
        PlatoonTemplate = 'T3AirTransport',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { MIBC, 'ArmyNeedsTransports', {} },
            -- Do we need additional conditions to build it ?
            { MIBC, 'IsIsland', { false } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MOBILE * categories.AIR * categories.ANTIAIR }},
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 3.5, 132.0 } }, -- relative income 10,60
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }},
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 0.7, 'MOBILE AIR ANTIAIR', '>','MOBILE AIR' } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'TRANSPORTFOCUS TECH3' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 6, categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS - categories.uea0203 }},
            { UCBC, 'UnitCapCheckLess', { 0.90 } },
        },
        BuilderType = 'Air',
    },
    -- ============== --
    --    IsIsland    --
    -- ============== --
    Builder {
        BuilderName = 'U1 Air Transport Island',
        PlatoonTemplate = 'T1AirTransport',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { MIBC, 'ArmyNeedsTransports', {} },
            -- Do we need additional conditions to build it ?
            { MIBC, 'IsIsland', { true } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MOBILE * categories.AIR * categories.ANTIAIR }},
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }},
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 0.7, 'MOBILE AIR ANTIAIR', '>','MOBILE AIR' } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'TRANSPORTFOCUS TECH1' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 12, categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS - categories.uea0203 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U2 Air Transport Island',
        PlatoonTemplate = 'T2AirTransport',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { MIBC, 'ArmyNeedsTransports', {} },
            -- Do we need additional conditions to build it ?
            { MIBC, 'IsIsland', { true } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MOBILE * categories.AIR * categories.ANTIAIR }},
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }},
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 0.7, 'MOBILE AIR ANTIAIR', '>','MOBILE AIR' } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'TRANSPORTFOCUS TECH2' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 12, categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS - categories.uea0203 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'U3 Air Transport Island',
        PlatoonTemplate = 'T3AirTransport',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { MIBC, 'ArmyNeedsTransports', {} },
            -- Do we need additional conditions to build it ?
            { MIBC, 'IsIsland', { true } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MOBILE * categories.AIR * categories.ANTIAIR }},
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 3.5, 132.0 } }, -- relative income 10,60
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }},
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 0.7, 'MOBILE AIR ANTIAIR', '>','MOBILE AIR' } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'TRANSPORTFOCUS TECH1' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 12, categories.MOBILE * categories.AIR * categories.TRANSPORTFOCUS - categories.uea0203 }},
            { UCBC, 'UnitCapCheckLess', { 0.90 } },
        },
        BuilderType = 'Air',
    },
}
-- ===================================================-======================================================== --
-- ==                                          Air Formbuilder                                               == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'Air FormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    -- =============== --
    --    PanicZone    --
    -- =============== --
    Builder {
        BuilderName = 'U123 PANIC AntiGround',
        PlatoonTemplate = 'U123-AntiGroundPanic 1 500',
        PlatoonAddBehaviors = { 'AirUnitRefit' },               -- Adds a ForkThread() to this platton. See: "AIBehaviors.lua"
        Priority = 2000,                                        -- Priority. 1000 is normal.
        InstanceCount = 4,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = BasePanicZone,                       -- Searchradius for new target.
            UseMoveOrder = false,                               -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = false,                              -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE',                    -- Only find targets matching these categories.
            PrioritizedCategories = {
                'MOBILE LAND ANTIAIR',
                'MOBILE LAND INDIRECTFIRE',
                'MOBILE LAND DIRECTFIRE',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UBC, 'EnemyUnitsGreaterAtLocationRadius', {  BasePanicZone, 'LocationType', 0, categories.MOBILE * categories.LAND }}, -- radius, LocationType, unitCount, categoryEnemy
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U123 PANIC AntiAir',
        PlatoonTemplate = 'U123-AntiAirPanic 1 500',
        PlatoonAddBehaviors = { 'AirUnitRefit' },               -- Adds a ForkThread() to this platton. See: "AIBehaviors.lua"
        Priority = 2000,                                        -- Priority. 1000 is normal.
        InstanceCount = 4,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = BasePanicZone,                       -- Searchradius for new target.
            UseMoveOrder = false,                               -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = false,                              -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE',                    -- Only find targets matching these categories.
            PrioritizedCategories = {
                'MOBILE AIR BOMBER',
                'MOBILE AIR ANTIAIR',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UBC, 'EnemyUnitsGreaterAtLocationRadius', {  BasePanicZone, 'LocationType', 0, categories.MOBILE * categories.AIR }}, -- radius, LocationType, unitCount, categoryEnemy
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    -- ================== --
    --    MilitaryZone    --
    -- ================== --
    Builder {
        BuilderName = 'U123 Military AntiAir',
        PlatoonTemplate = 'U123-AntiAirPanic 1 500',
        PlatoonAddBehaviors = { 'AirUnitRefit' },               -- Adds a ForkThread() to this platton. See: "AIBehaviors.lua"
        Priority = 1900,                                        -- Priority. 1000 is normal.
        InstanceCount = 2,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = BaseMilitaryZone,                    -- Searchradius for new target.
            UseMoveOrder = false,                               -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = false,                              -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE AIR',                -- Only find targets matching these categories.
            PrioritizedCategories = {
                'MOBILE AIR BOMBER',
                'MOBILE AIR ANTIAIR HIGHALTAIR',
                'MOBILE AIR ANTIAIR',
                'MOBILE AIR TRANSPORTFOCUS',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UBC, 'EnemyUnitsGreaterAtLocationRadius', {  BaseMilitaryZone, 'LocationType', 0, categories.MOBILE * categories.AIR }}, -- radius, LocationType, unitCount, categoryEnemy
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U123 Military AntiTransport',
        PlatoonTemplate = 'U123-AntiAirPanic 1 500',
        PlatoonAddBehaviors = { 'AirUnitRefit' },               -- Adds a ForkThread() to this platton. See: "AIBehaviors.lua"
        Priority = 1900,                                        -- Priority. 1000 is normal.
        InstanceCount = 2,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = BaseMilitaryZone,                    -- Searchradius for new target.
            UseMoveOrder = false,                               -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = false,                              -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE AIR',                -- Only find targets matching these categories.
            PrioritizedCategories = {
                'MOBILE AIR TRANSPORTFOCUS',
                'MOBILE AIR BOMBER',
                'MOBILE AIR ANTIAIR',
                'MOBILE AIR ANTIAIR HIGHALTAIR',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UBC, 'EnemyUnitsGreaterAtLocationRadius', {  BaseMilitaryZone, 'LocationType', 0, categories.MOBILE * categories.AIR }}, -- radius, LocationType, unitCount, categoryEnemy
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U123 Military AntiGround',
        PlatoonTemplate = 'U123-AntiGroundPanic 1 500',
        PlatoonAddBehaviors = { 'AirUnitRefit' },               -- Adds a ForkThread() to this platton. See: "AIBehaviors.lua"
        Priority = 1900,                                        -- Priority. 1000 is normal.
        InstanceCount = 2,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = BaseMilitaryZone,                     -- Searchradius for new target.
            UseMoveOrder = false,                               -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = false,                              -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE',                    -- Only find targets matching these categories.
            PrioritizedCategories = {
                'MOBILE LAND ANTIAIR',
                'MOBILE LAND INDIRECTFIRE',
                'MOBILE LAND DIRECTFIRE',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UBC, 'EnemyUnitsGreaterAtLocationRadius', {  BaseMilitaryZone, 'LocationType', 0, categories.MOBILE * categories.LAND }}, -- radius, LocationType, unitCount, categoryEnemy
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U123 Military AntiNaval',
        PlatoonTemplate = 'U123-TorpedoBomber 1 100',
        PlatoonAddBehaviors = { 'AirUnitRefit' },               -- Adds a ForkThread() to this platton. See: "AIBehaviors.lua"
        Priority = 1900,                                        -- Priority. 1000 is normal.
        InstanceCount = 2,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = BaseMilitaryZone,                    -- Searchradius for new target.
            UseMoveOrder = false,                               -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = 3,                                  -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'NAVAL',                     -- Only find targets matching these categories.
            PrioritizedCategories = {
                'NAVAL ANTIAIR',
                'MOBILE NAVAL',
                'STRUCTURE NAVAL',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UBC, 'EnemyUnitsGreaterAtLocationRadius', {  BaseMilitaryZone, 'LocationType', 0, categories.MOBILE * categories.NAVAL }}, -- radius, LocationType, unitCount, categoryEnemy
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    -- =============== --
    --    EnemyZone    --
    -- =============== --
    Builder {
        BuilderName = 'U123 AntiAir Intercept',                 -- Random Builder Name.
        PlatoonTemplate = 'U123-EnemyAntiAirInterceptor 10 20', -- Template Name. These units will be formed. See: "UvesoPlatoonTemplatesAir.lua"
        PlatoonAddBehaviors = { 'AirUnitRefit' },               -- Adds a ForkThread() to this platton. See: "AIBehaviors.lua"
        Priority = 1900,                                        -- Priority. 1000 is normal.
        InstanceCount = 15,                                     -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius from main base for new target. (A 5x5 Map is 256 high)
            IgnoreAntiAir = false,                              -- Don't attack if we have more then x anti air buildings at target position.
            UseMoveOrder = false,                               -- if true, the unit will first move to the targetposition and then attack it.
            TargetSearchCategory = 'MOBILE AIR',                -- Only find targets matching these categories.
            PrioritizedCategories = {
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 60, categories.MOBILE * categories.AIR * categories.ANTIAIR * categories.HIGHALTAIR - categories.EXPERIMENTAL - categories.ANTINAVY}},
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U123 AntiGround Bomber',                 -- Random Builder Name.
        PlatoonTemplate = 'U123-EnemyAntiGround Bomber 10 20',  -- Template Name. These units will be formed. See: "UvesoPlatoonTemplatesAir.lua"
        PlatoonAddBehaviors = { 'AirUnitRefit' },               -- Adds a ForkThread() to this platton. See: "AIBehaviors.lua"
        Priority = 1900,                                        -- Priority. 1000 is normal.
        InstanceCount = 1,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius for new target.
            UseMoveOrder = false,                               -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = 1,                                  -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'STRUCTURE, MASSEXTRACTION', -- Only find targets matching these categories.
            PrioritizedCategories = {
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 20, categories.MOBILE * categories.AIR * categories.BOMBER - categories.EXPERIMENTAL - categories.ANTINAVY}},
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U123 AntiGround Gunship',                -- Random Builder Name.
        PlatoonTemplate = 'U123-EnemyAntiGround Gunship 10 20', -- Template Name. These units will be formed. See: "UvesoPlatoonTemplatesAir.lua"
        PlatoonAddBehaviors = { 'AirUnitRefit' },               -- Adds a ForkThread() to this platton. See: "AIBehaviors.lua"
        Priority = 1900,                                        -- Priority. 1000 is normal.
        InstanceCount = 1,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius for new target.
            UseMoveOrder = false,                               -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = 1,                                  -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE, STRUCTURE',         -- Only find targets matching these categories.
            PrioritizedCategories = {
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 25, categories.MOBILE * categories.AIR * categories.GROUNDATTACK - categories.EXPERIMENTAL - categories.ANTINAVY}},
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    -- ============= --
    --    Special    --
    -- ============= --

    Builder {
        BuilderName = 'U123 AntiTransport Intercept',           -- Random Builder Name.
        PlatoonTemplate = 'U123-TransportInterceptor 1 12',     -- Template Name. These units will be formed. See: "UvesoPlatoonTemplatesAir.lua"
        PlatoonAddBehaviors = { 'AirUnitRefit' },               -- Adds a ForkThread() to this platton. See: "AIBehaviors.lua"
        Priority = 1800,                                        -- Priority. 1000 is normal.
        InstanceCount = 1,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = BaseMilitaryZone,                    -- Searchradius for new target.
            UseMoveOrder = false,                               -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = 2,                                  -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE AIR',                -- Only find targets matching these categories.
            PrioritizedCategories = {
                'AIR TRANSPORTFOCUS',                           -- Only attack transporter. (Then return to base and disband.)
                'MOBILE',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- true, if the enemy has more then 0 (at least 1) transporter.
            { UBC, 'UnitsGreaterAtEnemy', { 0 , 'MOBILE AIR TRANSPORTFOCUS' } }, 
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    -- ====================== --
    --    AntiExperimental    --
    -- ====================== --
    Builder {
        BuilderName = 'U123 AntiExperimental Interceptor Grow',
        PlatoonTemplate = 'U123-ExperimentalAttackInterceptorGrow 3 100',
        PlatoonAddBehaviors = { 'AirUnitRefit' },               -- Adds a ForkThread() to this platton. See: "AIBehaviors.lua"
        Priority = 2000,                                         -- Priority. 1000 is normal.
        InstanceCount = 4,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = BaseMilitaryZone,                                 -- Searchradius for new target.
            UseMoveOrder = false,                                -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = 3,                         -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE AIR',                -- Only find targets matching these categories.
            PrioritizedCategories = {
                'MOBILE AIR EXPERIMENTAL',
                'MOBILE',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UBC, 'UnitsGreaterAtEnemy', { 0 , 'MOBILE AIR EXPERIMENTAL' } },
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U123 AntiExperimental Bomber Grow',
        PlatoonTemplate = 'U123-ExperimentalAttackBomberGrow 3 100',
        PlatoonAddBehaviors = { 'AirUnitRefit' },               -- Adds a ForkThread() to this platton. See: "AIBehaviors.lua"
        Priority = 2000,                                         -- Priority. 1000 is normal.
        InstanceCount = 4,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = BaseMilitaryZone,                                 -- Searchradius for new target.
            UseMoveOrder = false,                                -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = 3,                         -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE LAND, STRUCTURE',                -- Only find targets matching these categories.
            PrioritizedCategories = {
                'MOBILE LAND EXPERIMENTAL',
                'MOBILE',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UBC, 'UnitsGreaterAtEnemy', { 0 , 'MOBILE LAND EXPERIMENTAL, STRUCTURE EXPERIMENTAL' } },
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U123 AntiExperimental Gunship Grow',
        PlatoonTemplate = 'U123-ExperimentalAttackGunshipGrow 3 100',
        PlatoonAddBehaviors = { 'AirUnitRefit' },               -- Adds a ForkThread() to this platton. See: "AIBehaviors.lua"
        Priority = 2000,                                         -- Priority. 1000 is normal.
        InstanceCount = 4,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = BaseMilitaryZone,                                 -- Searchradius for new target.
            UseMoveOrder = false,                                -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = 3,                         -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE, STRUCTURE',         -- Only find targets matching these categories.
            PrioritizedCategories = {
                'MOBILE AIR EXPERIMENTAL',
                'MOBILE LAND EXPERIMENTAL',
                'STRUCTURE',
                'MOBILE',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UBC, 'UnitsGreaterAtEnemy', { 0 , 'EXPERIMENTAL' } },
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    -- ============= --
    --    UnitCap    --
    -- ============= --
    Builder {
        BuilderName = 'U12 UnitCap AntiAir',
        PlatoonTemplate = 'U12-AntiAirCap 1 500',
        Priority = 1550,                                         -- Priority. 1000 is normal.
        InstanceCount = 4,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = 10000,                                 -- Searchradius for new target.
            UseMoveOrder = false,                                -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = false,                         -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE AIR',              -- Only find targets matching these categories.
            PrioritizedCategories = {
                'TECH1',
                'TECH2',
                'TECH3',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UCBC, 'UnitCapCheckGreater', { .90 } },
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U12 UnitCap AntiGround',
        PlatoonTemplate = 'U12-AntiGroundCap 1 500',
        Priority = 1550,                                        -- Priority. 1000 is normal.
        InstanceCount = 20,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius for new target.
            UseMoveOrder = false,                                -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = false,                              -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE LAND, STRUCTURE',    -- Only find targets matching these categories.
            PrioritizedCategories = {
                'EXPERIMENTAL',
                'STRUCTURE NUKE',
                'STRUCTURE SHIELD',
                'STRUCTURE ENERGYPRODUCTION',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UCBC, 'UnitCapCheckGreater', { .90 } },
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    -- ===================== --
    --    ExperimentalCap    --
    -- ===================== --
    Builder {
        BuilderName = 'U12 ExperimentalCap AntiAir',
        PlatoonTemplate = 'U12-AntiAirCap 1 500',
        Priority = 1550,                                         -- Priority. 1000 is normal.
        InstanceCount = 4,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = 10000,                                 -- Searchradius for new target.
            UseMoveOrder = false,                                -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = false,                         -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE AIR',              -- Only find targets matching these categories.
            PrioritizedCategories = {
                'TECH1',
                'TECH2',
                'TECH3',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { ExperimentalCount, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U12 ExperimentalCap AntiGround',
        PlatoonTemplate = 'U12-AntiGroundCap 1 500',
        Priority = 1550,                                        -- Priority. 1000 is normal.
        InstanceCount = 20,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius for new target.
            UseMoveOrder = false,                                -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = false,                              -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE LAND, STRUCTURE',    -- Only find targets matching these categories.
            PrioritizedCategories = {
                'EXPERIMENTAL',
                'STRUCTURE NUKE',
                'STRUCTURE SHIELD',
                'STRUCTURE ENERGYPRODUCTION',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { ExperimentalCount, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    -- ================= --
    --    Finish him!    --
    -- ================= --
    Builder {
        BuilderName = 'U123 Air Kill Them All!!!',
        PlatoonTemplate = 'U123-AntiAirPanic 1 500',
        PlatoonAddBehaviors = { 'AirUnitRefit' },               -- Adds a ForkThread() to this platton. See: "AIBehaviors.lua"
        Priority = 1100,                                        -- Priority. 1000 is normal.
        InstanceCount = 3,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = BaseMilitaryZone,                    -- Searchradius for new target.
            UseMoveOrder = false,                               -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = false,                              -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE AIR',              -- Only find targets matching these categories.
            PrioritizedCategories = {
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.5, 'MOBILE AIR', '>', 'MOBILE AIR' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U123 Ground Kill Them All!!!',
        PlatoonTemplate = 'U123-AntiGroundPanic 1 500',
        PlatoonAddBehaviors = { 'AirUnitRefit' },               -- Adds a ForkThread() to this platton. See: "AIBehaviors.lua"
        Priority = 1100,                                        -- Priority. 1000 is normal.
        InstanceCount = 3,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = BaseMilitaryZone,                     -- Searchradius for new target.
            UseMoveOrder = false,                               -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = false,                              -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE LAND, STRUCTURE',    -- Only find targets matching these categories.
            PrioritizedCategories = {
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.5, 'MOBILE, STRUCTURE', '>', 'MOBILE, STRUCTURE' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U123 Torpedo Kill Them All!!!',
        PlatoonTemplate = 'U123-TorpedoBomber 1 100',
        PlatoonAddBehaviors = { 'AirUnitRefit' },               -- Adds a ForkThread() to this platton. See: "AIBehaviors.lua"
        Priority = 1100,                                        -- Priority. 1000 is normal.
        InstanceCount = 3,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = BaseMilitaryZone,                    -- Searchradius for new target.
            UseMoveOrder = false,                               -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = false,                                  -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE, STRUCTURE',    -- Only find targets matching these categories.
            PrioritizedCategories = {
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.5, 'MOBILE, STRUCTURE', '>', 'MOBILE, STRUCTURE' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
}


