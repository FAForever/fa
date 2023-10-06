

StandardLandFactory = AIBuilderGroupTemplate {
    BuilderGroupName = 'Standard land factory builders',
    BuilderGroupManager = 'FactoryManager',
    BuilderTemplates = {
        rawget(import('/lua/aibrains/templates/builders/Factories/Land/EasyLandFactoryBuilders.lua'), 'DefaultDirectFireTech3'),
        rawget(import('/lua/aibrains/templates/builders/Factories/Land/EasyLandFactoryBuilders.lua'), 'DefaultDirectFireTech2'),
        rawget(import('/lua/aibrains/templates/builders/Factories/Land/EasyLandFactoryBuilders.lua'), 'DefaultDirectFireTech1'),
        rawget(import('/lua/aibrains/templates/builders/Factories/Land/EasyLandFactoryBuilders.lua'), 'DefaultAntiAirTech3'),
        rawget(import('/lua/aibrains/templates/builders/Factories/Land/EasyLandFactoryBuilders.lua'), 'DefaultAntiAirTech2'),
        rawget(import('/lua/aibrains/templates/builders/Factories/Land/EasyLandFactoryBuilders.lua'), 'DefaultAntiAirTech1'),
    }
}

