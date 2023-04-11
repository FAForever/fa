
AIBuilderGroupTemplate {
    Identifier = 'EasyEngineerFactoryBuilders',
    ManagerName = 'EngineerManager',

    AIBuilderTemplate {
        Identifier = 'Easy - T1 Land Factory Builder',
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 1500,
        Conditions = { },
        Type = 'Any',
        Data = {
            Construction = {
                Location = 'LocationType',
                BuildStructures = {
                    'T1LandFactory',
                },
            }
        }
    },
}
