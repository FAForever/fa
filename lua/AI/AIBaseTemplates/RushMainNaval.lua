--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/RushMainNaval.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'RushMainNaval',
    Builders = {
        -- ==== ECONOMY ==== --
        -- Factory upgrades
        'T1NavalUpgradeBuilders',
        'T2NavalUpgradeBuilders',

        -- Engineer Builders
        'EngineerFactoryBuilders',
        'T1EngineerBuilders',
        'T2EngineerBuilders',
        'T3EngineerBuilders',
        'EngineerFactoryConstruction',

        -- Build energy at this base
        'EngineerEnergyBuilders',

        -- Build Mass high pri at this base
        'EngineerMassBuilders - Naval',

        -- Extractors
        'Time Exempt Extractor Upgrades',

        -- ACU Builders
        'Naval Rush Initial ACU Builders',
        'ACUBuilders',
        'ACUUpgrades',
        'ACUUpgrades - Shields',

        -- ACU Defense
        'T1ACUDefenses',
        'T2ACUDefenses',
        'T2ACUShields',
        'T3ACUShields',
        'T3ACUNukeDefenses',

        -- ==== EXPANSION ==== --
        'EngineerExpansionBuildersFull - Naval',

        -- ==== DEFENSES ==== --
        'T2MissileDefenses',
        'T3NukeDefenses',
        'T3NukeDefenseBehaviors',

        -- ==== NAVAL EXPANSION ==== --
        'NavalExpansionBuilders HighPri',

        -- ==== LAND UNIT BUILDERS ==== --
        'T2LandFactoryAmphibiousBuilders', --DUNCAN - added
        'T3LandFactoryBuilders',

        'FrequentLandAttackFormBuilders',
        --'MassHunterLandFormBuilders',
        --'MiscLandFormBuilders',
        'UnitCapLandAttackFormBuilders',

        'T1LandAA',
        'T2LandAA',
        'T3LandResponseBuilders',

        'T1ReactionDF',
        'T2ReactionDF',
        'T3ReactionDF',

        'T2Shields',
        'ShieldUpgrades',
        'T3Shields',

        -- ==== AIR UNIT BUILDERS ==== --
        'T1AirFactoryBuilders', --DUNCAN - added back in
        'T2AirFactoryBuilders',
        'T3AirFactoryBuilders',
        'FrequentAirAttackFormBuilders',
        'MassHunterAirFormBuilders',

        'UnitCapAirAttackFormBuilders',
        'ACUHunterAirFormBuilders',

        'TransportFactoryBuilders',

        'T1AntiAirBuilders',
        'T2AntiAirBuilders',
        'T3AntiAirBuilders',
        'BaseGuardAirFormBuilders', --DUNCAN - was 'BaseGuardAirFormBuildersNaval'

        -- ==== EXPERIMENTALS ==== --
        'MobileLandExperimentalEngineers',
        'MobileLandExperimentalForm',

        'MobileAirExperimentalEngineers',
        'MobileAirExperimentalForm',

        'SatelliteExperimentalEngineers',
        'SatelliteExperimentalForm',

        'EconomicExperimentalEngineers',
    },
    NonCheatBuilders = {
        'AirScoutFactoryBuilders',
        'AirScoutFormBuilders',

        'LandScoutFactoryBuilders',
        'LandScoutFormBuilders',

        'RadarEngineerBuilders',
        'RadarUpgradeBuildersMain',

        'CounterIntelBuilders',
    },
    BaseSettings = {
        EngineerCount = {
            Tech1 = 15,
            Tech2 = 10,
            Tech3 = 25,
            SCU = 2,
        },
        FactoryCount = {
            Land = 1,
            Air = 3,
            Sea = 0,
            Gate = 1,
        },
        MassToFactoryValues = {
            T1Value = 5,
            T2Value = 20,
            T3Value = 40,
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        return 0
    end,
    FirstBaseFunction = function(aiBrain)
        local mapSizeX, mapSizeZ = GetMapSize()
        local startX, startZ = aiBrain:GetArmyStartPos()

        local per = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not per then
            return 1, 'rushnaval'
        end
        if per == 'rushnaval' then
            return 1000, 'rushnaval'
        end

        --DUNCAN - Add island check
        local isIsland = false
        local islandMarker = import("/lua/ai/aiutilities.lua").AIGetClosestMarkerLocation(aiBrain, 'Island', startX, startZ)
        if islandMarker then
            isIsland = true
        end

        local navalMarker = import("/lua/ai/aiutilities.lua").AIGetClosestMarkerLocation(aiBrain, 'Naval Area', startX, startZ)
        local navalExclude = import("/lua/ai/aiutilities.lua").AIGetClosestMarkerLocation(aiBrain, 'Naval Exclude', startX, startZ)
        if not navalMarker or aiBrain:GetMapWaterRatio() < .5 or navalExclude then
            return 0, 'rushnaval'
        end

        if per == 'random' then
            return Random(1,100), 'rushnaval'
        elseif per != 'rush'and per != 'adaptive' and per != '' then
            return 1, 'rushnaval'
        end

        --DUNCAN - dont use this AI on setons
        if ScenarioInfo.name =='Seton\'s Clutch' then
            return 1, 'rushnaval'
        end


        --if true then
            --return 1000, 'rushnaval'
        --end

        --If we're playing on a 256 map, naval kinda craptastic
        if mapSizeX < 500 and mapSizeZ < 500 then
            return 10, 'rushnaval'

        --If we're playing on a 512 map, possibly go rush naval
        --DUNCAN - Only go naval if islands
        elseif isIsland and mapSizeX > 500 and mapSizeZ > 500 and mapSizeX < 1000 and mapSizeZ < 1000 then
            return Random(80, 100), 'rushnaval'

        --If we're playing on a 1024 or bigger, rushing naval might work
        elseif mapSizeX > 1000 and mapSizeZ > 1000 then
            return Random(80,100), 'rushnaval'
        end
    end,
}
