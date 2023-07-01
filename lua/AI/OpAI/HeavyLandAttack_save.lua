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
        ['OST_BLANK_TEMPLATE'] = {
            'OST_BLANK_TEMPLATE',
            '',
        },
        ['OST_HeavyLandAttack_AmphibiousTanks'] = {
            'OST_HeavyLandAttack_AmphibiousTanks',
            '',
            { 'uel0203', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_HeavyLandAttack_HeavyArtillery'] = {
            'OST_HeavyLandAttack_HeavyArtillery',
            '',
            { 'uel0304', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_HeavyLandAttack_HeavyAssaultBots'] = {
            'OST_HeavyLandAttack_HeavyAssaultBots',
            '',
            { 'uel0107', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_HeavyLandAttack_HeavyTanks'] = {
            'OST_HeavyLandAttack_HeavyTanks',
            '',
            { 'uel0202', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_HeavyLandAttack_LightArtillery'] = {
            'OST_HeavyLandAttack_LightArtillery',
            '',
            { 'uel0103', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_HeavyLandAttack_LightAssaultBots'] = {
            'OST_HeavyLandAttack_LightAssaultBots',
            '',
            { 'uel0106', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_HeavyLandAttack_MediumTanks'] = {
            'OST_HeavyLandAttack_MediumTanks',
            '',
            { 'uel0201', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_HeavyLandAttack_MobileAntiAir'] = {
            'OST_HeavyLandAttack_MobileAntiAir',
            '',
            { 'uel0104', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_HeavyLandAttack_MobileFlak'] = {
            'OST_HeavyLandAttack_MobileFlak',
            '',
            { 'uel0205', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_HeavyLandAttack_MobileMissile'] = {
            'OST_HeavyLandAttack_MobileMissile',
            '',
            { 'uel0111', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_HeavyLandAttack_MobileStealth'] = {
            'OST_HeavyLandAttack_MobileStealth',
            '',
            { 'uel0306', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_HeavyLandAttack_Scout'] = {
            'OST_HeavyLandAttack_Scout',
            '',
            { 'uel0101', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_HeavyLandAttack_Shields'] = {
            'OST_HeavyLandAttack_Shields',
            '',
            { 'uel0307', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_HeavyLandAttack_SiegeBots'] = {
            'OST_HeavyLandAttack_SiegeBots',
            '',
            { 'uel0303', -1, 5, 'attack', 'AttackFormation' },
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
                    ['OSB_Child_HeavyLandAttack_MobileMissile'] =  {
                        PlatoonTemplate = 'OST_HeavyLandAttack_MobileMissile',
                        Priority = 496,
                        InstanceCount = 2,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/heavylandattack_editorfunctions.lua', 'HeavyLandAttackChildArtillery',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_HeavyLandAttack'},
                                {type = 2, name = 'APPEND_ArtilleryChildren',  value = 'OSB_Master_HeavyLandAttack'},
                            }},
                        },
                    },
                    ['OSB_Child_HeavyLandAttack_MediumTanks'] =  {
                        PlatoonTemplate = 'OST_HeavyLandAttack_MediumTanks',
                        Priority = 495,
                        InstanceCount = 2,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/heavylandattack_editorfunctions.lua', 'HeavyLandAttackChildDirectFire',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1 , 2 },
                                {'default_brain','1','2'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_HeavyLandAttack'},
                                {type = 2, name = 'APPEND_DirectFireChildren',  value = 'OSB_Master_HeavyLandAttack'},
                            }},
                        },
                    },
                    ['OSB_Child_HeavyLandAttack_LightArtillery'] =  {
                        PlatoonTemplate = 'OST_HeavyLandAttack_LightArtillery',
                        Priority = 494,
                        InstanceCount = 2,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/heavylandattack_editorfunctions.lua', 'HeavyLandAttackChildArtillery',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_HeavyLandAttack'},
                                {type = 2, name = 'APPEND_ArtilleryChildren',  value = 'OSB_Master_HeavyLandAttack'},
                            }},
                        },
                    },
                    ['OSB_Child_HeavyLandAttack_SiegeBots'] =  {
                        PlatoonTemplate = 'OST_HeavyLandAttack_SiegeBots',
                        Priority = 499,
                        InstanceCount = 2,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/heavylandattack_editorfunctions.lua', 'HeavyLandAttackChildDirectFire',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_HeavyLandAttack'},
                                {type = 2, name = 'APPEND_DirectFireChildren',  value = 'OSB_Master_HeavyLandAttack'},
                            }},
                        },
                    },
                    ['OSB_Child_HeavyLandAttack_HeavyTanks'] =  {
                        PlatoonTemplate = 'OST_HeavyLandAttack_HeavyTanks',
                        Priority = 498,
                        InstanceCount = 2,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/heavylandattack_editorfunctions.lua', 'HeavyLandAttackChildDirectFire',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_HeavyLandAttack'},
                                {type = 2, name = 'APPEND_DirectFireChildren',  value = 'OSB_Master_HeavyLandAttack'},
                            }},
                        },
                    },
                    ['OSB_Child_HeavyLandAttack_AmphibiousTanks'] =  {
                        PlatoonTemplate = 'OST_HeavyLandAttack_AmphibiousTanks',
                        Priority = 496,
                        InstanceCount = 4,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/heavylandattack_editorfunctions.lua', 'HeavyLandAttackChildDirectFire',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1 , 3 },
                                {'default_brain','1','3'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_HeavyLandAttack'},
                                {type = 2, name = 'APPEND_DirectFireChildren',  value = 'OSB_Master_HeavyLandAttack'},
                            }},
                        },
                    },
                    ['OSB_Child_HeavyLandAttack_LightAssaultBots'] =  {
                        PlatoonTemplate = 'OST_HeavyLandAttack_LightAssaultBots',
                        Priority = 494,
                        InstanceCount = 4,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/heavylandattack_editorfunctions.lua', 'HeavyLandAttackChildDirectFire',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_HeavyLandAttack'},
                                {type = 2, name = 'APPEND_DirectFireChildren',  value = 'OSB_Master_HeavyLandAttack'},
                            }},
                        },
                    },
                    ['OSB_Child_HeavyLandAttack_MobileFlak'] =  {
                        PlatoonTemplate = 'OST_HeavyLandAttack_MobileFlak',
                        Priority = 495,
                        InstanceCount = 2,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/heavylandattack_editorfunctions.lua', 'HeavyLandAttackChildAntiAir',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_HeavyLandAttack'},
                                {type = 2, name = 'APPEND_AntiAirChildren',  value = 'OSB_Master_HeavyLandAttack'},
                            }},
                        },
                    },
                    ['OSB_Child_HeavyLandAttack_HeavyArtillery'] =  {
                        PlatoonTemplate = 'OST_HeavyLandAttack_HeavyArtillery',
                        Priority = 498,
                        InstanceCount = 2,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/heavylandattack_editorfunctions.lua', 'HeavyLandAttackChildArtillery',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_HeavyLandAttack'},
                                {type = 2, name = 'APPEND_ArtilleryChildren',  value = 'OSB_Master_HeavyLandAttack'},
                            }},
                        },
                    },
                    ['OSB_Child_HeavyLandAttack_MobileAntiAir'] =  {
                        PlatoonTemplate = 'OST_HeavyLandAttack_MobileAntiAir',
                        Priority = 493,
                        InstanceCount = 2,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/heavylandattack_editorfunctions.lua', 'HeavyLandAttackChildAntiAir',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_HeavyLandAttack'},
                                {type = 2, name = 'APPEND_AntiAirChildren',  value = 'OSB_Master_HeavyLandAttack'},
                            }},
                        },
                    },
                    ['OSB_Child_HeavyLandAttack_MobileStealth'] =  {
                        PlatoonTemplate = 'OST_HeavyLandAttack_MobileStealth',
                        Priority = 497,
                        InstanceCount = 2,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/heavylandattack_editorfunctions.lua', 'HeavyLandAttackChildDefensive',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 3 , 0 },
                                {'default_brain','3','0'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_HeavyLandAttack'},
                                {type = 2, name = 'APPEND_DefensiveChildren',  value = 'OSB_Master_HeavyLandAttack'},
                            }},
                        },
                    },
                    ['OSB_Master_HeavyLandAttack'] =  {
                        PlatoonTemplate = 'OST_BLANK_TEMPLATE',
                        Priority = 500,
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
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/ai/opai/heavylandattack_editorfunctions.lua', 'HeavyLandAttackMasterCountDifficulty',
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
                    ['OSB_Child_HeavyLandAttack_Shields'] =  {
                        PlatoonTemplate = 'OST_HeavyLandAttack_Shields',
                        Priority = 497,
                        InstanceCount = 2,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/heavylandattack_editorfunctions.lua', 'HeavyLandAttackChildDefensive',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1 , 2 },
                                {'default_brain','1','2'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_HeavyLandAttack'},
                                {type = 2, name = 'APPEND_DefensiveChildren',  value = 'OSB_Master_HeavyLandAttack'},
                            }},
                        },
                    },
                    ['OSB_Child_HeavyLandAttack_HeavyAssaultBots'] =  {
                        PlatoonTemplate = 'OST_HeavyLandAttack_HeavyAssaultBots',
                        Priority = 495,
                        InstanceCount = 2,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/heavylandattack_editorfunctions.lua', 'HeavyLandAttackChildDirectFire',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 3 , 0 },
                                {'default_brain','3','0'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_HeavyLandAttack'},
                                {type = 2, name = 'APPEND_DirectFireChildren',  value = 'OSB_Master_HeavyLandAttack'},
                            }},
                        },
                    },
                },
            },
        },
    },
}
