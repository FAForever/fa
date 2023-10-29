--***************************************************************************
--*
--**  File     :  /lua/ai/AILandAttackBuilders.lua
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

---@alias BuilderGroupsLandAttack 'T1LandFactoryBuilders' | 'T1LandAA' | 'T1ReactionDF' | 'T2LandFactoryBuilders' | 'T2LandFactoryAmphibiousBuilders' | 'T2ReactionDF' | 'T2LandAA' | 'T3LandFactoryBuilders' | 'T3LandResponseBuilders' | 'T3ReactionDF' | 'UnitCapLandAttackFormBuilders' | 'FrequentLandAttackFormBuilders' | 'Artillery Attack' | 'FearlessFrequentLandAttackFormBuilders' | 'BigLandAttackFormBuilders' | 'MassHunterLandFormBuilders' | 'MiscLandFormBuilders'

function LandAttackCondition(aiBrain, locationType, targetNumber)
    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    if not engineerManager then
        return false
    end
    local position = engineerManager:GetLocationCoords()
    local radius = engineerManager.Radius

    local poolThreat = pool:GetPlatoonThreat('Surface', categories.MOBILE * categories.LAND - categories.SCOUT - categories.ENGINEER, position, radius)
    if poolThreat > targetNumber then
        return true
    end
    return false
end

BuilderGroup {
    BuilderGroupName = 'T1LandFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    -- Initial bots, built during early game for harrassment
    Builder {
        BuilderName = 'T1 Bot - Early Game',
        PlatoonTemplate = 'T1LandDFBot',
        Priority = 825, --DUNCAN - was 925
        BuilderConditions = {
            { MIBC, 'LessThanGameTime', { 240 } }, --DUNCAN - was 300
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 1, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) }},
            --{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, 'MOBILE LAND DIRECTFIRE' } },
            --{ EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.05 }},
            --{ IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Land',
    },
    Builder {
       BuilderName = 'T1 Bot - Gunship marines',       --DUNCAN - added for GG's
       PlatoonTemplate = 'T1LandDFBot',
       Priority = 825, --DUNCAN - was 925
       BuilderConditions = {
        { MIBC, 'LessThanGameTime', { 360 } }, --DUNCAN - was 300
        { UCBC, 'HaveLessThanUnitsWithCategory', { 8, categories.MOBILE * categories.LAND * categories.TECH1 * categories.BOT - categories.ENGINEER - categories.ANTIAIR } },
        { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.FACTORY * (categories.TECH2 + categories.TECH3) } },
        { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.TRANSPORTFOCUS * categories.TECH1 } },
        { IBC, 'BrainNotLowPowerMode', {} },
       },
       BuilderType = 'Land',
    },
    -- Priority of tanks at tech 1
    -- Won't build if economy is hurting
    Builder {
        BuilderName = 'T1 Light Tank - Tech 1',
        PlatoonTemplate = 'T1LandDFTank',
        Priority = 825,
        --Priority = 950,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 150, categories.MOBILE * categories.LAND * categories.TECH1 - categories.ENGINEER - categories.ANTIAIR } },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 1, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) }},
            --{ UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, 'MOBILE LAND DIRECTFIRE' } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.0 }},
            --{ IBC, 'BrainNotLowPowerMode', {} },
        },
        BuilderType = 'Land',
    },
    -- Priority of tanks at tech 2
    -- Won't build if economy is hurting
    Builder {
        BuilderName = 'T1 Light Tank - Tech 2',
        PlatoonTemplate = 'T1LandDFTank',
        Priority = 500,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 150, categories.MOBILE * categories.LAND * categories.TECH1 - categories.ENGINEER - categories.ANTIAIR } },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 1, categories.FACTORY * categories.LAND * categories.TECH3 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.0 }},
        },
        BuilderType = 'Land',
    },
    -- Priority of tanks at tech 3
    -- Won't build if economy is hurting
    Builder {
        BuilderName = 'T1 Light Tank - Tech 3',
        PlatoonTemplate = 'T1LandDFTank',
        Priority = 400,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 150, categories.MOBILE * categories.LAND * categories.TECH1 - categories.ENGINEER - categories.ANTIAIR  } },
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.LAND * categories.TECH3 }},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.0 }},
            { UCBC, 'UnitCapCheckLess', { .8 } }, --DUNCAN - added
        },
        BuilderType = 'Land',
    },
    -- T1 Artillery, built in a ratio to tanks before tech 3
    Builder {
        BuilderName = 'T1 Mortar',
        PlatoonTemplate = 'T1LandArtillery',
        Priority = 825,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 150, categories.MOBILE * categories.LAND * categories.TECH1 - categories.ENGINEER - categories.ANTIAIR } },
            --{ UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'INDIRECTFIRE LAND MOBILE' } },
            { UCBC, 'HaveUnitRatio', { 0.3, categories.LAND * categories.INDIRECTFIRE * categories.MOBILE - categories.BOT, '<=', categories.LAND * categories.DIRECTFIRE * categories.MOBILE}},
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 1, categories.FACTORY * categories.LAND * categories.TECH3 }},
            --{ IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.0 }},
            { UCBC, 'UnitCapCheckLess', { .8 } }, --DUNCAN - added
        },
        BuilderType = 'Land',
    },
}

