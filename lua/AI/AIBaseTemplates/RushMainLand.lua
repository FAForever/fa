#***************************************************************************
#*
#**  File     :  /lua/ai/AIBaseTemplates/RushMainLand.lua
#**
#**  Summary  : Manage engineers for a location
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'RushMainLand',
    Builders = {
        # ==== ECONOMY ==== #
        # Factory upgrades
        'T1BalancedUpgradeBuilders',
        'T2BalancedUpgradeBuilders',

        # Engineer Builders
        'EngineerFactoryBuilders',
        'T1EngineerBuilders',
        'T2EngineerBuilders',
        'T3EngineerBuilders',
        'EngineerFactoryConstruction',
        'EngineerFactoryConstructionLandHigherPriority',

        # Engineer Support buildings
        'EngineeringSupportBuilder',

        # Build energy at this base
        'EngineerEnergyBuilders',

        # Build Mass high pri at this base
        'EngineerMassBuildersHighPri',

        # Extractors
        'Time Exempt Extractor Upgrades',

        # ACU Builders
        'Land Rush Initial ACU Builders',
        'ACUBuilders',
        'ACUUpgrades',
        'ACUUpgrades - Gun improvements',
        'ACUUpgrades - Tech 2 Engineering',
        'ACUUpgrades - Shields',

        # ACU Defense
        'T1ACUDefenses',
        'T2ACUDefenses',
        'T2ACUShields',
        'T3ACUShields',
        'T3ACUNukeDefenses',

        # ==== EXPANSION ==== #
        'EngineerExpansionBuildersFull',
        'EngineerExpansionBuildersSmall',
        #'EngineerFirebaseBuilders',

        # ==== DEFENSES ==== #
        #'T1BaseDefenses',
        'T2BaseDefenses',
        'T3BaseDefenses',

        'T2MissileDefenses',
        'T2ArtilleryFormBuilders',

        #'T1DefensivePoints',
        #'T2DefensivePoints',
        #'T3DefensivePoints',

        'T2Shields',
        'ShieldUpgrades',
        'T3Shields',

        'T3NukeDefenses',
        'T3NukeDefenseBehaviors',

        #'MiscDefensesEngineerBuilders',

        # ==== NAVAL EXPANSION ==== #
        'NavalExpansionBuilders',

        # ==== LAND UNIT BUILDERS ==== #
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

        # ==== AIR UNIT BUILDERS ==== #
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

        # ==== UNIT CAP BUILDERS ==== #
        'UnitCapAirAttackFormBuilders',
        'UnitCapLandAttackFormBuilders',

        # ==== ARTILLERY BUILDERS ==== #
        'T3ArtilleryGroup',
        'T3ArtilleryFormBuilders',

        'ExperimentalArtillery',

        'NukeBuildersEngineerBuilders',
        'NukeFormBuilders',

        # ==== EXPERIMENTALS ==== #
        'MobileLandExperimentalEngineers',
        'MobileLandExperimentalForm',

        #'MobileAirExperimentalEngineers',
        #'MobileAirExperimentalForm',

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
            #DUNCAN - Factory number tweaks, was 5, 1, 0, 1
            Land = 7,
            Air = 3,
            Sea = 0,
            Gate = 1,
        },
        MassToFactoryValues = {
            T1Value = 6,
            T2Value = 15,
            T3Value = 22.5
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        return 0
    end,
    FirstBaseFunction = function(aiBrain)
        local mapSizeX, mapSizeZ = GetMapSize()
        local startX, startZ = aiBrain:GetArmyStartPos()
        local isIsland = false
        local islandMarker = import('/lua/AI/AIUtilities.lua').AIGetClosestMarkerLocation(aiBrain, 'Island', startX, startZ)
        if islandMarker then
            isIsland = true
        end

        #If we're playing on an island map, do not use this plan
        if isIsland then
            return 0, 'rushland'
        end

        local per = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not per then
            return 1, 'rushland'
        end

        if per == 'rushland' and mapSizeX <= 512 and mapSizeZ <= 512 then
            return 1000, 'rushland'
        end

        if per == 'random' then
            return Random(1,100), 'rushland'
        elseif per != 'rush' and per != 'adaptive' and per != '' then
            return 1, 'rushland'
        end

        #DUNCAN - if this is islands then dont use land rush
        if isIsland then
            return  1, 'rushland'

        #DUNCAN - use this on 5km maps
        elseif mapSizeX <= 256 and mapSizeZ <= 256 and not isIsland then
            return 100, 'rushland'

        elseif mapSizeX >= 256 and mapSizeZ >= 256 and mapSizeX < 1024 and mapSizeZ < 1024 then
            return Random(50, 100), 'rushland'

        elseif mapSizeX <= 1024 and mapSizeZ <= 1024 then
            return 50, 'rushland'

        else
            return 20, 'rushland'
        end
    end,
}
