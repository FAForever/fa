-- File     :  /lua/ai/AIAirAttackBuilders.lua
-- Summary  : Default economic builders for skirmish
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
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
local TBC = '/lua/editor/threatbuildconditions.lua'
local PCBC = '/lua/editor/platooncountbuildconditions.lua'
local SAI = '/lua/scenarioplatoonai.lua'
local PlatoonFile = '/lua/platoon.lua'

---@alias BuilderGroupsAirAttack 'T1AirFactoryBuilders' | 'T1AntiAirBuilders' | 'T2AirFactoryBuilders' | 'T2AntiAirBuilders' | 'T3AirFactoryBuilders' | 'T3AntiAirBuilders' | 'TransportFactoryBuilders' | 'UnitCapAirAttackFormBuilders' | 'FrequentAirAttackFormBuilders' | 'BigAirAttackFormBuilders' | 'MassHunterAirFormBuilders' | 'BaseGuardAirFormBuildersNaval' | 'BaseGuardAirFormBuilders' | 'ACUHunterAirFormBuilders'

function AirAttackCondition(aiBrain, locationType, targetNumber)
    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')

    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager

    local position = engineerManager:GetLocationCoords()
    local radius = engineerManager.Radius

    local surfaceThreat = pool:GetPlatoonThreat('Surface', categories.MOBILE * categories.AIR - categories.SCOUT - categories.INTELLIGENCE, position, radius)
    local airThreat = pool:GetPlatoonThreat('Air', categories.MOBILE * categories.AIR - categories.SCOUT - categories.INTELLIGENCE, position, radius)
    if (surfaceThreat + airThreat) > targetNumber then
        return true
    end
    return false
end

BuilderGroup {
    BuilderGroupName = 'T1AirFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'T1 Air Bomber',
        PlatoonTemplate = 'T1AirBomber',
        Priority = 500,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'T1 Air Fighter',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 500,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
        },
        BuilderType = 'Air',
    },

    Builder {
        BuilderName = 'T1Gunship',
        PlatoonTemplate = 'T1Gunship',
        Priority = 500,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'T1 Air Bomber 2',
        PlatoonTemplate = 'T1AirBomber',
        Priority = 500,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'T1Gunship2',
        PlatoonTemplate = 'T1Gunship',
        Priority = 500,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'T1AntiAirBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'T1 Interceptors',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 555,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 10, categories.AIR * categories.ANTIAIR * categories.TECH1 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T1 Interceptors - Enemy air',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 560,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 15, categories.AIR * categories.ANTIAIR * categories.TECH1 } },
            { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 4, categories.MOBILE * categories.AIR - categories.SCOUT, 'Enemy'}},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T1 Interceptors - Extra Enemy air',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 560,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.AIR * categories.ANTIAIR * categories.TECH1 } },
            { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 9, categories.MOBILE * categories.AIR - categories.SCOUT, 'Enemy'}},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T1 Interceptors - Two Factories',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 500,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY * categories.AIR * categories.TECH1 } }, --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.AIR * categories.ANTIAIR * categories.TECH1 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
        },
        BuilderType = 'Air',
    },
}

BuilderGroup {
    BuilderGroupName = 'T2AirFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'T2 Air Gunship',
        PlatoonTemplate = 'T2AirGunship',
        Priority = 600,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'T2FighterBomber',
        PlatoonTemplate = 'T2FighterBomber',
        Priority = 600,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'T2 Air Gunship2',
        PlatoonTemplate = 'T2AirGunship',
        Priority = 600,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'T2FighterBomber2',
        PlatoonTemplate = 'T2FighterBomber',
        Priority = 600,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'T2 Torpedo Bomber',
        PlatoonTemplate = 'T2AirTorpedoBomber',
        Priority = 600,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 0, 'Naval', 10 } },
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'T2AntiAirBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'T1AntiAirPlanes Initial Higher Pri',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 600,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, 'AIR' } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 20, categories.AIR * categories.ANTIAIR } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T2AntiAirPlanes - Two Factories Higher Pri',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 600,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 2, 'AIR' } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 20, categories.AIR * categories.ANTIAIR } },
        },
        BuilderType = 'Air',
    },
}

