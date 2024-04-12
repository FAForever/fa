--***************************************************************************
--*
--**  File     :  /lua/ai/AIIntelBuilders.lua
--**
--**  Summary  : Default economic builders for skirmish
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local BBTmplFile = '/lua/basetemplates.lua'
local BuildingTmpl = 'BuildingTemplates'
local BaseTmpl = 'BaseTemplates'
local ExBaseTmpl = 'ExpansionBaseTemplates'
local Adj2x2Tmpl = 'Adjacency2x2'
local UCBC = '/lua/editor/unitcountbuildconditions.lua'
local MIBC = '/lua/editor/miscbuildconditions.lua'
local MABC = '/lua/editor/markerbuildconditions.lua'
local OAUBC = '/lua/editor/otherarmyunitcountbuildconditions.lua'
local EBC = '/lua/editor/economybuildconditions.lua'
local PCBC = '/lua/editor/platooncountbuildconditions.lua'
local SAI = '/lua/scenarioplatoonai.lua'
local TBC = '/lua/editor/threatbuildconditions.lua'
local IBC = '/lua/editor/instantbuildconditions.lua'
local PlatoonFile = '/lua/platoon.lua'

---@alias BuilderGroupsIntel 'AirScoutFactoryBuilders' | 'AirScoutFormBuilders' | 'LandScoutFactoryBuilders' | 'LandScoutFormBuilders' | 'RadarEngineerBuilders' | 'RadarUpgradeBuildersMain' | 'SonarEngineerBuilders' | 'SonarUpgradeBuilders' | 'CounterIntelBuilders' | 'RadarUpgradeBuildersExpansion' | 'SonarUpgradeBuildersSmall' | 'AeonOpticsEngineerBuilders' | 'CybranOpticsEngineerBuilders' | 

BuilderGroup {
    BuilderGroupName = 'AirScoutFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'T1 Air Scout',
        PlatoonTemplate = 'T1AirScout',
        Priority = 700,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.SCOUT * categories.AIR}}, --DUNCAN - was 8
            --{ UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.FACTORY }},
            --{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.TECH2 * categories.FACTORY * categories.AIR } },
            --{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.AIR * categories.FACTORY } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.SCOUT * categories.AIR } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T1 Air Scout - Lower Pri',
        PlatoonTemplate = 'T1AirScout',
        Priority = 500,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.SCOUT * categories.AIR}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.TECH2 * categories.FACTORY * categories.AIR } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.SCOUT * categories.AIR } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T2 Air Scout',
        PlatoonTemplate = 'T2AirScout',
        Priority = 600,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.SCOUT * categories.AIR}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.TECH3 * categories.FACTORY * categories.AIR } },
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.AIR * categories.FACTORY * categories.TECH2 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.SCOUT * categories.AIR } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T2 Air Scout - Lower Pri',
        PlatoonTemplate = 'T2AirScout',
        Priority = 650,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.SCOUT * categories.AIR}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.TECH3 * categories.FACTORY * categories.AIR } },
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.AIR * categories.FACTORY * categories.TECH2 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.SCOUT * categories.AIR } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T3 Air Scout',
        PlatoonTemplate = 'T3AirScout',
        Priority = 700,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.INTELLIGENCE * categories.AIR * categories.TECH3 }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.INTELLIGENCE * categories.AIR } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T3 Air Scout - Lower Pri',
        PlatoonTemplate = 'T3AirScout',
        Priority = 700,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.INTELLIGENCE * categories.AIR * categories.TECH3 }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.INTELLIGENCE * categories.AIR } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
        BuilderType = 'Air',
    },
}

