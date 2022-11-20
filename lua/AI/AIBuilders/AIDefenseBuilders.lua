--***************************************************************************
--*
--**  File     :  /lua/ai/AIDefenseBuilders.lua
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

local AIAddBuilderTable = import("/lua/ai/aiaddbuildertable.lua")

---@alias BuilderGroupsDefense 'T1BaseDefenses' | 'T2BaseDefenses' | 'T2ArtilleryFormBuilders' | 'T3BaseDefenses' | 'T1PerimeterDefenses' | 'T2PerimeterDefenses' | 'T3PerimeterDefenses' | 'T1DefensivePoints' | 'T2DefensivePoints' | 'T3DefensivePoints' | 'T1DefensivePoints High Pri' | 'T2DefensivePoints High Pri' | 'T3DefensivePoints High Pri' | 'T1NavalDefenses' | 'T2NavalDefenses' | 'T3NavalDefenses' | 'T2Shields' | 'ShieldUpgrades' | 'T3Shields' | 'T3NukeDefenses' | 'T3NukeDefenseBehaviors' | 'MiscDefensesEngineerBuilders' | 'T1LightDefenses' | 'T2MissileDefenses' | 'T2LightDefenses' | 'T3LightDefenses' | 'T1ACUDefenses' | 'T2ACUDefenses' | 'T2ACUShields' | 'T3ACUShields' | 'T3ACUNukeDefenses'

-- Inside the base location defenses
BuilderGroup {
    BuilderGroupName = 'T1BaseDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T1 Base D Engineer',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 875,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 10, categories.DEFENSE}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .9 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T1AADefense',
                    'T1GroundDefense',

                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'T1 Base D AA Engineer - Response',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 10, categories.DEFENSE * categories.ANTIAIR}},
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 5, 'Air' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .9 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T1AADefense',
                    'T1AADefense',
                    'T1GroundDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'T2BaseDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T2 Base D Engineer',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 875,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 6, categories.DEFENSE * categories.TECH2 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .9 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T2AADefense',
                    'T2GroundDefense',
                    'T2MissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'T2 Base D Engineer PD - Response',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 5, categories.DEFENSE * categories.TECH2 * categories.DIRECTFIRE }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .9 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T2AADefense',
                    'T2GroundDefense',
                    'T2MissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'T2 Base D Anti-TML Engineer - Response',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 3, categories.ANTIMISSILE * categories.TECH2 }},
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 0, 'Artillery' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .9 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T2MissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'T2 Base D AA Engineer - Response',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 950, --DUNCAN - was 925
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 5, categories.DEFENSE * categories.TECH2 * categories.ANTIAIR }},
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 5, 'Air' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .9 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T2AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'T2 Base D Artillery',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 925,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, categories.ARTILLERY * categories.TECH2 * categories.STRUCTURE }},
            --{ TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 10, 'Structures' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
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
        BuilderName = 'T2TMLEngineer',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 950, --DUNCAN - was 900
        BuilderConditions = {
            --DUNCAN - just have one of these.
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.TACTICALMISSILEPLATFORM}},
            { EBC, 'GreaterThanEconEfficiency', { 0.9, 1.2}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'CheckUnitRange', { 'LocationType', 'T2StrategicMissile', categories.STRUCTURE + (categories.LAND * (categories.TECH2 + categories.TECH3)) } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T2StrategicMissile',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'T2ArtilleryFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T2 TML Silo',
        PlatoonTemplate = 'T2TacticalLauncher',
        Priority = 1,
        InstanceCount = 1000,
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Artillery',
        PlatoonTemplate = 'T2ArtilleryStructure',
        Priority = 1,
        InstanceCount = 1000,
        FormRadius = 10000,
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'T3BaseDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T3 Base D Engineer AA',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 900,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 10, categories.DEFENSE * categories.TECH3 * categories.ANTIAIR * categories.STRUCTURE}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.1 }}, --DUNCAN - was 0.9, 1.2
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE * categories.TECH3 * categories.ANTIAIR * categories.STRUCTURE } },
            { UCBC, 'UnitCapCheckLess', { .9 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 0, --DUNCAN - was 2
            Construction = {
                BuildClose = true,
                AvoidCategory = 'TECH3 ANTIAIR STRUCTURE',
                maxUnits = 1,
                maxRadius = 10,
                AdjacencyCategory = 'SHIELD STUCTURE, FACTORY TECH3, FACTORY TECH2, FACTORY',
                BuildStructures = {
                    'T3AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'T3 Base D Engineer PD',
        PlatoonTemplate = 'UEFT3EngineerBuilder',
        Priority = 900, --DUNCAN - was 875
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, categories.DEFENSE * categories.TECH3 * categories.DIRECTFIRE }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .9 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 0,
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T3GroundDefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'T3TMLEngineer',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 900,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, categories.TACTICALMISSILEPLATFORM}},
            { EBC, 'GreaterThanEconEfficiency', { 0.9, 1.2}},
            { IBC, 'BrainNotLowPowerMode', {} },
            --{ UCBC, 'CheckUnitRange', { 'LocationType', 'T2StrategicMissile', categories.STRUCTURE + (categories.LAND * (categories.TECH2 + categories.TECH3)) } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T2StrategicMissile',
                },
                Location = 'LocationType',
            }
        }
    },
}

