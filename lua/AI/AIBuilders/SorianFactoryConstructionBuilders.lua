--***************************************************************************
--*
--**  File     :  /lua/ai/SorianFactoryConstructionBuilders.lua
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
local SIBC = '/lua/editor/SorianInstantBuildConditions.lua'
local SBC = '/lua/editor/SorianBuildConditions.lua'

local ExtractorToFactoryRatio = 2.2

BuilderGroup {
    BuilderGroupName = 'SorianLandInitialFactoryConstruction',
    BuildersType = 'EngineerBuilder',
    -- =======================================
    --     Land Factory Builders - Initial
    -- =======================================
    Builder {
        BuilderName = 'Sorian T1 Land Factory Builder - Initial',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 1000,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'LAND FACTORY', 'LocationType', }},
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
    BuilderGroupName = 'SorianEngineerFactoryConstructionLandHigherPriority',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'SorianT2 Land Factory Builder Higher Pri',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 750,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, 'ENGINEER TECH3' } },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 3, 'LAND' } },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.1} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'LAND FACTORY', 'LocationType', }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1LandFactory',
                },
                Location = 'LocationType',
                --AdjacencyCategory = 'ENERGYPRODUCTION',
            }
        }
    },
    Builder {
        BuilderName = 'SorianT3 Land Factory Builder Higher Pri',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 750,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 3, 'LAND' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.1} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'LAND FACTORY', 'LocationType', }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1LandFactory',
                },
                Location = 'LocationType',
                --AdjacencyCategory = 'ENERGYPRODUCTION',
            }
        }
    },
    Builder {
        BuilderName = 'SorianCDR T1 Land Factory Higher Pri - Init',
        PlatoonTemplate = 'CommanderBuilderSorian',
        Priority = 905,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            --{ UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'LAND FACTORY'}},
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 3, 'FACTORY LAND' }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'LAND FACTORY', 'LocationType', }},
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
    Builder {
        BuilderName = 'Sorian T1 Land Factory Higher Pri - Init',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 975, --950,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            --{ UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'LAND FACTORY'}},
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 3, 'FACTORY LAND' }},
            { SBC, 'GreaterThanGameTime', { 165 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'LAND FACTORY', 'LocationType', }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1LandFactory',
                },
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T1 Land Factory Higher Pri',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 975, --950,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'LAND FACTORY'}},
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'AIR FACTORY'}},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 2, 'FACTORY LAND' }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, 'FACTORY AIR' }},
            { SBC, 'GreaterThanGameTime', { 165 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'LAND FACTORY', 'LocationType', }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1LandFactory',
                },
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T1 Air Factory Higher Pri',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 975, --950,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Air' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'LAND FACTORY'}},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 2, 'FACTORY LAND' }},
            { SBC, 'GreaterThanGameTime', { 165 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'AIR FACTORY', 'LocationType', }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1AirFactory',
                },
            }
        }
    },
    Builder {
        BuilderName = 'SorianCDR T1 Land Factory Higher Pri',
        PlatoonTemplate = 'CommanderBuilderSorian',
        Priority = 905,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'LAND FACTORY'}},
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'AIR FACTORY'}},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 2, 'FACTORY LAND' }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, 'FACTORY AIR' }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'LAND FACTORY', 'LocationType', }},
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
    Builder {
        BuilderName = 'SorianCDR T1 Air Factory Higher Pri',
        PlatoonTemplate = 'CommanderBuilderSorian',
        Priority = 905,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Air' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'LAND FACTORY'}},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 2, 'FACTORY LAND' }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'AIR FACTORY', 'LocationType', }},
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
}

BuilderGroup {
    BuilderGroupName = 'SorianEngineerFactoryConstruction Balance',
    BuildersType = 'EngineerBuilder',
    -- =============================
    --     Land Factory Builders
    -- =============================
    Builder {
        BuilderName = 'Sorian T1 Land Factory Builder Balance',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 905,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.1} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'LAND FACTORY', 'LocationType', }},
            --{ UCBC, 'FactoryRatioLessAtLocation', { 'LocationType', 'LAND', 'AIR' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1LandFactory',
                },
                Location = 'LocationType',
                --AdjacencyCategory = 'ENERGYPRODUCTION',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian CDR T1 Land Factory Balance',
        PlatoonTemplate = 'CommanderBuilderSorian',
        Priority = 905,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'LAND FACTORY', 'LocationType', }},
            --{ UCBC, 'FactoryRatioLessAtLocation', { 'LocationType', 'LAND', 'AIR' } },
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
        BuilderName = 'Sorian T1 Air Factory Builder Balance',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 906,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Air' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.1} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'FactoryRatioLessAtLocation', { 'LocationType', 'AIR', 'LAND' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'AIR FACTORY', 'LocationType', }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1AirFactory',
                },
                Location = 'LocationType',
                --AdjacencyCategory = 'ENERGYPRODUCTION',
            }
        }
    },

    Builder {
        BuilderName = 'Sorian CDR T1 Air Factory Balance',
        PlatoonTemplate = 'CommanderBuilderSorian',
        Priority = 906,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Air' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'FactoryRatioLessAtLocation', { 'LocationType', 'AIR', 'LAND' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'AIR FACTORY', 'LocationType', }},
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
}