------------------------------------------
-- T1 Mobile AA
------------------------------------------
BuilderGroup {
    BuilderGroupName = 'T1LandAA',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'T1 Mobile AA',
        PlatoonTemplate = 'T1LandAA',
        Priority = 500,
        BuilderConditions = {
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 1, categories.FACTORY * ( categories.TECH2 + categories.TECH3 ) }},
            { UCBC, 'HaveUnitRatio', { 0.1, categories.LAND * categories.ANTIAIR, '<=', categories.LAND * categories.DIRECTFIRE}},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.LAND * categories.ANTIAIR * categories.MOBILE } },
            --{ UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, 'ANTIAIR' } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.0 }},
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'T1 Mobile AA - Response',
        PlatoonTemplate = 'T1LandAA',
        PlatoonAddBehaviors = { 'AirLandToggle' },
        --DUNCAN - increase from 500 to 850
        Priority = 850,
        BuilderConditions = {
            { TBC, 'HaveLessThreatThanNearby', { 'LocationType', 'Air', 'Air' } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.LAND * categories.ANTIAIR * categories.MOBILE } },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 1, categories.FACTORY * categories.LAND * ( categories.TECH2 + categories.TECH3 ) }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 4, categories.FACTORY * categories.LAND * categories.TECH3 }},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.0 }},
        },
        BuilderType = 'Land',
    },
}

------------------------------------------
-- T1 Response Builder
-- Used to respond to the sight of tanks nearby
------------------------------------------
BuilderGroup {
    BuilderGroupName = 'T1ReactionDF',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'T1 Tank Enemy Nearby',
        PlatoonTemplate = 'T1LandDFTank',
        Priority = 900,
        BuilderConditions = {
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 1, categories.FACTORY * categories.LAND * ( categories.TECH2 + categories.TECH3 ) }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 150, categories.MOBILE * categories.LAND * categories.TECH1 - categories.ENGINEER - categories.ANTIAIR } },
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 0, 'Land' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.0 }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.DIRECTFIRE * categories.LAND * categories.MOBILE } },
        },
        BuilderType = 'Land',
    },
}