BuilderGroup {
    BuilderGroupName = 'T3AirFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'T3 Air Gunship',
        PlatoonTemplate = 'T3AirGunship',
        Priority = 700,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'T3 Air Bomber',
        PlatoonTemplate = 'T3AirBomber',
        Priority = 700,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'T3 Air Gunship2',
        PlatoonTemplate = 'T3AirGunship',
        Priority = 700,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'T3 Air Bomber2',
        PlatoonTemplate = 'T3AirBomber',
        Priority = 700,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'T3 Air Fighter',
        PlatoonTemplate = 'T3AirFighter',
        Priority = 700,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T3 Torpedo Bomber',
        PlatoonTemplate = 'T3TorpedoBomber',
        Priority = 700,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 0, 'Naval', 10 } },
        },
    }
}

BuilderGroup {
    BuilderGroupName = 'T3AntiAirBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'T3AntiAirPlanes Initial',
        PlatoonTemplate = 'T3AirFighter',
        Priority = 755,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 10, categories.AIR * categories.ANTIAIR * categories.TECH3 } },  --DUNCAN - added
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T3AntiAirPlanes - Two Factories',
        PlatoonTemplate = 'T3AirFighter',
        Priority = 700,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.7, 1.05 }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 2, 'AIR' } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.AIR * categories.ANTIAIR * categories.TECH3 } }, --DUNCAN - added
        },
        BuilderType = 'Air',
    },
}

