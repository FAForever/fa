--****************************************************************************
--**
--**  File     :  /lua/AI/AIBuilders/ExpansionBuilders.lua
--**
--**  Summary  : Builder definitions for expansion bases
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
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
local PlatoonFile = '/lua/platoon.lua'

local ExtractorToFactoryRatio = 3

---@alias BuilderGroupsExpansion 'EngineerExpansionBuildersFull' | 'EngineerExpansionBuildersFull - Naval' | 'EngineerExpansionBuildersSmall' | 'EngineerFirebaseBuilders' 

BuilderGroup {
    BuilderGroupName = 'EngineerExpansionBuildersFull',
    BuildersType = 'EngineerBuilder',

    --------------------------------------------------------------------------------
    ---- Builds expansion bases
    --------------------------------------------------------------------------------
    ------ Start the Factories in the expansion
    Builder {
        BuilderName = 'T1VacantStartingAreaEngineer - Rush',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 985,
        InstanceCount = 2,
        BuilderConditions = {
            --DUNCAN - Added to limit expansions
            { UCBC, 'ExpansionBaseCheck', { } },
            { UCBC, 'StartLocationNeedsEngineer', { 'LocationType', 1000, -1000, 5, 0, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { MIBC, 'LessThanGameTime', { 600 } },
            --{ UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, 'MASSEXTRACTION', '>=','FACTORY' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 6.5, '>=', 'FACTORY TECH1 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 14, '>=', 'FACTORY TECH2 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 19, '>=', 'FACTORY TECH3 STRUCTURE' } },
            --{ EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true, --DUNCAN - added
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                NearMarkerType = 'Start Location',
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 5,
                ThreatRings = 0,
                ThreatType = 'StructuresNotMex',
                BuildStructures = {
                    --DUNCAN - adjusted
                    'T1GroundDefense',
                    'T1LandFactory',
                    'T1GroundDefense',
                    'T1LandFactory',
                    'T1AADefense',
                    'T1Radar',
                }
            },
            NeedGuard = true,
        }
    },

    Builder {
        BuilderName = 'T1VacantStartingAreaEngineer',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 932,
        InstanceCount = 2,
        BuilderConditions = {
            --DUNCAN - Added to limit expansions
            { UCBC, 'ExpansionBaseCheck', { } },
            { UCBC, 'StartLocationNeedsEngineer', { 'LocationType', 1000, -1000, 100, 0, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            --{ UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, 'MASSEXTRACTION', '>=','FACTORY' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 6.5, '>=', 'FACTORY TECH1 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 14, '>=', 'FACTORY TECH2 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 19, '>=', 'FACTORY TECH3 STRUCTURE' } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                NearMarkerType = 'Start Location',
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 100,
                ThreatRings = 0,
                ThreatType = 'StructuresNotMex',
                BuildStructures = {
                    --DUNCAN - adjusted
                    'T1GroundDefense',
                    'T1LandFactory',
                    'T1GroundDefense',
                    'T1AADefense',
                    'T1LandFactory',
                    'T1Radar',
                }
            },
            NeedGuard = true,
        }
    },
    Builder {
        BuilderName = 'T2VacantStartingAreaEngineer',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 942, --DUNCAN - was 922
        InstanceCount = 2,
        BuilderConditions = {
            --DUNCAN - Added to limit expansions
            { UCBC, 'ExpansionBaseCheck', { } },
            { UCBC, 'StartLocationNeedsEngineer', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            --{ UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, 'MASSEXTRACTION', '>=','FACTORY' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 6.5, '>=', 'FACTORY TECH1 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 14, '>=', 'FACTORY TECH2 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 19, '>=', 'FACTORY TECH3 STRUCTURE' } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                NearMarkerType = 'Start Location',
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 0,
                ThreatRings = 2,
                ThreatType = 'StructuresNotMex',
                BuildStructures = {
                    --DUNCAN - Added strat missle, radar, extra PD, move fac to end, added shield
                    'T1GroundDefense',
                    'T1Radar',
                    'T2AADefense',
                    'T2GroundDefense',
                    'T2StrategicMissile',
                    'T2GroundDefense',
                    'T1LandFactory',
                    'T2ShieldDefense',
                }
            },
            NeedGuard = true,
        }
    },
    Builder {
        BuilderName = 'T3VacantStartingAreaEngineer',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 922,
        InstanceCount = 2,
        BuilderConditions = {
            --DUNCAN - Added to limit expansions
            { UCBC, 'ExpansionBaseCheck', { } },
            { UCBC, 'StartLocationNeedsEngineer', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, categories.MASSEXTRACTION, '>=', categories.FACTORY } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                NearMarkerType = 'Start Location',
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 0,
                ThreatRings = 2,
                ThreatType = 'StructuresNotMex',
                BuildStructures = {
                    --DUNCAN - Added strat missle, radar, extra PD, move fac to end, added shield
                    'T1GroundDefense',
                    'T1Radar',
                    'T2AADefense',
                    'T2GroundDefense',
                    'T2StrategicMissile',
                    'T2GroundDefense',
                    'T1LandFactory',
                    'T2ShieldDefense',
                }
            },
            NeedGuard = true,
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'EngineerExpansionBuildersFull - Naval',
    BuildersType = 'EngineerBuilder',

    --------------------------------------------------------------------------------
    ---- Builds expansion bases
    --------------------------------------------------------------------------------
    ------ Start the Factories in the expansion
    Builder {
        BuilderName = 'T1VacantStartingAreaEngineer - Naval',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 922,
        InstanceCount = 2,
        BuilderConditions = {
            --DUNCAN - Added to limit expansions
            { UCBC, 'ExpansionBaseCheck', { } },
            { UCBC, 'StartLocationNeedsEngineer', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            --{ EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                NearMarkerType = 'Start Location',
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 0,
                ThreatRings = 2,
                ThreatType = 'StructuresNotMex',
                BuildStructures = {
                    'T1GroundDefense',
                    'T1LandFactory',
                    'T1AADefense',
                }
            },
            NeedGuard = true,
        }
    },
    Builder {
        BuilderName = 'T2VacantStartingAreaEngineer - Naval',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 922,
        InstanceCount = 2,
        BuilderConditions = {
            --DUNCAN - Added to limit expansions
            { UCBC, 'ExpansionBaseCheck', { } },
            { UCBC, 'StartLocationNeedsEngineer', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            --{ EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                NearMarkerType = 'Start Location',
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 0,
                ThreatRings = 2,
                ThreatType = 'StructuresNotMex',
                BuildStructures = {
                    --DUNCAN - Added strat missle, radar, extra PD, move fac to end, added shield
                    'T1GroundDefense',
                    'T1Radar',
                    'T2AADefense',
                    'T2GroundDefense',
                    'T2StrategicMissile',
                    'T2GroundDefense',
                    'T1LandFactory',
                    'T2ShieldDefense',
                }
            },
            NeedGuard = true,
        }
    },
    Builder {
        BuilderName = 'T3VacantStartingAreaEngineer - Naval',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 922,
        InstanceCount = 2,
        BuilderConditions = {
            --DUNCAN - Added to limit expansions
            { UCBC, 'ExpansionBaseCheck', { } },
            { UCBC, 'StartLocationNeedsEngineer', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, categories.MASSEXTRACTION, '>=', categories.FACTORY } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                NearMarkerType = 'Start Location',
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 0,
                ThreatRings = 2,
                ThreatType = 'StructuresNotMex',
                BuildStructures = {
                    --DUNCAN - Added strat missle, radar, extra PD, move fac to end, added shield
                    'T1GroundDefense',
                    'T1Radar',
                    'T2AADefense',
                    'T2GroundDefense',
                    'T2StrategicMissile',
                    'T2GroundDefense',
                    'T1LandFactory',
                    'T2ShieldDefense',
                    'T3AADefense',
                }
            },
            NeedGuard = true,
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'EngineerExpansionBuildersSmall',
    BuildersType = 'EngineerBuilder',

    --------------------------------------------------------------------------------
    ---- Builds expansion bases
    --------------------------------------------------------------------------------
    Builder {
        BuilderName = 'T1 Vacant Expansion Area Engineer(Full Base)',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 922,
        InstanceCount = 2,
        BuilderConditions = {
            --DUNCAN - Added to limit expansions
            { UCBC, 'ExpansionBaseCheck', { } },
            { UCBC, 'ExpansionAreaNeedsEngineer', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            --{ UCBC, 'StartLocationsFull', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            --{ EBC, 'MassIncomeToUnitRatio', { 10, '>=', 'FACTORY TECH1 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 20, '>=', 'FACTORY TECH2 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 30, '>=', 'FACTORY TECH3 STRUCTURE' } },
            --{ UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, 'MASSEXTRACTION', '>=','FACTORY' } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                NearMarkerType = 'Expansion Area',
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 100,
                ThreatRings = 2,
                ThreatType = 'StructuresNotMex',
                BuildStructures = {
                    'T1GroundDefense',
                    'T1LandFactory',
                    --DUNCAN - added AA
                    'T1AADefense',
                }
            },
            NeedGuard = true,
        }
    },
    Builder {
        BuilderName = 'T1 Vacant Expansion Area Engineer(Fire base)',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 0, --DUNCAN - was 850
        InstanceCount = 4,
        BuilderConditions = {
            { UCBC, 'ExpansionBaseCheck', { } },
            { UCBC, 'ExpansionAreaNeedsEngineer', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            --{ UCBC, 'StartLocationsFull', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .7 } },
            --{ UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, 'MASSEXTRACTION', '>=','FACTORY' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                NearMarkerType = 'Expansion Area',
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 0,
                ThreatRings = 2,
                ThreatType = 'StructuresNotMex',
                BuildStructures = {    --DUNCAN - added AA, radar, land fac
                    'T1GroundDefense',
                    'T1GroundDefense',
                    'T1AADefense',
                    'T1AADefense',
                }
            },
            NeedGuard = true,
        }
    },
    Builder {
        BuilderName = 'T1 Engineer Drop',
        PlatoonTemplate = 'EngineerDrop',
        Priority = 0, --DUNCAN - not working yet
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { MIBC, 'LessThanGameTime', { 600 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = true,
                NearMarkerType = 'Mass',
                BuildStructures = {
                    'T1GroundDefense',
                    'T1GroundDefense',
                    'T1GroundDefense',
                    'T1GroundDefense',
                    'T1LandFactory',
                    'T1AADefense',
                    'T1AADefense',
                    'T1GroundDefense',
                    'T1GroundDefense',
                    'T1GroundDefense',
                    'T1GroundDefense',
                    'T1LandFactory',
                    'T1GroundDefense',
                    'T1GroundDefense',
                    'T1GroundDefense',
                    'T1GroundDefense',
                }
            },
            NeedGuard = false,
        }
    },

    Builder {
        BuilderName = 'T2VacantExpansiongAreaEngineer',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 850,
        InstanceCount = 2,
        BuilderConditions = {
            --DUNCAN - Added to limit expansions
            { UCBC, 'ExpansionBaseCheck', { } },
            { UCBC, 'ExpansionAreaNeedsEngineer', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            --{ UCBC, 'StartLocationsFull', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .7 } },
            { UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, categories.MASSEXTRACTION, '>=', categories.FACTORY } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                NearMarkerType = 'Expansion Area',
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 0,
                ThreatRings = 2,
                ThreatType = 'StructuresNotMex',
                BuildStructures = {
                    --DUNCAN - Added strat missle, radar, extra PD, move fac to end, added shield
                    'T1GroundDefense',
                    'T1Radar',
                    'T2AADefense',
                    'T2GroundDefense',
                    'T2StrategicMissile',
                    'T2GroundDefense',
                    'T1LandFactory',
                    'T2ShieldDefense',
                }
            },
            NeedGuard = true,
        }
    },
    Builder {
        BuilderName = 'T3VacantExpansionAreaEngineer',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 850,
        InstanceCount = 2,
        BuilderConditions = {
            --DUNCAN - Added to limit expansions
            { UCBC, 'ExpansionBaseCheck', { } },
            { UCBC, 'ExpansionAreaNeedsEngineer', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            --{ UCBC, 'StartLocationsFull', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .7 } },
            { UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, categories.MASSEXTRACTION, '>=', categories.FACTORY } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                NearMarkerType = 'Expansion Area',
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 0,
                ThreatRings = 2,
                ThreatType = 'StructuresNotMex',
                BuildStructures = {
                    'T1LandFactory',
                    'T2GroundDefense',
                    'T2AADefense',
                    'T3AADefense',
                }
            },
            NeedGuard = true,
        }
    },
}


BuilderGroup {
    BuilderGroupName = 'EngineerFirebaseBuilders',
    BuildersType = 'EngineerBuilder',

    --------------------------------------------------------------------------------
    ---- Builds fire bases
    --------------------------------------------------------------------------------
    Builder {
        BuilderName = 'T2 Expansion Area Firebase Engineer',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 950, --DUNCAN - was 800
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'CanBuildFirebase', { 'LocationType', 256, 'Expansion Area', -1000, 5, 1, 'AntiSurface', 1, 'DEFENSE TECH2', 20} },
            { UCBC, 'UnitCapCheckLess', { .85 } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                FireBase = true,
                FireBaseRange = 256,
                NearMarkerType = 'Expansion Area',
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 5,
                ThreatRings = 1,
                ThreatType = 'AntiSurface',
                MarkerUnitCount = 1,
                MarkerUnitCategory = 'DEFENSE TECH2',
                MarkerRadius = 20,
                BuildStructures = {  --DUNCAN - changed base a bit
                    'T2GroundDefense',
                    'T1GroundDefense',
                    'T1Radar',
                    'T1AADefense',
                    'T2StrategicMissile',
                    'T2ShieldDefense',
                    'T2MissileDefense',
                    'T2GroundDefense',
                    'T2AADefense',
                    'T2StrategicMissile',
                    'T2Artillery',
                }
            }
        }
    },
    Builder {
        BuilderName = 'T3 Expansion Area Firebase Engineer',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 950, --DUNCAN - was 800
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'CanBuildFirebase', { 'LocationType', 256, 'Expansion Area', -1000, 5, 1, 'AntiSurface', 1, 'DEFENSE TECH2', 20} },
            { UCBC, 'UnitCapCheckLess', { .85 } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                FireBase = true,
                FireBaseRange = 256,
                NearMarkerType = 'Expansion Area',
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 5,
                ThreatRings = 1,
                MarkerUnitCount = 1,
                MarkerUnitCategory = 'DEFENSE TECH2',
                MarkerRadius = 20,
                BuildStructures = { --DUNCAN - changed base a bit
                    'T2GroundDefense',
                    'T1Radar',
                    'T2GroundDefense',
                    'T3AADefense',
                    'T2ShieldDefense',
                    'T2StrategicMissile',
                    'T2Artillery',
                    'T3AADefense',
                    'T2Artillery',
                    'T2Artillery',
                }
            }
        }
    },
}
