#***************************************************************************
#*
#**  File     :  /lua/ai/SorianDefenseBuilders.lua
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
local IBC = '/lua/editor/InstantBuildConditions.lua'
local TBC = '/lua/editor/ThreatBuildConditions.lua'
local PlatoonFile = '/lua/platoon.lua'
local SBC = '/lua/editor/SorianBuildConditions.lua'
local SIBC = '/lua/editor/SorianInstantBuildConditions.lua'

local AIAddBuilderTable = import('/lua/ai/AIAddBuilderTable.lua')

BuilderGroup {
    BuilderGroupName = 'SorianMassAdjacencyDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T1 Mass Adjacency Defense Engineer',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 825,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3'}},
            { MABC, 'MarkerLessThanDistance',  { 'Mass', 600, -1, 0, 0}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'AdjacencyCheck', { 'LocationType', 'MASSEXTRACTION', 600, 'ueb2101' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            Construction = {
                AdjacencyCategory = 'MASSEXTRACTION',
                AdjacencyDistance = 600,
                BuildClose = false,
                ThreatMin = -1,
                ThreatMax = 0,
                ThreatRings = 0,
                MinRadius = 250,
                BuildStructures = {
                    'T1GroundDefense',
                    'T1AADefense',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2 Mass Adjacency Defense Engineer',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 825,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3'}},
            { MABC, 'MarkerLessThanDistance',  { 'Mass', 600, -1, 0, 0}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'AdjacencyCheck', { 'LocationType', 'MASSEXTRACTION', 600, 'ueb2101' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            Construction = {
                AdjacencyCategory = 'MASSEXTRACTION',
                AdjacencyDistance = 600,
                BuildClose = false,
                ThreatMin = -1,
                ThreatMax = 0,
                ThreatRings = 0,
                MinRadius = 250,
                BuildStructures = {
                    'T1GroundDefense',
                    'T1AADefense',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Mass Adjacency Defense Engineer',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 825,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3'}},
            { MABC, 'MarkerLessThanDistance',  { 'Mass', 600, -1, 0, 0}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'AdjacencyCheck', { 'LocationType', 'MASSEXTRACTION', 600, 'ueb2301' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            Construction = {
                AdjacencyCategory = 'MASSEXTRACTION',
                AdjacencyDistance = 600,
                BuildClose = false,
                ThreatMin = -1,
                ThreatMax = 0,
                ThreatRings = 0,
                MinRadius = 250,
                BuildStructures = {
                    'T2GroundDefense',
                    'T2AADefense',
                }
            }
        }
    },
}

# Inside the base location defenses
BuilderGroup {
    BuilderGroupName = 'SorianT1BaseDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T1 Base D Engineer',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 0,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 10, 'DEFENSE STRUCTURE'}},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH2'}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.TECH1 * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T1AADefense',
                    'T1GroundDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T1 Base D AA Engineer - Response',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 900,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 4, 'DEFENSE ANTIAIR STRUCTURE'}},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH2'}},
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 1, 'Air' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.TECH1 * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T1AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T1 Base D PD Engineer - Response',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 900,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 4, 'DEFENSE DIRECTFIRE STRUCTURE'}},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH2'}},
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 1, 'Land' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.TECH1 * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T1GroundDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT2BaseDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T2 Base D Engineer',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 920,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 40, 'DEFENSE TECH2 STRUCTURE' }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENERGYPRODUCTION TECH2' }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.TECH2 * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T2AADefense',
                    'T2GroundDefense',
                    'T2MissileDefense',
                    'T2Artillery',
                    'T2StrategicMissile',
                    'T2MissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2 Base D Engineer PD - Response',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 0, #925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 20, 'DEFENSE TECH2 DIRECTFIRE STRUCTURE' }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENERGYPRODUCTION TECH2'}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.TECH2 * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T2GroundDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2 Base D Anti-TML Engineer - Response',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 0, #925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 10, 'ANTIMISSILE TECH2 STRUCTURE' }},
            #{ TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 0, 'Artillery' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.TECH2 * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T2MissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2 Base D AA Engineer - Response',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 20, 'DEFENSE TECH2 ANTIAIR STRUCTURE' }},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.DEFENSE * categories.TECH3 * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE}},
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 1, 'Air' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.TECH2 * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T2AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2 Base D Artillery',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 0, #925,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 10, 'ARTILLERY TECH2 STRUCTURE' }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            #{ TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 10, 'Structures' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            #{ UCBC, 'CheckUnitRange', { 'LocationType', 'T2Artillery', categories.STRUCTURE + (categories.LAND * (categories.TECH2 + categories.TECH3)) } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildStructures = {
                    'T2Artillery',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2TMLEngineer',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 0, #925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 8, categories.TACTICALMISSILEPLATFORM * categories.STRUCTURE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            #{ UCBC, 'CheckUnitRange', { 'LocationType', 'T2StrategicMissile', categories.STRUCTURE + (categories.LAND * (categories.TECH2 + categories.TECH3)) } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
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
    BuilderGroupName = 'SorianT2ArtilleryFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Sorian T2 TML Silo',
        PlatoonTemplate = 'T2TacticalLauncherSorian',
        Priority = 1,
        InstanceCount = 1000,
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T2 Artillery',
        PlatoonTemplate = 'T2ArtilleryStructureSorian',
        Priority = 1,
        InstanceCount = 1000,
        FormRadius = 10000,
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT3BaseDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T3 Base D Engineer AA',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 945,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 40, 'DEFENSE TECH3 ANTIAIR STRUCTURE'}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSPRODUCTION * categories.TECH3 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.TECH3 * categories.STRUCTURE * (categories.ANTIAIR + categories.DIRECTFIRE) } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T3AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Base D Engineer AA - Response',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 948,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 15, 'DEFENSE TECH3 ANTIAIR STRUCTURE' }},
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 1, 'Air' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.TECH3 * categories.STRUCTURE * (categories.ANTIAIR + categories.DIRECTFIRE) } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T3AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Base D Engineer AA - Exp Response',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 1300,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 30, 'DEFENSE TECH3 ANTIAIR STRUCTURE'}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'UnitCapCheckLess', { .8 } },
            #{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, 'EXPERIMENTAL AIR', 'Enemy'}},
            { SBC, 'T4ThreatExists', {{'Air'}, categories.AIR}},
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T3AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2TMLEngineer - Exp Response',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 1300,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 8, categories.TACTICALMISSILEPLATFORM * categories.STRUCTURE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            #{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, 'EXPERIMENTAL LAND', 'Enemy'}},
            { SBC, 'T4ThreatExists', {{'Land'}, categories.LAND}},
            #{ UCBC, 'CheckUnitRange', { 'LocationType', 'T2StrategicMissile', categories.STRUCTURE + (categories.LAND * (categories.TECH2 + categories.TECH3)) } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T2StrategicMissile',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Base D Engineer PD - Exp Response',
        PlatoonTemplate = 'UEFT3EngineerBuilderSorian',
        Priority = 1300,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 10, 'DEFENSE TECH3 DIRECTFIRE STRUCTURE'}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSPRODUCTION * categories.TECH3 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.TECH3 * categories.STRUCTURE * (categories.ANTIAIR + categories.DIRECTFIRE) } },
            { SBC, 'T4ThreatExists', {{'Land'}, categories.LAND}},
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T3GroundDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Base D Engineer PD',
        PlatoonTemplate = 'UEFT3EngineerBuilderSorian',
        Priority = 945,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 15, 'DEFENSE TECH3 DIRECTFIRE STRUCTURE'}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSPRODUCTION * categories.TECH3 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.TECH3 * categories.STRUCTURE * (categories.ANTIAIR + categories.DIRECTFIRE) } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T3GroundDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT2BaseDefenses - Emerg',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T2 Base D AA Engineer - Response R',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 10, 'DEFENSE TECH2 ANTIAIR STRUCTURE' }},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.DEFENSE * categories.TECH3 * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE}},
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 1, 'Air' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.TECH2 * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T2AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2 Base D Engineer PD - Response R',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 10, 'DEFENSE TECH2 DIRECTFIRE STRUCTURE' }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENERGYPRODUCTION TECH2'}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.TECH2 * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T2GroundDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT3BaseDefenses - Emerg',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T3 Base D AA Engineer - Response R',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 10, 'DEFENSE TECH3 ANTIAIR STRUCTURE' }},
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 1, 'Air' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.TECH3 * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T3AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Base D Engineer AA - Exp Response R',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 1300,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 30, 'DEFENSE TECH3 ANTIAIR STRUCTURE'}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'UnitCapCheckLess', { .8 } },
            #{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, 'EXPERIMENTAL AIR', 'Enemy'}},
            { SBC, 'T4ThreatExists', {{'Air'}, categories.AIR}},
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T3AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2TMLEngineer - Exp Response R',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 1300,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 8, categories.TACTICALMISSILEPLATFORM * categories.STRUCTURE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            #{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, 'EXPERIMENTAL LAND', 'Enemy'}},
            { SBC, 'T4ThreatExists', {{'Land'}, categories.LAND}},
            #{ UCBC, 'CheckUnitRange', { 'LocationType', 'T2StrategicMissile', categories.STRUCTURE + (categories.LAND * (categories.TECH2 + categories.TECH3)) } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T2StrategicMissile',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Base D Engineer PD - Exp Response R',
        PlatoonTemplate = 'UEFT3EngineerBuilderSorian',
        Priority = 1300,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 10, 'DEFENSE TECH3 DIRECTFIRE STRUCTURE'}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSPRODUCTION * categories.TECH3 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.TECH3 * categories.STRUCTURE * (categories.ANTIAIR + categories.DIRECTFIRE) } },
            { SBC, 'T4ThreatExists', {{'Land'}, categories.LAND}},
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T3GroundDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

