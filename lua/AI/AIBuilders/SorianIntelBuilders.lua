#***************************************************************************
#*
#**  File     :  /lua/ai/SorianIntelBuilders.lua
#**
#**  Summary  : Default economic builders for skirmish
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local BBTmplFile = '/lua/basetemplates.lua'
local BuildingTmpl = 'BuildingTemplates'
local BaseTmpl = 'BaseTemplates'
local ExBaseTmpl = 'ExpansionBaseTemplates'
local Adj2x2Tmpl = 'Adjacency2x2'
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local MIBC = '/lua/editor/MiscBuildConditions.lua'
local MABC = '/lua/editor/MarkerBuildConditions.lua'
local OAUBC = '/lua/editor/OtherArmyUnitCountBuildConditions.lua'
local EBC = '/lua/editor/EconomyBuildConditions.lua'
local PCBC = '/lua/editor/PlatoonCountBuildConditions.lua'
local SAI = '/lua/ScenarioPlatoonAI.lua'
local TBC = '/lua/editor/ThreatBuildConditions.lua'
local IBC = '/lua/editor/InstantBuildConditions.lua'
local PlatoonFile = '/lua/platoon.lua'
local SBC = '/lua/editor/SorianBuildConditions.lua'
local SIBC = '/lua/editor/SorianInstantBuildConditions.lua'

