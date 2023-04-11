
AIBuilderGroupTemplate {
    BuilderGroupName = 'EasyEngineerFactoryBuilders',
    ManagerName = 'EngineerManager',

    AIBuilderTemplate {
        BuilderName = 'Easy - T1 Land Factory Builder',
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 1500,
        BuilderConditions = { },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                Location = 'MAIN',
                BuildStructures = {
                    'T1LandFactory',
                },
            }
        }
    },
}
