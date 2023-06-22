--***************************************************************************
--*
--**  File     :  /lua/ai/AIFactoryConstructionBuilders.lua
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

local ExtractorToFactoryRatio = 2.2

---@alias BuilderGroupsFactoryConstruction 'LandInitialFactoryConstruction' | 'AirInitialFactoryConstruction' | 'EngineerFactoryConstructionAirHigherPriority' | 'EngineerFactoryConstruction Balance' | 'EngineerFactoryConstruction'

BuilderGroup {
    BuilderGroupName = 'LandInitialFactoryConstruction',
    BuildersType = 'EngineerBuilder',
    -- =======================================
    --     Land Factory Builders - Initial
    -- =======================================
    Builder {
        BuilderName = 'T1 Land Factory Builder - Initial',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1500,  --DUNCAN - was 1000
        BuilderConditions = {
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 1, categories.LAND } }, --DUNCAN - added
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                Location = 'LocationType',
                BuildStructures = {
                    'T1LandFactory',
                },
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'AirInitialFactoryConstruction',
    BuildersType = 'EngineerBuilder',
    -- ======================================
    --     Air Factory Builders - Initial
    -- ======================================
    Builder {
        BuilderName = 'T1 Air Factory Builder - Initial',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1500, --DUNCAN - was 1000
        BuilderConditions = {
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 1, categories.AIR } }, --DUNCAN - added
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Air' } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                Location = 'LocationType',
                BuildStructures = {
                    'T1AirFactory',
                },
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'EngineerFactoryConstructionExpansion',
    BuildersType = 'EngineerBuilder',
    -- ============================
    --     Air Factory Builders
    -- ============================
    Builder {
        BuilderName = 'Air Factory Builder Expansion',
        PlatoonTemplate = 'T123EngineerBuilder',
        Priority = 750,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Air' } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 1.05, 1.1} },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 3, categories.AIR } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1AirFactory',
                },
                Location = 'LocationType',
                AdjacencyCategory = categories.ENERGYPRODUCTION,
            }
        }
    },
    Builder {
        BuilderName = 'Land Factory Builder Expansion',
        PlatoonTemplate = 'T123EngineerBuilder',
        Priority = 750,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 1.05, 1.1} },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 3, categories.LAND } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1LandFactory',
                },
                Location = 'LocationType',
                AdjacencyCategory = categories.ENERGYPRODUCTION,
            }
        }
    },
    
}

BuilderGroup {
    BuilderGroupName = 'EngineerFactoryConstruction',
    BuildersType = 'EngineerBuilder',
    -- =============================
    --     Land Factory Builders
    -- =============================
    Builder {
        BuilderName = 'T1 Land Factory Primary Builder',
        PlatoonTemplate = 'T123EngineerBuilder',
        Priority = 925,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { UCBC, 'FactoryLessAtLocation', { 'MAIN', 1, categories.STRUCTURE * categories.FACTORY * categories.LAND - categories.SUPPORTFACTORY }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.FACTORY * categories.LAND - categories.SUPPORTFACTORY }},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 0.8 } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1LandFactory',
                },
                Location = 'LocationType',
                AdjacencyCategory = 'ENERGYPRODUCTION',
            }
        },
    },
    Builder {
        BuilderName = 'T1 Land Factory Builder Land Path',
        PlatoonTemplate = 'T123EngineerBuilder',
        Priority = 950,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.85, 0.85 } },
            { MIBC, 'PathToEnemy', { 'LocationType', 'Land' }},
            { UCBC, 'FactoryLessAtLocation', { 'MAIN', 4, categories.STRUCTURE * categories.FACTORY * categories.LAND }},
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1LandFactory',
                },
                Location = 'LocationType',
                AdjacencyCategory = categories.ENERGYPRODUCTION,
            }
        },
    },
    Builder {
        BuilderName = 'T1 Land Factory Builder',
        PlatoonTemplate = 'T123EngineerBuilder',
        Priority = 900,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.05 } },
            { UCBC, 'ForcePathLimit', {'LocationType', categories.FACTORY * categories.LAND, 'Land', 2}},
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1LandFactory',
                },
                Location = 'LocationType',
                AdjacencyCategory = categories.ENERGYPRODUCTION,
            }
        },
    },
    Builder {
        BuilderName = 'CDR T1 Land Factory',
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 900,
        BuilderConditions = {
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.85, 1.0 } },
            { UCBC, 'ForcePathLimit', {'LocationType', categories.FACTORY * categories.LAND, 'Land', 2}},
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T1LandFactory',
                },
            }
        }
    },

    -- ============================
    --     Air Factory Builders
    -- ============================
    Builder {
        BuilderName = 'T1 Air Factory Primary Builder',
        PlatoonTemplate = 'T123EngineerBuilder',
        Priority = 925,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Air' } },
            { UCBC, 'FactoryLessAtLocation', { 'MAIN', 1, categories.STRUCTURE * categories.FACTORY * categories.AIR - categories.SUPPORTFACTORY }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.STRUCTURE * categories.FACTORY * categories.AIR - categories.SUPPORTFACTORY }},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 0.8 } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1AirFactory',
                },
                Location = 'LocationType',
                AdjacencyCategory = 'ENERGYPRODUCTION',
            }
        }
    },
    Builder {
        BuilderName = 'T1 Air Factory Builder',
        PlatoonTemplate = 'T123EngineerBuilder',
        Priority = 900,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Air' } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.95, 1.05 } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1AirFactory',
                },
                Location = 'LocationType',
                AdjacencyCategory = categories.ENERGYPRODUCTION,
            }
        }
    },

    Builder {
        BuilderName = 'CDR T1 Air Factory',
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 900,
        BuilderConditions = {
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.85, 1.0 } },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Air' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T1AirFactory',
                },
            }
        }
    },

    -- ====================================== --
    --     Air Factories + Transport Need
    -- ====================================== --
    Builder {
        BuilderName = 'T1 Air Factory Transport Needed',
        PlatoonTemplate = 'T123EngineerBuilder',
        Priority = 900,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Air' } },
            { MIBC, 'TransportRequested', {} },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 1, categories.AIR * categories.FACTORY } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1AirFactory',
                },
                Location = 'LocationType',
                AdjacencyCategory = categories.ENERGYPRODUCTION,
            }
        }
    },

    -- =============================
    --     Quantum Gate Builders
    -- =============================
    Builder {
        BuilderName = 'T3 Gate Engineer',
        PlatoonTemplate = 'T3EngineerBuilder',
        Priority = 850,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.EXPERIMENTAL } }, --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.EXPERIMENTAL}}, --DUNCAN - Added
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENERGYPRODUCTION * categories.TECH3 }},
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 1, categories.GATE * categories.TECH3 * categories.STRUCTURE }},
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Gate' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T3QuantumGate',
                },
                Location = 'LocationType',
                AdjacencyCategory = categories.ENERGYPRODUCTION,
            }
        }
    },
}