------------------------------------------
-- T2 Factories
------------------------------------------
BuilderGroup {
    BuilderGroupName = 'T2LandFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    -- Tech 2 Priority
    Builder {
        BuilderName = 'T2 Tank - Tech 2',
        PlatoonTemplate = 'T2LandDFTank',
        Priority = 600,
        BuilderType = 'Land',
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 150, categories.MOBILE * categories.LAND * categories.TECH2 - categories.ENGINEER - categories.ANTIAIR } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 4, categories.FACTORY * categories.LAND * categories.TECH3 }},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.00 }}, --DUNCAN - was 1.05
        },
    },
    -- Tech 3 Priority
    Builder {
        BuilderName = 'T2 Tank 2 - Tech 3',
        PlatoonTemplate = 'T2LandDFTank',
        Priority = 550,
        BuilderType = 'Land',
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 150, categories.MOBILE * categories.LAND * categories.TECH2 - categories.ENGINEER - categories.ANTIAIR } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 3, categories.FACTORY * categories.LAND * categories.TECH3 }},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
        },
    },
    -- MML's, built in a ratio to directfire units
    Builder {
        BuilderName = 'T2 MML',
        PlatoonTemplate = 'T2LandArtillery',
        Priority = 600,
        BuilderType = 'Land',
        BuilderConditions = {
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 4, categories.FACTORY * categories.LAND * categories.TECH3 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 150, categories.MOBILE * categories.LAND * categories.TECH2 - categories.ENGINEER - categories.ANTIAIR } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
            { UCBC, 'HaveUnitRatio', { 0.3, categories.LAND * categories.INDIRECTFIRE, '<=', categories.LAND * categories.DIRECTFIRE}},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.INDIRECTFIRE * categories.LAND } },
        },
    },
    -- Tech 2 priority
    Builder {
        BuilderName = 'T2AttackTank - Tech 2',
        PlatoonTemplate = 'T2AttackTank',
        Priority = 600,
        BuilderType = 'Land',
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 150, categories.MOBILE * categories.LAND * categories.TECH2 - categories.ENGINEER - categories.ANTIAIR } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 4, categories.FACTORY * categories.LAND * categories.TECH3 }},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
        },
    },
    -- Tech 3 priority
    Builder {
        BuilderName = 'T2AttackTank2 - Tech 3',
        PlatoonTemplate = 'T2AttackTank',
        Priority = 550,
        BuilderType = 'Land',
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 150, categories.MOBILE * categories.LAND * categories.TECH2 - categories.ENGINEER - categories.ANTIAIR } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 3, categories.FACTORY * categories.LAND * categories.TECH3 }},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
        },
    },
    -- Tech 2 priority
    Builder {
        BuilderName = 'T2 Amphibious Tank - Tech 2',
        PlatoonTemplate = 'T2LandAmphibious',
        Priority = 600,
        BuilderType = 'Land',
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 150, categories.MOBILE * categories.LAND * categories.TECH2 - categories.ENGINEER - categories.ANTIAIR } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 3, categories.FACTORY * categories.LAND * categories.TECH3 }},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
        },
    },
    -- Tech 3 priority
    Builder {
        BuilderName = 'T2 Amphibious Tank',
        PlatoonTemplate = 'T2LandAmphibious',
        Priority = 550,
        BuilderType = 'Land',
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 150, categories.MOBILE * categories.LAND * categories.TECH2 - categories.ENGINEER - categories.ANTIAIR  } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 4, categories.FACTORY * categories.LAND * categories.TECH3 }},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'T2MobileShields',
        PlatoonTemplate = 'T2MobileShields',
        Priority = 550,
        BuilderType = 'Land',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 4, categories.FACTORY * categories.LAND * categories.TECH3 }},
            --DUNCAN - Was 1.05 power
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.2 }},
            --DUNCAN - reduce ratio from 0.1, ratio doesnt include tech 1
            { UCBC, 'HaveUnitRatio', { 0.08, categories.LAND * categories.MOBILE * (categories.COUNTERINTELLIGENCE + (categories.SHIELD * categories.DEFENSE)) - categories.DIRECTFIRE, '<=', categories.DIRECTFIRE * categories.LAND * categories.MOBILE - categories.TECH1 }},
        },
    },
    Builder {
        BuilderName = 'T2MobileShields - T3 Factories',
        PlatoonTemplate = 'T2MobileShields',
        Priority = 550,
        BuilderType = 'Land',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 3, categories.FACTORY * categories.LAND * categories.TECH3 }},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
            --DUNCAN - reduce ratio from 0.1
            { UCBC, 'HaveUnitRatio', { 0.08, categories.LAND * categories.MOBILE * (categories.COUNTERINTELLIGENCE + (categories.SHIELD * categories.DEFENSE)) - categories.DIRECTFIRE, '<=', categories.DIRECTFIRE * categories.LAND * categories.MOBILE - categories.TECH1 }},
        },
    },
    Builder {
        BuilderName = 'T2MobileBombs',
        PlatoonTemplate = 'T2MobileBombs',
        Priority = 0,
        BuilderType = 'Land',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
            { UCBC, 'HaveUnitRatio', { 0.2, categories.LAND * categories.INDIRECTFIRE, '<=', categories.LAND * categories.DIRECTFIRE}},
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'T2LandFactoryAmphibiousBuilders',
    BuildersType = 'FactoryBuilder',
    -- Tech 2 priority
    Builder {
        BuilderName = 'T2AmphibiousTank - Tech 2',
        PlatoonTemplate = 'T2LandAmphibious',
        Priority = 600,
        BuilderType = 'Land',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, categories.FACTORY * categories.LAND * categories.TECH3 }},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
        },
    },
    -- Tech 3 priority
    Builder {
        BuilderName = 'T2AmphibiousTank',
        PlatoonTemplate = 'T2LandAmphibious',
        Priority = 550,
        BuilderType = 'Land',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, categories.FACTORY * categories.LAND * categories.TECH3 }},
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
        },
    },
}

------------------------------------------
-- T2 Response Builder
-- Used to respond to the sight of tanks nearby
------------------------------------------
BuilderGroup {
    BuilderGroupName = 'T2ReactionDF',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'T2 Tank Enemy Nearby',
        PlatoonTemplate = 'T2AttackTank',
        Priority = 925,
        BuilderConditions = {
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 1, categories.FACTORY * categories.LAND * categories.TECH3 }},
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 0, 'Land' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.DIRECTFIRE * categories.LAND * categories.MOBILE - categories.TECH1 - categories.ANTIAIR} },
        },
        BuilderType = 'Land',
    },
}

