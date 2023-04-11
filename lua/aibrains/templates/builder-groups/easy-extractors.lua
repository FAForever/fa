AIBuilderGroupTemplate {
    Identifier = 'EasyEngineerExtractorBuilders',
    ManagerName = 'EngineerManager',

    AIBuilderTemplate {
        Identifier = 'Easy - T1ResourceEngineer 40',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1005,
        InstanceCount = 2,
        Conditions = {},
        Type = 'Any',
        LocationType = 'MAIN',
        Data = {
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
