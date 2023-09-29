--***************************************************************************
--*
--**  File     :  /lua/ai/AIEconomicBuilders.lua
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
local IBC = '/lua/editor/instantbuildconditions.lua'
local OAUBC = '/lua/editor/otherarmyunitcountbuildconditions.lua'
local EBC = '/lua/editor/economybuildconditions.lua'
local PCBC = '/lua/editor/platooncountbuildconditions.lua'
local SAI = '/lua/scenarioplatoonai.lua'
local TBC = '/lua/editor/threatbuildconditions.lua'
local PlatoonFile = '/lua/platoon.lua'

---@alias BuilderGroupsEconomic 'EngineerFactoryBuilders' | 'Engineer Transfers' | 'Land Rush Initial ACU Builders' | 'Balanced Rush Initial ACU Builders' | 'Air Rush Initial ACU Builders' | 'Naval Rush Initial ACU Builders' | 'Default Initial ACU Builders' | 'Easy Initial ACU Builders' | 'ACUBuilders' | 'ACUUpgrades - Gun improvements' | 'ACUUpgrades - Tech 2 Engineering' | 'ACUUpgrades - Shields' | 'ACUUpgrades' | 'T1EngineerBuilders' | 'T2EngineerBuilders' | 'T3EngineerBuilders' | 'EngineerMassBuildersHighPri' | 'EngineerMassBuilders - Naval' | 'EngineerMassBuildersLowerPri' | 'EngineerMassBuildersMidPriSingle' | 'EngineerEnergyBuilders' | 'EngineerEnergyBuildersExpansions' | 'EngineeringSupportBuilder'

BuilderGroup {
    BuilderGroupName = 'EngineerFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    -- ============
    --    TECH 1
    -- ============
    Builder {
        BuilderName = 'T1 Engineer Disband - Init',
        PlatoonTemplate = 'T1BuildEngineer',
        Priority = 900,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 4, categories.ENGINEER * categories.TECH1 }}, --DUNCAN - was 3
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH1 } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech1' } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'T1 Engineer Power',
        PlatoonTemplate = 'T1BuildEngineer',
        Priority = 850,
        BuilderConditions = {
            { EBC, 'LessThanEnergyTrendOverTime', { 0.0 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech1' } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'T1 Engineer Disband - Filler 1',
        PlatoonTemplate = 'T1BuildEngineer',
        Priority = 800,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 9, categories.ENGINEER * categories.TECH1 }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH1 } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech1' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'T1 Engineer Disband - Filler 2',
        PlatoonTemplate = 'T1BuildEngineer',
        Priority = 700,
        BuilderConditions = {
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1} },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH1 } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech1' } },
            { IBC, 'BrainNotLowMassMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'All',
    },

    -- ============
    --    TECH 2
    -- ============
    Builder {
        BuilderName = 'T2 Engineer Disband - Init',
        PlatoonTemplate = 'T2BuildEngineer',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH2 }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH2 } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech2' } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'T2 Engineer Power',
        PlatoonTemplate = 'T2BuildEngineer',
        Priority = 851,
        BuilderConditions = {
            { EBC, 'LessThanEnergyTrendOverTime', { 0.0 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER  } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech2' } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'T2 Engineer Disband - Filler 1',
        PlatoonTemplate = 'T2BuildEngineer',
        Priority = 800,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 6, categories.ENGINEER * categories.TECH2 }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH2 } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech2' } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.95, 1.2 } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'T2 Engineer Disband - Filler 2',
        PlatoonTemplate = 'T2BuildEngineer',
        Priority = 700,
        BuilderConditions = {
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.95, 1.2} },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH2 } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech2' } },
            { IBC, 'BrainNotLowMassMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'All',
    },

    -- ============
    --    TECH 3
    -- ============
    Builder {
        BuilderName = 'T3 Engineer Disband - Init',
        PlatoonTemplate = 'T3BuildEngineer',
        Priority = 950,
        BuilderConditions = {
            { UCBC,'EngineerLessAtLocation', { 'LocationType', 6, categories.ENGINEER * categories.TECH3 }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH3 } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech3' } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'T3 Engineer Power',
        PlatoonTemplate = 'T3BuildEngineer',
        Priority = 852,
        BuilderConditions = {
            { EBC, 'LessThanEnergyTrendOverTime', { 0.0 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER  } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech3' } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'T3 Engineer Disband - Filler',
        PlatoonTemplate = 'T3BuildEngineer',
        Priority = 900,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 9, categories.ENGINEER * categories.TECH3 }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH3 } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech3' } },
            --{ UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'T3 Engineer Disband - Filler 2',
        PlatoonTemplate = 'T3BuildEngineer',
        Priority = 800,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 12, categories.ENGINEER * categories.TECH3 }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH3 } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech3' } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.95, 1.2 } },
            { IBC, 'BrainNotLowMassMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'T3 Engineer Disband - Filler 3',
        PlatoonTemplate = 'T3BuildEngineer',
        Priority = 700,
        BuilderConditions = {
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.95, 1.2 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ENGINEER * categories.TECH3 } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech3' } },
            { IBC, 'BrainNotLowMassMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'All',
    },

    -- ====================
    --    SUB COMMANDERS
    -- ====================
    Builder {
        BuilderName = 'T3 Sub Commander',
        PlatoonTemplate = 'T3LandSubCommander',
        Priority = 950, --DUNCAN - was 900
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.EXPERIMENTAL}}, --DUNCAN - Added
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 } }, --DUNCAN - was 0.95, 1.3
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'SCU' } },
            { IBC, 'BrainNotLowMassMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Gate',
    },
}

BuilderGroup {
    BuilderGroupName = 'Engineer Transfers',
    BuildersType = 'EngineerBuilder',

    Builder {
        BuilderName = 'T2 Engineer Transfer to Main',
        PlatoonTemplate = 'T2EngineerTransfer',
        Priority = 950,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'MAIN', 2, categories.ENGINEER * ( categories.TECH2 + categories.TECH3 ) } },
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, categories.ENGINEER * ( categories.TECH2 + categories.TECH3 ) } },
        },
        BuilderData = {
            LocationType = 'MAIN',
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T3 Engineer Transfer to Main',
        PlatoonTemplate = 'T3EngineerTransfer',
        Priority = 950,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'MAIN', 2, categories.ENGINEER * categories.TECH3 } },
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, categories.ENGINEER * categories.TECH3 } },
        },
        BuilderData = {
            LocationType = 'MAIN',
        },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'Land Rush Initial ACU Builders',
    BuildersType = 'EngineerBuilder',

    -- Initial builder
    Builder {
        BuilderName = 'CDR Initial Land Rush',
        PlatoonAddBehaviors = { 'CommanderBehaviorImproved', },
        PlatoonTemplate = 'CommanderInitialBuilder',
        Priority = 1000,
        BuilderConditions = {
                { IBC, 'NotPreBuilt', {}},
            },
        InstantCheck = true,
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Construction = {
                BaseTemplateFile = '/lua/AI/AIBaseTemplates/ACUBaseTemplate.lua',
                BaseTemplate = 'ACUBaseTemplate',
            }
        }
    },
    Builder {
        BuilderName = 'CDR Initial PreBuilt Land Rush',
        PlatoonAddBehaviors = { 'CommanderBehaviorImproved', },
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 1000,
        BuilderConditions = {
                { IBC, 'PreBuiltBase', {}},
            },
        InstantCheck = true,
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1LandFactory',
                    'T1AirFactory',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1AirFactory',
                    'T1LandFactory',
                    'T1LandFactory',
                    'T1LandFactory',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                }
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'Balanced Rush Initial ACU Builders',
    BuildersType = 'EngineerBuilder',

    -- Initial builder
    Builder {
        BuilderName = 'CDR Initial Balanced',
        PlatoonAddBehaviors = { 'CommanderBehaviorImproved', },
        PlatoonTemplate = 'CommanderInitialBuilder',
        Priority = 1000,
        BuilderConditions = {
                { IBC, 'NotPreBuilt', {}},
            },
        InstantCheck = true,
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Construction = {
                BaseTemplateFile = '/lua/AI/AIBaseTemplates/ACUBaseTemplate.lua',
                BaseTemplate = 'ACUBaseTemplate',
            }
        }
    },
    Builder {
        BuilderName = 'CDR Initial PreBuilt Balanced',
        PlatoonAddBehaviors = { 'CommanderBehaviorImproved', },
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 1000,
        BuilderConditions = {
                { IBC, 'PreBuiltBase', {}},
            },
        InstantCheck = true,
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1LandFactory',
                    'T1AirFactory',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1AirFactory',
                    'T1LandFactory',
                    'T1LandFactory',
                    'T1LandFactory',
                }
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'Air Rush Initial ACU Builders',
    BuildersType = 'EngineerBuilder',

    -- Initial builder
    Builder {
        BuilderName = 'CDR Initial Air Rush',
        PlatoonAddBehaviors = { 'CommanderBehaviorImproved', },
        PlatoonTemplate = 'CommanderInitialBuilder',
        Priority = 1000,
        BuilderConditions = {
                { IBC, 'NotPreBuilt', {}},
            },
        InstantCheck = true,
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Construction = {
                BaseTemplateFile = '/lua/AI/AIBaseTemplates/ACUBaseTemplate.lua',
                BaseTemplate = 'ACUBaseTemplate',
            }
        }
    },
    Builder {
        BuilderName = 'CDR Initial PreBuilt Air Rush',
        PlatoonAddBehaviors = { 'CommanderBehaviorImproved', },
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 1000,
        BuilderConditions = {
                { IBC, 'PreBuiltBase', {}},
            },
        InstantCheck = true,
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1LandFactory',
                    'T1AirFactory',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1AirFactory',
                    'T1LandFactory',
                    'T1LandFactory',
                    'T1LandFactory',
                }
            }
        }
    },
}

