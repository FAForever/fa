local AIBuildUnits = import("/lua/ai/aibuildunits.lua")
local AIUtils = import("/lua/ai/aiutilities.lua")
local TemplateNames = import("/lua/templatenames.lua").TemplateNames

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
local BMBC = '/lua/editor/basemanagerbuildconditions.lua'
local SAI = '/lua/scenarioplatoonai.lua'
local PlatoonFile = '/lua/platoon.lua'

Builders = {
    ------------------------------------------------
    ------ ECONOMY BUILDERS ------
    ------------------------------------------------
    {
        BuilderName = 'T1ResourceEngineer',
        TemplateName = 'T1EngineerBuilder',
        -- AI Function
        Priority = 1000,
        InstanceCount = 2,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
                { BMBC, 'NeedStructure', { 'T1Resource', 'BASENAME'}},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T1Resource',
                }
            }
        }
    },
    {
        BuilderName = 'T2ResourceEngineer',
        TemplateName = 'T2EngineerBuilder',
        Priority = 900,
        InstanceCount = 1,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH2}},
                { BMBC, 'NeedStructure', { 'T2Resource', 'BASENAME'}},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T2Resource',
                }
            }
        }
    },
    {
        BuilderName = 'T3ResourceEngineer',
        TemplateName = 'T3EngineerBuilder',
        Priority = 900,
        InstanceCount = 1,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH2}},
                { BMBC, 'NeedStructure', { 'T3Resource', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T3Resource',
                }
            }
        }
    },
    {
        BuilderName = 'T1HydrocarbonEngineer',
        TemplateName = 'T1EngineerBuilder',
        Priority = 975,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
                { BMBC, 'NeedStructure', { 'T1HydroCarbon', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T1HydroCarbon',
                }
            }
        }
    },
    {
        BuilderName = 'T1PowerEngineer',
        Priority = 950,
        TemplateName = 'T1EngineerBuilder',
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 20, categories.TECH1 * categories.ENERGYPRODUCTION}},
                { BMBC, 'NeedStructure', { 'T1EnergyProduction', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                },
            }
        }
    },
--    {
--        BuilderName = 'T1 Engineer Reclaim',
--        PlatoonAIPlan = 'ReclaimAI',
--        Priority = 975,
--        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
--                { MIBC, 'ReclaimablesInArea', { 'MAIN', }},
--            },
--        PlatoonType = 'Any',
--        RequiresConstruction = false,
--        PlatoonData = {
--            NotPartOfAttackForce = true,
--        },
--    },
--    {
--        BuilderName = 'T1 Engineer Reclaim Enemy Walls',
--        PlatoonAIPlan = 'ReclaimUnitsAI',
--        Priority = 975,
--        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
--                { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 10, categories.WALL, 'Enemy'}},
--            },
--        PlatoonType = 'Any',
--        RequiresConstruction = false,
--        PlatoonData = {
--            Radius = 1000,
--            Categories = {'WALL'},
--            ThreatMin = -10,
--            ThreatMax = 10000,
--            ThreatRings = 1,
--            NotPartOfAttackForce = true,
--        },
--    },
--    {
--        BuilderName = 'T2 Engineer Capture',
--        PlatoonAIPlan = 'CaptureAI',
--        Priority = 900,
--        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
--                { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 10, categories.ENERGYPRODUCTION * categories.TECH2, 'Enemy'}},
--                { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 10, categories.DEFENSE, 'Enemy'}},
--            },
--        PlatoonType = 'Any',
--        RequiresConstruction = false,
--        PlatoonData = {
--            Radius = 300,
--            Categories = {'ENERGYPRODUCTION, MASSPRODUCTION, ARTILLERY, FACTORY'},
--            ThreatMin = 1,
--            ThreatMax = 1,
--            ThreatRings = 1,
--            NotPartOfAttackForce = true,
--        },
--    },
    {
        BuilderName = 'T2PowerEngineer2',
        TemplateName = 'T2EngineerBuilder',
        Priority = 950,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH2}},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 10, categories.TECH2 * categories.ENERGYPRODUCTION}},
                { BMBC, 'NeedStructure', { 'T2EnergyProduction', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T2EnergyProduction',
                    'T2EnergyProduction',
                    'T2EnergyProduction',
                },
            }
        }
    },
