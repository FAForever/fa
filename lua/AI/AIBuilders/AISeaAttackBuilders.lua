--***************************************************************************
--*
--**  File     :  /lua/ai/AISeaAttackBuilders.lua
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
local TBC = '/lua/editor/threatbuildconditions.lua'
local SAI = '/lua/scenarioplatoonai.lua'
local PlatoonFile = '/lua/platoon.lua'

---@alias BuilderGroupsSeaAttack 'T1SeaFactoryBuilders' | 'T2SeaFactoryBuilders' | 'T3SeaFactoryBuilders' | 'FrequentSeaAttackFormBuilders' | 'BigSeaAttackFormBuilders' | 'MassHunterSeaFormBuilders'

function SeaAttackCondition(aiBrain, locationType, targetNumber)
    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')

    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    if not engineerManager then
        return false
    end

    local position = engineerManager:GetLocationCoords()
    local radius = engineerManager.Radius

    local surfaceThreat = pool:GetPlatoonThreat('Surface', categories.MOBILE * categories.NAVAL, position, radius)
    local subThreat = pool:GetPlatoonThreat('Sub', categories.MOBILE * categories.NAVAL, position, radius)
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
            { UCBC,'HaveLessThanUnitsWithCategory', { 2, categories.MOBILE * categories.NAVAL * categories.SUBMERSIBLE } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.05 }},
       },
       BuilderType = 'Sea',
    },
    Builder {
       BuilderName = 'T1 Sea Frigate - init',
       PlatoonTemplate = 'T1SeaFrigate',
       Priority = 1000,
       BuilderType = 'Sea',
       BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.MOBILE * categories.NAVAL * categories.FRIGATE } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.05 }},
       },
    },
    Builder {
        BuilderName = 'T1 Sea Sub',
        PlatoonTemplate = 'T1SeaSub',
        Priority = 501,
        BuilderConditions = {
            { UCBC, 'HaveUnitRatio', { 0.4, categories.MOBILE * categories.NAVAL * categories.SUBMERSIBLE, '<=', categories.MOBILE * categories.NAVAL}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
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
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
    },
    Builder {
        BuilderName = 'T1 Naval Anti-Air',
        PlatoonTemplate = 'T1SeaAntiAir',
        Priority = 500,
        BuilderConditions = {
            --DUNCAN - commented out as need some anti all the time.
            --{ TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 10, 'Air' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
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
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.CRUISER }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2 }}, --DUNCAN - was 0.9
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
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.DESTROYER }},
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, 'T1SUBMARINE'}},
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
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.CRUISER}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.DESTROYER}},
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.SHIELD * categories.NAVAL * categories.MOBILE } },
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
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.CRUISER}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, categories.DESTROYER}},
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.COUNTERINTELLIGENCE * categories.NAVAL * categories.MOBILE } },
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
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.BATTLESHIP } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.NUKE } }, --DUNCAN - added so it doesnt over build
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
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.BATTLESHIP } },
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
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.BATTLESHIP } },
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
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.BATTLESHIP } },
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
        InstanceCount = 10, --DUNCAN - was 5
        BuilderType = 'Any',
        BuilderData = {
            UseFormation = 'AttackFormation',
            ThreatWeights = {
                IgnoreStrongerTargetsRatio = 100.0,  --DUNCAN - uncommented, was 100
                PrimaryThreatTargetType = 'Naval',
                SecondaryThreatTargetType = 'Economy',
                SecondaryThreatWeight = 1, --DUNCAN - was 0.1
                WeakAttackThreatWeight = 1,
                VeryNearThreatWeight = 10,
                NearThreatWeight = 5,
                MidThreatWeight = 1,
                FarThreatWeight = 1,
            },
        },
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.MOBILE * categories.NAVAL * ( categories.TECH2 + categories.TECH3 ) } },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, categories.MOBILE * categories.NAVAL * categories.TECH1 * (categories.SUBMERSIBLE + categories.DIRECTFIRE) - categories.ENGINEER - categories.EXPERIMENTAL } },
            { SeaAttackCondition, { 'LocationType', 14 } },
        },
    },
    Builder {
        BuilderName = 'Frequent Sea Attack T2',
        PlatoonTemplate = 'SeaAttack',
        Priority = 1,
        InstanceCount = 10, --DUNCAN - was 5
        BuilderType = 'Any',
        BuilderData = {
            UseFormation = 'AttackFormation',
            ThreatWeights = {
                IgnoreStrongerTargetsRatio = 100.0,  --DUNCAN - uncommented, was 100
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
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.MOBILE * categories.TECH3 * categories.NAVAL } },
            { SeaAttackCondition, { 'LocationType', 50 } }, --DUNCAN - was 60
        },
    },
    Builder {
        BuilderName = 'Frequent Sea Attack T3',
        PlatoonTemplate = 'SeaAttack',
        Priority = 1,
        InstanceCount = 20,  --DUNCAN - was 5
        BuilderType = 'Any',
        BuilderData = {
            UseFormation = 'AttackFormation',
            ThreatWeights = {
                IgnoreStrongerTargetsRatio = 100.0, --DUNCAN - uncommented, was 100
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
            { SeaAttackCondition, { 'LocationType', 180 } }, --DUNCAN - was 180
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
                IgnoreStrongerTargetsRatio = 100.0, --DUNCAN - uncommented, was 100
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
            { UCBC, 'HaveLessThanUnitsWithCategory', { 4, categories.NAVAL * categories.NUKE } },
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
                IgnoreStrongerTargetsRatio = 100.0, --DUNCAN - uncommented, was 100
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
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 3, categories.NAVAL * categories.NUKE } },
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
                IgnoreStrongerTargetsRatio = 100.0,  --DUNCAN - uncommented
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
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.MOBILE * categories.NAVAL * ( categories.TECH2 + categories.TECH3 ) } },
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
                IgnoreStrongerTargetsRatio = 100.0,  --DUNCAN - uncommented
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
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, categories.MOBILE * categories.TECH3 * categories.NAVAL } },
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
                IgnoreStrongerTargetsRatio = 100.0, --DUNCAN - uncommented
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
    Builder {
        BuilderName = 'Frequent Sea Mass Raid',
        PlatoonTemplate = 'SeaRaid',
        Priority = 300,
        InstanceCount = 2,
        BuilderConditions = {  
            { MIBC, 'WaterMassMarkersPresent', {} },
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.MOBILE * categories.NAVAL * categories.SUBMERSIBLE * categories.TECH1 } },
            },
        BuilderData = {
            MarkerType = 'Mass',        
            MoveFirst = 'Random',
            MoveNext = 'Threat',
            ThreatType = 'Economy',
            FindHighestThreat = true,
            MaxThreatThreshold = 1000,
            MinThreatThreshold = 50,
            AggressiveMove = true,   
            AvoidClosestRadius = 50,
        },
        BuilderType = 'Any',
    },
}