-- NAVAL RUSH
BuilderGroup {
    BuilderGroupName = 'Naval Rush Initial ACU Builders',
    BuildersType = 'EngineerBuilder',

    -- Initial builder
    Builder {
        BuilderName = 'CDR Initial Naval Rush',
        PlatoonAddBehaviors = { 'CommanderBehaviorImproved', },
        PlatoonTemplate = 'CommanderInitialBuilder',
        Priority = 1000,
        BuilderConditions = {
                { IBC, 'NotPreBuilt', {}},
            },
        InstantCheck = true,
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Construction = {
                BaseTemplateFile = '/lua/AI/AIBaseTemplates/ACUBaseTemplate.lua',
                BaseTemplate = 'ACUBaseTemplate',
            }
        }
    },
    Builder {
        BuilderName = 'CDR Initial PreBuilt Naval',
        PlatoonAddBehaviors = { 'CommanderBehaviorImproved', },
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 1000,
        BuilderConditions = {
                { IBC, 'PreBuiltBase', {}},
            },
        InstantCheck = true,
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1AirFactory',
                    'T1EnergyProduction',
                }
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'Easy Initial ACU Builders',
    BuildersType = 'EngineerBuilder',

    -- Initial builder
    Builder {
        BuilderName = 'CDR Initial Easy',
        PlatoonAddBehaviors = { 'CommanderBehaviorImproved', },
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 1000,
        BuilderConditions = {
                { IBC, 'NotPreBuilt', {}},
            },
        InstantCheck = true,
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Construction = {
                BuildStructures = {
                    --DUNCAN - Altered build order
                    'T1LandFactory',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    --'T1Resource',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    --'T1Resource',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1AirFactory',
                    'T1EnergyProduction',
                    'T1LandFactory',
                }
            }
        }
    },
    Builder {
        BuilderName = 'CDR Initial PreBuilt Easy',
        PlatoonAddBehaviors = { 'CommanderBehaviorImproved', },
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 1000,
        BuilderConditions = {
                { IBC, 'PreBuiltBase', {}},
            },
        InstantCheck = true,
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1AirFactory',
                    'T1EnergyProduction',
                }
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'Default Initial ACU Builders',
    BuildersType = 'EngineerBuilder',

    -- Initial builder
    Builder {
        BuilderName = 'CDR Initial Default',
        PlatoonAddBehaviors = { 'CommanderBehaviorImproved', },
        PlatoonTemplate = 'CommanderInitialBuilder',
        Priority = 1000,
        BuilderConditions = {
                { IBC, 'NotPreBuilt', {}},
            },
        InstantCheck = true,
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Construction = {
                BaseTemplateFile = '/lua/AI/AIBaseTemplates/ACUBaseTemplate.lua',
                BaseTemplate = 'ACUBaseTemplate',
            }
        }
    },
    Builder {
        BuilderName = 'CDR Initial PreBuilt Default',
        PlatoonAddBehaviors = { 'CommanderBehaviorImproved', },
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 1000,
        BuilderConditions = {
                { IBC, 'PreBuiltBase', {}},
            },
        InstantCheck = true,
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1AirFactory',
                    'T1EnergyProduction',
                }
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'ACUBuilders',
    BuildersType = 'EngineerBuilder',

    -- After initial
    -- Build on nearby mass locations
    Builder {
        BuilderName = 'CDR Single T1Resource',
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 0, --DUNCAN - was 950
        BuilderConditions = {
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 40, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T1Resource',
                },
            }
        }
    },
    Builder {
        BuilderName = 'CDR T1 Power',
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 875,
        BuilderConditions = {
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.5, 0.5 }}, --DUNCAN - was 0.8 mass check
            { EBC, 'LessThanEnergyTrendOverTime', { 10.0 } },
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, categories.ENGINEER * ( categories.TECH2 + categories.TECH3 ) } },
        },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                AdjacencyCategory = categories.FACTORY,
                BuildStructures = {
                    'T1EnergyProduction',
                },
            }
        }
    },

    Builder {
        BuilderName = 'CDR Base D',
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 0, categories.DEFENSE * categories.TECH1 }},
            { MABC, 'MarkerLessThanDistance',  { 'Rally Point', 50 }},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.95, 1.2 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BaseTemplate = ExBaseTmpl,
                BuildClose = false,
                NearMarkerType = 'Rally Point',
                ThreatMin = -5,
                ThreatMax = 5,
                ThreatRings = 0,
                BuildStructures = {
                    'T1GroundDefense',
                    'T1AADefense',
                }
            }
        }
    },

    -- CDR Assisting
    Builder {
        BuilderName = 'CDR Assist T2/T3 Power',
        PlatoonTemplate = 'CommanderAssist',
        Priority = 700,
        BuilderConditions = {
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 ) }},
            { EBC, 'LessThanEconEfficiencyOverTime', { 2.0, 1.5 }},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.7, 0.4 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssisteeType = 'Engineer',
                AssistLocation = 'LocationType',
                BeingBuiltCategories = {'ENERGYPRODUCTION TECH3', 'ENERGYPRODUCTION TECH2'},
                Time = 20,
            },
        }
    },
    Builder {
        BuilderName = 'CDR Assist Experimental', --DUNCAN - added
        PlatoonTemplate = 'CommanderAssist',
        Priority = 701,
        BuilderConditions = {
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, categories.EXPERIMENTAL }},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.6, 1.2 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssisteeType = 'Engineer',
                AssistLocation = 'LocationType',
                BeingBuiltCategories = {'EXPERIMENTAL'},
                Time = 30,
            },
        }
    },
    Builder {
        BuilderName = 'CDR Assist Engineer', --DUNCAN - added
        PlatoonTemplate = 'CommanderAssist',
        Priority = 500,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, categories.ALLUNITS } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.7, 1.1 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssisteeType = 'Engineer',
                AssistLocation = 'MAIN',
                Time = 30,
                BeingBuiltCategories = { 'SHIELD STRUCTURE', 'DEFENSE ANTIAIR', 'DEFENSE DIRECTFIRE',
                                        'DEFENSE ANTINAVY', 'EXPERIMENTAL', 'STRUCTURE NUKE',
                                        'STRUCTURE STRATEGIC', 'STRUCTURE ANTIMISSILE', 'ENERGYPRODUCTION DRAGBUILD',
                                        'FACTORY'},
            },
        }
    },
    --Builder {
    --    BuilderName = 'CDR Assist Factory',
    --    PlatoonTemplate = 'CommanderAssist',
    --    Priority = 500,
    --    BuilderConditions = {
    --        { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1} },
    --        { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, 'MOBILE' }},
    --        { IBC, 'BrainNotLowPowerMode', {} },
    --    },
    --    BuilderType = 'Any',
    --    BuilderData = {
    --        Assist = {
    --            AssistLocation = 'LocationType',
    --            AssisteeType = 'Factory',
    --            BuilderCategories = {'FACTORY',},
    --            PermanentAssist = true,
    --            Time = 20,
    --        },
    --    }
    --},
    --Builder {
    --    BuilderName = 'CDR Assist Factory Upgrade Tech 2',
    --    PlatoonTemplate = 'CommanderAssist',
    --    Priority = 800,
    --    BuilderConditions = {
    --        { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, 'TECH2 FACTORY' } },
    --        { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) } },
    --        { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 } },
    --        { IBC, 'BrainNotLowPowerMode', {} },
    --    },
    --    BuilderType = 'Any',
    --    BuilderData = {
    --        Assist = {
    --            AssistLocation = 'LocationType',
    --            AssisteeType = 'Factory',
    --            PermanentAssist = true,
    --            BeingBuiltCategories = {'FACTORY TECH2',},
    --            Time = 40,
    --        },
    --    }
    --},
    --Builder {
    --    BuilderName = 'CDR Assist Factory Upgrade Tech 3',
    --    PlatoonTemplate = 'CommanderAssist',
    --    Priority = 800,
    --    BuilderConditions = {
    --        { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, 'TECH3 FACTORY' } },
    --        { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'TECH3 FACTORY' } },
    --        { IBC, 'BrainNotLowPowerMode', {} },
    --        { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 } },
    --    },
    --    BuilderType = 'Any',
    --    BuilderData = {
    --        Assist = {
    --            AssistLocation = 'LocationType',
    --            AssisteeType = 'Factory',
    --            PermanentAssist = true,
    --            BeingBuiltCategories = {'FACTORY TECH3',},
    --            Time = 40,
    --        },
    --    }
    --},
    --Builder {
    --    BuilderName = 'CDR Assist Mass Extractor Upgrade',
    --    PlatoonTemplate = 'CommanderAssist',
    --    Priority = 0,
    --    BuilderConditions = {
    --        { UCBC, 'BuildingGreaterAtLocation', { 'LocationType', 0, 'TECH2 MASSEXTRACTION' } },
    --        { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 ) } },
    --        { IBC, 'BrainNotLowPowerMode', {} },
    --    },
    --    BuilderType = 'Any',
    --    BuilderData = {
    --        Assist = {
    --            AssisteeType = 'Structure',
    --            AssistLocation = 'LocationType',
    --            BeingBuiltCategories = {'MASSEXTRACTION'},
    --            Time = 30,
    --        },
    --    }
    --},
}

