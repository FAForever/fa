
AIBuilderGroupTemplate {
    BuilderGroupName = 'EasyEngineerPowerBuilders',
    ManagerName = 'EngineerManager',

    AIBuilderTemplate {
        BuilderName = 'Easy - T1 Power Engineer',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1100,
        BuilderConditions = { },
        BuilderType = 'Any',
        LocationType = 'MAIN',
        BuilderData = {
            Construction = {
                AdjacencyCategory = categories.FACTORY * categories.STRUCTURE - categories.NAVAL,
                BuildStructures = {
                    'T1EnergyProduction',
                },
            }
        }
    },
}