------------------------------------------
-- T2 AA
------------------------------------------
BuilderGroup {
    BuilderGroupName = 'T2LandAA',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'T2 Mobile Flak',
        PlatoonTemplate = 'T2LandAA',
        Priority = 600,
        BuilderConditions = {
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 1, categories.FACTORY * categories.LAND * categories.TECH3 }},
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 15, 'Air', 10 } },
            { UCBC, 'HaveUnitRatio', { 0.2, categories.LAND * categories.ANTIAIR, '<=', categories.LAND * categories.DIRECTFIRE}},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ANTIAIR * categories.LAND - categories.TECH1  } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.05 }},
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'T2 Mobile Flak Response',
        PlatoonTemplate = 'T2LandAA',
        Priority = 850, --DUNCAN - was 500
        BuilderConditions = {
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 1, categories.FACTORY * categories.LAND * categories.TECH3 }},
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 15, 'Air' } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ANTIAIR * categories.LAND - categories.TECH1 } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.05 }},
        },
        BuilderType = 'Land',
    },
}

------------------------------------------
-- T3 Land
------------------------------------------
BuilderGroup {
    BuilderGroupName = 'T3LandFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    -- T3 Tank
    Builder {
        BuilderName = 'T3 Siege Assault Bot',
        PlatoonTemplate = 'T3LandBot',
        Priority = 700,
        BuilderType = 'Land',
        BuilderConditions = {
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.LAND * categories.FACTORY * categories.TECH3 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.05 }},
        },
    },
    -- T3 Artilery
    Builder {
        BuilderName = 'T3 Mobile Heavy Artillery',
        PlatoonTemplate = 'T3LandArtillery',
        Priority = 700,
        BuilderType = 'Land',
        BuilderConditions = {
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.LAND * categories.FACTORY * categories.TECH3 } },
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 10, 'AntiSurface', 10 } },
            { UCBC, 'HaveUnitRatio', { 0.2, categories.LAND * categories.INDIRECTFIRE, '<=', categories.LAND * categories.DIRECTFIRE}},
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'T3 Mobile Flak',
        PlatoonTemplate = 'T3LandAA',
        Priority = 700,
        BuilderConditions = {
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.LAND * categories.FACTORY * categories.TECH3 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.05 }},
            { UCBC, 'HaveUnitRatio', { 0.1, categories.LAND * categories.INDIRECTFIRE, '<=', categories.LAND * categories.DIRECTFIRE}},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ANTIAIR * categories.LAND * categories.MOBILE - categories.TECH1 } },
            { TBC, 'HaveLessThreatThanNearby', { 'LocationType', 'Air', 'Air' } },
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'T3SniperBots',
        PlatoonTemplate = 'T3SniperBots',
        Priority = 700,
        BuilderType = 'Land',
        BuilderConditions = {
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.LAND * categories.FACTORY * categories.TECH3 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'T3ArmoredAssault',
        PlatoonTemplate = 'T3ArmoredAssault',
        Priority = 700,
        BuilderType = 'Land',
        BuilderConditions = {
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.LAND * categories.FACTORY * categories.TECH3 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.05 }}, --DUNCAN - was 0.6
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.MASSEXTRACTION * categories.TECH3 } },  --DUNCAN - Added
        },
    },
    Builder {
        BuilderName = 'T3MobileMissile',
        PlatoonTemplate = 'T3MobileMissile',
        Priority = 700,
        BuilderType = 'Land',
        BuilderConditions = {
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.LAND * categories.FACTORY * categories.TECH3 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.05 }}, --DUNCAN - was 0.6
            { UCBC, 'HaveUnitRatio', { 0.2, categories.LAND * categories.INDIRECTFIRE, '<=', categories.LAND * categories.DIRECTFIRE}},
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 10, 'AntiSurface', 10 } },
        },
    },
    Builder {
        BuilderName = 'T3MobileShields',
        PlatoonTemplate = 'T3MobileShields',
        Priority = 700,
        BuilderType = 'Land',
        BuilderConditions = {
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.LAND * categories.FACTORY * categories.TECH3 } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.05 }},
            { UCBC, 'HaveUnitRatio', { 0.1, categories.LAND * categories.MOBILE * (categories.COUNTERINTELLIGENCE + (categories.SHIELD * categories.DEFENSE)) - categories.DIRECTFIRE, '<=', categories.LAND * categories.DIRECTFIRE}},
        },
    },
}

------------------------------------------
-- T3 AA
-----------------------------------------
BuilderGroup {
    BuilderGroupName = 'T3LandResponseBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'T3 Mobile AA Response',
        PlatoonTemplate = 'T3LandAA',
        Priority = 850, --DUNCAN - was 500
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.LAND * categories.FACTORY * categories.TECH3 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ANTIAIR * categories.LAND - categories.TECH1 } },
            { TBC, 'HaveLessThreatThanNearby', { 'LocationType', 'Air', 'Air' } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.05 }},
        },
        BuilderType = 'Land',
    },
}

