BaseTemplateMain = AIBaseTemplate {
    BaseTemplateName = 'Easy AI - Main base v1',
    EngineerManager = {
        BuilderGroupTemplates = {},
        BuilderGroupTemplatesNonCheating = {},
    },
    StructureManager = {
        BuilderGroupTemplates = {
            rawget(import("/lua/aibrains/templates/builder-groups/builder-groups-easy-structure.lua"), 'BuilderGroupsFactories'),
            rawget(import("/lua/aibrains/templates/builder-groups/builder-groups-easy-structure.lua"), 'BuilderGroupsResources')
        },
        BuilderGroupTemplatesNonCheating = {},
    },
    FactoryManager = {
        BuilderGroupTemplates = {
            import('/lua/aibrains/templates/builder-groups/Factories/Air/EasyAirFactoryBuilderGroups.lua').DefaultAirFactory,
            import('/lua/aibrains/templates/builder-groups/Factories/Land/EasyLandFactoryBuilderGroups.lua').DefaultLandFactory,
            import('/lua/aibrains/templates/builder-groups/Factories/Naval/EasyNavalFactoryBuilderGroups.lua').DefaultNavalFactory,
        },
        BuilderGroupTemplatesNonCheating = {},
    }
}
