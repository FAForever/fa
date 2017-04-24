#***************************************************************************
#*
#**  File     :  /lua/ai/AISeaAttackBuilders.lua
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
local TBC = '/lua/editor/ThreatBuildConditions.lua'
local SAI = '/lua/ScenarioPlatoonAI.lua'
local PlatoonFile = '/lua/platoon.lua'

function SeaAttackCondition(aiBrain, locationType, targetNumber)
    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')

    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager

    local position = engineerManager:GetLocationCoords()
    local radius = engineerManager:GetLocationRadius()

    local surfaceThreat = pool:GetPlatoonThreat('AntiSurface', categories.MOBILE * categories.NAVAL, position, radius)
    local subThreat = pool:GetPlatoonThreat('AntiSub', categories.MOBILE * categories.NAVAL, position, radius)
    if (surfaceThreat + subThreat) > targetNumber then
        return true
    end
    return false
end

BuilderGroup {
    BuilderGroupName = 'T1SeaFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
       BuilderName = 'T1 Sea Sub - init',
       PlatoonTemplate = 'T1SeaSub',
       Priority = 1000,
       BuilderConditions = {
            { UCBC,'HaveLessThanUnitsWithCategory', { 2, 'MOBILE NAVAL SUBMERSIBLE' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.2 }},
       },
       BuilderType = 'Sea',
    },
    Builder {
       BuilderName = 'T1 Sea Frigate - init',
       PlatoonTemplate = 'T1SeaFrigate',
       Priority = 1000,
       BuilderType = 'Sea',
       BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, 'MOBILE NAVAL FRIGATE' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.2 }},
       },
    },
    Builder {
        BuilderName = 'T1 Sea Sub',
        PlatoonTemplate = 'T1SeaSub',
        Priority = 501,
        BuilderConditions = {
            { UCBC, 'HaveUnitRatio', { 0.4, categories.MOBILE * categories.NAVAL * categories.SUBMERSIBLE, '<=', categories.MOBILE * categories.NAVAL}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'T1 Sea Frigate',
        PlatoonTemplate = 'T1SeaFrigate',
        Priority = 500,
        BuilderType = 'Sea',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
    },
    Builder {
        BuilderName = 'T1 Naval Anti-Air',
        PlatoonTemplate = 'T1SeaAntiAir',
        Priority = 500,
        BuilderConditions = {
            #DUNCAN - commented out as need some anti all the time.
            #{ TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 10, 'Air' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
        BuilderType = 'Sea',
    },
}

BuilderGroup {
    BuilderGroupName = 'T2SeaFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'T2 Naval Destroyer',
        PlatoonTemplate = 'T2SeaDestroyer',
        Priority = 600,
        BuilderType = 'Sea',
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'CRUISER'}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }}, #DUNCAN - was 0.9
        },
    },
    Builder {
        BuilderName = 'T2 Naval Cruiser',
        PlatoonTemplate = 'T2SeaCruiser',
        PlatoonAddBehaviors = { 'AirLandToggle' },
        Priority = 600,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'T2SubKiller',
        PlatoonTemplate = 'T2SubKiller',
        Priority = 600,
        BuilderType = 'Sea',
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'DESTROYER'}},
            #{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, 'T1SUBMARINE'}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
    },
    Builder {
        BuilderName = 'T2ShieldBoat',
        PlatoonTemplate = 'T2ShieldBoat',
        Priority = 600,
        BuilderType = 'Sea',
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'CRUISER'}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'DESTROYER'}},
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, 'SHIELD NAVAL MOBILE' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
    },
    Builder {
        BuilderName = 'T2CounterIntelBoat',
        PlatoonTemplate = 'T2CounterIntelBoat',
        Priority = 600,
        BuilderType = 'Sea',
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'CRUISER'}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'DESTROYER'}},
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, 'COUNTERINTELLIGENCE NAVAL MOBILE' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'T3SeaFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'T3 Naval Battleship',
        PlatoonTemplate = 'T3SeaBattleship',
        Priority = 700,
        BuilderType = 'Sea',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
    },
    Builder {
        BuilderName = 'T3 Naval Nuke Sub',
        PlatoonTemplate = 'T3SeaNukeSub',
        Priority = 700,
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'BATTLESHIP' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.NUKE } }, #DUNCAN - added so it doesnt over build
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'T3MissileBoat',
        PlatoonTemplate = 'T3MissileBoat',
        Priority = 700,
        BuilderType = 'Sea',
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'BATTLESHIP' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
    },
    Builder {
        BuilderName = 'T3SubKiller',
        PlatoonTemplate = 'T3SubKiller',
        Priority = 700,
        BuilderType = 'Sea',
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'BATTLESHIP' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
    },
    Builder {
        BuilderName = 'T3Battlecruiser',
        PlatoonTemplate = 'T3Battlecruiser',
        Priority = 700,
        BuilderType = 'Sea',
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'BATTLESHIP' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }},
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'FrequentSeaAttackFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Frequent Sea Attack T1',
        PlatoonTemplate = 'SeaAttack',
        Priority = 1,
        InstanceCount = 10, #DUNCAN - was 5
        BuilderType = 'Any',
        BuilderData = {
            UseFormation = 'AttackFormation',
            ThreatWeights = {
                IgnoreStrongerTargetsRatio = 100.0,  #DUNCAN - uncommented, was 100
                PrimaryThreatTargetType = 'Naval',
                SecondaryThreatTargetType = 'Economy',
                SecondaryThreatWeight = 1, #DUNCAN - was 0.1
                WeakAttackThreatWeight = 1,
                VeryNearThreatWeight = 10,
                NearThreatWeight = 5,
                MidThreatWeight = 1,
                FarThreatWeight = 1,
            },
        },
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, 'MOBILE TECH2 NAVAL, MOBILE TECH3 NAVAL' } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, 'MOBILE NAVAL SUB' } },
            { SeaAttackCondition, { 'LocationType', 14 } },
        },
    },
    Builder {
        BuilderName = 'Frequent Sea Attack T2',
        PlatoonTemplate = 'SeaAttack',
        Priority = 1,
        InstanceCount = 10, #DUNCAN - was 5
        BuilderType = 'Any',
        BuilderData = {
            UseFormation = 'AttackFormation',
            ThreatWeights = {
                IgnoreStrongerTargetsRatio = 100.0,  #DUNCAN - uncommented, was 100
                PrimaryThreatTargetType = 'Naval',
                SecondaryThreatTargetType = 'Economy',
                SecondaryThreatWeight = 0.1,
                WeakAttackThreatWeight = 1,
                VeryNearThreatWeight = 10,
                NearThreatWeight = 5,
                MidThreatWeight = 1,
                FarThreatWeight = 1,
            },
        },
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, 'MOBILE TECH3 NAVAL' } },
            { SeaAttackCondition, { 'LocationType', 50 } }, #DUNCAN - was 60
        },
    },
    Builder {
        BuilderName = 'Frequent Sea Attack T3',
        PlatoonTemplate = 'SeaAttack',
        Priority = 1,
        InstanceCount = 20,  #DUNCAN - was 5
        BuilderType = 'Any',
        BuilderData = {
            UseFormation = 'AttackFormation',
            ThreatWeights = {
                IgnoreStrongerTargetsRatio = 100.0, #DUNCAN - uncommented, was 100
                PrimaryThreatTargetType = 'Naval',
                SecondaryThreatTargetType = 'Economy',
                SecondaryThreatWeight = 0.1,
                WeakAttackThreatWeight = 1,
                VeryNearThreatWeight = 10,
                NearThreatWeight = 5,
                MidThreatWeight = 1,
                FarThreatWeight = 1,
            },
        },
        BuilderConditions = {
            { SeaAttackCondition, { 'LocationType', 180 } }, #DUNCAN - was 180
        },
    },
    Builder {
        BuilderName = 'Frequent Sea Attack T3 Nuke',
        PlatoonTemplate = 'SeaNuke',
        PlatoonAddPlans = { 'NukeAI', },
        Priority = 1,
        InstanceCount = 20,
        BuilderType = 'Any',
        BuilderData = {
            UseFormation = 'AttackFormation',
            ThreatWeights = {
                IgnoreStrongerTargetsRatio = 100.0, #DUNCAN - uncommented, was 100
                PrimaryThreatTargetType = 'Naval',
                SecondaryThreatTargetType = 'Economy',
                SecondaryThreatWeight = 0.1,
                WeakAttackThreatWeight = 1,
                VeryNearThreatWeight = 10,
                NearThreatWeight = 5,
                MidThreatWeight = 1,
                FarThreatWeight = 1,
            },
        },
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'NAVAL NUKE' } },
        },
    },
    Builder {
        BuilderName = 'Frequent Sea Attack T3 Nuke - Dont fire',
        PlatoonTemplate = 'SeaNuke',
        Priority = 1,
        InstanceCount = 20,
        BuilderType = 'Any',
        BuilderData = {
            UseFormation = 'AttackFormation',
            ThreatWeights = {
                IgnoreStrongerTargetsRatio = 100.0, #DUNCAN - uncommented, was 100
                PrimaryThreatTargetType = 'Naval',
                SecondaryThreatTargetType = 'Economy',
                SecondaryThreatWeight = 0.1,
                WeakAttackThreatWeight = 1,
                VeryNearThreatWeight = 10,
                NearThreatWeight = 5,
                MidThreatWeight = 1,
                FarThreatWeight = 1,
            },
        },
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'NAVAL NUKE' } },
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'BigSeaAttackFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Big Sea Attack T1',
        PlatoonTemplate = 'SeaAttack',
        Priority = 1,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderData = {
            ThreatWeights = {
                IgnoreStrongerTargetsRatio = 100.0,  #DUNCAN - uncommented
                PrimaryThreatTargetType = 'Naval',
                SecondaryThreatTargetType = 'Economic',
                SecondaryThreatWeight = 0.1,
                WeakAttackThreatWeight = 1,
                VeryNearThreatWeight = 10,
                NearThreatWeight = 5,
                MidThreatWeight = 1,
                FarThreatWeight = 1,
            },
        },
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, 'MOBILE TECH2 NAVAL, MOBILE TECH3 NAVAL' } },
            { SeaAttackCondition, { 'LocationType', 40 } },
        },
    },
    Builder {
        BuilderName = 'Big Sea Attack T2',
        PlatoonTemplate = 'SeaAttack',
        Priority = 1,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderData = {
            ThreatWeights = {
                IgnoreStrongerTargetsRatio = 100.0,  #DUNCAN - uncommented
                PrimaryThreatTargetType = 'Naval',
                SecondaryThreatTargetType = 'Economic',
                SecondaryThreatWeight = 0.1,
                WeakAttackThreatWeight = 1,
                VeryNearThreatWeight = 10,
                NearThreatWeight = 5,
                MidThreatWeight = 1,
                FarThreatWeight = 1,
            },
        },
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, 'MOBILE TECH3 NAVAL' } },
            { SeaAttackCondition, { 'LocationType', 120 } },
        },
    },
    Builder {
        BuilderName = 'Big Sea Attack T3',
        PlatoonTemplate = 'SeaAttack',
        Priority = 1,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderData = {
            ThreatWeights = {
                IgnoreStrongerTargetsRatio = 100.0, #DUNCAN - uncommented
                PrimaryThreatTargetType = 'Naval',
                SecondaryThreatTargetType = 'Economic',
                SecondaryThreatWeight = 0.1,
                WeakAttackThreatWeight = 1,
                VeryNearThreatWeight = 10,
                NearThreatWeight = 5,
                MidThreatWeight = 1,
                FarThreatWeight = 1,
            },
        },
        BuilderConditions = {
            { SeaAttackCondition, { 'LocationType', 360 } },
        },
    },
    Builder {
        BuilderName = 'T3 Naval Carrier',
        PlatoonTemplate = 'T3SeaCarrier',
        Priority = 1,
        InstanceCount = 5,
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'MassHunterSeaFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
}
