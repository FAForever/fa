#***************************************************************************
#*
#**  File     :  /lua/ai/SorianEconomyUpgradeBuilders.lua
#**
#**  Summary  : Default economic builders for skirmish
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
local TBC = '/lua/editor/ThreatBuildConditions.lua'
local PlatoonFile = '/lua/platoon.lua'
local SIBC = '/lua/editor/SorianInstantBuildConditions.lua'
local SBC = '/lua/editor/SorianBuildConditions.lua'

BuilderGroup {
    BuilderGroupName = 'SorianTime Exempt Extractor Upgrades Expansion',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Sorian T1 Mass Extractor Upgrade Timeless Single Expansion',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 2,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconIncome',  { 3.5, 10}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.65, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, 'MASSEXTRACTION TECH2', 'MASSEXTRACTION' } },
            { UCBC, 'UnitsGreaterAtLocation', { 'MAIN', 3, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3', 'MASSEXTRACTION' } },
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T2 Mass Extractor Upgrade Timeless Single Expansion',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        InstanceCount = 2,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconIncome',  { 20, 10}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.65, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, 'MASSEXTRACTION TECH3', 'MASSEXTRACTION' } },
            { UCBC, 'UnitsGreaterAtLocation', { 'MAIN', 3, 'MASSEXTRACTION TECH3', 'MASSEXTRACTION' } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T2 Mass Extractor Upgrade Timeless Multiple Expansion',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        InstanceCount = 4,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconIncome',  { 35, 10}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.65, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 4, 'MASSEXTRACTION TECH3', 'MASSEXTRACTION' } },
            { UCBC, 'UnitsGreaterAtLocation', { 'MAIN', 3, 'MASSEXTRACTION TECH3', 'MASSEXTRACTION' } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianTime Exempt Extractor Upgrades',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T1 Mass Extractor Upgrade Storage Based',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 1,
        Priority = 0, #200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconStorageCurrent', { 600, 0 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0, 1.2 }},
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION' }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'MASSEXTRACTION TECH2', 'MASSEXTRACTION' } },

        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T1 Mass Extractor Upgrade Bleed Off',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 1,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 1.0, 0 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0, 1.2 }},
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION' }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'MASSEXTRACTION TECH2', 'MASSEXTRACTION' } },

        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T1 Mass Extractor Upgrade Timeless Single',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 1,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconIncome',  { 2.2, 10}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.65, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'MASSEXTRACTION TECH2', 'MASSEXTRACTION' } },
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'Sorian T1 Mass Extractor Upgrade Timeless Two',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 2,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconIncome',  { 6, 10}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.65, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, 'MASSEXTRACTION TECH2', 'MASSEXTRACTION' } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'Sorian T1 Mass Extractor Upgrade Timeless LOTS',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 4,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconIncome',  { 15, 10}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.65, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 4, 'MASSEXTRACTION TECH2', 'MASSEXTRACTION' } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 2, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Mass Extractor Upgrade Storage Based',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        InstanceCount = 1,
        Priority = 0, #200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconStorageCurrent', { 3000, 0 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0, 1.2 }},
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'MASSEXTRACTION TECH3', 'MASSEXTRACTION' } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Mass Extractor Upgrade Bleed Off',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        InstanceCount = 1,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 1.0, 0 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0, 1.2 }},
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'MASSEXTRACTION TECH3', 'MASSEXTRACTION' } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T2 Mass Extractor Upgrade Timeless',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'MASSEXTRACTION TECH3', 'MASSEXTRACTION' } },
            { SIBC, 'GreaterThanEconIncome', { 13, 50 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.90, 1.2 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'Sorian T2 Mass Extractor Upgrade Timeless Multiple',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        Priority = 200,
        InstanceCount = 3,
        BuilderConditions = {
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, 'MASSEXTRACTION TECH3', 'MASSEXTRACTION' } },
            { SIBC, 'GreaterThanEconIncome',  { 20, 50 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.90, 1.2 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3' }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 2, 'MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T2 Mass Extractor Upgrade Timeless - Later',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'MASSEXTRACTION TECH3', 'MASSEXTRACTION' } },
            { SIBC, 'GreaterThanEconIncome', { 13, 50 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.65, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T2 Mass Extractor Upgrade Timeless Multiple - Later',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        Priority = 200,
        InstanceCount = 3,
        BuilderConditions = {
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, 'MASSEXTRACTION TECH3', 'MASSEXTRACTION' } },
            { SIBC, 'GreaterThanEconIncome',  { 20, 50 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.65, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianTime Exempt Extractor Upgrades - Rush',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'T1 Mass Extractor Upgrade Storage Based - Rush',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 1,
        Priority = 0, #200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconStorageCurrent', { 600, 0 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0, 1.2 }},
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION' }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'MASSEXTRACTION TECH2', 'MASSEXTRACTION' } },

        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T1 Mass Extractor Upgrade Bleed Off - Rush',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 1,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 1.0, 0 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0, 1.2 }},
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION' }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'MASSEXTRACTION TECH2', 'MASSEXTRACTION' } },

        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T1 Mass Extractor Upgrade Timeless Single - Rush',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 1,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconIncome',  { 2.2, 10}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.65, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'MASSEXTRACTION TECH2', 'MASSEXTRACTION' } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'FACTORY TECH2' }},
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'Sorian T1 Mass Extractor Upgrade Timeless Two - Rush',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 2,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconIncome',  { 6, 10}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.65, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, 'MASSEXTRACTION TECH2', 'MASSEXTRACTION' } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'FACTORY TECH2' }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'Sorian T1 Mass Extractor Upgrade Timeless LOTS - Rush',
        PlatoonTemplate = 'T1MassExtractorUpgrade',
        InstanceCount = 4,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconIncome',  { 15, 10}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.65, 1.2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 4, 'MASSEXTRACTION TECH2', 'MASSEXTRACTION' } },
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'FACTORY TECH2' }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 2, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Mass Extractor Upgrade Storage Based - Rush',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        InstanceCount = 1,
        Priority = 0, #200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconStorageCurrent', { 3000, 0 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0, 1.2 }},
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'MASSEXTRACTION TECH3', 'MASSEXTRACTION' } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'T2 Mass Extractor Upgrade Bleed Off - Rush',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        InstanceCount = 1,
        Priority = 200,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconStorageRatio', { 1.0, 0 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0, 1.2 }},
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'MASSEXTRACTION TECH3', 'MASSEXTRACTION' } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T2 Mass Extractor Upgrade Timeless - Rush',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'MASSEXTRACTION TECH3', 'MASSEXTRACTION' } },
            { SIBC, 'GreaterThanEconIncome', { 13, 50 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.90, 1.2 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'Sorian T2 Mass Extractor Upgrade Timeless Multiple - Rush',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        Priority = 200,
        InstanceCount = 3,
        BuilderConditions = {
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, 'MASSEXTRACTION TECH3', 'MASSEXTRACTION' } },
            { SIBC, 'GreaterThanEconIncome',  { 20, 50 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.90, 1.2 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, 'MASSEXTRACTION TECH2, MASSEXTRACTION TECH3' }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 2, 'MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T2 Mass Extractor Upgrade Timeless - Later - Rush',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        Priority = 200,
        InstanceCount = 1,
        BuilderConditions = {
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'MASSEXTRACTION TECH3', 'MASSEXTRACTION' } },
            { SIBC, 'GreaterThanEconIncome', { 13, 50 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.65, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'Sorian T2 Mass Extractor Upgrade Timeless Multiple - Later - Rush',
        PlatoonTemplate = 'T2MassExtractorUpgrade',
        Priority = 200,
        InstanceCount = 3,
        BuilderConditions = {
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'ENERGYPRODUCTION TECH2, ENERGYPRODUCTION TECH3' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, 'MASSEXTRACTION TECH3', 'MASSEXTRACTION' } },
            { SIBC, 'GreaterThanEconIncome',  { 20, 50 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.65, 1.2 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'MASSEXTRACTION TECH3' }},
        },
        FormRadius = 10000,
        BuilderType = 'Any',
    },
}