BuilderGroup {
    BuilderGroupName = 'AirScoutFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T1 Air Scout - No Build',
        PlatoonTemplate = 'T1AirScoutForm',
        Priority = 650,
        InstanceCount = 3,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T3 Air Scout - No Build',
        PlatoonTemplate = 'T3AirScoutForm',
        Priority = 750,
        PlatoonAddBehaviors = { 'AirUnitRefit' },
        InstanceCount = 3,
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'LandScoutFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'T1 Land Scout Initial',
        PlatoonTemplate = 'T1LandScout',
        Priority = 875,
        BuilderConditions = {
            --{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY - categories.TECH1 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.LAND * categories.SCOUT }}, --DUNCAN - was 4
            --{ UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.SCOUT * categories.LAND } },
            { IBC, 'BrainNotLowPowerMode', {} },
            --{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
        BuilderType = 'Land',
    },
    --Builder {
    --    BuilderName = 'T1 Land Scout',
    --    PlatoonTemplate = 'T1LandScout',
    --    Priority = 850,
    --    BuilderConditions = {
    --        --{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY - categories.TECH1 }},
    --        { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.LAND * categories.SCOUT }},
    --        --{ UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.SCOUT * categories.LAND } },
    --        { IBC, 'BrainNotLowPowerMode', {} },
    --        --{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
    --    },
    --    BuilderType = 'Land',
    --},
    Builder {
        BuilderName = 'T1 Land Scout Ratio Build',
        PlatoonTemplate = 'T1LandScout',
        Priority = 700,
        BuilderConditions = {
            { UCBC, 'HaveUnitRatio', { 0.1, categories.LAND * categories.SCOUT, '<=', categories.LAND * categories.MOBILE - categories.ENGINEER }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.SCOUT * categories.LAND } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.2 }}, --DUNCAN - was 0.9
        },
        BuilderType = 'Land',
    },
}

