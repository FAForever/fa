
BuilderGroupsFactories = AIBuilderGroupTemplate {
    BuilderGroupName = 'Easy AI - Factory builders',
    BuilderGroupManager = 'StructureManager',
    BuilderTemplates = {
        rawget(import('/lua/aibrains/templates/builders/builders-easy-structure.lua'), 'UpgradeToTech2LandHQ'),
        rawget(import('/lua/aibrains/templates/builders/builders-easy-structure.lua'), 'UpgradeToTech3LandHQ'),
        rawget(import('/lua/aibrains/templates/builders/builders-easy-structure.lua'), 'UpgradeToTech2Extractor'),
        rawget(import('/lua/aibrains/templates/builders/builders-easy-structure.lua'), 'UpgradeToTech3Extractor'),
    }
}