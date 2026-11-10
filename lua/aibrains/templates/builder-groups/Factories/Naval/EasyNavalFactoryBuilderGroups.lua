

DefaultNavalFactory = AIBuilderGroupTemplate {
    BuilderGroupName = 'Standard naval factory builders',
    BuilderGroupManager = 'FactoryManager',
    BuilderGroupType = 'NAVAL',
    BuilderTemplates = {
        import('/lua/aibrains/templates/builders/factories/shared/easysharedfactorybuilders.lua').DefaultEngineersTech1,
        import('/lua/aibrains/templates/builders/factories/shared/easysharedfactorybuilders.lua').DefaultEngineersTech2,
        import('/lua/aibrains/templates/builders/factories/shared/easysharedfactorybuilders.lua').DefaultEngineersTech3,

        import('/lua/aibrains/templates/builders/factories/naval/easynavalfactorybuilders.lua').DefaultAntiAirTech1,
        import('/lua/aibrains/templates/builders/factories/naval/easynavalfactorybuilders.lua').DefaultAntiAirTech2,
        import('/lua/aibrains/templates/builders/factories/naval/easynavalfactorybuilders.lua').DefaultAntiAirTech3,
        import('/lua/aibrains/templates/builders/factories/naval/easynavalfactorybuilders.lua').DefaultDirectFireTech1,
        import('/lua/aibrains/templates/builders/factories/naval/easynavalfactorybuilders.lua').DefaultDirectFireTech2,
        import('/lua/aibrains/templates/builders/factories/naval/easynavalfactorybuilders.lua').DefaultDirectFireTech3,
    }
}

