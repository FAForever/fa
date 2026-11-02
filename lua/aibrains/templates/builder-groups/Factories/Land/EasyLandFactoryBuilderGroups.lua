

DefaultLandFactory = AIBuilderGroupTemplate {
    BuilderGroupName = 'Standard land factory builders',
    BuilderGroupManager = 'FactoryManager',
    BuilderGroupType = 'LAND',
    BuilderTemplates = {
        import('/lua/aibrains/templates/builders/factories/shared/easysharedfactorybuilders.lua').DefaultEngineersTech1,
        import('/lua/aibrains/templates/builders/factories/shared/easysharedfactorybuilders.lua').DefaultEngineersTech2,
        import('/lua/aibrains/templates/builders/factories/shared/easysharedfactorybuilders.lua').DefaultEngineersTech3,

        import('/lua/aibrains/templates/builders/factories/land/easylandfactorybuilders.lua').DefaultAntiAirTech1,
        import('/lua/aibrains/templates/builders/factories/land/easylandfactorybuilders.lua').DefaultAntiAirTech2,
        import('/lua/aibrains/templates/builders/factories/land/easylandfactorybuilders.lua').DefaultAntiAirTech3,
        import('/lua/aibrains/templates/builders/factories/land/easylandfactorybuilders.lua').DefaultDirectFireTech1,
        import('/lua/aibrains/templates/builders/factories/land/easylandfactorybuilders.lua').DefaultDirectFireTech2,
        import('/lua/aibrains/templates/builders/factories/land/easylandfactorybuilders.lua').DefaultDirectFireTech3,
    }
}