--    {
--        BuilderName = 'T2EngineerPatrol',
--        TemplateName = 'T2EngineerGenericSingle',
--        PlatoonAIPlan = 'ReclaimAI',
--        Priority = 975,
--        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
--            },
--        PlatoonType = 'Any',
--        RequiresConstruction = false,
--        PlatoonData = {
--            NotPartOfAttackForce = true,
--        },
--    },
    {
        BuilderName = 'T3PowerEngineer',
        TemplateName = 'T3EngineerBuilder',
        Priority = 950,
        InstanceCount = 1,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH3}},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 25, categories.TECH3 * categories.ENERGYPRODUCTION}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.1, 0.2}},
                { BMBC, 'NeedStructure', { 'T3EnergyProduction', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T3EnergyProduction',
                    'T3EnergyProduction',
                    'T3EnergyProduction',
                },
            }
        }
    },
    {
        BuilderName = 'T3MassFabEngineer',
        TemplateName = 'T3EngineerBuilder',
        Priority = 950,
        InstanceCount = 1,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH3}},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 15, categories.TECH3 * categories.MASSFABRICATION}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.1, 0.2}},
                { BMBC, 'NeedStructure', { 'T3MassCreation', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T3MassCreation',
                    'T3MassCreation',
                },
            }
        }
    },

    --------------------------------------------------------------------------------
    ----  BASE CONSTRUCTION
    --------------------------------------------------------------------------------
    {
        BuilderName = 'T1RadarEngineer',
        TemplateName = 'EngineerBuilder',
        Priority = 950,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.RADAR}},
                { EBC, 'GreaterThanEconIncome',  { 0.5, 15}},
                { BMBC, 'NeedStructure', { 'T1Radar', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T1Radar',
                },
            }
        }
    },
    {
        BuilderName = 'T2AirStagingEngineer',
        TemplateName = 'T2EngineerBuilder',
        Priority = 800,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH2}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 25, categories.AIR}},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 2, categories.AIRSTAGINGPLATFORM}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.3, 0.3}},
                { BMBC, 'NeedStructure', { 'T2AirStagingPlatform', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T2AirStagingPlatform',
                },
            }
        }
    },
    {
        BuilderName = 'T2ArtilleryEngineer',
        TemplateName = 'T2EngineerBuilder',
        Priority = 800,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH2}},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 10, categories.ARTILLERY * categories.STRUCTURE * categories.TECH2}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.2, 0.2}},
                { BMBC, 'NeedStructure', { 'T2Artillery', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T2Artillery',
                    'T2Artillery',
                },
            }
        }
    },
    {
        BuilderName = 'T2MissileEngineer',
        TemplateName = 'T2EngineerBuilder',
        Priority = 800,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH2}},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 10, categories.ARTILLERY * categories.STRUCTURE * categories.TECH2}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.2, 0.2}},
                { BMBC, 'NeedStructure', { 'T2StrategicMissile', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T2StrategicMissile',
                    'T2StrategicMissile',
                },
            }
        }
    },
    {
        BuilderName = 'T3GateEngineer',
        TemplateName = 'T3EngineerBuilder',
        Priority = 850,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 10, categories.ENGINEER * categories.TECH3}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.FACTORY * categories.TECH3}},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.GATE * categories.TECH3 * categories.STRUCTURE}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.7, 0.7}},
                { BMBC, 'NeedStructure', { 'T3QuantumGate', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T3QuantumGate',
                },
            }
        }
    },
    {
        BuilderName = 'T3ArtilleryEngineer',
        TemplateName = 'T3EngineerBuilderBig',
        Priority = 875,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 8, categories.ENGINEER * categories.TECH3}},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.TECH3 * categories.ARTILLERY}},
                { EBC, 'GreaterThanEconIncome', {15, 100}},
                { BMBC, 'NeedStructure', { 'T3Artillery', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        PlatoonAddPlans = {'PlatoonCallForHelpAI'},
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T3Artillery', 
                },
            }
        }
    },
    {
        BuilderName = 'T3NukeEngineer',
        TemplateName = 'T3EngineerBuilderBig',
        Priority = 875,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 8, categories.ENGINEER * categories.TECH3}},
                { EBC, 'GreaterThanEconIncome', {15, 100}},
                { BMBC, 'NeedStructure', { 'T3StrategicMissile', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T3StrategicMissile', 
                },
            }
        }
    },
    --------------------------------------------------------------------------------
    ----  BASE DEFENSE CONSTRUCTION
    --------------------------------------------------------------------------------
    {
        BuilderName = 'T1BaseDEngineerGround',
        TemplateName = 'EngineerGenericSingle',
        Priority = 700,
        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
--                { UCBC, 'HaveLessThanUnitsWithCategory', { 10, categories.DEFENSE * categories.TECH1}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.3, 0.3}},
                { BMBC, 'NeedStructure', { 'T1GroundDefense', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T1GroundDefense',
                    'T1GroundDefense',
                    'T1GroundDefense',
                    'T1GroundDefense',
                },
            }
        }
    },
    {
        BuilderName = 'T1BaseDEngineerAA',
        TemplateName = 'EngineerGenericSingle',
        Priority = 700,
        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
--                { UCBC, 'HaveLessThanUnitsWithCategory', { 10, categories.DEFENSE * categories.TECH1}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.3, 0.3}},
                { BMBC, 'NeedStructure', { 'T1AADefense', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T1AADefense',
                    'T1AADefense',
                    'T1AADefense',
                    'T1AADefense',
                },
            }
        }
    },
    {
        BuilderName = 'T2BaseDEngineerGround',
        TemplateName = 'T2EngineerGenericSingle',
        Priority = 900,
        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH2}},
