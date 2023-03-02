------------------------------------------------------------------------------
----
----  File     :  /lua/platoontemplates.lua
----
----  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------

EngineerFormTemplates = {
    CommanderAssist={
        "CommanderAssist",
        "EngineerAssistAI",
        { categories.COMMAND, 1, 1, "support", "None" }
    },
    CommanderBuilder={
        "CommanderBuilder",
        "EngineerBuildAI",
        { categories.COMMAND, 1, 1, "support", "None" }
    },
    CommanderEnhance={
        "CommanderEnhance",
        "EnhanceAI",
        { categories.COMMAND, 1, 1, "support", "None" }
    },
    Engineer={
        "Engineer",
        "EngineerBuildAI",
        { categories.ENGINEER * categories.TECH1, 1, 3, "support", "None" }
    },
    EngineerAssist={
        "EngineerAssist",
        "EngineerAssistAI",
        { categories.ENGINEER * categories.TECH1, 1, 1, "support", "None" }
    },
    EngineerBuilder={
        "EngineerBuilder",
        "EngineerBuildAI",
        { categories.ENGINEER * categories.TECH1, 1, 3, "support", "None" }
    },
    T2Engineer={
        "T2Engineer",
        "EngineerBuildAI",
        { categories.ENGINEER * categories.TECH2, 1, 3, "support", "None" }
    },
    T2EngineerAssist={
        "T2EngineerAssist",
        "EngineerAssistAI",
        { categories.ENGINEER * categories.TECH2, 1, 2, "support", "None" }
    },
    T2EngineerBuilder={
        "T2EngineerBuilder",
        "EngineerBuildAI",
        { categories.ENGINEER * categories.TECH2, 1, 3, "support", "None" }
    },
    T3Engineer={
        "T3Engineer",
        "EngineerBuildAI",
        { categories.ENGINEER * categories.TECH3 + categories.SUBCOMMANDER, 1, 3, "support", "None" }
    },
    T3EngineerAssist={
        "T3EngineerAssist",
        "EngineerAssistAI",
        { categories.ENGINEER * categories.TECH3 + categories.SUBCOMMANDER, 1, 3, "support", "None" }
    },
    T3EngineerBuilder={
        "T3EngineerBuilder",
        "EngineerBuildAI",
        { categories.ENGINEER * categories.TECH3 + categories.SUBCOMMANDER, 1, 3, "support", "None" }
    },
}

EngineerBuildTemplates = {
    -- UEF
    {
        EngineerOnlyBuild={
            "EngineerOnlyBuild",
            "DisbandAI",
            { "uel0105", -1, 1, "support", "None" }
        },
        EngineerOnlyBuild3={
            "EngineerOnlyBuild3",
            "DisbandAI",
            { "uel0105", -1, 1, "support", "None" }
        },
        T2EngineerOnlyBuild={
            "T2EngineerOnlyBuild",
            "DisbandAI",
            { "uel0208", -1, 1, "support", "None" }
        },
        T3EngineerOnlyBuild={
            "T3EngineerOnlyBuild",
            "DisbandAI",
            { "uel0309", -1, 1, "support", "None" }
        },
        T3EngineerOnlyBuild2={
            "T3EngineerOnlyBuild2",
            "DisbandAI",
            { "uel0309", -1, 1, "support", "None" }
        },
    },
    -- Aeon
    {
        EngineerOnlyBuild={
            "EngineerOnlyBuild",
            "DisbandAI",
            { "ual0105", -1, 1, "support", "None" }
        },
        EngineerOnlyBuild3={
            "EngineerOnlyBuild3",
            "DisbandAI",
            { "ual0105", -1, 1, "support", "None" }
        },
        T2EngineerOnlyBuild={
            "T2EngineerOnlyBuild",
            "DisbandAI",
            { "ual0208", -1, 1, "support", "None" }
        },
        T3EngineerOnlyBuild={
            "T3EngineerOnlyBuild",
            "DisbandAI",
            { "ual0309", -1, 1, "support", "None" }
        },
        T3EngineerOnlyBuild2={
            "T3EngineerOnlyBuild2",
            "DisbandAI",
            { "ual0309", -1, 1, "support", "None" }
        },
    },
    -- Cybran
    {
        EngineerOnlyBuild={
            "EngineerOnlyBuild",
            "DisbandAI",
            { "url0105", -1, 1, "support", "None" }
        },
        EngineerOnlyBuild3={
            "EngineerOnlyBuild3",
            "DisbandAI",
            { "url0105", -1, 1, "support", "None" }
        },
        T2EngineerOnlyBuild={
            "T2EngineerOnlyBuild",
            "DisbandAI",
            { "url0208", -1, 1, "support", "None" }
        },
        T3EngineerOnlyBuild={
            "T3EngineerOnlyBuild",
            "DisbandAI",
            { "url0309", -1, 1, "support", "None" }
        },
        T3EngineerOnlyBuild2={
            "T3EngineerOnlyBuild2",
            "DisbandAI",
            { "url0309", -1, 1, "support", "None" }
        },
    },
    -- Seraphim
    {
        EngineerOnlyBuild={
            "EngineerOnlyBuild",
            "DisbandAI",
            { "xsl0105", -1, 1, "support", "None" }
        },
        EngineerOnlyBuild3={
            "EngineerOnlyBuild3",
            "DisbandAI",
            { "xsl0105", -1, 1, "support", "None" }
        },
        T2EngineerOnlyBuild={
            "T2EngineerOnlyBuild",
            "DisbandAI",
            { "xsl0208", -1, 1, "support", "None" }
        },
        T3EngineerOnlyBuild={
            "T3EngineerOnlyBuild",
            "DisbandAI",
            { "xsl0309", -1, 1, "support", "None" }
        },
        T3EngineerOnlyBuild2={
            "T3EngineerOnlyBuild2",
            "DisbandAI",
            { "xsl0309", -1, 1, "support", "None" }
        },
    },
}

