
BuilderGroupsFactories = AIBuilderGroupTemplate {
    BuilderGroupName = 'Factory upgrade tasks',
    BuilderGroupManager = 'StructureManager',
    BuilderTemplates = {
        rawget(import('/lua/aibrains/templates/builders/builders-easy-structure.lua'), 'UpgradeToTech2LandHQ'),
        rawget(import('/lua/aibrains/templates/builders/builders-easy-structure.lua'), 'UpgradeToTech3LandHQ'),
    }
}

BuilderGroupsResources = AIBuilderGroupTemplate {
    BuilderGroupName = 'Resource upgrade tasks',
    BuilderGroupManager = 'StructureManager',
    BuilderTemplates = {
        rawget(import('/lua/aibrains/templates/builders/builders-easy-structure.lua'), 'UpgradeToTech2Extractor'),
        rawget(import('/lua/aibrains/templates/builders/builders-easy-structure.lua'), 'UpgradeToTech3Extractor'),
    }
}