BuilderGroup {
    BuilderGroupName = 'TransportFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'T1 Air Transport - Early',
        PlatoonTemplate = 'T1AirTransport',
        Priority = 850,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'TransportRequested', {} },
            { MIBC, 'MapGreaterThan', { 256, 256 }},
            { MIBC, 'LessThanGameTime', { 600 } },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.0 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.TRANSPORTFOCUS } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.TRANSPORTFOCUS } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T1 Air Transport',
        PlatoonTemplate = 'T1AirTransport',
        Priority = 560,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'TransportRequested', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.05 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.AIR * categories.ANTIAIR } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.TRANSPORTFOCUS } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.TRANSPORTFOCUS } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T2 Air Transport',
        PlatoonTemplate = 'T2AirTransport',
        Priority = 650,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'TransportRequested', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.05 }},  --DUNCAN - was 0.9
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 10, categories.LAND * (categories.TECH2 + categories.TECH3) } }, --DUNCAN - added
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.AIR * categories.ANTIAIR } }, --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.TRANSPORTFOCUS * categories.TECH2 } }, --DUNCAN - was 25
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, categories.TRANSPORTFOCUS } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T3 Air Transport',
        PlatoonTemplate = 'T3AirTransport',
        Priority = 750,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'TransportRequested', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 10, categories.LAND * categories.TECH3 } }, --DUNCAN - added
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 10, categories.LAND *  categories.TECH3 } }, --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsWithCategory', { 4, categories.TRANSPORTFOCUS * categories.TECH2 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.TRANSPORTFOCUS * categories.TECH3 } }, --DUNCAN - was 25
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 2, categories.TRANSPORTFOCUS } },
        },
        BuilderType = 'Air',
    },

    Builder {
        BuilderName = 'T1 Air Transport Default',
        PlatoonTemplate = 'T1AirTransport',
        Priority = 500,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'TransportRequested', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.05 }},  --DUNCAN - was 0.9
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.AIR * categories.ANTIAIR } }, --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsWithCategory', { 5 , categories.TRANSPORTFOCUS} },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.TRANSPORTFOCUS } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T2 Air Transport Default',
        PlatoonTemplate = 'T2AirTransport',
        Priority = 600,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'TransportRequested', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.05 }},  --DUNCAN - was 0.9
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.TRANSPORTFOCUS } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.AIR * categories.ANTIAIR } }, --DUNCAN - added
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 8, categories.LAND * (categories.TECH2 + categories.TECH3) } }, --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3 , categories.TRANSPORTFOCUS * categories.TECH2} },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T3 Air Transport Default',
        PlatoonTemplate = 'T3AirTransport',
        Priority = 700,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'TransportRequested', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.AIR * categories.ANTIAIR } }, --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsWithCategory', { 4, categories.TRANSPORTFOCUS * categories.TECH2 } }, --DUNCAN - Added
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2 , categories.TRANSPORTFOCUS * categories.TECH3} },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 10, categories.LAND * categories.TECH3 } }, --DUNCAN - added
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.TRANSPORTFOCUS } },
        },
        BuilderType = 'Air',
    },

    Builder {
        BuilderName = 'T1 Air Transport HighNeed',
        PlatoonTemplate = 'T1AirTransport',
        Priority = 700,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'TransportRequested', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.05 }},  --DUNCAN - was 0.9
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.AIR * categories.ANTIAIR } }, --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsWithCategory', { 7, categories.TRANSPORTFOCUS * categories.TECH1 } }, --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.TRANSPORTFOCUS } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T2 Air Transport HighNeed',
        PlatoonTemplate = 'T2AirTransport',
        Priority = 800,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'TransportRequested', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.05 }},  --DUNCAN - was 0.9
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.AIR * categories.ANTIAIR } }, --DUNCAN - added
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 10, categories.LAND * (categories.TECH2 + categories.TECH3) } }, --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, categories.TRANSPORTFOCUS * categories.TECH2 } }, --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.TRANSPORTFOCUS } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T3 Air Transport HighNeed',
        PlatoonTemplate = 'T3AirTransport',
        Priority = 900,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'TransportRequested', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.05 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 5, categories.AIR * categories.ANTIAIR } }, --DUNCAN - added
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 10, categories.LAND * categories.TECH3 } }, --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsWithCategory', { 4, categories.TRANSPORTFOCUS * categories.TECH2 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.TRANSPORTFOCUS * categories.TECH3 } }, --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.TRANSPORTFOCUS } },
        },
        BuilderType = 'Air',
    },

    Builder {
        BuilderName = 'T1 Air Transport Island',
        PlatoonTemplate = 'T1AirTransport',
        Priority = 700,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'IsIsland', { true } },
            { MIBC, 'TransportRequested', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.05 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 7 , categories.TRANSPORTFOCUS * categories.TECH1} },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.TRANSPORTFOCUS } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T2 Air Transport Island',
        PlatoonTemplate = 'T2AirTransport',
        Priority = 800,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'IsIsland', { true } },
            { MIBC, 'TransportRequested', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.05 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3 , categories.TRANSPORTFOCUS * categories.TECH2} },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 10, categories.LAND * (categories.TECH2 + categories.TECH3) } }, --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.TRANSPORTFOCUS } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'T3 Air Transport Island',
        PlatoonTemplate = 'T3AirTransport',
        Priority = 900,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { MIBC, 'IsIsland', { true } },
            { MIBC, 'TransportRequested', {} },
            { EBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.05 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 4, categories.TRANSPORTFOCUS * categories.TECH2 } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 2 , categories.TRANSPORTFOCUS * categories.TECH3} },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 10, categories.LAND * categories.TECH3 } }, --DUNCAN - added
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, categories.TRANSPORTFOCUS } },
        },
        BuilderType = 'Air',
    },

}

BuilderGroup {
    BuilderGroupName = 'UnitCapAirAttackFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'Unit Cap Default Bomber Attack',
        PlatoonTemplate = 'BomberAttack',
        Priority = 1,
        InstanceCount = 10,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'UnitCapCheckGreater', { .90 } },
        },
        BuilderData = {
            PrioritizedCategories = {
                'ANTIAIR STRUCTURE',
                'MASSEXTRACTION',
                'ENERGYPRODUCTION',
                'MASSFABRICATION',
                'SHIELD',
                'DEFENSE STRUCTURE',
                'STRUCTURE',
                'COMMAND',
                'MOBILE ANTIAIR',
                'ALLUNITS',
            },
        },
    },
    Builder {
        BuilderName = 'GunshipAttackT1Cap',
        PlatoonTemplate = 'GunshipAttack',
        Priority = 100,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'UnitCapCheckGreater', { .90 } },
        },
    },
}