------------------------------------------
-- T3 Response
-----------------------------------------
BuilderGroup {
    BuilderGroupName = 'T3ReactionDF',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'T3 Assault Enemy Nearby',
        PlatoonTemplate = 'T3ArmoredAssault',
        Priority = 950,
        BuilderConditions = {
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.LAND * categories.FACTORY * categories.TECH3 } },
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 0, 'Land' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.DIRECTFIRE * categories.LAND * categories.MOBILE * categories.TECH3 } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, categories.MASSEXTRACTION * categories.TECH3 } },  --DUNCAN - Added
        },
        BuilderType = 'Land',
    },
    Builder {
        BuilderName = 'T3 SiegeBot Enemy Nearby',
        PlatoonTemplate = 'T3LandBot',
        Priority = 945,
        BuilderConditions = {
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.LAND * categories.FACTORY * categories.TECH3 } },
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 0, 'Land' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.DIRECTFIRE * categories.LAND * categories.MOBILE * categories.TECH3 } },
        },
        BuilderType = 'Land',
    },
}

-- ===================== --
--     Form Builders
-- ===================== --
BuilderGroup {
    BuilderGroupName = 'UnitCapLandAttackFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Unit Cap Default Land Attack',
        PlatoonTemplate = 'LandAttackHunt', --DUNCAN - was just land attack
        Priority = 1,
        InstanceCount = 10,
        BuilderType = 'Any',
        BuilderConditions = {
            { MIBC, 'IsIsland', { false } }, --DUNCAN - added to stop units bunching on island maps
            { UCBC, 'UnitCapCheckGreater', { .90 } },   --DUNCAN - was 95
        },
        BuilderData = {
            NeverGuardBases = true,
            NeverGuardEngineers = true,
            --UseFormation = 'AttackFormation',
            AggressiveMove = true,
            ThreatWeights = {
                IgnoreStrongerTargetsRatio = 100.0,
            },
        },
    }
}