-- ================================= --
--     EMERGENCY FACTORY UPGRADES
-- ================================= --
BuilderGroup {
    BuilderGroupName = 'SorianEditEmergencyUpgradeBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'SorianEdit Emergency T1 Factory Upgrade',
        PlatoonTemplate = 'T1LandFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2,  categories.MASSEXTRACTION * (categories.TECH2 +  categories.TECH3) } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY LAND TECH2 RESEARCH, FACTORY LAND TECH3 RESEARCH'}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.LAND * categories.TECH1 } },
			{ EBC, 'GreaterThanEconIncome',  { 10, 50 } },
			{ UCBC, 'GreaterThanGameTimeSeconds', { 300 } },
            { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, 'MOBILE TECH2, FACTORY TECH2', 'Enemy'}},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit Emergency T2 Factory Upgrade',
        PlatoonTemplate = 'T2LandFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, 'MASSEXTRACTION TECH3'} },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY LAND TECH3 RESEARCH'}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.LAND * categories.RESEARCH * categories.TECH2 } },
			{ UCBC, 'GreaterThanGameTimeSeconds', { 500 } },
            { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, 'MOBILE TECH3, FACTORY TECH3', 'Enemy'}},
			{ EBC, 'GreaterThanEconIncome',  { 20, 50 } },
        },
        BuilderType = 'Any',
    },
}

-- ================================= --
--     RUSH FACTORY UPGRADES
-- ================================= --
BuilderGroup {
    BuilderGroupName = 'SorianEditT1RushUpgradeBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'SorianEdit Rush T1 Land Factory Upgrade Initial',
        PlatoonTemplate = 'T1LandFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4,  categories.MASSEXTRACTION * (categories.TECH2 +  categories.TECH3) } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY LAND TECH2 RESEARCH, FACTORY LAND TECH3 RESEARCH'}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.LAND * categories.TECH1 } },
            ----{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION TECH2'}},
			{ UCBC, 'GreaterThanGameTimeSeconds', { 300 } },
            { EBC, 'GreaterThanEconIncome',  { 14, 30}},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit RushT1AirFactoryUpgradeInitial',
        PlatoonTemplate = 'T1AirFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        FormDebugFunction = nil,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4,  categories.MASSEXTRACTION * (categories.TECH2 +  categories.TECH3) } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY AIR TECH2 RESEARCH, FACTORY AIR TECH3 RESEARCH'}},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.AIR * categories.TECH1 } },
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION TECH2'}},
			{ UCBC, 'GreaterThanGameTimeSeconds', { 300 } },
            { EBC, 'GreaterThanEconIncome',  { 10, 35}},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit Rush T1 Land Factory Upgrade',
        PlatoonTemplate = 'T1LandFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4,  categories.MASSEXTRACTION * (categories.TECH2 +  categories.TECH3) } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.LAND * categories.TECH1 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY LAND TECH2 RESEARCH, FACTORY LAND TECH3 RESEARCH'}},
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'FACTORY LAND TECH2, FACTORY LAND TECH3'}},
            ----{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION TECH2'}},
			{ UCBC, 'GreaterThanGameTimeSeconds', { 300 } },
            { EBC, 'GreaterThanEconIncome',  { 10, 35}},
            --{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit RushT1AirFactoryUpgrade',
        PlatoonTemplate = 'T1AirFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        FormDebugFunction = nil,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4,  categories.MASSEXTRACTION * (categories.TECH2 +  categories.TECH3) } },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.AIR * categories.TECH1 } },
                { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY AIR TECH2 RESEARCH, FACTORY AIR TECH3 RESEARCH'}},
                --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'FACTORY AIR TECH2, FACTORY AIR TECH3'}},
                ----{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION TECH2'}},
				{ UCBC, 'GreaterThanGameTimeSeconds', { 300 } },
                { EBC, 'GreaterThanEconIncome',  { 15, 35}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
        },
        BuilderType = 'Any',
    },
}

