AIBuilderGroupTemplate {
    BuilderGroupName = 'EasyEngineerExtractorBuilders',
    ManagerName = 'EngineerManager',

    AIBuilderTemplate {
        BuilderName = 'Easy - T1ResourceEngineer 40',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1005,
        InstanceCount = 2,
        BuilderConditions = {},
        BuilderType = 'Any',
        LocationType = 'MAIN',
        BuilderData = {
            NeedGuard = true,
            DesiresAssist = false,
            Construction = {
                BuildStructures = {
                    'T1Resource',
                }
            }
        }
    },
}
