--***************************************************************************
--*
--**  File     :  /lua/ai/AIEconomyUpgradeBuilders.lua
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

---@alias BuilderGroupsEconomicUpgrade 'ExtractorUpgrades' | 'Time Exempt Extractor Upgrades Expansion' | 'Time Exempt Extractor Upgrades' | 'SpeedExtractorUpgrades' | 'T1BalancedUpgradeBuilders' | 'T2BalancedUpgradeBuilders' | 'T1BalancedUpgradeBuildersExpansion' | 'T2BalancedUpgradeBuildersExpansion' | 'T1SpeedUpgradeBuilders' | 'T2SpeedUpgradeBuilders' | 'T1SpeedUpgradeBuildersExpansions' | 'T2SpeedUpgradeBuildersExpansions' | 'T1SlowUpgradeBuilders' | 'T2SlowUpgradeBuilders' | 'T1NavalUpgradeBuilders' | 'T2NavalUpgradeBuilders'

BuilderGroup {
    BuilderGroupName = 'ExtractorUpgrades',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T1 Mass Extractor Upgrade',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 1,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconIncomeOverTime',  { 2.4, 20}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { MIBC, 'GreaterThanGameTime', { 480 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.MASSEXTRACTION } },
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },

        -- In case economy becomes locked under the normal income required
        -- look and see if there is enough mass stored to push through the upgrade
    Builder {
        BuilderName = 'T1 Mass Extractor Upgrade Time Limit Based',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 1,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'GreaterThanGameTime', { 540 } },
            { EBC, 'GreaterThanEconStorageCurrent', { 600, 0 } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.MASSEXTRACTION } },

        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },

    --Builder {
    --    BuilderName = 'T1 Mass Extractor Upgrade Time Limit Based',
    --    PlatoonTemplate = 'T1MassExtractorUpgrade',
    --    InstanceCount = 1,
    --    Priority = 200,
    --    BuilderConditions = {
    --        { IBC, 'BrainNotLowPowerMode', {} },
    --        { EBC, 'GreaterThanEconIncome',  { 5, 20}},
    --        { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
    --
    --    },
    --    FormRadius = 10000,
    --    BuilderType = 'Any',
    --},
    Builder {
        BuilderName = 'T2 Mass Extractor Upgrade',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        Priority = 200,
        BuilderConditions = {
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 ) } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.MASSEXTRACTION } },
            { EBC, 'GreaterThanEconIncomeOverTime', { 7, 50 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.MASSEXTRACTION }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'Time Exempt Extractor Upgrades Expansion',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T1 Mass Extractor Upgrade Timeless Single Expansion',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 2,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconIncomeOverTime',  { 3.5, 20}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.7, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 2, categories.MASSEXTRACTION } },
            { UCBC, 'UnitsGreaterAtLocation', { 'MAIN', 3, categories.MASSEXTRACTION } },
        },
        FormRadius = 160,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Mass Extractor Upgrade Timeless Single Expansion',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        InstanceCount = 2,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconIncomeOverTime',  { 13, 200}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.8, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 2, categories.MASSEXTRACTION } },
            { UCBC, 'UnitsGreaterAtLocation', { 'MAIN', 3, categories.MASSEXTRACTION * categories.TECH3 } },
        },
        FormRadius = 160,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Mass Extractor Upgrade Timeless Multiple Expansion',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        InstanceCount = 3,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconIncomeOverTime',  { 25, 200}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 1.0, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 3, categories.MASSEXTRACTION } },
            { UCBC, 'UnitsGreaterAtLocation', { 'MAIN', 3, categories.MASSEXTRACTION * categories.TECH3 } },
        },
        FormRadius = 160,
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'Time Exempt Extractor Upgrades',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T1 Mass Extractor Upgrade Timeless Single',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 1,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconIncomeOverTime',  { 2.0, 10}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.6, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.MASSEXTRACTION } },
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'T1 Mass Extractor Upgrade Timeless Two',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 2,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconIncomeOverTime',  { 4, 30}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.7, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 2, categories.MASSEXTRACTION } },
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'T1 Mass Extractor Upgrade Timeless LOTS',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 4,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconIncomeOverTime',  { 8, 10}},
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 4, categories.MASSEXTRACTION } },
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Mass Extractor Upgrade Timeless',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 ) } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.MASSEXTRACTION * categories.TECH3 } },
            { EBC, 'GreaterThanEconIncomeOverTime', { 6, 50 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.7, 1.2 }},
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.MASSEXTRACTION }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'T2 Mass Extractor Upgrade Timeless Multiple',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        Priority = 200,
        InstanceCount = 3,
        BuilderConditions = {
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 ) } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 3, categories.MASSEXTRACTION * categories.TECH3 } },
            { EBC, 'GreaterThanEconIncomeOverTime', { 13, 100 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'SpeedExtractorUpgrades',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T1 Mass Extractor Upgrade Speed',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 1,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconIncomeOverTime',  { 2.0, 20}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 2, categories.MASSEXTRACTION } },
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T1 Mass Extractor Upgrade 2 Speed',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 1,
        Priority = 200,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 ) }},
            { EBC, 'GreaterThanEconIncomeOverTime',  { 4.0, 35}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 2, categories.MASSEXTRACTION } },
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'T2 Mass Extractor Upgrade Speed',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        Priority = 200,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 ) } },
            { EBC, 'GreaterThanEconIncomeOverTime', { 6.0, 95 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 2, categories.MASSEXTRACTION * categories.TECH3 } },
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Mass Extractor Upgrade 2 Speed',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        Priority = 200,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.MASSEXTRACTION * categories.TECH3 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 ) } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 2, categories.MASSEXTRACTION * categories.TECH3 } },
            { EBC, 'GreaterThanEconIncomeOverTime', { 9.0, 120 } },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
}