BuilderGroup {
    BuilderGroupName = 'FrequentAirAttackFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'BomberAttackT1Frequent',
        PlatoonTemplate = 'BomberAttack',
        Priority = 100,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderData = {
            SearchRadius = 100, --DUNCAN - was 60?
            PrioritizedCategories = {
                'ANTIAIR STRUCTURE',
                'SHIELD',
                'MASSEXTRACTION',
                'ENERGYPRODUCTION',
                'MASSFABRICATION',
                'DEFENSE STRUCTURE',
                'STRUCTURE',
                'COMMAND',
                'MOBILE ANTIAIR',
                'ALLUNITS',
            },
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.AIR * categories.MOBILE * categories.BOMBER } },
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.AIR * categories.MOBILE * (categories.TECH2 + categories.TECH3) } },
        },
    },
    Builder {
        BuilderName = 'GunshipAttackT1Frequent',
        PlatoonTemplate = 'GunshipAttack',
        Priority = 100,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.AIR * categories.MOBILE * categories.GROUNDATTACK } },
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.AIR * categories.MOBILE * ( categories.TECH2 + categories.TECH3) } },
        },
    },
    Builder {
        BuilderName = 'BomberAttackT2Frequent',
        PlatoonTemplate = 'BomberAttack',
        Priority = 100,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderData = {
            SearchRadius = 100, --DUNCAN - was 60?
            PrioritizedCategories = {
                'ANTIAIR STRUCTURE',
                'SHIELD',
                'MASSEXTRACTION',
                'ENERGYPRODUCTION',
                'MASSFABRICATION',
                'COMMAND',
                'DEFENSE STRUCTURE',
                'STRUCTURE',
                'MOBILE ANTIAIR',
                'ALLUNITS',
            },
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 3, categories.AIR * categories.MOBILE * categories.BOMBER } },
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.AIR * categories.MOBILE * categories.TECH3 } },
        },
    },
    Builder {
        BuilderName = 'GunshipAttackT2Frequent',
        PlatoonTemplate = 'GunshipAttack',
        Priority = 100,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 4, categories.AIR * categories.MOBILE * categories.GROUNDATTACK } },
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.AIR * categories.MOBILE * categories.TECH3 } },
        },
    },
    Builder {
        BuilderName = 'BomberAttackT3Frequent',
        PlatoonTemplate = 'BomberAttack',
        Priority = 100,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderData = {
            SearchRadius = 100, --DUNCAN - was 60?
            PrioritizedCategories = {
                'COMMAND',
                'ANTIAIR STRUCTURE',
                'SHIELD',
                'MASSEXTRACTION',
                'ENERGYPRODUCTION',
                'MASSFABRICATION',
                'DEFENSE STRUCTURE',
                'STRUCTURE',
                'MOBILE ANTIAIR',
                'ALLUNITS',
            },
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.AIR * categories.MOBILE * categories.BOMBER * categories.TECH3 } },
        },
    },
    Builder {
        BuilderName = 'GunshipAttackT3Frequent',
        PlatoonTemplate = 'GunshipAttack',
        Priority = 100,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, categories.AIR * categories.MOBILE * categories.GROUNDATTACK * categories.TECH3 } },
        },
    },
    Builder {
        BuilderName = 'Torpedo Bombers Frequent',
        PlatoonTemplate = 'TorpedoBomberAttack',
        Priority = 100,
        InstanceCount = 5,
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, categories.ANTINAVY * categories.AIR * categories.MOBILE } },
        },
        BuilderData = {
            PrimaryTargetThreatType = 'Naval',
            SecondaryTargetThreatType = 'AntiSub',
        },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'BigAirAttackFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'BomberAttackT1Big',
        PlatoonTemplate = 'BomberAttack',
        Priority = 100,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderData = {
            SearchRadius = 100, --DUNCAN - was 60?
            PrioritizedCategories = {
                'ANTIAIR STRUCTURE',
                'SHIELD',
                'MASSEXTRACTION',
                'ENERGYPRODUCTION',
                'MASSFABRICATION',
                'DEFENSE STRUCTURE',
                'STRUCTURE',
                'COMMAND',
                'MOBILE ANTIAIR',
                'ALLUNITS',
            },
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 9, categories.AIR * categories.MOBILE * categories.BOMBER } },
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.AIR * categories.MOBILE * (categories.TECH2 + categories.TECH3) } },
        },
    },
    Builder {
        BuilderName = 'GunshipAttackT1Big',
        PlatoonTemplate = 'GunshipAttack',
        Priority = 100,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 5, categories.AIR * categories.MOBILE * categories.GROUNDATTACK } },
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.AIR * categories.MOBILE * (categories.TECH2 + categories.TECH3) } },
        },
    },
    Builder {
        BuilderName = 'BomberAttackT2Big',
        PlatoonTemplate = 'BomberAttack',
        Priority = 100,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderData = {
            SearchRadius = 100, --DUNCAN - was 60?
            PrioritizedCategories = {
                'ANTIAIR STRUCTURE',
                'SHIELD',
                'MASSEXTRACTION',
                'ENERGYPRODUCTION',
                'MASSFABRICATION',
                'COMMAND',
                'DEFENSE STRUCTURE',
                'STRUCTURE',
                'MOBILE ANTIAIR',
                'ALLUNITS',
            },
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 8, categories.AIR * categories.MOBILE * categories.BOMBER } },
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.AIR * categories.MOBILE * categories.TECH3 } },
        },
    },
    Builder {
        BuilderName = 'GunshipAttackT2Big',
        PlatoonTemplate = 'GunshipAttack',
        Priority = 100,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 10, categories.AIR * categories.MOBILE * categories.GROUNDATTACK } },
            { UCBC, 'PoolLessAtLocation', { 'LocationType', 1, categories.AIR * categories.MOBILE * categories.TECH3 } },
        },
    },
    Builder {
        BuilderName = 'BomberAttackT3Big',
        PlatoonTemplate = 'BomberAttack',
        Priority = 100,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderData = {
            SearchRadius = 100, --DUNCAN - was 60?
            PrioritizedCategories = {
                'COMMAND',
                'ANTIAIR STRUCTURE',
                'SHIELD',
                'MASSEXTRACTION',
                'ENERGYPRODUCTION',
                'MASSFABRICATION',
                'DEFENSE STRUCTURE',
                'STRUCTURE',
                'MOBILE ANTIAIR',
                'ALLUNITS',
            },
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 3, categories.AIR * categories.MOBILE * categories.BOMBER * categories.TECH3 } },
        },
    },
    Builder {
        BuilderName = 'GunshipAttackT3 Big',
        PlatoonTemplate = 'GunshipAttack',
        Priority = 100,
        InstanceCount = 5,
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 5, categories.AIR * categories.MOBILE * categories.GROUNDATTACK * categories.TECH3 } },
        },
    },
    Builder {
        BuilderName = 'Torpedo Bombers Big',
        PlatoonTemplate = 'TorpedoBomberAttack',
        Priority = 100,
        InstanceCount = 5,
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 5, categories.ANTINAVY * categories.AIR * categories.MOBILE } },
        },
        BuilderData = {
            PrimaryTargetThreatType = 'Naval',
            SecondaryTargetThreatType = 'AntiSub',
        },
        BuilderType = 'Any',
    },
}