# Defenses surrounding the base in patrol points
BuilderGroup {
    BuilderGroupName = 'SorianT1PerimeterDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T1 Base D Engineer - Perimeter',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 910,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 20, categories.DEFENSE * categories.TECH1 * categories.STRUCTURE}},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH2'}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearBasePatrolPoints = true,
                BuildStructures = {
                    'T1AADefense',
                    'T1GroundDefense',
                    'T1AADefense',
                    'T1GroundDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT2PerimeterDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T2 Base D Engineer - Perimeter',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 930,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 30, categories.DEFENSE * categories.TECH2 * categories.STRUCTURE}},
            #{ UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH3'}},
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 4, 'FACTORY TECH3' }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearBasePatrolPoints = true,
                BuildStructures = {
                    'T2GroundDefense',
                    'T2AADefense',
                    'T2MissileDefense',
                    'T2Artillery',
                    'T2StrategicMissile',
                    'T2GroundDefense',
                    'T2AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT3PerimeterDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T3 Base D Engineer - Perimeter',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 948, #945,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 30, categories.DEFENSE * categories.TECH3 * categories.STRUCTURE * (categories.ANTIAIR + categories.DIRECTFIRE)}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearBasePatrolPoints = true,
                BuildStructures = {
                    'T3AADefense',
                    'T2GroundDefense',
                    'T2MissileDefense',
                    'T2Artillery',
                    'T2StrategicMissile',
                    'T2ShieldDefense',
                    'T3AADefense',
                    'T2GroundDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

# Defenses at defensive point markers
BuilderGroup {
    BuilderGroupName = 'SorianT1DefensivePoints',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T1 Defensive Point Engineer',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 900, #850,
        BuilderConditions = {
            # Most paramaters freaking ever Build Condition -- All the threat ones are optional
            ####                                   MarkerType   LocRadius       category      markerRad unitMax tMin tMax Rings tType
            { SIBC, 'DefensivePointNeedsStructure', { 'LocationType', 350, 'DEFENSE TECH1 STRUCTURE', 20,        4,     0,   1,   1, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, 'DEFENSE STRUCTURE' } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 350,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 4,
                MarkerUnitCategory = 'DEFENSE TECH1 STRUCTURE',
                BuildStructures = {
                'T1GroundDefense',
                'T1AADefense',
                'T1GroundDefense',
                'T1AADefense',
                },
            },
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT2DefensivePoints',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T2 Defensive Point Engineer UEF',
        PlatoonTemplate = 'UEFT2EngineerBuilderSorian',
        Priority = 900, #875,
        InstanceCount = 1,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { SIBC, 'DefensivePointNeedsStructure', { 'LocationType', 1000, 'DEFENSE TECH2 STRUCTURE, DEFENSE TECH3 STRUCTURE', 20, 4, 0, 1, 1, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, 'DEFENSE STRUCTURE' } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 4,
                MarkerUnitCategory = 'DEFENSE TECH2 STRUCTURE, DEFENSE TECH3 STRUCTURE',
                BuildStructures = {
                    'T2GroundDefense',
                    'T2AADefense',
                    'T2MissileDefense',
                    'T2ShieldDefense',
                    'T2StrategicMissile',
                    'T2Artillery',
                    'T2EngineerSupport',
                    'T2ShieldDefense',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2 Defensive Point Engineer Cybran',
        PlatoonTemplate = 'CybranT2EngineerBuilderSorian',
        Priority = 900, #875,
        InstanceCount = 1,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { SIBC, 'DefensivePointNeedsStructure', { 'LocationType', 1000, 'DEFENSE TECH2 STRUCTURE, DEFENSE TECH3 STRUCTURE', 20, 4, 0, 1, 1, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, 'DEFENSE STRUCTURE' } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 4,
                MarkerUnitCategory = 'DEFENSE TECH2 STRUCTURE, DEFENSE TECH3 STRUCTURE',
                BuildStructures = {
                    'T2GroundDefense',
                    'T2AADefense',
                    'T2MissileDefense',
                    'T2ShieldDefense',
                    'T2StrategicMissile',
                    'T2Artillery',
                    'T2EngineerSupport',
                    'T2ShieldDefense',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2 Defensive Point Engineer',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 900, #875,
        InstanceCount = 1,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { SIBC, 'DefensivePointNeedsStructure', { 'LocationType', 1000, 'DEFENSE TECH2 STRUCTURE, DEFENSE TECH3 STRUCTURE', 20, 4, 0, 1, 1, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, 'DEFENSE STRUCTURE' } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
            { MIBC, 'FactionIndex', {2, 4}},
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 4,
                MarkerUnitCategory = 'DEFENSE TECH2 STRUCTURE, DEFENSE TECH3 STRUCTURE',
                BuildStructures = {
                    'T2GroundDefense',
                    'T2AADefense',
                    'T2MissileDefense',
                    'T2ShieldDefense',
                    'T2StrategicMissile',
                    'T2Artillery',
                    'T2ShieldDefense',
                }
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT3DefensivePoints',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T3 Defensive Point Engineer UEF',
        PlatoonTemplate = 'UEFT3EngineerBuilderSorian',
        Priority = 900,
        InstanceCount = 1,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'DefensivePointNeedsStructure', { 'LocationType', 2000, 'DEFENSE TECH3 STRUCTURE', 20, 2, 0, 1, 1, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, 'DEFENSE STRUCTURE' } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 2000,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 2,
                MarkerUnitCategory = 'DEFENSE TECH3 STRUCTURE',
                BuildStructures = {
                    'T3GroundDefense',
                    'T3AADefense',
                    'T2MissileDefense',
                    'T2ShieldDefense',
                    'T2StrategicMissile',
                    'T2Artillery',
                    'T2EngineerSupport',
                    'T2ShieldDefense',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Defensive Point Engineer Cybran',
        PlatoonTemplate = 'CybranT3EngineerBuilderSorian',
        Priority = 900,
        InstanceCount = 1,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'DefensivePointNeedsStructure', { 'LocationType', 2000, 'DEFENSE TECH3 STRUCTURE', 20, 2, 0, 1, 1, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, 'DEFENSE STRUCTURE' } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 2000,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 2,
                MarkerUnitCategory = 'DEFENSE TECH3 STRUCTURE',
                BuildStructures = {
                    'T2GroundDefense',
                    'T3AADefense',
                    'T2MissileDefense',
                    'T2ShieldDefense',
                    'T2StrategicMissile',
                    'T2Artillery',
                    'T2EngineerSupport',
                    'T2ShieldDefense',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Defensive Point Engineer',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 900,
        InstanceCount = 1,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'DefensivePointNeedsStructure', { 'LocationType', 2000, 'DEFENSE TECH3 STRUCTURE', 20, 2, 0, 1, 1, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, 'DEFENSE STRUCTURE' } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
            { MIBC, 'FactionIndex', {2, 4}},
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 2000,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 2,
                MarkerUnitCategory = 'DEFENSE TECH3 STRUCTURE',
                BuildStructures = {
                    'T2GroundDefense',
                    'T3AADefense',
                    'T2MissileDefense',
                    'T2ShieldDefense',
                    'T2StrategicMissile',
                    'T2Artillery',
                    'T2ShieldDefense',
                }
            }
        }
    },
}

# Defenses at defensive point markers
BuilderGroup {
    BuilderGroupName = 'SorianT1DefensivePoints Turtle',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T1 Turtle Defensive Point Engineer',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 950,
        BuilderConditions = {
            # Most paramaters freaking ever Build Condition -- All the threat ones are optional
            ####                                   MarkerType   LocRadius       category      markerRad unitMax tMin tMax Rings tType
            { SIBC, 'DefensivePointNeedsStructure', { 'LocationType', 350, 'DEFENSE TECH1 STRUCTURE', 20,        4,     0,   1,   1, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, 'DEFENSE STRUCTURE' } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 350,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 4,
                MarkerUnitCategory = 'DEFENSE TECH1 STRUCTURE',
                BuildStructures = {
                'T1GroundDefense',
                'T1AADefense',
                'T1GroundDefense',
                'T1AADefense',
                },
            },
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT2DefensivePoints Turtle',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T2 Turtle Defensive Point Engineer UEF',
        PlatoonTemplate = 'UEFT2EngineerBuilderSorian',
        Priority = 950,
        InstanceCount = 1,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { SIBC, 'DefensivePointNeedsStructure', { 'LocationType', 1000, 'DEFENSE TECH2 STRUCTURE, DEFENSE TECH3 STRUCTURE', 20, 4, 0, 1, 1, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, 'DEFENSE STRUCTURE' } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 4,
                MarkerUnitCategory = 'DEFENSE TECH2 STRUCTURE, DEFENSE TECH3 STRUCTURE',
                BuildStructures = {
                    'T2GroundDefense',
                    'T2AADefense',
                    'T2MissileDefense',
                    'T2ShieldDefense',
                    'T2StrategicMissile',
                    'T2Artillery',
                    'T2EngineerSupport',
                    'T2GroundDefense',
                    'T2AADefense',
                    'T2ShieldDefense',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2 Turtle Defensive Point Engineer Cybran',
        PlatoonTemplate = 'CybranT2EngineerBuilderSorian',
        Priority = 950,
        InstanceCount = 1,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { SIBC, 'DefensivePointNeedsStructure', { 'LocationType', 1000, 'DEFENSE TECH2 STRUCTURE, DEFENSE TECH3 STRUCTURE', 20, 4, 0, 1, 1, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, 'DEFENSE STRUCTURE' } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 4,
                MarkerUnitCategory = 'DEFENSE TECH2 STRUCTURE, DEFENSE TECH3 STRUCTURE',
                BuildStructures = {
                    'T2GroundDefense',
                    'T2AADefense',
                    'T2MissileDefense',
                    'T2ShieldDefense',
                    'T2StrategicMissile',
                    'T2Artillery',
                    'T2EngineerSupport',
                    'T2GroundDefense',
                    'T2AADefense',
                    'T2ShieldDefense',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2 Turtle Defensive Point Engineer',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 950,
        InstanceCount = 1,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { SIBC, 'DefensivePointNeedsStructure', { 'LocationType', 1000, 'DEFENSE TECH2 STRUCTURE, DEFENSE TECH3 STRUCTURE', 20, 4, 0, 1, 1, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, 'DEFENSE STRUCTURE' } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
            { MIBC, 'FactionIndex', {2, 4}},
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 4,
                MarkerUnitCategory = 'DEFENSE TECH2 STRUCTURE, DEFENSE TECH3 STRUCTURE',
                BuildStructures = {
                    'T2GroundDefense',
                    'T2AADefense',
                    'T2MissileDefense',
                    'T2ShieldDefense',
                    'T2StrategicMissile',
                    'T2Artillery',
                    'T2GroundDefense',
                    'T2AADefense',
                    'T2ShieldDefense',
                }
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT3DefensivePoints Turtle',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T3 Turtle Defensive Point Engineer UEF',
        PlatoonTemplate = 'UEFT3EngineerBuilderSorian',
        Priority = 950,
        InstanceCount = 1,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'DefensivePointNeedsStructure', { 'LocationType', 2000, 'DEFENSE TECH3 STRUCTURE', 20, 2, 0, 1, 1, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, 'DEFENSE STRUCTURE' } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 2000,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 2,
                MarkerUnitCategory = 'DEFENSE TECH3 STRUCTURE',
                BuildStructures = {
                    'T3GroundDefense',
                    'T3AADefense',
                    'T2MissileDefense',
                    'T2ShieldDefense',
                    'T2StrategicMissile',
                    'T2Artillery',
                    'T2EngineerSupport',
                    'T3GroundDefense',
                    'T3AADefense',
                    'T2ShieldDefense',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Turtle Defensive Point Engineer Cybran',
        PlatoonTemplate = 'CybranT3EngineerBuilderSorian',
        Priority = 950,
        InstanceCount = 1,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'DefensivePointNeedsStructure', { 'LocationType', 2000, 'DEFENSE TECH3 STRUCTURE', 20, 2, 0, 1, 1, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, 'DEFENSE STRUCTURE' } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 2000,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 2,
                MarkerUnitCategory = 'DEFENSE TECH3 STRUCTURE',
                BuildStructures = {
                    'T2GroundDefense',
                    'T3AADefense',
                    'T2MissileDefense',
                    'T2ShieldDefense',
                    'T2StrategicMissile',
                    'T2Artillery',
                    'T2EngineerSupport',
                    'T2GroundDefense',
                    'T3AADefense',
                    'T2ShieldDefense',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Turtle Defensive Point Engineer',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 950,
        InstanceCount = 1,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'DefensivePointNeedsStructure', { 'LocationType', 2000, 'DEFENSE TECH3 STRUCTURE', 20, 2, 0, 1, 1, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, 'DEFENSE STRUCTURE' } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
            { MIBC, 'FactionIndex', {2, 4}},
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true,
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 2000,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 2,
                MarkerUnitCategory = 'DEFENSE TECH3 STRUCTURE',
                BuildStructures = {
                    'T2GroundDefense',
                    'T3AADefense',
                    'T2MissileDefense',
                    'T2ShieldDefense',
                    'T2StrategicMissile',
                    'T2Artillery',
                    'T2GroundDefense',
                    'T3AADefense',
                    'T2ShieldDefense',
                }
            }
        }
    },
}

# Defenses at naval markers where a naval factory would be built
BuilderGroup {
    BuilderGroupName = 'SorianT1NavalDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T1 Naval D Engineer',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 900,
        BuilderConditions = {
            { UCBC, 'NavalDefensivePointNeedsStructure', { 'LocationType', 300, 'DEFENSE TECH1 ANTINAVY', 20, 3, 0, 1, 1, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE } },
            { UCBC, 'UnitCapCheckLess', { .7 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Naval Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 300,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 3,
                MarkerUnitCategory = 'DEFENSE TECH1 ANTINAVY',
                BuildStructures = {
                    'T1NavalDefense',
                    'T1GroundDefense',
                },
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T1 Base D Naval AA Engineer',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 900,
        BuilderConditions = {
            { UCBC, 'NavalDefensivePointNeedsStructure', { 'LocationType', 300, 'DEFENSE TECH1 ANTIAIR', 20, 2, 0, 1, 1, 'AntiSurface' } },
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 1, 'Air' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE } },
            { UCBC, 'UnitCapCheckLess', { .7 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Naval Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 300,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 2,
                MarkerUnitCategory = 'DEFENSE TECH1 ANTIAIR',
                BuildStructures = {
                    'T1AADefense',
                },
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT2NavalDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T2 Naval D Engineer',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'NavalDefensivePointNeedsStructure', { 'LocationType', 300, 'DEFENSE TECH2 ANTINAVY', 20, 3, 0, 1, 1, 'AntiSurface' } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE } },
            { UCBC, 'UnitCapCheckLess', { .7 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Naval Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 300,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 3,
                MarkerUnitCategory = 'DEFENSE TECH2 ANTINAVY',
                BuildStructures = {
                    'T2NavalDefense',
                    'T2Artillery',
                },
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2 Base D Naval AA Engineer',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'NavalDefensivePointNeedsStructure', { 'LocationType', 300, 'DEFENSE TECH2 ANTIAIR', 20, 2, 0, 1, 1, 'AntiSurface' } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 1, 'Air' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE } },
            { UCBC, 'UnitCapCheckLess', { .7 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Naval Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 300,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 2,
                MarkerUnitCategory = 'DEFENSE TECH2 ANTIAIR',
                BuildStructures = {
                    'T2AADefense',
                },
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT3NavalDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T3 Naval D Engineer',
        PlatoonTemplate = 'CybranT3EngineerBuilderSorian',
        Priority = 945,
        BuilderConditions = {
            { UCBC, 'NavalDefensivePointNeedsStructure', { 'LocationType', 300, 'DEFENSE TECH3 ANTINAVY', 20, 3, 0, 1, 1, 'AntiSurface' } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Naval Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 300,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 3,
                MarkerUnitCategory = 'DEFENSE TECH3 ANTINAVY',
                BuildStructures = {
                    'T3NavalDefense',
                    'T2Artillery',
                },
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Base D Naval AA Engineer',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 945,
        BuilderConditions = {
            { UCBC, 'NavalDefensivePointNeedsStructure', { 'LocationType', 300, 'DEFENSE TECH3 ANTIAIR', 20, 2, 0, 1, 1, 'AntiSurface' } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 1, 'Air' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.STRUCTURE - categories.SHIELD - categories.ANTIMISSILE } },
            { UCBC, 'UnitCapCheckLess', { .7 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Naval Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 300,
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 2,
                MarkerUnitCategory = 'DEFENSE TECH3 ANTIAIR',
                BuildStructures = {
                    'T3AADefense',
                },
            }
        }
    },
}

# Shields
BuilderGroup {
    BuilderGroupName = 'SorianT2Shields',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T2 Shield D Engineer Near Energy Production',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 930,
        BuilderConditions = {
            #{ UCBC, 'HaveLessThanUnitsWithCategory', { 10, categories.SHIELD * categories.TECH2 * categories.STRUCTURE}},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 6, categories.SHIELD * categories.TECH2 * categories.STRUCTURE }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiency', { 0.9, 1.2 } },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, 'SHIELD STRUCTURE' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                AdjacencyCategory = 'FACTORY, ENERGYPRODUCTION EXPERIMENTAL, ENERGYPRODUCTION TECH3, ENERGYPRODUCTION TECH2',
                AdjacencyDistance = 100,
                BuildClose = false,
                BuildStructures = {
                    'T2ShieldDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT2ShieldsExpansion',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T2 Shield D Engineer Near Factory Expansion',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 925,
        BuilderConditions = {
            #{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.SHIELD * categories.TECH2 * categories.STRUCTURE}},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, categories.SHIELD * categories.TECH2 * categories.STRUCTURE }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiency', { 0.9, 1.2 } },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, 'SHIELD STRUCTURE TECH2' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                AdjacencyCategory = 'FACTORY, ENERGYPRODUCTION EXPERIMENTAL, ENERGYPRODUCTION TECH3, ENERGYPRODUCTION TECH2',
                AdjacencyDistance = 100,
                BuildClose = false,
                BuildStructures = {
                    'T2ShieldDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianShieldUpgrades',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Sorian T2 Shield Cybran 1',
        PlatoonTemplate = 'T2Shield1',
        Priority = 5,
        InstanceCount = 5,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconIncome',  { 5, 150}},
            { MIBC, 'FactionIndex', {3}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T2 Shield Cybran 2',
        PlatoonTemplate = 'T2Shield2',
        Priority = 5,
        InstanceCount = 5,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconIncome',  { 5, 200}},
            { MIBC, 'FactionIndex', {3}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T2 Shield Cybran 3',
        PlatoonTemplate = 'T2Shield3',
        Priority = 5,
        InstanceCount = 5,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconIncome',  { 5, 300}},
            { MIBC, 'FactionIndex', {3}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T2 Shield Cybran 4',
        PlatoonTemplate = 'T2Shield4',
        Priority = 5,
        InstanceCount = 5,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconIncome',  { 5, 400}},
            { MIBC, 'FactionIndex', {3}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T2 Shield UEF Seraphim',
        PlatoonTemplate = 'T2Shield',
        Priority = 5,
        InstanceCount = 2,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconIncome',  { 7, 350}},
            { MIBC, 'FactionIndex', {1, 4}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 10, categories.SHIELD * categories.TECH3 * categories.STRUCTURE} },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
        },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT3Shields',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T3 Shield D Engineer Factory Adj',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 950,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.ENGINEER * categories.TECH3}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 10, categories.SHIELD * categories.TECH3 * categories.STRUCTURE} },
            { MIBC, 'FactionIndex', {1, 2, 4}},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, 'SHIELD STRUCTURE TECH3' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                AdjacencyCategory = 'FACTORY, STRUCTURE EXPERIMENTAL, ENERGYPRODUCTION TECH3, ENERGYPRODUCTION TECH2',
                AdjacencyDistance = 100,
                BuildClose = false,
                BuildStructures = {
                    'T3ShieldDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Shield D Engineer Factory Adj Cybran',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 950,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.ENGINEER * categories.TECH3}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 16, categories.SHIELD * categories.TECH2 * categories.STRUCTURE} },
            { MIBC, 'FactionIndex', {3}},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, 'SHIELD STRUCTURE TECH2' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                AdjacencyCategory = 'FACTORY, STRUCTURE EXPERIMENTAL, ENERGYPRODUCTION TECH3, ENERGYPRODUCTION TECH2',
                AdjacencyDistance = 100,
                BuildClose = false,
                BuildStructures = {
                    'T2ShieldDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT3ShieldsExpansion',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T3 Shield D Engineer Near Factory Expansion',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 940,
        BuilderConditions = {
            #{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.SHIELD * categories.TECH2 * categories.STRUCTURE}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.ENGINEER * categories.TECH3}},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, categories.SHIELD * categories.TECH3 * categories.STRUCTURE }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3} },
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'FactionIndex', {1, 2, 4}},
            { SIBC, 'GreaterThanEconEfficiency', { 0.9, 1.2 } },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, 'SHIELD STRUCTURE TECH2' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                AdjacencyCategory = 'FACTORY, ENERGYPRODUCTION EXPERIMENTAL, ENERGYPRODUCTION TECH3, ENERGYPRODUCTION TECH2',
                AdjacencyDistance = 100,
                BuildClose = false,
                BuildStructures = {
                    'T3ShieldDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Shield D Engineer Near Factory Expansion Cybran',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 940,
        BuilderConditions = {
            #{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.SHIELD * categories.TECH2 * categories.STRUCTURE}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.ENGINEER * categories.TECH3}},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 6, categories.SHIELD * categories.TECH2 * categories.STRUCTURE }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3} },
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'FactionIndex', {3}},
            { SIBC, 'GreaterThanEconEfficiency', { 0.9, 1.2 } },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, 'SHIELD STRUCTURE TECH2' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                AdjacencyCategory = 'FACTORY, ENERGYPRODUCTION EXPERIMENTAL, ENERGYPRODUCTION TECH3, ENERGYPRODUCTION TECH2',
                AdjacencyDistance = 100,
                BuildClose = false,
                BuildStructures = {
                    'T2ShieldDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

# Anti nuke defenses
BuilderGroup {
    BuilderGroupName = 'SorianT3NukeDefensesExp',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T3 Anti-Nuke Engineer Near Factory Expansion',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 935,
        BuilderConditions = {
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.ENGINEER * categories.TECH3}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSPRODUCTION * categories.TECH3 } },
            { UCBC, 'BuildingLessAtLocation', { 'LocationType', 1, 'ANTIMISSILE TECH3 STRUCTURE' } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.ANTIMISSILE * categories.TECH3 * categories.STRUCTURE}},
            #{ SIBC, 'GreaterThanEconIncome', { 2.5, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'EngineerNeedsAssistance', { false, 'LocationType', {'ANTIMISSILE TECH3 STRUCTURE'} }},
            { UCBC, 'UnitCapCheckLess', { .95 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                AdjacencyCategory = 'FACTORY -NAVAL',
                AdjacencyDistance = 100,
                BuildStructures = {
                    'T3StrategicMissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

# Anti nuke defenses
BuilderGroup {
    BuilderGroupName = 'SorianT3NukeDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T3 Anti-Nuke Engineer Near Factory - First',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 960,
        InstanceCount = 1,
        BuilderConditions = {
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.ENGINEER * categories.TECH3}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSPRODUCTION * categories.TECH3 } },
            { UCBC, 'BuildingLessAtLocation', { 'LocationType', 1, 'ANTIMISSILE TECH3 STRUCTURE' } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.ANTIMISSILE * categories.TECH3 * categories.STRUCTURE}},
            #{ SIBC, 'GreaterThanEconIncome', { 2.5, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'EngineerNeedsAssistance', { false, 'LocationType', {'ANTIMISSILE TECH3 STRUCTURE'} }},
            { UCBC, 'UnitCapCheckLess', { .95 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                AdjacencyCategory = 'FACTORY -NAVAL',
                AdjacencyDistance = 100,
                BuildStructures = {
                    'T3StrategicMissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Anti-Nuke Engineer Near Factory',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 0, #945,
        InstanceCount = 1,
        BuilderConditions = {
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.ENGINEER * categories.TECH3}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSPRODUCTION * categories.TECH3 } },
            { UCBC, 'BuildingLessAtLocation', { 'LocationType', 1, 'ANTIMISSILE TECH3 STRUCTURE' } },
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 0, categories.ANTIMISSILE * categories.TECH3 * categories.STRUCTURE}},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, categories.ANTIMISSILE * categories.TECH3 * categories.STRUCTURE}},
            #{ SIBC, 'GreaterThanEconIncome', { 2.5, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'EngineerNeedsAssistance', { false, 'LocationType', {'ANTIMISSILE TECH3 STRUCTURE'} }},
            { UCBC, 'UnitCapCheckLess', { .95 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                AdjacencyCategory = 'FACTORY -NAVAL',
                AdjacencyDistance = 100,
                BuildStructures = {
                    'T3StrategicMissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Anti-Nuke Engineer - Emerg',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 1301,
        InstanceCount = 1,
        BuilderConditions = {
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.ENGINEER * categories.TECH3}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSPRODUCTION * categories.TECH3 } },
            { UCBC, 'BuildingLessAtLocation', { 'LocationType', 1, 'ANTIMISSILE TECH3 STRUCTURE' } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.ANTIMISSILE * categories.TECH3 * categories.STRUCTURE}},
            #{ SIBC, 'GreaterThanEconIncome', { 2.5, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'UnitCapCheckLess', { .95 } },
            { SIBC, 'EngineerNeedsAssistance', { false, 'LocationType', {'ANTIMISSILE TECH3 STRUCTURE'} }},
            { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, 'NUKE SILO STRUCTURE', 'Enemy'}},
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 8,
            Construction = {
                BuildClose = false,
                AdjacencyCategory = 'FACTORY -NAVAL',
                AdjacencyDistance = 100,
                BuildStructures = {
                    'T3StrategicMissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Anti-Nuke Engineer - Emerg 2',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 1301,
        InstanceCount = 1,
        BuilderConditions = {
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.ENGINEER * categories.TECH3}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSPRODUCTION * categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ANTIMISSILE TECH3 STRUCTURE' } },
            { UCBC, 'BuildingLessAtLocation', { 'LocationType', 1, 'ANTIMISSILE TECH3 STRUCTURE' } },
            { SBC, 'HaveComparativeUnitsWithCategoryAndAllianceAtLocation', { 'LocationType', true, categories.ANTIMISSILE * categories.TECH3 * categories.STRUCTURE, categories.STRUCTURE * categories.NUKE * categories.TECH3, 'Enemy'}},
            #{ SIBC, 'GreaterThanEconIncome', { 2.5, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'EngineerNeedsAssistance', { false, 'LocationType', {'ANTIMISSILE TECH3 STRUCTURE'} }},
            { UCBC, 'UnitCapCheckLess', { .95 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 8,
            Construction = {
                BuildClose = false,
                AdjacencyCategory = 'FACTORY -NAVAL',
                AdjacencyDistance = 100,
                BuildStructures = {
                    'T3StrategicMissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Engineer Assist Anti-Nuke Emerg',
        PlatoonTemplate = 'T3EngineerAssistSorian',
        Priority = 1302,
        InstanceCount = 8,
        BuilderConditions = {
            { UCBC, 'LocationEngineersBuildingGreater', { 'LocationType', 0, categories.ANTIMISSILE * categories.TECH3 * categories.STRUCTURE}},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.ANTIMISSILE * categories.TECH3 * categories.STRUCTURE}},
            { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, 'NUKE SILO STRUCTURE', 'Enemy'}},
            { IBC, 'BrainNotLowPowerMode', {} },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'EngineerNeedsAssistance', { true, 'LocationType', {'ANTIMISSILE TECH3 STRUCTURE'} }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistUntilFinished = true,
                AssistRange = 250,
                BeingBuiltCategories = {'ANTIMISSILE TECH3 STRUCTURE'},
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Engineer Assist Anti-Nuke Emerg 2',
        PlatoonTemplate = 'T3EngineerAssistSorian',
        Priority = 1302,
        InstanceCount = 8,
        BuilderConditions = {
            { UCBC, 'LocationEngineersBuildingGreater', { 'LocationType', 0, categories.ANTIMISSILE * categories.TECH3 * categories.STRUCTURE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ANTIMISSILE TECH3 STRUCTURE' } },
            { SBC, 'HaveComparativeUnitsWithCategoryAndAllianceAtLocation', { 'LocationType', true, categories.ANTIMISSILE * categories.TECH3 * categories.STRUCTURE, categories.STRUCTURE * categories.NUKE * categories.TECH3, 'Enemy'}},
            { IBC, 'BrainNotLowPowerMode', {} },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { SIBC, 'EngineerNeedsAssistance', { true, 'LocationType', {'ANTIMISSILE TECH3 STRUCTURE'} }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistUntilFinished = true,
                AssistRange = 250,
                BeingBuiltCategories = {'ANTIMISSILE TECH3 STRUCTURE'},
                Time = 60,
            },
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT3NukeDefenseBehaviors',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Sorian T3 Anti Nuke Silo',
        PlatoonTemplate = 'T3AntiNuke',
        Priority = 5,
        InstanceCount = 20,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT1LightDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T1 Base D Engineer - Light',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 8, 'DEFENSE STRUCTURE'}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T1GroundDefense',
                    'T1AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T1 Base D Engineer - Light - Emerg AA',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 1001,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, 'DEFENSE ANTIAIR STRUCTURE'}},
            { IBC, 'BrainNotLowPowerMode', {} },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T1AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T1 Base D Engineer - Light - Emerg PD',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 1001,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, 'DEFENSE DIRECTFIRE STRUCTURE'}},
            { IBC, 'BrainNotLowPowerMode', {} },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T1GroundDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT2MissileDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T2MissileDefenseEng',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 0, #925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 6, 'ANTIMISSILE TECH2 STRUCTURE' }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENERGYPRODUCTION TECH2' }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T2MissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2 Base D Anti-TML Engineer - Emerg Response',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 1200,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 6, 'ANTIMISSILE TECH2' }},
            { SBC, 'GreaterThanEnemyUnitsAroundBase', { 'LocationType', 0, 'TACTICALMISSILEPLATFORM TECH2 STRUCTURE', 256 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.ANTIMISSILE * categories.TECH2 } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T2MissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT2LightDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T2 Base D Engineer - Light',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 15, 'DEFENSE TECH2 STRUCTURE' }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENERGYPRODUCTION TECH2' }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T2GroundDefense',
                    'T2AADefense',
                    'T2MissileDefense',
                    'T2Artillery',
                    'T2StrategicMissile',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian Light T2 Artillery',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 930,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, 'ARTILLERY TECH2 STRUCTURE' }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            #{ TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 10, 'Structures' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'CheckUnitRange', { 'LocationType', 'T2Artillery', categories.STRUCTURE + (categories.LAND * (categories.TECH2 + categories.TECH3)) } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildStructures = {
                    'T2Artillery',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian Light T2TML',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 930,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, categories.TACTICALMISSILEPLATFORM}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'CheckUnitRange', { 'LocationType', 'T2StrategicMissile', categories.STRUCTURE + (categories.LAND * (categories.TECH2 + categories.TECH3)) } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
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
    BuilderGroupName = 'SorianT3LightDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T3 Base D Engineer AA - Light',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 6, 'DEFENSE TECH3 ANTIAIR STRUCTURE'}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T3AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Base D Engineer PD - Light',
        PlatoonTemplate = 'UEFT3EngineerBuilderSorian',
        Priority = 875,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 6, 'DEFENSE TECH3 DIRECTFIRE STRUCTURE'}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSPRODUCTION * categories.TECH3 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T3GroundDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianAirStagingExpansion',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T2 Air Staging Engineer Expansion',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 900,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.AIRSTAGINGPLATFORM}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.2 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T2AirStagingPlatform',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T1 Wall Builder Expansion',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 0,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'HaveAreaWithUnitsFewWalls', { 'LocationType', 200, 5, 'DEFENSE', false, false, false } },
        },
        BuilderData = {
            NumAssistees = 0,
            Construction = {
                BuildStructures = { 'Wall' },
                LocationType = 'LocationType',
                Wall = true,
                MarkerRadius = 200,
                MarkerUnitCount = 5,
                MarkerUnitCategory = 'DEFENSE',
            },
        },
    },
}

# Misc Defenses
BuilderGroup {
    BuilderGroupName = 'SorianMiscDefensesEngineerBuilders',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T1 Wall Builder',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 0,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'HaveAreaWithUnitsFewWalls', { 'LocationType', 200, 5, 'DEFENSE', false, false, false } },
        },
        BuilderData = {
            NumAssistees = 0,
            Construction = {
                BuildStructures = { 'Wall' },
                LocationType = 'LocationType',
                Wall = true,
                MarkerRadius = 200,
                MarkerUnitCount = 5,
                MarkerUnitCategory = 'DEFENSE',
            },
        },
    },
    Builder {
        BuilderName = 'Sorian T2 Air Staging Engineer',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 900,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, categories.AIRSTAGINGPLATFORM * categories.STRUCTURE}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.2 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T2AirStagingPlatform',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T1 Engineer Reclaim Enemy Walls',
        PlatoonTemplate = 'EngineerBuilderSorian',
        PlatoonAIPlan = 'ReclaimUnitsAI',
        Priority = 975,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
                { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 10, categories.WALL, 'Enemy'}},
            },
        BuilderType = 'Any',
        BuilderData = {
            Radius = 1000,
            Categories = {'WALL'},
            ThreatMin = -10,
            ThreatMax = 10000,
            ThreatRings = 1,
        },
    },
    Builder {
        BuilderName = 'Sorian T2 Engineer Reclaim Enemy Walls',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        PlatoonAIPlan = 'ReclaimUnitsAI',
        Priority = 975,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH2}},
                { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 10, categories.WALL, 'Enemy'}},
            },
        BuilderType = 'Any',
        BuilderData = {
            Radius = 1000,
            Categories = {'WALL'},
            ThreatMin = -10,
            ThreatMax = 10000,
            ThreatRings = 1,
        },
    },
    Builder {
        BuilderName = 'Sorian T3 Engineer Reclaim Enemy Walls',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        PlatoonAIPlan = 'ReclaimUnitsAI',
        Priority = 975,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH3}},
                { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 10, categories.WALL, 'Enemy'}},
            },
        BuilderType = 'Any',
        BuilderData = {
            Radius = 1000,
            Categories = {'WALL'},
            ThreatMin = -10,
            ThreatMax = 10000,
            ThreatRings = 1,
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT1ACUDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T1 ACU D Engineer',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 890,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 10, 'DEFENSE STRUCTURE'}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                NearUnitCategory = 'COMMAND',
                NearUnitRadius = 32000,
                BuildClose = false,
                BuildStructures = {
                    'T1AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT2ACUDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T2 ACU D Engineer',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 890,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 6, 'DEFENSE TECH2 STRUCTURE' }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENERGYPRODUCTION TECH2' }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                NearUnitCategory = 'COMMAND',
                NearUnitRadius = 32000,
                BuildClose = false,
                BuildStructures = {
                    'T2AADefense',
                    'T2MissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT2ACUShields',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T2 Shield D Engineer Near ACU',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 890,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.ENGINEER * categories.TECH2}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.SHIELD * categories.TECH2 * categories.STRUCTURE}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'FactionIndex', {2} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.2 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                NearUnitCategory = 'COMMAND',
                NearUnitRadius = 32000,
                BuildClose = false,
                BuildStructures = {
                    'T2ShieldDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}


BuilderGroup {
    BuilderGroupName = 'SorianT3ACUShields',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T3 Shield D Engineer Near ACU',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 890,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 8, categories.ENGINEER * categories.TECH3}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, categories.SHIELD * categories.STRUCTURE} },
            { MIBC, 'FactionIndex', {1, 2, 4}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                NearUnitCategory = 'COMMAND',
                NearUnitRadius = 32000,
                BuildClose = false,
                BuildStructures = {
                    'T3ShieldDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT3ACUNukeDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T3 Anti-Nuke Engineer Near ACU',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 890,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.ENGINEER * categories.TECH3}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'BuildingLessAtLocation', { 'LocationType', 1, 'ANTIMISSILE TECH3 STRUCTURE' } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.ANTIMISSILE * categories.TECH3 * categories.STRUCTURE}},
            #{ SIBC, 'GreaterThanEconIncome', { 2.5, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 5,
            Construction = {
                NearUnitCategory = 'COMMAND',
                NearUnitRadius = 32000,
                BuildClose = false,
                BuildStructures = {
                    'T3StrategicMissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}