-- ================================= --
--     BALANCED FACTORY UPGRADES
-- ================================= --
BuilderGroup {
    BuilderGroupName = 'SorianEditT1BalancedUpgradeBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'SorianEdit Balanced T1 Land Factory Upgrade Initial',
        PlatoonTemplate = 'T1LandFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'FACTORY LAND TECH2 RESEARCH, FACTORY LAND TECH3 RESEARCH'}},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.LAND * categories.TECH1 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4,  categories.MASSEXTRACTION * (categories.TECH2 +  categories.TECH3) } },
				{ UCBC, 'GreaterThanGameTimeSeconds', { 200 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
        },
        BuilderType = 'Any',
    },
   
    Builder {
        BuilderName = 'SorianEdit BalancedT1AirFactoryUpgradeInitial',
        PlatoonTemplate = 'T1AirFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        FormDebugFunction = nil,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.AIR * categories.TECH1 } },
                { UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'FACTORY AIR TECH2 RESEARCH, FACTORY AIR TECH3 RESEARCH'}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4,  categories.MASSEXTRACTION * (categories.TECH2 +  categories.TECH3) } },
				{ UCBC, 'GreaterThanGameTimeSeconds', { 200 } },
                { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 3, 'FACTORY TECH2, FACTORY TECH3' } },
                { EBC, 'GreaterThanEconIncome',  { 3, 25}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
        },
        BuilderType = 'Any',
    },

    --[[ Builder {
        BuilderName = 'SorianEdit Balanced T1 Land Factory Upgrade',
        PlatoonTemplate = 'T1LandFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'FACTORY LAND TECH2 RESEARCH, FACTORY LAND TECH3 RESEARCH'}},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.LAND * categories.TECH1 } },
                --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'FACTORY LAND TECH2, FACTORY LAND TECH3'}},
                ----{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION TECH2'}},
				{ UCBC, 'GreaterThanGameTimeSeconds', { 300 } },
                { EBC, 'GreaterThanEconIncome',  { 40, 75}},
                --{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
                { IBC, 'BrainNotLowPowerMode', {} },
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit BalancedT1AirFactoryUpgrade',
        PlatoonTemplate = 'T1AirFactoryUpgrade',
        Priority = 120,
        InstanceCount = 4,
        FormDebugFunction = nil,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.AIR * categories.TECH1 } },
                { UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'FACTORY AIR TECH2 RESEARCH, FACTORY AIR TECH3 RESEARCH'}},
                --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'FACTORY AIR TECH2, FACTORY AIR TECH3'}},
                ----{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION TECH2'}},
				{ UCBC, 'GreaterThanGameTimeSeconds', { 300 } },
                { EBC, 'GreaterThanEconIncome',  { 35, 75}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            },
        BuilderType = 'Any',
    }, ]]--
}