BuilderGroup { --DUNCAN - added group
    BuilderGroupName = 'ACUUpgrades - Gun improvements',
    BuildersType = 'EngineerBuilder',
    -- UEF
    Builder {
        BuilderName = 'UEF CDR Upgrade HeavyAntiMatter',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { MIBC, 'IsIsland', { false } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.FACTORY }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.MASSEXTRACTION }},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) } },
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { UCBC, 'CmdrHasUpgrade', { 'HeavyAntiMatterCannon', false }},
                { MIBC, 'FactionIndex', {1}},
                { MIBC, 'RandomNumber', {0, 6, 1, 10}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Enhancement = { 'HeavyAntiMatterCannon' },
        },

    },
    -- Aeon
    Builder {
        BuilderName = 'Aeon CDR Upgrade Crysalis',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { MIBC, 'IsIsland', { false } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.FACTORY }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.MASSEXTRACTION }},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) } },
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { UCBC, 'CmdrHasUpgrade', { 'CrysalisBeam', false }},
                { MIBC, 'FactionIndex', {2}},
                { MIBC, 'RandomNumber', {0, 6, 1, 10}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            TimeBetweenEnhancements = 20,
            Enhancement = { 'HeatSink', 'CrysalisBeam'},
        },
    },
    -- Cybran
    Builder {
        BuilderName = 'Cybran CDR Upgrade CoolingUpgrade',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { MIBC, 'IsIsland', { false } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.FACTORY }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.MASSEXTRACTION }},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) } },
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { UCBC, 'CmdrHasUpgrade', { 'CoolingUpgrade', false }},
                { MIBC, 'FactionIndex', {3}},
                { MIBC, 'RandomNumber', {0, 6, 1, 10}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Enhancement = { 'CoolingUpgrade'},
        },

    },
    -- Seraphim
    Builder {
        BuilderName = 'Seraphim CDR Upgrade RateOfFire',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { MIBC, 'IsIsland', { false } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.FACTORY }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.MASSEXTRACTION }},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) } },
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { UCBC, 'CmdrHasUpgrade', { 'RateOfFire', false }},
                { MIBC, 'FactionIndex', {4}},
                { MIBC, 'RandomNumber', {0, 6, 1, 10}},
            },
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderType = 'Any',
        BuilderData = {
            Enhancement = { 'RateOfFire' },
        },

    },
}

BuilderGroup {
    BuilderGroupName = 'ACUUpgrades - Tech 2 Engineering',
    BuildersType = 'EngineerBuilder',
    -- UEF
    Builder {
        BuilderName = 'UEF CDR Upgrade Adv Engi',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.TECH2 * categories.FACTORY }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.TECH2 * categories.MASSEXTRACTION }},
                --{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'AdvancedEngineering', false }},
                { MIBC, 'FactionIndex', {1}},
            },
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderType = 'Any',
        BuilderData = {
            Enhancement = { 'LeftPod', 'RightPod', 'AdvancedEngineering' },
        },
    },
    -- Aeon
    Builder {
        BuilderName = 'Aeon CDR Upgrade Adv Engi, replacing Crysalis',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.TECH2 * categories.FACTORY }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.TECH2 * categories.MASSEXTRACTION }},
                --{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'AdvancedEngineering', false }},
                { UCBC, 'CmdrHasUpgrade', { 'CrysalisBeam', true }},
                { MIBC, 'FactionIndex', {2}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Enhancement = { 'CrysalisBeamRemove', 'AdvancedEngineering'},
        },

    },
    Builder {
        BuilderName = 'Aeon CDR Upgrade Adv Engi',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.TECH2 * categories.FACTORY }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.TECH2 * categories.MASSEXTRACTION }},
                --{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'AdvancedEngineering', false }},
                { UCBC, 'CmdrHasUpgrade', { 'CrysalisBeam', false }},
                { MIBC, 'FactionIndex', {2}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Enhancement = { 'AdvancedEngineering'},
        },

    },
    -- Cybran
    Builder {
        BuilderName = 'Cybran CDR Upgrade Adv Engi, replacing cooling',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.TECH2 * categories.FACTORY }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.TECH2 * categories.MASSEXTRACTION }},
                --{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'AdvancedEngineering', false }},
                { UCBC, 'CmdrHasUpgrade', { 'CoolingUpgrade', true}},
                { MIBC, 'FactionIndex', {3}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Enhancement = { 'CoolingUpgradeRemove','AdvancedEngineering'},
        },

    },
     Builder {
        BuilderName = 'Cybran CDR Upgrade Adv Engi',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.TECH2 * categories.FACTORY }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.TECH2 * categories.MASSEXTRACTION }},
                --{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'AdvancedEngineering', false }},
                { UCBC, 'CmdrHasUpgrade', { 'CoolingUpgrade', false }},
                { MIBC, 'FactionIndex', {3}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Enhancement = { 'AdvancedEngineering'},
        },

    },
    -- Seraphim
    Builder {
        BuilderName = 'Seraphim CDR Upgrade Adv Engi',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.TECH2 * categories.FACTORY }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.TECH2 * categories.MASSEXTRACTION }},
                --{ EBC, 'GreaterThanEconStorageRatio', { 0.25, 0.25}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'AdvancedEngineering', false }},
                { MIBC, 'FactionIndex', {4}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Enhancement = { 'AdvancedEngineering' },
        },

    },
}

