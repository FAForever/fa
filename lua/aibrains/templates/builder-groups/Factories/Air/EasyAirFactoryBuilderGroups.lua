

DefaultAirFactory = AIBuilderGroupTemplate {
    BuilderGroupName = 'Standard land factory builders',
    BuilderGroupManager = 'FactoryManager',
    BuilderGroupType = 'AIR',
    BuilderTemplates = {
        import('/lua/aibrains/templates/builders/factories/shared/easysharedfactorybuilders.lua').DefaultEngineersTech1,
        import('/lua/aibrains/templates/builders/factories/shared/easysharedfactorybuilders.lua').DefaultEngineersTech2,
        import('/lua/aibrains/templates/builders/factories/shared/easysharedfactorybuilders.lua').DefaultEngineersTech3,

        import('/lua/aibrains/templates/builders/factories/air/easyairfactorybuilders.lua').DefaultAntiAirTech1,
        import('/lua/aibrains/templates/builders/factories/air/easyairfactorybuilders.lua').DefaultAntiAirTech2,
        import('/lua/aibrains/templates/builders/factories/air/easyairfactorybuilders.lua').DefaultAntiAirTech3,
        import('/lua/aibrains/templates/builders/factories/air/easyairfactorybuilders.lua').DefaultGroundAttackTech1,
        import('/lua/aibrains/templates/builders/factories/air/easyairfactorybuilders.lua').DefaultGroundAttackTech2,
        import('/lua/aibrains/templates/builders/factories/air/easyairfactorybuilders.lua').DefaultGroundAttackTech3,
    }
}

