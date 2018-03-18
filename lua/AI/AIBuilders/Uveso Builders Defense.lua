local UBC = '/lua/editor/UvesoBuildConditions.lua'
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local IBC = '/lua/editor/InstantBuildConditions.lua'
local EBC = '/lua/editor/EconomyBuildConditions.lua'
local MIBC = '/lua/editor/MiscBuildConditions.lua'

-- ===================================================-======================================================== --
-- ==                                       Build T2 & T3 Shields                                            == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'Shields Uveso',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'U2 Shield',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 1000,
        DelayEqualBuildPlattons = {'Shield', 3},
        InstanceCount = 1,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioAtLocation', { 'LocationType', 1.0, 'STRUCTURE SHIELD', '<=','STRUCTURE ENERGYPRODUCTION TECH3' } },
            -- Do we need additional conditions to build it ?
            { MIBC, 'FactionIndex', { 1, 3, 4 }}, -- 1: UEF, 2: Aeon, 3: Cybran, 4: Seraphim, 5: Nomads 
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'Shield' }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, categories.STRUCTURE * categories.SHIELD}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, 'STRUCTURE SHIELD -EXPERIMENTAL' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 6, 'STRUCTURE SHIELD EXPERIMENTAL' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 4,
                BuildClose = true,
                AdjacencyCategory = 'GATE, STRUCTURE ENERGYPRODUCTION EXPERIMENTAL, STRUCTURE EXPERIMENTAL, STRUCTURE FACTORY, STRUCTURE ENERGYPRODUCTION TECH3, STRUCTURE ENERGYPRODUCTION TECH2, STRUCTURE ENERGYPRODUCTION',
                AvoidCategory = categories.STRUCTURE * categories.SHIELD,
                maxUnits = 1,
                maxRadius = 15,
                LocationType = 'LocationType',
                BuildStructures = {
                    'T2ShieldDefense',
                },
            },
        },
    },
    Builder {
        BuilderName = 'U3 Shield',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1000,
        DelayEqualBuildPlattons = {'Shield', 3},
        InstanceCount = 1,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioAtLocation', { 'LocationType', 1.0, 'STRUCTURE SHIELD', '<=','STRUCTURE ENERGYPRODUCTION TECH3' } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'Shield' }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, categories.STRUCTURE * categories.SHIELD}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, 'STRUCTURE SHIELD -EXPERIMENTAL' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 6, 'STRUCTURE SHIELD EXPERIMENTAL' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                DesiresAssist = true,
                NumAssistees = 4,
                BuildClose = true,
                AdjacencyCategory = 'GATE, STRUCTURE ENERGYPRODUCTION EXPERIMENTAL, STRUCTURE EXPERIMENTAL, STRUCTURE FACTORY, STRUCTURE ENERGYPRODUCTION TECH3, STRUCTURE ENERGYPRODUCTION TECH2, STRUCTURE ENERGYPRODUCTION',
                AvoidCategory = categories.STRUCTURE * categories.SHIELD,
                maxUnits = 1,
                maxRadius = 15,
                LocationType = 'LocationType',
                BuildStructures = {
                    'T3ShieldDefense',
                }
            }
        }
    },
    -- =============== --
    --    Assistees    --
    -- =============== --
    Builder {
        BuilderName = 'U1 Assist Shield',
        PlatoonTemplate = 'EngineerAssist',
        Priority = 1000,
        InstanceCount = 2,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveGreaterThanUnitsInCategoryBeingBuiltAtLocation', { 'LocationType', 0, categories.STRUCTURE * categories.SHIELD, categories.STRUCTURE * categories.SHIELD }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            -- Don't build it if...
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                PermanentAssist = true,
                BeingBuiltCategories = {'STRUCTURE SHIELD'},
                AssisteeType = 'Structure',
                Time = 360,
            },
        }
    },
}
-- ===================================================-======================================================== --
-- ==                                      Upgrade T1 & T2 Shields                                           == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'ShieldUpgrades Uveso',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'U2 Shield Cybran 1',
        PlatoonTemplate = 'T2Shield1',
        Priority = 1000,
        DelayEqualBuildPlattons = {'Shield', 2},
        InstanceCount = 10,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 0.85, 0.85 }}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.1, 1.1 }}, -- relative baseincome 0=bad, 1=ok, 2=full
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 0, categories.TECH3 * categories.ENERGYPRODUCTION}},
            { UBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 3, categories.STRUCTURE * categories.SHIELD }},
            { UBC, 'CheckBuildPlattonDelay', { 'Shield' }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U2 Shield Cybran 2',
        PlatoonTemplate = 'T2Shield2',
        Priority = 1000,
        DelayEqualBuildPlattons = {'Shield', 2},
        InstanceCount = 10,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 0.85, 0.85 }}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.1, 1.1 }}, -- relative baseincome 0=bad, 1=ok, 2=full
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 0, categories.TECH3 * categories.ENERGYPRODUCTION}},
            { UBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 3, categories.STRUCTURE * categories.SHIELD }},
            { UBC, 'CheckBuildPlattonDelay', { 'Shield' }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U2 Shield Cybran 3',
        PlatoonTemplate = 'T2Shield3',
        Priority = 1000,
        DelayEqualBuildPlattons = {'Shield', 2},
        InstanceCount = 10,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 0.85, 0.85 }}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.1, 1.1 }}, -- relative baseincome 0=bad, 1=ok, 2=full
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 0, categories.TECH3 * categories.ENERGYPRODUCTION}},
            { UBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 3, categories.STRUCTURE * categories.SHIELD }},
            { UBC, 'CheckBuildPlattonDelay', { 'Shield' }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U2 Shield Cybran 4',
        PlatoonTemplate = 'T2Shield4',
        Priority = 1000,
        DelayEqualBuildPlattons = {'Shield', 2},
        InstanceCount = 10,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 0.85, 0.85 }}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.1, 1.1 }}, -- relative baseincome 0=bad, 1=ok, 2=full
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, categories.TECH3 * categories.ENERGYPRODUCTION}},
            { UBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 3, categories.STRUCTURE * categories.SHIELD }},
            { UBC, 'CheckBuildPlattonDelay', { 'Shield' }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U2 Shield UEF Seraphim',
        PlatoonTemplate = 'T2Shield',
        Priority = 1000,
        DelayEqualBuildPlattons = {'Shield', 2},
        InstanceCount = 10,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 0.85, 0.85 }}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.1, 1.1 }}, -- relative baseincome 0=bad, 1=ok, 2=full
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, categories.TECH3 * categories.ENERGYPRODUCTION}},
            { UBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 3, categories.STRUCTURE * categories.SHIELD }},
            { UBC, 'CheckBuildPlattonDelay', { 'Shield' }},
        },
        BuilderType = 'Any',
    },
}
-- ===================================================-======================================================== --
-- ==                                    T2 Tactical Missile Launcher                                        == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'Tactical Missile Launcher minimum Uveso',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'U2 TML Minimum',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 1000,
        BuilderConditions = {
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.TACTICALMISSILEPLATFORM}},
            { EBC, 'GreaterThanEconEfficiency', { 1.0, 1.0}},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'STRUCTURE SHIELD, STRUCTURE ENERGYPRODUCTION',
                AdjacencyDistance = 50,
                AvoidCategory = categories.FACTORY,
                maxUnits = 1,
                maxRadius = 10,
                BuildClose = false,
                BuildStructures = {
                    'T2StrategicMissile',
                },
                Location = 'LocationType',
            }
        }
    },
}
BuilderGroup {
    BuilderGroupName = 'Tactical Missile Launcher Maximum Uveso',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'U2 TML Maximum',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 1000,
        BuilderConditions = {
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { UBC, 'HaveUnitRatioAtLocation', { 'LocationType', 1.0, 'STRUCTURE TACTICALMISSILEPLATFORM TECH2', '<=','STRUCTURE SHIELD' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 9, categories.TACTICALMISSILEPLATFORM}},
            { EBC, 'GreaterThanEconEfficiency', { 1.0, 1.0}},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'STRUCTURE SHIELD',
                AdjacencyDistance = 50,
                BuildClose = false,
                BuildStructures = {
                    'T2StrategicMissile',
                },
                Location = 'LocationType',
            }
        }
    },
}
BuilderGroup {
    BuilderGroupName = 'Tactical Missile Launcher TacticalAISorian Uveso',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'U2 TML AI',
        PlatoonTemplate = 'T2TacticalLauncherSorian',
        Priority = 5000,
        InstanceCount = 1,
        FormRadius = 10000,
        BuilderType = 'Any',
    },
}
-- ===================================================-======================================================== --
-- ==                                     T2 Tactical Missile Defenses                                       == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'Tactical Missile Defenses Uveso',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'U2 TMD Panic 1',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 1000,
        BuilderConditions = {
            { UBC, 'EnemyUnitsGreaterAtLocationRadius', {  280, 'LocationType', 0, categories.TACTICALMISSILEPLATFORM }}, -- radius, LocationType, unitCount, categoryEnemy
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * categories.TECH2 }},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                AdjacencyCategory = 'STRUCTURE MASSEXTRACTION, STRUCTURE FACTORY',
                AdjacencyDistance = 50,
                AvoidCategory = categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * categories.TECH2,
                maxUnits = 1,
                maxRadius = 10,
                BuildClose = false,
                BuildStructures = {
                    'T2MissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'U2 TMD Panic 2',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 1000,
        BuilderConditions = {
            { UBC, 'EnemyUnitsGreaterAtLocationRadius', {  280, 'LocationType', 3, categories.TACTICALMISSILEPLATFORM }}, -- radius, LocationType, unitCount, categoryEnemy
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 6, categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * categories.TECH2 }},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                AdjacencyCategory = 'STRUCTURE MASSEXTRACTION, STRUCTURE FACTORY',
                AdjacencyDistance = 50,
                AvoidCategory = categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * categories.TECH2,
                maxUnits = 1,
                maxRadius = 10,
                BuildClose = false,
                BuildStructures = {
                    'T2MissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'U2 TMD Panic 3',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 1000,
        BuilderConditions = {
            { UBC, 'EnemyUnitsGreaterAtLocationRadius', {  280, 'LocationType', 6, categories.TACTICALMISSILEPLATFORM }}, -- radius, LocationType, unitCount, categoryEnemy
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 20, categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * categories.TECH2 }},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                AdjacencyCategory = 'STRUCTURE MASSEXTRACTION, STRUCTURE FACTORY',
                AdjacencyDistance = 50,
                AvoidCategory = categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * categories.TECH2,
                maxUnits = 1,
                maxRadius = 10,
                BuildClose = false,
                BuildStructures = {
                    'T2MissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'U2 TMD',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 1000,
        BuilderConditions = {
            { EBC, 'GreaterThanEconStorageRatio', { 0.05, 0.50}}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconStorageCurrent', { 28.0, 320.0 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 30, categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * categories.TECH2 }},
            { UBC, 'HaveUnitRatioAtLocation', { 'LocationType', 0.5, 'STRUCTURE DEFENSE ANTIMISSILE TECH2', '<','STRUCTURE FACTORY' } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * (categories.TECH2 + categories.TECH3) } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                AdjacencyCategory = 'STRUCTURE MASSEXTRACTION, STRUCTURE FACTORY',
                AdjacencyDistance = 50,
                AvoidCategory = categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * categories.TECH2,
                maxUnits = 1,
                maxRadius = 10,
                BuildClose = false,
                BuildStructures = {
                    'T2MissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}
-- ===================================================-======================================================== --
-- ==                                    T3 Strategic Missile LAUNCHER                                       == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'Strategic Missile Launcher Uveso',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'U3 SML',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1000,
        BuilderConditions = {
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.50}}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconTrend', { 8.0, 500.0 } }, -- relative income
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.ENERGYPRODUCTION * categories.TECH3 } },

            { UBC, 'HaveUnitRatioVersusEnemy', { 1.5, 'STRUCTURE NUKE TECH3', '<=', 'STRUCTURE DEFENSE ANTIMISSILE TECH3' } },
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH3' }},

            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.NUKE * categories.STRUCTURE}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.EXPERIMENTAL } },

            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T3StrategicMissile',
                },
                Location = 'LocationType',
            }
        }
    },
}
    -- This adds the NukeAI Plan to the NUKE. ( IssueNuke({unit}, GetHighestThreatClusterLocation) )
