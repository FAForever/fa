#***************************************************************************
#*
#**  File     :  /lua/ai/AIBaseTemplates/SorianMainWater.lua
#**  Author(s): Michael Robbins aka Sorian
#**
#**  Summary  : Manage engineers for a location
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local Random = Random
local sorianbuildconditionsUp = import('/lua/editor/SorianBuildConditions.lua')
local GetMapSize = GetMapSize
local aibrain_methodsGetArmyStartPos = moho.aibrain_methods.GetArmyStartPos

BaseBuilderTemplate {
    BaseTemplateName = 'SorianMainWater',
    Builders = {
        # ==== ECONOMY ==== #
        # Factory upgrades
        'SorianT1NavalUpgradeBuilders',
        'SorianT2NavalUpgradeBuilders',
        'SorianEmergencyUpgradeBuilders',
        'SorianMassFabPause',

        # Engineer Builders
        'SorianEngineerFactoryBuilders',
        'SorianT1EngineerBuilders',
        'SorianT2EngineerBuilders',
        'SorianT3EngineerBuilders',
        'SorianEngineerFactoryConstruction Air',
        'SorianEngineerFactoryConstruction',

        # SCU Upgrades
        'SorianSCUUpgrades',

        # Engineer Support buildings
        'SorianEngineeringSupportBuilder',

        # Build energy at this base
        'SorianEngineerEnergyBuilders',

        # Build Mass high pri at this base
        'SorianEngineerMassBuilders - Naval',

        # Extractors
        'SorianTime Exempt Extractor Upgrades',

        # ACU Builders
        'Sorian Naval Initial ACU Builders',
        'SorianACUBuilders',
        'SorianACUUpgrades',

        # ACU Defense
        'SorianT1ACUDefenses',
        'SorianT2ACUDefenses',
        'SorianT2ACUShields',
        'SorianT3ACUShields',
        'SorianT3ACUNukeDefenses',

        'SorianMassAdjacencyDefenses',

        # ==== EXPANSION ==== #
        'SorianEngineerExpansionBuildersFull - Naval',
        'SorianEngineerFirebaseBuilders',

        # ==== DEFENSES ==== #
        'SorianT1BaseDefenses',
        'SorianT2BaseDefenses',
        'SorianT3BaseDefenses',

        'SorianT1NavalDefenses',
        'SorianT2NavalDefenses',
        'SorianT3NavalDefenses',

        'SorianT2PerimeterDefenses',
        'SorianT3PerimeterDefenses',

        #'SorianT1DefensivePoints',
        #'SorianT2DefensivePoints',
        #'SorianT3DefensivePoints',

        'SorianT2ArtilleryFormBuilders',
        'SorianT3ArtilleryFormBuilders',
        'SorianT4ArtilleryFormBuilders',
        'SorianT2MissileDefenses',
        'SorianT3NukeDefenses',
        'SorianT3NukeDefenseBehaviors',
        'SorianMiscDefensesEngineerBuilders',

        # ==== NAVAL EXPANSION ==== #
        'SorianNavalExpansionBuildersFast',

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
        #'SorianT1AirFactoryBuilders',
        #'SorianT2AirFactoryBuilders',
        'SorianT3AirFactoryBuilders',
        'SorianFrequentAirAttackFormBuilders',
        'SorianMassHunterAirFormBuilders',

        'SorianUnitCapAirAttackFormBuilders',
        'SorianACUHunterAirFormBuilders',

        'SorianAntiNavyAirFormBuilders',

        'SorianTransportFactoryBuilders - Air',

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
            Land = 1,
            Air = 4,
            Sea = 0,
            Gate = 1,
        },
        MassToFactoryValues = {
            T1Value = 8, #6
            T2Value = 20, #15
            T3Value = 40, #22.5
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
            return 1, 'sorianwater'
        end

        if per != 'sorianwater' and per != 'sorianadaptive' and per != '' then
            return 1, 'sorianwater'
        end

        local mapSizeX, mapSizeZ = GetMapSize()

        local startX, startZ = aibrain_methodsGetArmyStartPos(aiBrain)
        local isIsland = sorianbuildconditionsUp.IsIslandMap(aiBrain)

        if per == 'sorianwater' then
            return 1000, 'sorianwater'
        end

        #If we're playing on an island map, do not use this plan often
        if mapSizeX < 1024 and mapSizeZ < 1024 and isIsland then
            return Random(65, 80), 'sorianwater'
        elseif mapSizeX >= 1024 and mapSizeZ >= 1024 and isIsland then
            return Random(98, 100), 'sorianwater'
        else
            return 1, 'sorianwater'
        end
    end,
}
