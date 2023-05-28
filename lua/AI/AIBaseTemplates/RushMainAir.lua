--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/RushMainAir.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'RushMainAir',
    Builders = {
        -- ==== ECONOMY ==== --
        -- Factory upgrades
        'T1BalancedUpgradeBuilders',
        'T2BalancedUpgradeBuilders',

        -- Engineer Builders
        'EngineerFactoryBuilders',
        'T1EngineerBuilders',
        'T2EngineerBuilders',
        'T3EngineerBuilders',
        'EngineerFactoryConstruction',

        -- Engineer Support buildings
        'EngineeringSupportBuilder',

        -- Build energy at this base
        'EngineerEnergyBuilders',

        -- Build Mass high pri at this base
        'EngineerMassBuildersHighPri',

        -- Extractors
        'Time Exempt Extractor Upgrades',

        -- ACU Builders
        'Air Rush Initial ACU Builders',
        'ACUBuilders',
        'ACUUpgrades',
        'ACUUpgrades - Tech 2 Engineering',
        'ACUUpgrades - Shields',

        -- ACU Defense
        'T1ACUDefenses',
        'T2ACUDefenses',
        'T2ACUShields',
        'T3ACUShields',
        'T3ACUNukeDefenses',

        -- ==== EXPANSION ==== --
        'EngineerExpansionBuildersFull',
        'EngineerExpansionBuildersSmall',
        'EngineerFirebaseBuilders',

        -- ==== DEFENSES ==== --
        --'T1BaseDefenses',
        'T2BaseDefenses',
        'T3BaseDefenses',

        'T2MissileDefenses',
        --'T2ArtilleryFormBuilders',

        --'T1DefensivePoints',
        --'T2DefensivePoints',
        --'T3DefensivePoints',

        'T2Shields',
        'ShieldUpgrades',
        'T3Shields',

        'T3NukeDefenses',
        'T3NukeDefenseBehaviors',

        'MiscDefensesEngineerBuilders',

        -- ==== NAVAL EXPANSION ==== --
        'NavalExpansionBuilders',

        -- ==== LAND UNIT BUILDERS ==== --
        'T1LandFactoryBuilders',
        'T2LandFactoryBuilders',
        'T3LandFactoryBuilders',

        'FrequentLandAttackFormBuilders',
        'MassHunterLandFormBuilders',
        'MiscLandFormBuilders',

        'T1LandAA',
        'T2LandAA',
        'T3LandResponseBuilders',

        'T1ReactionDF',
        'T2ReactionDF',
        'T3ReactionDF',

        -- ==== AIR UNIT BUILDERS ==== --
        'T1AirFactoryBuilders',
        'T2AirFactoryBuilders',
        'T3AirFactoryBuilders',
        'BigAirAttackFormBuilders',
        'MassHunterAirFormBuilders',

        'ACUHunterAirFormBuilders',

        'TransportFactoryBuilders',

        'T1AntiAirBuilders', --DUNCAN - added back in
        'T2AntiAirBuilders',
        'T3AntiAirBuilders',
        'BaseGuardAirFormBuilders',

        -- ==== UNIT CAP BUILDERS ==== --
        'UnitCapAirAttackFormBuilders',
        'UnitCapLandAttackFormBuilders',

        -- ==== ARTILLERY BUILDERS ==== --
        'T3ArtilleryGroup',
        'T3ArtilleryFormBuilders',

        'ExperimentalArtillery',

        'NukeBuildersEngineerBuilders',
        'NukeFormBuilders',

        -- ==== EXPERIMENTALS ==== --
        --'MobileLandExperimentalEngineers',
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
            SCU = 1,
        },
        FactoryCount = {
            --DUNCAN - was 2, 10, 0, 1
            Land = 1,
            Air = 8,
            Sea = 0,
            Gate = 1,
        },
        MassToFactoryValues = {
            T1Value = 5,
            T2Value = 15,
            T3Value = 22.5
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        return 0
    end,
    FirstBaseFunction = function(aiBrain)
        local per = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not per then
            return 1, 'rushair'
        end

        if per == 'rushair' then
            return 1000, 'rushair'
        end

        --DUNCAN - dont use this AI on setons
        if ScenarioInfo.name =='Seton\'s Clutch' then
            return 1, 'rushair'
        end

        if per == 'random' then
            return Random(1,100), 'rushair'

        elseif per != 'rush'and per != 'adaptive' and per != '' then
            return 1, 'rushair'
        end

        if true then
            --return 1000, 'rushair'
        end

        local mapSizeX, mapSizeZ = GetMapSize()
        local startX, startZ = aiBrain:GetArmyStartPos()

        --DUNCAN - Add island check
        local isIsland = false
        local islandMarker = import("/lua/ai/aiutilities.lua").AIGetClosestMarkerLocation(aiBrain, 'Island', startX, startZ)
        if islandMarker then
            isIsland = true
        end

        if mapSizeX < 512 and mapSizeZ < 512 then
            return 25, 'rushair'

        elseif mapSizeX <= 512 and mapSizeZ <= 512 then
            return Random(25, 75), 'rushair'

        elseif mapSizeX <= 1024 and mapSizeZ < 1024 then
            return Random(70, 100), 'rushair'

        else
            return Random(80, 100), 'rushair'
        end
    end,
}
