local UBC = '/lua/editor/UvesoBuildConditions.lua'
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local EBC = '/lua/editor/EconomyBuildConditions.lua'
local IBC = '/lua/editor/InstantBuildConditions.lua'
local MIBC = '/lua/editor/MiscBuildConditions.lua'

local ExperimentalCount = 3
local mapSizeX, mapSizeZ = GetMapSize()
local BaseMilitaryZone = math.max( mapSizeX-50, mapSizeZ-50 ) / 2 -- Half the map
local BasePanicZone = BaseMilitaryZone / 2
BasePanicZone = math.max( 40, BasePanicZone )
BasePanicZone = math.min( 120, BasePanicZone )
LOG('* AI DEBUG: BasePanicZone= '..math.floor( BasePanicZone * 0.01953125 ) ..' Km - ('..BasePanicZone..' units)' )
LOG('* AI DEBUG: BaseMilitaryZone= '..math.floor( BaseMilitaryZone * 0.01953125 )..' Km - ('..BaseMilitaryZone..' units)' )

-- ===================================================-======================================================== --
-- ==                                        Build T1 T2 T3 Land                                             == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'LandAttackBuilders Uveso',
    BuildersType = 'FactoryBuilder',
    -- ============ --
    --    TECH 1    --
    -- ============ --
    -- Panic builder, in case the enemy is in front of our base 
    Builder {
        BuilderName = 'U1 ANTICDR PANIC',
        PlatoonTemplate = 'T1LandArtillery',
        Priority = 1100,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'EnemyUnitsGreaterAtLocationRadius', {  100, 'LocationType', 0, categories.COMMAND }}, -- radius, LocationType, unitCount, categoryEnemy
            -- Do we need additional conditions to build it ?
            { UBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'U1 Arty PANIC',
        PlatoonTemplate = 'T1LandArtillery',
        Priority = 1100,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'EnemyUnitsGreaterAtLocationRadius', {  BasePanicZone, 'LocationType', 0, categories.MOBILE * categories.LAND }}, -- radius, LocationType, unitCount, categoryEnemy
            -- Do we need additional conditions to build it ?
            { UBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'U1 T1LandAA PANIC',
        PlatoonTemplate = 'T1LandAA',
        Priority = 1100,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'EnemyUnitsGreaterAtLocationRadius', {  20, 'LocationType', 0, categories.MOBILE * categories.AIR - categories.SCOUT}}, -- radius, LocationType, unitCount, categoryEnemy
            -- Do we need additional conditions to build it ?
            { UBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            { UBC, 'HaveUnitRatio', { 1.0, 'MOBILE LAND ANTIAIR', '<','MOBILE LAND DIRECTFIRE, MOBILE LAND INDIRECTFIRE' } },
            -- Have we the eco to build it ?
            -- Don't build it if...
            --{ UCBC, 'HaveLessThanUnitsWithCategory', { 5, categories.MOBILE * categories.ANTIAIR }},
        },
        BuilderType = 'Land',
    },
    -- Default T1 builder will not respect eco and build as long as we have less units then the enemy
    Builder {
        BuilderName = 'U1 Bot',
        PlatoonTemplate = 'T1LandDFBot',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.LAND * categories.FACTORY * categories.TECH1 }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'LAND MOBILE DIRECTFIRE, LAND MOBILE INDIRECTFIRE', '<=', 'LAND MOBILE' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { ExperimentalCount, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
            { UCBC, 'UnitCapCheckLess', { .80 } },
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'U1 Tank',
        PlatoonTemplate = 'T1LandDFTank',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.LAND * categories.FACTORY * categories.TECH1 }},
            -- Have we the eco to build it ?
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'LAND MOBILE DIRECTFIRE, LAND MOBILE INDIRECTFIRE', '<=', 'LAND MOBILE' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { ExperimentalCount, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
            { UCBC, 'UnitCapCheckLess', { .80 } },
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'U1 Arty',
        PlatoonTemplate = 'T1LandArtillery',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.LAND * categories.FACTORY * categories.TECH1 }},
            -- Have we the eco to build it ?
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'LAND MOBILE DIRECTFIRE, LAND MOBILE INDIRECTFIRE', '<=', 'LAND MOBILE' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { ExperimentalCount, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
            { UCBC, 'UnitCapCheckLess', { .80 } },
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'U1 Mobile AA emergency',
        PlatoonTemplate = 'T1LandAA',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.0, 'MOBILE ANTIAIR', '<=', 'MOBILE AIR' } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.LAND * categories.FACTORY * categories.TECH1 }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'LAND MOBILE DIRECTFIRE, LAND MOBILE INDIRECTFIRE', '<=', 'LAND MOBILE' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { ExperimentalCount, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
            { UCBC, 'UnitCapCheckLess', { .80 } },
        },
        BuilderType = 'Land',
    },
    -- ============ --
    --    TECH 2    --
    -- ============ --
    Builder {
        BuilderName = 'U2 DFTank',
        PlatoonTemplate = 'T2LandDFTank',
        Priority = 1000,
        BuilderType = 'Land',
        BuilderConditions = {
            -- When do we want to build this ?
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.MOBILE * categories.ENGINEER * categories.TECH2 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.LAND * categories.FACTORY * categories.TECH2 }},
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.MOBILE * categories.LAND  * (categories.DIRECTFIRE + categories.INDIRECTFIRE) * categories.TECH2 }},
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'LAND MOBILE DIRECTFIRE, LAND MOBILE INDIRECTFIRE', '<=', 'LAND MOBILE' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { ExperimentalCount, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
            { UCBC, 'UnitCapCheckLess', { .80 } },
        },
    },
    Builder {
        BuilderName = 'U2 AttackTank',
        PlatoonTemplate = 'T2AttackTank',
        Priority = 1000,
        BuilderType = 'Land',
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.2, 'LAND MOBILE DIRECTFIRE', '<=', 'LAND MOBILE' } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.MOBILE * categories.ENGINEER * categories.TECH2 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.LAND * categories.FACTORY * categories.TECH2 }},
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.LAND  * (categories.DIRECTFIRE + categories.INDIRECTFIRE) * categories.TECH2 }},
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'LAND MOBILE DIRECTFIRE, LAND MOBILE INDIRECTFIRE', '<=', 'LAND MOBILE' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { ExperimentalCount, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
            { UCBC, 'UnitCapCheckLess', { .80 } },
        },
    },
    Builder {
        BuilderName = 'U2 Amphibious',
        PlatoonTemplate = 'T2LandAmphibious',
        Priority = 1000,
        BuilderType = 'Land',
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.2, 'LAND MOBILE DIRECTFIRE', '<=', 'LAND MOBILE' } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.MOBILE * categories.ENGINEER * categories.TECH2 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.LAND * categories.FACTORY * categories.TECH2 }},
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 4, categories.MOBILE * categories.LAND  * (categories.DIRECTFIRE + categories.INDIRECTFIRE) * categories.TECH2 }},
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'LAND MOBILE DIRECTFIRE, LAND MOBILE INDIRECTFIRE', '<=', 'LAND MOBILE' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { ExperimentalCount, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
            { UCBC, 'UnitCapCheckLess', { .80 } },
        },
    },
    Builder {
        BuilderName = 'U2 Artillery',
        PlatoonTemplate = 'T2LandArtillery',
        Priority = 1000,
        BuilderType = 'Land',
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.2, 'LAND MOBILE INDIRECTFIRE', '<=', 'LAND MOBILE' } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.MOBILE * categories.ENGINEER * categories.TECH2 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.LAND * categories.FACTORY * categories.TECH2 }},
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 5, categories.MOBILE * categories.LAND  * (categories.DIRECTFIRE + categories.INDIRECTFIRE) * categories.TECH2 }},
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'LAND MOBILE DIRECTFIRE, LAND MOBILE INDIRECTFIRE', '<=', 'LAND MOBILE' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { ExperimentalCount, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
            { UCBC, 'UnitCapCheckLess', { .80 } },
        },
    },
    Builder {
        BuilderName = 'U2 Mobile AA',
        PlatoonTemplate = 'T2LandAA',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.2, 'LAND MOBILE DIRECTFIRE', '<=', 'LAND MOBILE' } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.MOBILE * categories.ENGINEER * categories.TECH2 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.LAND * categories.FACTORY * categories.TECH2 }},
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 6, categories.MOBILE * categories.LAND  * (categories.DIRECTFIRE + categories.INDIRECTFIRE) * categories.TECH2 }},
            { UBC, 'HaveUnitRatioVersusEnemy', { 0.1, 'LAND MOBILE DIRECTFIRE, LAND MOBILE INDIRECTFIRE', '<=', 'LAND MOBILE' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { ExperimentalCount, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
            { UCBC, 'UnitCapCheckLess', { .80 } },
        },
        BuilderType = 'Land',
    },
    -- ============ --
    --    TECH 3    --
    -- ============ --
    Builder {
        BuilderName = 'U3 Siege Assault Bot',
        PlatoonTemplate = 'T3LandBot',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.2, 'LAND MOBILE DIRECTFIRE', '<=', 'LAND MOBILE' } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.FACTORY * categories.LAND * categories.TECH3 }},
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, categories.MOBILE * categories.LAND  * (categories.DIRECTFIRE + categories.INDIRECTFIRE) * categories.TECH3 }},
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'LAND MOBILE DIRECTFIRE, LAND MOBILE INDIRECTFIRE', '<=', 'LAND MOBILE' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { ExperimentalCount, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'U3 Mobile Artillery',
        PlatoonTemplate = 'T3LandArtillery',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.2, 'LAND MOBILE DIRECTFIRE', '<=', 'LAND MOBILE' } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.FACTORY * categories.LAND * categories.TECH3 }},
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.MOBILE * categories.LAND  * (categories.DIRECTFIRE + categories.INDIRECTFIRE) * categories.TECH3 }},
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'LAND MOBILE DIRECTFIRE, LAND MOBILE INDIRECTFIRE', '<=', 'LAND MOBILE' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { ExperimentalCount, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'U3 SniperBots',
        PlatoonTemplate = 'T3SniperBots',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.2, 'LAND MOBILE DIRECTFIRE', '<=', 'LAND MOBILE' } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.FACTORY * categories.LAND * categories.TECH3 }},
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 5, categories.MOBILE * categories.LAND  * (categories.DIRECTFIRE + categories.INDIRECTFIRE) * categories.TECH3 }},
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'LAND MOBILE DIRECTFIRE, LAND MOBILE INDIRECTFIRE', '<=', 'LAND MOBILE' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { ExperimentalCount, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'U3 ArmoredAssault',
        PlatoonTemplate = 'T3ArmoredAssault',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.2, 'LAND MOBILE DIRECTFIRE', '<=', 'LAND MOBILE' } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.FACTORY * categories.LAND * categories.TECH3 }},
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 5, categories.MOBILE * categories.LAND  * (categories.DIRECTFIRE + categories.INDIRECTFIRE) * categories.TECH3 }},
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'LAND MOBILE DIRECTFIRE, LAND MOBILE INDIRECTFIRE', '<=', 'LAND MOBILE' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { ExperimentalCount, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'U3 Mobile AA',
        PlatoonTemplate = 'T3LandAA',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.2, 'LAND MOBILE DIRECTFIRE', '<=', 'LAND MOBILE' } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.FACTORY * categories.LAND * categories.TECH3 }},
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 7, categories.MOBILE * categories.LAND  * (categories.DIRECTFIRE + categories.INDIRECTFIRE) * categories.TECH3 }},
            { UBC, 'HaveUnitRatioVersusEnemy', { 0.1, 'LAND MOBILE DIRECTFIRE, LAND MOBILE INDIRECTFIRE', '<=', 'LAND MOBILE' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { ExperimentalCount, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'U3 MobileShields',
        PlatoonTemplate = 'T3MobileShields',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.2, 'LAND MOBILE DIRECTFIRE', '<=', 'LAND MOBILE' } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.FACTORY * categories.LAND * categories.TECH3 }},
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 7, categories.MOBILE * categories.LAND  * (categories.DIRECTFIRE + categories.INDIRECTFIRE) * categories.TECH3 }},
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'LAND MOBILE DIRECTFIRE, LAND MOBILE INDIRECTFIRE', '<=', 'LAND MOBILE' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { ExperimentalCount, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Land',
    },
}
-- ===================================================-======================================================== --
-- ==                                         Land Formbuilder                                               == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'Land FormBuilders',                     -- BuilderGroupName, initalized from AIBaseTemplates in "\lua\AI\AIBaseTemplates"
    BuildersType = 'PlatoonFormBuilder',                        -- BuilderTypes are: EngineerBuilder, FactoryBuilder, PlatoonFormBuilder.
    Builder {
        BuilderName = 'U123 AntiCDR PANIC',                     -- Random Builder Name.
        PlatoonTemplate = 'LandAttackHuntUveso 2 10',           -- Template Name. These units will be formed. See: "UvesoPlatoonTemplatesLand.lua"
        Priority = 1100,                                        -- Priority. 1000 is normal.
        InstanceCount = 12,                                     -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = 100,                                 -- Searchradius for new target.
            RequireTransport = true,                            -- If this is true, the unit is forced to use a transport, even if it has a valid path to the destination.
            AggressiveMove = false,                             -- If true, the unit will attack everything while moving to the target.
            IgnoreGroundDefense = false,                        -- Don't attack if we have more then x ground defense buildings at target position. false = no check
            TargetSearchCategory = 'COMMAND',                   -- Only find targets matching these categories.
            PrioritizedCategories = {                           -- Attack these targets.
                'COMMAND',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            { UBC, 'EnemyUnitsGreaterAtLocationRadius', {  100, 'LocationType', 0, categories.COMMAND }}, -- radius, LocationType, unitCount, categoryEnemy
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U123 AntiMass SingleHunt',               -- Random Builder Name.
        PlatoonTemplate = 'U123 SingleAttack',                  -- Template Name. These units will be formed. See: "UvesoPlatoonTemplatesLand.lua"
        Priority = 1000,                                        -- Priority. 1000 is normal.
        InstanceCount = 2,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius for new target.
            RequireTransport = true,                            -- If this is true, the unit is forced to use a transport, even if it has a valid path to the destination.
            AggressiveMove = false,                             -- If true, the unit will attack everything while moving to the target.
            IgnoreGroundDefense = false,                        -- Don't attack if we have more then x ground defense buildings at target position. false = no check
            TargetSearchCategory = 'MASSEXTRACTION',            -- Only find targets matching these categories.
            PrioritizedCategories = {                           -- Attack these targets.
                'MASSEXTRACTION TECH1',
                'MASSEXTRACTION TECH2',
                'MASSEXTRACTION TECH3',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UBC, 'GreaterThanGameTimeSeconds', { 600 } },
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U123 Spam +2',                           -- Random Builder Name.
        PlatoonTemplate = 'LandAttackHuntUveso 2 10',           -- Template Name. These units will be formed. See: "UvesoPlatoonTemplatesLand.lua"
        Priority = 1000,                                        -- Priority. 1000 is normal.
        InstanceCount = 4,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius for new target.
            RequireTransport = false,                           -- If this is true, the unit is forced to use a transport, even if it has a valid path to the destination.
            AggressiveMove = true,                              -- If true, the unit will attack everything while moving to the target.
            IgnoreGroundDefense = false,                            -- Don't attack if we have more then x ground defense buildings at target position. false = no check
            TargetSearchCategory = 'MOBILE LAND, STRUCTURE',    -- Only find targets matching these categories.
            PrioritizedCategories = {                           -- Attack these targets.
                'ALLUNITS -SCOUT',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UCBC, 'HaveLessThanUnitsWithCategory', { 10, categories.MOBILE * categories.LAND * categories.TECH3 * ( categories.DIRECTFIRE + categories.INDIRECTFIRE ) }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 5, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U123 Spam +5',                           -- Random Builder Name.
        PlatoonTemplate = 'LandAttackHuntUveso 5 30',           -- Template Name. These units will be formed. See: "UvesoPlatoonTemplatesLand.lua"
        Priority = 1000,                                        -- Priority. 1000 is normal.
        InstanceCount = 8,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius for new target.
            RequireTransport = false,                           -- If this is true, the unit is forced to use a transport, even if it has a valid path to the destination.
            AggressiveMove = true,                              -- If true, the unit will attack everything while moving to the target.
            IgnoreGroundDefense = false,                            -- Don't attack if we have more then x ground defense buildings at target position. false = no check
            TargetSearchCategory = 'MOBILE LAND, STRUCTURE',    -- Only find targets matching these categories.
            PrioritizedCategories = {                           -- Attack these targets.
                'ALLUNITS -SCOUT',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UCBC, 'HaveLessThanUnitsWithCategory', { 10, categories.MOBILE * categories.LAND * categories.TECH3 * ( categories.DIRECTFIRE + categories.INDIRECTFIRE ) }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 5, categories.MOBILE *categories.LAND * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U123 Spam +10',                          -- Random Builder Name.
        PlatoonTemplate = 'LandAttackHuntUveso 10 40',          -- Template Name. These units will be formed. See: "UvesoPlatoonTemplatesLand.lua"
        Priority = 1000,                                        -- Priority. 1000 is normal.
        InstanceCount = 20,                                     -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius for new target.
            RequireTransport = false,                           -- If this is true, the unit is forced to use a transport, even if it has a valid path to the destination.
            AggressiveMove = true,                              -- If true, the unit will attack everything while moving to the target.
            IgnoreGroundDefense = false,                        -- Don't attack if we have more then x ground defense buildings at target position. false = no check
            TargetSearchCategory = 'MOBILE LAND, STRUCTURE',    -- Only find targets matching these categories.
            PrioritizedCategories = {                           -- Attack these targets.
                'EXPERIMENTAL',
                'ALLUNITS -SCOUT',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- build always
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    -- ============= --
    --    UnitCap    --
    -- ============= --
    Builder {
        BuilderName = 'U123 UnitCap Ground',
        PlatoonTemplate = 'U12-LandCap 1 500',                  -- Template Name. These units will be formed. See: "UvesoPlatoonTemplatesLand.lua"
        Priority = 1050,                                        -- Priority. 1000 is normal.
        InstanceCount = 20,                                     -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius for new target.
            RequireTransport = false,                           -- If this is true, the unit is forced to use a transport, even if it has a valid path to the destination.
            AggressiveMove = true,                              -- If true, the unit will attack everything while moving to the target.
            IgnoreGroundDefense = false,                        -- Don't attack if we have more then x ground defense buildings at target position. false = no check
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
        BuilderName = 'U123 ExperimentalCap Ground',
        PlatoonTemplate = 'U12-LandCap 1 500',                  -- Template Name. These units will be formed. See: "UvesoPlatoonTemplatesLand.lua"
        Priority = 1050,                                        -- Priority. 1000 is normal.
        InstanceCount = 20,                                     -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius for new target.
            RequireTransport = false,                           -- If this is true, the unit is forced to use a transport, even if it has a valid path to the destination.
            AggressiveMove = true,                              -- If true, the unit will attack everything while moving to the target.
            IgnoreGroundDefense = false,                        -- Don't attack if we have more then x ground defense buildings at target position. false = no check
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
        BuilderName = 'U123 Land Kill Them All!!!',
        PlatoonTemplate = 'LandAttackHuntUveso 5 30',                  -- Template Name. These units will be formed. See: "UvesoPlatoonTemplatesLand.lua"
        Priority = 1100,                                        -- Priority. 1000 is normal.
        InstanceCount = 20,                                     -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius for new target.
            RequireTransport = false,                           -- If this is true, the unit is forced to use a transport, even if it has a valid path to the destination.
            AggressiveMove = true,                              -- If true, the unit will attack everything while moving to the target.
            IgnoreGroundDefense = false,                        -- Don't attack if we have more then x ground defense buildings at target position. false = no check
            TargetSearchCategory = 'MOBILE LAND, STRUCTURE',    -- Only find targets matching these categories.
            PrioritizedCategories = {
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.5, 'MOBILE -ENGINEER', '>', 'MOBILE -ENGINEER' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
}