BuilderGroup {
    BuilderGroupName = 'MassHunterAirFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'BomberAttack Mass Hunter',
        PlatoonTemplate = 'BomberAttack',
        Priority = 100,
        InstanceCount = 2,
        BuilderType = 'Any',
        BuilderData = {
            SearchRadius = 100, --DUNCAN - was 60?
            PrioritizedCategories = {
                'ANTIAIR STRUCTURE',
                'SHIELD',
                'MASSEXTRACTION',
                'MOBILE LAND',
                'ENERGYPRODUCTION',
                'MASSFABRICATION',
                'DEFENSE STRUCTURE',
                'STRUCTURE',
                'COMMAND',
                'MOBILE ANTIAIR',
                'ALLUNITS',
            },
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 3, categories.AIR * categories.MOBILE * categories.BOMBER } },
        },
    },
    Builder {
        BuilderName = 'Mass Hunter Gunships',
        PlatoonTemplate = 'GunshipMassHunter',
        -- Commented out as the platoon doesn't exist in AILandAttackBuilders.lua
        --PlatoonTemplate = 'EarlyGameMassHuntersCategory',
        Priority = 950,
        BuilderConditions = {
                --{ MIBC, 'LessThanGameTime', { 600 } },
                --{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, categories.TECH2 * categories.MOBILE * categories.LAND - categories.ENGINEER } },
            },
        BuilderData = {
            MarkerType = 'Mass',
            MoveFirst = 'Random',
            MoveNext = 'GunshipHuntAI', 	--DUNCAN - was guardbase
            ThreatType = 'Economy', 		    -- Type of threat to use for gauging attacks
            FindHighestThreat = false, 		-- Don't find high threat targets
            MaxThreatThreshold = 140, 		-- If threat is higher than this, do not attack
            MinThreatThreshold = 50, 		-- If threat is lower than this, do not attack
            AvoidBases = true,
            AvoidBasesRadius = 75,
            AggressiveMove = true,
            AvoidClosestRadius = 50,
            GuardRadius = 200,
        },
        InstanceCount = 2,
        BuilderType = 'Any',
    },
}

