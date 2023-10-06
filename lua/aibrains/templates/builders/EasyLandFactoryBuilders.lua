
DefaultDirectFire = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Direct fire units',
    BuilderConditions = {},
    BuilderType = 'LAND',
    BuilderData = {
        Categories = categories.DIRECTFIRE - categories.ANTIAIR,
    },

    BuilderPriority = 200,
}

DefaultAntiAir = AIBuilderTemplate {
    BuilderManager = 'FactoryManager',
    BuilderName = 'Easy AI - Anti air units',
    BuilderConditions = {},
    BuilderType = 'LAND',
    BuilderData = {
        Categories = categories.ANTIAIR,
    },

    BuilderPriority = 200,
}
