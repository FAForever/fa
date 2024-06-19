--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/RushMainBalanced.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'RushMainBalanced',
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
        'Balanced Rush Initial ACU Builders',
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
        'T2ArtilleryFormBuilders',

        --'T1DefensivePoints',
        --'T2DefensivePoints',
        --'T3DefensivePoints',

        'T2Shields',
        'ShieldUpgrades',
        'T3Shields',

        'T3NukeDefenses',
        'T3NukeDefenseBehaviors',

        --'MiscDefensesEngineerBuilders',

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
        'FrequentAirAttackFormBuilders',
        'MassHunterAirFormBuilders',

        'ACUHunterAirFormBuilders',

        'TransportFactoryBuilders',

        'T1AntiAirBuilders',
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

        'AeonOpticsEngineerBuilders',
        'CybranOpticsEngineerBuilders',
    },
    BaseSettings = {
        EngineerCount = {
            Tech1 = 15,
            Tech2 = 10,
            Tech3 = 25,
            SCU = 3,
        },
        FactoryCount = {
            --DUNCAN - Factory number tweaks, was 6, 4, 0, 1
            Land = 7,
            Air = 4,
            Sea = 0,
            Gate = 1,
        },
        MassToFactoryValues = {
            T1Value = 4.5,
            T2Value = 14,
            T3Value = 22.5
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        return 0
    end,
    FirstBaseFunction = function(aiBrain)
        local per = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        local mapSizeX, mapSizeZ = GetMapSize()
        local isIsland = false

        if not per then
            return 1, 'rushbalanced'
        end

        if per == 'rushland' and mapSizeX > 512 and mapSizeZ > 512 then
            return 1000, 'rushland'
        end

        if per == 'random' then
            return Random(1,100), 'rushbalanced'

        elseif per != 'rush' and per != 'adaptive' and per != '' then
            return 1, 'rushbalanced'
        end



        local startX, startZ = aiBrain:GetArmyStartPos()
        local islandMarker = import("/lua/ai/aiutilities.lua").AIGetClosestMarkerLocation(aiBrain, 'Island', startX, startZ)
        if islandMarker then
            isIsland = true
        end

        if true then
            --return 1000, 'rushbalanced'
        end

        --If we're playing on an island map, do not use this plan often
        if isIsland then
            return Random(25, 50), 'rushbalanced'

        --DUNCAN - Dont use balanced on small 5km maps
        elseif mapSizeX > 256 and mapSizeZ > 256 and mapSizeX <= 512 and mapSizeZ <= 512 then
            return Random(75, 100), 'rushbalanced'

        elseif mapSizeX >= 512 and mapSizeZ >= 512 and mapSizeX <= 1024 and mapSizeZ <= 1024 then
            return Random(50, 100), 'rushbalanced'

        else
            return Random(25, 75), 'rushbalanced'
        end
    end,
}
