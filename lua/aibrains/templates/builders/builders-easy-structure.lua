UpgradeToTech2LandHQ = AIBuilderTemplate {
    BuilderManager = 'StructureManager',
    BuilderName = 'Easy AI - Upgrade to Tech 2 Land HQ',
    BuilderConditions = {},
    BuilderType = 'STRUCTURE',
    BuilderFaction = 'Any',
    BuilderPriority = 400,
    BuilderData = {
        UseUpgradeToBlueprintField = true,
    },

}

UpgradeToTech3LandHQ = AIBuilderTemplate {
    BuilderManager = 'StructureManager',
    BuilderName = 'Easy AI - Upgrade to Tech 3 Land HQ',
    BuilderConditions = {},
    BuilderType = 'STRUCTURE',
    BuilderFaction = 'Any',
    BuilderData = {
        UseUpgradeToBlueprintField = true,
    },

    BuilderPriority = 400,
}

UpgradeToTech2Extractor = AIBuilderTemplate {
    BuilderManager = 'StructureManager',
    BuilderName = 'Easy AI - Upgrade to Tech 2 Extractor',
    BuilderConditions = {},
    BuilderType = 'MASSEXTRACTION',
    BuilderTech = "TECH1",
    BuilderPriority = 400,
    BuilderData = {
        UseUpgradeToBlueprintField = true,
    },
}

UpgradeToTech3Extractor = AIBuilderTemplate {
    BuilderManager = 'StructureManager',
    BuilderName = 'Easy AI - Upgrade to Tech 3 Extractor',
    BuilderConditions = {},
    BuilderType = 'MASSEXTRACTION',
    BuilderTech = "TECH2",
    BuilderPriority = 400,
    BuilderData = {
        UseUpgradeToBlueprintField = true,
    },
}