-- ================================= --
--     BALANCED FACTORY UPGRADES
-- ================================= --
BuilderGroup {
    BuilderGroupName = 'T1BalancedUpgradeBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Balanced T1 Land Factory Upgrade Initial',
        PlatoonTemplate = 'T1LandFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncome',  { 2.4, 30}},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY * categories.LAND * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH1 * categories.LAND } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'BalancedT1AirFactoryUpgradeInitial',
        PlatoonTemplate = 'T1AirFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        FormDebugFunction = nil,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 2.8, 75}},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY * categories.AIR * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH1 * categories.AIR } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Balanced T1 Land Factory Upgrade',
        PlatoonTemplate = 'T1LandFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.1} },
                { IBC, 'BrainNotLowPowerMode', {} },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH1 * categories.LAND } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'BalancedT1AirFactoryUpgrade',
        PlatoonTemplate = 'T1AirFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 3.5, 75}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 1.0, 1.2} },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH1 * categories.AIR } },
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY * categories.AIR }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 7, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}}, --DUNCAN - Increased to 7
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Balanced T1 Sea Factory Upgrade',
        PlatoonTemplate = 'T1SeaFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 4.5, 80}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 1.0, 1.2} },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH1 * categories.LAND } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.NAVAL } },
            },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'T2BalancedUpgradeBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Balanced T2 Land Factory Upgrade',
        PlatoonTemplate = 'T2LandFactoryUpgrade',
        Priority = 300,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 6.0, 180}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH2 } },
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 2, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) } },
                { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 7, categories.MOBILE * categories.LAND }},
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Balanced T2 Air Factory Upgrade',
        PlatoonTemplate = 'T2AirFactoryUpgrade',
        Priority = 300,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 7.0, 180}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.5, 1.2 }},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH2 } },
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 2, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.MASSEXTRACTION * categories.TECH3} },
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Balanced T2 Sea Factory Upgrade',
        PlatoonTemplate = 'T2SeaFactoryUpgrade',
        Priority = 300,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 11.0, 300}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 2, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) } },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH2 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.MASSEXTRACTION * categories.TECH3} },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * categories.TECH3} },
            },
        BuilderType = 'Any',
    },
}

