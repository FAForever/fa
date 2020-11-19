#***************************************************************************
#*
#**  File     :  /lua/ai/AIBaseTemplates/SorianMainRush.lua
#**  Author(s): Michael Robbins aka Sorian
#**
#**  Summary  : Manage engineers for a location
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'SorianMainRush',
    Builders = {
        # ==== ECONOMY ==== #
        # Factory upgrades
        'SorianT1RushUpgradeBuilders',
        'SorianT2BalancedUpgradeBuilders',
        'SorianEmergencyUpgradeBuilders',
        'SorianSupportFactoryUpgrades',
        'SorianSupportFactoryUpgradesNAVY',
        'SorianMassFabPause',

        # Engineer Builders
        'SorianEngineerFactoryBuilders - Rush',
        'SorianT1EngineerBuilders',
        'SorianT2EngineerBuilders',
        'SorianT3EngineerBuilders',
        'SorianEngineerFactoryConstructionLandHigherPriority',
        'SorianEngineerFactoryConstruction',

        # SCU Upgrades
        'SorianSCUUpgrades',

        # Engineer Support buildings
        'SorianEngineeringSupportBuilder',

        # Build energy at this base
        'SorianEngineerEnergyBuilders',

        # Build Mass high pri at this base
        #'SorianEngineerMassBuilders - Rush',
        'SorianEngineerMassBuildersHighPri',

        # Extractors
        'SorianTime Exempt Extractor Upgrades - Rush',

        # ACU Builders
        'Sorian Rush Initial ACU Builders',
        'SorianACUBuilders',
        'SorianACUUpgrades',
        'SorianACUAttack',

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
        'SorianT2BaseDefenses - Emerg',
        'SorianT3BaseDefenses - Emerg',

        'SorianT1DefensivePoints',
        'SorianT2DefensivePoints',
        #'SorianT3DefensivePoints',

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
        'SorianT1LandFactoryBuilders - Rush',
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

        'SorianTransportFactoryBuilders - Rush',

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
        'SorianParagonStrategy',
        'SorianSmallMapRush',
        'Sorian Tele SCU Strategy',
        'SorianWaterMapLowLand',
        'Sorian PD Creep Strategy',
        'SorianStopNukes',
        'SorianEnemyTurtle - In Range',
        'SorianEnemyTurtle - Out of Range',
        'Sorian Excess Mass Strategy',
        'SorianRushGunUpgrades',

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
        'SorianEngineerExpansionBuildersStrategy',
        'SorianACUUpgrades - Rush',
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
            Tech3 = 25, #15,
            SCU = 2,
        },
        FactoryCount = {
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
        return -1
    end,
    FirstBaseFunction = function(aiBrain)
        if not aiBrain.Sorian then
            return -1
        end
        local per = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not per then
            return 1, 'sorianrush'
        end

        if per != 'sorianrush' and per != 'sorianadaptive' and per != '' then
            return 1, 'sorianrush'
        end

        local mapSizeX, mapSizeZ = GetMapSize()

        local startX, startZ = aiBrain:GetArmyStartPos()
        local isIsland = import('/lua/editor/SorianBuildConditions.lua').IsIslandMap(aiBrain)

        if per == 'sorianrush' then
            return 1000, 'sorianrush'
        end

        if mapSizeX < 1024 and mapSizeZ < 1024 and isIsland then
            return Random(75, 100), 'sorianrush'

        elseif mapSizeX <= 256 and mapSizeZ <= 256 and not isIsland then
            return 100, 'sorianrush'

        elseif mapSizeX >= 256 and mapSizeZ >= 256 and mapSizeX < 1024 and mapSizeZ < 1024 then
            return Random(75, 100), 'sorianrush'

        elseif mapSizeX <= 1024 and mapSizeZ <= 1024 then
            return 50, 'sorianrush'

        else
            return 20, 'sorianrush'
        end
    end,
}
