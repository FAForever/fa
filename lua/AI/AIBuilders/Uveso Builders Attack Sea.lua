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

-- ===================================================-======================================================== --
-- ==                                        Build T1 T2 T3 Land                                             == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'SeaFactoryBuilders Uveso',
    BuildersType = 'FactoryBuilder',
    -- ============ --
    --    TECH 1    --
    -- ============ --
    -- Panic builder, in case the enemy is in front of our base 
    Builder {
        BuilderName = 'U1 Sub PANIC',
        PlatoonTemplate = 'T1SeaSub',
        Priority = 1100,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'EnemyUnitsGreaterAtLocationRadius', {  BasePanicZone, 'LocationType', 0, categories.MOBILE * categories.NAVAL }}, -- radius, LocationType, unitCount, categoryEnemy
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Sea',
    },
    -- Default T1 builder will not respect eco and build as long as we have less units then the enemy
    Builder {
        BuilderName = 'U1 Sub',
        PlatoonTemplate = 'T1SeaSub',
        Priority = 999,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 10, 'MOBILE NAVAL' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 50, categories.MOBILE *categories.NAVAL }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.NAVAL * categories.FACTORY * categories.TECH1 }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'UnitCapCheckLess', { .80 } },
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'U1 Sea Frigate ratio Sub',
        PlatoonTemplate = 'T1SeaFrigate',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatio', { 1.0, 'NAVAL MOBILE ANTIAIR', '<','NAVAL MOBILE SUBMERSIBLE' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.MOBILE * categories.NAVAL * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Sea',
    },

    Builder {
        BuilderName = 'U1 Sea Sub',
        PlatoonTemplate = 'T1SeaSub',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL SUBMERSIBLE', '<=', 'NAVAL' } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 30, 'MOBILE NAVAL SUBMERSIBLE' } },
            -- Have we the eco to build it ?
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.MOBILE * categories.NAVAL * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'U1 Sea Frigate',
        PlatoonTemplate = 'T1SeaFrigate',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'NAVAL' } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 30, 'MOBILE NAVAL SUBMERSIBLE' } },
            -- Have we the eco to build it ?
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.MOBILE * categories.NAVAL * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'U1 Sea AntiAir',
        PlatoonTemplate = 'T1SeaAntiAir',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.4, 'MOBILE NAVAL ANTIAIR', '<=', 'MOBILE AIR' } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 30, 'MOBILE NAVAL SUBMERSIBLE' } },
            -- Have we the eco to build it ?
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'NAVAL' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.MOBILE * categories.NAVAL * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Sea',
    },
    -- ============ --
    --    TECH 2    --
    -- ============ --
    Builder {
        BuilderName = 'U2 Sea Destroyer',
        PlatoonTemplate = 'T2SeaDestroyer',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'NAVAL' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.50}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'MOBILE NAVAL' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.MOBILE * categories.NAVAL * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'U2 Sea Cruiser',
        PlatoonTemplate = 'T2SeaCruiser',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'NAVAL' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.50}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'MOBILE NAVAL' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.MOBILE * categories.NAVAL * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'U2 Sea SubKiller',
        PlatoonTemplate = 'T2SubKiller',
        Priority = 1100,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL SUBMERSIBLE', '<=', 'NAVAL' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.50}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