-- Defenses surrounding the base in patrol points
BuilderGroup {
    BuilderGroupName = 'T1PerimeterDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T1 Base D Engineer - Perimeter',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 910,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 20, categories.DEFENSE * categories.TECH1}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.2 }},
            --{ UCBC, 'UnitCapCheckLess', { .6 } },
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
                    'T1GroundDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'T2PerimeterDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T2 Base D Engineer - Perimeter',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 910,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 30, categories.DEFENSE * categories.TECH2}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.2 }},
            --{ UCBC, 'UnitCapCheckLess', { .6 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearBasePatrolPoints = true,
                BuildStructures = {
                    'T1GroundDefense',
                    'T2GroundDefense',
                    'T2AADefense',
                    'T2ShieldDefense',
                    'T2MissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'T3PerimeterDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T3 Base D Engineer - Perimeter',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 910,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 30, categories.DEFENSE * categories.TECH3}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            --{ UCBC, 'UnitCapCheckLess', { .6 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearBasePatrolPoints = true,
                BuildStructures = {
                    'T1GroundDefense',
                    'T3AADefense',
                    'T2Artillery',
                    'T2ShieldDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

-- Defenses at defensive point markers
BuilderGroup {
    BuilderGroupName = 'T1DefensivePoints',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T1 Defensive Point Engineer',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 850,
        BuilderConditions = {
            -- Most paramaters freaking ever Build Condition -- All the threat ones are optional
            --------                                   MarkerType   LocRadius  category markerRad unitMax tMin tMax Rings tType
            { UCBC, 'DefensivePointNeedsStructure', { 'LocationType', 150, 'DEFENSE', 20,        5,     0,   1,   2, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 150,
                LocationType = 'LocationType',
                ThreatMin = 0,
                ThreatMax = 1,
                ThreatRings = 2,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 5,
                MarkerUnitCategory = 'DEFENSE',
                BuildStructures = {
                    'T1AADefense',
                    'T1AADefense',
                    'T1GroundDefense',
                },
            },
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'T2DefensivePoints',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T2 Defensive Point Engineer',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 850,
        InstanceCount = 1,
        BuilderConditions = {
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'DefensivePointNeedsStructure', { 'LocationType', 150, 'DEFENSE TECH2, DEFENSE TECH3', 20, 5, 0, 1, 2, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 150,
                LocationType = 'LocationType',
                ThreatMin = 0,
                ThreatMax = 1,
                ThreatRings = 2,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 5,
                MarkerUnitCategory = 'DEFENSE TECH2, DEFENSE TECH3',
                BuildStructures = {
                    'T2GroundDefense',
                    'T2AADefense',
                    'T2AADefense',
                }
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'T3DefensivePoints',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T3 Defensive Point Engineer',
        PlatoonTemplate = 'UEFT3EngineerBuilder',
        Priority = 850,
        InstanceCount = 1,
        BuilderConditions = {
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'DefensivePointNeedsStructure', { 'LocationType', 150, 'DEFENSE TECH3 DIRECTFIRE', 20, 2, 0, 1, 2, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .75 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 150,
                LocationType = 'LocationType',
                ThreatMin = 0,
                ThreatMax = 1,
                ThreatRings = 2,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 2,
                MarkerUnitCategory = 'DEFENSE TECH3 DIRECTFIRE',
                BuildStructures = {
                    'T3GroundDefense',
                }
            }
        }
    },
}

-- Defenses at defensive point markers
BuilderGroup {
    BuilderGroupName = 'T1DefensivePoints High Pri',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T1 Defensive Point Engineer High Pri',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 930,
        BuilderConditions = {
            -- Most paramaters freaking ever Build Condition -- All the threat ones are optional
            --------                                   MarkerType   LocRadius  category markerRad unitMax tMin tMax Rings tType
            { UCBC, 'DefensivePointNeedsStructure', { 'LocationType', 150, 'DEFENSE', 20,        3,     0,   1,   2, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 150,
                LocationType = 'LocationType',
                ThreatMin = 0,
                ThreatMax = 1,
                ThreatRings = 2,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 5,
                MarkerUnitCategory = 'DEFENSE',
                BuildStructures = {
                    'T1AADefense',
                    'T1GroundDefense',
                    'T1GroundDefense',
                },
            },
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'T2DefensivePoints High Pri',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T2 Defensive Point Engineer High Pri',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 930,
        InstanceCount = 1,
        BuilderConditions = {
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.2 }},
            { UCBC, 'DefensivePointNeedsStructure', { 'LocationType', 150, 'DEFENSE TECH2, DEFENSE TECH3', 20, 3, 0, 1, 2, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 150,
                LocationType = 'LocationType',
                ThreatMin = 0,
                ThreatMax = 1,
                ThreatRings = 2,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 5,
                MarkerUnitCategory = 'DEFENSE TECH2, DEFENSE TECH3',
                BuildStructures = {
                    'T2GroundDefense',
                    'T2AADefense',
                    'T2ShieldDefense',
                    'T1GroundDefense',
                }
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'T3DefensivePoints High Pri',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T3 Defensive Point Engineer High Pri',
        PlatoonTemplate = 'UEFT3EngineerBuilder',
        Priority = 930,
        InstanceCount = 1,
        BuilderConditions = {
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'DefensivePointNeedsStructure', { 'LocationType', 150, 'DEFENSE TECH3 DIRECTFIRE', 20, 2, 0, 1, 2, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 2, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 150,
                LocationType = 'LocationType',
                ThreatMin = 0,
                ThreatMax = 1,
                ThreatRings = 2,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 2,
                MarkerUnitCategory = 'DEFENSE TECH3 DIRECTFIRE',
                BuildStructures = {
                    'T3GroundDefense',
                }
            }
        }
    },
}

-- Defenses at naval markers where a naval factory would be built
BuilderGroup {
    BuilderGroupName = 'T1NavalDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T1 Naval D Engineer',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, categories.DEFENSE * categories.TECH1 * categories.ANTINAVY }},
            { UCBC, 'NavalDefensivePointNeedsStructure', { 'LocationType', 75, 'DEFENSE TECH1 ANTINAVY', 20, 2, 0, 1, 2, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .7 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Naval Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 75,
                LocationType = 'LocationType',
                ThreatMin = 0,
                ThreatMax = 1,
                ThreatRings = 2,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 2,
                MarkerUnitCategory = 'DEFENSE TECH1 ANTINAVY',
                BuildStructures = {
                    'T1NavalDefense',
                },
            }
        }
    },
    Builder {
        BuilderName = 'T1 Base D Naval AA Engineer',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'NavalDefensivePointNeedsStructure', { 'LocationType', 75, 'DEFENSE TECH1 ANTIAIR', 20, 2, 0, 1, 2, 'AntiSurface' } },
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 5, 'Air' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .7 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Naval Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 75,
                LocationType = 'LocationType',
                ThreatMin = 0,
                ThreatMax = 1,
                ThreatRings = 2,
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
    BuilderGroupName = 'T2NavalDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T2 Naval D Engineer',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, categories.DEFENSE * categories.TECH2 * categories.ANTINAVY }},
            { UCBC, 'NavalDefensivePointNeedsStructure', { 'LocationType', 75, 'DEFENSE TECH2 ANTINAVY', 20, 2, 0, 1, 2, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .7 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Naval Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 75,
                LocationType = 'LocationType',
                ThreatMin = 0,
                ThreatMax = 1,
                ThreatRings = 2,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 2,
                MarkerUnitCategory = 'DEFENSE TECH2 ANTINAVY',
                BuildStructures = {
                    'T2NavalDefense',
                },
            }
        }
    },
    Builder {
        BuilderName = 'T2 Base D Naval AA Engineer',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'NavalDefensivePointNeedsStructure', { 'LocationType', 75, 'DEFENSE TECH2 ANTIAIR', 20, 2, 0, 1, 2, 'AntiSurface' } },
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 5, 'Air' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .7 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Naval Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 75,
                LocationType = 'LocationType',
                ThreatMin = 0,
                ThreatMax = 1,
                ThreatRings = 2,
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
    BuilderGroupName = 'T3NavalDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T3 Naval D Engineer',
        PlatoonTemplate = 'CybranT3EngineerBuilder',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.DEFENSE * categories.TECH3 * categories.ANTINAVY }},
            { UCBC, 'NavalDefensivePointNeedsStructure', { 'LocationType', 75, 'DEFENSE TECH3 ANTIAIR', 20, 2, 0, 1, 2, 'AntiSurface' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .7 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Naval Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 75,
                LocationType = 'LocationType',
                ThreatMin = 0,
                ThreatMax = 1,
                ThreatRings = 2,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 2,
                MarkerUnitCategory = 'DEFENSE TECH3 ANTINAVY',
                BuildStructures = {
                    'T3NavalDefense',
                },
            }
        }
    },
    Builder {
        BuilderName = 'T3 Base D Naval AA Engineer',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'NavalDefensivePointNeedsStructure', { 'LocationType', 75, 'DEFENSE TECH3 ANTIAIR', 20, 2, 0, 1, 2, 'AntiSurface' } },
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 5, 'Air' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.DEFENSE } },
            { UCBC, 'UnitCapCheckLess', { .7 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                BuildClose = false,
                NearMarkerType = 'Naval Defensive Point',
                MarkerRadius = 20,
                LocationRadius = 75,
                LocationType = 'LocationType',
                ThreatMin = 0,
                ThreatMax = 1,
                ThreatRings = 2,
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

-- Shields
BuilderGroup {
    BuilderGroupName = 'T2Shields',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T2 Shield D Engineer Near Energy Production',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 1000, --DUNCAN - was 850
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 7, categories.SHIELD * categories.STRUCTURE}}, --DUNCAN - Added Sructure
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.DEFENSE * categories.TECH2}}, --DUNCAN - Added
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiency', { 0.8, 1.4 } },
            { UCBC, 'LocationEngineersBuildingLess', { 'LocationType', 1, categories.SHIELD } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                AdjacencyCategory = 'ENERGYPRODUCTION EXPERIMENTAL, ENERGYPRODUCTION TECH3, FACTORY TECH3, FACTORY TECH2, ENERGYPRODUCTION TECH2, FACTORY',
                AdjacencyDistance = 60,
                BuildClose = false,
                AvoidCategory = 'SHIELD',
                maxUnits = 1,
                maxRadius = 10,
                BuildStructures = {
                    'T2ShieldDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'ShieldUpgrades',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T2 Shield Cybran 1',
        PlatoonTemplate = 'T2Shield1',
        Priority = 5,
        InstanceCount = 5,
        BuilderConditions = {
            { EBC, 'GreaterThanEconIncomeOverTime',  { 5, 150}},
            { MIBC, 'FactionIndex', {3}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.2 }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Shield Cybran 2',
        PlatoonTemplate = 'T2Shield2',
        Priority = 5,
        InstanceCount = 5,
        BuilderConditions = {
            { EBC, 'GreaterThanEconIncomeOverTime',  { 5, 200}},
            { MIBC, 'FactionIndex', {3}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.2 }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Shield Cybran 3',
        PlatoonTemplate = 'T2Shield3',
        Priority = 5,
        InstanceCount = 5,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } }, --DUNCAN - Added
            { EBC, 'GreaterThanEconIncomeOverTime',  { 5, 300}},
            { MIBC, 'FactionIndex', {3}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.2 }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Shield Cybran 4',
        PlatoonTemplate = 'T2Shield4',
        Priority = 5,
        InstanceCount = 5,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } }, --DUNCAN - Added
            { EBC, 'GreaterThanEconIncomeOverTime',  { 5, 400}},
            { MIBC, 'FactionIndex', {3}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.2 }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Shield UEF Seraphim',
        PlatoonTemplate = 'T2Shield',
        Priority = 5,
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } }, --DUNCAN - Added
            { EBC, 'GreaterThanEconIncomeOverTime',  { 7, 350}},
            { MIBC, 'FactionIndex', {1, 4}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.2 }},
        },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'T3Shields',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T3 Shield D Engineer Factory Adj',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 950, --DUNCAN - was 875
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.ENGINEER * categories.TECH3}}, --DUNCAN - was 8
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 8, categories.SHIELD * categories.STRUCTURE}}, --DUNCAN - Added Sructure
            { MIBC, 'FactionIndex', {1, 2, 4}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.1 }}, --DUNCAN - was 0.9, 1.4
            { IBC, 'BrainNotLowPowerMode', {} },
            --{ UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                AdjacencyCategory = 'ENERGYPRODUCTION EXPERIMENTAL, ENERGYPRODUCTION TECH3, FACTORY TECH3, FACTORY TECH2, ENERGYPRODUCTION TECH2, FACTORY',
                AdjacencyDistance = 60,
                BuildClose = false,
                AvoidCategory = 'SHIELD',
                maxUnits = 1,
                maxRadius = 10,
                BuildStructures = {
                    'T3ShieldDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

-- Anti nuke defenses
BuilderGroup {
    BuilderGroupName = 'T3NukeDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T3 Anti-Nuke Engineer Near Factory',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.ANTIMISSILE * categories.TECH3}}, --DUNCAN - Added
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.ENGINEER * categories.TECH3}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * categories.TECH3 } }, --DUNCAN - Added
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * categories.TECH3 } },  --DUNCAN - Added
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL  + categories.BATTLESHIP } }, --DUNCAN - added
            { UCBC, 'BuildingLessAtLocation', { 'LocationType', 1, categories.ANTIMISSILE * categories.TECH3 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, categories.ANTIMISSILE * categories.TECH3}},
            { EBC, 'GreaterThanEconIncomeOverTime', { 2.5, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'UnitCapCheckLess', { .95 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 5,
            Construction = {
                BuildClose = false,
                AdjacencyCategory = 'FACTORY - NAVAL',
                AdjacencyDistance = 100,
                BuildStructures = {
                    'T3StrategicMissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'T3NukeDefenseBehaviors',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T3 Anti Nuke Silo',
        PlatoonTemplate = 'T3AntiNuke',
        Priority = 5,
        InstanceCount = 20,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            },
        BuilderType = 'Any',
    },
}

-- Misc Defenses
BuilderGroup {
    BuilderGroupName = 'MiscDefensesEngineerBuilders',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T1 Wall Builder',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 0,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'HaveAreaWithUnitsFewWalls', { 'LocationType', 100, 5, 'STRUCTURE - WALL', false, false, false } },
        },
        BuilderData = {
            NumAssistees = 0,
            Construction = {
                BuildStructures = { 'Wall' },
                LocationType = 'LocationType',
                Wall = true,
                MarkerRadius = 100,
                MarkerUnitCount = 5,
                MarkerUnitCategory = 'STRUCTURE - WALL',
            },
        },
    },
    Builder {
        BuilderName = 'T2 Air Staging Engineer',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.AIRSTAGINGPLATFORM}}, --DUNCAN - was 2
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.AIRSTAGINGPLATFORM}}, --DUNCAN - Added
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
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
        BuilderName = 'T2 Air Staging Engineer - Lots of Air', --DUNCAN - added this builder
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 0, --DUNCAN - disabled for now due to air staging engine bugs.
        BuilderConditions = {
            { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 40, categories.AIR}},
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, categories.AIRSTAGINGPLATFORM}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 4, categories.AIRSTAGINGPLATFORM}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                BuildClose = false,
                BuildStructures = {
                    'T2AirStagingPlatform',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'T1 Engineer Reclaim Enemy Walls',
        PlatoonTemplate = 'EngineerBuilder',
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
}