-- ============================================ --
--     BALANCED FACTORY UPGRADES EXPANSIONS
-- ============================================ --
BuilderGroup {
    BuilderGroupName = 'T1BalancedUpgradeBuildersExpansion',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Balanced T1 Land Factory Upgrade Expansion',
        PlatoonTemplate = 'T1LandFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconIncomeOverTime',  { 6.0, 75}},
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.85, 1.4} },
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY * categories.LAND }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.FACTORY * (categories.TECH2 + categories.TECH3)}},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH1 } },
                
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'BalancedT1AirFactoryUpgrade Expansion',
        PlatoonTemplate = 'T1AirFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 5.5, 75}},
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.85, 1.4} },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH1 } },
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY * categories.AIR }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.FACTORY * categories.TECH2}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.FACTORY * categories.TECH2}},
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Balanced T1 Sea Factory Upgrade Expansion',
        PlatoonTemplate = 'T1SeaFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 6.5, 80}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.85, 1.4} },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH1 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.NAVAL } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.FACTORY * categories.TECH2}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.FACTORY * categories.TECH2}},
            },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'T2BalancedUpgradeBuildersExpansion',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Balanced T2 Land Factory Upgrade Expansion',
        PlatoonTemplate = 'T2LandFactoryUpgrade',
        Priority = 300,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 11.0, 180}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.3} },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.FACTORY * categories.TECH3}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.MASSEXTRACTION * categories.TECH3}},
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.TECH2 * categories.LAND }},
                { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 7, categories.MOBILE * categories.LAND}},
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Balanced T2 Air Factory Upgrade Expansion',
        PlatoonTemplate = 'T2AirFactoryUpgrade',
        Priority = 300,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 11.0, 180}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.3} },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH2 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.FACTORY * categories.TECH3}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.MASSEXTRACTION * categories.TECH3}},
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.TECH2 * categories.AIR }},
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Balanced T2 Sea Factory Upgrade Expansion',
        PlatoonTemplate = 'T2SeaFactoryUpgrade',
        Priority = 300,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 11.0, 300}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.3} },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH2 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.FACTORY * categories.TECH3}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.MASSEXTRACTION * categories.TECH3}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * categories.TECH3}},
            },
        BuilderType = 'Any',
    },
}

-- ====================== --
--     SPEED UPGRADES     --
-- ====================== --
BuilderGroup {
    BuilderGroupName = 'T1SpeedUpgradeBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T1 Land Factory Upgrade Speed',
        PlatoonTemplate = 'T1LandFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY } },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH1 * categories.LAND } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T1AirFactoryUpgrade Speed',
        PlatoonTemplate = 'T1AirFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        FormDebugFunction = nil,
        BuilderConditions = {
            { EBC, 'GreaterThanEconIncomeOverTime',  { 3.0, 50}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH1 * categories.AIR } },
            { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T1 Sea Factory Upgrade Speed',
        PlatoonTemplate = 'T1SeaFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 4.5, 50}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.TECH1 * categories.NAVAL }},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH1 * categories.NAVAL } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            },
        BuilderType = 'Any',
    },
 }

BuilderGroup {
    BuilderGroupName = 'T2SpeedUpgradeBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T2 Land Factory Upgrade Speed',
        PlatoonTemplate = 'T2LandFactoryUpgrade',
        Priority = 300,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 6.0, 120}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH2 * categories.LAND } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * categories.TECH3}},
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY } },
                { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH2 } },
                { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Air Factory Upgrade Speed',
        PlatoonTemplate = 'T2AirFactoryUpgrade',
        Priority = 300,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 6.0, 120}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH2 * categories.AIR } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * categories.TECH3}},
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY } },
                { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH2 } },
                { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Sea Factory Upgrade Speed',
        PlatoonTemplate = 'T2SeaFactoryUpgrade',
        Priority = 300,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 7.0, 150}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH2 * categories.NAVAL } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * categories.TECH3}},
                { EBC, 'MassToFactoryRatioBaseCheck', { 'LocationType' } },
            },
        BuilderType = 'Any',
    },
}