--BuilderGroup {
--    BuilderGroupName = 'Strategic Missile Launcher NukeAI Uveso',
--    BuildersType = 'PlatoonFormBuilder',
--    Builder {
--        BuilderName = 'U3 Nuke Silo',
--        PlatoonTemplate = 'T3Nuke',
--        Priority = 1000,
--        InstanceCount = 1,
--       BuilderType = 'Any',
--    },
--}
-- ===================================================-======================================================== --
-- ==                                    T3 Strategic Missile Defense                                        == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'Strategic Missile Defense Uveso',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'U3 SMD Enemy Main',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1100,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioAtLocationRadiusVersusEnemy', { 1.50, 'LocationType', 90, 'STRUCTURE DEFENSE ANTIMISSILE TECH3', '<','SILO NUKE TECH3, SILO NUKE EXPERIMENTAL' } },
            -- Do we need additional conditions to build it ?
            { UBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            -- Have we the eco to build it ?
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * (categories.TECH3 + categories.EXPERIMENTAL) } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 5,
            Construction = {
                BuildClose = false,
                AdjacencyCategory = categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3,
                AdjacencyDistance = 50,
                AvoidCategory = categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * categories.TECH3,
                maxUnits = 1,
                maxRadius = 20,
                BuildStructures = {
                    'T3StrategicMissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'U3 SMD Enemy Expansion',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1000,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioAtLocationRadiusVersusEnemy', { 1.50, 'LocationType', 90, 'STRUCTURE DEFENSE ANTIMISSILE TECH3', '<','SILO NUKE TECH3, SILO NUKE EXPERIMENTAL' } },
            -- Do we need additional conditions to build it ?
            { UBC, 'BuildNotOnLocation', { 'LocationType', 'MAIN' } },
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            -- Don't build it if...
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * (categories.TECH3 + categories.EXPERIMENTAL) } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 5,
            Construction = {
                BuildClose = false,
                AdjacencyCategory = categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH3,
                AdjacencyDistance = 50,
                AvoidCategory = categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * categories.TECH3,
                maxUnits = 1,
                maxRadius = 20,
                BuildStructures = {
                    'T3StrategicMissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
-- ===================================================-======================================================== --
-- ==                                          T3/T4 Artillery                                               == --
-- ===================================================-======================================================== --
    Builder {
        BuilderName = 'U3 Artillery',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1000,
        DelayEqualBuildPlattons = {'Artillery', 20},
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.EXPERIMENTAL}},
            -- Do we need additional conditions to build it ?
            { UCBC, 'CheckUnitRange', { 'LocationType', 'T3Artillery', categories.STRUCTURE * categories.TECH3 } },
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 0.95, 0.95 }}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconTrend', { 2.0, 300.0 } }, -- relative income
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }}, -- relative baseincome 0=bad, 1=ok, 2=full
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'Artillery' }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH3' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T3Artillery',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'U3 RapidArtillery',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1000,
        DelayEqualBuildPlattons = {'Artillery', 20},
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.EXPERIMENTAL}},
            -- Do we need additional conditions to build it ?
            { UCBC, 'CheckUnitRange', { 'LocationType', 'T3Artillery', categories.STRUCTURE * categories.TECH3 } },
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 0.80, 0.95 }}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconTrend', { 2.0, 300.0 } }, -- relative income
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }}, -- relative baseincome 0=bad, 1=ok, 2=full
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'Artillery' }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH3' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T3RapidArtillery',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'U4 Artillery',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1000,
        DelayEqualBuildPlattons = {'Artillery', 20},
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.EXPERIMENTAL}},
            -- Do we need additional conditions to build it ?
            { UCBC, 'CheckUnitRange', { 'LocationType', 'T3Artillery', categories.STRUCTURE * categories.TECH3 } },
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 0.80, 0.95 }}, -- Ratio from 0 to 1. (1=100%)
            { EBC, 'GreaterThanEconTrend', { 2.0, 300.0 } }, -- relative income
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0 }}, -- relative baseincome 0=bad, 1=ok, 2=full
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'Artillery' }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH3' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T4Artillery',
                },
                Location = 'LocationType',
            }
        }
    },
}

