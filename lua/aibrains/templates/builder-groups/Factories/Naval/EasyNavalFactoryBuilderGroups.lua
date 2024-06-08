

DefaultNavalFactory = AIBuilderGroupTemplate {
    BuilderGroupName = 'Standard naval factory builders',
    BuilderGroupManager = 'FactoryManager',
    BuilderGroupType = 'NAVAL',
    BuilderTemplates = {
        import('/lua/aibrains/templates/builders/Factories/Shared/EasySharedFactoryBuilders.lua').DefaultEngineersTech1,
        import('/lua/aibrains/templates/builders/Factories/Shared/EasySharedFactoryBuilders.lua').DefaultEngineersTech2,
        import('/lua/aibrains/templates/builders/Factories/Shared/EasySharedFactoryBuilders.lua').DefaultEngineersTech3,

        import('/lua/aibrains/templates/builders/Factories/Naval/EasyNavalFactoryBuilders.lua').DefaultAntiAirTech1,
        import('/lua/aibrains/templates/builders/Factories/Naval/EasyNavalFactoryBuilders.lua').DefaultAntiAirTech2,
        import('/lua/aibrains/templates/builders/Factories/Naval/EasyNavalFactoryBuilders.lua').DefaultAntiAirTech3,
        import('/lua/aibrains/templates/builders/Factories/Naval/EasyNavalFactoryBuilders.lua').DefaultDirectFireTech1,
        import('/lua/aibrains/templates/builders/Factories/Naval/EasyNavalFactoryBuilders.lua').DefaultDirectFireTech2,
        import('/lua/aibrains/templates/builders/Factories/Naval/EasyNavalFactoryBuilders.lua').DefaultDirectFireTech3,
    }
}