BuilderGroup {
    BuilderGroupName = 'ACUUpgrades - Shields',
    BuildersType = 'EngineerBuilder',
    -- UEF
    Builder {
        BuilderName = 'UEF CDR Upgrade Shield, replaceing right pod',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.FACTORY * categories.TECH3 }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.TECH3 * categories.MASSEXTRACTION }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * categories.TECH3 }},
                --{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'Shield', false }},
                { UCBC, 'CmdrHasUpgrade', { 'RightPod', true }},
                { MIBC, 'FactionIndex', {1}},
            },
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderType = 'Any',
        BuilderData = {
            Enhancement = { 'RightPodRemove', 'Shield' },
        },
    },
    Builder {
        BuilderName = 'UEF CDR Upgrade Shield',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.FACTORY * categories.TECH3 }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.TECH3 * categories.MASSEXTRACTION }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * categories.TECH3 }},
                --{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'Shield', false }},
                { UCBC, 'CmdrHasUpgrade', { 'RightPod', false }},
                { MIBC, 'FactionIndex', {1}},
            },
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderType = 'Any',
        BuilderData = {
            Enhancement = { 'Shield' },
        },
    },
    -- Aeon
    Builder {
        BuilderName = 'Aeon CDR Upgrade Shield',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.FACTORY * categories.TECH3 }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.TECH3 * categories.MASSEXTRACTION }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * categories.TECH3 }},
                --{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'Shield', false }},
                { MIBC, 'FactionIndex', {2}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Enhancement = { 'Shield' },
        },

    },
    -- Cybran
    Builder {
        BuilderName = 'Cybran CDR Upgrade Stealth and Cloak',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.FACTORY * categories.TECH3 }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.TECH3 * categories.MASSEXTRACTION }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.ENERGYPRODUCTION * categories.TECH3 }},
                --{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'CloakingGenerator', false }},
                { MIBC, 'FactionIndex', {3}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Enhancement = { 'StealthGenerator', 'CloakingGenerator', 'MicrowaveLaserGenerator'},
        },

    },
    -- Seraphim
    Builder {
        BuilderName = 'Seraphim CDR Upgrade AdvancedRegenAura',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.FACTORY * categories.TECH3 }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.TECH3 * categories.MASSEXTRACTION }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * categories.TECH3 }},
                --{ EBC, 'GreaterThanEconStorageRatio', { 0.25, 0.25}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { UCBC, 'CmdrHasUpgrade', { 'AdvancedRegenAura', false }},
                { MIBC, 'FactionIndex', {4}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Enhancement = { 'RegenAura', 'AdvancedRegenAura' },
        },

    },
    Builder {
        BuilderName = 'Seraphim CDR Upgrade AdvancedRegenAura, replace rate of fire',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.FACTORY * categories.TECH3 }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.TECH3 * categories.MASSEXTRACTION }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * categories.TECH3 }},
                --{ EBC, 'GreaterThanEconStorageRatio', { 0.25, 0.25}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { UCBC, 'CmdrHasUpgrade', { 'AdvancedRegenAura', false }},
                { UCBC, 'CmdrHasUpgrade', { 'RateOfFire', true }},
                { MIBC, 'FactionIndex', {4}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Enhancement = { 'RateOfFireRemove', 'RegenAura', 'AdvancedRegenAura' },
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'ACUUpgrades',
    BuildersType = 'EngineerBuilder',
    -- UEF
    Builder {
        BuilderName = 'UEF CDR Upgrade AdvEng - Pods',
        PlatoonTemplate = 'CommanderEnhance',
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 ) }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 ) }},
                { EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { MIBC, 'FactionIndex', {1}},
            },
        Priority = 0,
        BuilderType = 'Any',
        BuilderData = {
            Enhancement = { 'AdvancedEngineering', 'LeftPod', 'RightPod', 'ResourceAllocation'},
        },
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
    },
    Builder {
        BuilderName = 'UEF CDR Upgrade T3 Eng - Shields',
        PlatoonTemplate = 'CommanderEnhance',
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.FACTORY * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 )}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { MIBC, 'FactionIndex', {1}},
            },
        Priority = 0,
        BuilderType = 'Any',
        BuilderData = {
            Enhancement = { 'T3Engineering', 'RightPodRemove', 'Shield', 'ShieldGeneratorField'},
        },
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
    },

    -- Aeon
    Builder {
        BuilderName = 'Aeon CDR Upgrade AdvEng - Resource - Crysalis',
        PlatoonTemplate = 'CommanderEnhance',
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.FACTORY * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 )}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { MIBC, 'FactionIndex', {2}},
            },
        Priority = 0,
        BuilderType = 'Any',
        BuilderData = {
            Enhancement = { 'AdvancedEngineering', 'ResourceAllocation', 'CrysalisBeam'},
        },
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
    },
    Builder {
        BuilderName = 'Aeon CDR Upgrade T3 Eng - ResourceAdv - EnhSensor',
        PlatoonTemplate = 'CommanderEnhance',
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.FACTORY * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 )}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { MIBC, 'FactionIndex', {2}},
            },
        Priority = 0,
        BuilderType = 'Any',
        BuilderData = {
            Enhancement = { 'T3Engineering', 'ResourceAllocationAdvanced', 'EnhancedSensors'},
        },
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
    },

    -- Cybran
    Builder {
        BuilderName = 'Cybran CDR Upgrade AdvEng - Laser Gen',
        PlatoonTemplate = 'CommanderEnhance',
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.FACTORY * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 )}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { MIBC, 'FactionIndex', {3}},
            },
        Priority = 0,
        BuilderType = 'Any',
        BuilderData = {
            Enhancement = { 'AdvancedEngineering', 'MicrowaveLaserGenerator'},
        },
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
    },
    Builder {
        BuilderName = 'Cybran CDR Upgrade T3 Eng - Resource',
        PlatoonTemplate = 'CommanderEnhance',
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.FACTORY * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 )}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { MIBC, 'FactionIndex', {3}},
            },
        Priority = 0,
        BuilderType = 'Any',
        BuilderData = {
            Enhancement = { 'T3Engineering', 'ResourceAllocation'},
        },
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
    },

    -- Seraphim
    Builder {
        BuilderName = 'Seraphim CDR Upgrade AdvEng - Dmgstbl',
        PlatoonTemplate = 'CommanderEnhance',
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.FACTORY * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 )}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.25, 0.25}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { MIBC, 'FactionIndex', {4}},
            },
        Priority = 0,
        BuilderType = 'Any',
        BuilderData = {
            Enhancement = { 'AdvancedEngineering', 'DamageStabilization' },
        },
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
    },
    Builder {
        BuilderName = 'Seraphim CDR Upgrade T3 Eng - ResourceAdv - EnhSensor',
        PlatoonTemplate = 'CommanderEnhance',
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.FACTORY * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.5, 0.5}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { MIBC, 'FactionIndex', {4}},
            },
        Priority = 0,
        BuilderType = 'Any',
        BuilderData = {
            Enhancement = { 'T3Engineering' },
        },
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
    },
}

