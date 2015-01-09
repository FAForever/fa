#***************************************************************************
#*
#**  File     :  /lua/ai/SorianNavalBuilders.lua
#**
#**  Summary  : Default Naval structure builders for skirmish
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
local PlatoonFile = '/lua/platoon.lua'
local SBC = '/lua/editor/SorianBuildConditions.lua'
local SIBC = '/lua/editor/SorianInstantBuildConditions.lua'


BuilderGroup {
    BuilderGroupName = 'SorianNavalExpansionBuildersFast',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T1 Naval Builder Fast - initial',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 985,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'NavalAreaNeedsEngineer', { 'LocationType', 600, -1000, 10, 1, 'AntiSurface' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, 'FACTORY NAVAL TECH2, FACTORY NAVAL TECH3'}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'FACTORY NAVAL TECH2, FACTORY NAVAL TECH3' } },
            { SIBC, 'LessThanNavalBases', { } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                NearMarkerType = 'Naval Area',
                LocationRadius = 600,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 10,
                ThreatRings = 0,
                ThreatType = 'AntiSurface',
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                ExpansionRadius = 50,
                BuildStructures = {
                'T1SeaFactory',
                'T1NavalDefense',
                'T1AADefense',
                'T1Sonar',
                'T1SeaFactory',
                'T1SeaFactory',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T1 Naval Builder Fast',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 922,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'NavalAreaNeedsEngineer', { 'LocationType', 600, -1000, 10, 1, 'AntiSurface' } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'FACTORY NAVAL'}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'FACTORY NAVAL TECH2, FACTORY NAVAL TECH3' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1 }},
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { SIBC, 'LessThanNavalBases', { } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                NearMarkerType = 'Naval Area',
                LocationRadius = 600,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 10,
                ThreatRings = 0,
                ThreatType = 'AntiSurface',
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                ExpansionRadius = 50,
                BuildStructures = {
                    'T1SeaFactory',
                'T1NavalDefense',
                'T1AADefense',
                'T1Sonar',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2 Naval Builder Fast',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 922,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'NavalAreaNeedsEngineer', { 'LocationType', 600, -1000, 10, 1, 'AntiSurface' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'FACTORY NAVAL TECH2, FACTORY NAVAL TECH3' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1 }},
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { SIBC, 'LessThanNavalBases', { } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                NearMarkerType = 'Naval Area',
                LocationRadius = 600,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 10,
                ThreatRings = 0,
                ThreatType = 'AntiSurface',
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                ExpansionRadius = 50,
                BuildStructures = {
                    'T1SeaFactory',
                'T2NavalDefense',
                'T2AADefense',
                'T2Sonar',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Naval Builder Fast',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 922,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'NavalAreaNeedsEngineer', { 'LocationType', 600, -1000, 10, 1, 'AntiSurface' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'FACTORY NAVAL TECH2, FACTORY NAVAL TECH3' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1 }},
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { SIBC, 'LessThanNavalBases', { } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                NearMarkerType = 'Naval Area',
                LocationRadius = 600,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 10,
                ThreatRings = 0,
                ThreatType = 'AntiSurface',
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                ExpansionRadius = 50,
                BuildStructures = {
                    'T1SeaFactory',
                'T2NavalDefense',
                'T3AADefense',
                'T2Sonar',
                }
            }
        }
    },
}

# For everything but Naval Rush
BuilderGroup {
    BuilderGroupName = 'SorianNavalExpansionBuilders',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T1 Naval Builder',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 922,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'NavalAreaNeedsEngineer', { 'LocationType', 600, -1000, 10, 1, 'AntiSurface' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1 }},
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { SIBC, 'LessThanNavalBases', { } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                NearMarkerType = 'Naval Area',
                LocationRadius = 600,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 10,
                ThreatRings = 0,
                ThreatType = 'AntiSurface',
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                ExpansionRadius = 50,
                BuildStructures = {
                    'T1SeaFactory',
                'T1NavalDefense',
                'T1AADefense',
                'T1Sonar',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2 Naval Builder',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 922,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'NavalAreaNeedsEngineer', { 'LocationType', 600, -1000, 10, 1, 'AntiSurface' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1 }},
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { SIBC, 'LessThanNavalBases', { } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                NearMarkerType = 'Naval Area',
                LocationRadius = 600,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 10,
                ThreatRings = 0,
                ThreatType = 'AntiSurface',
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                ExpansionRadius = 50,
                BuildStructures = {
                    'T1SeaFactory',
                'T2NavalDefense',
                'T2AADefense',
                'T2Sonar',
                }
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Naval Builder',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 922,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'NavalAreaNeedsEngineer', { 'LocationType', 600, -1000, 10, 1, 'AntiSurface' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1 }},
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { SIBC, 'LessThanNavalBases', { } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                NearMarkerType = 'Naval Area',
                LocationRadius = 600,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 10,
                ThreatRings = 0,
                ThreatType = 'AntiSurface',
                BuildClose = false,
                BaseTemplate = ExBaseTmpl,
                ExpansionBase = true,
                ExpansionRadius = 50,
                BuildStructures = {
                    'T1SeaFactory',
                'T2NavalDefense',
                'T3AADefense',
                'T2Sonar',
                }
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianEngineerNavalFactoryBuilder',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T1 Naval Factory Builder',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 905,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, 'ENGINEER TECH2, ENGINEER TECH3' } },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Sea' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1 }},
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                Location = 'LocationType',
                NearMarkerType = 'Naval Area',
                BuildClose = true,
                BuildStructures = {
                    'T1SeaFactory',
                },
            },
        },
    },
    Builder {
        BuilderName = 'Sorian T2 Naval Factory Builder',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 905,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, 'ENGINEER TECH3' } },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Sea' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1 }},
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                Location = 'LocationType',
                NearMarkerType = 'Naval Area',
                BuildClose = true,
                BuildStructures = {
                    'T1SeaFactory',
                },
            },
        },
    },
    Builder {
        BuilderName = 'Sorian T3 Naval Factory Builder',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 905,
        BuilderConditions = {
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Sea' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1 }},
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                Location = 'LocationType',
                NearMarkerType = 'Naval Area',
                BuildClose = true,
                BuildStructures = {
                    'T1SeaFactory',
                },
            },
        },
    },
}
