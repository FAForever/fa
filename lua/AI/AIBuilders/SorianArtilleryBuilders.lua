--***************************************************************************
--*
--**  File     :  /lua/ai/AIArtilleryBuilders.lua
--**
--**  Summary  : Default artillery/nuke/etc builders for skirmish
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
local SIBC = '/lua/editor/SorianInstantBuildConditions.lua'
local SBC = '/lua/editor/SorianBuildConditions.lua'

-- T3 Artillery/Rapid Fire Artillery
BuilderGroup {
    BuilderGroupName = 'SorianT3ArtilleryGroup',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T3 Artillery Engineer - In range',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 951,
        BuilderConditions = {
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.TECH3 * categories.ARTILLERY * categories.STRUCTURE, 'LocationType', }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'EngineerNeedsAssistance', { false, 'LocationType', {'EXPERIMENTAL', 'NUKE STRUCTURE', 'TECH3 ARTILLERY STRUCTURE'} }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL}},
            { SIBC, 'GreaterThanEconIncome', {15, 750}},
            { SIBC, 'GreaterThanEconEfficiency', { 0.9, 1.2}},
            { IBC, 'BrainNotLowPowerMode', {} },
            --{ UCBC, 'CheckUnitRange', { 'LocationType', 'T3Artillery', categories.STRUCTURE } },
            { SBC, 'MapGreaterThan', { 1000, 1000 }},
            { SBC, 'EnemyInT3ArtilleryRange', { 'LocationType', true } },
        },
        BuilderType = 'Any',
        BuilderData = {
            MinNumAssistees = 2,
            Construction = {
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STRUCTURE',
                BuildStructures = {
                    'T3Artillery',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Artillery Engineer',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 949,
        BuilderConditions = {
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.TECH3 * categories.ARTILLERY * categories.STRUCTURE, 'LocationType', }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.STRUCTURE * categories.TECH3 * categories.ARTILLERY}},
            { SIBC, 'EngineerNeedsAssistance', { false, 'LocationType', {'EXPERIMENTAL', 'NUKE STRUCTURE', 'TECH3 ARTILLERY STRUCTURE'} }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL}},
            { SIBC, 'GreaterThanEconIncome', {15, 750}},
            --{ SBC, 'MapGreaterThan', { 500, 500 }},
            { SIBC, 'GreaterThanEconEfficiency', { 0.9, 1.2}},
            { IBC, 'BrainNotLowPowerMode', {} },
            --{ UCBC, 'CheckUnitRange', { 'LocationType', 'T3Artillery', categories.STRUCTURE } },
            { SBC, 'EnemyInT3ArtilleryRange', { 'LocationType', false } },
        },
        BuilderType = 'Any',
        BuilderData = {
            MinNumAssistees = 2,
            Construction = {
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STRUCTURE',
                BuildStructures = {
                    'T3Artillery',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Artillery Engineer - 5x5+',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 949,
        BuilderConditions = {
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.TECH3 * categories.ARTILLERY * categories.STRUCTURE, 'LocationType', }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.STRUCTURE * categories.TECH3 * categories.ARTILLERY}},
            { SIBC, 'EngineerNeedsAssistance', { false, 'LocationType', {'EXPERIMENTAL', 'NUKE STRUCTURE', 'TECH3 ARTILLERY STRUCTURE'} }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.EXPERIMENTAL}},
            { SIBC, 'GreaterThanEconIncome', {15, 750}},
            --{ SBC, 'MapGreaterThan', { 500, 500 }},
            { SBC, 'MapLessThan', { 1000, 1000 }},
            { SIBC, 'GreaterThanEconEfficiency', { 0.9, 1.2}},
            { IBC, 'BrainNotLowPowerMode', {} },
            --{ UCBC, 'CheckUnitRange', { 'LocationType', 'T3Artillery', categories.STRUCTURE } },
            { SBC, 'EnemyInT3ArtilleryRange', { 'LocationType', true } },
        },
        BuilderType = 'Any',
        BuilderData = {
            MinNumAssistees = 2,
            Construction = {
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STRUCTURE',
                BuildStructures = {
                    'T3Artillery',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian Rapid T3 Artillery Engineer',
        PlatoonTemplate = 'AeonT3EngineerBuilderSorian',
        Priority = 950,
        BuilderConditions = {
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.TECH3 * categories.ARTILLERY * categories.STRUCTURE, 'LocationType', }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.TECH3 * categories.ARTILLERY * categories.STRUCTURE * categories.PRODUCTSC1}},
            { SIBC, 'EngineerNeedsAssistance', { false, 'LocationType', {'EXPERIMENTAL', 'NUKE STRUCTURE', 'TECH3 ARTILLERY STRUCTURE'} }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL}},
            { SIBC, 'GreaterThanEconIncome', {15, 750}},
            { SIBC, 'GreaterThanEconEfficiency', { 0.9, 1.2}},
            { SBC, 'MapGreaterThan', { 1000, 1000 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            --{ SIBC, 'T4BuildingCheck', {} },
            --{ UCBC, 'CheckUnitRange', { 'LocationType', 'T3RapidArtillery', categories.STRUCTURE, 2 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            MinNumAssistees = 2,
            Construction = {
                BuildClose = true,
                --T4 = true,
                AdjacencyCategory = 'SHIELD STRUCTURE',
                BuildStructures = {
                    'T3RapidArtillery',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3EngineerAssistBuildHLRA',
        PlatoonTemplate = 'T3EngineerAssistSorian',
        Priority = 850,
        InstanceCount = 4,
        BuilderConditions = {
            { UCBC, 'LocationEngineersBuildingGreater', { 'LocationType', 0, categories.ARTILLERY * categories.TECH3 * categories.STRUCTURE}},
            { SIBC, 'GreaterThanEconEfficiency', { 0.9, 1.2}},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 150,
                BeingBuiltCategories = {'ARTILLERY TECH3 STRUCTURE'},
                Time = 120,
            },
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT3ArtilleryGroupExp',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T3 Artillery Engineer Expansion - In range',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 951,
        BuilderConditions = {
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.TECH3 * categories.ARTILLERY * categories.STRUCTURE, 'LocationType', }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL}},
            { SIBC, 'GreaterThanEconIncome', {15, 750}},
            { SIBC, 'GreaterThanEconEfficiency', { 0.9, 1.2}},
            { SBC, 'MapGreaterThan', { 1000, 1000 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            --{ UCBC, 'CheckUnitRange', { 'LocationType', 'T3Artillery', categories.STRUCTURE } },
            { SBC, 'EnemyInT3ArtilleryRange', { 'LocationType', true } },
        },
        BuilderType = 'Any',
        BuilderData = {
            MinNumAssistees = 2,
            Construction = {
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STRUCTURE',
                BuildStructures = {
                    'T3Artillery',
                },
                Location = 'LocationType',
            }
        }
    },
}

-- T3 Artillery/Rapid Fire Artillery
BuilderGroup {
    BuilderGroupName = 'SorianExperimentalArtillery',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T4 Artillery Engineer',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        PlatoonAddPlans = {'NameUnitsSorian'},
        Priority = 949,
        InstanceCount = 1,
        BuilderConditions = {
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.TECH3 * categories.ARTILLERY * categories.STRUCTURE}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.EXPERIMENTAL * categories.STRUCTURE}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.EXPERIMENTAL * categories.STRUCTURE * categories.ARTILLERY}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'EngineerNeedsAssistance', { false, 'LocationType', {'EXPERIMENTAL', 'NUKE STRUCTURE', 'TECH3 ARTILLERY STRUCTURE'} }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL}},
            { SIBC, 'GreaterThanEconIncome', {15, 750}},
            { SIBC, 'GreaterThanEconEfficiency', { 0.9, 1.2}},
            { SBC, 'MapGreaterThan', { 1000, 1000 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            --{ SIBC, 'T4BuildingCheck', {} },
            { MIBC, 'FactionIndex', {1,4} },
            --{ UCBC, 'CheckUnitRange', { 'LocationType', 'T4Artillery', categories.STRUCTURE } },
        },
        BuilderType = 'Any',
        BuilderData = {
            MinNumAssistees = 2,
            Construction = {
                BuildClose = true,
                --T4 = true,
                AdjacencyCategory = 'SHIELD STRUCTURE',
                BuildStructures = {
                    'T4Artillery',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T4 Artillery Engineer - Cybran',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        PlatoonAddPlans = {'NameUnitsSorian'},
        Priority = 949,
        InstanceCount = 1,
        BuilderConditions = {
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.TECH3 * categories.ARTILLERY * categories.STRUCTURE}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.EXPERIMENTAL * categories.ARTILLERY * categories.OVERLAYINDIRECTFIRE}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.EXPERIMENTAL * categories.ARTILLERY * categories.OVERLAYINDIRECTFIRE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'EngineerNeedsAssistance', { false, 'LocationType', {'EXPERIMENTAL', 'NUKE STRUCTURE', 'TECH3 ARTILLERY STRUCTURE'} }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL}},
            { SIBC, 'GreaterThanEconIncome', {15, 750}},
            { SIBC, 'GreaterThanEconEfficiency', { 0.9, 1.2}},
            { SBC, 'MapGreaterThan', { 1000, 1000 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            --{ SIBC, 'T4BuildingCheck', {} },
            { MIBC, 'FactionIndex', {3} },
            --{ UCBC, 'CheckUnitRange', { 'LocationType', 'T4Artillery', categories.STRUCTURE } },
        },
        BuilderType = 'Any',
        BuilderData = {
            MinNumAssistees = 2,
            Construction = {
                BuildClose = true, --false
                --T4 = true,
                --BaseTemplate = ExBaseTmpl,
                --NearMarkerType = 'Rally Point',
                AdjacencyCategory = 'SHIELD STRUCTURE',
                BuildStructures = {
                    'T4LandExperimental2',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T4EngineerAssistBuildHLRA',
        PlatoonTemplate = 'T3EngineerAssistSorian',
        Priority = 850,
        InstanceCount = 8,
        BuilderConditions = {
            { UCBC, 'LocationEngineersBuildingGreater', { 'LocationType', 0, categories.ARTILLERY * categories.TECH3 * categories.STRUCTURE}},
            { SIBC, 'GreaterThanEconEfficiency', { 0.9, 1.2}},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssisteeType = 'Engineer',
                AssistRange = 150,
                AssistLocation = 'LocationType',
                BeingBuiltCategories = {'EXPERIMENTAL STRUCTURE'},
                Time = 120,
            },
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT3ArtilleryFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Sorian T3 Artillery',
        PlatoonTemplate = 'T3ArtilleryStructureSorian',
        Priority = 1,
        InstanceCount = 1000,
        FormRadius = 10000,
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT4ArtilleryFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Sorian T4 Artillery',
        PlatoonTemplate = 'T4ArtilleryStructureSorian',
        PlatoonAddPlans = {'NameUnitsSorian'},
        Priority = 1,
        InstanceCount = 1000,
        FormRadius = 10000,
        BuilderType = 'Any',
    },
}

-- Nukes
BuilderGroup {
    BuilderGroupName = 'SorianNukeBuildersEngineerBuilders',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian Seraphim Exp Nuke Engineer',
        PlatoonTemplate = 'SeraphimT3EngineerBuilderSorian',
        Priority = 949,
        InstanceCount = 1,
        BuilderConditions = {
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.TECH3 * categories.ARTILLERY * categories.STRUCTURE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.NUKE * categories.STRUCTURE * categories.TECH3}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.EXPERIMENTAL * categories.STRUCTURE * categories.NUKE}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.NUKE * categories.STRUCTURE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'EngineerNeedsAssistance', { false, 'LocationType', {'EXPERIMENTAL', 'NUKE STRUCTURE', 'TECH3 ARTILLERY STRUCTURE'} }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL}},
            { SIBC, 'GreaterThanEconIncome', {15, 750}},
            { SBC, 'MapGreaterThan', { 1000, 1000 }},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2}},
            { IBC, 'BrainNotLowPowerMode', {} },
            --{ SIBC, 'T4BuildingCheck', {} },
        },
        BuilderType = 'Any',
        BuilderData = {
            MinNumAssistees = 2,
            Construction = {
                BuildClose = true,
                --T4 = true,
                AdjacencyCategory = 'SHIELD STRUCTURE',
                BuildStructures = {
                    'T4Artillery',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Nuke Engineer',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 950,
        InstanceCount = 1,
        BuilderConditions = {
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.NUKE * categories.STRUCTURE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSPRODUCTION * categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL}},
            --{ SIBC, 'GreaterThanEconIncome', {15, 750}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2}},
            { SBC, 'MapGreaterThan', { 1000, 1000 }},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
        BuilderData = {
            MinNumAssistees = 2,
            Construction = {
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STRUCTURE',
                BuildStructures = {
                    'T3StrategicMissile',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Nuke Engineer - 10x10',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 950,
        InstanceCount = 1,
        BuilderConditions = {
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.NUKE * categories.STRUCTURE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSPRODUCTION * categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.EXPERIMENTAL}},
            --{ SIBC, 'GreaterThanEconIncome', {15, 750}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2}},
            { SBC, 'MapGreaterThan', { 500, 500 }},
            { SBC, 'MapLessThan', { 1000, 1000 }},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
        BuilderData = {
            MinNumAssistees = 2,
            Construction = {
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STRUCTURE',
                BuildStructures = {
                    'T3StrategicMissile',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Engineer Assist Build Nuke',
        PlatoonTemplate = 'T3EngineerAssistSorian',
        Priority = 850,
        InstanceCount = 4,
        BuilderConditions = {
            { UCBC, 'LocationEngineersBuildingGreater', { 'LocationType', 0, categories.STRUCTURE * categories.NUKE}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2}},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 150,
                BeingBuiltCategories = {'STRUCTURE NUKE'},
                Time = 120,
            },
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Engineer Assist Build Nuke Missile',
        PlatoonTemplate = 'T3EngineerAssistSorian',
        Priority = 850,
        InstanceCount = 3,
        BuilderConditions = {
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 0, 'NUKE STRUCTURE'}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2}},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'NonUnitBuildingStructure',
                AssistRange = 150,
                AssisteeCategory = 'STRUCTURE NUKE',
                Time = 120,
            },
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianNukeFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Sorian T3 Nuke Silo',
        PlatoonTemplate = 'T3NukeSorian',
        Priority = 1,
        InstanceCount = 10,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T4 Nuke Silo',
        PlatoonTemplate = 'T4NukeSorian',
        Priority = 1,
        InstanceCount = 10,
        BuilderType = 'Any',
    },
}
