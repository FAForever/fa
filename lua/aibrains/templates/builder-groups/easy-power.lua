
AIBuilderGroupTemplate {
    Identifier = 'EasyEngineerPowerBuilders',
    ManagerName = 'EngineerManager',

    AIBuilderTemplate {
        Identifier = 'Easy - T1 Power Engineer',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1100,
        Conditions = { },
        Type = 'Any',
        LocationType = 'MAIN',
        Data = {
            Construction = {
                AdjacencyCategory = categories.FACTORY * categories.STRUCTURE - categories.NAVAL,
                BuildStructures = {
                    'T1EnergyProduction',
                },
            }
        }
    },
}
