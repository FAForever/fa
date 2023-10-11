
local GenericConditions = import("/lua/aibrains/conditions/GenericConditions.lua")
local FactoryManagerConditions = import("/lua/aibrains/conditions/FactoryManagerConditions.lua")

DefaultEngineersTech3 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Engineers tech 3',
    BuilderConditions = {
        { GenericConditions.CanBuildTech3 },
        { FactoryManagerConditions.ResearchedTech3 }
    },
    BuilderData = {
        Categories = categories.TECH3 * (categories.ENGINEER),
    },

    BuilderPriority = 220,
}

DefaultEngineersTech2 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Engineers tech 2',
    BuilderConditions = {
        { GenericConditions.CanBuildTech2 },
        { FactoryManagerConditions.ResearchedTech2 }
    },
    BuilderData = {
        Categories = categories.TECH2 * (categories.ENGINEER),
    },

    BuilderPriority = 210,
}

DefaultEngineersTech1 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Engineers tech 1',
    BuilderConditions = {

    },
    BuilderData = {
        Categories = categories.TECH1 * (categories.ENGINEER),
    },

    BuilderPriority = 200,
}