-- ===================================================-======================================================== --
-- ==                                     T1 Base Anti Air defense                                           == --
-- ===================================================-======================================================== --

BuilderGroup {
    BuilderGroupName = 'Base Anti Air Defense Uveso',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'U1 AirFactory AA',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1500,
        InstanceCount = 1,                                      -- Number of plattons that will be formed.
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioAtLocation', { 'LocationType', 1.0, 'STRUCTURE DEFENSE ANTIAIR', '<=','STRUCTURE FACTORY' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 10, categories.STRUCTURE * categories.DEFENSE * categories.ANTIAIR }},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.STRUCTURE * categories.DEFENSE * categories.ANTIAIR * categories.TECH3 }},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                AdjacencyCategory = 'STRUCTURE FACTORY',
                AdjacencyDistance = 50,
                AvoidCategory = categories.STRUCTURE * categories.ANTIAIR * categories.TECH1,
                maxUnits = 1,
                maxRadius = 10,
                BuildClose = false,
                BuildStructures = {
                    'T1AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'U2 AirFactory AA',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 1500,
        InstanceCount = 1,                                      -- Number of plattons that will be formed.
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioAtLocation', { 'LocationType', 1.0, 'STRUCTURE DEFENSE ANTIAIR TECH2', '<=','STRUCTURE FACTORY' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 20, categories.STRUCTURE * categories.DEFENSE * categories.ANTIAIR }},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.STRUCTURE * categories.DEFENSE * categories.ANTIAIR * categories.TECH3 }},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                AdjacencyCategory = 'STRUCTURE FACTORY',
                AdjacencyDistance = 50,
                AvoidCategory = categories.STRUCTURE * categories.ANTIAIR * categories.TECH2,
                maxUnits = 1,
                maxRadius = 10,
                BuildClose = false,
                BuildStructures = {
                    'T2AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'U3 AirFactory AA',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1500,
        InstanceCount = 2,                                      -- Number of plattons that will be formed.
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioAtLocation', { 'LocationType', 1.3, 'STRUCTURE DEFENSE ANTIAIR TECH3', '<=','STRUCTURE FACTORY' } },
            -- Do we need additional conditions to build it ?
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 32, categories.STRUCTURE * categories.DEFENSE * categories.ANTIAIR }},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                AdjacencyCategory = 'STRUCTURE FACTORY',
                AdjacencyDistance = 50,
                AvoidCategory = categories.STRUCTURE * categories.ANTIAIR * categories.TECH3,
                maxUnits = 1,
                maxRadius = 8,
                BuildClose = false,
                BuildStructures = {
                    'T3AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'U3 AirFactory AA EXPERIMENTAL Response',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1500,
        InstanceCount = 2,                                      -- Number of plattons that will be formed.
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveUnitRatioAtLocation', { 'LocationType', 2.0, 'STRUCTURE DEFENSE ANTIAIR TECH3', '<=','STRUCTURE FACTORY' } },
            -- Do we need additional conditions to build it ?
            { UBC, 'UnitsGreaterAtEnemy', { 0 , 'EXPERIMENTAL AIR' } },
            -- Have we the eco to build it ?
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.50, 0.95}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 64, categories.STRUCTURE * categories.DEFENSE * categories.ANTIAIR }},
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                AdjacencyCategory = 'STRUCTURE FACTORY',
                AdjacencyDistance = 50,
                AvoidCategory = categories.STRUCTURE * categories.ANTIAIR * categories.TECH3,
                maxUnits = 1,
                maxRadius = 8,
                BuildClose = false,
                BuildStructures = {
                    'T3AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    -- ================ --
    --    Reclaim AA    --
    -- ================ --
    Builder {
        BuilderName = 'U1 Reclaim T1 AA',
        PlatoonTemplate = 'EngineerBuilder',
        PlatoonAIPlan = 'ReclaimStructuresAI',
        Priority = 500,
        InstanceCount = 3,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 16, categories.STRUCTURE * categories.DEFENSE * categories.ANTIAIR }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.DEFENSE * categories.ANTIAIR * categories.TECH1 }},
            -- Have we the eco to build it ?
            -- Don't build it if...
            { UCBC, 'UnitCapCheckGreater', { .80 } },
        },
        BuilderData = {
            Location = 'LocationType',
            Reclaim = {'STRUCTURE DEFENSE ANTIAIR TECH1'},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U1 Reclaim T2 AA',
        PlatoonTemplate = 'T2EngineerBuilder',
        PlatoonAIPlan = 'ReclaimStructuresAI',
        Priority = 500,
        InstanceCount = 3,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 16, categories.STRUCTURE * categories.DEFENSE * categories.ANTIAIR }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.DEFENSE * categories.ANTIAIR * categories.TECH2 }},
            -- Have we the eco to build it ?
            -- Don't build it if...
            { UCBC, 'UnitCapCheckGreater', { .90 } },
        },
        BuilderData = {
            Location = 'LocationType',
            Reclaim = {'STRUCTURE DEFENSE ANTIAIR TECH2'},
        },
        BuilderType = 'Any',
    },
}