BuilderGroup {
    BuilderGroupName = 'SorianEngineerFactoryConstruction Air',
    BuildersType = 'EngineerBuilder',
    Builder {
        BuilderName = 'Sorian T1 Air Factory Builder - Air',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 900,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Air' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.1} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'AIR FACTORY', 'LocationType', }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1AirFactory',
                },
                Location = 'LocationType',
                --AdjacencyCategory = 'ENERGYPRODUCTION',
            }
        }
    },

    Builder {
        BuilderName = 'Sorian CDR T1 Air Factory - Air',
        PlatoonTemplate = 'CommanderBuilderSorian',
        Priority = 900,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Air' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'AIR FACTORY', 'LocationType', }},
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
}

BuilderGroup {
    BuilderGroupName = 'SorianEngineerFactoryConstruction',
    BuildersType = 'EngineerBuilder',
    -- =============================
    --     Land Factory Builders
    -- =============================
    Builder {
        BuilderName = 'Sorian T1 Land Factory Builder',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 900,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.1} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'LAND FACTORY', 'LocationType', }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1LandFactory',
                },
                Location = 'LocationType',
                --AdjacencyCategory = 'ENERGYPRODUCTION',
            }
        },
    },
    Builder {
        BuilderName = 'Sorian CDR T1 Land Factory',
        PlatoonTemplate = 'CommanderBuilderSorian',
        Priority = 900,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'LAND FACTORY', 'LocationType', }},
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
    Builder {
        BuilderName = 'Sorian T1 Land Factory Builder - Dead ACU',
        PlatoonTemplate = 'AnyEngineerBuilderSorian',
        Priority = 900,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Land' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.1} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'LAND FACTORY', 'LocationType', }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, 'COMMAND', }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1LandFactory',
                },
                Location = 'LocationType',
                --AdjacencyCategory = 'ENERGYPRODUCTION',
            }
        },
    },

    -- ============================
    --     Air Factory Builders
    -- ============================
    Builder {
        BuilderName = 'Sorian T1 Air Factory Builder',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 900,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Air' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.1} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'AIR FACTORY', 'LocationType', }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1AirFactory',
                },
                Location = 'LocationType',
                --AdjacencyCategory = 'ENERGYPRODUCTION',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian CDR T1 Air Factory',
        PlatoonTemplate = 'CommanderBuilderSorian',
        Priority = 900,
        BuilderConditions = {
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.1} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Air' } },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'AIR FACTORY', 'LocationType', }},
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
    Builder {
        BuilderName = 'Sorian T1 Air Factory Builder - Dead ACU',
        PlatoonTemplate = 'AnyEngineerBuilderSorian',
        Priority = 900,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Air' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.1} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'AIR FACTORY', 'LocationType', }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, 'COMMAND', }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1AirFactory',
                },
                Location = 'LocationType',
                --AdjacencyCategory = 'ENERGYPRODUCTION',
            }
        }
    },

    -- ====================================== --
    --     Air Factories + Transport Need
    -- ====================================== --
    Builder {
        BuilderName = 'Sorian T1 Air Factory Transport Needed',
        PlatoonTemplate = 'EngineerBuilderSorian',
        Priority = 900,
        BuilderConditions = {
            { UCBC, 'EngineerLessAtLocation', { 'LocationType', 1, 'ENGINEER TECH3, ENGINEER TECH2' } },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Air' } },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 3, 'AIR FACTORY' } },
            { MIBC, 'ArmyNeedsTransports', {} },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'UnitCapCheckLess', { .8 } },
            { UCBC, 'HaveUnitRatio', { ExtractorToFactoryRatio, 'MASSEXTRACTION', '>=','FACTORY' } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'AIR FACTORY', 'LocationType', }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1AirFactory',
                },
                Location = 'LocationType',
                --AdjacencyCategory = 'ENERGYPRODUCTION',
            }
        }
    },

    -- =============================
    --     Quantum Gate Builders
    -- =============================
    Builder {
        BuilderName = 'Sorian T3 Gate Engineer',
        PlatoonTemplate = 'T3EngineerBuilderSorian',
        Priority = 950, --850,
        BuilderConditions = {
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH3' }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 2, 'MASSPRODUCTION TECH3' }},
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 1, 'GATE TECH3 STRUCTURE' }},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2} },
            { UCBC, 'FactoryCapCheck', { 'LocationType', 'Gate' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'UnitCapCheckLess', { .85 } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T3QuantumGate',
                },
                Location = 'LocationType',
                --AdjacencyCategory = 'ENERGYPRODUCTION',
            }
        }
    },
}

