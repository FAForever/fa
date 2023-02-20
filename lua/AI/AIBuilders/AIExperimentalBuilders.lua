--***************************************************************************
--*
--**  File     :  /lua/ai/AIExperimentalBuilders.lua
--**
--**  Summary  : Default experimental builders for skirmish
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
local IBC = '/lua/editor/instantbuildconditions.lua'
local TBC = '/lua/editor/threatbuildconditions.lua'
local PlatoonFile = '/lua/platoon.lua'

local AIAddBuilderTable = import("/lua/ai/aiaddbuildertable.lua")

---@alias BuildergroupsExperimentals 'MobileLandExperimentalEngineers' | 'MobileLandExperimentalForm' | 'MobileAirExperimentalEngineers' | 'MobileAirExperimentalForm' | 'SatelliteExperimentalEngineers' | 'SatelliteExperimentalForm' | 'MobileNavalExperimentalEngineers' | 'MobileNavalExperimentalForm' | 'EconomicExperimentalEngineers'

BuilderGroup {
    BuilderGroupName = 'MobileLandExperimentalEngineers',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T3 Land Exp1 Engineer 1',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 875,
        InstanceCount = 1,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanMassStorageCurrent', { 150 }},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.1 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.EXPERIMENTAL}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.NUKE * categories.STRUCTURE}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * categories.TECH3}},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                NearMarkerType = 'Rally Point',
                BuildStructures = {
                    'T4LandExperimental1',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'T3 Land Exp2 Engineer 1',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 875,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanMassStorageCurrent', { 150 }},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.EXPERIMENTAL}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.NUKE * categories.STRUCTURE}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.ENERGYPRODUCTION * categories.TECH3}},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                NearMarkerType = 'Rally Point',
                BuildStructures = {
                    'T4LandExperimental2',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'T3 Land Exp3 Engineer 1',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 875,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanMassStorageCurrent', { 150 }},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.EXPERIMENTAL}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.NUKE * categories.STRUCTURE}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.ENERGYPRODUCTION * categories.TECH3}},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                NearMarkerType = 'Rally Point',
                BuildStructures = {
                    'T4LandExperimental3',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'T2 Engineer Assist Experimental Mobile Land',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 800,
        InstanceCount = 5,
        BuilderConditions = {
            { UCBC, 'LocationEngineersBuildingGreater', { 'LocationType', 0, categories.EXPERIMENTAL * categories.LAND * categories.MOBILE}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2} },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL MOBILE LAND'},
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'T3 Engineer Assist Experimental Mobile Land',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 750,
        InstanceCount = 5,
        BuilderConditions = {
            { UCBC, 'LocationEngineersBuildingGreater', { 'LocationType', 0, categories.EXPERIMENTAL * categories.LAND * categories.MOBILE}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2} },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL MOBILE LAND'},
                Time = 60,
            },
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'MobileLandExperimentalForm',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T4 Exp Land',
        PlatoonAddPlans = {'NameUnits'},
        PlatoonTemplate = 'T4ExperimentalLand',
        Priority = 1000,
        FormRadius = 10000,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.MOBILE * categories.LAND * categories.EXPERIMENTAL } },
        },
        BuilderType = 'Any',
        BuilderData = {
            ThreatWeights = {
                TargetThreatType = 'Commander',
            },
            UseMoveOrder = true,
            PrioritizedCategories = { 'EXPERIMENTAL LAND', 'COMMAND', 'FACTORY LAND', 'MASSPRODUCTION', 'ENERGYPRODUCTION', 'STRUCTURE STRATEGIC', 'STRUCTURE' }, -- list in order
        },
    },
    Builder {
        BuilderName = 'T4 Exp Land Group',
        PlatoonAddPlans = {'NameUnits'},
        PlatoonTemplate = 'T4ExperimentalLandGroup',
        Priority = 1000,
        FormRadius = 10000,
        InstanceCount = 10,
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, categories.MOBILE * categories.LAND * categories.EXPERIMENTAL } },
        },
        BuilderType = 'Any',
        BuilderData = {
            ThreatWeights = {
                TargetThreatType = 'Commander',
            },
            UseMoveOrder = true,
            PrioritizedCategories = { 'EXPERIMENTAL LAND', 'COMMAND', 'FACTORY LAND', 'MASSPRODUCTION', 'ENERGYPRODUCTION', 'STRUCTURE STRATEGIC', 'STRUCTURE' }, -- list in order
        },
    },
    --DUNCAN - added
    Builder {
        BuilderName = 'LandExperimentalGuard',
        PlatoonTemplate = 'T3ExperimentalGuard',
        PlatoonAIPlan = 'GuardUnit',
        Priority = 750,
        InstanceCount = 3,
        BuilderData = {
            GuardCategory = categories.MOBILE * categories.EXPERIMENTAL * categories.LAND - categories.ORBITALSYSTEM - categories.SATELLITE,
            LocationType = 'LocationType',
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 5, categories.MOBILE * categories.LAND * (categories.TECH1 + categories.TECH2 + categories.TECH3) } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MOBILE * categories.EXPERIMENTAL * categories.LAND - categories.ORBITALSYSTEM - categories.SATELLITE} },
            { UCBC, 'UnitsNeedGuard', { categories.MOBILE * categories.EXPERIMENTAL * categories.LAND - categories.ORBITALSYSTEM - categories.SATELLITE} },
        },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'MobileAirExperimentalEngineers',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T3 Air Exp1 Engineer 1',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 875,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanMassStorageCurrent', { 150 }},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2} },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.EXPERIMENTAL}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.NUKE * categories.STRUCTURE}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3}},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Protected Experimental Construction',
                BuildStructures = {
                    'T4AirExperimental1',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'T2 Engineer Assist Experimental Mobile Air',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 800,
        InstanceCount = 5,
        BuilderConditions = {
            { UCBC, 'LocationEngineersBuildingGreater', { 'LocationType', 0, categories.EXPERIMENTAL * categories.AIR * categories.MOBILE}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * categories.TECH3}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2} },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL MOBILE AIR'},
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'T3 Engineer Assist Experimental Mobile Air',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 750,
        InstanceCount = 5,
        BuilderConditions = {
            { UCBC, 'LocationEngineersBuildingGreater', { 'LocationType', 0, categories.EXPERIMENTAL * categories.AIR * categories.MOBILE}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2} },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL MOBILE AIR'},
                Time = 60,
            },
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'MobileAirExperimentalForm',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T4 Exp Air',
        PlatoonTemplate = 'T4ExperimentalAir',
        PlatoonAddPlans = {'NameUnits'},
        Priority = 801,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.MOBILE * categories.AIR * categories.EXPERIMENTAL } },
        },
        FormRadius = 10000,
        BuilderType = 'Any',
        BuilderData = {
            ThreatWeights = {
                TargetThreatType = 'Commander',
            },
            UseMoveOrder = true,
            PrioritizedCategories = { 'COMMAND', 'ANTIAIR', 'EXPERIMENTAL', 'ENERGYPRODUCTION', 'FACTORY', 'STRUCTURE' }, -- list in order
        },
    },
    Builder {
        BuilderName = 'T4 Exp Air Group',
        PlatoonTemplate = 'T4ExperimentalAirGroup',
        PlatoonAddPlans = {'NameUnits'},
        Priority = 800,
        InstanceCount = 50,
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, categories.MOBILE * categories.AIR * categories.EXPERIMENTAL } },
        },
        FormRadius = 10000,
        BuilderType = 'Any',
        BuilderData = {
            ThreatWeights = {
                TargetThreatType = 'Commander',
            },
            UseMoveOrder = true,
            PrioritizedCategories = { 'COMMAND', 'ANTIAIR', 'EXPERIMENTAL', 'ENERGYPRODUCTION', 'FACTORY', 'STRUCTURE' }, -- list in order
        },
    },
    Builder {
        BuilderName = 'AirExperimentalGuard',
        PlatoonTemplate = 'AirEscort',
        Priority = 750,
        InstanceCount = 3,
        BuilderType = 'Any',
        BuilderData = {
            GuardCategory = categories.MOBILE * categories.EXPERIMENTAL - categories.ORBITALSYSTEM - categories.SATELLITE,
            LocationType = 'LocationType',
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 4, categories.AIR * categories.MOBILE * (categories.TECH1 + categories.TECH2 + categories.TECH3) * categories.ANTIAIR } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MOBILE * categories.EXPERIMENTAL - categories.ORBITALSYSTEM } },
            { UCBC, 'UnitsNeedGuard', { categories.MOBILE * categories.EXPERIMENTAL - categories.ORBITALSYSTEM - categories.SATELLITE} },
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'SatelliteExperimentalEngineers',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T3 Satellite Exp Engineer',
        PlatoonTemplate = 'UEFT3EngineerBuilder',
        Priority = 875,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanMassStorageCurrent', { 150 }},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH3}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * categories.TECH3}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL}}, --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.EXPERIMENTAL * categories.ORBITALSYSTEM}}, --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.EXPERIMENTAL}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.NUKE * categories.STRUCTURE}},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T4SatelliteExperimental',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'T2 Engineer Assist Experimental Satellite',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 800,
        InstanceCount = 5,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * categories.TECH3}},
            { UCBC, 'LocationEngineersBuildingGreater', { 'LocationType', 0, categories.EXPERIMENTAL * categories.ORBITALSYSTEM }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2} },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                BeingBuiltCategories = {'EXPERIMENTAL ORBITALSYSTEM'},
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'T3 Engineer Assist Experimental Satellite',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 750,
        InstanceCount = 5,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * categories.TECH3}},
            { UCBC, 'LocationEngineersBuildingGreater', { 'LocationType', 0, categories.EXPERIMENTAL * categories.ORBITALSYSTEM }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2} },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                BeingBuiltCategories = {'EXPERIMENTAL ORBITALSYSTEM'},
                Time = 60,
            },
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SatelliteExperimentalForm',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T4 Exp Satellite',
        PlatoonTemplate = 'T4SatelliteExperimental',
        PlatoonAddPlans = {'NameUnits'},
        PlatoonAIPlan = 'StrikeForceAI',
        Priority = 800,
        FormRadius = 10000,
        InstanceCount = 50,
        BuilderType = 'Any',
        BuilderData = {
            SearchRadius = 60,
            PrioritizedCategories = { 'MASSEXTRACTION', 'TECH3 STRUCTURE', 'TECH2 STRUCTURE', 'STRUCTURE' }, -- list in order
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'MobileNavalExperimentalEngineers',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T4 Sea Exp1 Engineer',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 875,
        BuilderConditions = {
            { EBC, 'GreaterThanMassStorageCurrent', { 150 }},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.EXPERIMENTAL}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.NUKE * categories.STRUCTURE}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.TECH3 * categories.ARTILLERY * categories.STRUCTURE }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * categories.TECH3}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.BATTLESHIP}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH3}},
            { MABC, 'MarkerLessThanDistance',  { 'Naval Area', 400}},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Naval Area',
                BuildStructures = {
                    'T4SeaExperimental1',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'T2 Engineer Assist Experimental Mobile Naval',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 800,
        InstanceCount = 5,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * categories.TECH3}},
            { UCBC, 'LocationEngineersBuildingGreater', { 'LocationType', 0, categories.EXPERIMENTAL * categories.NAVAL * categories.MOBILE}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2} },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL MOBILE NAVAL'},
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'T3 Engineer Assist Experimental Mobile Naval',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 750,
        InstanceCount = 5,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * categories.TECH3}},
            { UCBC, 'LocationEngineersBuildingGreater', { 'LocationType', 0, categories.EXPERIMENTAL * categories.NAVAL * categories.MOBILE}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2} },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL MOBILE NAVAL'},
                Time = 60,
            },
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'MobileNavalExperimentalForm',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T4 Exp Sea',
        PlatoonTemplate = 'T4ExperimentalSea',
        PlatoonAddBehaviors = { 'TempestBehavior' },
        PlatoonAddPlans = {'NameUnits'},
        PlatoonAIPlan = 'AttackForceAI',
        Priority = 1300,
        FormRadius = 10000,
        InstanceCount = 50,
        BuilderType = 'Any',
        BuilderData = {
            ThreatWeights = {
                TargetThreatType = 'Commander',
            },
            PrioritizedCategories = { 'COMMAND', 'FACTORY -NAVAL','EXPERIMENTAL', 'MASSPRODUCTION', 'STRUCTURE' }, -- list in order
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'EconomicExperimentalEngineers',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Econ Exper Engineer',
        PlatoonTemplate = 'AeonT3EngineerBuilder',
        Priority = 875,
        BuilderConditions = {
            { EBC, 'GreaterThanMassStorageCurrent', { 150 }},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.EXPERIMENTAL } }, --DUNCAN - added
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENERGYPRODUCTION * categories.TECH3}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.EXPERIMENTAL}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.NUKE * categories.STRUCTURE}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.TECH3 * categories.ARTILLERY * categories.STRUCTURE }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.EXPERIMENTAL * categories.ECONOMIC}},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T4EconExperimental',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'T2 Engineer Assist Experimental Economic',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 800,
        InstanceCount = 5,
        BuilderConditions = {
            { UCBC, 'LocationEngineersBuildingGreater', { 'LocationType', 0, categories.EXPERIMENTAL * categories.ECONOMIC}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.1} },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL ECONOMIC'},
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'T3 Engineer Assist Experimental Mobile Economic',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 750,
        InstanceCount = 5,
        BuilderConditions = {
            { UCBC, 'LocationEngineersBuildingGreater', { 'LocationType', 0, categories.EXPERIMENTAL * categories.ECONOMIC }},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2} },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL ECONOMIC'},
                Time = 60,
            },
        }
    },
}
