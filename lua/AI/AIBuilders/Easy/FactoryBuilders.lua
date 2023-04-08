
BuilderGroup {
    BuilderGroupName = 'EasyEngineerFactoryBuilders',
    BuildersType = 'EngineerBuilder',

    Builder {
        BuilderName = 'Easy - T1 Land Factory Builder',
        PlatoonTemplate = 'CommanderBuilder',
        Priority = 1500,
        BuilderConditions = { },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                Location = 'LocationType',
                BuildStructures = {
                    'T1LandFactory',
                },
            }
        }
    },
}