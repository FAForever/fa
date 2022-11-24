--***************************************************************************
--*
--**  File     :  /lua/ai/AISeaAttackBuilders.lua
--**
--**  Summary  : Default economic builders for skirmish
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local UCBC = '/lua/editor/unitcountbuildconditions.lua'
local IBC = '/lua/editor/instantbuildconditions.lua'
local TBC = '/lua/editor/threatbuildconditions.lua'
local SBC = '/lua/editor/SorianBuildConditions.lua'
local SIBC = '/lua/editor/SorianInstantBuildConditions.lua'

local SUtils = import("/lua/ai/sorianutilities.lua")

function SeaAttackCondition(aiBrain, locationType, targetNumber)
    local UC = import("/lua/editor/unitcountbuildconditions.lua")
    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    if not engineerManager then
        return true
    end
    --if aiBrain:GetCurrentEnemy() then
    --	local estartX, estartZ = aiBrain:GetCurrentEnemy():GetArmyStartPos()
    --	targetNumber = aiBrain:GetThreatAtPosition({estartX, 0, estartZ}, 1, true, 'AntiSurface')
    --	targetNumber = targetNumber + aiBrain:GetThreatAtPosition({estartX, 0, estartZ}, 1, true, 'AntiSub')
    --end

    local position = engineerManager:GetLocationCoords()
    local radius = engineerManager.Radius

    --local surfaceThreat = pool:GetPlatoonThreat('AntiSurface', categories.MOBILE * categories.NAVAL, position, radius)
    --local subThreat = pool:GetPlatoonThreat('AntiSub', categories.MOBILE * categories.NAVAL, position, radius)
    local surfaceThreat = pool:GetPlatoonThreat('Surface', categories.MOBILE * categories.NAVAL)
    local subThreat = pool:GetPlatoonThreat('Sub', categories.MOBILE * categories.NAVAL)
    if (surfaceThreat + subThreat) >= targetNumber then
        return true
    elseif UC.UnitCapCheckGreater(aiBrain, .95) then
        return true
    elseif SUtils.ThreatBugcheck(aiBrain) then -- added to combat buggy inflated threat
        return true
    elseif UC.PoolGreaterAtLocation(aiBrain, locationType, 0, categories.MOBILE * categories.NAVAL * categories.TECH3) and (surfaceThreat + subThreat) > 1125 then --5 Units x 225
        return true
    elseif UC.PoolGreaterAtLocation(aiBrain, locationType, 0, categories.MOBILE * categories.NAVAL * categories.TECH2)
    and UC.PoolLessAtLocation(aiBrain, locationType, 1, categories.MOBILE * categories.NAVAL * categories.TECH3) and (surfaceThreat + subThreat) > 280 then --7 Units x 40
        return true
    elseif UC.PoolLessAtLocation(aiBrain, locationType, 1, categories.MOBILE * categories.NAVAL - categories.TECH1) and (surfaceThreat + subThreat) > 42 then --7 Units x 6
        return true
    end
    return false
end

