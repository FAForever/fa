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
    next_platoon_id = '10',
    Platoons = 
    {
        ['OST_LightAirAttack_Bombers'] = {
            'OST_LightAirAttack_Bombers',
            '',
            { 'uea0103', -1, 6, 'attack', 'GrowthFormation' },
        },
        ['OST_LightAirAttack_Gunships'] = {
            'OST_LightAirAttack_Gunships',
            '',
            { 'uea0203', -1, 6, 'attack', 'GrowthFormation' },
        },
        ['OST_LightAirAttack_HeavyGunships'] = {
            'OST_LightAirAttack_HeavyGunships',
            '',
            { 'uea0305', -1, 6, 'attack', 'GrowthFormation' },
        },
        ['OST_LightAirAttack_Interceptors'] = {
            'OST_LightAirAttack_Interceptors',
            '',
            { 'uea0102', -1, 6, 'attack', 'GrowthFormation' },
        },
        ['OST_LightAirAttack_StratBombers'] = {
            'OST_LightAirAttack_StratBombers',
            '',
            { 'uea0304', -1, 6, 'attack', 'GrowthFormation' },
        },
        ['OST_LightAirAttack_SuperiorityFighters'] = {
            'OST_LightAirAttack_SuperiorityFighters',
            '',
            { 'uea0303', -1, 6, 'attack', 'GrowthFormation' },
        },
        ['OST_LightAirAttack_TorpedoBombers'] = {
            'OST_LightAirAttack_TorpedoBombers',
            '',
            { 'uea0204', -1, 6, 'attack', 'GrowthFormation' },
        },
        ['OST_MASTER_TEMPLATE'] = {
            'OST_MASTER_TEMPLATE',
            '',
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
                next_platoon_builder_id = '8',
                Builders = {
                    ['OSB_Child_LightAirAttack_HeavyGunships'] =  {
                        PlatoonTemplate = 'OST_LightAirAttack_HeavyGunships',
                        Priority = 299,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = 1000,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','OSB_Master_LightAirAttack'},
                                {'default_brain','OSB_Master_LightAirAttack'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1 , 0 },
                                {'default_brain','1','0'}
                            },
                            {'/lua/ai/opai/lightairattack_editorfunctions.lua', 'LightAirChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LightAirAttack'},
                            }},
                        },
                    },
                    ['OSB_Child_LightAirAttack_StrategicBombers'] =  {
                        PlatoonTemplate = 'OST_LightAirAttack_StratBombers',
                        Priority = 298,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = 2000,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','OSB_Master_LightAirAttack'},
                                {'default_brain','OSB_Master_LightAirAttack'}
                            },
                            {'/lua/ai/opai/lightairattack_editorfunctions.lua', 'LightAirChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LightAirAttack'},
                            }},
                        },
                    },
                    ['OSB_Child_LightAirAttack_Bombers'] =  {
                        PlatoonTemplate = 'OST_LightAirAttack_Bombers',
                        Priority = 292,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','OSB_Master_LightAirAttack'},
                                {'default_brain','OSB_Master_LightAirAttack'}
                            },
                            {'/lua/ai/opai/lightairattack_editorfunctions.lua', 'LightAirChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LightAirAttack'},
                            }},
                        },
                    },
                    ['OSB_Child_LightAirAttack_Interceptors'] =  {
                        PlatoonTemplate = 'OST_LightAirAttack_Interceptors',
                        Priority = 291,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','OSB_Master_LightAirAttack'},
                                {'default_brain','OSB_Master_LightAirAttack'}
                            },
                            {'/lua/ai/opai/lightairattack_editorfunctions.lua', 'LightAirChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LightAirAttack'},
                            }},
                        },
                    },
                    ['OSB_Master_LightAirAttack'] =  {
                        PlatoonTemplate = 'OST_MASTER_TEMPLATE',
                        Priority = 300,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = 240,
                        PlatoonType = 'Any',
                        RequiresConstruction = false,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'PlatoonAttackHighestThreat',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','OSB_Master_LightAirAttack'},
                                {'default_brain','OSB_Master_LightAirAttack'}
                            },
                            {'/lua/ai/opai/lightairattack_editorfunctions.lua', 'LightAirMasterCountDifficulty',
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
                    ['OSB_Child_LightAirAttack_Gunships'] =  {
                        PlatoonTemplate = 'OST_LightAirAttack_Gunships',
                        Priority = 294,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','OSB_Master_LightAirAttack'},
                                {'default_brain','OSB_Master_LightAirAttack'}
                            },
                            {'/lua/ai/opai/lightairattack_editorfunctions.lua', 'LightAirChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LightAirAttack'},
                            }},
                        },
                    },
                    ['OSB_Child_LightAirAttack_TorpedoBombers'] =  {
                        PlatoonTemplate = 'OST_LightAirAttack_TorpedoBombers',
                        Priority = 292,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','OSB_Master_LightAirAttack'},
                                {'default_brain','OSB_Master_LightAirAttack'}
                            },
                            {'/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanNumCategory',
                                {'default_brain','Player', 5 , categories.NAVAL },
                                {'default_brain','Player','5','categories.NAVAL'}
                            },
                            {'/lua/ai/opai/lightairattack_editorfunctions.lua', 'LightAirChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LightAirAttack'},
                            }},
                        },
                    },
                    ['OSB_Child_LightAirAttack_AirSuperiorityFighters'] =  {
                        PlatoonTemplate = 'OST_LightAirAttack_SuperiorityFighters',
                        Priority = 297,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = 1000,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','OSB_Master_LightAirAttack'},
                                {'default_brain','OSB_Master_LightAirAttack'}
                            },
                            {'/lua/ai/opai/lightairattack_editorfunctions.lua', 'LightAirChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LightAirAttack'},
                            }},
                        },
                    },
                },
            },
        },
    },
}
