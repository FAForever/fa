
StandardLandFactory = AIBuilderGroupTemplate {
    BuilderGroupName = 'Standard land factory builders',
    BuilderGroupManager = 'FactoryManager',
    BuilderTemplates = {
        rawget(import('/lua/aibrains/templates/builders/EasyLandFactoryBuilders.lua'), 'DefaultDirectFire'),
        rawget(import('/lua/aibrains/templates/builders/EasyLandFactoryBuilders.lua'), 'DefaultAntiAir'),
    }
}