--                { UCBC, 'HaveLessThanUnitsWithCategory', { 15, categories.DEFENSE * categories.TECH2}},
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.2, 0.2}},
                { BMBC, 'NeedStructure', { 'T2GroundDefense', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T2GroundDefense',
                    'T2GroundDefense',
                },
            }
        }
    },
    {
        BuilderName = 'T2BaseDEngineerAA',
        TemplateName = 'T2EngineerGenericSingle',
        Priority = 900,
        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH2}},
--                { UCBC, 'HaveLessThanUnitsWithCategory', { 15, categories.DEFENSE * categories.TECH2}},
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.2, 0.2}},
                { BMBC, 'NeedStructure', { 'T2AADefense', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T2AADefense', 
                    'T2AADefense',
                },
            }
        }
    },
    {
        BuilderName = 'T2BaseDEngineerMissile',
        TemplateName = 'T2EngineerGenericSingle',
        Priority = 900,
        BuildConditions = {
                { EBC, 'GreaterThanEconStorageRatio', { 0.2, 0.2}},
                { BMBC, 'NeedStructure', { 'T2MissileDefense', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T2MissileDefense', 
                    'T2MissileDefense',
                },
            }
        }
    },
    {
        BuilderName = 'T2ShieldDEngineer',
        TemplateName = 'T2EngineerBuilder',
        Priority = 850,
        BuildConditions = {
                { EBC, 'GreaterThanEconStorageRatio', { 0.2, 0.4}},
                { BMBC, 'NeedStructure', { 'T2ShieldDefense', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T2ShieldDefense', 
                },
            }
        }
    },
    {
        BuilderName = 'T2CounterIntel',
        TemplateName = 'T2EngineerBuilder',
        Priority = 850,
        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH2}},
--                { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.COUNTERINTELLIGENCE * categories.TECH2}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.2, 0.4}},
                { BMBC, 'NeedStructure', { 'T2RadarJammer', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T2RadarJammer',
                },
            }
        }
    },
    {
        BuilderName = 'T3Anti-NukeEngineer',
        TemplateName = 'T3EngineerBuilder',
        Priority = 850,
        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 8, categories.ENGINEER * categories.TECH3}},
--                { UCBC, 'HaveLessThanUnitsWithCategory', { 5, categories.ANTIMISSILE * categories.TECH3}},
                { EBC, 'GreaterThanEconIncome', { 2.5, 100}},
                { BMBC, 'NeedStructure', { 'T3StrategicMissileDefense', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T3StrategicMissileDefense', 
                },
            }
        }
    },
    {
        BuilderName = 'T3BaseDEngineerAA',
        TemplateName = 'T3EngineerGenericSingle',
        Priority = 875,
        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 8, categories.ENGINEER * categories.TECH3}},
--                { UCBC, 'HaveLessThanUnitsWithCategory', { 20, categories.DEFENSE * categories.TECH3}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.2, 0.2}},
                { BMBC, 'NeedStructure', { 'T3AADefense', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T3AADefense',
                    'T3AADefense',
                },
            }
        }
    },
    {
        BuilderName = 'T3ShieldDEngineer',
        TemplateName = 'T3EngineerBuilder',
        Priority = 875,
        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 8, categories.ENGINEER * categories.TECH3}},