BuilderGroup {
    BuilderGroupName = 'T1EngineerBuilders',
    BuildersType = 'EngineerBuilder',
    -- =====================================
    --     T1 Engineer Resource Builders
    -- =====================================
    Builder {
        BuilderName = 'T1 Hydrocarbon Engineer Single',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1005,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.HYDROCARBON}},
                { UCBC, 'CanBuildOnHydroLessThanDistance', { 'LocationType', 160, -500, 0, 0, 'AntiSurface', 1 }},
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
    Builder {
        BuilderName = 'T1 Hydrocarbon Engineer',
        PlatoonTemplate = 'EngineerBuilder',
        --DUNCAN - Changed from 850
        Priority = 950,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.HYDROCARBON}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.MASSEXTRACTION}},
                { UCBC, 'CanBuildOnHydroLessThanDistance', { 'LocationType', 200, -500, 0, 0, 'AntiSurface', 1 }},
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
    Builder {
        BuilderName = 'T1 Engineer Reclaim',
        PlatoonTemplate = 'StateMachineEngineerT1',
        Priority = 1000,
        InstanceCount = 2,
        BuilderConditions = {
                { MIBC, 'ReclaimEnabledOnBrain', { }},
                { EBC, 'LessThanEconStorageRatio', { 0.75, 2.0}},
                { MIBC, 'ReclaimAvailableInGrid', { 'LocationType', }},
            },
        BuilderData = {
            LocationType = 'LocationType',
            SearchType   = 'MAIN',
            StateMachine = 'AIPlatoonAdaptiveReclaimBehavior',
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T1 Engineer Reclaim Excess',
        PlatoonTemplate = 'StateMachineEngineerT1',
        Priority = 3, --DUNCAN - was 1
        InstanceCount = 10,
        BuilderConditions = {
                { MIBC, 'ReclaimEnabledOnBrain', { }},
                { EBC, 'LessThanEconStorageRatio', { 0.75, 2.0}},
                { MIBC, 'ReclaimAvailableInGrid', { 'LocationType', true}},
            },
        BuilderData = {
            LocationType = 'LocationType',
            StateMachine = 'AIPlatoonAdaptiveReclaimBehavior',
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T1 Engineer Reclaim Old Pgens',
        PlatoonTemplate = 'EngineerBuilder',
        PlatoonAIPlan = 'ReclaimStructuresAI',
        Priority = 900,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.1, 1.1 }},
                { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, categories.TECH3 * categories.ENERGYPRODUCTION }},
                { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 0, categories.TECH1 * categories.ENERGYPRODUCTION * categories.DRAGBUILD - categories.HYDROCARBON }},
            },
        BuilderData = {
            Location = 'LocationType',
            Reclaim = { categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH1 * categories.DRAGBUILD - categories.HYDROCARBON },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T1 Engineer Find Unfinished',
        PlatoonTemplate = 'EngineerBuilder',
        PlatoonAIPlan = 'ManagerEngineerFindUnfinished',
        Priority = 1800,
        InstanceCount = 1,
        BuilderConditions = {
                { UCBC, 'UnfinishedUnits', { 'LocationType', categories.STRUCTURE}},
            },
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistUntilFinished = true,
                BeingBuiltCategories = {'STRUCTURE STRATEGIC, STRUCTURE ECONOMIC, STRUCTURE'},
                Time = 20,
            },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T1 Engineer Repair',
        PlatoonTemplate = 'EngineerBuilder',
        PlatoonAIPlan = 'RepairAI',
        Priority = 900,
        InstanceCount = 1,
        BuilderConditions = {
                { UCBC, 'DamagedStructuresInArea', { 'LocationType', }},
            },
        BuilderData = {
            LocationType = 'LocationType',
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T1 Mass Adjacency Engineer',
        PlatoonTemplate = 'EngineerBuilder',
        --DUNCAN - changed from 925
        Priority = 800,
        BuilderConditions = {
            --DUNCAN - changed from 1
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
            { MABC, 'MarkerLessThanDistance',  { 'Mass', 100, -3, 0, 0}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { UCBC, 'AdjacencyCheck', { 'LocationType', categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 ), 100, 'ueb1106' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 ),
                AdjacencyDistance = 100,
                BuildClose = false,
                ThreatMin = -3,
                ThreatMax = 0,
                ThreatRings = 0,
                BuildStructures = {
                    'MassStorage',
                }
            }
        }
    },
    Builder {
        BuilderName = 'T1 Energy Storage Engineer - initial',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 950,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1,  categories.ENERGYSTORAGE }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.ENERGYSTORAGE}},
            --{ UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, 'ENERGYSTORAGE' }},
            { UCBC, 'UnitCapCheckLess', { .7 } },
            --{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'EnergyStorage',
                },
            }
        }
    },
    Builder {
        BuilderName = 'T1 Energy Storage Engineer',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 950,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, categories.ENERGYSTORAGE }},
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, categories.ENERGYPRODUCTION * categories.TECH2 }},
            { UCBC, 'UnitCapCheckLess', { .7 } },
            { EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'EnergyStorage',
                },
            }
        }
    },
    Builder {
        BuilderName = 'T1 Energy Storage Engineer - T3 Energy Production',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 825,
        BuilderConditions = {
            { EBC, 'GreaterThanMassStorageCurrent', { 150 }},
            { EBC, 'LessThanEconEfficiencyOverTime', { 2.0, 1.3 }},
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 2, categories.ENERGYPRODUCTION * categories.TECH3 }}, --DUNCAN - was 0
            { UCBC, 'UnitCapCheckLess', { .7 } },
            { UCBC, 'AdjacencyCheck', { 'LocationType', categories.ENERGYPRODUCTION * categories.TECH3, 100, 'ueb1105' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = categories.ENERGYPRODUCTION * categories.TECH3,
                AdjacencyDistance = 100,
                BuildClose = false,
                BuildStructures = {
                    'EnergyStorage',
                    'EnergyStorage',
                    'EnergyStorage',
                    'EnergyStorage',
                },
            }
        }
    },

    -- =========================
    --     T1 ENGINEER ASSIST
    -- =========================
    Builder {
        BuilderName = 'T1 Engineer Assist Power',
        PlatoonTemplate = 'EngineerAssist',
        Priority = 950,
        BuilderConditions = {
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.7, 0.1 }},
            { EBC, 'LessThanEconEfficiencyOverTime', { 2.0, 1.3 }},
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, categories.ENERGYPRODUCTION }},
        },
        InstanceCount = 2,
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssistRange = 65,
                AssistUntilFinished = true,
                AssistClosestUnit = true,
                BeingBuiltCategories = {'ENERGYPRODUCTION TECH3', 'ENERGYPRODUCTION TECH2', 'ENERGYPRODUCTION'},
                AssisteeType = 'Engineer',
                AssisteeCategory = categories.ENGINEER,
            },
        }
    },

    Builder {
        BuilderName = 'T1 Engineer Assist T2 Factory Upgrade',
        PlatoonTemplate = 'EngineerAssist',
        Priority = 875,
        InstanceCount = 4,
        BuilderType = 'Any',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 1.0, 1.2 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1 }},
            { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, categories.FACTORY * categories.TECH2 }},
        },
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                PermanentAssist = true,
                BeingBuiltCategories = {'FACTORY TECH2'},
                AssisteeType = 'Factory',
                Time = 45,
            },
        }
    },
    Builder {
        BuilderName = 'T1 Engineer Assist Mass Upgrade',
        PlatoonTemplate = 'EngineerAssist',
        Priority = 850,
        InstanceCount = 2,
        BuilderType = 'Any',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 1.1, 1.2 }},
            { EBC, 'LessThanEconEfficiencyOverTime', { 1.5, 2.0 }},
            { UCBC, 'BuildingGreaterAtLocation', { 'LocationType', 0, categories.MASSEXTRACTION * (categories.TECH2 + categories.TECH3) }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 5, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 ) } },
        },
        BuilderData = {
            Assist = {
                AssisteeType = 'Structure',
                AssistLocation = 'LocationType',
                BeingBuiltCategories = {'MASSEXTRACTION TECH2', 'MASSEXTRACTION TECH3'},
                Time = 30,
            },
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'T2EngineerBuilders',
    BuildersType = 'EngineerBuilder',
    -- =====================================
    --     T2 Engineer Resource Builders
    -- =====================================
    Builder {
        BuilderName = 'T2 Mass Adjacency Engineer',
        PlatoonTemplate = 'T2EngineerBuilder',
        --DUNCAN - Changed from 850
        Priority = 0,
        BuilderConditions = {
            { MABC, 'MarkerLessThanDistance',  { 'Mass', 100, -3, 0, 0}},
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { UCBC, 'AdjacencyCheck', { 'LocationType', categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 ), 100, 'ueb1106' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 ),
                AdjacencyDistance = 100,
                BuildClose = false,
                ThreatMin = -3,
                ThreatMax = 0,
                ThreatRings = 0,
                BuildStructures = {
                    'MassStorage',
                }
            }
        }
    },
    Builder {
        BuilderName = 'T2 Engineer Reclaim Excess',
        PlatoonTemplate = 'StateMachineEngineerT2',
        Priority = 2, --DUNCAN - was 1
        InstanceCount = 10,
        BuilderConditions = {
                { MIBC, 'ReclaimEnabledOnBrain', { }},
                { EBC, 'LessThanEconStorageRatio', { 0.50, 2.0}},
                { MIBC, 'ReclaimAvailableInGrid', { 'LocationType', true}},
            },
        BuilderData = {
            LocationType = 'LocationType',
            ReclaimTime = 30,
            StateMachine = 'AIPlatoonAdaptiveReclaimBehavior',
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Engineer Reclaim Old Pgens',
        PlatoonTemplate = 'T2EngineerBuilder',
        PlatoonAIPlan = 'ReclaimStructuresAI',
        Priority = 900,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.1, 1.1 }},
                { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, categories.TECH3 * categories.ENERGYPRODUCTION}},
                { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 0, categories.TECH1 * categories.ENERGYPRODUCTION * categories.DRAGBUILD - categories.HYDROCARBON }},
            },
        BuilderData = {
            Location = 'LocationType',
            Reclaim = { categories.STRUCTURE * categories.ENERGYPRODUCTION * categories.TECH1 * categories.DRAGBUILD - categories.HYDROCARBON },
        },
        BuilderType = 'Any',
    },

    -- =========================
    --     T2 ENGINEER ASSIST
    -- =========================
    Builder {
        BuilderName = 'T2 Engineer Assist Energy',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 900,
        InstanceCount = 5,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'LessThanEconEfficiencyOverTime', { 2.0, 1.3 }},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.7, 0.1 } },
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 ) } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssistRange = 65,
                AssistUntilFinished = true,
                AssistClosestUnit = true,
                BeingBuiltCategories = {'ENERGYPRODUCTION TECH3', 'ENERGYPRODUCTION TECH2'},
                AssisteeType = 'Engineer',
                AssisteeCategory = categories.ENGINEER,
            },
        }
    },
    Builder {
        BuilderName = 'T2 Engineer Assist Factory',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 500,
        InstanceCount = 25,
        BuilderType = 'Any',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, categories.MOBILE } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 1.0, 1.1 }},
        },
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                PermanentAssist = true,
                BeingBuiltCategories = { 'MOBILE',},
                AssisteeType = 'Factory',
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'T2 Engineer Assist Transport',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 875,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 1.0, 1.1 }},
            { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, categories.TRANSPORTFOCUS } },
            
        },
        InstanceCount = 2,
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                PermanentAssist = false,
                BeingBuiltCategories = {'TRANSPORTFOCUS'},
                AssisteeType = 'Factory',
                Time = 60,
            },
        },
    },
    Builder {
        BuilderName = 'T2 Engineer Assist Engineer',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 500,
        InstanceCount = 15,
        BuilderType = 'Any',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.1 }},
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, categories.ALLUNITS } },
        },
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                PermanentAssist = true,
                BeingBuiltCategories = { 'ALLUNITS' },
                AssisteeType = 'Engineer',
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'T2 Engineer Assist T3 Factory Upgrade',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 975,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.1 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
            { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, categories.FACTORY * categories.TECH3 }},
        },
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                PermanentAssist = true,
                BeingBuiltCategories = {'FACTORY TECH3'},
                AssisteeType = 'Factory',
                Time = 60,
            },
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'T3EngineerBuilders',
    BuildersType = 'EngineerBuilder',
    -- =========================
    --     T3 ENGINEER BUILD
    -- =========================
    Builder {
        BuilderName = 'T3 Engineer Reclaim Excess',
        PlatoonTemplate = 'StateMachineEngineerT3',
        Priority = 0, --DUNCAN - was 1
        InstanceCount = 2, --DUNCAN - was 10
        BuilderConditions = {
            { MIBC, 'ReclaimEnabledOnBrain', { }},
            { EBC, 'LessThanEconStorageRatio', { 0.35, 2.0}},
            { MIBC, 'ReclaimAvailableInGrid', { 'LocationType', true}},
        },
        BuilderData = {
            LocationType = 'LocationType',
            ReclaimTime = 10,
            StateMachine = 'AIPlatoonAdaptiveReclaimBehavior',
        },
        BuilderType = 'Any',
    },
    -- =========================
    --     T3 ENGINEER ASSIST
    -- =========================
    Builder {
        BuilderName = 'T3 Engineer Assist T3 Energy Production',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 950,
        InstanceCount = 5,
        BuilderConditions = {
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, categories.ENERGYPRODUCTION * categories.TECH3 }},
            { EBC, 'LessThanEconEfficiencyOverTime', { 2, 1.3}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.7, 0.1 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssistRange = 65,
                AssistUntilFinished = true,
                AssistClosestUnit = true,
                BeingBuiltCategories = {'ENERGYPRODUCTION TECH3'},
                AssisteeType = 'Engineer',
                AssisteeCategory = categories.ENGINEER,
            },
        }
    },
    Builder {
        BuilderName = 'T3 Engineer Assist Transport',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 900,
        BuilderConditions = {
            { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, categories.TRANSPORTFOCUS } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.1 }},
        },
        InstanceCount = 2,
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                PermanentAssist = false,
                BeingBuiltCategories = {'TRANSPORTFOCUS'},
                AssisteeType = 'Factory',
                Time = 60,
            },
        },
    },
    Builder {
        BuilderName = 'T3 Engineer Assist Mass Fab',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 800,
        InstanceCount = 1,
        BuilderConditions = {
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'LessThanEconEfficiencyOverTime', { 1.0, 2.0}},
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.6, 1.1}},
                { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 1, categories.ENGINEER * categories.TECH3 }},
                { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, categories.MASSPRODUCTION * categories.TECH3 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                BeingBuiltCategories = { 'MASSPRODUCTION TECH3', },
                AssisteeType = 'Engineer',
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'T3 Engineer Assist Defenses',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 750,
        InstanceCount = 1,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 1.0, 1.1} },
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 1, categories.ENGINEER * categories.TECH3 }},
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, categories.STRUCTURE * categories.DEFENSE }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                BeingBuiltCategories = { 'STRUCTURE DEFENSE', },
                AssisteeType = 'Engineer',
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'T3 Engineer Assist Shields',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 750,
        InstanceCount = 2,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 1.0, 1.1} },
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, categories.STRUCTURE * categories.SHIELD }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                BeingBuiltCategories = { 'STRUCTURE SHIELD', },
                AssisteeType = 'Engineer',
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'T3 Engineer Assist Factory',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 700,
        InstanceCount = 20,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 1.0, 1.1} },
            { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, categories.MOBILE }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL } }, --DUNCAN - added
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                PermanentAssist = true,
                AssisteeType = 'Factory',
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'T3 Engineer Assist Engineer',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 700,
        InstanceCount = 20,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.1} }, --DUNCAN - was 1.0, 1.1
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, categories.STRUCTURE * categories.TECH3 + categories.EXPERIMENTAL }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                PermanentAssist = true,
                BeingBuiltCategories = { 'SHIELD STRUCTURE', 'EXPERIMENTAL', 'STRUCTURE NUKE',
                               'STRUCTURE STRATEGIC', 'STRUCTURE ANTIMISSILE', 'DEFENSE ANTIAIR TECH3',
                               'DEFENSE DIRECTFIRE TECH3', 'DEFENSE ANTINAVY', 'ENERGYPRODUCTION TECH2',},
                               --DUNCAN - different priorities
                AssisteeType = 'Engineer',
                Time = 60,
            },
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'EngineerMassBuildersHighPri',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T1ResourceEngineer 40',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1002,
        InstanceCount = 2,
        BuilderConditions = {
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 40, -500, 1, 0, 'AntiSurface', 1 }},
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
        BuilderName = 'T1ResourceEngineer 150',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1000,
        InstanceCount = 3,
        BuilderConditions = {
                --{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, categories.ENGINEER * (categories.TECH2 + categories.TECH3) }},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 150, -500, 1, 0, 'AntiSurface', 1 }},
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
        BuilderName = 'T1ResourceEngineer 250',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 970,
        InstanceCount = 3,
        BuilderConditions = {
                --{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, categories.ENGINEER * (categories.TECH2 + categories.TECH3) }},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 250, -500, 1, 0, 'AntiSurface', 1 }},
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
        BuilderName = 'T1ResourceEngineer 450',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 800,
        InstanceCount = 3,
        BuilderConditions = {
                --{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, categories.ENGINEER * (categories.TECH2 + categories.TECH3) }},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 450, -500, 1, 0, 'AntiSurface', 1 }},
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
        BuilderName = 'T1ResourceEngineer 1000',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 850,
        InstanceCount = 1,
        BuilderConditions = {
                --{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, categories.ENGINEER * (categories.TECH2 + categories.TECH3) }},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 1000, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            --NeedGuard = true,
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'T2 T2Resource Engineer 100', --DUNCAN - was 250.
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 975,
        InstanceCount = 1,
        BuilderConditions = {
                { UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH3 }},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 100, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource', --DUNCAN - change from T2
                }
            }
        }
    },
    Builder {
        BuilderName = 'T2 T2Resource Engineer 500',
        PlatoonTemplate = 'T2EngineerBuilder',
        --DUNCAN - Changed from 875
        Priority = 0,
        InstanceCount = 1,
        BuilderConditions = {
                { UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH3}},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 1000, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T2Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'T3 T3Resource Engineer 250 range',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 0, --DUNCAN - was 975
        BuilderConditions = {
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 250, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource', --DUNCAN - change from T3
                }
            }
        }
    },
    Builder {
        BuilderName = 'T3 Mass Fab Engineer',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 980, --DUNCAN - was 900
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.MASSFABRICATION } },
                { EBC, 'LessThanEconEfficiencyOverTime', { 0.95, 2.0}}, --DUNCAN - was 0.8
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.4, 1.2}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENERGYPRODUCTION * categories.TECH3 } }, --DUNCAN - was 0
                { IBC, 'BrainNotLowPowerMode', {} },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.MASSEXTRACTION * categories.TECH3 } }, --DUNCAN - Added
            },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false, --DUNCAN - seems to work better at placing next to power
                AdjacencyCategory = categories.ENERGYPRODUCTION * (categories.TECH3 + categories.TECH2),
                BuildStructures = {
                    'T3MassCreation',
                },
            }
        }
    },
}