-- ================================= --
--     SPEED UPGRADES EXPANSIONS     --
-- ================================= --
BuilderGroup {
    BuilderGroupName = 'T1SpeedUpgradeBuildersExpansions',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T1 Land Factory Upgrade Speed Expansions',
        PlatoonTemplate = 'T1LandFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY } },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.FACTORY * categories.TECH3}},
                --{ EBC, 'GreaterThanEconIncome',  { 3.5, 50}},
                { IBC, 'BrainNotLowPowerMode', {} },
                --{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T1AirFactoryUpgrade Speed Expansions',
        PlatoonTemplate = 'T1AirFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 3.0, 50}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.FACTORY * categories.TECH3}},
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T1 Sea Factory Upgrade Speed Expansions',
        PlatoonTemplate = 'T1SeaFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 4.5, 50}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.TECH1 * categories.NAVAL }},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.FACTORY * ( categories.TECH2 + categories.TECH3 )}},
            },
        BuilderType = 'Any',
    },
 }

BuilderGroup {
    BuilderGroupName = 'T2SpeedUpgradeBuildersExpansions',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T2 Land Factory Upgrade Speed Expansions',
        PlatoonTemplate = 'T2LandFactoryUpgrade',
        Priority = 300,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 6.0, 120}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH2 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * categories.TECH3}},
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.FACTORY * categories.TECH3}},
                { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH2 } },
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Air Factory Upgrade Speed Expansions',
        PlatoonTemplate = 'T2AirFactoryUpgrade',
        Priority = 300,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 6.0, 120}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH2 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * categories.TECH3}},
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.FACTORY * categories.TECH3}},
                { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH2 } },
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Sea Factory Upgrade Speed Expansions',
        PlatoonTemplate = 'T2SeaFactoryUpgrade',
        Priority = 300,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 7.0, 150}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH2 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * categories.TECH3}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.FACTORY * categories.TECH3}},
            },
        BuilderType = 'Any',
    },
}


-- ===================== --
--     SLOW UPGRADES     --
-- ===================== --
BuilderGroup {
    BuilderGroupName = 'T1SlowUpgradeBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T1 Land Factory Upgrade Slow',
        PlatoonTemplate = 'T1LandFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
            { EBC, 'GreaterThanEconIncomeOverTime',  { 5.0, 50}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.FACTORY * categories.TECH2 } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T1AirFactoryUpgrade Slow',
        PlatoonTemplate = 'T1AirFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
            { EBC, 'GreaterThanEconIncomeOverTime',  { 5.0, 40}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.FACTORY * categories.TECH2 } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T1 Sea Factory Upgrade Slow',
        PlatoonTemplate = 'T1SeaFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
            { EBC, 'GreaterThanEconIncomeOverTime',  { 6, 10}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.TECH1 * categories.NAVAL }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.FACTORY * categories.TECH2 } },
        },
        BuilderType = 'Any',
    },
 }

BuilderGroup {
    BuilderGroupName = 'T2SlowUpgradeBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T2 Land Factory Upgrade Slow',
        PlatoonTemplate = 'T2LandFactoryUpgrade',
        Priority = 300,
        BuilderConditions = {
            { EBC, 'GreaterThanEconIncomeOverTime',  { 9, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * categories.TECH3}},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY } },
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH2 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.FACTORY * categories.TECH3 } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Air Factory Upgrade Slow',
        PlatoonTemplate = 'T2AirFactoryUpgrade',
        Priority = 300,
        BuilderConditions = {
            { EBC, 'GreaterThanEconIncomeOverTime',  { 9, 100}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * categories.TECH3}},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY } },
            { UCBC, 'EngineerGreaterAtLocation', { 'LocationType', 3, categories.ENGINEER * categories.TECH2 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.FACTORY * categories.TECH3 } },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Sea Factory Upgrade Slow',
        PlatoonTemplate = 'T2SeaFactoryUpgrade',
        Priority = 300,
        BuilderConditions = {
            { EBC, 'GreaterThanEconIncomeOverTime',  { 12, 150}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * categories.TECH3}},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.FACTORY * categories.TECH3 } },
        },
        BuilderType = 'Any',
    },
}

