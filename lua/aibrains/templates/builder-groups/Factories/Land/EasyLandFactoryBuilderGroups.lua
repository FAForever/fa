

DefaultLandFactory = AIBuilderGroupTemplate {
    BuilderGroupName = 'Standard land factory builders',
    BuilderGroupManager = 'FactoryManager',
    BuilderGroupType = 'LAND',
    BuilderTemplates = {
        import('/lua/aibrains/templates/builders/Factories/Shared/EasySharedFactoryBuilders.lua').DefaultEngineersTech1,
        import('/lua/aibrains/templates/builders/Factories/Shared/EasySharedFactoryBuilders.lua').DefaultEngineersTech2,
        import('/lua/aibrains/templates/builders/Factories/Shared/EasySharedFactoryBuilders.lua').DefaultEngineersTech3,

        import('/lua/aibrains/templates/builders/Factories/Land/EasyLandFactoryBuilders.lua').DefaultAntiAirTech1,
        import('/lua/aibrains/templates/builders/Factories/Land/EasyLandFactoryBuilders.lua').DefaultAntiAirTech2,
        import('/lua/aibrains/templates/builders/Factories/Land/EasyLandFactoryBuilders.lua').DefaultAntiAirTech3,
        import('/lua/aibrains/templates/builders/Factories/Land/EasyLandFactoryBuilders.lua').DefaultDirectFireTech1,
        import('/lua/aibrains/templates/builders/Factories/Land/EasyLandFactoryBuilders.lua').DefaultDirectFireTech2,
        import('/lua/aibrains/templates/builders/Factories/Land/EasyLandFactoryBuilders.lua').DefaultDirectFireTech3,
    }
}

