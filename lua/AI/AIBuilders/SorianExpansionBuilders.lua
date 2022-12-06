--****************************************************************************
--**
--**  File     :  /lua/AI/AIBuilders/SorianExpansionBuilders.lua
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
local SBC = '/lua/editor/SorianBuildConditions.lua'
local SIBC = '/lua/editor/SorianInstantBuildConditions.lua'

local ExtractorToFactoryRatio = 3

BuilderGroup {
    BuilderGroupName = 'SorianEngineerExpansionBuildersFull',
    BuildersType = 'EngineerBuilder',

    --------------------------------------------------------------------------------
    ---- Builds expansion bases
    --------------------------------------------------------------------------------
    ------ Start the Factories in the expansion
    Builder {
        BuilderName = 'Sorian T1VacantStartingAreaEngineer - Rush',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 985,
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'StartLocationNeedsEngineer', { 'LocationType', 1000, -1000, 5, 0, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { SBC, 'LessThanGameTime', { 600 } },
            { SIBC, 'LessThanExpansionBases', { } },
            { SBC, 'NoRushTimeCheck', { 0 }},
            --{ UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, 'MASSEXTRACTION', '>=','FACTORY' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 6.5, '>=', 'FACTORY TECH1 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 14, '>=', 'FACTORY TECH2 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 19, '>=', 'FACTORY TECH3 STRUCTURE' } },
            --{ EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
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
                    'T1GroundDefense',
                    'T1LandFactory',
                    'T1LandFactory',
                    'T1AADefense',
                    'T1Radar',
                }
            },
            NeedGuard = true,
        }
    },

    Builder {
        BuilderName = 'Sorian T1VacantStartingAreaEngineer',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 932,
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'StartLocationNeedsEngineer', { 'LocationType', 1000, -1000, 100, 0, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { SIBC, 'LessThanExpansionBases', { } },
            { SBC, 'NoRushTimeCheck', { 0 }},
            --{ UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, 'MASSEXTRACTION', '>=','FACTORY' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 6.5, '>=', 'FACTORY TECH1 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 14, '>=', 'FACTORY TECH2 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 19, '>=', 'FACTORY TECH3 STRUCTURE' } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
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
        BuilderName = 'Sorian T2VacantStartingAreaEngineer',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 922,
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'StartLocationNeedsEngineer', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { SIBC, 'LessThanExpansionBases', { } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
            --{ UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, 'MASSEXTRACTION', '>=','FACTORY' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 6.5, '>=', 'FACTORY TECH1 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 14, '>=', 'FACTORY TECH2 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 19, '>=', 'FACTORY TECH3 STRUCTURE' } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
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
                    'T2GroundDefense',
                    'T1LandFactory',
                    'T2AADefense',
                    'T2Radar',
                }
            },
            NeedGuard = true,
        }
    },
    Builder {
        BuilderName = 'Sorian T3VacantStartingAreaEngineer',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 922,
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'StartLocationNeedsEngineer', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { SIBC, 'LessThanExpansionBases', { } },
            { SBC, 'NoRushTimeCheck', { 0 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, 'MASSEXTRACTION', '>=','FACTORY' } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
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
                    'T2GroundDefense',
                    'T1LandFactory',
                    'T3AADefense',
                    'T2Radar',
                }
            },
            NeedGuard = true,
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianEngineerExpansionBuildersFull - Naval',
    BuildersType = 'EngineerBuilder',

    --------------------------------------------------------------------------------
    ---- Builds expansion bases
    --------------------------------------------------------------------------------
    ------ Start the Factories in the expansion
    Builder {
        BuilderName = 'Sorian T1VacantStartingAreaEngineer - Naval',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 922,
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'StartLocationNeedsEngineer', { 'LocationType', 1000, -1000, 100, 0, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { SIBC, 'LessThanExpansionBases', { } },
            { SBC, 'NoRushTimeCheck', { 0 }},
            --{ UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, 'MASSEXTRACTION', '>=','FACTORY' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 6.5, '>=', 'FACTORY TECH1 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 14, '>=', 'FACTORY TECH2 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 19, '>=', 'FACTORY TECH3 STRUCTURE' } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
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
        BuilderName = 'Sorian T2VacantStartingAreaEngineer - Naval',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 922,
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'StartLocationNeedsEngineer', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { SIBC, 'LessThanExpansionBases', { } },
            { SBC, 'NoRushTimeCheck', { 0 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            --{ UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, 'MASSEXTRACTION', '>=','FACTORY' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 6.5, '>=', 'FACTORY TECH1 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 14, '>=', 'FACTORY TECH2 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 19, '>=', 'FACTORY TECH3 STRUCTURE' } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
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
                    'T2GroundDefense',
                    'T1LandFactory',
                    'T2AADefense',
                    'T2Radar',
                }
            },
            NeedGuard = true,
        }
    },
    Builder {
        BuilderName = 'Sorian T3VacantStartingAreaEngineer - Naval',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 922,
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'StartLocationNeedsEngineer', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { SIBC, 'LessThanExpansionBases', { } },
            { SBC, 'NoRushTimeCheck', { 0 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, 'MASSEXTRACTION', '>=','FACTORY' } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
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
                    'T2GroundDefense',
                    'T1LandFactory',
                    'T3AADefense',
                    'T2Radar',
                }
            },
            NeedGuard = true,
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianEngineerExpansionBuildersSmall',
    BuildersType = 'EngineerBuilder',

    --------------------------------------------------------------------------------
    ---- Builds expansion bases
    --------------------------------------------------------------------------------
    Builder {
        BuilderName = 'Sorian T1 Vacant Expansion Area Engineer(Full Base)',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 922,
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'ExpansionAreaNeedsEngineer', { 'LocationType', 1000, -1000, 100, 2, 'StructuresNotMex' } },
            { UCBC, 'StartLocationsFull', { 'LocationType', 1000, -1000, 100, 2, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { SIBC, 'LessThanExpansionBases', { } },
            { SBC, 'NoRushTimeCheck', { 0 }},
            --{ EBC, 'MassIncomeToUnitRatio', { 10, '>=', 'FACTORY TECH1 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 20, '>=', 'FACTORY TECH2 STRUCTURE' } },
            --{ EBC, 'MassIncomeToUnitRatio', { 30, '>=', 'FACTORY TECH3 STRUCTURE' } },
            --{ UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, 'MASSEXTRACTION', '>=','FACTORY' } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
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
                ThreatMax = 100,
                ThreatRings = 2,
                ThreatType = 'StructuresNotMex',
                BuildStructures = {
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
        BuilderName = 'Sorian T1 Vacant Expansion Area Engineer(Fire base)',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 0, --850,
        InstanceCount = 2,
        BuilderConditions = {
            { SIBC, 'ExpansionPointNeedsStructure', { 'LocationType', 1000, 'DEFENSE TECH1 STRUCTURE', 20, 3, 0, 1, 2, 'StructuresNotMex' } },
            --{ UCBC, 'StartLocationsFull', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .7 } },
            --{ UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, 'MASSEXTRACTION', '>=','FACTORY' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
            Construction = {
                BuildClose = false,
                MarkerRadius = 20,
                NearMarkerType = 'Expansion Area',
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = 0,
                ThreatMax = 1,
                ThreatRings = 2,
                MarkerUnitCount = 3,
                ThreatType = 'StructuresNotMex',
                MarkerUnitCategory = 'DEFENSE TECH1 STRUCTURE',
                BuildStructures = {
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
        BuilderName = 'Sorian T2VacantExpansiongAreaEngineer',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 850,
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'ExpansionAreaNeedsEngineer', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'StartLocationsFull', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .7 } },
            { SIBC, 'LessThanExpansionBases', { } },
            { SBC, 'NoRushTimeCheck', { 0 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, 'MASSEXTRACTION', '>=','FACTORY' } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
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
                BuildStructures = {
                    'T2GroundDefense',
                    'T1LandFactory',
                    'T2AADefense',
                    'T2Radar',
                }
            },
            NeedGuard = true,
        }
    },
    Builder {
        BuilderName = 'Sorian T3VacantExpansionAreaEngineer',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 850,
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'ExpansionAreaNeedsEngineer', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'StartLocationsFull', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UCBC, 'UnitCapCheckLess', { .7 } },
            { SIBC, 'LessThanExpansionBases', { } },
            { SBC, 'NoRushTimeCheck', { 0 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, 'MASSEXTRACTION', '>=','FACTORY' } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
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
                BuildStructures = {
                    'T2GroundDefense',
                    'T1LandFactory',
                    'T3AADefense',
                    'T2Radar',
                }
            },
            NeedGuard = true,
        }
    },
}


BuilderGroup {
    BuilderGroupName = 'SorianEngineerFirebaseBuilders',
    BuildersType = 'EngineerBuilder',

    --------------------------------------------------------------------------------
    ---- Builds fire bases
    --------------------------------------------------------------------------------
    Builder {
        BuilderName = 'Sorian T2 Expansion Area Firebase Engineer',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 851,
        InstanceCount = 1,
        BuilderConditions = {
            { MABC, 'CanBuildFirebase', { 'LocationType', 256, 'Expansion Area', -1000, 5, 1, 'AntiSurface', 1, 'STRATEGIC', 20} },
            { UCBC, 'UnitCapCheckLess', { .85 } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
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
                MarkerUnitCategory = 'STRATEGIC',
                MarkerRadius = 20,
                BuildStructures = {
                    'T2StrategicMissile',
                    'T2AADefense',
                    'T2GroundDefense',
                    'T2Radar',
                    'T2Artillery',
                    'T2MissileDefense',
                    'T2AADefense',
                    'T2GroundDefense',
                    'T2StrategicMissile',
                    'T2Artillery',
                    'T2ShieldDefense',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Expansion Area Firebase Engineer - Cybran',
        PlatoonTemplate = 'CybranT3EngineerBuilderSorian',
        Priority = 950,
        InstanceCount = 1,
        BuilderConditions = {
            { SBC, 'CanBuildFirebase', { 'LocationType', 700, 'Expansion Area', -10000, 5, 1, 'AntiSurface', 1, 'STRUCTURE ARTILLERY TECH3', 20} },
            --{ UCBC, 'UnitCapCheckLess', { .85 } },
            { SBC, 'EnemyInT3ArtilleryRange', { 'LocationType', false } },
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
            { SBC, 'MapGreaterThan', { 500, 500 }},
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                FireBase = true,
                FireBaseRange = 700,
                NearMarkerType = 'Expansion Area',
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                MarkerUnitCount = 1,
                MarkerUnitCategory = 'STRUCTURE ARTILLERY TECH3',
                MarkerRadius = 20,
                BuildStructures = {
                    'T2RadarJammer',
                    'T3AADefense',
                    'T2GroundDefense',
                    'T2Radar',
                    'T3AADefense',
                    'T2GroundDefense',
                    'T2MissileDefense',
                    'T2ShieldDefense',
                    'T2EngineerSupport',
                    'T2ShieldDefense',
                    'T3Artillery',
                    'T2Artillery',
                    'T2StrategicMissile',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Expansion Area Firebase Engineer - Aeon',
        PlatoonTemplate = 'AeonT3EngineerBuilderSorian',
        Priority = 950,
        InstanceCount = 1,
        BuilderConditions = {
            { SBC, 'CanBuildFirebase', { 'LocationType', 900, 'Expansion Area', -10000, 5, 1, 'AntiSurface', 1, 'STRUCTURE ARTILLERY TECH3', 20} },
            --{ UCBC, 'UnitCapCheckLess', { .85 } },
            { SBC, 'EnemyInT3ArtilleryRange', { 'LocationType', false } },
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
            { SBC, 'MapGreaterThan', { 500, 500 }},
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                FireBase = true,
                FireBaseRange = 900,
                NearMarkerType = 'Expansion Area',
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                MarkerUnitCount = 1,
                MarkerUnitCategory = 'STRUCTURE ARTILLERY TECH3',
                MarkerRadius = 20,
                BuildStructures = {
                    'T2RadarJammer',
                    'T3AADefense',
                    'T2GroundDefense',
                    'T2Radar',
                    'T3AADefense',
                    'T2GroundDefense',
                    'T2MissileDefense',
                    'T3ShieldDefense',
                    'T3ShieldDefense',
                    'T3Artillery',
                    'T2Artillery',
                    'T2StrategicMissile',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Expansion Area Firebase Engineer - UEF',
        PlatoonTemplate = 'UEFT3EngineerBuilderSorian',
        Priority = 950,
        InstanceCount = 1,
        BuilderConditions = {
            { SBC, 'CanBuildFirebase', { 'LocationType', 750, 'Expansion Area', -10000, 5, 1, 'AntiSurface', 1, 'STRUCTURE ARTILLERY TECH3', 20} },
            --{ UCBC, 'UnitCapCheckLess', { .85 } },
            { SBC, 'EnemyInT3ArtilleryRange', { 'LocationType', false } },
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
            { SBC, 'MapGreaterThan', { 500, 500 }},
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                FireBase = true,
                FireBaseRange = 750,
                NearMarkerType = 'Expansion Area',
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                MarkerUnitCount = 1,
                MarkerUnitCategory = 'STRUCTURE ARTILLERY TECH3',
                MarkerRadius = 20,
                BuildStructures = {
                    'T2RadarJammer',
                    'T3AADefense',
                    'T2GroundDefense',
                    'T2Radar',
                    'T3AADefense',
                    'T2GroundDefense',
                    'T2MissileDefense',
                    'T3ShieldDefense',
                    'T2EngineerSupport',
                    'T3ShieldDefense',
                    'T3Artillery',
                    'T2Artillery',
                    'T2StrategicMissile',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Expansion Area Firebase Engineer - Seraphim',
        PlatoonTemplate = 'SeraphimT3EngineerBuilderSorian',
        Priority = 950,
        InstanceCount = 1,
        BuilderConditions = {
            { SBC, 'CanBuildFirebase', { 'LocationType', 825, 'Expansion Area', -10000, 5, 1, 'AntiSurface', 1, 'STRUCTURE ARTILLERY TECH3', 20} },
            --{ UCBC, 'UnitCapCheckLess', { .85 } },
            { SBC, 'EnemyInT3ArtilleryRange', { 'LocationType', false } },
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
            { SBC, 'MapGreaterThan', { 500, 500 }},
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                FireBase = true,
                FireBaseRange = 825,
                NearMarkerType = 'Expansion Area',
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                MarkerUnitCount = 1,
                MarkerUnitCategory = 'STRUCTURE ARTILLERY TECH3',
                MarkerRadius = 20,
                BuildStructures = {
                    'T2RadarJammer',
                    'T3AADefense',
                    'T2GroundDefense',
                    'T2Radar',
                    'T3AADefense',
                    'T2GroundDefense',
                    'T2MissileDefense',
                    'T3ShieldDefense',
                    'T3ShieldDefense',
                    'T3Artillery',
                    'T2Artillery',
                    'T2StrategicMissile',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Expansion Area Firebase Engineer - Cybran - DP',
        PlatoonTemplate = 'CybranT3EngineerBuilderSorian',
        Priority = 950,
        InstanceCount = 1,
        BuilderConditions = {
            { SBC, 'CanBuildFirebase', { 'LocationType', 700, 'Defensive Point', -10000, 5, 1, 'AntiSurface', 1, 'STRUCTURE ARTILLERY TECH3', 20} },
            --{ UCBC, 'UnitCapCheckLess', { .85 } },
            { SBC, 'EnemyInT3ArtilleryRange', { 'LocationType', false } },
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
            { SBC, 'MapGreaterThan', { 500, 500 }},
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                FireBase = true,
                FireBaseRange = 700,
                NearMarkerType = 'Defensive Point',
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                MarkerUnitCount = 1,
                MarkerUnitCategory = 'STRUCTURE ARTILLERY TECH3',
                MarkerRadius = 20,
                BuildStructures = {
                    'T2RadarJammer',
                    'T3AADefense',
                    'T2GroundDefense',
                    'T2Radar',
                    'T3AADefense',
                    'T2GroundDefense',
                    'T2MissileDefense',
                    'T3ShieldDefense',
                    'T3ShieldDefense',
                    'T3Artillery',
                    'T2Artillery',
                    'T2StrategicMissile',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Expansion Area Firebase Engineer - Aeon - DP',
        PlatoonTemplate = 'AeonT3EngineerBuilderSorian',
        Priority = 950,
        InstanceCount = 1,
        BuilderConditions = {
            { SBC, 'CanBuildFirebase', { 'LocationType', 900, 'Defensive Point', -10000, 5, 1, 'AntiSurface', 1, 'STRUCTURE ARTILLERY TECH3', 20} },
            --{ UCBC, 'UnitCapCheckLess', { .85 } },
            { SBC, 'EnemyInT3ArtilleryRange', { 'LocationType', false } },
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
            { SBC, 'MapGreaterThan', { 500, 500 }},
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                FireBase = true,
                FireBaseRange = 900,
                NearMarkerType = 'Defensive Point',
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                MarkerUnitCount = 1,
                MarkerUnitCategory = 'STRUCTURE ARTILLERY TECH3',
                MarkerRadius = 20,
                BuildStructures = {
                    'T2RadarJammer',
                    'T3AADefense',
                    'T2GroundDefense',
                    'T2Radar',
                    'T3AADefense',
                    'T2GroundDefense',
                    'T2MissileDefense',
                    'T3ShieldDefense',
                    'T3ShieldDefense',
                    'T3Artillery',
                    'T2Artillery',
                    'T2StrategicMissile',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Expansion Area Firebase Engineer - UEF - DP',
        PlatoonTemplate = 'UEFT3EngineerBuilderSorian',
        Priority = 950,
        InstanceCount = 1,
        BuilderConditions = {
            { SBC, 'CanBuildFirebase', { 'LocationType', 750, 'Defensive Point', -10000, 5, 1, 'AntiSurface', 1, 'STRUCTURE ARTILLERY TECH3', 20} },
            --{ UCBC, 'UnitCapCheckLess', { .85 } },
            { SBC, 'EnemyInT3ArtilleryRange', { 'LocationType', false } },
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
            { SBC, 'MapGreaterThan', { 500, 500 }},
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                FireBase = true,
                FireBaseRange = 750,
                NearMarkerType = 'Defensive Point',
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                MarkerUnitCount = 1,
                MarkerUnitCategory = 'STRUCTURE ARTILLERY TECH3',
                MarkerRadius = 20,
                BuildStructures = {
                    'T2RadarJammer',
                    'T3AADefense',
                    'T2GroundDefense',
                    'T2Radar',
                    'T3AADefense',
                    'T2GroundDefense',
                    'T2MissileDefense',
                    'T3ShieldDefense',
                    'T3ShieldDefense',
                    'T3Artillery',
                    'T2Artillery',
                    'T2StrategicMissile',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Expansion Area Firebase Engineer - Seraphim - DP',
        PlatoonTemplate = 'SeraphimT3EngineerBuilderSorian',
        Priority = 950,
        InstanceCount = 1,
        BuilderConditions = {
            { SBC, 'CanBuildFirebase', { 'LocationType', 825, 'Defensive Point', -10000, 5, 1, 'AntiSurface', 1, 'STRUCTURE ARTILLERY TECH3', 20} },
            --{ UCBC, 'UnitCapCheckLess', { .85 } },
            { SBC, 'EnemyInT3ArtilleryRange', { 'LocationType', false } },
            --{ SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.TECH3 * categories.ANTIMISSILE}},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.EXPERIMENTAL}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
            { SBC, 'MapGreaterThan', { 500, 500 }},
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
            Construction = {
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                FireBase = true,
                FireBaseRange = 825,
                NearMarkerType = 'Defensive Point',
                LocationType = 'LocationType',
                ThreatMin = -10000,
                ThreatMax = 5,
                ThreatRings = 1,
                MarkerUnitCount = 1,
                MarkerUnitCategory = 'STRUCTURE ARTILLERY TECH3',
                MarkerRadius = 20,
                BuildStructures = {
                    'T2RadarJammer',
                    'T3AADefense',
                    'T2GroundDefense',
                    'T2Radar',
                    'T3AADefense',
                    'T2GroundDefense',
                    'T2MissileDefense',
                    'T3ShieldDefense',
                    'T3ShieldDefense',
                    'T3Artillery',
                    'T2Artillery',
                    'T2StrategicMissile',
                }
            }
        }
    },
}