BuilderGroup {
    BuilderGroupName = 'SorianEditT2BalancedUpgradeBuilders',
    BuildersType = 'PlatoonFormBuilder',

    --[[ Builder {
        BuilderName = 'SorianEdit Balanced T1 Land Factory Upgrade - T3',
        PlatoonTemplate = 'T1LandFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.LAND * categories.TECH2 * categories.RESEARCH } },
                { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY LAND TECH3 RESEARCH'}},
                --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'MASSEXTRACTION TECH3'}},
				{ UCBC, 'GreaterThanGameTimeSeconds', { 500 } },
                { EBC, 'GreaterThanEconIncome',  { 14, 1.80}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
                { IBC, 'BrainNotLowPowerMode', {} },
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit BalancedT1AirFactoryUpgrade - T3',
        PlatoonTemplate = 'T1AirFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        FormDebugFunction = nil,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.AIR * categories.TECH2 * categories.RESEARCH } },
                { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY AIR TECH3 RESEARCH'}},
                --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'MASSEXTRACTION TECH3'}},
				{ UCBC, 'GreaterThanGameTimeSeconds', { 500 } },
                { EBC, 'GreaterThanEconIncome',  { 14, 1.80}},
                { IBC, 'BrainNotLowPowerMode', {} },
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            },
        BuilderType = 'Any',
    }, ]]--

    Builder {
        BuilderName = 'SorianEdit Balanced T2 Land Factory Upgrade - initial',
        PlatoonTemplate = 'T2LandFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.MASSEXTRACTION * categories.TECH3 } },
                { UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'FACTORY LAND TECH3 RESEARCH'}},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.LAND * categories.TECH2 * categories.RESEARCH } },
                { UCBC, 'GreaterThanGameTimeSeconds', { 400 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit Balanced T2 Air Factory Upgrade - initial',
        PlatoonTemplate = 'T2AirFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.MASSEXTRACTION * categories.TECH3 } },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.AIR * categories.TECH2 * categories.RESEARCH } },
                { UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'FACTORY AIR TECH3 RESEARCH'}},
                { UCBC, 'GreaterThanGameTimeSeconds', { 400 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
        },
        BuilderType = 'Any',
    },

    --[[ Builder {
        BuilderName = 'SorianEdit Balanced T2 Land Factory Upgrade - Large Map',
        PlatoonTemplate = 'T2LandFactoryUpgrade',
        Priority = 140,
        InstanceCount = 4,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY LAND TECH3 RESEARCH'}},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.LAND * categories.TECH2 * categories.RESEARCH } },
                --{ SIBC, 'FactoryRatioLessOrEqual', { 'LocationType', 1.0, 'FACTORY LAND TECH3', 'FACTORY AIR TECH3', 'FACTORY AIR TECH2'}},
                -- { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 7, 'MOBILE LAND'}},
                { EBC, 'GreaterThanEconIncome',  { 14, 1.80}},
                { IBC, 'BrainNotLowPowerMode', {} },
				{ UCBC, 'GreaterThanGameTimeSeconds', { 500 } },
                --{ SBC, 'AIType', {'sorianrush', false }},
                ----CanBuildFirebase { 1000, 1000 }},
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            },
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'SorianEdit Balanced T2 Air Factory Upgrade - Large Map',
        PlatoonTemplate = 'T2AirFactoryUpgrade',
        Priority = 140,
        InstanceCount = 4,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.AIR * categories.TECH2 * categories.RESEARCH } },
                { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY AIR TECH3 RESEARCH'}},
                --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'FACTORY TECH3, FACTORY TECH2'}},
                --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'MASSEXTRACTION TECH3'}},
                { EBC, 'GreaterThanEconIncome',  { 14, 1.80}},
                { IBC, 'BrainNotLowPowerMode', {} },
				{ UCBC, 'GreaterThanGameTimeSeconds', { 500 } },
                --{ SBC, 'AIType', {'sorianrush', false }},
                ----CanBuildFirebase { 1000, 1000 }},
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit Balanced T2 Land Factory Upgrade - Rush',
        PlatoonTemplate = 'T2LandFactoryUpgrade',
        Priority = 140,
        InstanceCount = 4,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY LAND TECH3 RESEARCH'}},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.LAND * categories.TECH2 * categories.RESEARCH } },
                --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'MASSEXTRACTION TECH3'}},
                --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'FACTORY TECH3, FACTORY TECH2'}},
                -- { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 7, 'MOBILE LAND'}},
                { EBC, 'GreaterThanEconIncome',  { 14, 1.80}},
                { IBC, 'BrainNotLowPowerMode', {} },
				{ UCBC, 'GreaterThanGameTimeSeconds', { 500 } },
                --{ SBC, 'AIType', {'sorianrush', true }},
                ----CanBuildFirebase { 1000, 1000 }},
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit Balanced T2 Air Factory Upgrade - Small Map',
        PlatoonTemplate = 'T2AirFactoryUpgrade',
        Priority = 140,
        InstanceCount = 4,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.AIR * categories.TECH2 * categories.RESEARCH } },
                { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY AIR TECH3 RESEARCH'}},
                { EBC, 'GreaterThanEconIncome',  { 14, 1.80}},
                { IBC, 'BrainNotLowPowerMode', {} },
				{ UCBC, 'GreaterThanGameTimeSeconds', { 500 } },
                --{ SBC, 'AIType', {'sorianrush', true }},
                ----CanBuildFirebase { 1000, 1000 }},
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            },
        BuilderType = 'Any',
    }, ]]--
}

-- ================================= --
--     NAVAL FACTORY UPGRADES
-- ================================= --
BuilderGroup {
    BuilderGroupName = 'SorianEditT1NavalUpgradeBuilders',
    BuildersType = 'PlatoonFormBuilder',
    -- ================================= --
    --     INITIAL FACTORY UPGRADES
    -- ================================= --
    Builder {
        BuilderName = 'SorianEdit Naval T1 Naval Factory Upgrade Initial',
        PlatoonTemplate = 'T1SeaFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        FormDebugFunction = nil,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.NAVAL * categories.TECH1 } },
                { UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'FACTORY NAVAL TECH2 RESEARCH'}},
				{ UCBC, 'GreaterThanGameTimeSeconds', { 500 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 7,  categories.MASSEXTRACTION * (categories.TECH2 +  categories.TECH3) } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
        },
        BuilderType = 'Any',
    },
   --[[ -- ================================= --
    --     FACTORY UPGRADES AFTER INITIAL
    -- ================================= --
     Builder {
        BuilderName = 'SorianEdit Naval T1 Sea Factory Upgrade',
        PlatoonTemplate = 'T1SeaFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 4, categories.FACTORY * categories.NAVAL * categories.TECH1 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'FACTORY NAVAL TECH2 RESEARCH'}},
                --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION TECH2'}},
                --{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, 'NAVAL' } },
                { IBC, 'BrainNotLowPowerMode', {} },
				{ UCBC, 'GreaterThanGameTimeSeconds', { 500 } },
                { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.2} },
            },
        BuilderType = 'Any',
    },]]--
}

