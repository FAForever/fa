#***************************************************************************
#*
#**  File     :  /lua/ai/AIEconomicBuilders.lua
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
local IBC = '/lua/editor/InstantBuildConditions.lua'
local OAUBC = '/lua/editor/OtherArmyUnitCountBuildConditions.lua'
local EBC = '/lua/editor/EconomyBuildConditions.lua'
local PCBC = '/lua/editor/PlatoonCountBuildConditions.lua'
local SAI = '/lua/ScenarioPlatoonAI.lua'
local TBC = '/lua/editor/ThreatBuildConditions.lua'
local PlatoonFile = '/lua/platoon.lua'

BuilderGroup {
    BuilderGroupName = 'EngineerFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    # ============
    #    TECH 1
    # ============
    Builder {
        BuilderName = 'T1 Engineer Disband - Init',
        PlatoonTemplate = 'T1BuildEngineer',
        Priority = 900,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 4, 'ENGINEER TECH1' }}, #DUNCAN - was 3
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'ENGINEER TECH1' } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech1' } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'T1 Engineer Disband - Filler 1',
        PlatoonTemplate = 'T1BuildEngineer',
        Priority = 800,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 9, 'ENGINEER TECH1' }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'ENGINEER TECH1' } },
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
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'ENGINEER TECH1' } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech1' } },
            { IBC, 'BrainNotLowMassMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'All',
    },

    # ============
    #    TECH 2
    # ============
    Builder {
        BuilderName = 'T2 Engineer Disband - Init',
        PlatoonTemplate = 'T2BuildEngineer',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH2' }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'ENGINEER TECH2' } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech2' } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'T2 Engineer Disband - Filler 1',
        PlatoonTemplate = 'T2BuildEngineer',
        Priority = 800,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 6, 'ENGINEER TECH2' }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'ENGINEER TECH2' } },
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
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'ENGINEER TECH2' } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech2' } },
            { IBC, 'BrainNotLowMassMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'All',
    },

    # ============
    #    TECH 3
    # ============
    Builder {
        BuilderName = 'T3 Engineer Disband - Init',
        PlatoonTemplate = 'T3BuildEngineer',
        Priority = 950,
        BuilderConditions = {
            { UCBC,'EngineerLessAtLocation', { 'LocationType', 6, 'ENGINEER TECH3' }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'ENGINEER TECH3' } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech3' } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'T3 Engineer Disband - Filler',
        PlatoonTemplate = 'T3BuildEngineer',
        Priority = 900,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 9, 'ENGINEER TECH3' }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'ENGINEER TECH3' } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech3' } },
            #{ UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'All',
    },
    Builder {
        BuilderName = 'T3 Engineer Disband - Filler 2',
        PlatoonTemplate = 'T3BuildEngineer',
        Priority = 800,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 12, 'ENGINEER TECH3' }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'ENGINEER TECH3' } },
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
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'ENGINEER TECH3' } },
            { UCBC, 'EngineerCapCheck', { 'LocationType', 'Tech3' } },
            { IBC, 'BrainNotLowMassMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'All',
    },

    # ====================
    #    SUB COMMANDERS
    # ====================
    Builder {
        BuilderName = 'T3 Sub Commander',
        PlatoonTemplate = 'T3LandSubCommander',
        Priority = 950, #DUNCAN - was 900
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.EXPERIMENTAL}}, #DUNCAN - Added
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 } }, #DUNCAN - was 0.95, 1.3
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
            { UCBC, 'UnitsLessAtLocation', { 'MAIN', 2, 'ENGINEER TECH2, ENGINEER TECH3' } },
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH2, ENGINEER TECH3' } },
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
            { UCBC, 'UnitsLessAtLocation', { 'MAIN', 2, 'ENGINEER TECH3' } },
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH3' } },
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

    # Initial builder
    Builder {
        BuilderName = 'CDR Initial Land Rush',
        PlatoonAddBehaviors = { 'CommanderBehavior', },
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
                    #DUNCAN - Altered build order
                    'T1LandFactory',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    #'T1Resource',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1LandFactory',
                    'T1EnergyProduction',
                    'T1LandFactory',
                }
            }
        }
    },
    Builder {
        BuilderName = 'CDR Initial PreBuilt Land Rush',
        PlatoonAddBehaviors = { 'CommanderBehavior', },
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

    # Initial builder
    Builder {
        BuilderName = 'CDR Initial Balanced',
        PlatoonAddBehaviors = { 'CommanderBehavior', },
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
                    #DUNCAN - Altered build order
                    'T1LandFactory',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    #'T1Resource',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    #'T1Resource',
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
        BuilderName = 'CDR Initial PreBuilt Balanced',
        PlatoonAddBehaviors = { 'CommanderBehavior', },
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

    # Initial builder
    Builder {
        BuilderName = 'CDR Initial Air Rush',
        PlatoonAddBehaviors = { 'CommanderBehavior', },
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
                    'T1AirFactory',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    #'T1Resource',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1AirFactory',
                }
            }
        }
    },
    Builder {
        BuilderName = 'CDR Initial PreBuilt Air Rush',
        PlatoonAddBehaviors = { 'CommanderBehavior', },
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

# NAVAL RUSH
BuilderGroup {
    BuilderGroupName = 'Naval Rush Initial ACU Builders',
    BuildersType = 'EngineerBuilder',

    # Initial builder
    Builder {
        BuilderName = 'CDR Initial Naval Rush',
        PlatoonAddBehaviors = { 'CommanderBehavior', },
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
                    #DUNCAN - order changed
                    'T1AirFactory',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    #'T1Resource',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1LandFactory',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                }
            }
        }
    },
    Builder {
        BuilderName = 'CDR Initial PreBuilt Naval',
        PlatoonAddBehaviors = { 'CommanderBehavior', },
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

    # Initial builder
    Builder {
        BuilderName = 'CDR Initial Default',
        PlatoonAddBehaviors = { 'CommanderBehavior', },
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
                    #DUNCAN - Altered build order
                    'T1LandFactory',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    #'T1Resource',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    #'T1Resource',
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
        BuilderName = 'CDR Initial PreBuilt Default',
        PlatoonAddBehaviors = { 'CommanderBehavior', },
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

    # After initial
    # Build on nearby mass locations
    Builder {
        BuilderName = 'CDR Single T1Resource',
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 0, #DUNCAN - was 950
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
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.5, 0.5 }}, #DUNCAN - was 0.8 mass check
            { EBC, 'LessThanEconEfficiencyOverTime', { 2.0, 1.4 }},
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, 'ENGINEER TECH2, ENGINEER TECH3' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                AdjacencyCategory = 'FACTORY',
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
            { UCBC, 'HaveLessThanUnitsWithCategory', { 0, 'DEFENSE TECH1' }},
            { MABC, 'MarkerLessThanDistance',  { 'Rally Point', 50 }},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.95, 1.2 } },
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

    # CDR Assisting
    Builder {
        BuilderName = 'CDR Assist T2/T3 Power',
        PlatoonTemplate = 'CommanderAssist',
        Priority = 700,
        BuilderConditions = {
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3' }},
            { EBC, 'LessThanEconEfficiencyOverTime', { 2.0, 1.5 }},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.5, 0.5 } },
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
        BuilderName = 'CDR Assist Experimental', #DUNCAN - added
        PlatoonTemplate = 'CommanderAssist',
        Priority = 701,
        BuilderConditions = {
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, 'EXPERIMENTAL' }},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.2 } },
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
        BuilderName = 'CDR Assist Engineer', #DUNCAN - added
        PlatoonTemplate = 'CommanderAssist',
        Priority = 500,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, 'ALLUNITS' } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.1 }},
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
    #Builder {
    #    BuilderName = 'CDR Assist Factory',
    #    PlatoonTemplate = 'CommanderAssist',
    #    Priority = 500,
    #    BuilderConditions = {
    #        { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1} },
    #        { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, 'MOBILE' }},
    #        { IBC, 'BrainNotLowPowerMode', {} },
    #    },
    #    BuilderType = 'Any',
    #    BuilderData = {
    #        Assist = {
    #            AssistLocation = 'LocationType',
    #            AssisteeType = 'Factory',
    #            BuilderCategories = {'FACTORY',},
    #            PermanentAssist = true,
    #            Time = 20,
    #        },
    #    }
    #},
    #Builder {
    #    BuilderName = 'CDR Assist Factory Upgrade Tech 2',
    #    PlatoonTemplate = 'CommanderAssist',
    #    Priority = 800,
    #    BuilderConditions = {
    #        { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, 'TECH2 FACTORY' } },
    #        { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY TECH2, FACTORY TECH3' } },
    #        { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 } },
    #        { IBC, 'BrainNotLowPowerMode', {} },
    #    },
    #    BuilderType = 'Any',
    #    BuilderData = {
    #        Assist = {
    #            AssistLocation = 'LocationType',
    #            AssisteeType = 'Factory',
    #            PermanentAssist = true,
    #            BeingBuiltCategories = {'FACTORY TECH2',},
    #            Time = 40,
    #        },
    #    }
    #},
    #Builder {
    #    BuilderName = 'CDR Assist Factory Upgrade Tech 3',
    #    PlatoonTemplate = 'CommanderAssist',
    #    Priority = 800,
    #    BuilderConditions = {
    #        { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, 'TECH3 FACTORY' } },
    #        { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'TECH3 FACTORY' } },
    #        { IBC, 'BrainNotLowPowerMode', {} },
    #        { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 } },
    #    },
    #    BuilderType = 'Any',
    #    BuilderData = {
    #        Assist = {
    #            AssistLocation = 'LocationType',
    #            AssisteeType = 'Factory',
    #            PermanentAssist = true,
    #            BeingBuiltCategories = {'FACTORY TECH3',},
    #            Time = 40,
    #        },
    #    }
    #},
    #Builder {
    #    BuilderName = 'CDR Assist Mass Extractor Upgrade',
    #    PlatoonTemplate = 'CommanderAssist',
    #    Priority = 0,
    #    BuilderConditions = {
    #        { UCBC, 'BuildingGreaterAtLocation', { 'LocationType', 0, 'TECH2 MASSEXTRACTION' } },
    #        { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3' } },
    #        { IBC, 'BrainNotLowPowerMode', {} },
    #    },
    #    BuilderType = 'Any',
    #    BuilderData = {
    #        Assist = {
    #            AssisteeType = 'Structure',
    #            AssistLocation = 'LocationType',
    #            BeingBuiltCategories = {'MASSEXTRACTION'},
    #            Time = 30,
    #        },
    #    }
    #},
}

