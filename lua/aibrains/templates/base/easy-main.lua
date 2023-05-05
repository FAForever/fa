BaseTemplateMain = AIBaseTemplate {
    BaseTemplateName = 'Easy AI - Main base',
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
            import("/lua/aibrains/templates/builder-groups/builder-groups-easy-structure.lua").BuilderGroupsFactories
        },
        BuilderGroupTemplatesNonCheating = {},
    }
}