BuilderGroup {
    BuilderGroupName = 'SorianEditT2NavalUpgradeBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'SorianEdit Naval T2 Sea Factory Upgrade init',
        PlatoonTemplate = 'T2SeaFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 1,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.NAVAL * categories.TECH2 * categories.RESEARCH } },
                { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY NAVAL TECH3 RESEARCH'}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * categories.TECH3 } },
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
        },
        BuilderType = 'Any',
    },

    --[[ Builder {
        BuilderName = 'SorianEdit Naval T2 Sea Factory Upgrade',
        PlatoonTemplate = 'T2SeaFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 4, categories.FACTORY * categories.NAVAL * categories.TECH2 * categories.RESEARCH } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, 'FACTORY NAVAL TECH3 RESEARCH'}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, 'MASSEXTRACTION TECH3'} },
                { EBC, 'GreaterThanEconIncome',  { 20, 10}},
				{ UCBC, 'GreaterThanGameTimeSeconds', { 500 } },
                { IBC, 'BrainNotLowPowerMode', {} },
            },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit Naval T1 Sea Factory Upgrade',
        PlatoonTemplate = 'T1SeaFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 3,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 4, categories.FACTORY * categories.NAVAL * categories.TECH1 } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, 'FACTORY NAVAL TECH2 RESEARCH'}},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, 'MASSEXTRACTION TECH3'} },
                { EBC, 'GreaterThanEconIncome',  { 20, 10}},
				{ UCBC, 'GreaterThanGameTimeSeconds', { 300 } },
                { IBC, 'BrainNotLowPowerMode', {} },
            },
        BuilderType = 'Any',
    }, ]]--
}

BuilderGroup {
    BuilderGroupName = 'SorianEditT1FastUpgradeBuildersExpansion',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'SorianEdit Fast T1 Land Factory Upgrade Expansion',
        PlatoonTemplate = 'T1LandFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY LAND TECH2 RESEARCH, FACTORY LAND TECH3 RESEARCH'}},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.LAND * categories.TECH1 } },
                --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION TECH2'}},
                --{ UCBC, 'FactoryLessAtLocation', { 'MAIN', 1, 'FACTORY TECH1' } },
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
                { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit FastT1AirFactoryUpgrade Expansion',
        PlatoonTemplate = 'T1AirFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        FormDebugFunction = nil,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY AIR TECH2 RESEARCH, FACTORY AIR TECH3 RESEARCH'}},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.AIR * categories.TECH1 } },
                --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION TECH2'}},
                { IBC, 'BrainNotLowPowerMode', {} },
				{ UCBC, 'GreaterThanGameTimeSeconds', { 300 } },
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit Fast T1 Sea Factory Upgrade Expansion',
        PlatoonTemplate = 'T1SeaFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY NAVAL TECH2 RESEARCH, FACTORY NAVAL TECH3 RESEARCH'}},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 4, categories.FACTORY * categories.NAVAL * categories.TECH1 } },
                { IBC, 'BrainNotLowPowerMode', {} },
				{ UCBC, 'GreaterThanGameTimeSeconds', { 300 } },
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
        },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianEditT2FastUpgradeBuildersExpansion',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'SorianEdit Fast T2 Land Factory Upgrade Expansion',
        PlatoonTemplate = 'T2LandFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.LAND * categories.TECH2 * categories.RESEARCH } },
                { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY LAND TECH3 RESEARCH'}},
                -- { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 7, 'MOBILE LAND'}},
                { IBC, 'BrainNotLowPowerMode', {} },
				{ UCBC, 'GreaterThanGameTimeSeconds', { 500 } },
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit Fast T2 Air Factory Upgrade Expansion',
        PlatoonTemplate = 'T2AirFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.AIR * categories.TECH2 * categories.RESEARCH } },
                { UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY AIR TECH3 RESEARCH'}},
                { EBC, 'GreaterThanEconIncome',  { 11, 1.80}},
                { IBC, 'BrainNotLowPowerMode', {} },
				{ UCBC, 'GreaterThanGameTimeSeconds', { 500 } },
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit Fast T2 Sea Factory Upgrade Expansion',
        PlatoonTemplate = 'T2SeaFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 4, categories.FACTORY * categories.NAVAL * categories.TECH2 * categories.RESEARCH } },
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, 'FACTORY NAVAL TECH3 RESEARCH'}},
                { EBC, 'GreaterThanEconIncome',  { 11, 20}},
                { IBC, 'BrainNotLowPowerMode', {} },
				{ UCBC, 'GreaterThanGameTimeSeconds', { 500 } },
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            },
        BuilderType = 'Any',
    },
}

