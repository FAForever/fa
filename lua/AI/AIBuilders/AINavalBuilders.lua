--***************************************************************************
--*
--**  File     :  /lua/ai/AINavalBuilders.lua
--**
--**  Summary  : Default Naval structure builders for skirmish
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
local PlatoonFile = '/lua/platoon.lua'

---@alias BuilderGroupsNaval 'NavalExpansionBuilders' | 'NavalExpansionBuilders HighPri' | 'EngineerNavalFactoryBuilder'

local NavalExpansionPriorityAdjust = function(self, aiBrain, builderManager)
    if aiBrain.IntelData.FrigateRaid then
        return 1000
    end
    if aiBrain.IntelData.MapWaterRatio < 0.20 and not aiBrain.IntelData.MassMarkersInWater then
        return 0
    elseif aiBrain.IntelData.MapWaterRatio < 0.30 then
        return 200
    elseif aiBrain.IntelData.MapWaterRatio < 0.40 then
        return 400
    elseif aiBrain.IntelData.MapWaterRatio < 0.60 then
        return 675
    else
        return 922
    end
end

-- For everything but Naval Rush
BuilderGroup {
    BuilderGroupName = 'NavalExpansionBuilders',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T1 Naval Builder',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 922,
        PriorityFunction = NavalExpansionPriorityAdjust,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'NavalBaseCheck', { } }, -- related to ScenarioInfo.Options.NavalExpansionsAllowed
            --DUNCAN - Added to limit expansions
            { UCBC, 'NavalBaseCount', { '<', 1 } },
            { UCBC, 'NavalAreaNeedsEngineer', { 'LocationType', 250, -1000, 10, 1, 'AntiSurface' } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.0 }},
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                NearMarkerType = 'Naval Area',
                LocationRadius = 250,
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
                }
            }
        }
    },
    Builder {
        BuilderName = 'T2 Naval Builder',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 0, --DUNCAN - was 922
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'NavalBaseCheck', { } }, -- related to ScenarioInfo.Options.NavalExpansionsAllowed
            --DUNCAN - Added to limit expansions
            { UCBC, 'NavalBaseCount', { '<', 1 } },
            { UCBC, 'NavalAreaNeedsEngineer', { 'LocationType', 250, -1000, 10, 1, 'AntiSurface' } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                NearMarkerType = 'Naval Area',
                LocationRadius = 250,
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
                }
            }
        }
    },
    Builder {
        BuilderName = 'T3 Naval Builder',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 0, --DUNCAN - was 922
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'NavalBaseCheck', { } }, -- related to ScenarioInfo.Options.NavalExpansionsAllowed
            --DUNCAN - Added to limit expansions
            { UCBC, 'NavalBaseCount', { '<', 1 } },
            { UCBC, 'NavalAreaNeedsEngineer', { 'LocationType', 250, -1000, 10, 1, 'AntiSurface' } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                NearMarkerType = 'Naval Area',
                LocationRadius = 250,
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
                }
            }
        }
    },
}

-- Used in Naval Rush
BuilderGroup {
    BuilderGroupName = 'NavalExpansionBuilders HighPri',
    BuildersType = 'EngineerBuilder',

    Builder {
        BuilderName = 'T1 Naval Builder Initial',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 985,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'NavalBaseCheck', { } }, -- related to ScenarioInfo.Options.NavalExpansionsAllowed
            --DUNCAN - Added to limit expansions
            { UCBC, 'NavalBaseCount', { '<', 1 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.FACTORY * categories.NAVAL } },
            { UCBC, 'NavalAreaNeedsEngineer', { 'LocationType', 500, -1000, 10, 1, 'AntiSurface' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY * categories.NAVAL * ( categories.TECH2 + categories.TECH3 )}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.FACTORY * categories.NAVAL * ( categories.TECH2 + categories.TECH3 ) } },
            --{ UCBC, 'UnitsGreaterThanExpansionValue', { 'MASSEXTRACTION', 6, 4, 6 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                NearMarkerType = 'Naval Area',
                LocationRadius = 500,
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
                    'T1SeaFactory',
                    'T1AADefense',
                    'T1SeaFactory',
                    'T1SeaFactory',
                    'T1AADefense',
                    'T1Sonar',
                    --'T1NavalDefense',
                    'T1SeaFactory',
                }
            }
        }
    },
    Builder {
        BuilderName = 'T1 Naval Builder HighPri',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 850,
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'NavalBaseCheck', { } }, -- related to ScenarioInfo.Options.NavalExpansionsAllowed
            --DUNCAN - Added to limit expansions
            { UCBC, 'NavalBaseCount', { '<', 2 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.FACTORY * categories.NAVAL }},
            { MIBC, 'MapGreaterThan', { 512, 512 }},
            { UCBC, 'NavalAreaNeedsEngineer', { 'LocationType', 500, -1000, 10, 1, 'AntiSurface' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.FACTORY * categories.NAVAL * ( categories.TECH2 + categories.TECH3 ) } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                NearMarkerType = 'Naval Area',
                LocationRadius = 500,
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
                    'T1AADefense',
                    --'T1NavalDefense',
                    'T1Sonar',
                }
            }
        }
    },
    Builder {
        BuilderName = 'T2 Naval Builder HighPri',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 0, --DUNCAN - was 850
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'NavalBaseCheck', { } }, -- related to ScenarioInfo.Options.NavalExpansionsAllowed
            --DUNCAN - Added to limit expansions
            { UCBC, 'NavalBaseCount', { '<', 2 } },
            { MIBC, 'MapGreaterThan', { 512, 512 }},
            { UCBC, 'NavalAreaNeedsEngineer', { 'LocationType', 500, -1000, 10, 1, 'AntiSurface' } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                NearMarkerType = 'Naval Area',
                LocationRadius = 500,
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
                }
            }
        }
    },
    Builder {
        BuilderName = 'T3 Naval Builder HighPri',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority =  0, --DUNCAN - was 850
        InstanceCount = 1,
        BuilderConditions = {
            { UCBC, 'NavalBaseCheck', { } }, -- related to ScenarioInfo.Options.NavalExpansionsAllowed
            --DUNCAN - Added to limit expansions
            { UCBC, 'NavalBaseCount', { '<', 2 } },
            { MIBC, 'MapGreaterThan', { 512, 512 }},
            { UCBC, 'NavalAreaNeedsEngineer', { 'LocationType', 500, -1000, 10, 1, 'AntiSurface' } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                NearMarkerType = 'Naval Area',
                LocationRadius = 500,
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
                }
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'EngineerNavalFactoryBuilder',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'T1 Naval Factory Builder',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'NavalBaseCheck', { } }, -- related to ScenarioInfo.Options.NavalExpansionsAllowed
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Sea' } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
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
        BuilderName = 'T2 Naval Factory Builder',
        PlatoonTemplate = 'T2EngineerBuilder',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'NavalBaseCheck', { } }, -- related to ScenarioInfo.Options.NavalExpansionsAllowed
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Sea' } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
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
        BuilderName = 'T3 Naval Factory Builder',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'NavalBaseCheck', { } }, -- related to ScenarioInfo.Options.NavalExpansionsAllowed
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Sea' } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
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