BuilderGroup {
    BuilderGroupName = 'FrequentLandAttackFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Frequent Land Attack T1',
        PlatoonTemplate = 'LandAttackMedium',
        Priority = 1,
        InstanceCount = 12,
        BuilderType = 'Any',
        BuilderData = {
            NeverGuardBases = true,
            NeverGuardEngineers = true,
            UseFormation = 'AttackFormation',
            AggressiveMove = true,
        },
        BuilderConditions = {
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.MOBILE * categories.LAND - categories.ENGINEER - categories.TECH1 } },
            { LandAttackCondition, { 'LocationType', 20 } },
        },
    },
    Builder {
        BuilderName = 'Frequent Land Attack T2',
        PlatoonTemplate = 'LandAttackMedium',
        Priority = 1,
        InstanceCount = 13,
        BuilderType = 'Any',
        BuilderData = {
            NeverGuardBases = true,
            NeverGuardEngineers = true,
            UseFormation = 'AttackFormation',
            AggressiveMove = true,
        },
        BuilderConditions = {
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.MOBILE * categories.LAND * categories.TECH3 - categories.ENGINEER} },
            { LandAttackCondition, { 'LocationType', 50 } },
        },
    },
    Builder {
        BuilderName = 'Frequent Land Attack T3',
        PlatoonTemplate = 'LandAttackMedium',
        Priority = 1,
        InstanceCount = 13,
        BuilderType = 'Any',
        BuilderData = {
            NeverGuardBases = true,
            NeverGuardEngineers = true,
            UseFormation = 'AttackFormation',
            AggressiveMove = true,
            ThreatWeights = {
                IgnoreStrongerTargetsRatio = 2.0,
            },
        },
        BuilderConditions = {
            { LandAttackCondition, { 'LocationType', 230 } },
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'Artillery Attack',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Artillery Attack',
        PlatoonTemplate = 'ArtilleryAttack',
        Priority = 1000,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderData = {
            NeverGuardBases = true,
            NeverGuardEngineers = true,
            UseFormation = 'GrowthFormation',
            ThreatWeights = {
                --IgnoreStrongerTargetsRatio = 100.0,
                PrimaryThreatTargetType = 'Structure',
                SecondaryThreatTargetType = 'AntiSurface',
                SecondaryThreatWeight = 5,
                WeakAttackThreatWeight = 1,
                VeryNearThreatWeight = 10,
                NearThreatWeight = 5,
                MidThreatWeight = 1,
                FarThreatWeight = 1,
            },
        },
        BuilderConditions = {
            --{ UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.MOBILE * categories.LAND - categories.ENGINEER - categories.TECH1 } },
            --{ LandAttackCondition, { 'LocationType', 10 } },
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'FearlessFrequentLandAttackFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Fearless Land Attack T1',
        PlatoonTemplate = 'LandAttack',
        Priority = 1,
        InstanceCount = 15,
        BuilderType = 'Any',
        BuilderData = {
            NeverGuardBases = true,
            NeverGuardEngineers = true,
            UseFormation = 'AttackFormation',
            ThreatWeights = {
                IgnoreStrongerTargetsRatio = 100.0,
            },
        },
        BuilderConditions = {
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.MOBILE * categories.LAND - categories.ENGINEER - categories.TECH1 } },
            { LandAttackCondition, { 'LocationType', 20 } },
        },
    },
    Builder {
        BuilderName = 'Fearless Land Attack T2',
        PlatoonTemplate = 'LandAttack',
        Priority = 1,
        InstanceCount = 15,
        BuilderType = 'Any',
        BuilderData = {
            NeverGuardBases = true,
            NeverGuardEngineers = true,
            UseFormation = 'AttackFormation',
            ThreatWeights = {
                IgnoreStrongerTargetsRatio = 100.0,
            },
        },
        BuilderConditions = {
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.MOBILE * categories.LAND * categories.TECH3 - categories.ENGINEER} },
            { LandAttackCondition, { 'LocationType', 70 } },
        },
    },
    Builder {
        BuilderName = 'Fearless Land Attack T3',
        PlatoonTemplate = 'LandAttack',
        Priority = 1,
        InstanceCount = 15,
        BuilderType = 'Any',
        BuilderData = {
            NeverGuardBases = true,
            NeverGuardEngineers = true,
            UseFormation = 'AttackFormation',
            ThreatWeights = {
                IgnoreStrongerTargetsRatio = 100.0,
            },
        },
        BuilderConditions = {
            { LandAttackCondition, { 'LocationType', 230 } },
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'BigLandAttackFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Big Land Attack T1',
        PlatoonTemplate = 'LandAttackMedium', --DUNCAN - was just LandAttack
        Priority = 1,
        InstanceCount = 15,
        BuilderType = 'Any',
        BuilderData = {
            NeverGuardBases = true,
            NeverGuardEngineers = true,
            UseFormation = 'AttackFormation',
        },
        BuilderConditions = {
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.MOBILE * categories.LAND - categories.ENGINEER - categories.TECH1 } },
            { LandAttackCondition, { 'LocationType', 30 } },
        },
    },
    Builder {
        BuilderName = 'Big Land Attack T2',
        PlatoonTemplate = 'LandAttackMedium', --DUNCAN - was just LandAttack
        Priority = 1,
        InstanceCount = 15,
        BuilderType = 'Any',
        BuilderData = {
            NeverGuardBases = true,
            NeverGuardEngineers = true,
            UseFormation = 'AttackFormation',
        },
        BuilderConditions = {
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.MOBILE * categories.LAND * categories.TECH3 - categories.ENGINEER } },
            { LandAttackCondition, { 'LocationType', 150 } },
        },
    },
    Builder {
        BuilderName = 'Big Land Attack T3',
        PlatoonTemplate = 'LandAttackLarge', --DUNCAN - was just LandAttack
        Priority = 1,
        InstanceCount = 15,
        BuilderType = 'Any',
        BuilderData = {
            NeverGuardBases = true,
            NeverGuardEngineers = true,
            UseFormation = 'AttackFormation',
        },
        BuilderConditions = {
            { LandAttackCondition, { 'LocationType', 460 } },
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'MassHunterLandFormBuilders',
    BuildersType = 'PlatoonFormBuilder',

    -- Hunts for mass locations with Economic threat value of no more than 2 mass extractors
    Builder {
        BuilderName = 'Mass Hunter Early Game',
        PlatoonTemplate = 'StateMachinePlatoon',
        -- Commented out as the platoon doesn't exist in AILandAttackBuilders.lua
        --PlatoonTemplate = 'EarlyGameMassHuntersCategory',
        Priority = 950,
        BuilderConditions = {
                { MIBC, 'MapCheck', { 'Seton\'s Clutch', false } },
                { MIBC, 'LessThanGameTime', { 600 } },
                --{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.TECH2 * categories.MOBILE * categories.LAND - categories.ENGINEER } },
            },
        BuilderData = {
            StateMachine = 'AIPlatoonAdaptiveRaidBehavior',
            MarkerType = 'Mass',
            MoveFirst = 'Random',
            MoveNext = 'Threat',
            ThreatType = 'Economy', 		    -- Type of threat to use for gauging attacks
            FindHighestThreat = false, 		-- Don't find high threat targets
            MaxThreatThreshold = 140, 		-- If threat is higher than this, do not attack
            MinThreatThreshold = 50, 		-- If threat is lower than this, do not attack
            AvoidBases = true,
            AvoidBasesRadius = 75,
            --UseFormation = 'AttackFormation',
            AggressiveMove = true,
            AvoidClosestRadius = 50,
        },
        InstanceCount = 2,
        BuilderType = 'Any',
    },

    -- Mid Game Mass Hunter
    -- Used after 10, goes after mass locations of no max threat
    Builder {
        BuilderName = 'Mass Hunter Mid Game',
        PlatoonTemplate = 'StateMachinePlatoon',
        Priority = 950,
        BuilderConditions = {
                { MIBC, 'MapCheck', { 'Seton\'s Clutch', false } },
                { MIBC, 'GreaterThanGameTime', { 600 } },
                --{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.TECH2 * categories.MOBILE * categories.LAND - categories.ENGINEER } },
            },
        BuilderData = {
            StateMachine = 'AIPlatoonAdaptiveRaidBehavior',
            MarkerType = 'Mass',
            MoveFirst = 'Random',
            MoveNext = 'Threat',
            ThreatType = 'Economy', 		    -- Type of threat to use for gauging attacks
            FindHighestThreat = false, 		-- Don't find high threat targets
            MaxThreatThreshold = 9999999, 	-- If threat is higher than this, do not attack
            MinThreatThreshold = 50, 		-- If threat is lower than this, do not attack
            AvoidBases = true,
            AvoidBasesRadius = 75,
            --UseFormation = 'AttackFormation',
            AggressiveMove = true,
            AvoidClosestRadius = 50,
        },
        InstanceCount = 2,
        BuilderType = 'Any',
    },


    -- Early Game Start Location Attack
    -- Used in the first 12 minutes to attack starting location areas
    -- The platoon then stays at that location and disbands after a certain amount of time
    -- Also the platoon carries an engineer with it
    Builder {
        BuilderName = 'Start Location Attack',
        PlatoonTemplate = 'StateMachinePlatoon',
        Priority = 1000, --DUNCAN - was 960
        BuilderConditions = {
                { MIBC, 'MapCheck', { 'Seton\'s Clutch', false } },
                --{ UCBC, 'ExpansionAreaNeedsEngineer', { 'LocationType', 350, -1000, 0, 2, 'StructuresNotMex' } },
                { MIBC, 'LessThanGameTime', { 900 } },  --DUNCAN - was 720
                --{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.TECH2 * categories.MOBILE * categories.LAND - categories.ENGINEER } },
            },
        BuilderData = {
            StateMachine = 'AIPlatoonAdaptiveRaidBehavior',
            MarkerType = 'Start Location',
            MoveFirst = 'Closest',
            MoveNext = 'None', --DUNCAN - was guard base
            --ThreatType = '',
            --SelfThreat = '',
            --FindHighestThreat ='',
            --ThreatThreshold = '',
            AvoidBases = true,
            AvoidBasesRadius = 100,
            AggressiveMove = true,
            AvoidClosestRadius = 50,
            GuardTimer = 60, --DUNCAN - was 30
            --UseFormation = 'AttackFormation',
        },
        InstanceCount = 2,
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'Base Location Guard Small',
        PlatoonTemplate = 'BaseGuardSmall',
        Priority = 0, --DUNCAN - was 1000
        BuilderConditions = {
                --{ UCBC, 'ExpansionAreaNeedsEngineer', { 'LocationType', 350, -1000, 0, 2, 'StructuresNotMex' } },
                { MIBC, 'LessThanGameTime', { 720 } },
                --{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.TECH2 * categories.MOBILE * categories.LAND - categories.ENGINEER } },
            },
        BuilderData = {
            LocationType = 'LocationType',
        },
        InstanceCount = 2,
        BuilderType = 'Any',
    },

    Builder {
        BuilderName = 'Base Location Guard Medium',
        PlatoonTemplate = 'BaseGuardMedium',
        Priority =  0, --DUNCAN - was 1000
        BuilderConditions = {
                --{ UCBC, 'ExpansionAreaNeedsEngineer', { 'LocationType', 350, -1000, 0, 2, 'StructuresNotMex' } },
                { MIBC, 'GreaterThanGameTime', { 720 } },
                --{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.TECH2 * categories.MOBILE * categories.LAND - categories.ENGINEER } },
            },
        BuilderData = {
            LocationType = 'LocationType',
        },
        InstanceCount = 2,
        BuilderType = 'Any',
    },

    -- Small patrol that goes to expansion areas and attacks
    Builder {
        BuilderName = 'Expansion Area Patrol',
        PlatoonTemplate = 'StartLocationAttack2',
        Priority = 925,
        BuilderConditions = {
                { MIBC, 'LessThanGameTime', { 300 } },
                --{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.TECH2 * categories.MOBILE * categories.LAND - categories.ENGINEER } },
            },
        BuilderData = {
            MarkerType = 'Expansion Area',
            MoveFirst = 'Random',
            MoveNext = 'Random',
            --ThreatType = '',
            --SelfThreat = '',
            --FindHighestThreat ='',
            --ThreatThreshold = '',
            AvoidBases = true,
            AvoidBasesRadius = 75,
            --UseFormation = 'AttackFormation',
            AggressiveMove = true,
            AvoidClosestRadius = 50,
        },
        InstanceCount = 2,
        BuilderType = 'Any',
    },

    -- Seek and destroy
    Builder {
        BuilderName = 'T1 Hunters',
        PlatoonTemplate = 'StateMachinePlatoon',
        Priority = 990,
        InstanceCount = 2,
        BuilderType = 'Any',
        BuilderData = {
            NeverGuardBases = true,
            NeverGuardEngineers = true,
            StateMachine = 'AIPlatoonAdaptiveAttackBehavior',
        },
        BuilderConditions = {
            { MIBC, 'IsIsland', { false } }, --DUNCAN - added to stop units bunching on island maps
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.MOBILE * categories.LAND - categories.ENGINEER - categories.TECH1 } },
            { LandAttackCondition, { 'LocationType', 15 } },
        },
    },

    -- Seek and destroy
    Builder {
        BuilderName = 'T2 Hunters',
        PlatoonTemplate = 'StateMachinePlatoon',
        Priority = 990,
        InstanceCount = 2,
        BuilderType = 'Any',
        BuilderData = {
            NeverGuardBases = true,
            NeverGuardEngineers = true,
            StateMachine = 'AIPlatoonAdaptiveAttackBehavior',
        },
        BuilderConditions = {
            { MIBC, 'IsIsland', { false } }, --DUNCAN - added to stop units bunching on island maps
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.MOBILE * categories.LAND - categories.ENGINEER - categories.TECH1 } },
            { LandAttackCondition, { 'LocationType', 20 } },
        },
    },

    -- Seek and destroy
    Builder {
        BuilderName = 'T1 LAB Hunters',
        PlatoonTemplate = 'StateMachineSmallAttackPlatoon',
        Priority = 1000,
        InstanceCount = 4,
        BuilderType = 'Any',
        BuilderData = {
            NeverGuardBases = true,
            NeverGuardEngineers = true,
            StateMachine = 'AIPlatoonAdaptiveAttackBehavior',
        },
        BuilderConditions = {
            { MIBC, 'IsIsland', { false } }, --DUNCAN - added to stop units bunching on island maps
            --{ UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.MOBILE * categories.LAND - categories.ENGINEER - categories.TECH1 } },
            --{ LandAttackCondition, { 'LocationType', 10 } },
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'MiscLandFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    --DUNCAN - uncommented
    Builder {
        BuilderName = 'T1 Tanks - Engineer Guard',
        PlatoonTemplate = 'StateMachineSmallAttackPlatoon',
        Priority = 750,
        InstanceCount = 2,
        BuilderData = {
            StateMachine = 'AIPlatoonAdaptiveGuardBehavior',
            NeverGuardBases = true,
        },
        BuilderConditions = {
            { MIBC, 'IsIsland', { false } }, --DUNCAN - added to stop units bunching on island maps
            { MIBC, 'MapCheck', { 'Seton\'s Clutch', false } },
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.MOBILE * categories.LAND - categories.ENGINEER - categories.TECH1 } },
            { UCBC, 'EngineersNeedGuard', { 'LocationType' } },
        },
        BuilderType = 'Any',
    },
    --DUNCAN - added
    Builder {
        BuilderName = 'T1 Ghetto Gunship',
        PlatoonTemplate = 'GhettoMarines',
        Priority = 1000,
        InstanceCount = 4,
        BuilderType = 'Any',
        BuilderData = {
            SearchRadius = 30,
            PrioritizedCategories = {
                'MASSEXTRACTION',
                'DEFENSE STRUCTURE',
                'HYDROCARBON',
                'ENGINEER',
                'ANTIAIR STRUCTURE',
                'COMMAND',
                'ENERGYPRODUCTION TECH2',
                'ALLUNITS',
            },
        },
        BuilderConditions = {
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.TECH1 * categories.TRANSPORTFOCUS } },
        },
    },
}