BuilderGroup { #DUNCAN - added group
    BuilderGroupName = 'ACUUpgrades - Gun improvements',
    BuildersType = 'EngineerBuilder',
    # UEF
    Builder {
        BuilderName = 'UEF CDR Upgrade HeavyAntiMatter',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { MIBC, 'IsIsland', { false } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'FACTORY' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, 'MASSEXTRACTION' }},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, 'FACTORY TECH2, FACTORY TECH3' } },
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { UCBC, 'CmdrHasUpgrade', { 'HeavyAntiMatterCannon', false }},
                { MIBC, 'FactionIndex', {1, 1}},
                { MIBC, 'RandomNumber', {0, 6, 1, 10}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Enhancement = { 'HeavyAntiMatterCannon' },
        },

    },
    # Aeon
    Builder {
        BuilderName = 'Aeon CDR Upgrade Crysalis',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { MIBC, 'IsIsland', { false } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'FACTORY' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, 'MASSEXTRACTION' }},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, 'FACTORY TECH2, FACTORY TECH3' } },
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { UCBC, 'CmdrHasUpgrade', { 'CrysalisBeam', false }},
                { MIBC, 'FactionIndex', {2, 2}},
                { MIBC, 'RandomNumber', {0, 6, 1, 10}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            TimeBetweenEnhancements = 20,
            Enhancement = { 'HeatSink', 'CrysalisBeam'},
        },
    },
    # Cybran
    Builder {
        BuilderName = 'Cybran CDR Upgrade CoolingUpgrade',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { MIBC, 'IsIsland', { false } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'FACTORY' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, 'MASSEXTRACTION' }},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, 'FACTORY TECH2, FACTORY TECH3' } },
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { UCBC, 'CmdrHasUpgrade', { 'CoolingUpgrade', false }},
                { MIBC, 'FactionIndex', {3, 3}},
                { MIBC, 'RandomNumber', {0, 6, 1, 10}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Enhancement = { 'CoolingUpgrade'},
        },

    },
    # Seraphim
    Builder {
        BuilderName = 'Seraphim CDR Upgrade RateOfFire',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { MIBC, 'IsIsland', { false } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'FACTORY' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, 'MASSEXTRACTION' }},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, 'FACTORY TECH2, FACTORY TECH3' } },
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { UCBC, 'CmdrHasUpgrade', { 'RateOfFire', false }},
                { MIBC, 'FactionIndex', {4, 4}},
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
    # UEF
    Builder {
        BuilderName = 'UEF CDR Upgrade Adv Engi',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'TECH2 FACTORY' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'TECH2 MASSEXTRACTION' }},
                #{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'AdvancedEngineering', false }},
                { MIBC, 'FactionIndex', {1, 1}},
            },
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderType = 'Any',
        BuilderData = {
            Enhancement = { 'LeftPod', 'RightPod', 'AdvancedEngineering' },
        },
    },
    # Aeon
    Builder {
        BuilderName = 'Aeon CDR Upgrade Adv Engi, replacing Crysalis',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'TECH2 FACTORY' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'TECH2 MASSEXTRACTION' }},
                #{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'AdvancedEngineering', false }},
                { UCBC, 'CmdrHasUpgrade', { 'CrysalisBeam', true }},
                { MIBC, 'FactionIndex', {2, 2}},
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
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'TECH2 FACTORY' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'TECH2 MASSEXTRACTION' }},
                #{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'AdvancedEngineering', false }},
                { UCBC, 'CmdrHasUpgrade', { 'CrysalisBeam', false }},
                { MIBC, 'FactionIndex', {2, 2}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Enhancement = { 'AdvancedEngineering'},
        },

    },
    # Cybran
    Builder {
        BuilderName = 'Cybran CDR Upgrade Adv Engi, replacing cooling',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'TECH2 FACTORY' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'TECH2 MASSEXTRACTION' }},
                #{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'AdvancedEngineering', false }},
                { UCBC, 'CmdrHasUpgrade', { 'CoolingUpgrade', true}},
                { MIBC, 'FactionIndex', {3, 3}},
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
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'TECH2 FACTORY' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'TECH2 MASSEXTRACTION' }},
                #{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'AdvancedEngineering', false }},
                { UCBC, 'CmdrHasUpgrade', { 'CoolingUpgrade', false }},
                { MIBC, 'FactionIndex', {3, 3}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Enhancement = { 'AdvancedEngineering'},
        },

    },
    # Seraphim
    Builder {
        BuilderName = 'Seraphim CDR Upgrade Adv Engi',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'TECH2 FACTORY' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'TECH2 MASSEXTRACTION' }},
                #{ EBC, 'GreaterThanEconStorageRatio', { 0.25, 0.25}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'AdvancedEngineering', false }},
                { MIBC, 'FactionIndex', {4, 4}},
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
    # UEF
    Builder {
        BuilderName = 'UEF CDR Upgrade Shield, replaceing right pod',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'FACTORY TECH3' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, 'TECH3 MASSEXTRACTION' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH3' }},
                #{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'Shield', false }},
                { UCBC, 'CmdrHasUpgrade', { 'RightPod', true }},
                { MIBC, 'FactionIndex', {1, 1}},
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
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'FACTORY TECH3' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, 'TECH3 MASSEXTRACTION' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH3' }},
                #{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'Shield', false }},
                { UCBC, 'CmdrHasUpgrade', { 'RightPod', false }},
                { MIBC, 'FactionIndex', {1, 1}},
            },
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderType = 'Any',
        BuilderData = {
            Enhancement = { 'Shield' },
        },
    },
    # Aeon
    Builder {
        BuilderName = 'Aeon CDR Upgrade Shield',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'FACTORY TECH3' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, 'TECH3 MASSEXTRACTION' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH3' }},
                #{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'Shield', false }},
                { MIBC, 'FactionIndex', {2, 2}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Enhancement = { 'Shield' },
        },

    },
    # Cybran
    Builder {
        BuilderName = 'Cybran CDR Upgrade Stealth and Cloak',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'FACTORY TECH3' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, 'TECH3 MASSEXTRACTION' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'ENERGYPRODUCTION TECH3' }},
                #{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.4 }},
                { UCBC, 'CmdrHasUpgrade', { 'CloakingGenerator', false }},
                { MIBC, 'FactionIndex', {3, 3}},
            },
        BuilderType = 'Any',
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
        BuilderData = {
            Enhancement = { 'StealthGenerator', 'CloakingGenerator', 'MicrowaveLaserGenerator'},
        },

    },
    # Seraphim
    Builder {
        BuilderName = 'Seraphim CDR Upgrade AdvancedRegenAura',
        PlatoonTemplate = 'CommanderEnhance',
        Priority = 1000,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'FACTORY TECH3' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, 'TECH3 MASSEXTRACTION' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH3' }},
                #{ EBC, 'GreaterThanEconStorageRatio', { 0.25, 0.25}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { UCBC, 'CmdrHasUpgrade', { 'AdvancedRegenAura', false }},
                { MIBC, 'FactionIndex', {4, 4}},
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
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'FACTORY TECH3' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, 'TECH3 MASSEXTRACTION' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH3' }},
                #{ EBC, 'GreaterThanEconStorageRatio', { 0.25, 0.25}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { UCBC, 'CmdrHasUpgrade', { 'AdvancedRegenAura', false }},
                { UCBC, 'CmdrHasUpgrade', { 'RateOfFire', true }},
                { MIBC, 'FactionIndex', {4, 4}},
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
    # UEF
    Builder {
        BuilderName = 'UEF CDR Upgrade AdvEng - Pods',
        PlatoonTemplate = 'CommanderEnhance',
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'FACTORY TECH2, FACTORY TECH3' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3' }},
                { EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { MIBC, 'FactionIndex', {1, 1}},
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
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'FACTORY TECH2, FACTORY TECH3'}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3'}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3'}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { MIBC, 'FactionIndex', {1, 1}},
            },
        Priority = 0,
        BuilderType = 'Any',
        BuilderData = {
            Enhancement = { 'T3Engineering', 'RightPodRemove', 'Shield', 'ShieldGeneratorField'},
        },
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
    },

    # Aeon
    Builder {
        BuilderName = 'Aeon CDR Upgrade AdvEng - Resource - Crysalis',
        PlatoonTemplate = 'CommanderEnhance',
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'FACTORY TECH2, FACTORY TECH3'}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3'}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3'}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { MIBC, 'FactionIndex', {2, 2}},
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
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'FACTORY TECH2, FACTORY TECH3'}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3'}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3'}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { MIBC, 'FactionIndex', {2, 2}},
            },
        Priority = 0,
        BuilderType = 'Any',
        BuilderData = {
            Enhancement = { 'T3Engineering', 'ResourceAllocationAdvanced', 'EnhancedSensors'},
        },
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
    },

    # Cybran
    Builder {
        BuilderName = 'Cybran CDR Upgrade AdvEng - Laser Gen',
        PlatoonTemplate = 'CommanderEnhance',
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'FACTORY TECH2, FACTORY TECH3'}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3'}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3'}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { MIBC, 'FactionIndex', {3, 3}},
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
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'FACTORY TECH2, FACTORY TECH3'}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3'}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3'}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { MIBC, 'FactionIndex', {3, 3}},
            },
        Priority = 0,
        BuilderType = 'Any',
        BuilderData = {
            Enhancement = { 'T3Engineering', 'ResourceAllocation'},
        },
        PlatoonAddFunctions = { {SAI, 'BuildOnce'}, },
    },

    # Seraphim
    Builder {
        BuilderName = 'Seraphim CDR Upgrade AdvEng - Dmgstbl',
        PlatoonTemplate = 'CommanderEnhance',
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'FACTORY TECH2, FACTORY TECH3'}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3'}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3'}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.25, 0.25}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { MIBC, 'FactionIndex', {4, 4}},
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
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'FACTORY TECH2, FACTORY TECH3'}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3'}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENERGYPRODUCTION TECH3'}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.5, 0.5}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
                { MIBC, 'FactionIndex', {4, 4}},
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
    # =====================================
    #     T1 Engineer Resource Builders
    # =====================================
    Builder {
        BuilderName = 'T1 Hydrocarbon Engineer',
        PlatoonTemplate = 'EngineerBuilder',
        #DUNCAN - Changed from 850
        Priority = 980,
        BuilderConditions = {
                #DUNCAN - commented out
                #{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.ENGINEER * (categories.TECH2 + categories.TECH3) } },
                #DUNCAN - Changed to 3
                { UCBC, 'HaveLessThanUnitsWithCategory', { 3, 'HYDROCARBON'}},
                #DUNCAN - Added so doenst build before a few mass exs
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION'}},
                { MABC, 'MarkerLessThanDistance',  { 'Hydrocarbon', 200}}, #DUNCAN - was 150
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
        PlatoonTemplate = 'EngineerBuilder',
        PlatoonAIPlan = 'ReclaimAI',
        Priority = 900, #DUNCAN - was 950
        InstanceCount = 3,
        BuilderConditions = {
                { MIBC, 'ReclaimablesInArea', { 'LocationType', }},
            },
        BuilderData = {
            LocationType = 'LocationType',
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T1 Engineer Reclaim Excess',
        PlatoonTemplate = 'EngineerBuilder',
        PlatoonAIPlan = 'ReclaimAI',
        Priority = 2, #DUNCAN - was 1
        InstanceCount = 10,
        BuilderConditions = {
                { MIBC, 'ReclaimablesInArea', { 'LocationType', }},
            },
        BuilderData = {
            LocationType = 'LocationType',
            ReclaimTime = 30,
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
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.1, 1.1 }},
                { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, categories.TECH3 * categories.ENERGYPRODUCTION}},
                { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 0, categories.TECH1 * categories.ENERGYPRODUCTION * categories.DRAGBUILD }},
            },
        BuilderData = {
            Location = 'LocationType',
            Reclaim = {'STRUCTURE ENERGYPRODUCTION TECH1 DRAGBUILD'},
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
        #DUNCAN - changed from 925
        Priority = 800,
        BuilderConditions = {
            #DUNCAN - changed from 1
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3'}},
            { MABC, 'MarkerLessThanDistance',  { 'Mass', 100, -3, 0, 0}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { UCBC, 'AdjacencyCheck', { 'LocationType', 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3', 100, 'ueb1106' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'MASSEXTRACTION TECH3, MASSEXTRACTION TECH2',
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
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1,  'ENERGYSTORAGE' }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, 'ENERGYSTORAGE'}},
            #{ UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, 'ENERGYSTORAGE' }},
            { UCBC, 'UnitCapCheckLess', { .7 } },
            #{ EBC, 'GreaterThanEconStorageRatio', { 0.6, 0.6 }},
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
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, 'ENERGYSTORAGE' }},
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, 'ENERGYPRODUCTION TECH2' }},
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
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 2, 'ENERGYPRODUCTION TECH3' }}, #DUNCAN - was 0
            { UCBC, 'UnitCapCheckLess', { .7 } },
            { EBC, 'LessThanEconEfficiencyOverTime', { 2.0, 1.3 }},
            { UCBC, 'AdjacencyCheck', { 'LocationType', 'ENERGYPRODUCTION TECH3', 100, 'ueb1105' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'ENERGYPRODUCTION TECH3',
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

    # =========================
    #     T1 ENGINEER ASSIST
    # =========================
    #Builder {
    #    BuilderName = 'T1 Engineer Assist Factory',
    #    PlatoonTemplate = 'EngineerAssist',
    #    Priority = 600,
    #    BuilderConditions = {
    #        { IBC, 'BrainNotLowPowerMode', {} },
    #        { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, 'MOBILE' } },
    #        { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
    #    },
    #    InstanceCount = 5,
    #    BuilderType = 'Any',
    #    BuilderData = {
    #        Assist = {
    #            AssistLocation = 'LocationType',
    #            PermanentAssist = true,
    #            AssisteeType = 'Factory',
    #            Time = 30,
    #        },
    #    }
    #},
    #Builder {
    #    BuilderName = 'T1 Engineer Assist FactoryLowerPri',
    #    PlatoonTemplate = 'EngineerAssist',
    #    Priority = 500,
    #    InstanceCount = 50,
    #    BuilderConditions = {
    #        { IBC, 'BrainNotLowPowerMode', {} },
    #        { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, 'MOBILE' } },
    #        { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
    #    },
    #    BuilderType = 'Any',
    #    BuilderData = {
    #        Assist = {
    #            AssistLocation = 'LocationType',
    #            PermanentAssist = true,
    #            AssisteeType = 'Factory',
    #            Time = 30,
    #        },
    #    }
    #},
    #DUNCAN - uncommented
    Builder {
        BuilderName = 'T1 Engineer Assist Engineer',
        PlatoonTemplate = 'EngineerAssist',
        Priority = 1,
        InstanceCount = 20,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, 'ALLUNITS' } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                PermanentAssist = true,
                AssisteeType = 'Engineer',
                Time = 30,
            },
        }
    },
    #Builder {
    #    BuilderName = 'T1 Engineer Assist Shield',
    #    PlatoonTemplate = 'EngineerAssist',
    #    Priority = 825,
    #    BuilderConditions = {
    #        { IBC, 'BrainNotLowPowerMode', {} },
    #        { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, 'STRUCTURE SHIELD' }},
    #        { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
    #    },
    #    InstanceCount = 2,
    #    BuilderType = 'Any',
    #    BuilderData = {
    #        Assist = {
    #            AssistLocation = 'LocationType',
    #            AssisteeType = 'Engineer',
    #            BeingBuiltCategories = {'SHIELD STRUCTURE'},
    #            Time = 60,
    #        },
    #    }
    #},
    #Builder {
    #    BuilderName = 'T1 Engineer Assist Mass Upgrade',
    #    PlatoonTemplate = 'EngineerAssist',
    #    Priority = 850,
    #    BuilderConditions = {
    #        { IBC, 'BrainNotLowPowerMode', {} },
    #        { UCBC, 'BuildingGreaterAtLocation', { 'LocationType', 0, 'MASSEXTRACTION TECH2'}},
    #        { UCBC, 'HaveLessThanUnitsWithCategory', { 5, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3' } },
    #        { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
    #        { EBC, 'LessThanEconEfficiencyOverTime', { 1.5, 2.0 }},
    #    },
    #    InstanceCount = 2,
    #    BuilderType = 'Any',
    #    BuilderData = {
    #        Assist = {
    #            AssisteeType = 'Structure',
    #            AssistLocation = 'LocationType',
    #            BeingBuiltCategories = {'MASSEXTRACTION TECH2'},
    #            Time = 60,
    #        },
    #    }
    #},
    #Builder {
    #    BuilderName = 'T1 Engineer Assist Power',
    #    PlatoonTemplate = 'EngineerAssist',
    #    Priority = 900,
    #    BuilderConditions = {
    #        { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, 'ENERGYPRODUCTION' }},
    #        { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 0.8 }},
    #        { EBC, 'LessThanEconEfficiencyOverTime', { 2.0, 1.4 }},
    #    },
    #    InstanceCount = 2,
    #    BuilderType = 'Any',
    #    BuilderData = {
    #        Assist = {
    #            AssistLocation = 'LocationType',
    #            PermanentAssist = true,
    #            BeingBuiltCategories = {'ENERGYPRODUCTION TECH3', 'ENERGYPRODUCTION TECH2', 'ENERGYPRODUCTION'},
    #            AssisteeType = 'Engineer',
    #            Time = 60,
    #        },
    #    }
    #},
    #Builder {
    #    BuilderName = 'T1 Engineer Assist Transport',
    #    PlatoonTemplate = 'EngineerAssist',
    #    Priority = 875,
    #    BuilderConditions = {
    #        { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, 'TRANSPORTFOCUS' } },
    #        { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
    #    },
    #    InstanceCount = 2,
    #    BuilderType = 'Any',
    #    BuilderData = {
    #        Assist = {
    #            AssistLocation = 'LocationType',
    #            PermanentAssist = false,
    #            BeingBuiltCategories = {'TRANSPORTFOCUS'},
    #            AssisteeType = 'Factory',
    #            Time = 60,
    #        },
    #    },
    #},
    #Builder {
    #    BuilderName = 'T1 Engineer Assist T2 Factory Upgrade',
    #    PlatoonTemplate = 'EngineerAssist',
    #    Priority = 875,
    #    BuilderConditions = {
    #        { IBC, 'BrainNotLowPowerMode', {} },
    #        { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENGINEER TECH1'}},
    #        { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, 'FACTORY TECH2' }},
    #        { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
    #    },
    #    InstanceCount = 4,
    #    BuilderType = 'Any',
    #    BuilderData = {
    #        Assist = {
    #            AssistLocation = 'LocationType',
    #            PermanentAssist = true,
    #            BeingBuiltCategories = {'FACTORY TECH2'},
    #            AssisteeType = 'Factory',
    #            Time = 60,
    #        },
    #    }
    #},
    #Builder {
    #    BuilderName = 'T1 Engineer Assist T3 Factory Upgrade',
    #    PlatoonTemplate = 'EngineerAssist',
    #    Priority = 900,
    #    BuilderConditions = {
    #        { IBC, 'BrainNotLowPowerMode', {} },
    #        { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENGINEER TECH1'}},
    #        { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, 'FACTORY TECH3' }},
    #        { UCBC, 'HaveLessThanUnitsWithCategory', { 3, 'TECH3 FACTORY' } },
    #        { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
    #    },
    #    InstanceCount = 8,
    #    BuilderType = 'Any',
    #    BuilderData = {
    #        Assist = {
    #            AssistLocation = 'LocationType',
    #            PermanentAssist = true,
    #            BeingBuiltCategories = {'FACTORY TECH3'},
    #            AssisteeType = 'Factory',
    #            Time = 60,
    #        },
    #    }
    #},
}

