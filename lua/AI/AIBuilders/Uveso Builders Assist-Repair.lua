local IBC = '/lua/editor/InstantBuildConditions.lua'
local EBC = '/lua/editor/EconomyBuildConditions.lua'
local MIBC = '/lua/editor/MiscBuildConditions.lua'
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local UBC = '/lua/editor/UvesoBuildConditions.lua'



-- ===================================================-======================================================== --
-- ==                                             Assistees                                                  == --
-- ===================================================-======================================================== --
BuilderGroup {
    BuilderGroupName = 'Assistees Uveso',
    BuildersType = 'EngineerBuilder',
    -- =============== --
    --    Factories    --
    -- =============== --
    Builder {
        BuilderName = 'U1 Assist 1st T2 Factory Upgrade',
        PlatoonTemplate = 'EngineerAssist',
        Priority = 890,
        InstanceCount = 20,
        BuilderConditions = {
            { UBC, 'HaveGreaterThanUnitsInCategoryBeingBuiltAtLocation', { 'LocationType', 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH2 , categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH1 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.STRUCTURE * categories.FACTORY * categories.LAND * ( categories.TECH2 + categories.TECH3 ) } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Structure',
                AssistRange = 50,
                BeingBuiltCategories = {'STRUCTURE LAND FACTORY TECH2'},
                PermanentAssist = false,
                Time = 10,
            },
        }
    },
    Builder {
        BuilderName = 'U1 Assist 1st T3 Factory Upgrade',
        PlatoonTemplate = 'EngineerAssist',
        Priority = 890,
        InstanceCount = 20,
        BuilderConditions = {
            { UBC, 'HaveGreaterThanUnitsInCategoryBeingBuiltAtLocation', { 'LocationType', 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 , categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH2 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Structure',
                AssistRange = 50,
                BeingBuiltCategories = {'STRUCTURE LAND FACTORY TECH3'},
                PermanentAssist = false,
                Time = 10,
            },
        }
    },
    Builder {
        BuilderName = 'U2 Assist 1st T3 Factory Upgrade',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 890,
        InstanceCount = 20,
        BuilderConditions = {
            { UBC, 'HaveGreaterThanUnitsInCategoryBeingBuiltAtLocation', { 'LocationType', 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 , categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH2 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH2' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Structure',
                AssistRange = 50,
                BeingBuiltCategories = {'STRUCTURE LAND FACTORY TECH3'},
                PermanentAssist = false,
                Time = 10,
            },
        }
    },
    -- ============ --
    --    ENERGY    --
    -- ============ --
    Builder {
        BuilderName = 'U1 Assist Energy Turbo',
        PlatoonTemplate = 'EngineerAssist',
        Priority = 870,
        InstanceCount = 10,
        DelayEqualBuildPlattons = {'Assist Energy', 5},
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveGreaterThanUnitsInCategoryBeingBuiltAtLocation', { 'LocationType', 0, categories.STRUCTURE * categories.ENERGYPRODUCTION * (categories.TECH2 + categories.TECH3) , categories.CONSTRUCTION * categories.MOBILE }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH1' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'Assist Energy' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Structure',
                AssistRange = 30,
                BeingBuiltCategories = {'STRUCTURE ENERGYPRODUCTION TECH2', 'STRUCTURE ENERGYPRODUCTION TECH3'},
                PermanentAssist = false,
                Time = 30,
            },
        }
    },
    Builder {
        BuilderName = 'U2 Assist Energy Turbo',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 870,
        DelayEqualBuildPlattons = {'Assist Energy', 5},
        InstanceCount = 10,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveGreaterThanUnitsInCategoryBeingBuiltAtLocation', { 'LocationType', 0, categories.STRUCTURE * categories.ENERGYPRODUCTION * (categories.TECH2 + categories.TECH3) , categories.CONSTRUCTION * categories.MOBILE }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH2' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'Assist Energy' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Structure',
                AssistRange = 30,
                BeingBuiltCategories = {'STRUCTURE ENERGYPRODUCTION TECH2', 'STRUCTURE ENERGYPRODUCTION TECH3'},
                PermanentAssist = false,
                Time = 30,
            },
        }
    },
    Builder {
        BuilderName = 'U3 Assist Energy Turbo',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 870,
        DelayEqualBuildPlattons = {'Assist Energy', 5},
        InstanceCount = 10,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveGreaterThanUnitsInCategoryBeingBuiltAtLocation', { 'LocationType', 0, categories.STRUCTURE * categories.ENERGYPRODUCTION * (categories.TECH2 + categories.TECH3) , categories.CONSTRUCTION * categories.MOBILE }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH3' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'Assist Energy' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Structure',
                AssistRange = 30,
                BeingBuiltCategories = {'STRUCTURE ENERGYPRODUCTION TECH2', 'STRUCTURE ENERGYPRODUCTION TECH3'},
                PermanentAssist = false,
                Time = 30,
            },
        }
    },
    -- =================== --
    --    Experimentals    --
    -- =================== --
    Builder {
        BuilderName = 'U1 Assist Experimental',
        PlatoonTemplate = 'EngineerAssist',
        Priority = 810,
        DelayEqualBuildPlattons = {'Assist Experimental', 15},
        InstanceCount = 20,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveGreaterThanUnitsInCategoryBeingBuiltAtLocation', { 'LocationType', 0, categories.MOBILE * categories.EXPERIMENTAL, categories.CONSTRUCTION * categories.MOBILE }},
            -- Do we need additional conditions to build it ?
            --{ UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.10, 0.75 }}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'Assist Experimental' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL MOBILE'},
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'U-T2 Assist Experimental',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 810,
        DelayEqualBuildPlattons = {'Assist Experimental', 5},
        InstanceCount = 20,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveGreaterThanUnitsInCategoryBeingBuiltAtLocation', { 'LocationType', 0, categories.MOBILE * categories.EXPERIMENTAL, categories.CONSTRUCTION * categories.MOBILE }},
            -- Do we need additional conditions to build it ?
            --{ UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH2' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.10, 0.75 }}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'Assist Experimental' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL MOBILE'},
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'U-T3 Assist Experimental',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 1000,
        DelayEqualBuildPlattons = {'Assist Experimental', 5},
        InstanceCount = 10,
        BuilderConditions = {
            -- When do we want to build this ?
            { UBC, 'HaveGreaterThanUnitsInCategoryBeingBuiltAtLocation', { 'LocationType', 0, categories.MOBILE * categories.EXPERIMENTAL, categories.CONSTRUCTION * categories.MOBILE }},
            -- Do we need additional conditions to build it ?
            --{ UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH3' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.10, 0.75 }}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'Assist Experimental' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL MOBILE'},
                Time = 60,
            },
        }
    },
    -- ============ --
    --    Paragon   --
    -- ============ --
    Builder {
        BuilderName = 'U1 Assist PARA',
        PlatoonTemplate = 'EngineerAssist',
        Priority = 810,
        DelayEqualBuildPlattons = {'AssistParagon', 15},
        InstanceCount = 10,
        BuilderConditions = {
            -- When do we want to build this ?
            { EBC, 'GreaterThanEconStorageRatio', { 0.75, 0.75 }}, -- Ratio from 0 to 1. (1=100%)
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, categories.STRUCTURE * categories.ECONOMIC * categories.EXPERIMENTAL }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 7.0, 200.0 } }, -- relative income
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'AssistParagon' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL ECONOMIC'},
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'U2 Assist PARA',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 810,
        DelayEqualBuildPlattons = {'AssistParagon', 15},
        InstanceCount = 10,
        BuilderConditions = {
            -- When do we want to build this ?
            { EBC, 'GreaterThanEconStorageRatio', { 0.75, 0.75 }}, -- Ratio from 0 to 1. (1=100%)
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, categories.STRUCTURE * categories.ECONOMIC * categories.EXPERIMENTAL }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 7.0, 200.0 } }, -- relative income
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'AssistParagon' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL ECONOMIC'},
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'U3 Assist PARA',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 810,
        DelayEqualBuildPlattons = {'AssistParagon', 15},
        InstanceCount = 5,
        BuilderConditions = {
            -- When do we want to build this ?
            { EBC, 'GreaterThanEconStorageRatio', { 0.99, 0.99 }}, -- Ratio from 0 to 1. (1=100%)
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, categories.STRUCTURE * categories.ECONOMIC * categories.EXPERIMENTAL }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 7.0, 200.0 } }, -- relative income
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'AssistParagon' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL ECONOMIC'},
                Time = 60,
            },
        }
    },
    -- ================== --
    --    PARAGON Turbo   --
    -- ================== --
    Builder {
        BuilderName = 'U1 Assist PARA Turbo',
        PlatoonTemplate = 'EngineerAssist',
        Priority = 900,
        InstanceCount = 10,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.ECONOMIC * categories.EXPERIMENTAL }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, categories.STRUCTURE * categories.ECONOMIC * categories.EXPERIMENTAL }},
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL ECONOMIC'},
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'U2 Assist PARA Turbo',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 900,
        InstanceCount = 10,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.ECONOMIC * categories.EXPERIMENTAL }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, categories.STRUCTURE * categories.ECONOMIC * categories.EXPERIMENTAL }},
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL ECONOMIC'},
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'U3 Assist PARA Turbo',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 900,
        InstanceCount = 10,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.ECONOMIC * categories.EXPERIMENTAL }},
            -- Do we need additional conditions to build it ?
            { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, categories.STRUCTURE * categories.ECONOMIC * categories.EXPERIMENTAL }},
            -- Have we the eco to build it ?
            -- Don't build it if...
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Engineer',
                AssistRange = 80,
                BeingBuiltCategories = {'EXPERIMENTAL ECONOMIC'},
                Time = 60,
            },
        }
    },