--            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'MOBILE NAVAL' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.MOBILE * categories.NAVAL * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'U2 Sea ShieldBoat',
        PlatoonTemplate = 'T2ShieldBoat',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'NAVAL' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.50}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'MOBILE NAVAL' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.MOBILE * categories.NAVAL * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'U2 Sea CounterIntelBoat',
        PlatoonTemplate = 'T2CounterIntelBoat',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'NAVAL' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.50}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'MOBILE NAVAL' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.MOBILE * categories.NAVAL * categories.EXPERIMENTAL }},
        },
        BuilderType = 'Sea',
    },
    -- ============ --
    --    TECH 3    --
    -- ============ --
    Builder {
        BuilderName = 'U3 Sea Battleship',
        PlatoonTemplate = 'T3SeaBattleship',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'NAVAL' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.50}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'MOBILE NAVAL' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'U3 Sea NukeSub',
        PlatoonTemplate = 'T3SeaNukeSub',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
           { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL SUBMERSIBLE', '<=', 'NAVAL' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.50}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'MOBILE NAVAL' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'U3 Sea MissileBoat',
        PlatoonTemplate = 'T3MissileBoat',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'NAVAL' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.50}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'MOBILE NAVAL' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'U3 Sea SubKiller',
        PlatoonTemplate = 'T3SubKiller',
        Priority = 1100,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL SUBMERSIBLE', '<=', 'NAVAL' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.50}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'MOBILE NAVAL' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'U3 Sea Battlecruiser',
        PlatoonTemplate = 'T3Battlecruiser',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'NAVAL' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.50}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.1, 'MOBILE NAVAL', '<=', 'MOBILE NAVAL' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.50, '<=', categories.MOBILE -categories.ENGINEER -categories.SCOUT } },
        },
        BuilderType = 'Sea',
    },
}
-- ===================================================-======================================================== --
-- ==                                      NAVAL T1 T2 T3 Formbuilder                                        == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'SeaAttack FormBuilders Uveso',
    BuildersType = 'PlatoonFormBuilder',
    -- =============== --
    --    PanicZone    --
    -- =============== --
    Builder {
        BuilderName = 'U123 PANIC AntiSea',
        PlatoonTemplate = 'U123-AntiSubPanic 1 500',
        Priority = 2000,                                        -- Priority. 1000 is normal.
        InstanceCount = 1,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = BasePanicZone,                       -- Searchradius for new target.
            AggressiveMove = true,                              -- If true, the unit will attack everything while moving to the target.
            IgnoreGroundDefense = false,                        -- Don't attack if we have more then x ground defense buildings at target position. false = no check
            TargetSearchCategory = 'NAVAL MOBILE',              -- Only find targets matching these categories.
            PrioritizedCategories = {
                'MOBILE NAVAL SUBMERSIBLE',
                'MOBILE NAVAL ANTIAIR',
                'MOBILE NAVAL',
                'NAVAL',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UBC, 'EnemyUnitsGreaterAtLocationRadius', {  BasePanicZone, 'LocationType', 0, categories.MOBILE * categories.NAVAL }}, -- radius, LocationType, unitCount, categoryEnemy
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
        BuilderName = 'U123 Military AntiSea',
        PlatoonTemplate = 'U123-AntiSubPanic 1 500',
        Priority = 2000,                                        -- Priority. 1000 is normal.
        InstanceCount = 1,                                      -- Number of plattons that will be formed.
        BuilderData = {
            SearchRadius = BaseMilitaryZone,                       -- Searchradius for new target.
            AggressiveMove = true,                              -- If true, the unit will attack everything while moving to the target.
            IgnoreGroundDefense = false,                        -- Don't attack if we have more then x ground defense buildings at target position. false = no check
            TargetSearchCategory = 'NAVAL MOBILE',              -- Only find targets matching these categories.
            PrioritizedCategories = {
                'MOBILE NAVAL SUBMERSIBLE',
                'MOBILE NAVAL ANTIAIR',
                'MOBILE NAVAL',
                'NAVAL',
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
        BuilderName = 'U123 KILLALL Solo',
        PlatoonTemplate = 'U123-KILLALL Solo',
        Priority = 1000,
        InstanceCount = 1,
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius for new target.
            AggressiveMove = true,                              -- If true, the unit will attack everything while moving to the target.
            IgnoreGroundDefense = false,                        -- Don't attack if we have more then x ground defense buildings at target position. false = no check
            TargetSearchCategory = 'ALLUNITS',       -- Only find targets matching these categories.
            PrioritizedCategories = {
                'MOBILE NAVAL',
                'STRUCTURE NAVAL',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 5, 'MOBILE NAVAL SUBMERSIBLE' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U123 KILLALL',
        PlatoonTemplate = 'U123 KILLALL 2 30',
        Priority = 1000,
        InstanceCount = 1,
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius for new target.
            AggressiveMove = true,                              -- If true, the unit will attack everything while moving to the target.
            IgnoreGroundDefense = false,                        -- Don't attack if we have more then x ground defense buildings at target position. false = no check
            TargetSearchCategory = 'ALLUNITS',       -- Only find targets matching these categories.
            PrioritizedCategories = {
                'MOBILE NAVAL',
                'STRUCTURE NAVAL',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 30, categories.MOBILE * categories.NAVAL}},
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',
    },
    -- ================= --
    --    Finish him!    --
    -- ================= --
    Builder {
        BuilderName = 'U123 Sea Kill Them All!!!',
        PlatoonTemplate = 'U123 KILLALL 2 30',
        Priority = 1000,
        InstanceCount = 1,
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius for new target.
            AggressiveMove = true,                              -- If true, the unit will attack everything while moving to the target.
            IgnoreGroundDefense = false,                        -- Don't attack if we have more then x ground defense buildings at target position. false = no check
            TargetSearchCategory = 'MOBILE, STRUCTURE, NAVAL',    -- Only find targets matching these categories.
            PrioritizedCategories = {
                'NAVAL',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.5, 'MOBILE NAVAL', '>', 'NAVAL' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',
    },
}
