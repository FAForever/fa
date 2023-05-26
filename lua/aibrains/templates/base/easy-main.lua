BaseTemplateMain = AIBaseTemplate {
    BaseTemplateName = 'Easy AI - Main base v1',
    EngineerManager = {
        BuilderGroupTemplates = {},
        BuilderGroupTemplatesNonCheating = {},
    },
    StructureManager = {
        BuilderGroupTemplates = {},
        BuilderGroupTemplatesNonCheating = {},
    },
    FactoryManager = {
        BuilderGroupTemplates = {
            rawget(import("/lua/aibrains/templates/builder-groups/builder-groups-easy-structure.lua"), 'BuilderGroupsFactories')
        },
        BuilderGroupTemplatesNonCheating = {},
    }
}