-- ============================= --
-- ==    Assistees General    == --
-- ============================= --
    Builder {
        BuilderName = 'U1 Assist Econ',
        PlatoonTemplate = 'EngineerAssist',
        Priority = 800,
        DelayEqualBuildPlattons = {'Assist General', 15},
        InstanceCount = 10,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, categories.STRUCTURE } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH1' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 1.0, 10.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.90, 0.90}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'Assist General' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Structure',
                AssistRange = 50,
                BeingBuiltCategories = {'STRUCTURE'},
                PermanentAssist = false,
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'U2 Assist Econ',
        PlatoonTemplate = 'T2EngineerAssist',
        Priority = 800,
        DelayEqualBuildPlattons = {'Assist General', 15},
        InstanceCount = 10,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, categories.STRUCTURE } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH2' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 1.0, 10.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.90, 0.90}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'Assist General' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Structure',
                AssistRange = 50,
                BeingBuiltCategories = {'STRUCTURE'},
                PermanentAssist = false,
                Time = 60,
            },
        }
    },
    Builder {
        BuilderName = 'U3 Assist Econ',
        PlatoonTemplate = 'T3EngineerAssist',
        Priority = 800,
        DelayEqualBuildPlattons = {'Assist General', 15},
        InstanceCount = 10,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, categories.STRUCTURE } },
            -- Do we need additional conditions to build it ?
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH2' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 1.0, 10.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.90, 0.90}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
            { UBC, 'CheckBuildPlattonDelay', { 'Assist General' }},
        },
        BuilderType = 'Any',
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                AssisteeType = 'Structure',
                AssistRange = 80,
                BeingBuiltCategories = {'STRUCTURE'},
                PermanentAssist = false,
                Time = 60,
            },
        }
    },
    -- =============== --
    --    Finisher     --
    -- =============== --
    Builder {
        BuilderName = 'U1 econ Finisher',
        PlatoonTemplate = 'EngineerBuilder',
        PlatoonAIPlan = 'ManagerEngineerFindUnfinished',
        Priority = 990,
        InstanceCount = 2,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'UnfinishedUnits', { 'LocationType', categories.STRUCTURE}},
            -- Do we need additional conditions to build it ?
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH1' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.90, 0.90}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
        },
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                BeingBuiltCategories = {'STRUCTURE'},
            },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U2 econ Finisher',
        PlatoonTemplate = 'T2EngineerBuilder',
        PlatoonAIPlan = 'ManagerEngineerFindUnfinished',
        Priority = 990,
        InstanceCount = 2,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'UnfinishedUnits', { 'LocationType', categories.STRUCTURE}},
            -- Do we need additional conditions to build it ?
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH2' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.90, 0.90}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
        },
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                BeingBuiltCategories = {'STRUCTURE'},
            },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U3 econ Finisher',
        PlatoonTemplate = 'T3EngineerBuilder',
        PlatoonAIPlan = 'ManagerEngineerFindUnfinished',
        Priority = 990,
        InstanceCount = 2,
        BuilderConditions = {
            -- When do we want to build this ?
            { UCBC, 'UnfinishedUnits', { 'LocationType', categories.STRUCTURE}},
            -- Do we need additional conditions to build it ?
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH3' }},
            -- Have we the eco to build it ?
            { EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } }, -- relative income
            { EBC, 'GreaterThanEconStorageRatio', { 0.90, 0.90}}, -- Ratio from 0 to 1. (1=100%)
            -- Don't build it if...
        },
        BuilderData = {
            Assist = {
                AssistLocation = 'LocationType',
                BeingBuiltCategories = {'STRUCTURE'},
            },
        },
        BuilderType = 'Any',
    },
    -- =============== --
    --    Repair     --
    -- =============== --
    Builder {
        BuilderName = 'U1 Engineer Repair',
        PlatoonTemplate = 'EngineerBuilder',
        PlatoonAIPlan = 'RepairAI',
        Priority = 1000,
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'DamagedStructuresInArea', { 'LocationType', }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH1' }},
        },
        BuilderData = {
            LocationType = 'LocationType',
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U2 Engineer Repair',
        PlatoonTemplate = 'T2EngineerBuilder',
        PlatoonAIPlan = 'RepairAI',
        Priority = 1000,
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'DamagedStructuresInArea', { 'LocationType', }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH2' }},
        },
        BuilderData = {
            LocationType = 'LocationType',
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U3 Engineer Repair',
        PlatoonTemplate = 'T3EngineerBuilder',
        PlatoonAIPlan = 'RepairAI',
        Priority = 1000,
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'DamagedStructuresInArea', { 'LocationType', }},
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 0, 'ENGINEER TECH3' }},
        },
        BuilderData = {
            LocationType = 'LocationType',
        },
        BuilderType = 'Any',
    },
    -- ============== --
    --    Reclaim     --
    -- ============== --
    Builder {
        BuilderName = 'U1 Reclaim Auto MAIN',
        PlatoonTemplate = 'EngineerBuilder',
        PlatoonAIPlan = 'ReclaimAIUveso',
        Priority = 700,
        InstanceCount = 10,
        BuilderConditions = {
            { EBC, 'LessThanEconStorageRatio', { 0.80, 1.01}}, -- Ratio from 0 to 1. (1=100%)
            { UBC, 'BuildOnlyOnLocation', { 'LocationType', 'MAIN' } },
            { UBC, 'EngineerManagerUnitsAtLocation', { 'MAIN', '>', 10,  'ENGINEER TECH1' } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH1' }},
        },
        BuilderData = {
            LocationType = 'LocationType',
            ReclaimTime = 30,
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'U1 Reclaim Auto Expansion',
        PlatoonTemplate = 'EngineerBuilder',
        PlatoonAIPlan = 'ReclaimAIUveso',
        Priority = 700,
        InstanceCount = 10,
        BuilderConditions = {
            { EBC, 'LessThanEconStorageRatio', { 0.80, 1.01}}, -- Ratio from 0 to 1. (1=100%)
            { UBC, 'BuildNotOnLocation', { 'LocationType', 'MAIN' } },
            { UBC, 'EngineerManagerUnitsAtLocation', { 'MAIN', '>', 1,  'ENGINEER TECH1' } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, 'ENGINEER TECH1' }},
        },
        BuilderData = {
            LocationType = 'LocationType',
            ReclaimTime = 30,
        },
        BuilderType = 'Any',
    },
}