PlatoonTemplates = {
    -- UEF templates
    {
        AirAttack = {
            "AirAttack",
            "AttackForceAI",
            { categories.MOBILE * categories.AIR - categories.EXPERIMENTAL, 1, 100, "Attack", "GrowthFormation" }
        },
        AirAttackHunt = {
            "AirAttackHunt",
            "HuntAI",
            { categories.MOBILE * categories.AIR - categories.EXPERIMENTAL, 1, 100, "Attack", "GrowthFormation" }
        },
        LandAttack = {
            "LandAttack",
            "AttackForceAI",
            { categories.MOBILE * categories.LAND - ( categories.EXPERIMENTAL + categories.ENGINEER ), 1, 100, "Attack", "GrowthFormation" }
        },
        LandAttackHunt = {
            "LandAttackHunt",
            "HuntAI",
            { categories.MOBILE * categories.LAND - ( categories.EXPERIMENTAL + categories.ENGINEER ), 1, 100, "Attack", "GrowthFormation" }
        },
        SeaAttack = {
            "SeaAttack",
            "AttackForceAI",
            { categories.MOBILE * categories.NAVAL - categories.EXPERIMENTAL, 1, 100, "Attack", "GrowthFormation" }
        },
        CommanderAssist={
            "CommanderAssist",
            "EngineerAssistAI",
            { categories.COMMAND, 1, 1, "support", "None" }
        },
        CommanderBuilder={
            "CommanderBuilder",
            "EngineerBuildAI",
            { categories.COMMAND, 1, 1, "support", "None" }
        },
        CommanderEnhance={
            "CommanderEnhance",
            "EnhanceAI",
            { categories.COMMAND, 1, 1, "support", "None" }
        },
        Engineer={
            "Engineer",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH1, 1, 3, "support", "None" }
        },
        EngineerAssist={
            "EngineerAssist",
            "EngineerAssistAI",
            { categories.ENGINEER * categories.TECH1, 1, 1, "support", "None" }
        },
        EngineerBuilder={
            "EngineerBuilder",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH1, 1, 3, "support", "None" }
        },
        EngineerGenericSingle={
            "EngineerGenericSingle",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH1, 1, 1, "support", "None" }
        },
        EngineerOnlyBuild={
            "EngineerOnlyBuild",
            "DisbandAI",
            { "uel0105", 1, 5, "support", "None" }
        },
        EngineerOnlyBuild3={
            "EngineerOnlyBuild3",
            "DisbandAI",
            { "uel0105", 3, 3, "support", "None" }
        },
        T1AirBomber1={
            "T1AirBomber1",
            "HuntAI",
            { "uea0103", 2, 5, "attack", "GrowthFormation" }
        },
        T1AirBomber2={
            "T1AirBomber2",
            "HuntAI",
            { "uea0103", -1, 5, "attack", "GrowthFormation" }
        },
        T1AirFactoryUpgrade={
            "T1AirFactoryUpgrade",
            "UnitUpgradeAI",
            { "ueb0102", 1, 1, "support", "None" }
        },
        T1AirFighter1={
            "T1AirFighter1",
            "PatrolBaseVectorsAI",
            { "uea0102", 2, 5, "attack", "GrowthFormation" }
        },
        T1AirScout1={
            "T1AirScout1",
            "ScoutingAI",
            { "uea0101", 1, 1, "scout", "GrowthFormation" }
        },
        T1AirTransport1={
            "T1AirTransport1",
            "DisbandAI",
            { "uea0107", -1, 1, "support", "GrowthFormation" }
        },
        T1EngineerGuard={
            "T1EngineerGuard",
            "None",
            { "uel0106", 1, 5, "guard", "GrowthFormation" }
        },
        T1LandAA1={
            "T1LandAA1",
            "PatrolBaseVectorsAI",
            { "uel0104", 2, 5, "Attack", "GrowthFormation" }
        },
        T1LandAA2={
            "T1LandAA2",
            "PatrolBaseVectorsAI",
            { "uel0104", -1, 5, "Attack", "GrowthFormation" }
        },
        T1LandArtillery1={
            "T1LandArtillery1",
            "PatrolBaseVectorsAI",
            { "uel0103", 2, 7, "Attack", "GrowthFormation" }
        },
        T1LandArtillery2={
            "T1LandArtillery2",
            "PatrolBaseVectorsAI",
            { "uel0103", -1, 7, "Attack", "GrowthFormation" }
        },
        T1LandArtilleryScout1={
            "T1LandArtilleryScout1",
            "PatrolBaseVectorsAI",
            { "uel0101", 1, 1, "attack", "GrowthFormation" },
            { "uel0103", 2, 7, "Attack", "GrowthFormation" }
        },
        T1LandArtilleryScout2={
            "T1LandArtilleryScout2",
            "PatrolBaseVectorsAI",
            { "uel0101", 1, 1, "attack", "GrowthFormation" },
            { "uel0103", -1, 7, "Attack", "GrowthFormation" }
        },
        T1LandDFBot1={
            "T1LandDFBot1",
            "PatrolBaseVectorsAI",
            { "uel0106", 2, 10, "attack", "GrowthFormation" }
        },
        T1LandDFBot2={
            "T1LandDFBot2",
            "PatrolBaseVectorsAI",
            { "uel0201", -1, 10, "attack", "GrowthFormation" }
        },
        T1LandDFTank1={
            "T1LandDFTank1",
            "PatrolBaseVectorsAI",
            { "uel0201", 2, 10, "attack", "GrowthFormation" }
        },
        T1LandDFTank2={
            "T1LandDFTank2",
            "PatrolBaseVectorsAI",
            { "uel0201", -1, 10, "attack", "GrowthFormation" }
        },
        T1LandFactoryInfiniteBuild={
            "T1LandFactoryInfiniteBuild",
            "LandFactoryInfiniteBuild",
            { "ueb0101", 1, 1, "support", "None" }
        },
        T1LandFactoryUpgrade={
            "T1LandFactoryUpgrade",
            "UnitUpgradeAI",
            { "ueb0101", 1, 1, "support", "None" }
        },
        T1LandScout1={
            "T1LandScout1",
            "ScoutingAI",
            { "uel0101", 1, 1, "scout", "GrowthFormation" }
        },
        T1MassExtractorUpgrade={
            "T1MassExtractorUpgrade",
            "UnitUpgradeAI",
            { "ueb1103", 1, 1, "support", "None" }
        },
        T1MassFabricator={
            "T1MassFabricator",
            "PauseAI",
            { "ueb1104", 1, 1, "support", "None" }
        },
        T1MassHunters={
            "T1MassHunters",
            "PatrolBaseVectorsAI",
            { "uel0101", 1, 1, "attack", "GrowthFormation" },
            { "uel0201", 2, 4, "attack", "GrowthFormation" }
        },
        MassHuntersCategory={
            'MassHuntersCategory',
            'AttackForceAI',
            { categories.LAND * categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT, 1, 8, 'attack', 'GrowthFormation' },
            { categories.LAND * categories.SCOUT, 0, 1, 'attack', 'GrowthFormation' },
        },
        MassHuntersCategoryHunt={
            'MassHuntersCategoryHunt',
            'HuntAI',
            { categories.LAND * categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT, 1, 8, 'attack', 'GrowthFormation' },
            { categories.LAND * categories.SCOUT, 0, 1, 'attack', 'GrowthFormation' },
        },
        T1RadarUpgrade={
            "T1RadarUpgrade",
            "UnitUpgradeAI",
            { "ueb3101", 1, 1, "support", "None" }
        },
        T1SeaFactoryUpgrade={
            "T1SeaFactoryUpgrade",
            "UnitUpgradeAI",
            { "ueb0103", 1, 1, "support", "None" }
        },
        T1SeaFrigate1={
            "T1SeaFrigate1",
            "AttackForceAI",
            { "ues0103", -1, 3, "attack", "GrowthFormation" }
        },
        T1SeaFrigate2={
            "T1SeaFrigate2",
            "AttackForceAI",
            { "ues0103", -1, 3, "attack", "GrowthFormation" }
        },
        T1SeaSub1={
            "T1SeaSub1",
            "AttackForceAI",
            { "ues0203", -1, 3, "attack", "GrowthFormation" }
        },
        T1SonarUpgrade={
            "T1SonarUpgrade",
            "UnitUpgradeAI",
            { "ueb3102", 1, 1, "support", "None" }
        },
        T2AirFactoryInfiniteBuild={
            "T2AirFactoryInfiniteBuild",
            "FactoryInfiniteBuild",
            { "ueb0202", 1, 1, "support", "None" }
        },
        T2AirFactoryUpgrade={
            "T2AirFactoryUpgrade",
            "UnitUpgradeAI",
            { "ueb0202", 1, 1, "support", "None" }
        },
        T2AirGunship1={
            "T2AirGunship1",
            "HuntAI",
            { "uea0203", 2, 5, "attack", "GrowthFormation" }
        },
        T2AirGunship2={
            "T2AirGunship2",
            "HuntAI",
            { "uea0203", -1, 5, "attack", "GrowthFormation" }
        },
        T2AirTorpedoBomber1={
            "T2AirTorpedoBomber1",
            "HuntAI",
            { "uea0204", 2, 5, "attack", "GrowthFormation" }
        },
        T2AirTransport1={
            "T2AirTransport1",
            "DisbandAI",
            { "uea0104", -1, 1, "support", "GrowthFormation" },
            { "uea0107", -1, 1, "support", "GrowthFormation" }
        },
        T2ArtilleryStructure={
            "T2ArtilleryStructure",
            "ArtilleryAI",
            { "ueb2303", 1, 1, "artillery", "None" }
        },
        T2Engineer={
            "T2Engineer",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH2, 1, 3, "support", "None" }
        },
        T2EngineerAssist={
            "T2EngineerAssist",
            "EngineerAssistAI",
            { categories.ENGINEER * categories.TECH2, 1, 2, "support", "None" }
        },
        T2EngineerBuilder={
            "T2EngineerBuilder",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH2, 1, 3, "support", "None" }
        },
        T2EngineerGenericSingle={
            "T2EngineerGenericSingle",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH2, 1, 1, "support", "None" }
        },
        T2EngineerOnlyBuild={
            "T2EngineerOnlyBuild",
            "DisbandAI",
            { "uel0208", 1, 5, "support", "None" }
        },
        T2LandAA1={
            "T2LandAA1",
            "PatrolBaseVectorsAI",
            { "uel0205", 1, 3, "attack", "GrowthFormation" }
        },
        T2LandAA2={
            "T2LandAA2",
            "PatrolBaseVectorsAI",
            { "uel0205", -1, 3, "attack", "GrowthFormation" }
        },
        T2LandAmphibious1={
            "T2LandAmphibious1",
            "PatrolBaseVectorsAI",
            { "uel0203", 1, 4, "attack", "GrowthFormation" }
        },
        T2LandAmphibious2={
            "T2LandAmphibious2",
            "PatrolBaseVectorsAI",
            { "uel0203", -1, 4, "attack", "GrowthFormation" }
        },
        T2LandArtillery1={
            "T2LandArtillery1",
            "PatrolBaseVectorsAI",
            { "uel0111", 1, 3, "artillery", "GrowthFormation" },
            { "uel0101", 1, 1, "artillery", "GrowthFormation" },
            { "uel0307", 1, 1, "artillery", "GrowthFormation" }
        },
        T2LandArtillery2={
            "T2LandArtillery2",
            "PatrolBaseVectorsAI",
            { "uel0111", -1, 3, "artillery", "GrowthFormation" },
            { "uel0101", 1, 1, "artillery", "GrowthFormation" },
            { "uel0201", -1, 10, "attack", "GrowthFormation" },
            { "uel0307", 1, 1, "artillery", "GrowthFormation" }
        },
        T2LandDFTank1={
            "T2LandDFTank1",
            "PatrolBaseVectorsAI",
            { "uel0202", 1, 4, "attack", "GrowthFormation" },
            { "uel0201", 2, 10, "attack", "GrowthFormation" }
        },
        T2LandDFTank2={
            "T2LandDFTank2",
            "PatrolBaseVectorsAI",
            { "uel0202", -1, 4, "attack", "GrowthFormation" },
            { "uel0201", -1, 10, "attack", "GrowthFormation" }
        },
        T2LandFactoryUpgrade={
            "T2LandFactoryUpgrade",
            "UnitUpgradeAI",
            { "ueb0201", 1, 1, "support", "None" }
        },
        T2MassExtractorUpgrade={
            "T2MassExtractorUpgrade",
            "UnitUpgradeAI",
            { "ueb1202", 1, 1, "support", "None" }
        },
        T2MobileShield1={
            "T2MobileShield1",
            "PatrolBaseVectorsAI",
            { "uel0307", 1, 1, "support", "GrowthFormation" }
        },
        T2RadarUpgrade={
            "T2RadarUpgrade",
            "UnitUpgradeAI",
            { "ueb3201", 1, 1, "support", "None" }
        },
        T2SeaCruiser1={
            "T2SeaCruiser1",
            "AttackForceAI",
            { "ues0202", -1, 2, "attack", "GrowthFormation" }
        },
        T2SeaDestroyer1={
            "T2SeaDestroyer1",
            "AttackForceAI",
            { "ues0201", -1, 2, "attack", "GrowthFormation" }
        },
        T2SeaFactoryUpgrade={
            "T2SeaFactoryUpgrade",
            "UnitUpgradeAI",
            { "ueb0203", 1, 1, "support", "None" }
        },
        T2Shield={
            "T2Shield",
            "UnitUpgradeAI",
            { "ueb4202", 1, 1, "support", "None" }
        },
        T2Shield1={
            "T2Shield1",
            "UnitUpgradeAI",
            { "ueb4202", 1, 1, "support", "None" }
        },
        T2Shield2={
            "T2Shield2",
            "UnitUpgradeAI",
            { "ueb4202", 1, 1, "support", "None" }
        },
        T2Shield3={
            "T2Shield3",
            "UnitUpgradeAI",
            { "ueb4202", 1, 1, "support", "None" }
        },
        T2Shield4={
            "T2Shield4",
            "UnitUpgradeAI",
            { "ueb4202", 1, 1, "support", "None" }
        },
        T2SonarUpgrade={
            "T2SonarUpgrade",
            "UnitUpgradeAI",
            { "ueb3202", 1, 1, "support", "None" }
        },
        T2TacticalLauncher={
            "T2TacticalLauncher",
            "TacticalAI",
            { "ueb2108", 1, 1, "attack", "None" }
        },
        T3AirBomber1={
            "T3AirBomber1",
            "HuntAI",
            { "uea0304", 2, 5, "attack", "GrowthFormation" }
        },
        T3AirBomber2={
            "T3AirBomber2",
            "HuntAI",
            { "uea0304", -1, 5, "attack", "GrowthFormation" }
        },
        T3AirFighter1={
            "T3AirFighter1",
            "PatrolBaseVectorsAI",
            { "uea0303", 2, 5, "attack", "GrowthFormation" }
        },
        T3AirGunship1={
            "T3AirGunship1",
            "HuntAI",
            { "uea0305", 2, 5, "attack", "GrowthFormation" }
        },
        T3AirGunship2={
            "T3AirGunship2",
            "HuntAI",
            { "uea0305", -1, 5, "attack", "GrowthFormation" }
        },
        T3AirScout1={
            "T3AirScout1",
            "ScoutingAI",
            { "uea0302", 1, 1, "scout", "GrowthFormation" }
        },
        T3AntiNuke={
            "T3AntiNuke",
            "AntiNukeAI",
            { "ueb4302", 1, 1, "attack", "None" }
        },
        T3ArtilleryStructure={
            "T3ArtilleryStructure",
            "ArtilleryAI",
            { "ueb2302", 1, 1, "artillery", "None" }
        },
        T3Engineer={
            "T3Engineer",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH3, 1, 3, "support", "None" }
        },
        T3EngineerAssist={
            "T3EngineerAssist",
            "EngineerAssistAI",
            { categories.ENGINEER * categories.TECH3, 1, 3, "support", "None" }
        },
        T3EngineerBuilder={
            "T3EngineerBuilder",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH3, 1, 3, "support", "None" }
        },
        T3EngineerBuilderBig={
            "T3EngineerBuilderBig",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH3, 1, 6, "support", "None" }
        },
        T3EngineerGenericSingle={
            "T3EngineerGenericSingle",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH3, 1, 1, "support", "None" }
        },
        T3EngineerOnlyBuild={
            "T3EngineerOnlyBuild",
            "DisbandAI",
            { "uel0309", 1, 6, "support", "None" }
        },
        T3EngineerOnlyBuild2={
            "T3EngineerOnlyBuild2",
            "DisbandAI",
            { "uel0309", -1, 6, "support", "None" }
        },
        T3LandAA1={
            "T3LandAA1",
            "PatrolBaseVectorsAI",
            { "delk002", 1, 3, "attack", "GrowthFormation" }
        },
        T3LandAA2={
            "T3LandAA2",
            "PatrolBaseVectorsAI",
            { "delk002", -1, 3, "attack", "GrowthFormation" }
        },
        T3LandArtillery1={
            "T3LandArtillery1",
            "PatrolBaseVectorsAI",
            { "uel0304", 1, 2, "artillery", "GrowthFormation" },
            { "uel0307", 1, 1, "artillery", "GrowthFormation" }
        },
        T3LandArtillery2={
            "T3LandArtillery2",
            "PatrolBaseVectorsAI",
            { "uel0304", -1, 2, "artillery", "GrowthFormation" },
            { "uel0201", -1, 10, "attack", "GrowthFormation" },
            { "uel0307", 1, 1, "artillery", "GrowthFormation" }
        },
        T3LandBot1={
            "T3LandBot1",
            "PatrolBaseVectorsAI",
            { "uel0303", 1, 3, "attack", "GrowthFormation" },
            { "uel0201", 2, 10, "attack", "GrowthFormation" }
        },
        T3LandBot2={
            "T3LandBot2",
            "PatrolBaseVectorsAI",
            { "uel0303", -1, 3, "attack", "GrowthFormation" },
            { "uel0201", -1, 10, "attack", "GrowthFormation" }
        },
        T3LandSubCommander1={
            "T3LandSubCommander1",
            "HuntAI",
            { "uel0301", 3, 3, "support", "GrowthFormation" }
        },
        T3MassFabricator={
            "T3MassFabricator",
            "PauseAI",
            { "ueb1303", 1, 1, "support", "None" }
        },
        T3Nuke={
            "T3Nuke",
            "NukeAI",
            { "ueb2305", 1, 1, "attack", "None" }
        },
        T3SeaBattleship1={
            "T3SeaBattleship1",
            "AttackForceAI",
            { "ues0302", -1, 1, "attack", "GrowthFormation" }
        },
        T3SeaCarrier1={
            "T3SeaCarrier1",
            "AttackForceAI",
            { "ues0401", -1, 1, "attack", "GrowthFormation" }
        },
        T3SeaNukeSub1={
            "T3SeaNukeSub1",
            "NukeAI",
            { "ues0304", -1, 1, "attack", "GrowthFormation" }
        },
        T4ArtilleryStructure={
            "T4ArtilleryStructure",
            "ArtilleryAI",
            { "ueb2401", 1, 1, "artillery", "None" }
        },
        T4ExperimentalAir={
            "T4ExperimentalAir",
            "DummyAI",
            { "uel0401", 1, 1, "attack", "None" }
        },
        T4ExperimentalLand1={
            "T4ExperimentalLand1",
            "DummyAI",
            { "uel0401", 1, 1, "attack", "None" }
        },
        T4ExperimentalLand2={
            "T4ExperimentalLand2",
            "DummyAI",
            { "uel0401", 1, 1, "attack", "None" }
        },
        T4ExperimentalSea={
            "T4ExperimentalSea",
            "DummyAI",
            { "ues0401", 1, 1, "attack", "None" }
        }
    },
    -- Aeon templates
    {
        AirAttack = {
            "AirAttack",
            "AttackForceAI",
            { categories.MOBILE * categories.AIR - categories.EXPERIMENTAL, 1, 100, "Attack", "GrowthFormation" }
        },
        AirAttackHunt = {
            "AirAttackHunt",
            "HuntAI",
            { categories.MOBILE * categories.AIR - categories.EXPERIMENTAL, 1, 100, "Attack", "GrowthFormation" }
        },
        LandAttack = {
            "LandAttack",
            "AttackForceAI",
            { categories.MOBILE * categories.LAND - ( categories.EXPERIMENTAL + categories.ENGINEER ), 1, 100, "Attack", "GrowthFormation" }
        },
        LandAttackHunt = {
            "LandAttackHunt",
            "HuntAI",
            { categories.MOBILE * categories.LAND - ( categories.EXPERIMENTAL + categories.ENGINEER ), 1, 100, "Attack", "GrowthFormation" }
        },
        SeaAttack = {
            "SeaAttack",
            "AttackForceAI",
            { categories.MOBILE * categories.NAVAL - categories.EXPERIMENTAL, 1, 100, "Attack", "GrowthFormation" }
        },
        CommanderAssist={
            "CommanderAssist",
            "EngineerAssistAI",
            { categories.COMMAND, 1, 1, "support", "None" }
        },
        CommanderBuilder={
            "CommanderBuilder",
            "EngineerBuildAI",
            { categories.COMMAND, 1, 1, "support", "None" }
        },
        CommanderEnhance={
            "CommanderEnhance",
            "EnhanceAI",
            { categories.COMMAND, 1, 1, "support", "None" }
        },
        Engineer={
            "Engineer",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH1, 1, 3, "support", "None" }
        },
        EngineerAssist={
            "EngineerAssist",
            "EngineerAssistAI",
            { categories.ENGINEER * categories.TECH1, 1, 1, "support", "None" }
        },
        EngineerBuilder={
            "EngineerBuilder",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH1, 1, 3, "support", "None" }
        },
        EngineerGenericSingle={
            "EngineerGenericSingle",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH1, 1, 1, "support", "None" }
        },
        EngineerOnlyBuild={
            "EngineerOnlyBuild",
            "DisbandAI",
            { "ual0105", 5, 5, "support", "None" }
        },
        EngineerOnlyBuild3={
            "EngineerOnlyBuild3",
            "DisbandAI",
            { "ual0105", 3, 3, "support", "None" }
        },
        T1AirBomber1={
            "T1AirBomber1",
            "HuntAI",
            { "uaa0103", -1, 5, "attack", "GrowthFormation" }
        },
        T1AirBomber2={
            "T1AirBomber2",
            "HuntAI",
            { "uaa0103", -1, 5, "attack", "GrowthFormation" }
        },
        T1AirFactoryUpgrade={
            "T1AirFactoryUpgrade",
            "UnitUpgradeAI",
            { "uab0102", 1, 1, "support", "None" }
        },
        T1AirFighter1={
            "T1AirFighter1",
            "PatrolBaseVectorsAI",
            { "uaa0102", 2, 5, "attack", "GrowthFormation" }
        },
        T1AirScout1={
            "T1AirScout1",
            "ScoutingAI",
            { "uaa0101", 1, 1, "scout", "GrowthFormation" }
        },
        T1AirTransport1={
            "T1AirTransport1",
            "DisbandAI",
            { "uaa0107", -1, 1, "support", "GrowthFormation" }
        },
        T1EngineerGuard={
            "T1EngineerGuard",
            "None",
            { "ual0106", 1, 5, "guard", "GrowthFormation" }
        },
        T1LandAA1={
            "T1LandAA1",
            "PatrolBaseVectorsAI",
            { "ual0104", 2, 5, "attack", "GrowthFormation" }
        },
        T1LandAA2={
            "T1LandAA2",
            "PatrolBaseVectorsAI",
            { "ual0104", -1, 5, "Attack", "GrowthFormation" }
        },
        T1LandArtillery1={
            "T1LandArtillery1",
            "PatrolBaseVectorsAI",
            { "ual0101", 1, 1, "attack", "GrowthFormation" },
            { "ual0103", 2, 7, "attack", "GrowthFormation" }
        },
        T1LandArtillery2={
            "T1LandArtillery2",
            "PatrolBaseVectorsAI",
            { "ual0103", -1, 7, "Attack", "GrowthFormation" }
        },
        T1LandArtilleryScout2={
            "T1LandArtilleryScout2",
            "PatrolBaseVectorsAI",
            { "ual0101", 1, 1, "attack", "GrowthFormation" },
            { "ual0103", -1, 7, "Attack", "GrowthFormation" }
        },
        T1LandDFBot1={
            "T1LandDFBot1",
            "PatrolBaseVectorsAI",
            { "ual0106", 2, 10, "attack", "GrowthFormation" }
        },
        T1LandDFBot2={
            "T1LandDFBot2",
            "PatrolBaseVectorsAI",
            { "ual0106", -1, 10, "attack", "GrowthFormation" }
        },
        T1LandDFTank1={
            "T1LandDFTank1",
            "PatrolBaseVectorsAI",
            { "ual0201", 2, 10, "attack", "GrowthFormation" }
        },
        T1LandDFTank2={
            "T1LandDFTank2",
            "PatrolBaseVectorsAI",
            { "ual0201", -1, 10, "attack", "GrowthFormation" }
        },
        T1LandFactoryInfiniteBuild={
            "T1LandFactoryInfiniteBuild",
            "LandFactoryInfiniteBuild",
            { "uab0101", 1, 1, "support", "None" }
        },
        T1LandFactoryUpgrade={
            "T1LandFactoryUpgrade",
            "UnitUpgradeAI",
            { "uab0101", 1, 1, "support", "None" }
        },
        T1LandScout1={
            "T1LandScout1",
            "ScoutingAI",
            { "ual0101", 1, 1, "scout", "GrowthFormation" }
        },
        T1MassExtractorUpgrade={
            "T1MassExtractorUpgrade",
            "UnitUpgradeAI",
            { "uab1103", 1, 1, "support", "None" }
        },
        T1MassFabricator={
            "T1MassFabricator",
            "PauseAI",
            { "uab1104", 1, 1, "support", "None" }
        },
        T1MassHunters={
            "T1MassHunters",
            "PatrolBaseVectorsAI",
            { "ual0101", 1, 1, "attack", "GrowthFormation" },
            { "ual0201", 2, 4, "attack", "GrowthFormation" }
        },
        MassHuntersCategory={
            'MassHuntersCategory',
            'AttackForceAI',
            { categories.LAND * categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT, 3, 8, 'attack', 'GrowthFormation' },
            { categories.LAND * categories.SCOUT, 0, 1, 'attack', 'GrowthFormation' },
        },
        MassHuntersCategoryHunt={
            'MassHuntersCategoryHunt',
            'HuntAI',
            { categories.LAND * categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT, 1, 8, 'attack', 'GrowthFormation' },
            { categories.LAND * categories.SCOUT, 0, 1, 'attack', 'GrowthFormation' },
        },
        T1RadarUpgrade={
            "T1RadarUpgrade",
            "UnitUpgradeAI",
            { "uab3101", 1, 1, "support", "None" }
        },
        T1SeaFactoryUpgrade={
            "T1SeaFactoryUpgrade",
            "UnitUpgradeAI",
            { "uab0103", 1, 1, "support", "None" }
        },
        T1SeaFrigate1={
            "T1SeaFrigate1",
            "AttackForceAI",
            { "uas0103", -1, 3, "attack", "GrowthFormation" }
        },
        T1SeaFrigate2={
            "T1SeaFrigate2",
            "AttackForceAI",
            { "uas0102", -1, 3, "attack", "GrowthFormation" }
        },
        T1SeaSub1={
            "T1SeaSub1",
            "AttackForceAI",
            { "uas0203", -1, 3, "attack", "GrowthFormation" }
        },
        T1SonarUpgrade={
            "T1SonarUpgrade",
            "UnitUpgradeAI",
            { "uab3102", 1, 1, "support", "None" }
        },
        T2AirFactoryInfiniteBuild={
            "T2AirFactoryInfiniteBuild",
            "FactoryInfiniteBuild",
            { "uab0202", 1, 1, "support", "None" }
        },
        T2AirFactoryUpgrade={
            "T2AirFactoryUpgrade",
            "UnitUpgradeAI",
            { "uab0202", 1, 1, "support", "None" }
        },
        T2AirGunship1={
            "T2AirGunship1",
            "HuntAI",
            { "uaa0203", 2, 5, "attack", "GrowthFormation" }
        },
        T2AirGunship2={
            "T2AirGunship2",
            "HuntAI",
            { "uaa0203", -1, 5, "attack", "GrowthFormation" }
        },
        T2AirTorpedoBomber1={
            "T2AirTorpedoBomber1",
            "HuntAI",
            { "uaa0204", 2, 5, "attack", "GrowthFormation" }
        },
        T2AirTransport1={
            "T2AirTransport1",
            "DisbandAI",
            { "uaa0104", -1, 1, "support", "GrowthFormation" },
            { "uaa0107", -1, 1, "support", "GrowthFormation" }
        },
        T2ArtilleryStructure={
            "T2ArtilleryStructure",
            "ArtilleryAI",
            { "uab2303", 1, 1, "artillery", "None" }
        },
        T2Engineer={
            "T2Engineer",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH2, 1, 3, "support", "None" }
        },
        T2EngineerAssist={
            "T2EngineerAssist",
            "EngineerAssistAI",
            { categories.ENGINEER * categories.TECH2, 1, 2, "support", "None" }
        },
        T2EngineerBuilder={
            "T2EngineerBuilder",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH2, 1, 3, "support", "None" }
        },
        T2EngineerGenericSingle={
            "T2EngineerGenericSingle",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH2, 1, 1, "support", "None" }
        },
        T2EngineerOnlyBuild={
            "T2EngineerOnlyBuild",
            "DisbandAI",
            { "ual0208", 5, 5, "support", "None" }
        },
        T2LandAA1={
            "T2LandAA1",
            "PatrolBaseVectorsAI",
            { "ual0205", 1, 3, "attack", "GrowthFormation" }
        },
        T2LandAA2={
            "T2LandAA2",
            "PatrolBaseVectorsAI",
            { "ual0205", -1, 3, "attack", "GrowthFormation" }
        },
        T2LandAmphibious1={
            "T2LandAmphibious1",
            "PatrolBaseVectorsAI",
            { "ual0201", 1, 6, "attack", "GrowthFormation" }
        },
        T2LandAmphibious2={
            "T2LandAmphibious2",
            "PatrolBaseVectorsAI",
            { "ual0201", -1, 4, "attack", "GrowthFormation" }
        },
        T2LandArtillery1={
            "T2LandArtillery1",
            "PatrolBaseVectorsAI",
            { "ual0111", 1, 3, "artillery", "GrowthFormation" },
            { "ual0101", 1, 1, "artillery", "GrowthFormation" },
            { "ual0307", 1, 1, "artillery", "GrowthFormation" }
        },
        T2LandArtillery2={
            "T2LandArtillery2",
            "PatrolBaseVectorsAI",
            { "ual0111", -1, 3, "artillery", "GrowthFormation" },
            { "ual0101", 1, 1, "artillery", "GrowthFormation" },
            { "ual0201", -1, 10, "attack", "GrowthFormation" },
            { "ual0307", 1, 1, "artillery", "GrowthFormation" }
        },
        T2LandDFTank1={
            "T2LandDFTank1",
            "PatrolBaseVectorsAI",
            { "ual0202", 1, 4, "attack", "GrowthFormation" }
        },
        T2LandDFTank2={
            "T2LandDFTank2",
            "PatrolBaseVectorsAI",
            { "ual0202", -1, 4, "attack", "GrowthFormation" },
            { "ual0201", -1, 10, "attack", "GrowthFormation" }
        },
        T2LandFactoryUpgrade={
            "T2LandFactoryUpgrade",
            "UnitUpgradeAI",
            { "uab0201", 1, 1, "support", "None" }
        },
        T2MassExtractorUpgrade={
            "T2MassExtractorUpgrade",
            "UnitUpgradeAI",
            { "uab1202", 1, 1, "support", "None" }
        },
        T2MobileShield1={
            "T2MobileShield1",
            "PatrolBaseVectorsAI",
            { "ual0307", 2, 2, "support", "GrowthFormation" }
        },
        T2RadarUpgrade={
            "T2RadarUpgrade",
            "UnitUpgradeAI",
            { "uab3201", 1, 1, "support", "None" }
        },
        T2SeaCruiser1={
            "T2SeaCruiser1",
            "AttackForceAI",
            { "uas0202", -1, 2, "attack", "GrowthFormation" }
        },
        T2SeaDestroyer1={
            "T2SeaDestroyer1",
            "AttackForceAI",
            { "uas0201", -1, 2, "attack", "GrowthFormation" }
        },
        T2SeaFactoryUpgrade={
            "T2SeaFactoryUpgrade",
            "UnitUpgradeAI",
            { "uab0203", 1, 1, "support", "None" }
        },
        T2Shield={
            "T2Shield",
            "DummyAI",
            { "uab4202", 1, 1, "attack", "None" }
        },
        T2Shield1={
            "T2Shield1",
            "DummyAI",
            { "uab4202", 1, 1, "attack", "None" }
        },
        T2Shield2={
            "T2Shield2",
            "DummyAI",
            { "uab4202", 1, 1, "attack", "None" }
        },
        T2Shield3={
            "T2Shield3",
            "DummyAI",
            { "uab4202", 1, 1, "attack", "None" }
        },
        T2Shield4={
            "T2Shield4",
            "DummyAI",
            { "uab4202", 1, 1, "attack", "None" }
        },
        T2SonarUpgrade={
            "T2SonarUpgrade",
            "UnitUpgradeAI",
            { "uab3202", 1, 1, "support", "None" }
        },
        T2TacticalLauncher={
            "T2TacticalLauncher",
            "TacticalAI",
            { "uab2108", 1, 1, "attack", "None" }
        },
        T3AirBomber1={
            "T3AirBomber1",
            "HuntAI",
            { "uaa0304", 2, 5, "attack", "GrowthFormation" }
        },
        T3AirBomber2={
            "T3AirBomber2",
            "HuntAI",
            { "uaa0304", -1, 5, "attack", "GrowthFormation" }
        },
        T3AirFighter1={
            "T3AirFighter1",
            "PatrolBaseVectorsAI",
            { "uaa0303", 2, 5, "attack", "GrowthFormation" }
        },
        T3AirGunship1={
            "T3AirGunship1",
            "HuntAI",
            { "uaa0304", 2, 5, "attack", "GrowthFormation" }
        },
        T3AirGunship2={
            "T3AirGunship2",
            "HuntAI",
            { "uaa0304", -1, 5, "attack", "GrowthFormation" }
        },
        T3AirScout1={
            "T3AirScout1",
            "ScoutingAI",
            { "uaa0302", 1, 1, "scout", "GrowthFormation" }
        },
        T3AntiNuke={
            "T3AntiNuke",
            "AntiNukeAI",
            { "uab4302", 1, 1, "attack", "None" }
        },
        T3ArtilleryStructure={
            "T3ArtilleryStructure",
            "ArtilleryAI",
            { "uab2302", 1, 1, "artillery", "None" }
        },
        T3Engineer={
            "T3Engineer",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH3, 1, 3, "support", "None" }
        },
        T3EngineerAssist={
            "T3EngineerAssist",
            "EngineerAssistAI",
            { categories.ENGINEER * categories.TECH3, 1, 3, "support", "None" }
        },
        T3EngineerBuilder={
            "T3EngineerBuilder",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH3, 1, 3, "support", "None" }
        },
        T3EngineerBuilderBig={
            "T3EngineerBuilderBig",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH3, 1, 6, "support", "None" }
        },
        T3EngineerGenericSingle={
            "T3EngineerGenericSingle",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH3, 1, 1, "support", "None" }
        },
        T3EngineerOnlyBuild={
            "T3EngineerOnlyBuild",
            "DisbandAI",
            { "ual0309", 6, 6, "support", "None" }
        },
        T3EngineerOnlyBuild2={
            "T3EngineerOnlyBuild2",
            "DisbandAI",
            { "ual0309", -1, 6, "support", "None" }
        },
        T3LandAA1={
            "T3LandAA1",
            "PatrolBaseVectorsAI",
            { "dalk003", 1, 3, "attack", "GrowthFormation" }
        },
        T3LandAA2={
            "T3LandAA2",
            "PatrolBaseVectorsAI",
            { "dalk003", -1, 3, "attack", "GrowthFormation" }
        },
        T3LandArtillery1={
            "T3LandArtillery1",
            "PatrolBaseVectorsAI",
            { "ual0304", 1, 2, "artillery", "GrowthFormation" },
            { "ual0307", 1, 1, "artillery", "GrowthFormation" }
        },
        T3LandArtillery2={
            "T3LandArtillery2",
            "PatrolBaseVectorsAI",
            { "ual0304", -1, 2, "artillery", "GrowthFormation" },
            { "ual0201", -1, 10, "attack", "GrowthFormation" },
            { "ual0307", 1, 1, "artillery", "GrowthFormation" }
        },
        T3LandBot1={
            "T3LandBot1",
            "PatrolBaseVectorsAI",
            { "ual0303", 1, 3, "attack", "GrowthFormation" }
        },
        T3LandBot2={
            "T3LandBot2",
            "PatrolBaseVectorsAI",
            { "ual0303", -1, 3, "attack", "GrowthFormation" },
            { "ual0201", -1, 10, "attack", "GrowthFormation" }
        },
        T3LandSubCommander1={
            "T3LandSubCommander1",
            "HuntAI",
            { "ual0301", 3, 3, "support", "GrowthFormation" }
        },
        T3MassFabricator={
            "T3MassFabricator",
            "PauseAI",
            { "uab1303", 1, 1, "support", "None" }
        },
        T3Nuke={
            "T3Nuke",
            "NukeAI",
            { "uab2305", 1, 1, "attack", "None" }
        },
        T3SeaBattleship1={
            "T3SeaBattleship1",
            "AttackForceAI",
            { "uas0302", -1, 1, "attack", "GrowthFormation" }
        },
        T3SeaCarrier1={
            "T3SeaCarrier1",
            "CarrierAI",
            { "uas0303", -1, 1, "attack", "GrowthFormation" }
        },
        T3SeaNukeSub1={
            "T3SeaNukeSub1",
            "NukeAI",
            { "uas0304", -1, 1, "attack", "GrowthFormation" }
        },
        T4ArtilleryStructure={
            "T4ArtilleryStructure",
            "ArtilleryAI",
            { "uab2302", 1, 1, "artillery", "None" }
        },
        T4ExperimentalAir={
            "T4ExperimentalAir",
            "DummyAI",
            { "uaa0310", 1, 1, "attack", "None" }
        },
        T4ExperimentalLand1={
            "T4ExperimentalLand1",
            "DummyAI",
            { "ual0401", 1, 1, "attack", "None" }
        },
        T4ExperimentalLand2={
            "T4ExperimentalLand2",
            "DummyAI",
            { "ual0401", 1, 1, "attack", "None" }
        },
        T4ExperimentalSea={
            "T4ExperimentalSea",
            "DummyAI",
            { "uas0401", 1, 1, "attack", "None" }
        }
    },
    -- Cybran Templates
    {
        AirAttack = {
            "AirAttack",
            "AttackForceAI",
            { categories.MOBILE * categories.AIR - categories.EXPERIMENTAL, 1, 100, "Attack", "GrowthFormation" }
        },
        AirAttackHunt = {
            "AirAttackHunt",
            "HuntAI",
            { categories.MOBILE * categories.AIR - categories.EXPERIMENTAL, 1, 100, "Attack", "GrowthFormation" }
        },
        LandAttack = {
            "LandAttack",
            "AttackForceAI",
            { categories.MOBILE * categories.LAND - ( categories.EXPERIMENTAL + categories.ENGINEER ), 1, 100, "Attack", "GrowthFormation" }
        },
        LandAttackHunt = {
            "LandAttackHunt",
            "HuntAI",
            { categories.MOBILE * categories.LAND - ( categories.EXPERIMENTAL + categories.ENGINEER ), 1, 100, "Attack", "GrowthFormation" }
        },
        SeaAttack = {
            "SeaAttack",
            "AttackForceAI",
            { categories.MOBILE * categories.NAVAL - categories.EXPERIMENTAL, 1, 100, "Attack", "GrowthFormation" }
        },
        CommanderAssist={
            "CommanderAssist",
            "EngineerAssistAI",
            { categories.COMMAND, 1, 1, "support", "None" }
        },
        CommanderBuilder={
            "CommanderBuilder",
            "EngineerBuildAI",
            { categories.COMMAND, 1, 1, "support", "None" }
        },
        CommanderEnhance={
            "CommanderEnhance",
            "EnhanceAI",
            { categories.COMMAND, 1, 1, "support", "None" }
        },
        Engineer={
            "Engineer",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH1, 1, 3, "support", "None" }
        },
        EngineerAssist={
            "EngineerAssist",
            "EngineerAssistAI",
            { categories.ENGINEER * categories.TECH1, 1, 1, "support", "None" }
        },
        EngineerBuilder={
            "EngineerBuilder",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH1, 1, 3, "support", "None" }
        },
        EngineerGenericSingle={
            "EngineerGenericSingle",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH1, 1, 1, "support", "None" }
        },
        EngineerOnlyBuild={
            "EngineerOnlyBuild",
            "DisbandAI",
            { "url0105", 5, 5, "support", "None" }
        },
        EngineerOnlyBuild3={
            "EngineerOnlyBuild3",
            "DisbandAI",
            { "url0105", 3, 3, "support", "None" }
        },
        T1AirBomber1={
            "T1AirBomber1",
            "HuntAI",
            { "ura0103", 2, 5, "attack", "GrowthFormation" }
        },
        T1AirBomber2={
            "T1AirBomber2",
            "HuntAI",
            { "ura0103", -1, 5, "attack", "GrowthFormation" }
        },
        T1AirFactoryUpgrade={
            "T1AirFactoryUpgrade",
            "UnitUpgradeAI",
            { "urb0102", 1, 1, "support", "None" }
        },
        T1AirFighter1={
            "T1AirFighter1",
            "PatrolBaseVectorsAI",
            { "ura0102", 2, 5, "attack", "GrowthFormation" }
        },
        T1AirScout1={
            "T1AirScout1",
            "ScoutingAI",
            { "ura0101", 1, 1, "scout", "GrowthFormation" }
        },
        T1AirTransport1={
            "T1AirTransport1",
            "DisbandAI",
            { "ura0107", -1, 1, "support", "GrowthFormation" }
        },
        T1EngineerGuard={
            "T1EngineerGuard",
            "None",
            { "url0106", 1, 5, "guard", "GrowthFormation" }
        },
        T1LandAA1={
            "T1LandAA1",
            "PatrolBaseVectorsAI",
            { "url0104", 2, 5, "attack", "GrowthFormation" }
        },
        T1LandAA2={
            "T1LandAA2",
            "PatrolBaseVectorsAI",
            { "url0104", -1, 5, "Attack", "GrowthFormation" }
        },
        T1LandArtillery1={
            "T1LandArtillery1",
            "PatrolBaseVectorsAI",
            { "url0101", 1, 1, "attack", "GrowthFormation" },
            { "url0103", 2, 7, "attack", "GrowthFormation" }
        },
        T1LandArtillery2={
            "T1LandArtillery2",
            "PatrolBaseVectorsAI",
            { "url0103", -1, 7, "Attack", "GrowthFormation" }
        },
        T1LandArtilleryScout2={
            "T1LandArtilleryScout2",
            "PatrolBaseVectorsAI",
            { "url0101", 1, 1, "attack", "GrowthFormation" },
            { "url0103", -1, 7, "Attack", "GrowthFormation" }
        },
        T1LandDFBot1={
            "T1LandDFBot1",
            "PatrolBaseVectorsAI",
            { "url0106", 2, 10, "attack", "GrowthFormation" }
        },
        T1LandDFBot2={
            "T1LandDFBot2",
            "PatrolBaseVectorsAI",
            { "url0106", -1, 10, "attack", "GrowthFormation" }
        },
        T1LandDFTank1={
            "T1LandDFTank1",
            "PatrolBaseVectorsAI",
            { "url0107", 2, 10, "attack", "GrowthFormation" }
        },
        T1LandDFTank2={
            "T1LandDFTank2",
            "PatrolBaseVectorsAI",
            { "url0107", -1, 10, "attack", "GrowthFormation" }
        },
        T1LandFactoryInfiniteBuild={
            "T1LandFactoryInfiniteBuild",
            "LandFactoryInfiniteBuild",
            { "urb0101", 1, 1, "support", "None" }
        },
        T1LandFactoryUpgrade={
            "T1LandFactoryUpgrade",
            "UnitUpgradeAI",
            { "urb0101", 1, 1, "support", "None" }
        },
        T1LandScout1={
            "T1LandScout1",
            "ScoutingAI",
            { "url0101", 1, 1, "scout", "GrowthFormation" }
        },
        T1MassExtractorUpgrade={
            "T1MassExtractorUpgrade",
            "UnitUpgradeAI",
            { "urb1103", 1, 1, "support", "None" }
        },
        T1MassFabricator={
            "T1MassFabricator",
            "PauseAI",
            { "urb1104", 1, 1, "support", "None" }
        },
        T1MassHunters={
            "T1MassHunters",
            "PatrolBaseVectorsAI",
            { "url0101", 1, 1, "attack", "GrowthFormation" },
            { "url0107", 2, 4, "attack", "GrowthFormation" }
        },
        MassHuntersCategory={
            'MassHuntersCategory',
            'AttackForceAI',
            { categories.LAND * categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT, 3, 8, 'attack', 'GrowthFormation' },
            { categories.LAND * categories.SCOUT, 3, 8, 'attack', 'GrowthFormation' },
        },
        MassHuntersCategoryHunt={
            'MassHuntersCategoryHunt',
            'HuntAI',
            { categories.LAND * categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT, 1, 8, 'attack', 'GrowthFormation' },
            { categories.LAND * categories.SCOUT, 0, 1, 'attack', 'GrowthFormation' },
        },
        T1RadarUpgrade={
            "T1RadarUpgrade",
            "UnitUpgradeAI",
            { "urb3101", 1, 1, "support", "None" }
        },
        T1SeaFactoryUpgrade={
            "T1SeaFactoryUpgrade",
            "UnitUpgradeAI",
            { "urb0103", 1, 1, "support", "None" }
        },
        T1SeaFrigate1={
            "T1SeaFrigate1",
            "AttackForceAI",
            { "urs0103", -1, 3, "attack", "GrowthFormation" }
        },
        T1SeaFrigate2={
            "T1SeaFrigate2",
            "AttackForceAI",
            { "urs0103", -1, 3, "attack", "GrowthFormation" }
        },
        T1SeaSub1={
            "T1SeaSub1",
            "AttackForceAI",
            { "urs0203", -1, 3, "attack", "GrowthFormation" }
        },
        T1SonarUpgrade={
            "T1SonarUpgrade",
            "UnitUpgradeAI",
            { "urb3102", 1, 1, "support", "None" }
        },
        T2AirFactoryInfiniteBuild={
            "T2AirFactoryInfiniteBuild",
            "FactoryInfiniteBuild",
            { "urb0202", 1, 1, "support", "None" }
        },
        T2AirFactoryUpgrade={
            "T2AirFactoryUpgrade",
            "UnitUpgradeAI",
            { "urb0202", 1, 1, "support", "None" }
        },
        T2AirGunship1={
            "T2AirGunship1",
            "HuntAI",
            { "ura0203", 2, 5, "attack", "GrowthFormation" }
        },
        T2AirGunship2={
            "T2AirGunship2",
            "HuntAI",
            { "ura0203", -1, 5, "attack", "GrowthFormation" }
        },
        T2AirTorpedoBomber1={
            "T2AirTorpedoBomber1",
            "HuntAI",
            { "ura0204", 2, 5, "attack", "GrowthFormation" }
        },
        T2AirTransport1={
            "T2AirTransport1",
            "DisbandAI",
            { "ura0104", -1, 1, "support", "GrowthFormation" },
            { "ura0107", -1, 1, "support", "GrowthFormation" }
        },
        T2ArtilleryStructure={
            "T2ArtilleryStructure",
            "ArtilleryAI",
            { "urb2303", 1, 1, "artillery", "None" }
        },
        T2Engineer={
            "T2Engineer",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH2, 1, 3, "support", "None" }
        },
        T2EngineerAssist={
            "T2EngineerAssist",
            "EngineerAssistAI",
            { categories.ENGINEER * categories.TECH2, 1, 2, "support", "None" }
        },
        T2EngineerBuilder={
            "T2EngineerBuilder",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH2, 1, 3, "support", "None" }
        },
        T2EngineerGenericSingle={
            "T2EngineerGenericSingle",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH2, 1, 1, "support", "None" }
        },
        T2EngineerOnlyBuild={
            "T2EngineerOnlyBuild",
            "DisbandAI",
            { "url0208", 5, 5, "support", "None" }
        },
        T2LandAA1={
            "T2LandAA1",
            "PatrolBaseVectorsAI",
            { "url0205", 1, 3, "attack", "GrowthFormation" }
        },
        T2LandAA2={
            "T2LandAA2",
            "PatrolBaseVectorsAI",
            { "url0205", -1, 3, "attack", "GrowthFormation" }
        },
        T2LandAmphibious1={
            "T2LandAmphibious1",
            "PatrolBaseVectorsAI",
            { "url0203", 1, 4, "attack", "GrowthFormation" }
        },
        T2LandAmphibious2={
            "T2LandAmphibious2",
            "PatrolBaseVectorsAI",
            { "url0203", -1, 4, "attack", "GrowthFormation" }
        },
        T2LandArtillery1={
            "T2LandArtillery1",
            "PatrolBaseVectorsAI",
            { "url0111", 1, 3, "artillery", "GrowthFormation" },
            { "url0101", 1, 1, "artillery", "GrowthFormation" },
            { "url0306", 1, 1, "artillery", "GrowthFormation" }
        },
        T2LandArtillery2={
            "T2LandArtillery2",
            "PatrolBaseVectorsAI",
            { "url0111", -1, 3, "artillery", "GrowthFormation" },
            { "url0107", -1, 10, "attack", "GrowthFormation" },
            { "url0101", 1, 1, "artillery", "GrowthFormation" },
            { "url0306", 1, 1, "artillery", "GrowthFormation" }
        },
        T2LandDFTank1={
            "T2LandDFTank1",
            "PatrolBaseVectorsAI",
            { "url0202", 1, 4, "attack", "GrowthFormation" }
        },
        T2LandDFTank2={
            "T2LandDFTank2",
            "PatrolBaseVectorsAI",
            { "url0202", -1, 4, "attack", "GrowthFormation" },
            { "url0107", -1, 10, "attack", "GrowthFormation" }
        },
        T2LandFactoryUpgrade={
            "T2LandFactoryUpgrade",
            "UnitUpgradeAI",
            { "urb0201", 1, 1, "support", "None" }
        },
        T2MassExtractorUpgrade={
            "T2MassExtractorUpgrade",
            "UnitUpgradeAI",
            { "urb1202", 1, 1, "support", "None" }
        },
        T2MobileShield1={
            "T2MobileShield1",
            "PatrolBaseVectorsAI",
            { "url0306", 2, 2, "support", "GrowthFormation" }
        },
        T2RadarUpgrade={
            "T2RadarUpgrade",
            "UnitUpgradeAI",
            { "urb3201", 1, 1, "support", "None" }
        },
        T2SeaCruiser1={
            "T2SeaCruiser1",
            "AttackForceAI",
            { "urs0202", -1, 2, "attack", "GrowthFormation" }
        },
        T2SeaDestroyer1={
            "T2SeaDestroyer1",
            "AttackForceAI",
            { "urs0201", -1, 2, "attack", "GrowthFormation" }
        },
        T2SeaFactoryUpgrade={
            "T2SeaFactoryUpgrade",
            "UnitUpgradeAI",
            { "urb0203", 1, 1, "support", "None" }
        },
        T2Shield={
            "T2Shield",
            "UnitUpgradeAI",
            { "urb4202", 1, 1, "attack", "None" }
        },
        T2Shield1={
            "T2Shield1",
            "UnitUpgradeAI",
            { "urb4202", 1, 1, "attack", "None" }
        },
        T2Shield2={
            "T2Shield2",
            "UnitUpgradeAI",
            { "urb4204", 1, 1, "attack", "None" }
        },
        T2Shield3={
            "T2Shield3",
            "UnitUpgradeAI",
            { "urb4205", 1, 1, "attack", "None" }
        },
        T2Shield4={
            "T2Shield4",
            "UnitUpgradeAI",
            { "urb4206", 1, 1, "attack", "None" }
        },
        T2SonarUpgrade={
            "T2SonarUpgrade",
            "UnitUpgradeAI",
            { "urb3202", 1, 1, "support", "None" }
        },
        T2TacticalLauncher={
            "T2TacticalLauncher",
            "TacticalAI",
            { "urb2108", 1, 1, "attack", "None" }
        },
        T3AirBomber1={
            "T3AirBomber1",
            "HuntAI",
            { "ura0304", 2, 5, "attack", "GrowthFormation" }
        },
        T3AirBomber2={
            "T3AirBomber2",
            "HuntAI",
            { "ura0304", -1, 5, "attack", "GrowthFormation" }
        },
        T3AirFighter1={
            "T3AirFighter1",
            "PatrolBaseVectorsAI",
            { "ura0303", 2, 5, "attack", "GrowthFormation" }
        },
        T3AirGunship1={
            "T3AirGunship1",
            "HuntAI",
            { "ura0304", 2, 5, "attack", "GrowthFormation" }
        },
        T3AirGunship2={
            "T3AirGunship2",
            "HuntAI",
            { "ura0304", -1, 5, "attack", "GrowthFormation" }
        },
        T3AirScout1={
            "T3AirScout1",
            "ScoutingAI",
            { "ura0302", 1, 1, "scout", "GrowthFormation" }
        },
        T3AntiNuke={
            "T3AntiNuke",
            "AntiNukeAI",
            { "urb4302", 1, 1, "attack", "None" }
        },
        T3ArtilleryStructure={
            "T3ArtilleryStructure",
            "ArtilleryAI",
            { "urb2302", 1, 1, "artillery", "None" }
        },
        T3Engineer={
            "T3Engineer",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH3, 1, 3, "support", "None" }
        },
        T3EngineerAssist={
            "T3EngineerAssist",
            "EngineerAssistAI",
            { categories.ENGINEER * categories.TECH3, 1, 3, "support", "None" }
        },
        T3EngineerBuilder={
            "T3EngineerBuilder",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH3, 1, 3, "support", "None" }
        },
        T3EngineerBuilderBig={
            "T3EngineerBuilderBig",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH3, 1, 6, "support", "None" }
        },
        T3EngineerGenericSingle={
            "T3EngineerGenericSingle",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH3, 1, 1, "support", "None" }
        },
        T3EngineerOnlyBuild={
            "T3EngineerOnlyBuild",
            "DisbandAI",
            { "url0309", 6, 6, "support", "None" }
        },
        T3EngineerOnlyBuild2={
            "T3EngineerOnlyBuild2",
            "DisbandAI",
            { "url0309", -1, 6, "support", "None" }
        },
        T3LandAA1={
            "T3LandAA1",
            "PatrolBaseVectorsAI",
            { "drlk001", 1, 3, "attack", "GrowthFormation" }
        },
        T3LandAA2={
            "T3LandAA2",
            "PatrolBaseVectorsAI",
            { "drlk001", -1, 3, "attack", "GrowthFormation" }
        },
        T3LandArtillery1={
            "T3LandArtillery1",
            "PatrolBaseVectorsAI",
            { "url0304", 1, 2, "artillery", "GrowthFormation" },
            { "url0306", 1, 1, "artillery", "GrowthFormation" }
        },
        T3LandArtillery2={
            "T3LandArtillery2",
            "PatrolBaseVectorsAI",
            { "url0304", -1, 2, "artillery", "GrowthFormation" },
            { "url0107", -1, 10, "attack", "GrowthFormation" },
            { "url0306", 1, 1, "artillery", "GrowthFormation" }
        },
        T3LandBot1={
            "T3LandBot1",
            "PatrolBaseVectorsAI",
            { "url0303", 1, 3, "attack", "GrowthFormation" }
        },
        T3LandBot2={
            "T3LandBot2",
            "PatrolBaseVectorsAI",
            { "url0303", -1, 3, "attack", "GrowthFormation" },
            { "url0107", -1, 10, "attack", "GrowthFormation" }
        },
        T3LandSubCommander1={
            "T3LandSubCommander1",
            "HuntAI",
            { "url0301", 3, 3, "support", "GrowthFormation" }
        },
        T3MassFabricator={
            "T3MassFabricator",
            "PauseAI",
            { "urb1303", 1, 1, "support", "None" }
        },
        T3Nuke={
            "T3Nuke",
            "NukeAI",
            { "urb2305", 1, 1, "attack", "None" }
        },
        T3SeaBattleship1={
            "T3SeaBattleship1",
            "AttackForceAI",
            { "urs0302", -1, 1, "attack", "GrowthFormation" }
        },
        T3SeaCarrier1={
            "T3SeaCarrier1",
            "CarrierAI",
            { "urs0303", -1, 1, "attack", "GrowthFormation" }
        },
        T3SeaNukeSub1={
            "T3SeaNukeSub1",
            "NukeAI",
            { "urs0304", -1, 1, "attack", "GrowthFormation" }
        },
        T4ArtilleryStructure={
            "T4ArtilleryStructure",
            "ArtilleryAI",
            { "urb2302", 1, 1, "artillery", "None" }
        },
        T4ExperimentalAir={
            "T4ExperimentalAir",
            "DummyAI",
            { "ura0401", 1, 1, "attack", "None" }
        },
        T4ExperimentalLand1={
            "T4ExperimentalLand1",
            "DummyAI",
            { "url0402", 1, 1, "attack", "None" }
        },
        T4ExperimentalLand2={
            "T4ExperimentalLand2",
            "DummyAI",
            { "url0401", 1, 1, "attack", "None" }
        },
        T4ExperimentalSea={
            "T4ExperimentalSea",
            "DummyAI",
            { "urs0302", -1, 1, "attack", "None" }
        }
    },
    -- Seraphim templates
    {
        AirAttack = {
            "AirAttack",
            "AttackForceAI",
            { categories.MOBILE * categories.AIR - categories.EXPERIMENTAL, 1, 100, "Attack", "GrowthFormation" }
        },
        AirAttackHunt = {
            "AirAttackHunt",
            "HuntAI",
            { categories.MOBILE * categories.AIR - categories.EXPERIMENTAL, 1, 100, "Attack", "GrowthFormation" }
        },
        LandAttack = {
            "LandAttack",
            "AttackForceAI",
            { categories.MOBILE * categories.LAND - ( categories.EXPERIMENTAL + categories.ENGINEER ), 1, 100, "Attack", "GrowthFormation" }
        },
        LandAttackHunt = {
            "LandAttackHunt",
            "HuntAI",
            { categories.MOBILE * categories.LAND - ( categories.EXPERIMENTAL + categories.ENGINEER ), 1, 100, "Attack", "GrowthFormation" }
        },
        SeaAttack = {
            "SeaAttack",
            "NavalForceAI",
            { categories.MOBILE * categories.NAVAL - categories.EXPERIMENTAL, 1, 100, "Attack", "GrowthFormation" }
        },
        CommanderAssist={
            "CommanderAssist",
            "EngineerAssistAI",
            { categories.COMMAND, 1, 1, "support", "None" }
        },
        CommanderBuilder={
            "CommanderBuilder",
            "EngineerBuildAI",
            { categories.COMMAND, 1, 1, "support", "None" }
        },
        CommanderEnhance={
            "CommanderEnhance",
            "EnhanceAI",
            { categories.COMMAND, 1, 1, "support", "None" }
        },
        Engineer={
            "Engineer",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH1, 1, 3, "support", "None" }
        },
        EngineerAssist={
            "EngineerAssist",
            "EngineerAssistAI",
            { categories.ENGINEER * categories.TECH1, 1, 1, "support", "None" }
        },
        EngineerBuilder={
            "EngineerBuilder",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH1, 1, 3, "support", "None" }
        },
        EngineerGenericSingle={
            "EngineerGenericSingle",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH1, 1, 1, "support", "None" }
        },
        EngineerOnlyBuild={
            "EngineerOnlyBuild",
            "DisbandAI",
            { "xsl0105", 5, 5, "support", "None" }
        },
        EngineerOnlyBuild3={
            "EngineerOnlyBuild3",
            "DisbandAI",
            { "xsl0105", 3, 3, "support", "None" }
        },
        T1AirBomber1={
            "T1AirBomber1",
            "HuntAI",
            { "xsa0103", 2, 5, "attack", "GrowthFormation" }
        },
        T1AirBomber2={
            "T1AirBomber2",
            "HuntAI",
            { "xsa0103", -1, 5, "attack", "GrowthFormation" }
        },
        T1AirFactoryUpgrade={
            "T1AirFactoryUpgrade",
            "UnitUpgradeAI",
            { "xsb0102", 1, 1, "support", "None" }
        },
        T1AirFighter1={
            "T1AirFighter1",
            "PatrolBaseVectorsAI",
            { "xsa0102", 2, 5, "attack", "GrowthFormation" }
        },
        T1AirScout1={
            "T1AirScout1",
            "ScoutingAI",
            { "xsa0101", 1, 1, "scout", "GrowthFormation" }
        },
        T1AirTransport1={
            "T1AirTransport1",
            "DisbandAI",
            { "xsa0107", -1, 1, "support", "GrowthFormation" }
        },
        T1EngineerGuard={
            "T1EngineerGuard",
            "None",
            { "xsl0201", 1, 5, "guard", "GrowthFormation" }
        },
        T1LandAA1={
            "T1LandAA1",
            "PatrolBaseVectorsAI",
            { "xsl0104", 2, 5, "attack", "GrowthFormation" }
        },
        T1LandAA2={
            "T1LandAA2",
            "PatrolBaseVectorsAI",
            { "xsl0104", -1, 5, "Attack", "GrowthFormation" }
        },
        T1LandArtillery1={
            "T1LandArtillery1",
            "PatrolBaseVectorsAI",
            { "xsl0101", 1, 1, "attack", "GrowthFormation" },
            { "xsl0103", 2, 7, "attack", "GrowthFormation" }
        },
        T1LandArtillery2={
            "T1LandArtillery2",
            "PatrolBaseVectorsAI",
            { "xsl0103", -1, 7, "Attack", "GrowthFormation" }
        },
        T1LandArtilleryScout2={
            "T1LandArtilleryScout2",
            "PatrolBaseVectorsAI",
            { "xsl0101", 1, 1, "attack", "GrowthFormation" },
            { "xsl0103", -1, 7, "Attack", "GrowthFormation" }
        },
        T1LandDFBot1={
            "T1LandDFBot1",
            "PatrolBaseVectorsAI",
            { "xsl0201", 2, 10, "attack", "GrowthFormation" }
        },
        T1LandDFBot2={
            "T1LandDFBot2",
            "PatrolBaseVectorsAI",
            { "xsl0201", -1, 10, "attack", "GrowthFormation" }
        },
        T1LandDFTank1={
            "T1LandDFTank1",
            "PatrolBaseVectorsAI",
            { "xsl0201", 2, 10, "attack", "GrowthFormation" }
        },
        T1LandDFTank2={
            "T1LandDFTank2",
            "PatrolBaseVectorsAI",
            { "xsl0201", -1, 10, "attack", "GrowthFormation" }
        },
        T1LandFactoryInfiniteBuild={
            "T1LandFactoryInfiniteBuild",
            "LandFactoryInfiniteBuild",
            { "xsb0101", 1, 1, "support", "None" }
        },
        T1LandFactoryUpgrade={
            "T1LandFactoryUpgrade",
            "UnitUpgradeAI",
            { "xsb0101", 1, 1, "support", "None" }
        },
        T1LandScout1={
            "T1LandScout1",
            "ScoutingAI",
            { "xsl0101", 1, 1, "scout", "GrowthFormation" }
        },
        T1MassExtractorUpgrade={
            "T1MassExtractorUpgrade",
            "UnitUpgradeAI",
            { "xsb1103", 1, 1, "support", "None" }
        },
        T1MassFabricator={
            "T1MassFabricator",
            "PauseAI",
            { "xsb1104", 1, 1, "support", "None" }
        },
        T1MassHunters={
            "T1MassHunters",
            "PatrolBaseVectorsAI",
            { "xsl0101", 1, 1, "attack", "GrowthFormation" },
            { "xsl0201", 2, 4, "attack", "GrowthFormation" }
        },
        MassHuntersCategory={
            'MassHuntersCategory',
            'AttackForceAI',
            { categories.LAND * categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT, 3, 8, 'attack', 'GrowthFormation' },
            { categories.LAND * categories.SCOUT, 0, 1, 'attack', 'GrowthFormation' },
        },
        MassHuntersCategoryHunt={
            'MassHuntersCategoryHunt',
            'HuntAI',
            { categories.LAND * categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT, 1, 8, 'attack', 'GrowthFormation' },
            { categories.LAND * categories.SCOUT, 0, 1, 'attack', 'GrowthFormation' },
        },
        T1RadarUpgrade={
            "T1RadarUpgrade",
            "UnitUpgradeAI",
            { "xsb3101", 1, 1, "support", "None" }
        },
        T1SeaFactoryUpgrade={
            "T1SeaFactoryUpgrade",
            "UnitUpgradeAI",
            { "xsb0103", 1, 1, "support", "None" }
        },
        T1SeaFrigate1={
            "T1SeaFrigate1",
            "AttackForceAI",
            { "xss0103", -1, 3, "attack", "GrowthFormation" }
        },
        T1SeaFrigate2={
            "T1SeaFrigate2",
            "AttackForceAI",
            { "xss0103", -1, 3, "attack", "GrowthFormation" }
        },
        T1SeaSub1={
            "T1SeaSub1",
            "AttackForceAI",
            { "xss0203", -1, 3, "attack", "GrowthFormation" }
        },
        T1SonarUpgrade={
            "T1SonarUpgrade",
            "UnitUpgradeAI",
            { "xsb3102", 1, 1, "support", "None" }
        },
        T2AirFactoryInfiniteBuild={
            "T2AirFactoryInfiniteBuild",
            "FactoryInfiniteBuild",
            { "xsb0202", 1, 1, "support", "None" }
        },
        T2AirFactoryUpgrade={
            "T2AirFactoryUpgrade",
            "UnitUpgradeAI",
            { "xsb0202", 1, 1, "support", "None" }
        },
        T2AirGunship1={
            "T2AirGunship1",
            "HuntAI",
            { "xsa0203", 2, 5, "attack", "GrowthFormation" }
        },
        T2AirGunship2={
            "T2AirGunship2",
            "HuntAI",
            { "xsa0203", -1, 5, "attack", "GrowthFormation" }
        },
        T2AirTorpedoBomber1={
            "T2AirTorpedoBomber1",
            "HuntAI",
            { "xsa0204", 2, 5, "attack", "GrowthFormation" }
        },
        T2AirTransport1={
            "T2AirTransport1",
            "DisbandAI",
            { "xsa0104", -1, 1, "support", "GrowthFormation" }
        },
        T2ArtilleryStructure={
            "T2ArtilleryStructure",
            "ArtilleryAI",
            { "xsb2303", 1, 1, "artillery", "None" }
        },
        T2Engineer={
            "T2Engineer",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH2, 1, 3, "support", "None" }
        },
        T2EngineerAssist={
            "T2EngineerAssist",
            "EngineerAssistAI",
            { categories.ENGINEER * categories.TECH2, 1, 2, "support", "None" }
        },
        T2EngineerBuilder={
            "T2EngineerBuilder",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH2, 1, 3, "support", "None" }
        },
        T2EngineerGenericSingle={
            "T2EngineerGenericSingle",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH2, 1, 1, "support", "None" }
        },
        T2EngineerOnlyBuild={
            "T2EngineerOnlyBuild",
            "DisbandAI",
            { "xsl0208", 5, 5, "support", "None" }
        },
        T2LandAA1={
            "T2LandAA1",
            "PatrolBaseVectorsAI",
            { "xsl0205", 1, 3, "attack", "GrowthFormation" }
        },
        T2LandAA2={
            "T2LandAA2",
            "PatrolBaseVectorsAI",
            { "xsl0205", -1, 3, "attack", "GrowthFormation" }
        },
        T2LandAmphibious1={
            "T2LandAmphibious1",
            "PatrolBaseVectorsAI",
            { "xsl0202", 1, 4, "attack", "GrowthFormation" }
        },
        T2LandAmphibious2={
            "T2LandAmphibious2",
            "PatrolBaseVectorsAI",
            { "xsl0202", -1, 4, "attack", "GrowthFormation" }
        },
        T2LandArtillery1={
            "T2LandArtillery1",
            "PatrolBaseVectorsAI",
            { "xsl0111", 1, 3, "artillery", "GrowthFormation" },
            { "xsl0101", 1, 1, "artillery", "GrowthFormation" },
            { "xsl0307", 1, 1, "artillery", "GrowthFormation" }
        },
        T2LandArtillery2={
            "T2LandArtillery2",
            "PatrolBaseVectorsAI",
            { "xsl0111", -1, 3, "artillery", "GrowthFormation" },
            { "xsl0201", -1, 10, "attack", "GrowthFormation" },
            { "xsl0101", 1, 1, "artillery", "GrowthFormation" },
            { "xsl0307", 1, 1, "artillery", "GrowthFormation" }
        },
        T2LandDFTank1={
            "T2LandDFTank1",
            "PatrolBaseVectorsAI",
            { "xsl0202", 1, 4, "attack", "GrowthFormation" }
        },
        T2LandDFTank2={
            "T2LandDFTank2",
            "PatrolBaseVectorsAI",
            { "xsl0202", -1, 4, "attack", "GrowthFormation" },
            { "xsl0201", -1, 10, "attack", "GrowthFormation" }
        },
        T2LandFactoryUpgrade={
            "T2LandFactoryUpgrade",
            "UnitUpgradeAI",
            { "xsb0201", 1, 1, "support", "None" }
        },
        T2MassExtractorUpgrade={
            "T2MassExtractorUpgrade",
            "UnitUpgradeAI",
            { "xsb1202", 1, 1, "support", "None" }
        },
        T2MobileShield1={
            "T2MobileShield1",
            "PatrolBaseVectorsAI",
            { "xsl0307", 2, 2, "support", "GrowthFormation" }
        },
        T2RadarUpgrade={
            "T2RadarUpgrade",
            "UnitUpgradeAI",
            { "xsb3201", 1, 1, "support", "None" }
        },
        T2SeaCruiser1={
            "T2SeaCruiser1",
            "AttackForceAI",
            { "xss0202", -1, 2, "attack", "GrowthFormation" }
        },
        T2SeaDestroyer1={
            "T2SeaDestroyer1",
            "AttackForceAI",
            { "xss0201", -1, 2, "attack", "GrowthFormation" }
        },
        T2SeaFactoryUpgrade={
            "T2SeaFactoryUpgrade",
            "UnitUpgradeAI",
            { "xsb0203", 1, 1, "support", "None" }
        },
        T2Shield={
            "T2Shield",
            "UnitUpgradeAI",
            { "xsb4202", 1, 1, "attack", "None" }
        },
        T2Shield1={
            "T2Shield1",
            "UnitUpgradeAI",
            { "xsb4202", 1, 1, "attack", "None" }
        },
        T2Shield2={
            "T2Shield2",
            "UnitUpgradeAI",
            { "xsb4204", 1, 1, "attack", "None" }
        },
        T2Shield3={
            "T2Shield3",
            "UnitUpgradeAI",
            { "xsb4205", 1, 1, "attack", "None" }
        },
        T2Shield4={
            "T2Shield4",
            "UnitUpgradeAI",
            { "xsb4206", 1, 1, "attack", "None" }
        },
