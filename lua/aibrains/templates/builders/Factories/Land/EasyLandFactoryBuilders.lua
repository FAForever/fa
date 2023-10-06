
local FactoryManagerConditions = import("/lua/aibrains/conditions/FactoryManagerConditions.lua")


DefaultDirectFireTech3 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Direct fire units',
    BuilderConditions = {
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
    BuilderName = 'Easy AI - Direct fire units',
    BuilderConditions = {
        { FactoryManagerConditions.ResearchedTech2 }
    },
    BuilderType = 'LAND',
    BuilderData = {
        Categories = categories.TECH2 * (categories.DIRECTFIRE - categories.ANTIAIR),
    },

    BuilderPriority = 210,
}

DefaultDirectFireTech1 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Direct fire units',
    BuilderConditions = {

    },
    BuilderType = 'LAND',
    BuilderData = {
        Categories = categories.TECH1 * (categories.DIRECTFIRE - categories.ANTIAIR),
    },

    BuilderPriority = 200,
}

DefaultAntiAirTech3 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Anti air units',
    BuilderConditions = {
        { FactoryManagerConditions.ResearchedTech3 }
    },
    BuilderType = 'LAND',
    BuilderData = {
        Categories = categories.TECH3 * (categories.ANTIAIR),
    },

    BuilderPriority = 220,
}

DefaultAntiAirTech2 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Anti air units',
    BuilderConditions = {
        { FactoryManagerConditions.ResearchedTech2 }
    },
    BuilderType = 'LAND',
    BuilderData = {
        Categories = categories.TECH2 * (categories.ANTIAIR),
    },

    BuilderPriority = 210,
}

DefaultAntiAirTech1 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Anti air units',
    BuilderConditions = {},
    BuilderType = 'LAND',
    BuilderData = {
        Categories = categories.TECH1 * (categories.ANTIAIR),
    },

    BuilderPriority = 200,
}