BuilderGroup {
    BuilderGroupName = 'SorianT1SeaFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'Sorian T1 Sea Sub',
        PlatoonTemplate = 'T1SeaSub',
        Priority = 500,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SBC, 'NoRushTimeCheck', { 600 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.NAVAL * categories.FACTORY * categories.TECH1 } },
            --{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, 'FACTORY NAVAL TECH3' }},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'Sorian T1 Sea Frigate',
        PlatoonTemplate = 'T1SeaFrigate',
        Priority = 500,
        BuilderType = 'Sea',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SBC, 'NoRushTimeCheck', { 600 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.NAVAL * categories.FACTORY * categories.TECH1 } },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, 'FACTORY NAVAL TECH3' }},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
    },
    Builder {
        BuilderName = 'Sorian T1 Naval Anti-Air',
        PlatoonTemplate = 'T1SeaAntiAir',
        Priority = 0,
        BuilderConditions = {
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 10, 'Air' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SBC, 'NoRushTimeCheck', { 600 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.NAVAL * categories.FACTORY * categories.TECH1 } },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, 'FACTORY NAVAL TECH3' }},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
        BuilderType = 'Sea',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT2SeaFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'Sorian T2 Naval Destroyer',
        PlatoonTemplate = 'T2SeaDestroyer',
        Priority = 600,
        BuilderType = 'Sea',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SBC, 'NoRushTimeCheck', { 600 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.NAVAL * categories.FACTORY * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
    },
    Builder {
        BuilderName = 'Sorian T2 Naval Cruiser',
        PlatoonTemplate = 'T2SeaCruiser',
        PlatoonAddBehaviors = { 'AirLandToggleSorian' },
        Priority = 600,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SBC, 'NoRushTimeCheck', { 600 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.NAVAL * categories.FACTORY * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'Sorian T2SubKiller',
        PlatoonTemplate = 'T2SubKiller',
        Priority = 600,
        BuilderType = 'Sea',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SBC, 'NoRushTimeCheck', { 600 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.NAVAL * categories.FACTORY * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
    },
    Builder {
        BuilderName = 'Sorian T2ShieldBoat',
        PlatoonTemplate = 'T2ShieldBoat',
        Priority = 600,
        BuilderType = 'Sea',
        BuilderConditions = {
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, 'SHIELD NAVAL MOBILE' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SBC, 'NoRushTimeCheck', { 600 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.NAVAL * categories.FACTORY * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
    },
    Builder {
        BuilderName = 'Sorian T2CounterIntelBoat',
        PlatoonTemplate = 'T2CounterIntelBoat',
        Priority = 0,
        BuilderType = 'Sea',
        BuilderConditions = {
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, 'COUNTERINTELLIGENCE NAVAL MOBILE' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SBC, 'NoRushTimeCheck', { 600 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.NAVAL * categories.FACTORY * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT2SeaStrikeForceBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'Sorian T2 Naval Destroyer - SF',
        PlatoonTemplate = 'T2SeaDestroyer',
        Priority = 705,
        BuilderType = 'Sea',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SBC, 'NoRushTimeCheck', { 600 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.NAVAL * categories.FACTORY * categories.TECH2 } },
            { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 1, categories.STRUCTURE * categories.DEFENSE * categories.ANTINAVY, 'Enemy'}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
    },
    Builder {
        BuilderName = 'Sorian T2 Naval Cruiser - SF',
        PlatoonTemplate = 'T2SeaCruiser',
        PlatoonAddBehaviors = { 'AirLandToggleSorian' },
        Priority = 705,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SBC, 'NoRushTimeCheck', { 600 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.NAVAL * categories.FACTORY * categories.TECH2 } },
            { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 1, categories.STRUCTURE * categories.DEFENSE * categories.ANTINAVY, 'Enemy'}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
        BuilderType = 'Sea',
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT3SeaFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'Sorian T2 Naval Destroyer - T3',
        PlatoonTemplate = 'T2SeaDestroyer',
        Priority = 700,
        BuilderType = 'Sea',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SBC, 'NoRushTimeCheck', { 600 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.NAVAL * categories.FACTORY * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
    },
    Builder {
        BuilderName = 'Sorian T2 Naval Cruiser - T3',
        PlatoonTemplate = 'T2SeaCruiser',
        PlatoonAddBehaviors = { 'AirLandToggleSorian' },
        Priority = 700,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SBC, 'NoRushTimeCheck', { 600 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.NAVAL * categories.FACTORY * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'Sorian T3 Naval Battleship',
        PlatoonTemplate = 'T3SeaBattleship',
        Priority = 700,
        BuilderType = 'Sea',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SBC, 'NoRushTimeCheck', { 600 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.NAVAL * categories.FACTORY * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
            { UCBC, 'HaveUnitRatio', { 0.1, categories.NAVAL * categories.MOBILE * categories.TECH3, '<=', categories.NAVAL * categories.MOBILE * categories.TECH2}},
        },
    },
    Builder {
        BuilderName = 'Sorian T3 Naval Nuke Sub',
        PlatoonTemplate = 'T3SeaNukeSub',
        Priority = 0, --700,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SBC, 'NoRushTimeCheck', { 600 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.NAVAL * categories.FACTORY * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
        },
        BuilderType = 'Sea',
    },
    Builder {
        BuilderName = 'Sorian T3MissileBoat',
        PlatoonTemplate = 'T3MissileBoat',
        Priority = 700,
        BuilderType = 'Sea',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SBC, 'NoRushTimeCheck', { 600 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.NAVAL * categories.FACTORY * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
            { UCBC, 'HaveUnitRatio', { 0.1, categories.NAVAL * categories.MOBILE * categories.TECH3, '<=', categories.NAVAL * categories.MOBILE * categories.TECH2}},
        },
    },
    Builder {
        BuilderName = 'Sorian T3Battlecruiser',
        PlatoonTemplate = 'T3Battlecruiser',
        Priority = 700,
        BuilderType = 'Sea',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SBC, 'NoRushTimeCheck', { 600 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.NAVAL * categories.FACTORY * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.1 }},
            { UCBC, 'HaveUnitRatio', { 0.1, categories.NAVAL * categories.MOBILE * categories.TECH3, '<=', categories.NAVAL * categories.MOBILE * categories.TECH2}},
        },
    },
}


BuilderGroup {
    BuilderGroupName = 'SorianSeaHunterFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Sorian Sea Hunters T1',
        PlatoonTemplate = 'SeaHuntSorian',
        --PlatoonAddPlans = {'DistressResponseAISorian', 'PlatoonCallForHelpAISorian'},
        PlatoonAddPlans = {'AirLandToggleSorian'},
        Priority = 10,
        InstanceCount = 2,
        BuilderType = 'Any',
        BuilderData = {
        UseFormation = 'AttackFormation',
        },
        BuilderConditions = {
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, 'MOBILE TECH2 NAVAL, MOBILE TECH3 NAVAL' } },
            { SeaAttackCondition, { 'LocationType', 20 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
    },
    Builder {
        BuilderName = 'Sorian Sea Hunters T2',
        PlatoonTemplate = 'SeaHuntSorian',
        --PlatoonAddPlans = {'DistressResponseAISorian', 'PlatoonCallForHelpAISorian'},
        PlatoonAddPlans = {'AirLandToggleSorian'},
        Priority = 10,
        InstanceCount = 2,
        BuilderType = 'Any',
        BuilderData = {
        UseFormation = 'AttackFormation',
        },
        BuilderConditions = {
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, 'MOBILE TECH3 NAVAL' } },
            { SeaAttackCondition, { 'LocationType', 60 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
    },
    Builder {
        BuilderName = 'Sorian Sea Hunters T3',
        PlatoonTemplate = 'SeaHuntSorian',
        --PlatoonAddPlans = {'DistressResponseAISorian', 'PlatoonCallForHelpAISorian'},
        PlatoonAddPlans = {'AirLandToggleSorian'},
        Priority = 10,
        InstanceCount = 2,
        BuilderType = 'Any',
        BuilderData = {
        UseFormation = 'AttackFormation',
        },
        BuilderConditions = {
            { SeaAttackCondition, { 'LocationType', 180 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
    },
    Builder {
        BuilderName = 'Sorian Sea StrikeForce T2',
        PlatoonTemplate = 'SeaStrikeSorian',
        --PlatoonAddPlans = {'DistressResponseAISorian', 'PlatoonCallForHelpAISorian'},
        PlatoonAddPlans = {'AirLandToggleSorian'},
        Priority = 100,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, 'MOBILE TECH2 NAVAL' } },
            { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 1, categories.STRUCTURE * categories.DEFENSE * categories.ANTINAVY, 'Enemy'}},
            { SeaAttackCondition, { 'LocationType', 60 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderData = {
            UseFormation = 'AttackFormation',
            SearchRadius = 6000,
            PrioritizedCategories = {
                'STRUCTURE DEFENSE ANTINAVY TECH2',
                'STRUCTURE DEFENSE ANTINAVY TECH1',
                'MOBILE NAVAL',
                'STRUCTURE NAVAL',
            },
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianFrequentSeaAttackFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Sorian Frequent Sea Attack T1',
        PlatoonTemplate = 'SeaAttackSorian',
        --PlatoonAddPlans = {'DistressResponseAISorian', 'PlatoonCallForHelpAISorian'},
        PlatoonAddPlans = {'AirLandToggleSorian'},
        Priority = 1,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderData = {
        UseFormation = 'AttackFormation',
            ThreatWeights = {
                --IgnoreStrongerTargetsRatio = 100.0,
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
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, 'MOBILE TECH2 NAVAL, MOBILE TECH3 NAVAL' } },
            { SeaAttackCondition, { 'LocationType', 20 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
    },
    Builder {
        BuilderName = 'Sorian Frequent Sea Attack T2',
        PlatoonTemplate = 'SeaAttackSorian',
        --PlatoonAddPlans = {'DistressResponseAISorian', 'PlatoonCallForHelpAISorian'},
        PlatoonAddPlans = {'AirLandToggleSorian'},
        Priority = 1,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderData = {
        UseFormation = 'AttackFormation',
            ThreatWeights = {
                --IgnoreStrongerTargetsRatio = 100.0,
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
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, 'MOBILE TECH3 NAVAL' } },
            { SeaAttackCondition, { 'LocationType', 60 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
    },
    Builder {
        BuilderName = 'Sorian Frequent Sea Attack T3',
        PlatoonTemplate = 'SeaAttackSorian',
        --PlatoonAddPlans = {'DistressResponseAISorian', 'PlatoonCallForHelpAISorian'},
        PlatoonAddPlans = {'AirLandToggleSorian'},
        Priority = 1,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderData = {
        UseFormation = 'AttackFormation',
            ThreatWeights = {
                --IgnoreStrongerTargetsRatio = 100.0,
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
            { SeaAttackCondition, { 'LocationType', 180 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianBigSeaAttackFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Sorian Big Sea Attack T1',
        PlatoonTemplate = 'SeaAttackSorian',
        --PlatoonAddPlans = {'DistressResponseAISorian', 'PlatoonCallForHelpAISorian'},
        PlatoonAddPlans = {'AirLandToggleSorian'},
        Priority = 1,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderData = {
        UseFormation = 'AttackFormation',
            ThreatWeights = {
                --IgnoreStrongerTargetsRatio = 100.0,
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
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, 'MOBILE TECH2 NAVAL, MOBILE TECH3 NAVAL' } },
            { SeaAttackCondition, { 'LocationType', 40 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
    },
    Builder {
        BuilderName = 'Sorian Big Sea Attack T2',
        PlatoonTemplate = 'SeaAttackSorian',
        --PlatoonAddPlans = {'DistressResponseAISorian', 'PlatoonCallForHelpAISorian'},
        PlatoonAddPlans = {'AirLandToggleSorian'},
        Priority = 1,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderData = {
        UseFormation = 'AttackFormation',
            ThreatWeights = {
                --IgnoreStrongerTargetsRatio = 100.0,
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
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, 'MOBILE TECH3 NAVAL' } },
            { SeaAttackCondition, { 'LocationType', 120 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
    },
    Builder {
        BuilderName = 'Sorian Big Sea Attack T3',
        PlatoonTemplate = 'SeaAttackSorian',
        --PlatoonAddPlans = {'DistressResponseAISorian', 'PlatoonCallForHelpAISorian'},
        PlatoonAddPlans = {'AirLandToggleSorian'},
        Priority = 1,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderData = {
        UseFormation = 'AttackFormation',
            ThreatWeights = {
                --IgnoreStrongerTargetsRatio = 100.0,
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
            { SBC, 'NoRushTimeCheck', { 0 }},
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianMassHunterSeaFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
}


-- kept for mod compatibility, as they may depend on these
local BBTmplFile = '/lua/basetemplates.lua'
local BuildingTmpl = 'BuildingTemplates'
local BaseTmpl = 'BaseTemplates'
local ExBaseTmpl = 'ExpansionBaseTemplates'
local Adj2x2Tmpl = 'Adjacency2x2'
local MIBC = '/lua/editor/miscbuildconditions.lua'
local MABC = '/lua/editor/markerbuildconditions.lua'
local OAUBC = '/lua/editor/otherarmyunitcountbuildconditions.lua'
local EBC = '/lua/editor/economybuildconditions.lua'
local PCBC = '/lua/editor/platooncountbuildconditions.lua'
local SAI = '/lua/scenarioplatoonai.lua'
local PlatoonFile = '/lua/platoon.lua'