--        T2SonarUpgrade={
--            "T2SonarUpgrade",
--            "UnitUpgradeAI",
--            { "xsb3202", 1, 1, "support", "None" } -- unit xsb3202 can't upgrade to xsb0305 (building does not exist).
--        },
        T2TacticalLauncher={
            "T2TacticalLauncher",
            "TacticalAI",
            { "xsb2108", 1, 1, "attack", "None" }
        },
        T3AirBomber1={
            "T3AirBomber1",
            "HuntAI",
            { "xsa0304", 2, 5, "attack", "GrowthFormation" }
        },
        T3AirBomber2={
            "T3AirBomber2",
            "HuntAI",
            { "xsa0304", -1, 5, "attack", "GrowthFormation" }
        },
        T3AirFighter1={
            "T3AirFighter1",
            "PatrolBaseVectorsAI",
            { "xsa0303", 2, 5, "attack", "GrowthFormation" }
        },
        T3AirGunship1={
            "T3AirGunship1",
            "HuntAI",
            { "xsa0304", 2, 5, "attack", "GrowthFormation" }
        },
        T3AirGunship2={
            "T3AirGunship2",
            "HuntAI",
            { "xsa0304", -1, 5, "attack", "GrowthFormation" }
        },
        T3AirScout1={
            "T3AirScout1",
            "ScoutingAI",
            { "xsa0302", 1, 1, "scout", "GrowthFormation" }
        },
        T3AntiNuke={
            "T3AntiNuke",
            "AntiNukeAI",
            { "xsb4302", 1, 1, "attack", "None" }
        },
        T3ArtilleryStructure={
            "T3ArtilleryStructure",
            "ArtilleryAI",
            { "xsb2302", 1, 1, "artillery", "None" }
        },
        T3Engineer={
            "T3Engineer",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH3, 1, 3, "support", "None" }
        },
        T3EngineerAssist={
            "T3EngineerAssist",
            "EngineerAssistAI",
            { categories.ENGINEER * categories.TECH3, 1, 3, "support", "None" }
        },
        T3EngineerBuilder={
            "T3EngineerBuilder",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH3, 1, 3, "support", "None" }
        },
        T3EngineerBuilderBig={
            "T3EngineerBuilderBig",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH3, 1, 6, "support", "None" }
        },
        T3EngineerGenericSingle={
            "T3EngineerGenericSingle",
            "EngineerBuildAI",
            { categories.ENGINEER * categories.TECH3, 1, 1, "support", "None" }
        },
        T3EngineerOnlyBuild={
            "T3EngineerOnlyBuild",
            "DisbandAI",
            { "xsl0309", 6, 6, "support", "None" }
        },
        T3EngineerOnlyBuild2={
            "T3EngineerOnlyBuild2",
            "DisbandAI",
            { "xsl0309", -1, 6, "support", "None" }
        },
        T3LandAA1={
            "T3LandAA1",
            "PatrolBaseVectorsAI",
            { "dslk004", 1, 3, "attack", "GrowthFormation" }
        },
        T3LandAA2={
            "T3LandAA2",
            "PatrolBaseVectorsAI",
            { "dslk004", -1, 3, "attack", "GrowthFormation" }
        },
        T3LandArtillery1={
            "T3LandArtillery1",
            "PatrolBaseVectorsAI",
            { "xsl0304", 1, 2, "artillery", "GrowthFormation" },
            { "xsl0307", 1, 1, "artillery", "GrowthFormation" }
        },
        T3LandArtillery2={
            "T3LandArtillery2",
            "PatrolBaseVectorsAI",
            { "xsl0304", -1, 2, "artillery", "GrowthFormation" },
            { "xsl0201", -1, 10, "attack", "GrowthFormation" },
            { "xsl0307", 1, 1, "artillery", "GrowthFormation" }
        },
        T3LandBot1={
            "T3LandBot1",
            "PatrolBaseVectorsAI",
            { "xsl0303", 1, 3, "attack", "GrowthFormation" }
        },
        T3LandBot2={
            "T3LandBot2",
            "PatrolBaseVectorsAI",
            { "xsl0303", -1, 3, "attack", "GrowthFormation" },
            { "xsl0201", -1, 10, "attack", "GrowthFormation" }
        },
        T3LandSubCommander1={
            "T3LandSubCommander1",
            "HuntAI",
            { "xsl0301", 3, 3, "support", "GrowthFormation" }
        },
        T3MassFabricator={
            "T3MassFabricator",
            "PauseAI",
            { "xsb1303", 1, 1, "support", "None" }
        },
        T3Nuke={ "T3Nuke", "NukeAI", { "xsb2305", 1, 1, "attack", "None" } },
        T3SeaBattleship1={
            "T3SeaBattleship1",
            "AttackForceAI",
            { "xss0302", -1, 1, "attack", "GrowthFormation" }
        },
        T3SeaCarrier1={
            "T3SeaCarrier1",
            "CarrierAI",
            { "xss0303", -1, 1, "attack", "GrowthFormation" }
        },
        T3SeaNukeSub1={
            "T3SeaNukeSub1",
            "NukeAI",
            { "xss0203", -1, 1, "attack", "GrowthFormation" }
        },
        T4ArtilleryStructure={
            "T4ArtilleryStructure",
            "ArtilleryAI",
            { "xsb2302", 1, 1, "artillery", "None" }
        },
        T4ExperimentalAir={
            "T4ExperimentalAir",
            "DummyAI",
            { "xsa0402", 1, 1, "attack", "None" }
        },
        T4ExperimentalLand1={
            "T4ExperimentalLand1",
            "DummyAI",
            { "xsl0401", 1, 1, "attack", "None" }
        },
        T4ExperimentalLand2={
            "T4ExperimentalLand2",
            "DummyAI",
            { "xsl0401", 1, 1, "attack", "None" }
        },
        T4ExperimentalSea={
            "T4ExperimentalSea",
            "DummyAI",
            { "xss0302", -1, 1, "attack", "None" }
        }
    }
}