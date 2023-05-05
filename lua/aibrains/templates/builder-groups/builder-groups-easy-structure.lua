
BuilderGroupsFactories = AIBuilderGroupTemplate {
    BuilderGroupName = 'Easy AI - Factory builders',
    BuilderGroupManager = 'StructureManager',
    BuilderTemplates = {
        import('/lua/aibrains/templates/builders/builders-easy-structure.lua').UpgradeToTech2LandHQ,
        import('/lua/aibrains/templates/builders/builders-easy-structure.lua').UpgradeToTech3LandHQ,
    }
}