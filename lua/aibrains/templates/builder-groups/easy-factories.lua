
AIBuilderGroupTemplate {
    BuilderGroupName = 'EasyEngineerFactoryBuilders',
    ManagerName = 'EngineerManager',

    AIBuilderTemplate {
        BuilderName = 'Easy - Tech 1 Initial Land Factory',
        Priority = 1500,
        BuilderConditions = { },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildStructures = {
                    'T1LandFactory',
                },
            }
        }
    },
}