-----------------------------------------------------------
-- NAVAL MEX ENGINEERS
-----------------------------------------------------------
BuilderGroup {
    BuilderGroupName = 'EngineerMassBuilders - Naval',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T1ResourceEngineer 150 - Naval',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1000,
        InstanceCount = 4,
        BuilderConditions = {
                --{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, categories.ENGINEER * (categories.TECH2 + categories.TECH3) }},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 150, -500, 1, 0, 'AntiSurface', 1 }},
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
        BuilderName = 'T1ResourceEngineer 250 - Naval',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 980,
        InstanceCount = 4,
        BuilderConditions = {
                --{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, categories.ENGINEER * (categories.TECH2 + categories.TECH3) }},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 250, -500, 1, 0, 'AntiSurface', 1 }},
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
        BuilderName = 'T1ResourceEngineer 450 - Naval',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 970,
        InstanceCount = 4,
        BuilderConditions = {
                --{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, categories.ENGINEER * (categories.TECH2 + categories.TECH3) }},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 450, -500, 1, 0, 'AntiSurface', 1 }},
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
        BuilderName = 'T1ResourceEngineer 1000 - Naval',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 850,
        InstanceCount = 1,
        BuilderConditions = {
                --{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, categories.ENGINEER * (categories.TECH2 + categories.TECH3) }},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 1000, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            --NeedGuard = true,
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'T2 T2Resource Engineer 250 - Naval',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 975,
        InstanceCount = 1,
        BuilderConditions = {
                { UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH3 }},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 250, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource', --DUNCAN - change from T2
                }
            }
        }
    },
    Builder {
        BuilderName = 'T2 T2Resource Engineer 500 - Naval',
        PlatoonTemplate = 'T2EngineerBuilder',
        --DUNCAN - Changed from 875
        Priority = 0,
        InstanceCount = 1,
        BuilderConditions = {
                { UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH3 }},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 1000, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T2Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'T3 T3Resource Engineer 250 range - Naval',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 0, --DUNCAN - was 975
        BuilderConditions = {
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 250, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource', --DUNCAN - change from T3
                }
            }
        }
    },
    Builder {
        BuilderName = 'T3 T3Resource Engineer 500 range - Naval',
        PlatoonTemplate = 'T3EngineerBuilder',
        --DUNCAN - Changed from 850
        Priority = 0,
        BuilderConditions = {
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 1000, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T3Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'T3 Mass Fab Engineer - Naval',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 900,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.MASSFABRICATION } },
                { EBC, 'LessThanEconEfficiencyOverTime', { 0.8, 2}},
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.4, 1.2}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENERGYPRODUCTION * categories.TECH3 } }, --DUNCAN - was 0
                { IBC, 'BrainNotLowPowerMode', {} },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * categories.TECH3 } }, --DUNCAN - Added
            },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = true,
                AdjacencyCategory = categories.ENERGYPRODUCTION,
                BuildStructures = {
                    'T3MassCreation',
                },
            }
        }
    },
}