BuilderGroup {
    BuilderGroupName = 'SorianAirScoutFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'Sorian T1 Air Scout - Init',
        PlatoonTemplate = 'T1AirScout',
        Priority = 600, #700,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.SCOUT * categories.AIR}},
            { SBC, 'LessThanGameTime', { 300 } },
            { SBC, 'MapGreaterThan', { 1000, 1000 }},
            #{ UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.FACTORY }},
            #{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.TECH2 * categories.FACTORY * categories.AIR } },
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.AIR * categories.FACTORY * categories.TECH1 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.SCOUT * categories.AIR } },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
            { SBC, 'NoRushTimeCheck', { 600 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'Sorian T1 Air Scout',
        PlatoonTemplate = 'T1AirScout',
        Priority = 700, #700,
        BuilderConditions = {
            #{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.SCOUT * categories.AIR}}, #1
            { SIBC, 'HaveLessThanUnitsForMapSize', { {[256] = 2, [512] = 4, [1024] = 6, [2048] = 8, [4096] = 8}, categories.SCOUT * categories.AIR}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.TECH3 * categories.FACTORY * categories.AIR } },
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.AIR * categories.FACTORY * categories.TECH1 } },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, categories.AIR * categories.FACTORY * categories.TECH2 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.SCOUT * categories.AIR } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
            { SBC, 'NoRushTimeCheck', { 600 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'Sorian T1 Air Scout - Lower Pri',
        PlatoonTemplate = 'T1AirScout',
        Priority = 501, #500,
        BuilderConditions = {
            #{ UCBC, 'HaveLessThanUnitsWithCategory', { 5, categories.SCOUT * categories.AIR}}, #3
            { SIBC, 'HaveLessThanUnitsForMapSize', { {[256] = 4, [512] = 6, [1024] = 8, [2048] = 10, [4096] = 12}, categories.SCOUT * categories.AIR}},
            { SBC, 'MapGreaterThan', { 500, 500 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.TECH3 * categories.FACTORY * categories.AIR } },
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.AIR * categories.FACTORY * categories.TECH1 } },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, categories.AIR * categories.FACTORY * categories.TECH2 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.SCOUT * categories.AIR } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
            { SBC, 'NoRushTimeCheck', { 600 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'Sorian T2 Air Scout',
        PlatoonTemplate = 'T2AirScout',
        Priority = 800, #601,
        BuilderConditions = {
            #{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.SCOUT * categories.AIR}}, #1
            { SIBC, 'HaveLessThanUnitsForMapSize', { {[256] = 2, [512] = 4, [1024] = 6, [2048] = 8, [4096] = 8}, categories.SCOUT * categories.AIR}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.TECH3 * categories.FACTORY * categories.AIR } },
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.AIR * categories.FACTORY * categories.TECH2 } },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, categories.AIR * categories.FACTORY * categories.TECH3 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.SCOUT * categories.AIR } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
            { SBC, 'NoRushTimeCheck', { 600 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'Sorian T2 Air Scout - Lower Pri',
        PlatoonTemplate = 'T2AirScout',
        Priority = 601, #500,
        BuilderConditions = {
            #{ UCBC, 'HaveLessThanUnitsWithCategory', { 5, categories.SCOUT * categories.AIR}}, #3
            { SIBC, 'HaveLessThanUnitsForMapSize', { {[256] = 4, [512] = 6, [1024] = 8, [2048] = 10, [4096] = 12}, categories.SCOUT * categories.AIR}},
            { SBC, 'MapGreaterThan', { 500, 500 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.TECH3 * categories.FACTORY * categories.AIR } },
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.AIR * categories.FACTORY * categories.TECH2 } },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, categories.AIR * categories.FACTORY * categories.TECH3 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.SCOUT * categories.AIR } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
            { SBC, 'NoRushTimeCheck', { 600 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'Sorian T3 Air Scout',
        PlatoonTemplate = 'T3AirScout',
        Priority = 900, #701,
        BuilderConditions = {
            #{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.INTELLIGENCE * categories.AIR * categories.TECH3 }}, #1
            { SIBC, 'HaveLessThanUnitsForMapSize', { {[256] = 2, [512] = 4, [1024] = 6, [2048] = 8, [4096] = 8}, categories.INTELLIGENCE * categories.AIR * categories.TECH3}},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.AIR * categories.FACTORY * categories.TECH3 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.INTELLIGENCE * categories.AIR * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
            { SBC, 'NoRushTimeCheck', { 600 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'Sorian T3 Air Scout - Lower Pri',
        PlatoonTemplate = 'T3AirScout',
        Priority = 701, #700,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 5, categories.INTELLIGENCE * categories.AIR * categories.TECH3 }}, #3
            { SIBC, 'HaveLessThanUnitsForMapSize', { {[256] = 4, [512] = 6, [1024] = 8, [2048] = 10, [4096] = 12}, categories.INTELLIGENCE * categories.AIR * categories.TECH3}},
            { SBC, 'MapGreaterThan', { 500, 500 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.AIR * categories.FACTORY * categories.TECH3 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.INTELLIGENCE * categories.AIR * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
            { SBC, 'NoRushTimeCheck', { 600 }},
        },
        BuilderType = 'Air',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianAirScoutFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Sorian T1 Air Scout - No Build',
        PlatoonTemplate = 'T1AirScoutFormSorian',
        Priority = 650,
        BuilderConditions = {
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        PlatoonAddBehaviors = { 'AirUnitRefitSorian' },
        InstanceCount = 30,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T3 Air Scout - No Build',
        PlatoonTemplate = 'T3AirScoutFormSorian',
        Priority = 750,
        BuilderConditions = {
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        PlatoonAddPlans = { 'AirIntelToggle' },
        PlatoonAddBehaviors = { 'AirUnitRefitSorian' },
        InstanceCount = 30,
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianLandScoutFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'Sorian T1 Land Scout Initial',
        PlatoonTemplate = 'T1LandScout',
        Priority = 875,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY - categories.TECH1 }},
            { SBC, 'LessThanGameTime', { 600 } },
            { SBC, 'MapGreaterThan', {1000, 1000} },
            { SBC, 'IsIslandMap', { false } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.LAND * categories.SCOUT }},
            #{ UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.SCOUT * categories.LAND } },
            #{ IBC, 'BrainNotLowPowerMode', {} },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.05 }},
            { SBC, 'NoRushTimeCheck', { 600 }},
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'Sorian T1 Land Scout Initial - 10 x 10',
        PlatoonTemplate = 'T1LandScout',
        Priority = 875,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY - categories.TECH1 }},
            { SBC, 'LessThanGameTime', { 600 } },
            { SBC, 'MapLessThan', {1000, 1000} },
            { SBC, 'MapGreaterThan', {500, 500} },
            { SBC, 'IsIslandMap', { false } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.LAND * categories.SCOUT }},
            #{ UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.SCOUT * categories.LAND } },
            #{ IBC, 'BrainNotLowPowerMode', {} },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.05 }},
            { SBC, 'NoRushTimeCheck', { 600 }},
        },
        BuilderType = 'Land',
    },
        Builder {
        BuilderName = 'Sorian T1 Land Scout Initial - 5 x 5',
        PlatoonTemplate = 'T1LandScout',
        Priority = 875,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY - categories.TECH1 }},
            { SBC, 'LessThanGameTime', { 600 } },
            { SBC, 'MapLessThan', {500, 500} },
            { SBC, 'IsIslandMap', { false } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.LAND * categories.SCOUT }},
            #{ UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.SCOUT * categories.LAND } },
            #{ IBC, 'BrainNotLowPowerMode', {} },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.05 }},
            { SBC, 'NoRushTimeCheck', { 600 }},
        },
        BuilderType = 'Land',
    },
    #Builder {
    #    BuilderName = 'Sorian T1 Land Scout',
    #    PlatoonTemplate = 'T1LandScout',
    #    Priority = 850,
    #    BuilderConditions = {
    #        #{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY - categories.TECH1 }},
    #        { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.LAND * categories.SCOUT }},
    #        #{ UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.SCOUT * categories.LAND } },
    #        { IBC, 'BrainNotLowPowerMode', {} },
    #        #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
    #    },
    #    BuilderType = 'Land',
    #},
    Builder {
        BuilderName = 'Sorian T1 Land Scout Ratio Build',
        PlatoonTemplate = 'T1LandScout',
        Priority = 827,
        BuilderConditions = {
            { UCBC, 'HaveUnitRatio', { 0.10, categories.LAND * categories.SCOUT, '<=', categories.LAND * categories.MOBILE - categories.ENGINEER }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.SCOUT * categories.LAND } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SBC, 'GreaterThanGameTime', { 600 } },
            { SBC, 'IsIslandMap', { false } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.05 }},
            { SBC, 'NoRushTimeCheck', { 600 }},
        },
        BuilderType = 'Land',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianLandScoutFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Sorian T1 Land Scout Form init',
        BuilderConditions = {
            #{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY * categories.LAND - categories.TECH1 }},
            { SBC, 'LessThanGameTime', { 300 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        PlatoonTemplate = 'T1LandScoutFormSorian',
        Priority = 10000, #725,
        InstanceCount = 30,
        BuilderData = {
            UseCloak = false,
        },
        LocationType = 'LocationType',
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T1 Land Scout Form',
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.FACTORY * categories.AIR * categories.TECH3 }},
            { SBC, 'GreaterThanGameTime', { 300 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        PlatoonTemplate = 'T1LandScoutFormSorian',
        Priority = 10000, #725,
        InstanceCount = 30,
        BuilderData = {
            UseCloak = true,
        },
        LocationType = 'LocationType',
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianRadarEngineerBuilders',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T1 Radar Engineer',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 960,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, categories.ENGINEER - categories.COMMAND - categories.TECH1 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, (categories.RADAR + categories.OMNI) * categories.STRUCTURE}},
            { SIBC, 'GreaterThanEconIncome',  { 0.5, 15 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1Radar',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T1 Radar Engineer - T2',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 960,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, categories.ENGINEER * categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, (categories.RADAR + categories.OMNI) * categories.STRUCTURE}},
            { SIBC, 'GreaterThanEconIncome',  { 0.5, 15 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1Radar',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T1 Radar Engineer - T3',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 960,
        BuilderConditions = {
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, (categories.RADAR + categories.OMNI) * categories.STRUCTURE}},
            { SIBC, 'GreaterThanEconIncome',  { 0.5, 15 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1Radar',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2 Radar Engineer',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, categories.ENGINEER - categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, (categories.RADAR + categories.OMNI) * categories.STRUCTURE}},
            { SIBC, 'GreaterThanEconIncome',  { 7.5, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T2Radar',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Omni Engineer',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.OMNI * categories.STRUCTURE } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'GreaterThanEconIncome',  { 15, 400}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.OMNI * categories.STRUCTURE, 'RADAR STRUCTURE' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T3Radar',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianRadarUpgradeBuildersMain',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Sorian T1 Radar Upgrade',
        PlatoonTemplate = 'T1RadarUpgrade',
        Priority = 200,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconIncome',  { 2, 100 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.RADAR * categories.STRUCTURE * categories.TECH2, 'RADAR STRUCTURE' }},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.25 }},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.RADAR * categories.STRUCTURE * categories.TECH2 } },
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
        FormDebugFunction = function()
            local test = false
        end,
    },
    Builder {
        BuilderName = 'Sorian T2 Radar Upgrade',
        PlatoonTemplate = 'T2RadarUpgrade',
        Priority = 300,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconIncome',  { 9, 500}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.OMNI * categories.STRUCTURE } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.25 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.OMNI * categories.STRUCTURE } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.OMNI * categories.STRUCTURE, 'RADAR STRUCTURE' } },
        },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianSonarEngineerBuilders',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T1 Sonar Engineer',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, categories.ENGINEER - categories.COMMAND - categories.TECH1} },
            { MABC, 'MarkerLessThanDistance',  { 'Naval Area', 200} },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.SONAR * categories.STRUCTURE } },
            { SIBC, 'GreaterThanEconIncome',  { 0.5, 150 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1Sonar',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2 Sonar Engineer',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, categories.ENGINEER * categories.TECH3 } },
            { MABC, 'MarkerLessThanDistance',  { 'Naval Area', 200}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.SONAR * categories.STRUCTURE } },
            { SIBC, 'GreaterThanEconIncome',  { 0.5, 150 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T2Sonar',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianCounterIntelBuilders',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T2 Counter Intel Near Factory',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 0,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH2}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.COUNTERINTELLIGENCE * categories.TECH2}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'FACTORY -NAVAL',
                AdjacencyDistance = 100,
                BuildClose = false,
                BuildStructures = {
                    'T2RadarJammer',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianRadarUpgradeBuildersExpansion',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Sorian T1 Radar Upgrade Expansion',
        PlatoonTemplate = 'T1RadarUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconIncome',  { 4, 200 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.RADAR * categories.STRUCTURE * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.25 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.RADAR * categories.TECH2 * categories.STRUCTURE } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.RADAR * categories.STRUCTURE * categories.TECH2, 'RADAR STRUCTURE' }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T2 Radar Upgrade Expansion',
        PlatoonTemplate = 'T2RadarUpgrade',
        Priority = 300,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconIncome',  { 9, 1000}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.OMNI * categories.STRUCTURE } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.25 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.OMNI * categories.STRUCTURE } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.OMNI * categories.STRUCTURE, 'RADAR STRUCTURE' } },
        },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianSonarUpgradeBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Sorian T1 Sonar Upgrade',
        PlatoonTemplate = 'T1SonarUpgrade',
        Priority = 200,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SONAR * categories.TECH1}},
            { SIBC, 'GreaterThanEconIncome',  { 5, 15}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T2 Sonar Upgrade',
        PlatoonTemplate = 'T2SonarUpgrade',
        Priority = 300,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SONAR * categories.TECH2}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.SONAR * categories.TECH3}},
            { SIBC, 'GreaterThanEconIncome',  { 10, 600}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianSonarUpgradeBuildersSmall',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Sorian T1 Sonar Upgrade Small',
        PlatoonTemplate = 'T1SonarUpgrade',
        Priority = 200,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SONAR * categories.TECH2}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { SIBC, 'GreaterThanEconIncome',  { 5, 15}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T2 Sonar Upgrade Small',
        PlatoonTemplate = 'T2SonarUpgrade',
        Priority = 300,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SONAR * categories.TECH3}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.SONAR * categories.TECH3}},
            { SIBC, 'GreaterThanEconIncome',  { 10, 600}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
    },
}
