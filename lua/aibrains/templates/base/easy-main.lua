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
            rawget(import("/lua/aibrains/templates/builder-groups/Factories/Land/EasyLandFactoryBuilderGroups.lua"), 'StandardLandFactory'),
        },
        BuilderGroupTemplatesNonCheating = {},
    }
}