-- NAVAL RUSH AIR GUARD
BuilderGroup {
    BuilderGroupName = 'BaseGuardAirFormBuildersNaval',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'AntiAirHunt Naval',
        PlatoonTemplate = 'AntiAirHunt',
        PlatoonAddBehaviors = { 'AirUnitRefit' },
        Priority = 1,
        InstanceCount = 20,
        BuilderType = 'Any',
        BuilderData = {
            NeverGuardEngineers = true,
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.AIR * categories.MOBILE * (categories.TECH1 + categories.TECH2 + categories.TECH3) * categories.ANTIAIR } },
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'BaseGuardAirFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'AntiAirHunt',
        PlatoonTemplate = 'AntiAirHunt',
        PlatoonAddBehaviors = { 'AirUnitRefit' },
        Priority = 1,
        InstanceCount = 2, --DUNCAN - was 5
        BuilderType = 'Any',
        BuilderData = {
            Location = 'LocationType',
            NeverGuardEngineers = true,
        },
        BuilderConditions = {
            --DUNCAN - was 1
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 4, categories.AIR * categories.MOBILE * (categories.TECH1 + categories.TECH2 + categories.TECH3) * categories.ANTIAIR } },
        },
    },
    Builder {
        BuilderName = 'AntiAirBaseGuard',
        PlatoonTemplate = 'AntiAirBaseGuard',
        PlatoonAddBehaviors = { 'AirUnitRefit' },
        Priority = 1,
        InstanceCount = 5, --DUNCAN - was 2
        BuilderType = 'Any',
        BuilderData = {
            NeverGuardEngineers = true,
            GuardRadius = 400,
            HomeRadius = 50,
        },
        BuilderConditions = {
            --DUNCAN - was 2
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 4, categories.AIR * categories.MOBILE * (categories.TECH1 + categories.TECH2) * categories.ANTIAIR } },
        },
    },
    Builder {
        BuilderName = 'GunshipBaseGuard',
        PlatoonTemplate = 'GunshipBaseGuard',
        Priority = 0, --DUNCAN - was 10
        InstanceCount = 2,
        BuilderType = 'Any',
        BuilderData = {
            NeverGuardEngineers = true,
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 2, categories.AIR * categories.MOBILE * (categories.TECH1 + categories.TECH2) * categories.GROUNDATTACK } },
        },
    },
    Builder {
        BuilderName = 'T3BomberEscort',
        PlatoonTemplate = 'AirEscort',
        Priority = 3,
        InstanceCount = 2,
        BuilderType = 'Any',
        BuilderData = {
            GuardCategory = categories.MOBILE * categories.AIR * categories.TECH3 * categories.BOMBER,
            LocationType = 'LocationType',
        },
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 4, categories.AIR * categories.MOBILE * (categories.TECH1 + categories.TECH2 + categories.TECH3) * categories.ANTIAIR } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MOBILE * categories.AIR * categories.TECH3 * categories.BOMBER } },
            { UCBC, 'UnitsNeedGuard', { categories.MOBILE * categories.AIR * categories.TECH3 * categories.BOMBER } },
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'ACUHunterAirFormBuilders',
    BuildersType = 'PlatoonFormBuilder',
}