-- ============================================ --
--     BALANCED FACTORY UPGRADES EXPANSIONS
-- ============================================ --
BuilderGroup {
    BuilderGroupName = 'SorianEditT1BalancedUpgradeBuildersExpansion',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'SorianEdit Balanced T1 Land Factory Upgrade Expansion',
        PlatoonTemplate = 'T1LandFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 7,  categories.MASSEXTRACTION * (categories.TECH2 +  categories.TECH3) } },
                { UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'FACTORY LAND TECH2 RESEARCH, FACTORY LAND TECH3 RESEARCH'}},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.LAND * categories.TECH1 } },
                --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION TECH2'}},
                --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'FACTORY TECH3'}},
                --{ UCBC, 'FactoryLessAtLocation', { 'MAIN', 1, 'FACTORY TECH1' } },
                --{ UCBC, 'FactoryGreaterAtLocation', { 'MAIN', 2, 'FACTORY TECH3' } },
                { EBC, 'GreaterThanEconIncome',  { 12, 5.0}},
				{ UCBC, 'GreaterThanGameTimeSeconds', { 300 } },
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
                { IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'SorianEdit BalancedT1AirFactoryUpgrade Expansion',
        PlatoonTemplate = 'T1AirFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        FormDebugFunction = nil,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 7,  categories.MASSEXTRACTION * (categories.TECH2 +  categories.TECH3) } },
                { UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'FACTORY AIR TECH2 RESEARCH, FACTORY AIR TECH3 RESEARCH'}},
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.AIR * categories.TECH1 } },
                --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, 'MASSEXTRACTION TECH2'}},
                --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'FACTORY TECH3'}},
                --{ UCBC, 'FactoryLessAtLocation', { 'MAIN', 1, 'FACTORY TECH1' } },
                --{ UCBC, 'FactoryGreaterAtLocation', { 'MAIN', 2, 'FACTORY TECH3' } },
                { EBC, 'GreaterThanEconIncome',  { 12, 5.0}},
                { IBC, 'BrainNotLowPowerMode', {} },
				{ UCBC, 'GreaterThanGameTimeSeconds', { 300 } },
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
        },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianEditT2BalancedUpgradeBuildersExpansion',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'SorianEdit Balanced T2 Land Factory Upgrade Expansion',
        PlatoonTemplate = 'T2LandFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * categories.TECH3 } },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.LAND * categories.TECH2 * categories.RESEARCH } },
                { UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'FACTORY LAND TECH3 RESEARCH'}},
                -- { UCBC, 'UnitsGreaterAtLocation', { 'LocationType', 7, 'MOBILE LAND'}},
                { EBC, 'GreaterThanEconIncome',  { 11, 1.80}},
                { IBC, 'BrainNotLowPowerMode', {} },
				{ UCBC, 'GreaterThanGameTimeSeconds', { 500 } },
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit Balanced T2 Air Factory Upgrade Expansion',
        PlatoonTemplate = 'T2AirFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.MASSEXTRACTION * categories.TECH3 } },
                { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.FACTORY * categories.AIR * categories.TECH2 * categories.RESEARCH } },
                { UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'FACTORY AIR TECH3 RESEARCH'}},
                --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'MASSEXTRACTION TECH3'}},
                { EBC, 'GreaterThanEconIncome',  { 11, 1.80}},
                { IBC, 'BrainNotLowPowerMode', {} },
				{ UCBC, 'GreaterThanGameTimeSeconds', { 500 } },
                { EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
        },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianEditSupportFactoryUpgrades',
    BuildersType = 'PlatoonFormBuilder',
    -- LAND Support Factories
    Builder {
        BuilderName = 'SorianEdit T1 Land Support Factory Upgrade',
        PlatoonTemplate = 'T1LandFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9501', 'zab9501', 'zrb9501', 'zsb9501', 'znb9501' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 7,  categories.MASSEXTRACTION * (categories.TECH2 +  categories.TECH3) } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * ( categories.TECH2 + categories.TECH3 ) - categories.SUPPORTFACTORY } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 4, categories.STRUCTURE * categories.FACTORY * categories.TECH1 * categories.LAND }},
        },
        BuilderType = 'Any',
    },
    -- Builder for 5 factions
    Builder {
        BuilderName = 'SorianEdit T2 Land Support Factory Upgrade 1',
        PlatoonTemplate = 'T2LandSupFactoryUpgrade1',
        Priority = 4000,
        InstanceCount = 4,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9601', 'zab9601', 'zrb9601', 'zsb9601', 'znb9601' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * categories.TECH3 } },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENERGYPRODUCTION * categories.TECH3 - categories.HYDROCARBON } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.UEF * categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 - categories.SUPPORTFACTORY} },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.UEF * categories.SUPPORTFACTORY * categories.LAND * categories.TECH2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 4, categories.STRUCTURE * categories.FACTORY * categories.TECH2 * categories.LAND }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit T2 Land Support Factory Upgrade 2',
        PlatoonTemplate = 'T2LandSupFactoryUpgrade2',
        Priority = 4000,
        InstanceCount = 4,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9601', 'zab9601', 'zrb9601', 'zsb9601', 'znb9601' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * categories.TECH3 } },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENERGYPRODUCTION * categories.TECH3 - categories.HYDROCARBON } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.AEON * categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 - categories.SUPPORTFACTORY} },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.AEON * categories.SUPPORTFACTORY * categories.LAND * categories.TECH2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 4, categories.STRUCTURE * categories.FACTORY * categories.TECH2 * categories.LAND }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit T2 Land Support Factory Upgrade 3',
        PlatoonTemplate = 'T2LandSupFactoryUpgrade3',
        Priority = 4000,
        InstanceCount = 4,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9601', 'zab9601', 'zrb9601', 'zsb9601', 'znb9601' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * categories.TECH3 } },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENERGYPRODUCTION * categories.TECH3 - categories.HYDROCARBON } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.CYBRAN * categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 - categories.SUPPORTFACTORY} },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.CYBRAN * categories.SUPPORTFACTORY * categories.LAND * categories.TECH2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 4, categories.STRUCTURE * categories.FACTORY * categories.TECH2 * categories.LAND }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit T2 Land Support Factory Upgrade 4',
        PlatoonTemplate = 'T2LandSupFactoryUpgrade4',
        Priority = 4000,
        InstanceCount = 4,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9601', 'zab9601', 'zrb9601', 'zsb9601', 'znb9601' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * categories.TECH3 } },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENERGYPRODUCTION * categories.TECH3 - categories.HYDROCARBON } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SERAPHIM * categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 - categories.SUPPORTFACTORY} },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SERAPHIM * categories.SUPPORTFACTORY * categories.LAND * categories.TECH2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 4, categories.STRUCTURE * categories.FACTORY * categories.TECH2 * categories.LAND }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit T2 Land Support Factory Upgrade 5',
        PlatoonTemplate = 'T2LandSupFactoryUpgrade5',
        Priority = 4000,
        InstanceCount = 4,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9601', 'zab9601', 'zrb9601', 'zsb9601', 'znb9601' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * categories.TECH3 } },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENERGYPRODUCTION * categories.TECH3 - categories.HYDROCARBON } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.LAND * categories.TECH3 - categories.SUPPORTFACTORY - categories.SERAPHIM - categories.CYBRAN - categories.AEON - categories.UEF } },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SUPPORTFACTORY * categories.TECH2 * categories.LAND - categories.SERAPHIM - categories.CYBRAN - categories.AEON - categories.UEF }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 4, categories.STRUCTURE * categories.FACTORY * categories.TECH2 * categories.LAND }},
        },
        BuilderType = 'Any',
    },
    -- AIR Support Factoriesa
    Builder {
        BuilderName = 'SorianEdit T1 Air Support Factory Upgrade',
        PlatoonTemplate = 'T1AirFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 3,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9502', 'zab9502', 'zrb9502', 'zsb9502', 'znb9502' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6,  categories.MASSEXTRACTION * (categories.TECH2 +  categories.TECH3) } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.AIR * ( categories.TECH2 + categories.TECH3 ) - categories.SUPPORTFACTORY } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 4, categories.STRUCTURE * categories.FACTORY * categories.TECH1 * categories.AIR }},
        },
        BuilderType = 'Any',
    },
    -- Builder for 5 factions
    Builder {
        BuilderName = 'SorianEdit T2 Air Support Factory Upgrade 1',
        PlatoonTemplate = 'T2AirSupFactoryUpgrade1',
        Priority = 4000,
        InstanceCount = 3,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9602', 'zab9602', 'zrb9602', 'zsb9602', 'znb9602' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * categories.TECH3 } },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENERGYPRODUCTION * categories.TECH3 - categories.HYDROCARBON } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.UEF * categories.STRUCTURE * categories.FACTORY * categories.AIR * categories.TECH3 - categories.SUPPORTFACTORY} },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.UEF * categories.AIR * categories.SUPPORTFACTORY * categories.TECH2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 4, categories.STRUCTURE * categories.FACTORY * categories.TECH2 * categories.AIR }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit T2 Air Support Factory Upgrade 2',
        PlatoonTemplate = 'T2AirSupFactoryUpgrade2',
        Priority = 4000,
        InstanceCount = 3,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9602', 'zab9602', 'zrb9602', 'zsb9602', 'znb9602' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * categories.TECH3 } },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENERGYPRODUCTION * categories.TECH3 - categories.HYDROCARBON } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.AEON * categories.STRUCTURE * categories.FACTORY * categories.AIR * categories.TECH3 - categories.SUPPORTFACTORY} },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.AEON * categories.AIR * categories.SUPPORTFACTORY * categories.TECH2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 4, categories.STRUCTURE * categories.FACTORY * categories.TECH2 * categories.AIR }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit T2 Air Support Factory Upgrade 3',
        PlatoonTemplate = 'T2AirSupFactoryUpgrade3',
        Priority = 4000,
        InstanceCount = 3,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9602', 'zab9602', 'zrb9602', 'zsb9602', 'znb9602' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * categories.TECH3 } },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENERGYPRODUCTION * categories.TECH3 - categories.HYDROCARBON } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.CYBRAN * categories.STRUCTURE * categories.FACTORY * categories.AIR * categories.TECH3 - categories.SUPPORTFACTORY} },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.CYBRAN * categories.AIR * categories.SUPPORTFACTORY * categories.TECH2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 4, categories.STRUCTURE * categories.FACTORY * categories.TECH2 * categories.AIR }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit T2 Air Support Factory Upgrade 4',
        PlatoonTemplate = 'T2AirSupFactoryUpgrade4',
        Priority = 4000,
        InstanceCount = 3,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9602', 'zab9602', 'zrb9602', 'zsb9602', 'znb9602' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * categories.TECH3 } },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENERGYPRODUCTION * categories.TECH3 - categories.HYDROCARBON } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SERAPHIM * categories.STRUCTURE * categories.FACTORY * categories.AIR * categories.TECH3 - categories.SUPPORTFACTORY} },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SERAPHIM * categories.AIR * categories.SUPPORTFACTORY * categories.TECH2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 4, categories.STRUCTURE * categories.FACTORY * categories.TECH2 * categories.AIR }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit T2 Air Support Factory Upgrade 5',
        PlatoonTemplate = 'T2AirSupFactoryUpgrade5',
        Priority = 4000,
        InstanceCount = 3,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9602', 'zab9602', 'zrb9602', 'zsb9602', 'znb9602' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.MASSEXTRACTION * categories.TECH3 } },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENERGYPRODUCTION * categories.TECH3 - categories.HYDROCARBON } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6,  categories.MASSEXTRACTION * (categories.TECH2 +  categories.TECH3) } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.AIR * categories.TECH3 - categories.SUPPORTFACTORY - categories.SERAPHIM - categories.CYBRAN - categories.AEON - categories.UEF } },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SUPPORTFACTORY * categories.TECH2 * categories.AIR - categories.SERAPHIM - categories.CYBRAN - categories.AEON - categories.UEF }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 4, categories.STRUCTURE * categories.FACTORY * categories.TECH2 * categories.AIR }},
        },
        BuilderType = 'Any',
    },
}
BuilderGroup {
    BuilderGroupName = 'SorianEditSupportFactoryUpgradesNAVY',
    BuildersType = 'PlatoonFormBuilder',
    -- NAVAL Support Factories
    Builder {
        BuilderName = 'SorianEdit T1 Navy Support Factory Upgrade',
        PlatoonTemplate = 'T1SeaFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9503', 'zab9503', 'zrb9503', 'zsb9503', 'znb9503' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { EBC, 'GreaterThanEconStorageRatio', { 0.03, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6,  categories.MASSEXTRACTION * (categories.TECH2 +  categories.TECH3) } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.NAVAL * ( categories.TECH2 + categories.TECH3 ) - categories.SUPPORTFACTORY } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.STRUCTURE * categories.FACTORY * categories.TECH1 * categories.NAVAL }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit T2 Navy Support Factory Upgrade',
        PlatoonTemplate = 'T1SeaFactoryUpgrade',
        Priority = 4000,
        InstanceCount = 4,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9503', 'zab9503', 'zrb9503', 'zsb9503', 'znb9503' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { EBC, 'GreaterThanEconStorageRatio', { 0.03, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6,  categories.MASSEXTRACTION * (categories.TECH2 +  categories.TECH3) } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.NAVAL * categories.TECH3 - categories.SUPPORTFACTORY } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.STRUCTURE * categories.FACTORY * categories.TECH2 * categories.NAVAL }},
        },
        BuilderType = 'Any',
    },
