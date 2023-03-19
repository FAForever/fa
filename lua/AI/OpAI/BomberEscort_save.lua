--[[                                                                           ]]--
--[[  Automatically generated code (do not edit)                               ]]--
--[[                                                                           ]]--
--[[                                                                           ]]--
--[[  Scenario                                                                 ]]--
--[[                                                                           ]]--
Scenario = {
    next_area_id = '1',
    --[[                                                                           ]]--
    --[[  Props                                                                    ]]--
    --[[                                                                           ]]--
    Props = {
    },
    --[[                                                                           ]]--
    --[[  Areas                                                                    ]]--
    --[[                                                                           ]]--
    Areas = {
    },
    --[[                                                                           ]]--
    --[[  Markers                                                                  ]]--
    --[[                                                                           ]]--
    MasterChain = {
        ['_MASTERCHAIN_'] = {
            Markers = {
            },
        },
    },
    Chains = {
    },
    --[[                                                                           ]]--
    --[[  Orders                                                                   ]]--
    --[[                                                                           ]]--
    next_queue_id = '1',
    Orders = {
    },
    --[[                                                                           ]]--
    --[[  Platoons                                                                 ]]--
    --[[                                                                           ]]--
    next_platoon_id = '18',
    Platoons =
    {
        ['OST_BLANK_TEMPLATE'] = {
            'OST_BLANK_TEMPLATE',
            '',
        },
        ['OST_BomberEscort_AirSuperiority'] = {
            'OST_BomberEscort_AirSuperiority',
            '',
            { 'uea0303', -1, 1, 'attack', 'GrowthFormation' },
        },
        ['OST_BomberEscort_Bombers'] = {
            'OST_BomberEscort_Bombers',
            '',
            { 'uea0103', -1, 1, 'artillery', 'GrowthFormation' },
        },
        ['OST_BomberEscort_Gunships'] = {
            'OST_BomberEscort_Gunships',
            '',
            { 'uea0203', -1, 1, 'artillery', 'GrowthFormation' },
        },
        ['OST_BomberEscort_HeavyGunships'] = {
            'OST_BomberEscort_HeavyGunships',
            '',
            { 'uea0305', -1, 1, 'artillery', 'GrowthFormation' },
        },
        ['OST_BomberEscort_Interceptors'] = {
            'OST_BomberEscort_Interceptors',
            '',
            { 'uea0102', -1, 1, 'attack', 'GrowthFormation' },
        },
        ['OST_BomberEscort_StrategicBombers'] = {
            'OST_BomberEscort_StrategicBombers',
            '',
            { 'uea0304', -1, 1, 'artillery', 'GrowthFormation' },
        },
        ['OST_BomberEscort_TorpedoBombers'] = {
            'OST_BomberEscort_TorpedoBombers',
            '',
            { 'uea0204', -1, 1, 'artillery', 'GrowthFormation' },
        },
    },
    --[[                                                                           ]]--
    --[[  Armies                                                                   ]]--
    --[[                                                                           ]]--
    next_army_id = '2',
    next_group_id = '1',
    next_unit_id = '1',
    Armies =
    {
        --[[                                                                           ]]--
        --[[  Army                                                                     ]]--
        --[[                                                                           ]]--
        ['ARMY_1'] =
        {
            personality = '',
            plans = '',
            color = 0,
            faction = 0,
            Economy = {
                mass = 0,
                energy = 0,
            },
            Alliances = {
            },
            ['Units'] = GROUP {
                orders = '',
                platoon = '',
                Units = {
                    ['INITIAL'] = GROUP {
                        orders = '',
                        platoon = '',
                        Units = {
                        },
                    },
                },
            },
            PlatoonBuilders = {
                next_platoon_builder_id = '10',
                Builders = {
                    ['OSB_Child_BomberEscort_Bombers'] =  {
                        PlatoonTemplate = 'OST_BomberEscort_Bombers',
                        Priority = 692,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/bomberescort_editorfunctions.lua', 'BomberEscortChildBomberCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/platooncountbuildconditions.lua', 'NumBuildersLessThanOSCounter',
                                {'default_brain','default_builder_name', 2 },
                                {'default_brain','default_builder_name','2'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_BomberEscort'},
                                {type = 2, name = 'APPEND_BomberChildren',  value = 'OSB_Master_BomberEscort'},
                            }},
                        },
                    },
                    ['OSB_Child_BomberEscort_HeavyGunships'] =  {
                        PlatoonTemplate = 'OST_BomberEscort_HeavyGunships',
                        Priority = 695,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/bomberescort_editorfunctions.lua', 'BomberEscortChildBomberCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/platooncountbuildconditions.lua', 'NumBuildersLessThanOSCounter',
                                {'default_brain','default_builder_name', 1 },
                                {'default_brain','default_builder_name','1'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1 , 0 },
                                {'default_brain','1','0'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_BomberEscort'},
                                {type = 2, name = 'APPEND_BomberChildren',  value = 'OSB_Master_BomberEscort'},
                            }},
                        },
                    },
                    ['OSB_Child_BomberEscort_AirSuperiority'] =  {
                        PlatoonTemplate = 'OST_BomberEscort_AirSuperiority',
                        Priority = 698,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/bomberescort_editorfunctions.lua', 'BomberEscortChildEscortCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/platooncountbuildconditions.lua', 'NumBuildersLessThanOSCounter',
                                {'default_brain','default_builder_name', 2 },
                                {'default_brain','default_builder_name','2'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_BomberEscort'},
                                {type = 2, name = 'APPEND_EscortChildren',  value = 'OSB_Master_BomberEscort'},
                            }},
                        },
                    },
                    ['OSB_Child_BomberEscort_StrategicBombers'] =  {
                        PlatoonTemplate = 'OST_BomberEscort_StrategicBombers',
                        Priority = 696,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/bomberescort_editorfunctions.lua', 'BomberEscortChildBomberCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/platooncountbuildconditions.lua', 'NumBuildersLessThanOSCounter',
                                {'default_brain','default_builder_name', 1 },
                                {'default_brain','default_builder_name','1'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_BomberEscort'},
                                {type = 2, name = 'APPEND_BomberChildren',  value = 'OSB_Master_BomberEscort'},
                            }},
                        },
                    },
                    ['OSB_Master_BomberEscort'] =  {
                        PlatoonTemplate = 'OST_BLANK_TEMPLATE',
                        Priority = 700,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Air',
                        RequiresConstruction = false,
                        PlatoonAIFunction = {'/lua/ai/opai/bomberescort_editorfunctions.lua', 'BomberEscortAI',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/bomberescort_editorfunctions.lua', 'BomberEscortMasterCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonBuildCallbacks = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMUnlockPlatoon',
                                {'default_brain','default_platoon'},
                                {'default_brain','default_platoon'}
                            },
                        },
                        PlatoonAddFunctions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMLockPlatoon',
                                {'default_platoon'},
                                {'default_platoon'}
                            },
                        },
                        PlatoonData = {
                            {type = 3, name = 'AMMasterPlatoon',  value = true},
                            {type = 3, name = 'UsePool', value = false},
                        },
                    },
                    ['OSB_Child_BomberEscort_Gunships'] =  {
                        PlatoonTemplate = 'OST_BomberEscort_Gunships',
                        Priority = 694,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/bomberescort_editorfunctions.lua', 'BomberEscortChildBomberCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/platooncountbuildconditions.lua', 'NumBuildersLessThanOSCounter',
                                {'default_brain','default_builder_name', 2 },
                                {'default_brain','default_builder_name','2'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_BomberEscort'},
                                {type = 2, name = 'APPEND_BomberChildren',  value = 'OSB_Master_BomberEscort'},
                            }},
                        },
                    },
                    ['OSB_Child_BomberEscort_TorpedoBombers'] =  {
                        PlatoonTemplate = 'OST_BomberEscort_TorpedoBombers',
                        Priority = 693,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/bomberescort_editorfunctions.lua', 'BomberEscortChildBomberCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/platooncountbuildconditions.lua', 'NumBuildersLessThanOSCounter',
                                {'default_brain','default_builder_name', 2 },
                                {'default_brain','default_builder_name','2'}
                            },
                            {'/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanNumCategory',
                                {'default_brain','Player', 5 , categories.NAVAL * categories.MOBILE },
                                {'default_brain','Player','5','categories.NAVAL * categories.MOBILE'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_BomberEscort'},
                                {type = 2, name = 'APPEND_BomberChildren',  value = 'OSB_Master_BomberEscort'},
                            }},
                        },
                    },
                    ['OSB_Child_BomberEscort_Interceptors'] =  {
                        PlatoonTemplate = 'OST_BomberEscort_Interceptors',
                        Priority = 696,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/bomberescort_editorfunctions.lua', 'BomberEscortChildEscortCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/platooncountbuildconditions.lua', 'NumBuildersLessThanOSCounter',
                                {'default_brain','default_builder_name', 2 },
                                {'default_brain','default_builder_name','2'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_BomberEscort'},
                                {type = 2, name = 'APPEND_EscortChildren',  value = 'OSB_Master_BomberEscort'},
                            }},
                        },
                    },
                },
            },
        },
    },
}