BuilderGroup {
    BuilderGroupName = 'T1LightDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T1 Base D Engineer - Light',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 4, categories.DEFENSE}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T1GroundDefense',
                    'T1AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'T2MissileDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T2MissileDefenseEng',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, categories.ANTIMISSILE * categories.TECH2 * categories.STRUCTURE }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T2MissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'T2LightDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T2 Base D Engineer - Light',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 4, categories.DEFENSE * categories.TECH2 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T2GroundDefense',
                    'T2AADefense',
                    'T2MissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'T3LightDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T3 Base D Engineer AA - Light',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, categories.DEFENSE * categories.TECH3 * categories.ANTIAIR }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T3AADefense',
                },
                Location = 'LocationType',
            }
        }
    },
    Builder {
        BuilderName = 'T3 Base D Engineer PD - Light',
        PlatoonTemplate = 'UEFT3EngineerBuilder',
        Priority = 875,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.DEFENSE * categories.TECH3 * categories.DIRECTFIRE }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T3GroundDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}


BuilderGroup {
    BuilderGroupName = 'T1ACUDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T1 ACU D Engineer',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 890,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 4, categories.DEFENSE * categories.ANTIAIR }}, --DUNCAN - limt to 3 anti air
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.2 }}, --DUNCAN - was 0.9, 1.2
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
    BuilderGroupName = 'T2ACUDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T2 ACU D Engineer',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 890,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 6, categories.DEFENSE * categories.TECH2 }},
            --DUNCAN - Commented out
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENERGYPRODUCTION TECH2' }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.1 }}, --DUNCAN - was 0.9, 1.2
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                NearUnitCategory = 'COMMAND',
                NearUnitRadius = 32000,
                BuildClose = true, --DUNCAN - was false
                BuildStructures = {
                    --DUNCAN - Added PD
                    'T2GroundDefense',
                    'T2AADefense',
                    'T2MissileDefense',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'T2ACUShields',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T2 Shield D Engineer Near ACU',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 890,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.DEFENSE * categories.TECH2}}, --DUNCAN - Added
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENGINEER * categories.TECH2}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 4, categories.SHIELD * categories.TECH2* categories.STRUCTURE}}, --DUNCAN - Added Sructure
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'FactionIndex', {2} },
            { EBC, 'GreaterThanEconEfficiency', { 0.8, 1.1 } }, --DUNCAN - was 1.4
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                AvoidCategory = 'SHIELD',
                maxUnits = 1,
                maxRadius = 10,
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
    BuilderGroupName = 'T3ACUShields',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T3 Shield D Engineer Near ACU',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 890,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 7, categories.ENGINEER * categories.TECH3}}, --DUNCAN - was 8
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 5, categories.SHIELD * categories.STRUCTURE}}, --DUNCAN - Added Sructure
            { MIBC, 'FactionIndex', {1, 2, 4}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }}, --DUNCAN - was 0.9, 1.4
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 2,
            Construction = {
                AvoidCategory = 'SHIELD',
                maxUnits = 1,
                maxRadius = 10,
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
    BuilderGroupName = 'T3ACUNukeDefenses',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T3 Anti-Nuke Engineer Near ACU',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 1000, --DUNCAN - was 890
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.ANTIMISSILE * categories.TECH3}}, --DUNCAN - Added
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENGINEER * categories.TECH3}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },  --DUNCAN - Added
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL + categories.BATTLESHIP } }, --DUNCAN - added
            { UCBC, 'BuildingLessAtLocation', { 'LocationType', 1, categories.ANTIMISSILE * categories.TECH3 } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.ANTIMISSILE * categories.TECH3}},
            --{ EBC, 'GreaterThanEconIncomeOverTime', { 2.5, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.1 }}, --DUNCAN - was 0.9, 1.4
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