-- Builder for 5 factions
    Builder {
        BuilderName = 'SorianEdit T2 Navy Support Factory Upgrade 1',
        PlatoonTemplate = 'T2SeaSupFactoryUpgrade1',
        Priority = 4000,
        InstanceCount = 4,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9603', 'zab9603', 'zrb9603', 'zsb9603', 'znb9603' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { EBC, 'GreaterThanEconStorageRatio', { 0.03, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.MASSEXTRACTION * categories.TECH3 } },
            -- { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.ENERGYPRODUCTION * categories.TECH3 - categories.HYDROCARBON } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.UEF * categories.STRUCTURE * categories.FACTORY * categories.NAVAL * categories.TECH3 - categories.SUPPORTFACTORY} },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.UEF * categories.NAVAL * categories.SUPPORTFACTORY * categories.TECH2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 3, categories.STRUCTURE * categories.FACTORY * categories.TECH2 * categories.NAVAL }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit T2 Navy Support Factory Upgrade 2',
        PlatoonTemplate = 'T2SeaSupFactoryUpgrade2',
        Priority = 4000,
        InstanceCount = 4,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9603', 'zab9603', 'zrb9603', 'zsb9603', 'znb9603' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.MASSEXTRACTION * categories.TECH3 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.ENERGYPRODUCTION * categories.TECH3 - categories.HYDROCARBON } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.AEON * categories.STRUCTURE * categories.FACTORY * categories.NAVAL * categories.TECH3 - categories.SUPPORTFACTORY} },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.AEON * categories.NAVAL * categories.SUPPORTFACTORY * categories.TECH2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.STRUCTURE * categories.FACTORY * categories.TECH2 * categories.NAVAL }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit T2 Navy Support Factory Upgrade 3',
        PlatoonTemplate = 'T2SeaSupFactoryUpgrade3',
        Priority = 4000,
        InstanceCount = 4,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9603', 'zab9603', 'zrb9603', 'zsb9603', 'znb9603' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.MASSEXTRACTION * categories.TECH3 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.ENERGYPRODUCTION * categories.TECH3 - categories.HYDROCARBON } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.CYBRAN * categories.STRUCTURE * categories.FACTORY * categories.NAVAL * categories.TECH3 - categories.SUPPORTFACTORY} },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.CYBRAN * categories.NAVAL * categories.SUPPORTFACTORY * categories.TECH2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.STRUCTURE * categories.FACTORY * categories.TECH2 * categories.NAVAL }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit T2 Navy Support Factory Upgrade 4',
        PlatoonTemplate = 'T2SeaSupFactoryUpgrade4',
        Priority = 4000,
        InstanceCount = 4,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9603', 'zab9603', 'zrb9603', 'zsb9603', 'znb9603' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.MASSEXTRACTION * categories.TECH3 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.ENERGYPRODUCTION * categories.TECH3 - categories.HYDROCARBON } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SERAPHIM * categories.STRUCTURE * categories.FACTORY * categories.NAVAL * categories.TECH3 - categories.SUPPORTFACTORY} },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SERAPHIM * categories.NAVAL * categories.SUPPORTFACTORY * categories.TECH2 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.STRUCTURE * categories.FACTORY * categories.TECH2 * categories.NAVAL }},
        },
        BuilderType = 'Any',
    },
    Builder {
        BuilderName = 'SorianEdit T2 Navy Support Factory Upgrade 5',
        PlatoonTemplate = 'T2SeaSupFactoryUpgrade5',
        Priority = 4000,
        InstanceCount = 3,
        BuilderData = {
            OverideUpgradeBlueprint = { 'zeb9603', 'zab9603', 'zrb9603', 'zsb9603', 'znb9603' }, -- overides Upgrade blueprint for all 5 factions. Used for support factories
        },
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { IBC, 'BrainNotLowMassMode', {} },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconStorageRatio', { 0.04, 0.01 } },
			{ EBC, 'GreaterThanEconTrend', { 0.0, 0.0 } },
			{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 0.95 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.MASSEXTRACTION * categories.TECH3 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.ENERGYPRODUCTION * categories.TECH3 - categories.HYDROCARBON } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.STRUCTURE * categories.FACTORY * categories.NAVAL * categories.TECH3 - categories.SUPPORTFACTORY - categories.SERAPHIM - categories.CYBRAN - categories.AEON - categories.UEF } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SUPPORTFACTORY * categories.TECH2 * categories.NAVAL - categories.SERAPHIM - categories.CYBRAN - categories.AEON - categories.UEF }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingUpgrade', { 2, categories.STRUCTURE * categories.FACTORY * categories.TECH2 * categories.NAVAL }},
        },
        BuilderType = 'Any',
    },
}