BuilderGroup {
    BuilderGroupName = 'EngineerMassBuildersLowerPri',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T1ResourceEngineer 150 Low',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1000,
        InstanceCount = 2,
        BuilderConditions = {
                --{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 4, categories.ENGINEER * (categories.TECH2 + categories.TECH3)}},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 150, -500, 1, 0, 'AntiSurface', 1 }},
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
        BuilderName = 'T1ResourceEngineer 350 Low',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 700,
        InstanceCount = 2,
        BuilderConditions = {
                --{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 4, categories.ENGINEER * (categories.TECH2 + categories.TECH3)}},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 350, -500, 1, 0, 'AntiSurface', 1 }},
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
        BuilderName = 'T1ResourceEngineer 1000 Low',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 650,
        InstanceCount = 2,
        BuilderConditions = {
                --{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 4, categories.ENGINEER * (categories.TECH2 + categories.TECH3)}},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 1000, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            --NeedGuard = true,
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'T2ResourceEngineer 150 Low',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1000,
        InstanceCount = 2,
        BuilderConditions = {
                --{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 4, categories.ENGINEER * (categories.TECH2 + categories.TECH3)}},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 150, -500, 1, 0, 'AntiSurface', 1 }},
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
        BuilderName = 'T2 T2Resource Engineer 350 Low',
        PlatoonTemplate = 'T2EngineerBuilder',
        --DUNCAN - Changed from 850
        Priority = 0,
        InstanceCount = 1,
        BuilderConditions = {
                --{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 4, 'ENGINEER TECH3'}},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 350, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T2Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'T2 T2Resource Engineer 1000 Low',
        PlatoonTemplate = 'T2EngineerBuilder',
        --DUNCAN - Changed from 7500
        Priority = 0,
        InstanceCount = 1,
        BuilderConditions = {
                --{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 4, 'ENGINEER TECH3'}},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 1000, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T2Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'T3 T3Resource Engineer 350 range Low',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 0, --DUNCAN - was 850
        BuilderConditions = {
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 350, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'T3 T3Resource Engineer 1000 range Low',
        PlatoonTemplate = 'T3EngineerBuilder',
        --DUNCAN - Changed from 750
        Priority = 0,
        BuilderConditions = {
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 1000, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T3Resource',
                }
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'EngineerMassBuildersMidPriSingle',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T1ResourceEngineer 1000 Mid - Single',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 750,
        BuilderConditions = {
                --{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, categories.ENGINEER * (categories.TECH2 + categories.TECH3)}},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 1000, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true, --DUNCAN - Added
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'T2 T2Resource Engineer 1000 Mid - Single',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 750,
        BuilderConditions = {
                --{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, 'ENGINEER TECH3'}},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 1000, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'T3 T3Resource Engineer 1000 range Mid - Single',
        PlatoonTemplate = 'T3EngineerBuilder',
        --DUNCAN - Changed from 750
        Priority = 0,
        BuilderConditions = {
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 1000, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T3Resource',
                }
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'EngineerEnergyBuilders',
    BuildersType = 'EngineerBuilder',
    -- =====================================
    --     T2 Engineer Resource Builders
    -- =====================================
    Builder {
        BuilderName = 'T1 Power Engineer - rebuild',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1100,
        BuilderConditions = {
            { MIBC, 'GreaterThanGameTime', { 600 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 4, categories.ENERGYPRODUCTION } },
            { EBC, 'LessThanEconEfficiencyOverTime', { 2.0, 1.35 }},
        },
        --InstanceCount = 2,
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = categories.FACTORY * categories.STRUCTURE - categories.NAVAL,
                BuildStructures = {
                    'T1EnergyProduction',
                },
            }
        }
    },
    Builder {
        BuilderName = 'T1 Power Engineer',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1000,
        InstanceCount = 1,
        BuilderConditions = {
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.6, 0.1 }},
            { EBC, 'LessThanEnergyTrendOverTime', { 15.0 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * (categories.TECH2 + categories.TECH3) }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = categories.FACTORY * categories.STRUCTURE - categories.NAVAL,
                BuildStructures = {
                    'T1EnergyProduction',
                },
            }
        }
    },
    Builder {
        BuilderName = 'T1 Power Engineer Scale',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1000,
        InstanceCount = 1,
        BuilderConditions = {
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.75, 0.1 }},
            { EBC, 'LessThanEnergyTrendOverTime', { 25.0 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * (categories.TECH2 + categories.TECH3) }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = categories.FACTORY * categories.STRUCTURE - categories.NAVAL,
                BuildStructures = {
                    'T1EnergyProduction',
                },
            }
        }
    },
    Builder {
        BuilderName = 'T2 Power Engineer',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 950,
        BuilderConditions = {
            { EBC, 'LessThanEnergyTrendOverTime', { 45.0 } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.5, 0.1 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.ENERGYPRODUCTION * categories.TECH2}}, --DUNCAN - Added
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, categories.TECH3 * categories.ENGINEER }},
            
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = true,
                AvoidCategory = categories.ENERGYPRODUCTION * categories.TECH2,
                maxUnits = 5,
                maxRadius = 15,
                AdjacencyCategory = categories.SHIELD * categories.STRUCTURE + categories.FACTORY * categories.STRUCTURE - categories.NAVAL,
                BuildStructures = {
                    'T2EnergyProduction',
                },
            }
        }
    },
    Builder {
        BuilderName = 'T3 Power Engineer',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1000,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.ENERGYPRODUCTION * (categories.TECH2 + categories.TECH3)}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.5, 0.1 }},
            { EBC, 'LessThanEnergyTrendOverTime', { 200.0 } },
        },
        BuilderData = {
            Construction = {
                BuildClose = true,
                AdjacencyCategory = categories.SHIELD * categories.STRUCTURE + categories.FACTORY * categories.STRUCTURE - categories.NAVAL,
                AvoidCategory = categories.ENERGYPRODUCTION * categories.TECH3,
                maxUnits = 5,
                maxRadius = 15,
                BuildStructures = {
                    'T3EnergyProduction',
                },
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'EngineerEnergyBuildersExpansions',
    BuildersType = 'EngineerBuilder',
    -- =====================================
    --     T2 Engineer Resource Builders
    -- =====================================
    --Builder {
    --    BuilderName = 'T1 Power Engineer Expansions',
    --    PlatoonTemplate = 'EngineerBuilder',
    --    Priority = 975,
    --    BuilderConditions = {
    --            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 8, 'ENERGYPRODUCTION' } },
    --            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, categories.ENGINEER * (categories.TECH2 + categories.TECH3) } },
    --            { EBC, 'LessThanEconEfficiencyOverTime', { 1.5, 1.2}},
    --        },
    --    InstanceCount = 1,
    --    BuilderType = 'Any',
    --    BuilderData = {
    --        Construction = {
    --            BuildStructures = {
    --                'T1EnergyProduction',
    --                'T1EnergyProduction',
    --                'T1EnergyProduction',
    --                'T1EnergyProduction',
    --            },
    --            Location = 'LocationType',
    --        }
    --    }
    --},
    --Builder {
    --    BuilderName = 'T2 Power Engineer Expansions',
    --    PlatoonTemplate = 'T2EngineerBuilder',
    --    Priority = 950,
    --    BuilderConditions = {
    --            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, 'ENERGYPRODUCTION TECH2' } },
    --            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, 'TECH3 ENGINEER' }},
    --            { EBC, 'LessThanEconEfficiencyOverTime', { 1.5, 1.2}},
    --        },
    --    BuilderType = 'Any',
    --    BuilderData = {
    --        Construction = {
    --            BuildStructures = {
    --                'T2EnergyProduction',
    --            },
    --            Location = 'LocationType',
    --        }
    --    }
    --},
    --Builder {
    --    BuilderName = 'T3 Power Engineer Expansions',
    --    PlatoonTemplate = 'T3EngineerBuilder',
    --    Priority = 1000,
    --    BuilderType = 'Any',
    --    BuilderConditions = {
    --            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, categories.ENERGYPRODUCTION * categories.TECH3 } },
    --            { EBC, 'LessThanEconEfficiencyOverTime', { 1.5, 1.2}},
    --        },
    --    BuilderData = {
    --        Construction = {
    --            BuildStructures = {
    --                'T3EnergyProduction',
    --            },
    --            Location = 'LocationType',
    --        }
    --    }
    --},
}

