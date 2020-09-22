#***************************************************************************
#*
#**  File     :  /lua/ai/AIBaseTemplates/SorianMainBalanced.lua
#**  Author(s): Michael Robbins aka Sorian
#**
#**  Summary  : Manage engineers for a location
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'SorianMainBalanced',
    Builders = {
        # ==== ECONOMY ==== #
        # Factory upgrades
        'SorianT1BalancedUpgradeBuilders',
        'SorianT2BalancedUpgradeBuilders',
        'SorianEditSupportFactoryUpgrades',
        'SorianEditSupportFactoryUpgradesNAVY',
        'SorianEmergencyUpgradeBuilders',
        'SorianMassFabPause',

        # Engineer Builders
        'SorianEngineerFactoryBuilders',
        'SorianT1EngineerBuilders',
        'SorianT2EngineerBuilders',
        'SorianT3EngineerBuilders',
        'SorianEngineerFactoryConstruction Balance',
        'SorianEngineerFactoryConstruction',

        # SCU Upgrades
        'SorianSCUUpgrades',

        # Engineer Support buildings
        'SorianEngineeringSupportBuilder',

        # Build energy at this base
        'SorianEngineerEnergyBuilders',

        # Build Mass high pri at this base
        'SorianEngineerMassBuildersHighPri',

        # Extractors
        'SorianTime Exempt Extractor Upgrades',

        # ACU Builders
        'Sorian Initial ACU Builders',
        'SorianACUBuilders',
        'SorianACUUpgrades',

        # ACU Defense
        'SorianT1ACUDefenses',
        'SorianT2ACUDefenses',
        'SorianT2ACUShields',
        'SorianT3ACUShields',
        'SorianT3ACUNukeDefenses',

        # ==== EXPANSION ==== #
        'SorianEngineerExpansionBuildersFull',
        'SorianEngineerExpansionBuildersSmall',
        'SorianEngineerFirebaseBuilders',

        # ==== DEFENSES ==== #
        'SorianT1BaseDefenses',
        'SorianT2BaseDefenses',
        'SorianT3BaseDefenses',

        'SorianT2PerimeterDefenses',
        'SorianT3PerimeterDefenses',

        'SorianT1DefensivePoints',
        'SorianT2DefensivePoints',
        'SorianT3DefensivePoints',

        'SorianT2ArtilleryFormBuilders',
        'SorianT3ArtilleryFormBuilders',
        'SorianT4ArtilleryFormBuilders',
        'SorianT2MissileDefenses',
        'SorianT3NukeDefenses',
        'SorianT3NukeDefenseBehaviors',
        'SorianMiscDefensesEngineerBuilders',

        'SorianMassAdjacencyDefenses',

        # ==== NAVAL EXPANSION ==== #
        'SorianNavalExpansionBuilders',

        # ==== LAND UNIT BUILDERS ==== #
        'SorianT1LandFactoryBuilders',
        'SorianT2LandFactoryBuilders',
        'SorianT3LandFactoryBuilders',

        'SorianFrequentLandAttackFormBuilders',
        'SorianMassHunterLandFormBuilders',
        'SorianMiscLandFormBuilders',
        'SorianUnitCapLandAttackFormBuilders',

        'SorianT1LandAA',
        'SorianT2LandAA',
        'SorianT3LandResponseBuilders',

        'SorianT1ReactionDF',
        'SorianT2ReactionDF',
        'SorianT3ReactionDF',

        'SorianT2Shields',
        'SorianShieldUpgrades',
        'SorianT3Shields',
        'SorianEngineeringUpgrades',

        # ==== AIR UNIT BUILDERS ==== #
        'SorianT1AirFactoryBuilders',
        'SorianT2AirFactoryBuilders',
        'SorianT3AirFactoryBuilders',
        'SorianFrequentAirAttackFormBuilders',
        'SorianMassHunterAirFormBuilders',

        'SorianUnitCapAirAttackFormBuilders',
        'SorianACUHunterAirFormBuilders',

        'SorianTransportFactoryBuilders',

        'SorianExpResponseFormBuilders',

        'SorianT1AntiAirBuilders',
        'SorianT2AntiAirBuilders',
        'SorianT3AntiAirBuilders',
        'SorianBaseGuardAirFormBuilders',

        # ==== EXPERIMENTALS ==== #
        'SorianMobileLandExperimentalEngineers',
        'SorianMobileLandExperimentalForm',

        'SorianMobileAirExperimentalEngineers',
        'SorianMobileAirExperimentalForm',

        #'SorianMobileNavalExperimentalEngineers',
        #'SorianMobileNavalExperimentalForm',

        'SorianEconomicExperimentalEngineers',
        'SorianMobileExperimentalEngineersGroup',

        # ==== ARTILLERY BUILDERS ==== #
        'SorianT3ArtilleryGroup',

        'SorianExperimentalArtillery',

        'SorianNukeBuildersEngineerBuilders',
        'SorianNukeFormBuilders',

        'SorianSatelliteExperimentalEngineers',
        'SorianSatelliteExperimentalForm',

        # ======== Strategies ======== #
        'SorianHeavyAirStrategy',
        'SorianBigAirGroup',
        'SorianJesterRush',
        'SorianNukeRush',
        'SorianT3ArtyRush',
        'SorianT2ACUSnipe',
        'SorianT3FBRush',
        'SorianTeamLevelAdjustment',
        'SorianParagonStrategy',
        'Sorian Tele SCU Strategy',
        'SorianWaterMapLowLand',
        'Sorian PD Creep Strategy',
        'SorianStopNukes',
        'SorianEnemyTurtle - In Range',
        'SorianEnemyTurtle - Out of Range',
        'Sorian Excess Mass Strategy',

        # ===== Strategy Platoons ===== #
        'SorianT1BomberHighPrio',
        'SorianT2BomberHighPrio',
        'SorianT3BomberHighPrio',
        'SorianT3BomberSpecialHighPrio',
        'SorianT1GunshipHighPrio',
        'SorianT1DefensivePoints - High Prio',
        'SorianT2DefensivePoints - High Prio',

        'SorianBomberLarge',
        'SorianBomberBig',
        'SorianGunShipLarge',
        'SorianNukeBuildersHighPrio',
        'SorianT3ArtyBuildersHighPrio',
        'SorianT2FirebaseBuildersHighPrio',
        'SorianT3FBBuildersHighPrio',
        'Sorian Extractor Upgrades Strategy',
        'SorianBalancedUpgradeBuildersExpansionStrategy',
        'SorianExcessMassBuilders',
    },
    NonCheatBuilders = {
        'SorianAirScoutFactoryBuilders',
        'SorianAirScoutFormBuilders',

        'SorianLandScoutFactoryBuilders',
        'SorianLandScoutFormBuilders',

        'SorianRadarEngineerBuilders',
        'SorianRadarUpgradeBuildersMain',

        'SorianCounterIntelBuilders',
    },
    BaseSettings = {
        EngineerCount = {
            Tech1 = 15,
            Tech2 = 10,
            Tech3 = 45, #30,
            SCU = 8,
        },
        FactoryCount = {
            Land = 4,
            Air = 5,
            Sea = 0,
            Gate = 1,
        },
        MassToFactoryValues = {
            T1Value = 6, #8
            T2Value = 15, #20
            T3Value = 22.5, #27.5
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        return -1
    end,
    FirstBaseFunction = function(aiBrain)
        if not aiBrain.Sorian then
            return -1
        end
        local per = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not per then
            return 1, 'sorian'
        end

        if per != 'sorian' and per != 'sorianadaptive' and per != '' then
            return 1, 'sorian'
        end

        local mapSizeX, mapSizeZ = GetMapSize()

        local startX, startZ = aiBrain:GetArmyStartPos()
        local isIsland = import('/lua/editor/SorianBuildConditions.lua').IsIslandMap(aiBrain)

        if per == 'sorian' then
            return 1000, 'sorian'
        end

        #If we're playing on an island map, do not use this plan often
        if isIsland then
            return Random(25, 50), 'sorian'

        elseif mapSizeX > 256 and mapSizeZ > 256 and mapSizeX <= 512 and mapSizeZ <= 512 then
            return Random(75, 100), 'sorian'

        elseif mapSizeX >= 512 and mapSizeZ >= 512 and mapSizeX <= 1024 and mapSizeZ <= 1024 then
            return Random(50, 100), 'sorian'

        else
            return Random(25, 75), 'sorian'
        end
    end,
}