--                { UCBC, 'HaveLessThanUnitsWithCategory', { 10, categories.SHIELD * categories.TECH3}},
                { MIBC, 'FactionIndex', {1, 2}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.1, 0.2}},
                { BMBC, 'NeedStructure', { 'T3ShieldDefense', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T3ShieldDefense', 
                },
            }
        }
    },


    --------------------------------------------------------------------------------
    ---- EMERGENCY BUILDING TECH 1
    --------------------------------------------------------------------------------
    
    {
        BuilderName = 'T1EmergencyMassExtractionEngineer',
        TemplateName = 'EngineerBuilder',
        Priority = 700,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.05, 0.0}},
                { EBC, 'LessThanEconTrend', { 0, 100000}},
                { BMBC, 'NeedStructure', { 'T1Resource', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T1Resource',
                }
            }
        }
    },
    {
        BuilderName = 'T1EmergencyMassCreationEngineer',
        TemplateName = 'EngineerBuilder',
        Priority = 850,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
                { EBC, 'LessThanEconStorageRatio', { 0.1, 1.1}},
                { BMBC, 'NeedStructure', { 'T1MassCreation', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T1MassCreation',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                },
            }
        }
    },
    {
        BuilderName = 'T1 Emergency Power Engineer',
        TemplateName = 'EngineerBuilder',
        Priority = 850,
        InstanceCount = 2,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
                { EBC, 'LessThanEconStorageRatio', { 1.1, 0.1}},
                { EBC, 'LessThanEconTrend', { 100000, 0}},
                { BMBC, 'NeedStructure', { 'T1EnergyProduction', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                    'T1EnergyProduction',
                },
            }
        }
    },
    {
        BuilderName = 'T1MassStorage',
        TemplateName = 'EngineerBuilder',
        Priority = 800,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.2, 0.1}},
                { BMBC, 'NeedStructure', { 'MassStorage', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'MassStorage',
                    'MassStorage',
                    'MassStorage',
                    'MassStorage',
                }
            }
        }
    },
    {
        BuilderName = 'T1EnergyStorageEngineer',
        TemplateName = 'EngineerBuilder',
        Priority = 750,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.5, 0.9}},
                { BMBC, 'NeedStructure', { 'EnergyStorage', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'EnergyStorage',
                },
                Location = 'MAIN',
            }
        }
    },
    
    --------------------------------------------------------------------------------
    ---- EMERGENCY BUILDING TECH 2
    --------------------------------------------------------------------------------
    {
        BuilderName = 'T2PowerEngineer',
        TemplateName = 'T2EngineerBuilder',
        Priority = 975,
        InstanceCount = 1,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH2}},
                { EBC, 'LessThanEconStorageRatio', { 1.1, 0.3}},
                { BMBC, 'NeedStructure', { 'T2EnergyProduction', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T2EnergyProduction',
                },
            }
        }
    },
    
    --------------------------------------------------------------------------------
    ---- EMERGENCY BUILDING TECH 3
    --------------------------------------------------------------------------------
    {
        BuilderName = 'T3EmergencyPowerEngineer',
        TemplateName = 'T3EngineerBuilder',
        Priority = 975,
        InstanceCount = 1,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH3}},
                { EBC, 'LessThanEconStorageRatio', { 1.1, 0.5}},
                { EBC, 'LessThanEconTrend', { 100000, 0}},
                { BMBC, 'NeedStructure', { 'T3EnergyProduction', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T3EnergyProduction',
                },
            }
        }
    },
    {
        BuilderName = 'T3EmergencyMassFabEngineer',
        TemplateName = 'T3EngineerBuilder',
        Priority = 975,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH3}},
                { EBC, 'LessThanEconStorageRatio', { 0.1, 1.1}},
                { EBC, 'LessThanEconTrend', { 0, 100000}},
                { BMBC, 'NeedStructure', { 'T3MassCreation', 'BASENAME' }},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Construction = {
                BuildStructures = {
                    'T3MassCreation',
                },
            }
        }
    },
    
    
    
    
    
    ------------------------------------------------------------------------------
    ------------ COMMANDER STUFF --------------------------------
    ------------------------------------------------------------------------------
--    {
--        BuilderName = 'EngineerT1LandFactory-HaveNone',
--        TemplateName = 'CommanderBuilder',
--        Priority = 500,
--        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.COMMAND}},
--                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY * categories.LAND}},
--            },
--        LocationType = 'MAIN',
--        PlatoonType = 'Any',
--        PlatoonAddPlans = {'PlatoonCallForHelpAI'},
--        RequiresConstruction = false,
--        ExpansionExclude = {'Sea'},
--        PlatoonData = {
--            Construction = {
--                BuildClose = true,
--                BuildStructures = {
--                    'T1LandFactory',
--                },
--                Location = 'MAIN',
--            }
--        }
--    },
    




    ------------------------------------------------------------------
    -------- EXPERIMENTAL BUILDERS ------------
    ------------------------------------------------------------------