BuilderGroup {
    BuilderGroupName = 'LandScoutFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T1 Land Scout Form',
        BuilderConditions = {
            --{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY * categories.LAND - categories.TECH1 }},
        },
        PlatoonTemplate = 'T1LandScoutForm',
        Priority = 730,
        InstanceCount = 1,
        LocationType = 'LocationType',
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T1 Land Scout Form Multi',
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, categories.SCOUT * categories.LAND } },
        },
        PlatoonTemplate = 'T1LandScoutForm',
        Priority = 725,
        InstanceCount = 2,
        LocationType = 'LocationType',
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'RadarEngineerBuilders',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T1 Radar Engineer',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 950,
        BuilderConditions = {
            --DUNCAN - commented out
            --{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, categories.ENGINEER - categories.COMMAND - categories.TECH1 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, (categories.RADAR + categories.OMNI) * categories.STRUCTURE}},
            { EBC, 'GreaterThanEconIncomeOverTime',  { 0.5, 15 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.7, 1.05 }}, --DUNCAN - was 0.9,1.2
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
        BuilderName = 'T2 Radar Engineer',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, categories.ENGINEER - categories.TECH3 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, (categories.RADAR + categories.OMNI) * categories.STRUCTURE}},
            { EBC, 'GreaterThanEconIncomeOverTime',  { 7.5, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
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
        BuilderName = 'T3 Omni Engineer',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.STRUCTURE * ( categories.RADAR + categories.OMNI ) } },
            { EBC, 'GreaterThanEconIncomeOverTime',  { 15, 400}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * ( categories.RADAR + categories.OMNI ) } },
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
    BuilderGroupName = 'RadarUpgradeBuildersMain',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T1 Radar Upgrade',
        PlatoonTemplate = 'T1RadarUpgrade',
        Priority = 200,
        BuilderConditions = {
            { EBC, 'GreaterThanEconIncomeOverTime',  { 2, 100 }},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.RADAR * categories.STRUCTURE } },
        },
        BuilderType = 'Any',
        FormDebugFunction = function()
            local test = false
        end,
    },
    Builder {
        BuilderName = 'T2 Radar Upgrade',
        PlatoonTemplate = 'T2RadarUpgrade',
        Priority = 300,
        BuilderConditions = {
            { EBC, 'GreaterThanEconIncomeOverTime',  { 9, 500}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * ( categories.RADAR + categories.OMNI ) } },
        },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'SonarEngineerBuilders',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T1 Sonar Engineer',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, categories.ENGINEER - categories.COMMAND - categories.TECH1} },
            { MABC, 'MarkerLessThanDistance',  { 'Naval Area', 200} },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.SONAR * categories.STRUCTURE } },
            { EBC, 'GreaterThanEconIncomeOverTime',  { 0.5, 150 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
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
        BuilderName = 'T2 Sonar Engineer',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, categories.ENGINEER * categories.TECH3 } },
            { MABC, 'MarkerLessThanDistance',  { 'Naval Area', 200}},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.SONAR * categories.STRUCTURE } },
            { EBC, 'GreaterThanEconIncomeOverTime',  { 0.5, 15 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
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
    BuilderGroupName = 'SonarUpgradeBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T1 Sonar Upgrade',
        PlatoonTemplate = 'T1SonarUpgrade',
        Priority = 200,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SONAR * categories.TECH1}},
            { EBC, 'GreaterThanEconIncomeOverTime',  { 5, 15}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Sonar Upgrade',
        PlatoonTemplate = 'T2SonarUpgrade',
        Priority = 300,
        BuilderConditions = {
            { MIBC, 'FactionIndex', { 1, 2, 3, 5 }}, -- 1: UEF, 2: Aeon, 3: Cybran, 4: Seraphim, 5: Nomads
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SONAR * categories.TECH2}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.SONAR * categories.TECH3}},
            { EBC, 'GreaterThanEconIncomeOverTime',  { 10, 600}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
        },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'CounterIntelBuilders',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T2 Counter Intel Near Factory',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 0,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH2}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.COUNTERINTELLIGENCE * categories.TECH2}},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = categories.FACTORY * categories.STRUCTURE - categories.NAVAL,
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
    BuilderGroupName = 'RadarUpgradeBuildersExpansion',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T1 Radar Upgrade Expansion',
        PlatoonTemplate = 'T1RadarUpgrade',
        Priority = 200,
        BuilderConditions = {
            { EBC, 'GreaterThanEconIncomeOverTime',  { 4, 100 }},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'ShouldUpgradeRadar', {'LocationType', 'TECH2'}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.RADAR * categories.TECH2 * categories.STRUCTURE } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Radar Upgrade Expansion',
        PlatoonTemplate = 'T2RadarUpgrade',
        Priority = 1, --DUNCAN - changed to 1
        BuilderConditions = {
            { EBC, 'GreaterThanEconIncomeOverTime',  { 9, 750}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'ShouldUpgradeRadar', {'LocationType', 'TECH3'}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.OMNI * categories.STRUCTURE } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * ( categories.RADAR + categories.OMNI ) } },
        },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'SonarUpgradeBuildersSmall',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T1 Sonar Upgrade Small',
        PlatoonTemplate = 'T1SonarUpgrade',
        Priority = 200,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SONAR * categories.TECH2}},
            { EBC, 'GreaterThanEconIncomeOverTime',  { 5, 15}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Sonar Upgrade Small',
        PlatoonTemplate = 'T2SonarUpgrade',
        Priority = 300,
        BuilderConditions = {
            { MIBC, 'FactionIndex', { 1, 2, 3, 5 }}, -- 1: UEF, 2: Aeon, 3: Cybran, 4: Seraphim, 5: Nomads
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SONAR * categories.TECH3}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.SONAR * categories.TECH3}},
            { EBC, 'GreaterThanEconIncomeOverTime',  { 10, 600}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'AeonOpticsEngineerBuilders',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T3 Optics Construction Aeon',
        PlatoonTemplate = 'AeonT3EngineerBuilder',
        Priority = 750,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.OPTICS * categories.AEON}},
            { EBC, 'GreaterThanEconIncomeOverTime', { 12, 1500}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = categories.ENERGYPRODUCTION,
                AdjacencyDistance = 100,
                BuildClose = false,
                BuildStructures = {
                    'T3Optics',
                },
                Location = 'LocationType',
            }
        }
    }
}

BuilderGroup {
    BuilderGroupName = 'CybranOpticsEngineerBuilders',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T3 Optics Construction Cybran',
        PlatoonTemplate = 'CybranT3EngineerBuilder',
        Priority = 750,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.OPTICS * categories.CYBRAN}},
            { EBC, 'GreaterThanEconIncomeOverTime', { 12, 1500}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = categories.ENERGYPRODUCTION,
                AdjacencyDistance = 100,
                BuildClose = false,
                BuildStructures = {
                    'T3Optics',
                },
                Location = 'LocationType',
            }
        }
    }
}