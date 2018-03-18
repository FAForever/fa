local IBC = '/lua/editor/InstantBuildConditions.lua'
local EBC = '/lua/editor/EconomyBuildConditions.lua'
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local SIBC = '/lua/editor/SorianInstantBuildConditions.lua'
local UBC = '/lua/editor/UvesoBuildConditions.lua'

local ExperimentalCount = 3
local mapSizeX, mapSizeZ = GetMapSize()
local BaseMilitaryZone = math.max( mapSizeX-50, mapSizeZ-50 ) / 2 -- Half the map
local BasePanicZone = BaseMilitaryZone / 2
BasePanicZone = math.max( 40, BasePanicZone )
BasePanicZone = math.min( 120, BasePanicZone )

-- ===================================================-======================================================== --
-- ==                                 Mobile Experimental Land/Air/Sea                                       == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'Mobile Experimental Builder Uveso',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Uveso T4AirExperimental1',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1000,
        DelayEqualBuildPlattons = {'Experimental', 10},
        InstanceCount = 3,
        BuilderConditions = {
            { UBC, 'CheckBuildPlattonDelay', { 'Experimental' }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 0.95, 0.95 }}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconTrend', { 2.0, 300.0 } }, -- relative income
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }}, -- relative baseincome 0=bad, 1=ok, 2=full
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH3' }},
            { UBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STRUCTURE, FACTORY TECH3, FACTORY TECH2, FACTORY TECH1',
                BuildStructures = {
                    'T4AirExperimental1',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Uveso T4LandExperimental3',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1000,
        DelayEqualBuildPlattons = {'Experimental', 10},
        InstanceCount = 1,
        BuilderConditions = {
            { UBC, 'CheckBuildPlattonDelay', { 'Experimental' }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 0.95, 0.95 }}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconTrend', { 2.0, 300.0 } }, -- relative income
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }}, -- relative baseincome 0=bad, 1=ok, 2=full
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH3' }},
            { UBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                AdjacencyCategory = 'SHIELD STRUCTURE, FACTORY TECH3, FACTORY TECH2, FACTORY TECH1',
                BuildStructures = {
                    'T4LandExperimental3',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Uveso T4SeaExperimental1',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1000,
        DelayEqualBuildPlattons = {'Experimental', 10},
        InstanceCount = 1,
        BuilderConditions = {
            { UBC, 'CheckBuildPlattonDelay', { 'Experimental' }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 0.80, 0.95 }}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconTrend', { 2.0, 300.0 } }, -- relative income
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }}, -- relative baseincome 0=bad, 1=ok, 2=full
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH3' }},
            { UBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STRUCTURE, FACTORY TECH3, FACTORY TECH2, FACTORY TECH1',
                BuildStructures = {
                    'T4SeaExperimental1',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Uveso T4LandExperimental2',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1000,
        DelayEqualBuildPlattons = {'Experimental', 10},
        InstanceCount = 1,
        BuilderConditions = {
            { UBC, 'CheckBuildPlattonDelay', { 'Experimental' }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 0.80, 0.95 }}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconTrend', { 2.0, 300.0 } }, -- relative income
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }}, -- relative baseincome 0=bad, 1=ok, 2=full
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH3' }},
            { UBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = false,
                AdjacencyCategory = 'SHIELD STRUCTURE, FACTORY TECH3, FACTORY TECH2, FACTORY TECH1',
                BuildStructures = {
                    'T4LandExperimental2',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Uveso T4LandExperimental1',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1000,
        DelayEqualBuildPlattons = {'Experimental', 10},
        InstanceCount = 1,
        BuilderConditions = {
            { UBC, 'CheckBuildPlattonDelay', { 'Experimental' }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 0.70, 0.95 }}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconTrend', { 2.0, 300.0 } }, -- relative income
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }}, -- relative baseincome 0=bad, 1=ok, 2=full
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH3' }},
            { UBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STRUCTURE, FACTORY TECH3, FACTORY TECH2, FACTORY TECH1',
                BuildStructures = {
                    'T4LandExperimental1',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'U-T4 LandExp1 Effi',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 900,
        DelayEqualBuildPlattons = {'Experimental Effi', 10},
        InstanceCount = 30,
        BuilderConditions = {
            { EBC, 'GreaterThanEconStorageRatio', { 0.95, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            { UBC, 'CheckBuildPlattonDelay', { 'Experimental Effi' }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 2.0, 300.0 } }, -- relative income
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.1, 1.1 }}, -- relative baseincome 0=bad, 1=ok, 2=full
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH3' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STRUCTURE, FACTORY TECH3, FACTORY TECH2, FACTORY TECH1',
                BuildStructures = {
                    'T4LandExperimental1',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'U-T4 LandExp1 Minimum',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 900,
        DelayEqualBuildPlattons = {'Experimental Effi', 10},
        InstanceCount = 1,
        BuilderConditions = {
            { UBC, 'CheckBuildPlattonDelay', { 'Experimental Effi' }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconIncome', { 20.0, 1000.0 }},
            { UBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.EXPERIMENTAL * categories.LAND }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STRUCTURE, FACTORY TECH3, FACTORY TECH2, FACTORY TECH1',
                BuildStructures = {
                    'T4LandExperimental1',
                },
                Location = 'LocationType',
            }
        }
    },
}
-- ===================================================-======================================================== --
-- ==                                 Economic Experimental (Paragon etc)                                    == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'Economic Experimental Builder Uveso',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'U3 Paragon 1st',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1000,
        DelayEqualBuildPlattons = {'Experimental', 15},
        BuilderConditions = {
            { UBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            { UBC, 'CheckBuildPlattonDelay', { 'Experimental' }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 0.90, 0.90}}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconTrend', { 6.0, 180.0 } }, -- relative income
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.EXPERIMENTAL}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.EXPERIMENTAL * categories.ECONOMIC }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.STRUCTURE * categories.EXPERIMENTAL * categories.ECONOMIC}},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'SHIELD STRUCTURE, STRUCTURE',
                AdjacencyDistance = 80,
                AvoidCategory = categories.ENERGYPRODUCTION * categories.EXPERIMENTAL,
                maxUnits = 1,
                maxRadius = 12,
                BuildClose = false,
                BuildStructures = {
                    'T4EconExperimental',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'U3 Paragon 2nd',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1000,
        BuilderConditions = {
            { UBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.EXPERIMENTAL}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.EXPERIMENTAL * categories.ECONOMIC }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.EXPERIMENTAL * categories.ECONOMIC}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.STRUCTURE * categories.EXPERIMENTAL * categories.ECONOMIC}},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'SHIELD STRUCTURE, STRUCTURE',
                AdjacencyDistance = 80,
                AvoidCategory = categories.ENERGYPRODUCTION * categories.EXPERIMENTAL,
                maxUnits = 1,
                maxRadius = 12,
                BuildClose = false,
                BuildStructures = {
                    'T4EconExperimental',
                },
                Location = 'LocationType',
            }
        }
    },
}
-- ===================================================-======================================================== --
-- ==                                  Experimental Attack FormBuilder                                       == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'ExperimentalAttackFormBuilders Uveso',
    BuildersType = 'PlatoonFormBuilder',
    -- ================== --
    --    BaseDefender    --
    -- ================== --
    Builder {
        BuilderName = 'U-T4 BaseDefender LAND',
        --PlatoonAddPlans = {'NameUnitsSorian'},
        PlatoonTemplate = 'T4ExperimentalLandUveso 1 1',
        Priority = 1600,                                        -- Priority. 1000 is normal.
        InstanceCount = 2,                                      -- Number of plattons that will be formed.
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = BasePanicZone*2,                     -- Searchradius for new target.
            UseMoveOrder = false,                               -- If true, the unit will first move to the targetposition and then attack it.
            TargetSearchCategory = 'MOBILE LAND, STRUCTURE LAND',-- Only find targets matching these categories.
            PrioritizedCategories = {
                'MOBILE EXPERIMENTAL',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.EXPERIMENTAL * categories.MOBILE * categories.LAND } },
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U-T4 BaseDefender AIR',
        PlatoonTemplate = 'U4-ExperimentalInterceptor 1 1',
        --PlatoonAddPlans = {'NameUnitsSorian'},
        Priority = 1500,                                        -- Priority. 1000 is normal.
        InstanceCount = 5,                                      -- Number of plattons that will be formed.
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = BasePanicZone*2,                     -- Searchradius for new target.
            UseMoveOrder = true,                                -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = false,                              -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE, STRUCTURE',         -- Only find targets matching these categories.
            PrioritizedCategories = {
                'EXPERIMENTAL',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.EXPERIMENTAL * categories.MOBILE * categories.AIR } },
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    -- ======================= --
    --    EnemyBaseAttacker    --
    -- ======================= --
    Builder {
        BuilderName = 'U-T4 Mass Hunter Experimental',
        --PlatoonAddPlans = {'NameUnitsSorian'},
        PlatoonTemplate = 'T4ExperimentalLandGroupUveso 2 2',
        Priority = 1500,                                        -- Priority. 1000 is normal.
        InstanceCount = 2,                                      -- Number of plattons that will be formed.
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = 10000,                                 -- Searchradius for new target.
            UseMoveOrder = false,                                -- If true, the unit will first move to the targetposition and then attack it.
            TargetSearchCategory = 'LAND, MASSEXTRACTION', -- Only find targets matching these categories. -- Only find targets matching these categories.   -- Only find targets matching these categories.
            PrioritizedCategories = {
                'MASSEXTRACTION',
                'STRUCTURE',
                'MOBILE LAND',
                'LAND',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.EXPERIMENTAL * categories.MOBILE * categories.LAND } },
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
     Builder {
        BuilderName = 'U-T4 Group Attack LAND SHIELDS',
        --PlatoonAddPlans = {'NameUnitsSorian'},
        PlatoonTemplate = 'T4ExperimentalLandGroupUveso 2 2',
        Priority = 1500,                                        -- Priority. 1000 is normal.
        InstanceCount = 1,                                     -- Number of plattons that will be formed.
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = 10000,                                 -- Searchradius for new target.
            UseMoveOrder = true,                                -- If true, the unit will first move to the targetposition and then attack it.
            TargetSearchCategory = 'MOBILE LAND, STRUCTURE LAND',   -- Only find targets matching these categories.
            PrioritizedCategories = {
                'STRUCTURE LAND SHIELDS EXPERIMENTAL',
                'STRUCTURE LAND SHIELDS',
                'STRUCTURE LAND DEFENSE',
                'STRUCTURE LAND',
                'LAND',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 3, categories.EXPERIMENTAL * categories.MOBILE * categories.LAND } },
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
     Builder {
        BuilderName = 'U-T4 Exp Group Attack NUKE',
        --PlatoonAddPlans = {'NameUnitsSorian'},
        PlatoonTemplate = 'T4ExperimentalLandGroupUveso 2 2',
        Priority = 1500,                                        -- Priority. 1000 is normal.
        InstanceCount = 1,                                      -- Number of plattons that will be formed.
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius for new target.
            UseMoveOrder = false,                               -- If true, the unit will first move to the targetposition and then attack it.
            TargetSearchCategory = 'MOBILE LAND, STRUCTURE LAND',   -- Only find targets matching these categories.
            PrioritizedCategories = {
                'STRUCTURE LAND NUKE',
                'STRUCTURE LAND DEFENSE',
                'STRUCTURE LAND',
                'LAND',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 4, categories.EXPERIMENTAL * categories.MOBILE * categories.LAND } },
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
     Builder {
        BuilderName = 'U-T4 Kill All',
        --PlatoonAddPlans = {'NameUnitsSorian'},
        PlatoonTemplate = 'T4ExperimentalLandGroupUveso 2 2',
        Priority = 1500,                                        -- Priority. 1000 is normal.
        InstanceCount = 15,                                      -- Number of plattons that will be formed.
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius for new target.
            UseMoveOrder = false,                               -- If true, the unit will first move to the targetposition and then attack it.
            TargetSearchCategory = 'LAND',                  -- Only find targets matching these categories.
            PrioritizedCategories = {
                'EXPERIMENTAL',
                'STRUCTURE LAND NUKE',
                'STRUCTURE LAND DEFENSE',
                'STRUCTURE LAND',
                'LAND',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 5, categories.EXPERIMENTAL * categories.MOBILE * categories.LAND } },
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U4 Exp AntiAir',
        PlatoonTemplate = 'U4-ExperimentalInterceptor 1 1',
        --PlatoonAddPlans = {'NameUnitsSorian'},
        Priority = 1500,                                        -- Priority. 1000 is normal.
        InstanceCount = 5,                                      -- Number of plattons that will be formed.
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = BaseMilitaryZone,                    -- Searchradius for new target.
            UseMoveOrder = false,                                -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = false,                              -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE, STRUCTURE',         -- Only find targets matching these categories.
            PrioritizedCategories = {
                'EXPERIMENTAL',
                'TECH3',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.EXPERIMENTAL * categories.MOBILE * categories.AIR } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, categories.EXPERIMENTAL * categories.MOBILE * categories.LAND } },
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U4 Exp Air KillAll',
        PlatoonTemplate = 'U4-ExperimentalInterceptor 1 1',
        --PlatoonAddPlans = {'NameUnitsSorian'},
        Priority = 1500,                                        -- Priority. 1000 is normal.
        InstanceCount = 5,                                      -- Number of plattons that will be formed.
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = 10000,                               -- Searchradius for new target.
            UseMoveOrder = false,                                -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = false,                              -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'ALLUNITS',                  -- Only find targets matching these categories.
            PrioritizedCategories = {
                'EXPERIMENTAL',
                'TECH3',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, categories.EXPERIMENTAL * categories.MOBILE * categories.AIR } },
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    -- ================= --
    --    Finish him!    --
    -- ================= --
    Builder {
        BuilderName = 'U-T4 Land. Kill Them All!!!',
        --PlatoonAddPlans = {'NameUnitsSorian'},
        PlatoonTemplate = 'T4ExperimentalLandGroupUveso 2 2',
        Priority = 1600,                                        -- Priority. 1000 is normal.
        InstanceCount = 20,                                      -- Number of plattons that will be formed.
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = 10000,                     -- Searchradius for new target.
            UseMoveOrder = false,                               -- If true, the unit will first move to the targetposition and then attack it.
            TargetSearchCategory = 'MOBILE, STRUCTURE',    -- Only find targets matching these categories.
            PrioritizedCategories = {
                'STRUCTURE ARTILLERY',
                'STRUCTURE NUKE',
                'LAND',
                'AIR',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.5, 'MOBILE', '>', 'MOBILE' } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, categories.EXPERIMENTAL * categories.MOBILE * categories.LAND } },
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
    Builder {
        BuilderName = 'U-T4 Air. Kill Them All!!!',
        PlatoonTemplate = 'U4-ExperimentalInterceptor 1 1',
        --PlatoonAddPlans = {'NameUnitsSorian'},
        Priority = 1500,                                        -- Priority. 1000 is normal.
        InstanceCount = 20,                                      -- Number of plattons that will be formed.
        FormRadius = 10000,
        BuilderData = {
            SearchRadius = 10000,                     -- Searchradius for new target.
            UseMoveOrder = false,                                -- If true, the unit will first move to the targetposition and then attack it.
            IgnoreAntiAir = false,                              -- Don't attack if we have more then x anti air buildings at target position.
            TargetSearchCategory = 'MOBILE, STRUCTURE',    -- Only find targets matching these categories.
            PrioritizedCategories = {
                'STRUCTURE',
                'MOBILE',
                'ALLUNITS',
            },
        },
        BuilderConditions = {                                   -- platoon will be formed if all conditions are true
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioVersusEnemy', { 1.5, 'MOBILE', '>', 'MOBILE' } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.EXPERIMENTAL * categories.MOBILE * categories.AIR } },
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',                                    -- Build with "Land" "Air" "Sea" "Gate" or "All" Factories. - "Any" forms a Platoon.
    },
}
