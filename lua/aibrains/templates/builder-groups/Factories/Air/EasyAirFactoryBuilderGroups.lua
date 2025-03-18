

DefaultAirFactory = AIBuilderGroupTemplate {
    BuilderGroupName = 'Standard land factory builders',
    BuilderGroupManager = 'FactoryManager',
    BuilderGroupType = 'AIR',
    BuilderTemplates = {
        import('/lua/aibrains/templates/builders/Factories/Shared/EasySharedFactoryBuilders.lua').DefaultEngineersTech1,
        import('/lua/aibrains/templates/builders/Factories/Shared/EasySharedFactoryBuilders.lua').DefaultEngineersTech2,
        import('/lua/aibrains/templates/builders/Factories/Shared/EasySharedFactoryBuilders.lua').DefaultEngineersTech3,

        import('/lua/aibrains/templates/builders/Factories/Air/EasyAirFactoryBuilders.lua').DefaultAntiAirTech1,
        import('/lua/aibrains/templates/builders/Factories/Air/EasyAirFactoryBuilders.lua').DefaultAntiAirTech2,
        import('/lua/aibrains/templates/builders/Factories/Air/EasyAirFactoryBuilders.lua').DefaultAntiAirTech3,
        import('/lua/aibrains/templates/builders/Factories/Air/EasyAirFactoryBuilders.lua').DefaultGroundAttackTech1,
        import('/lua/aibrains/templates/builders/Factories/Air/EasyAirFactoryBuilders.lua').DefaultGroundAttackTech2,
        import('/lua/aibrains/templates/builders/Factories/Air/EasyAirFactoryBuilders.lua').DefaultGroundAttackTech3,
    }
}

