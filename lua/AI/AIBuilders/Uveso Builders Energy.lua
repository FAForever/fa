-- Default economic builders for skirmish
local IBC = '/lua/editor/InstantBuildConditions.lua'
local SAI = '/lua/ScenarioPlatoonAI.lua'
local EBC = '/lua/editor/EconomyBuildConditions.lua'
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local MABC = '/lua/editor/MarkerBuildConditions.lua'
local MIBC = '/lua/editor/MiscBuildConditions.lua'
local UBC = '/lua/editor/UvesoBuildConditions.lua'

-- ===================================================-======================================================== --
-- ==                                       Build Power TECH 1,2,3                                           == --
-- ===================================================-======================================================== --
BuilderGroup {
    -- Build Power TECH 1,2,3
    BuilderGroupName = 'EnergyBuilders Uveso',
    BuildersType = 'EngineerBuilder',
    -- ============ --
    --    TECH 1    --
    -- ============ --
    Builder {
        BuilderName = 'U1 Power Trend < 100',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 2100,
        DelayEqualBuildPlattons = {'Energy', 3},
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'LessThanEnergyTrend', { 10.0 } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconIncome',  { 1.0, 6.0}}, -- Absolut Base income 4 60
            { EBC, 'GreaterThanEconStorageCurrent', { 0, -1 } },
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.TECH1 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.TECH1 } },
            { UBC, 'CheckBuildPlattonDelay', { 'Energy' }},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        InstanceCount = 1,
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                AdjacencyCategory = categories.FACTORY * categories.STRUCTURE * (categories.AIR + categories.LAND),
                AdjacencyDistance = 50,
                BuildClose = false,
                LocationType = 'LocationType',
                BuildStructures = {
                    'T1EnergyProduction',
                },
            }
        }
    },
    Builder {
        BuilderName = 'U1 Power Storage < 100',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 2100,
        DelayEqualBuildPlattons = {'Energy', 3},
        BuilderConditions = {
            -- When do we want to build this ?
            { EBC, 'LessThanEconStorageRatio', { -0.01, 0.99}}, -- Ratio from 0 to 1. (1=100%)
            -- Do we need additional conditions to build it ?
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconIncome',  { 1.0, 6.0}}, -- Absolut Base income 4 60
            { EBC, 'GreaterThanEconStorageCurrent', { 0, -1 } },
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.TECH1 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.TECH1 } },
            { UBC, 'CheckBuildPlattonDelay', { 'Energy' }},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        InstanceCount = 1,
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                AdjacencyCategory = 'FACTORY STRUCTURE AIR, FACTORY STRUCTURE LAND',
                AdjacencyDistance = 50,
                BuildClose = false,
                LocationType = 'LocationType',
                BuildStructures = {
                    'T1EnergyProduction',
                },
            }
        }
    },
    Builder {
        BuilderName = 'U1 Power Trend < 0',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 2100,
        DelayEqualBuildPlattons = {'Energy', 3},
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'LessThanEnergyTrend', { 0.0 } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconIncome',  { 1.0, 6.0}}, -- Absolut Base income 4 60
            { EBC, 'GreaterThanEconStorageCurrent', { 0, -1 } },
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.TECH1 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.TECH1 } },
            { UBC, 'CheckBuildPlattonDelay', { 'Energy' }},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        InstanceCount = 1,
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                AdjacencyCategory = 'FACTORY STRUCTURE AIR, FACTORY STRUCTURE LAND',
                AdjacencyDistance = 50,
                BuildClose = false,
                LocationType = 'LocationType',
                BuildStructures = {
                    'T1EnergyProduction',
                },
            }
        }
    },
    Builder {
        BuilderName = 'U-ACU Power Emergency',
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 2100,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'LessThanEnergyTrend', { 0.0 } },
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconIncome',  { 0.6, 6.0}}, -- Absolut Base income
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.TECH1 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.TECH1 } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        InstanceCount = 1,
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'FACTORY STRUCTURE AIR, FACTORY STRUCTURE LAND',
                AdjacencyDistance = 50,
                BuildClose = false,
                LocationType = 'LocationType',
                BuildStructures = {
                    'T1EnergyProduction',
                },
            }
        }
    },
    Builder {
        BuilderName = 'U-ACU Power Push 500',
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 2100,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'LessThanEnergyTrend', { 50.0 } },
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconStorageRatio', { 0.05, 0.05}}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconIncome',  { 0.6, 6.0}}, -- Absolut Base income
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.TECH1 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.TECH1 } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        InstanceCount = 1,
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'FACTORY STRUCTURE AIR, FACTORY STRUCTURE LAND',
                AdjacencyDistance = 50,
                BuildClose = false,
                LocationType = 'LocationType',
                BuildStructures = {
                    'T1EnergyProduction',
                },
            }
        }
    },
    Builder {
        BuilderName = 'U1 Power Hydrocarbon',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 2000,
        DelayEqualBuildPlattons = {'Energy', 1},
        InstanceCount = 1,
        BuilderConditions = {
            -- When do we want to build this ?
            { MABC, 'MarkerLessThanDistance',  { 'Hydrocarbon', 150}},
            -- Do we need additional conditions to build it ?
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconIncome',  { 0.4, 2.0}}, -- Absolut Base income 4 60
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'Energy' }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.TECH1 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.STRUCTURE * categories.ENERGYPRODUCTION - categories.TECH1 } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1HydroCarbon',
                }
            }
        }
    },
    -- ============ --
    --    TECH 2    --
    -- ============ --
    Builder {
        BuilderName = 'U2 Power minimum',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 2200,
        DelayEqualBuildPlattons = {'Energy', 3},
        InstanceCount = 1,
        BuilderConditions = {
            { UBC, 'CheckBuildPlattonDelay', { 'Energy' }},
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconIncome', { 0.6, 6.8 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 ) }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 + categories.EXPERIMENTAL ) } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STRUCTURE, FACTORY TECH3, FACTORY TECH2, FACTORY TECH1',
                AvoidCategory = categories.ENERGYPRODUCTION * categories.TECH2,
                maxUnits = 1,
                maxRadius = 10,
                LocationType = 'LocationType',
                BuildStructures = {
                    'T2EnergyProduction',
                },
            }
        }
    },
    Builder {
        BuilderName = 'U2 Power Trend < 1000',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 2200,
        DelayEqualBuildPlattons = {'Energy', 3},
        InstanceCount = 1,
        BuilderConditions = {
            { UBC, 'CheckBuildPlattonDelay', { 'Energy' }},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }}, -- relative baseincome 0=bad, 1=ok, 2=full
            { EBC, 'GreaterThanEconIncome', { 0.6, 6.8 }},
            { UBC, 'LessThanEnergyTrend', { 100.0 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 ) }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH2' }},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STRUCTURE, FACTORY TECH3, FACTORY TECH2, FACTORY TECH1',
                AvoidCategory = categories.ENERGYPRODUCTION * categories.TECH2,
                maxUnits = 1,
                maxRadius = 10,
                LocationType = 'LocationType',
                BuildStructures = {
                    'T2EnergyProduction',
                },
            }
        }
    },
    -- ============ --
    --    TECH 3    --
    -- ============ --
    Builder {
        BuilderName = 'U3 Power minimum',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 2300,
        DelayEqualBuildPlattons = {'Energy', 10},
        InstanceCount = 1,
        BuilderConditions = {
            { UBC, 'CheckBuildPlattonDelay', { 'Energy' }},
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }}, -- relative baseincome 0=bad, 1=ok, 2=full
            { EBC, 'GreaterThanEconIncome', { 0.5, 300.0 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.ENERGYPRODUCTION * categories.TECH3 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STRUCTURE, FACTORY TECH3, FACTORY TECH2, FACTORY TECH1',
                AvoidCategory = categories.ENERGYPRODUCTION * categories.TECH3,
                maxUnits = 1,
                maxRadius = 15,
                LocationType = 'LocationType',
                BuildStructures = {
                    'T3EnergyProduction',
                },
            }
        }
    },
    Builder {
        BuilderName = 'U3 Power Trend < 6000',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 2300,
        DelayEqualBuildPlattons = {'Energy', 10},
        InstanceCount = 1,
        BuilderConditions = {
            { UBC, 'CheckBuildPlattonDelay', { 'Energy' }},
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { UBC, 'LessThanEnergyTrend', { 600.0 } },
            { EBC, 'GreaterThanEconStorageRatio', { 0.00, 0.99}},
            { EBC, 'GreaterThanEconIncome', { 0.5, 100.0 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3}},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STRUCTURE, FACTORY TECH3, FACTORY TECH2, FACTORY TECH1',
                AvoidCategory = categories.ENERGYPRODUCTION * categories.TECH3,
                maxUnits = 1,
                maxRadius = 15,
                LocationType = 'LocationType',
                BuildStructures = {
                    'T3EnergyProduction',
                },
            }
        }
    },
    Builder {
        BuilderName = 'U3 Power Trend < Full',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 2300,
        DelayEqualBuildPlattons = {'Energy', 10},
        InstanceCount = 1,
        BuilderConditions = {
            { UBC, 'CheckBuildPlattonDelay', { 'Energy' }},
            { EBC, 'LessThanEconStorageRatio', { 1.00, 1.00}}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconIncome', { 0.5, 100.0 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3}},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STRUCTURE, FACTORY TECH3, FACTORY TECH2, FACTORY TECH1',
                AvoidCategory = categories.ENERGYPRODUCTION * categories.TECH3,
                maxUnits = 1,
                maxRadius = 15,
                LocationType = 'LocationType',
                BuildStructures = {
                    'T3EnergyProduction',
                },
            }
        }
    },
    Builder {
        BuilderName = 'U3 Power FullMass',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 2300,
        DelayEqualBuildPlattons = {'Energy', 10},
        InstanceCount = 4,
        BuilderConditions = {
            { UBC, 'CheckBuildPlattonDelay', { 'Energy' }},
            { EBC, 'GreaterThanEconTrend', { 10.0, 0.0 } }, -- relative income
            { UBC, 'LessThanEnergyTrend', { 1000.0 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 6, categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3}},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 10,
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STRUCTURE, FACTORY TECH3, FACTORY TECH2, FACTORY TECH1',
                AvoidCategory = categories.ENERGYPRODUCTION * categories.TECH3,
                maxUnits = 1,
                maxRadius = 15,
                LocationType = 'LocationType',
                BuildStructures = {
                    'T3EnergyProduction',
                },
            }
        }
    },
    -- =================== --
    --    EnergyStorage    --
    -- =================== --
    Builder {
        BuilderName = 'U1 Energy Storage Emergency',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1800,
        BuilderConditions = {
            -- When do we want to build this ?
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { UBC, 'LessEnergyStorageMax',  { 0.1}},
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1,  'ENERGYSTORAGE' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Location = 'LocationType',
            Construction = {
                BuildClose = false,
                AdjacencyCategory = 'STRUCTURE ENERGYPRODUCTION TECH3, STRUCTURE ENERGYPRODUCTION TECH2, STRUCTURE ENERGYPRODUCTION TECH1',
                LocationType = 'LocationType',
                BuildStructures = {
                    'EnergyStorage',
                },
            }
        }
    },
    Builder {
        BuilderName = 'U1 Energy Storage I',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1800,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, 'ENERGYSTORAGE' }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconIncome',  { 0.0, 25.0}}, -- Absolut Base income
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1,  'ENERGYSTORAGE' }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.STRUCTURE * categories.ENERGYSTORAGE }},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Location = 'LocationType',
            Construction = {
                BuildClose = false,
                AdjacencyCategory = 'STRUCTURE ENERGYPRODUCTION TECH3, STRUCTURE ENERGYPRODUCTION TECH2, STRUCTURE ENERGYPRODUCTION TECH1',
                LocationType = 'LocationType',
                BuildStructures = {
                    'EnergyStorage',
                },
            }
        }
    },
    Builder {
        BuilderName = 'U1 Energy Storage II',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1800,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, 'ENERGYSTORAGE' }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconIncome',  { 0.0, 100.0}}, -- Absolut Base income
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1,  'ENERGYSTORAGE' }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.STRUCTURE * categories.ENERGYSTORAGE }},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Location = 'LocationType',
            Construction = {
                BuildClose = false,
                AdjacencyCategory = 'STRUCTURE ENERGYPRODUCTION TECH3, STRUCTURE ENERGYPRODUCTION TECH2, STRUCTURE ENERGYPRODUCTION TECH1',
                LocationType = 'LocationType',
                BuildStructures = {
                    'EnergyStorage',
                },
            }
        }
    },
    Builder {
        BuilderName = 'U1 Energy Storage III',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1800,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 4, 'ENERGYSTORAGE' }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconIncome',  { 0.0, 300.0}}, -- Absolut Base income
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1,  'ENERGYSTORAGE' }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 7, categories.STRUCTURE * categories.ENERGYSTORAGE }},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Location = 'LocationType',
            Construction = {
                BuildClose = false,
                AdjacencyCategory = 'STRUCTURE ENERGYPRODUCTION TECH3, STRUCTURE ENERGYPRODUCTION TECH2, STRUCTURE ENERGYPRODUCTION TECH1',
                LocationType = 'LocationType',
                BuildStructures = {
                    'EnergyStorage',
                },
            }
        }
    },
    -- ======================= --
    --    Reclaim Buildings    --
    -- ======================= --
    Builder {
        BuilderName = 'U1 Reclaim T1 Pgens',
        PlatoonTemplate = 'EngineerBuilder',
        PlatoonAIPlan = 'ReclaimStructuresAI',
        Priority = 790,
        InstanceCount = 2,
        BuilderConditions = {
            { EBC, 'GreaterThanEconStorageRatio', { 0.00, 1.00}}, -- Ratio from 0 to 1. (1=100%)
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3 }},
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 0, categories.TECH1 * categories.ENERGYPRODUCTION }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
        },
        BuilderData = {
            Location = 'LocationType',
            Reclaim = {'STRUCTURE ENERGYPRODUCTION TECH1, STRUCTURE ENERGYPRODUCTION TECH2'},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U-ACU Reclaim T1 Pgens',
        PlatoonTemplate = 'CommanderBuilder',
        PlatoonAIPlan = 'ReclaimStructuresAI',
        Priority = 790,
        BuilderConditions = {
            { EBC, 'GreaterThanEconStorageRatio', { 0.00, 1.00}}, -- Ratio from 0 to 1. (1=100%)
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3 }},
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 0, categories.TECH1 * categories.ENERGYPRODUCTION }},
        },
        BuilderData = {
            Location = 'LocationType',
            Reclaim = {'STRUCTURE ENERGYPRODUCTION TECH1'},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U1 Reclaim T2 Pgens',
        PlatoonTemplate = 'EngineerBuilder',
        PlatoonAIPlan = 'ReclaimStructuresAI',
        Priority = 750,
        InstanceCount = 2,
        BuilderConditions = {
            { EBC, 'GreaterThanEconStorageRatio', { 0.00, 1.00}}, -- Ratio from 0 to 1. (1=100%)
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3 }},
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 0, categories.TECH1 * categories.ENERGYPRODUCTION }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
        },
        BuilderData = {
            Location = 'LocationType',
            Reclaim = {'STRUCTURE ENERGYPRODUCTION TECH1, STRUCTURE ENERGYPRODUCTION TECH2'},
        },
        BuilderType = 'Any',
    },
}
