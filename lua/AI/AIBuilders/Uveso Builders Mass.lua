-- Default economic builders for skirmish
local IBC = '/lua/editor/InstantBuildConditions.lua'
local SAI = '/lua/ScenarioPlatoonAI.lua'
local EBC = '/lua/editor/EconomyBuildConditions.lua'
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local MABC = '/lua/editor/MarkerBuildConditions.lua'
local MIBC = '/lua/editor/MiscBuildConditions.lua'
local UBC = '/lua/editor/UvesoBuildConditions.lua'

-- ============================================================================================================ --
-- ==                                     Build MassExtractors / Creators                                    == --
-- ============================================================================================================ --
BuilderGroup {
    -- Build MassExtractors / Creators 
    BuilderGroupName = 'MassBuilders Uveso',
    BuildersType = 'EngineerBuilder',
    -- ======================= --
    --    TECH 1 - Range 30    --
    -- ======================= --
    Builder {
        BuilderName = 'U1 Mass 30',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 2100,
        InstanceCount = 4,
        BuilderConditions = {
            -- When do we want to build this ?
            { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 30, -500, 1, 0, 'AntiSurface', 1 }}, -- LocationType, distance, threatMin, threatMax, threatRings, threatType, maxNum
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusCap', { 0.03, '<=', categories.STRUCTURE * categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = false,
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'U1 Mass 150',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 2090,
        InstanceCount = 4,
        BuilderConditions = {
            -- When do we want to build this ?
            { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 150, -500, 1, 0, 'AntiSurface', 1 }}, -- LocationType, distance, threatMin, threatMax, threatRings, threatType, maxNum
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusCap', { 0.03, '<=', categories.STRUCTURE * categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'U1 Mass 250',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 2080,
        InstanceCount = 4,
        BuilderConditions = {
            -- When do we want to build this ?
            { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 250, -500, 1, 0, 'AntiSurface', 1 }}, -- LocationType, distance, threatMin, threatMax, threatRings, threatType, maxNum
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusCap', { 0.06, '<=', categories.STRUCTURE * categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'U1 Mass 450',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 2070,
        InstanceCount = 4,
        BuilderConditions = {
            -- When do we want to build this ?
            { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 450, -500, 1, 0, 'AntiSurface', 1 }}, -- LocationType, distance, threatMin, threatMax, threatRings, threatType, maxNum
            -- Do we need additional conditions to build it ?
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH1' }},
            -- Have we the eco to build it ?
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusCap', { 0.10, '<=', categories.STRUCTURE * categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'U1 Mass 1000',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 2060,
        InstanceCount = 2,
        BuilderConditions = {
            -- When do we want to build this ?
            { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 1000, -500, 1, 0, 'AntiSurface', 1 }}, -- LocationType, distance, threatMin, threatMax, threatRings, threatType, maxNum
            -- Do we need additional conditions to build it ?
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH1' }},
            -- Have we the eco to build it ?
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusCap', { 0.14, '<=', categories.STRUCTURE * categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = false,                           -- If this is true, the unit is forced to use a transport, even if it has a valid path to the destination.
            NeedGuard = false,
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'U1 Mass 10-12 Trans',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 2000,
        InstanceCount = 1,
        BuilderConditions = {
            -- When do we want to build this ?
            { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 10000, false, false, false, false, 1 }}, -- LocationType, distance, threatMin, threatMax, threatRings, threatType, maxNum
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 9, categories.ENGINEER * categories.TECH1 }},
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH1' }},
            { UBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            -- Have we the eco to build it ?
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusCap', { 0.14, '<=', categories.STRUCTURE * categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,                           -- If this is true, the unit is forced to use a transport, even if it has a valid path to the destination.
            NeedGuard = false,
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'U-ACU Resource RECOVER',
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 4000,
        BuilderConditions = {
            -- When do we want to build this ?
            { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 10000, -5000, 5000, 1, 'AntiSurface', 1 }}, -- LocationType, distance, threatMin, threatMax, threatRings, threatType, maxNum
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.STRUCTURE * categories.MASSEXTRACTION } },
            -- Do we need additional conditions to build it ?
            { UBC, 'GreaterThanGameTimeSeconds', { 180 } },
            -- Have we the eco to build it ?
            -- Don't build it if...
            { UBC, 'HaveUnitRatioVersusCap', { 0.14, '<=', categories.STRUCTURE * categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = false,
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource',
                }
            }
        }
    },
    -- ============ --
    --    TECH 3    --
    -- ============ --
    Builder {
        BuilderName = 'U3 Mass Fab',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 0,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, 'ENERGYPRODUCTION TECH3' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 10, categories.STRUCTURE * categories.MASSEXTRACTION }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH3' }},
            { UCBC, 'HaveUnitRatio', { 0.3, 'MASSFABRICATION', '<=','ENERGYPRODUCTION TECH3' } },
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'MASSFABRICATION' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.14, '<=', categories.STRUCTURE * categories.MASSEXTRACTION } },

        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 4,
                AdjacencyCategory = 'ENERGYPRODUCTION TECH3',
                AdjacencyDistance = 50,
                AvoidCategory = categories.MASSFABRICATION,
                maxUnits = 1,
                maxRadius = 15,
                BuildClose = true,
                BuildStructures = {
                    'T3MassCreation',
                },
            }
        }
    },
}
-- ============================================================================================================ --
-- ==                                         Upgrade MassExtractors                                         == --
-- ============================================================================================================ --
BuilderGroup {
    -- Upgrade MassExtractors from Tech 1 to 2 AND from Tech 2 to 3
    BuilderGroupName = 'ExtractorUpgrades Uveso',
    BuildersType = 'PlatoonFormBuilder',
    -- ============ --
    --    TECH 1    --
    -- ============ --
    Builder {
        BuilderName = 'U12 Add to Upgrade Platoon',
        PlatoonTemplate = 'AddToMassExtractorUpgradePlatoon',
        Priority = 4000,
        InstanceCount = 1,
        FormRadius = 10000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveGreaterThanArmyPoolWithCategory', { 0, categories.MASSEXTRACTION} },
            -- Do we need additional conditions to build it ?
            { EBC, 'GreaterThanEconIncome',  { 0.0, 12.0}}, -- Absolut Base income
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',
    },
}
-- ===================================================-======================================================== --
-- ==                                     Build MassStorage/Adjacency                                        == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'MassStorageBuilder Uveso',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'U1 Mass Adjacency Engineer',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1800,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'AdjacencyCheck', { 'LocationType', 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3', 100, 'ueb1106' } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, 'MASSSTORAGE' }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconIncome',  { 0.0, 25.0}}, -- Absolut Base income
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1,  'MASSSTORAGE' }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 7, categories.STRUCTURE * categories.MASSSTORAGE }},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
            { UBC, 'LessThanEconStorageCurrent', { 20000, 10000000 } },
        },
        InstanceCount = 1,
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'MASSEXTRACTION TECH3, MASSEXTRACTION TECH2',
                AdjacencyDistance = 100,
                BuildClose = false,
                BuildStructures = {
                    'MassStorage',
                }
            }
        }
    },
    Builder {
        BuilderName = 'U1 Mass Storage Emergency',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1800,
        BuilderConditions = {
            -- When do we want to build this ?
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { UBC, 'LessMassStorageMax',  { 0.1}},
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1,  'MASSSTORAGE' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Location = 'LocationType',
            Construction = {
                AdjacencyCategory = 'MASSEXTRACTION TECH3, MASSEXTRACTION TECH2',
                AdjacencyDistance = 100,
                BuildClose = false,
                BuildStructures = {
                    'MassStorage',
                },
            }
        }
    },
    Builder {
        BuilderName = 'U1 Mass Storage I',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1800,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, 'MASSSTORAGE' }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconIncome',  { 0.0, 25.0}}, -- Absolut Base income
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1,  'MASSSTORAGE' }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 7, categories.STRUCTURE * categories.MASSSTORAGE }},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
            { UBC, 'LessThanEconStorageCurrent', { 20000, 10000000 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Location = 'LocationType',
            Construction = {
                AdjacencyCategory = 'MASSEXTRACTION TECH3, MASSEXTRACTION TECH2',
                AdjacencyDistance = 100,
                BuildClose = false,
                BuildStructures = {
                    'MassStorage',
                },
            }
        }
    },
}
