
local GenericConditions = import("/lua/aibrains/conditions/GenericConditions.lua")
local FactoryManagerConditions = import("/lua/aibrains/conditions/FactoryManagerConditions.lua")


DefaultDirectFireTech3 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Land direct fire units tech 3',
    BuilderConditions = {
        { GenericConditions.CanBuildTech3 },
        { FactoryManagerConditions.ResearchedTech3 }
    },
    BuilderType = 'LAND',
    BuilderData = {
        Categories = categories.TECH3 * (categories.DIRECTFIRE - categories.ANTIAIR),
    },

    BuilderPriority = 220,
}

DefaultDirectFireTech2 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Land direct fire units tech 2',
    BuilderConditions = {
        { GenericConditions.CanBuildTech2 },
        { FactoryManagerConditions.ResearchedTech2 }
    },
    BuilderData = {
        Categories = categories.TECH2 * (categories.DIRECTFIRE - categories.ANTIAIR),
    },

    BuilderPriority = 210,
}

DefaultDirectFireTech1 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Land direct fire units tech 1',
    BuilderConditions = {

    },
    BuilderData = {
        Categories = categories.TECH1 * (categories.DIRECTFIRE - categories.ANTIAIR),
    },

    BuilderPriority = 200,
}

DefaultAntiAirTech3 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Land to air units tech 3',
    BuilderConditions = {
        { GenericConditions.CanBuildTech3 },
        { FactoryManagerConditions.ResearchedTech3 }
    },
    BuilderData = {
        Categories = categories.TECH3 * (categories.ANTIAIR),
    },

    BuilderPriority = 220,
}

DefaultAntiAirTech2 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Land to air units tech 2',
    BuilderConditions = {
        { GenericConditions.CanBuildTech2 },
        { FactoryManagerConditions.ResearchedTech2 }
    },
    BuilderData = {
        Categories = categories.TECH2 * (categories.ANTIAIR),
    },

    BuilderPriority = 210,
}

DefaultAntiAirTech1 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Land to air units tech 1',
    BuilderConditions = {},
    BuilderData = {
        Categories = categories.TECH1 * (categories.ANTIAIR),
    },

    BuilderPriority = 200,
}
