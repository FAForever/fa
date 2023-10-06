
local GenericConditions = import("/lua/aibrains/conditions/GenericConditions.lua")
local FactoryManagerConditions = import("/lua/aibrains/conditions/FactoryManagerConditions.lua")

DefaultGroundAttackTech3 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Air to ground units tech 3',
    BuilderConditions = {
        { GenericConditions.CanBuildTech3 },
        { FactoryManagerConditions.ResearchedTech3 },
    },
    BuilderType = 'AIR',
    BuilderData = {
        Categories = categories.TECH3 * (categories.BOMBER + categories.GROUNDATTACK),
    },

    BuilderPriority = 220,
}

DefaultGroundAttackTech2 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Air to ground units tech 2',
    BuilderConditions = {
        { GenericConditions.CanBuildTech2 },
        { FactoryManagerConditions.ResearchedTech2 }
    },
    BuilderType = 'AIR',
    BuilderData = {
        Categories = categories.TECH2 * (categories.BOMBER + categories.GROUNDATTACK),
    },

    BuilderPriority = 210,
}

DefaultGroundAttackTech1 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Air to ground units tech 1',
    BuilderConditions = {

    },
    BuilderData = {
        Categories = categories.TECH1 * (categories.BOMBER + categories.GROUNDATTACK),
    },

    BuilderPriority = 200,
}

DefaultAntiAirTech3 = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Air to air units tech 3',
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
    BuilderName = 'Easy AI - Air to air units tech 2',
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
    BuilderName = 'Easy AI - Air to air units tech 1',
    BuilderConditions = {},
    BuilderData = {
        Categories = categories.TECH1 * (categories.ANTIAIR),
    },

    BuilderPriority = 200,
}