BuilderGroup {
    BuilderGroupName = 'T2EngineerBuilders',
    BuildersType = 'EngineerBuilder',
    # =====================================
    #     T2 Engineer Resource Builders
    # =====================================
    Builder {
        BuilderName = 'T2 Mass Adjacency Engineer',
        PlatoonTemplate = 'T2EngineerBuilder',
        #DUNCAN - Changed from 850
        Priority = 0,
        BuilderConditions = {
            { MABC, 'MarkerLessThanDistance',  { 'Mass', 100, -3, 0, 0}},
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { UCBC, 'AdjacencyCheck', { 'LocationType', 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3', 100, 'ueb1106' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3',
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
        PlatoonTemplate = 'T2EngineerBuilder',
        PlatoonAIPlan = 'ReclaimAI',
        Priority = 2, #DUNCAN - was 1
        InstanceCount = 10,
        BuilderConditions = {
                { MIBC, 'ReclaimablesInArea', { 'LocationType', }},
            },
        BuilderData = {
            LocationType = 'LocationType',
            ReclaimTime = 30,
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
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.1, 1.1 }},
                { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, categories.TECH3 * categories.ENERGYPRODUCTION}},
                { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 0, categories.TECH1 * categories.ENERGYPRODUCTION * categories.DRAGBUILD }},
            },
        BuilderData = {
            Location = 'LocationType',
            Reclaim = {'STRUCTURE ENERGYPRODUCTION TECH1 DRAGBUILD'},
        },
        BuilderType = 'Any',
    },

    # =========================
    #     T2 ENGINEER ASSIST
    # =========================
    Builder {
        BuilderName = 'T2 Engineer Assist Energy',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 900,
        InstanceCount = 3,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3' } },
            { EBC, 'LessThanEconEfficiencyOverTime', { 2.0, 1.5 }},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 0.5 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                PermanentAssist = true,
                BeingBuiltCategories = { 'ENERGYPRODUCTION TECH3', 'ENERGYPRODUCTION TECH2', },
                AssisteeType = 'Engineer',
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'T2 Engineer Assist Factory',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 500,
        InstanceCount = 50,
        BuilderType = 'Any',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, 'MOBILE' } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
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
            { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, 'TRANSPORTFOCUS' } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
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
        InstanceCount = 50,
        BuilderType = 'Any',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, 'ALLUNITS' } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
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
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENGINEER TECH1'}},
            { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, 'FACTORY TECH3' }},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.5, 1.1 }},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        InstanceCount = 5,
        BuilderType = 'Any',
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
    # =========================
    #     T3 ENGINEER BUILD
    # =========================
    Builder {
        BuilderName = 'T3 Engineer Reclaim Excess',
        PlatoonTemplate = 'T3EngineerBuilder',
        PlatoonAIPlan = 'ReclaimAI',
        Priority = 0, #DUNCAN - was 1
        InstanceCount = 2, #DUNCAN - was 10
        BuilderConditions = {
                { MIBC, 'ReclaimablesInArea', { 'LocationType', }},
            },
        BuilderData = {
            LocationType = 'LocationType',
            ReclaimTime = 10,
        },
        BuilderType = 'Any',
    },
    # =========================
    #     T3 ENGINEER ASSIST
    # =========================
    Builder {
        BuilderName = 'T3 Engineer Assist T3 Energy Production',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 950,
        InstanceCount = 3,
        BuilderConditions = {
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, 'ENERGYPRODUCTION TECH3' }},
            { EBC, 'LessThanEconEfficiencyOverTime', { 2, 1.3}},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 0.5 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                PermanentAssist = true,
                BeingBuiltCategories = {'ENERGYPRODUCTION TECH3'},
                AssisteeType = 'Engineer',
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'T3 Engineer Assist Transport',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 900,
        BuilderConditions = {
            { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, 'TRANSPORTFOCUS' } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
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
                { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH3' }},
                { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, 'MASSPRODUCTION TECH3' }},
                { EBC, 'LessThanEconEfficiencyOverTime', { 0.9, 2.0}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.1}},
                { IBC, 'BrainNotLowPowerMode', {} },
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
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH3' }},
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, 'STRUCTURE DEFENSE' }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.1} },
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
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, 'STRUCTURE SHIELD' }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.1} },
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
            { UCBC, 'LocationFactoriesBuildingGreater', { 'LocationType', 0, 'MOBILE' }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.1} },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL } }, #DUNCAN - added
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
            { UCBC, 'LocationEngineersBuildingAssistanceGreater', { 'LocationType', 0, 'STRUCTURE TECH3, EXPERIMENTAL' }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1} }, #DUNCAN - was 1.0, 1.1
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                PermanentAssist = true,
                BeingBuiltCategories = { 'SHIELD STRUCTURE', 'EXPERIMENTAL', 'STRUCTURE NUKE',
                               'STRUCTURE STRATEGIC', 'STRUCTURE ANTIMISSILE', 'DEFENSE ANTIAIR TECH3',
                               'DEFENSE DIRECTFIRE TECH3', 'DEFENSE ANTINAVY', 'ENERGYPRODUCTION TECH2',},
                               #DUNCAN - different priorities
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
        BuilderName = 'T1ResourceEngineer 150',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1000,
        InstanceCount = 4,
        BuilderConditions = {
                #{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH2, ENGINEER TECH3' }},
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
        InstanceCount = 4,
        BuilderConditions = {
                #{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH2, ENGINEER TECH3' }},
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
        InstanceCount = 4,
        BuilderConditions = {
                #{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH2, ENGINEER TECH3' }},
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
                #{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH2, ENGINEER TECH3' }},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 1000, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            #NeedGuard = true,
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource',
                }
            }
        }
    },
    Builder {
        BuilderName = 'T2 T2Resource Engineer 100', #DUNCAN - was 250.
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 975,
        InstanceCount = 1,
        BuilderConditions = {
                { UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH3' }},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 100, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource', #DUNCAN - change from T2
                }
            }
        }
    },
    Builder {
        BuilderName = 'T2 T2Resource Engineer 500',
        PlatoonTemplate = 'T2EngineerBuilder',
        #DUNCAN - Changed from 875
        Priority = 0,
        InstanceCount = 1,
        BuilderConditions = {
                { UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH3'}},
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
        Priority = 0, #DUNCAN - was 975
        BuilderConditions = {
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 250, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource', #DUNCAN - change from T3
                }
            }
        }
    },
    Builder {
        BuilderName = 'T3 T3Resource Engineer 500 range',
        PlatoonTemplate = 'T3EngineerBuilder',
        #DUNCAN - Changed from 850
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
        BuilderName = 'T3 Mass Fab Engineer',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1200, #DUNCAN - was 900
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'MASSFABRICATION' } },
                { EBC, 'LessThanEconEfficiencyOverTime', { 0.95, 2.0}}, #DUNCAN - was 0.8
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.4, 1.2}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, 'ENERGYPRODUCTION TECH3' } }, #DUNCAN - was 0
                { IBC, 'BrainNotLowPowerMode', {} },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, 'MASSEXTRACTION TECH3' } }, #DUNCAN - Added
            },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false, #DUNCAN - seems to work better at placing next to power
                AdjacencyCategory = 'ENERGYPRODUCTION TECH3, ENERGYPRODUCTION TECH2',
                BuildStructures = {
                    'T3MassCreation',
                },
            }
        }
    },
}