--    {
--        BuilderName = 'T3 Land Exp1 Engineer 1',
--        TemplateName = 'T3EngineerBuilder',
--        Priority = 875,
--        InstanceCount = 1,
--        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH3}},
--        },
--        LocationType = 'MAIN',
--        PlatoonType = 'Any',
--        PlatoonAddPlans = {'PlatoonCallForHelpAI'},
--        ExpansionExclude = {'Sea'},
--        RequiresConstruction = false,
--        PlatoonData = {
--            Construction = {
--                BuildClose = false,
--                BaseTemplate = ExBaseTmpl,
--                NearMarkerType = 'Rally Point',
--                BuildStructures = {
--                    'T4LandExperimental1', 
--                },
--                Location = 'MAIN',
--            }
--        }
--    },
--    {
--        BuilderName = 'T3 Land Exp2 Engineer 1',
--        TemplateName = 'T3EngineerBuilder',
--        Priority = 825,
--        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH3}},
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.LAND * categories.EXPERIMENTAL}},
--            },
--        LocationType = 'MAIN',
--        PlatoonType = 'Any',
--        PlatoonAddPlans = {'PlatoonCallForHelpAI'},
--        ExpansionExclude = {'Sea'},
--        RequiresConstruction = false,
--        PlatoonData = {
--            Construction = {
--                BuildClose = false,
--                BaseTemplate = ExBaseTmpl,
--                NearMarkerType = 'Rally Point',
--                BuildStructures = {
--                    'T4LandExperimental2', 
--                },
--                Location = 'MAIN',
--            }
--        }
--    },
--    {
--        BuilderName = 'T3 Air Exp1 Engineer 1',
--        TemplateName = 'T3EngineerBuilder',
--        Priority = 875,
--        InstanceCount = 1,
--        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH3}},
--            },
--        LocationType = 'MAIN',
--        PlatoonType = 'Any',
--        PlatoonAddPlans = {'PlatoonCallForHelpAI'},
--        ExpansionExclude = {'Sea'},
--        RequiresConstruction = false,
--        PlatoonData = {
--            Construction = {
--                BuildClose = false,
--                NearMarkerType = 'Protected Experimental Construction',
--                BuildStructures = {
--                    'T4AirExperimental1', 
--                },
--                Location = 'MAIN',
--            }
--        }
--    },
--    {
--        BuilderName = 'T3 Land Exp1 Engineer 2',
--        TemplateName = 'T3EngineerBuilderBig',
--        Priority = 900,
--        InstanceCount = 2,
--        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH3}},
--        },
--        LocationType = 'MAIN',
--        PlatoonType = 'Any',
--        PlatoonAddPlans = {'PlatoonCallForHelpAI'},
--        ExpansionExclude = {'Sea'},
--        RequiresConstruction = false,
--        PlatoonData = {
--            Construction = {
--                BuildClose = false,
--                BaseTemplate = ExBaseTmpl,
--                NearMarkerType = 'Rally Point',
--                BuildStructures = {
--                    'T4LandExperimental1', 
--                },
--                Location = 'MAIN',
--            }
--        }
--    },
--    {
--        BuilderName = 'T3 Land Exp2 Engineer 2',
--        TemplateName = 'T3EngineerBuilderBig',
--        Priority = 850,
--        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH3}},
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.LAND * categories.EXPERIMENTAL}},
--            },
--        LocationType = 'MAIN',
--        PlatoonType = 'Any',
--        PlatoonAddPlans = {'PlatoonCallForHelpAI'},
--        ExpansionExclude = {'Sea'},
--        RequiresConstruction = false,
--        PlatoonData = {
--            Construction = {
--                BuildClose = false,
--                BaseTemplate = ExBaseTmpl,
--                NearMarkerType = 'Rally Point',
--                BuildStructures = {
--                    'T4LandExperimental2', 
--                },
--                Location = 'MAIN',
--            }
--        }
--    },
--    {
--        BuilderName = 'T3 Air Exp1 Engineer 2',
--        TemplateName = 'T3EngineerBuilderBig',
--        Priority = 900,
--        InstanceCount = 3,
--        BuildConditions = {
--                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH3}},
--            },
--        LocationType = 'MAIN',
--        PlatoonType = 'Any',
--        PlatoonAddPlans = {'PlatoonCallForHelpAI'},
--        ExpansionExclude = {'Sea'},
--        RequiresConstruction = false,
--        PlatoonData = {
--            Construction = {
--                BuildClose = false,
--                NearMarkerType = 'Protected Experimental Construction',
--                BuildStructures = {
--                    'T4AirExperimental1', 
--                },
--                Location = 'MAIN',
--            }
--        }
--    },




    ----------------------------------------------------------------------------
    -------- ENGINEERS ASSISTING --------------------------
    ----------------------------------------------------------------------------
    {
        BuilderName = 'T1EngineerAssistAttack',
        --PlatoonTemplate = 'EngineerAssist',
        Priority = 900,
        InstanceCount = 1,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENGINEER * categories.TECH1}},
                { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, categories.MOBILE}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.25, 0.5}},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Assist = {
                AssistRange = 80,
                BeingBuiltCategories = { 'MOBILE' },
                Time = 60,
            },
        }
    },
    {
        BuilderName = 'T1EngineerAssistDefense',
        --PlatoonTemplate = 'EngineerAssist',
        Priority = 950,
        InstanceCount = 1,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENGINEER * categories.TECH1}},
                { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, categories.DEFENSE}},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Assist = {
                AssistRange = 80,
                BeingBuiltCategories = {'DEFENSE'}, 
                Time = 60,
            },
        }
    },
    {
        BuilderName = 'T2EngineerAssistAttack',
        --PlatoonTemplate = 'T2EngineerAssist',
        Priority = 900,
        InstanceCount = 1,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENGINEER * categories.TECH2}},
                { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, categories.MOBILE}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.25, 0.5}},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Assist = {
                AssistRange = 80,
                BuilderCategories = {'MOBILE'},
                Time = 60,
            },
        }
    },
    {
        BuilderName = 'T2EngineerAssistExperimental',
        --PlatoonTemplate = 'T3EngineerAssist',
        Priority = 850,
        InstanceCount = 1,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 10, categories.ENGINEER * categories.TECH2}},
                { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, categories.EXPERIMENTAL}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.25, 0.5}},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Assist = {
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL'},
                Time = 60,
            },
        }
    },
    {
        BuilderName = 'T3EngineerAssistAttack',
        --PlatoonTemplate = 'T3EngineerAssist',
        Priority = 850,
        InstanceCount = 1,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 10, categories.ENGINEER * categories.TECH3}},
                { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, categories.MOBILE}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.25, 0.5}},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Assist = {
                AssistRange = 80,
                BuilderCategories = {'MOBILE'},
                Time = 60,
            },
        }
    },
    {
        BuilderName = 'T3EngineerAssistArtillery',
        --PlatoonTemplate = 'T3EngineerAssist',
        Priority = 850,
        InstanceCount = 3,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 10, categories.ENGINEER * categories.TECH3}},
                { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, categories.ARTILLERY}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.25, 0.5}},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Assist = {
                AssistRange = 80,
                BeingBuiltCategories = {'ARTILLERY'},
                Time = 60,
            },
        }
    },
    {
        BuilderName = 'T3EngineerAssistExperimental',
        --PlatoonTemplate = 'T3EngineerAssist',
        Priority = 900,
        InstanceCount = 1,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 10, categories.ENGINEER * categories.TECH3}},
                { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, categories.EXPERIMENTAL}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.25, 0.5}},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Assist = {
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL'},
                Time = 60,
            },
        }
    },
    {
        BuilderName = 'T3EngineerAssistBuildNuke',
        --PlatoonTemplate = 'T3EngineerAssist',
        Priority = 850,
        InstanceCount = 3,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 10, categories.ENGINEER * categories.TECH3}},
                { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, categories.STRUCTURE * categories.NUKE}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.2, 0.5}},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Assist = {
                AssistRange = 80,
                BeingBuiltCategories = {'NUKE'},
                Time = 60,
            },
        }
    },
    {
        BuilderName = 'T3EngineerAssistNukeMissile',
        --PlatoonTemplate = 'T3EngineerAssist',
        Priority = 850,
        InstanceCount = 1,
        BuildConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 10, categories.ENGINEER * categories.TECH3}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.STRUCTURE * categories.NUKE}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.2, 0.5}},
            },
        PlatoonType = 'Any',
        RequiresConstruction = false,
        PlatoonData = {
            Assist = {
                AssistRange = 80,
                BuilderCategories = {'NUKE'},
                Time = 60,
            },
        }
    },
}