-- ================================= --
--     NAVAL FACTORY UPGRADES
-- ================================= --
BuilderGroup {
    BuilderGroupName = 'T1NavalUpgradeBuilders',
    BuildersType = 'PlatoonFormBuilder',

    -- ================================= --
    --     INITIAL FACTORY UPGRADES
    -- ================================= --
    Builder {
        BuilderName = 'Naval T1 Land Factory Upgrade Initial',
        PlatoonTemplate = 'T1LandFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 5, 75}},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY * categories.LAND * ( categories.TECH2 + categories.TECH3 ) } },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.LAND * categories.TECH1 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.FACTORY * categories.NAVAL * ( categories.TECH2 + categories.TECH3 )}},
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Naval T1 Air Factory Upgrade Initial',
        PlatoonTemplate = 'T1AirFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 5, 75}},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY * categories.AIR * ( categories.TECH2 + categories.TECH3 ) }},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH1 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.FACTORY * categories.NAVAL * ( categories.TECH2 + categories.TECH3 )}},
            },
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'Naval T1 Naval Factory Upgrade Initial',
        PlatoonTemplate = 'T1SeaFactoryUpgrade',
        Priority = 210,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 5, 75}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.MOBILE * categories.NAVAL}},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY * categories.NAVAL * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.NAVAL * ( categories.TECH2 + categories.TECH3 ) } },
            },
        BuilderType = 'Any',
    },
    -- ================================= --
    --     FACTORY UPGRADES AFTER INITIAL
    -- ================================= --
    Builder {
        BuilderName = 'Naval T1 Land Factory Upgrade',
        PlatoonTemplate = 'T1LandFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 10, 75}},
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.85, 1.4} },
                { IBC, 'BrainNotLowPowerMode', {} },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.LAND * categories.TECH1 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.FACTORY * categories.NAVAL * ( categories.TECH2 + categories.TECH3 )}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Naval T1 AirFactory Upgrade',
        PlatoonTemplate = 'T1AirFactoryUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 10, 75}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.85, 1.4} },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.AIR * categories.TECH1 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.FACTORY * categories.NAVAL * ( categories.TECH2 + categories.TECH3 )}},
                --{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, 'FACTORY AIR' }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Naval T1 Sea Factory Upgrade',
        PlatoonTemplate = 'T1SeaFactoryUpgrade',
        Priority = 210,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 8, 75}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.85, 1.4} },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.CRUISER + categories.DESTROYER + categories.BATTLESHIP}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.MOBILE * categories.NAVAL}},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.NAVAL * categories.TECH1 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.MASSEXTRACTION * ( categories.TECH2 + categories.TECH3 )}},
                --{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, 'NAVAL' } },
            },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'T2NavalUpgradeBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Naval T2 Land Factory Upgrade',
        PlatoonTemplate = 'T2LandFactoryUpgrade',
        Priority = 300,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 10, 0}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.LAND * categories.TECH2 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * categories.TECH3}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.FACTORY * categories.TECH3 * categories.NAVAL}},
                { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 7, categories.MOBILE * categories.LAND}},
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 2, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) } },

            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Naval T2 Air Factory Upgrade',
        PlatoonTemplate = 'T2AirFactoryUpgrade',
        Priority = 300,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 15, 0}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 3, categories.FACTORY * categories.TECH2 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * categories.TECH3} },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.FACTORY * categories.TECH3 * categories.NAVAL }},
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 2, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) } },
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Naval T2 Sea Factory Upgrade - initial',
        PlatoonTemplate = 'T2SeaFactoryUpgrade',
        Priority = 305,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 20, 0}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY * categories.NAVAL * categories.TECH3 }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.MOBILE * categories.NAVAL * categories.TECH2 }},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH2 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * categories.TECH3} },
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 2, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) } },
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Naval T2 Sea Factory Upgrade',
        PlatoonTemplate = 'T2SeaFactoryUpgrade',
        Priority = 305,
        InstanceCount = 1,
        BuilderConditions = {
                { EBC, 'GreaterThanEconIncomeOverTime',  { 20, 0}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconEfficiencyCombined', { 0.9, 1.2 }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.BATTLESHIP}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MOBILE * categories.NAVAL * categories.TECH2 }},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgraded', { 1, categories.FACTORY * categories.TECH2 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * categories.TECH3} },
                { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 2, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) } },
            },
        BuilderType = 'Any',
    },
}