##-------------------------------------------------------
# NAVAL MEX ENGINEERS
##-------------------------------------------------------
BuilderGroup {
    BuilderGroupName = 'EngineerMassBuilders - Naval',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T1ResourceEngineer 150 - Naval',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1000,
        InstanceCount = 4,
        BuilderConditions = {
                #{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH2, ENGINEER TECH3' }},
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
                #{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH2, ENGINEER TECH3' }},
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
                #{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH2, ENGINEER TECH3' }},
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
                #{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH2, ENGINEER TECH3' }},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 1000, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            #NeedGuard = true,
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
                { UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH3' }},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 250, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource', #DUNCAN - change from T2
                }
            }
        }
    },
    Builder {
        BuilderName = 'T2 T2Resource Engineer 500 - Naval',
        PlatoonTemplate = 'T2EngineerBuilder',
        #DUNCAN - Changed from 875
        Priority = 0,
        InstanceCount = 1,
        BuilderConditions = {
                { UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH3'}},
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
        Priority = 0, #DUNCAN - was 975
        BuilderConditions = {
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 250, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource', #DUNCAN - change from T3
                }
            }
        }
    },
    Builder {
        BuilderName = 'T3 T3Resource Engineer 500 range - Naval',
        PlatoonTemplate = 'T3EngineerBuilder',
        #DUNCAN - Changed from 850
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
                { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'MASSFABRICATION' } },
                { EBC, 'LessThanEconEfficiencyOverTime', { 0.8, 2}},
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.4, 1.2}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, 'ENERGYPRODUCTION TECH3' } }, #DUNCAN - was 0
                { IBC, 'BrainNotLowPowerMode', {} },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION TECH3' } }, #DUNCAN - Added
            },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = true,
                AdjacencyCategory = 'ENERGYPRODUCTION',
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
                #{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 4, 'ENGINEER TECH2, ENGINEER TECH3'}},
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
                #{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 4, 'ENGINEER TECH2, ENGINEER TECH3'}},
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
                #{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 4, 'ENGINEER TECH2, ENGINEER TECH3'}},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 1000, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            #NeedGuard = true,
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
                #{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 4, 'ENGINEER TECH2, ENGINEER TECH3'}},
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
        #DUNCAN - Changed from 850
        Priority = 0,
        InstanceCount = 1,
        BuilderConditions = {
                #{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 4, 'ENGINEER TECH3'}},
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
        #DUNCAN - Changed from 7500
        Priority = 0,
        InstanceCount = 1,
        BuilderConditions = {
                #{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 4, 'ENGINEER TECH3'}},
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
        Priority = 0, #DUNCAN - was 850
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
        #DUNCAN - Changed from 750
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
                #{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, 'ENGINEER TECH2, ENGINEER TECH3'}},
                { MABC, 'CanBuildOnMassLessThanDistance', { 'LocationType', 1000, -500, 1, 0, 'AntiSurface', 1 }},
            },
        BuilderType = 'Any',
        BuilderData = {
            NeedGuard = true, #DUNCAN - Added
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
                #{ UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, 'ENGINEER TECH3'}},
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
        #DUNCAN - Changed from 750
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
    # =====================================
    #     T2 Engineer Resource Builders
    # =====================================
    Builder {
        BuilderName = 'T1 Power Engineer - rebuild',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1100,
        BuilderConditions = {
            { MIBC, 'GreaterThanGameTime', { 600 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 4, 'ENERGYPRODUCTION' } },
            { EBC, 'LessThanEconEfficiencyOverTime', { 2.0, 1.35 }},
        },
        #InstanceCount = 2,
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'FACTORY',
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
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 3, 'ENGINEER TECH2, ENGINEER TECH3' } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 0.5 }},
            { EBC, 'LessThanEconEfficiencyOverTime', { 2.0, 1.35 }},
        },
        #InstanceCount = 2,
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'FACTORY',
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
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.ENERGYPRODUCTION * categories.TECH2}}, #DUNCAN - Added
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, 'TECH3 ENGINEER' }},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.5, 0.1 }},
            { EBC, 'LessThanEconEfficiencyOverTime', { 2.0, 1.3 }}, #DUNCAN - Moved check from 1.7
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = true,
                AvoidCategory = 'ENERGYPRODUCTION TECH2',
                maxUnits = 5,
                maxRadius = 15,
                AdjacencyCategory = 'SHIELD STUCTURE, FACTORY TECH3, FACTORY TECH2, FACTORY TECH1',
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
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.ENERGYPRODUCTION * categories.TECH2}}, #DUNCAN - Added
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.ENERGYPRODUCTION * categories.TECH3}}, #DUNCAN - Added
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.5, 0.1 }},
            { EBC, 'LessThanEconEfficiencyOverTime', { 2.0, 1.3 }}, #DUNCAN - added
        },
        BuilderData = {
            Construction = {
                BuildClose = true,
                AdjacencyCategory = 'SHIELD STUCTURE, FACTORY TECH3, FACTORY TECH2, FACTORY TECH1',
                AvoidCategory = 'ENERGYPRODUCTION TECH3',
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
    # =====================================
    #     T2 Engineer Resource Builders
    # =====================================
    #Builder {
    #    BuilderName = 'T1 Power Engineer Expansions',
    #    PlatoonTemplate = 'EngineerBuilder',
    #    Priority = 975,
    #    BuilderConditions = {
    #            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 8, 'ENERGYPRODUCTION' } },
    #            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, 'ENGINEER TECH2, ENGINEER TECH3' } },
    #            { EBC, 'LessThanEconEfficiencyOverTime', { 1.5, 1.2}},
    #        },
    #    InstanceCount = 1,
    #    BuilderType = 'Any',
    #    BuilderData = {
    #        Construction = {
    #            BuildStructures = {
    #                'T1EnergyProduction',
    #                'T1EnergyProduction',
    #                'T1EnergyProduction',
    #                'T1EnergyProduction',
    #            },
    #            Location = 'LocationType',
    #        }
    #    }
    #},
    #Builder {
    #    BuilderName = 'T2 Power Engineer Expansions',
    #    PlatoonTemplate = 'T2EngineerBuilder',
    #    Priority = 950,
    #    BuilderConditions = {
    #            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, 'ENERGYPRODUCTION TECH2' } },
    #            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, 'TECH3 ENGINEER' }},
    #            { EBC, 'LessThanEconEfficiencyOverTime', { 1.5, 1.2}},
    #        },
    #    BuilderType = 'Any',
    #    BuilderData = {
    #        Construction = {
    #            BuildStructures = {
    #                'T2EnergyProduction',
    #            },
    #            Location = 'LocationType',
    #        }
    #    }
    #},
    #Builder {
    #    BuilderName = 'T3 Power Engineer Expansions',
    #    PlatoonTemplate = 'T3EngineerBuilder',
    #    Priority = 1000,
    #    BuilderType = 'Any',
    #    BuilderConditions = {
    #            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, 'ENERGYPRODUCTION TECH3' } },
    #            { EBC, 'LessThanEconEfficiencyOverTime', { 1.5, 1.2}},
    #        },
    #    BuilderData = {
    #        Construction = {
    #            BuildStructures = {
    #                'T3EnergyProduction',
    #            },
    #            Location = 'LocationType',
    #        }
    #    }
    #},
}

BuilderGroup {
    BuilderGroupName = 'EngineeringSupportBuilder',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T2 Engineering Support UEF',
        PlatoonTemplate = 'UEFT2EngineerBuilder',
        Priority = 750,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, 'ENGINEERSTATION' }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 3, 'ENGINEER TECH2' } },
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 2, categories.TECH3 * categories.ENERGYPRODUCTION}},
            { EBC, 'GreaterThanEconIncome',  { 10, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.95, 1.4 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'ENERGYPRODUCTION',
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
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, 'ENGINEERSTATION' }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 3, 'ENGINEER TECH2' } },
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, categories.TECH2 * categories.ENERGYPRODUCTION}},
            { EBC, 'GreaterThanEconIncome',  { 10, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.95, 1.4 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'ENERGYPRODUCTION',
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
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 7, 'ENGINEERSTATION' }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 3, 'ENGINEER TECH3' } },
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, categories.TECH3 * categories.ENERGYPRODUCTION}},
            { EBC, 'GreaterThanEconIncome',  { 10, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.95, 1.4 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'ENERGYPRODUCTION',
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
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 7, 'ENGINEERSTATION' }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 3, 'ENGINEER TECH3' } },
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 1, categories.TECH3 * categories.ENERGYPRODUCTION}},
            { EBC, 'GreaterThanEconIncome',  { 10, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.95, 1.4 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                AdjacencyCategory = 'ENERGYPRODUCTION',
                BuildClose = true,
                FactionIndex = 3,
                BuildStructures = {
                    'T2EngineerSupport',
                },
            }
        }
    },
}