BuilderGroup {
    BuilderGroupName = 'EngineeringSupportBuilder',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T2 Engineering Support UEF',
        PlatoonTemplate = 'UEFT2EngineerBuilder',
        Priority = 750,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, categories.ENGINEERSTATION }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH2 } },
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 2, categories.TECH3 * categories.ENERGYPRODUCTION}},
            { EBC, 'GreaterThanEconIncomeOverTime',  { 10, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 1.0, 1.4 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = categories.ENERGYPRODUCTION,
                BuildClose = true,
                FactionIndex = 1,
                BuildStructures = {
                    'T2EngineerSupport',
                },
            }
        }
    },
    Builder {
        BuilderName = 'T2 Engineering Support Cybran',
        PlatoonTemplate = 'CybranT2EngineerBuilder',
        Priority = 750,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, categories.ENGINEERSTATION }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH2 } },
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, categories.TECH2 * categories.ENERGYPRODUCTION}},
            { EBC, 'GreaterThanEconIncomeOverTime',  { 10, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 1.0, 1.4 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = categories.ENERGYPRODUCTION,
                BuildClose = true,
                FactionIndex = 3,
                BuildStructures = {
                    'T2EngineerSupport',
                },
            }
        }
    },
    Builder {
        BuilderName = 'T3 Engineering Support UEF',
        PlatoonTemplate = 'UEFT3EngineerBuilder',
        Priority = 950,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 7, categories.ENGINEERSTATION }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH3 } },
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, categories.TECH3 * categories.ENERGYPRODUCTION}},
            { EBC, 'GreaterThanEconIncomeOverTime',  { 10, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 1.0, 1.4 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = categories.ENERGYPRODUCTION,
                BuildClose = true,
                FactionIndex = 1,
                BuildStructures = {
                    'T2EngineerSupport',
                },
            }
        }
    },
    Builder {
        BuilderName = 'T3 Engineering Support Cybran',
        PlatoonTemplate = 'CybranT3EngineerBuilder',
        Priority = 950,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 7, categories.ENGINEERSTATION }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH3 } },
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, categories.TECH3 * categories.ENERGYPRODUCTION}},
            { EBC, 'GreaterThanEconIncomeOverTime',  { 10, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 1.0, 1.4 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = categories.ENERGYPRODUCTION,
                BuildClose = true,
                FactionIndex = 3,
                BuildStructures = {
                    'T2EngineerSupport',
                },
            }
        }
    },
}