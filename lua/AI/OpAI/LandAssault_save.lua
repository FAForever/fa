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
    next_platoon_id = '27',
    Platoons = 
    {
        ['OST_BLANK_TEMPLATE'] = {
            'OST_BLANK_TEMPLATE',
            '',
        },
        ['OST_LandAssault_AmphibiousTanks'] = {
            'OST_LandAssault_AmphibiousTanks',
            '',
            { 'uel0203', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_LandAssault_HeavyArtillery'] = {
            'OST_LandAssault_HeavyArtillery',
            '',
            { 'uel0304', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_LandAssault_HeavyAssaultBots'] = {
            'OST_LandAssault_HeavyAssaultBots',
            '',
            { 'uel0107', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_LandAssault_HeavyTanks'] = {
            'OST_LandAssault_HeavyTanks',
            '',
            { 'uel0202', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_LandAssault_LightArtillery'] = {
            'OST_LandAssault_LightArtillery',
            '',
            { 'uel0103', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_LandAssault_LightAssaultBots'] = {
            'OST_LandAssault_LightAssaultBots',
            '',
            { 'uel0106', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_LandAssault_MediumTanks'] = {
            'OST_LandAssault_MediumTanks',
            '',
            { 'uel0201', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_LandAssault_MobileAntiAir'] = {
            'OST_LandAssault_MobileAntiAir',
            '',
            { 'uel0104', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_LandAssault_MobileFlak'] = {
            'OST_LandAssault_MobileFlak',
            '',
            { 'uel0205', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_LandAssault_MobileMissile'] = {
            'OST_LandAssault_MobileMissile',
            '',
            { 'uel0111', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_LandAssault_MobileStealth'] = {
            'OST_LandAssault_MobileStealth',
            '',
            { 'uel0306', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_LandAssault_Scout'] = {
            'OST_LandAssault_Scout',
            '',
            { 'uel0101', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_LandAssault_Shields'] = {
            'OST_LandAssault_Shields',
            '',
            { 'uel0307', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_LandAssault_SiegeBots'] = {
            'OST_LandAssault_SiegeBots',
            '',
            { 'uel0303', -1, 5, 'attack', 'AttackFormation' },
        },
        ['OST_LandAssault_T1Transports'] = {
            'OST_LandAssault_T1Transports',
            '',
            { 'uea0107', -1, 5, 'support', 'GrowthFormation' },
        },
        ['OST_LandAssault_T2Transports'] = {
            'OST_LandAssault_T2Transports',
            '',
            { 'uea0104', -1, 5, 'support', 'GrowthFormation' },
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
                next_platoon_builder_id = '11',
                Builders = {
                    ['OSB_Child_LandAssault_LightArtillery'] =  {
                        PlatoonTemplate = 'OST_LandAssault_LightArtillery',
                        Priority = 592,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LandAssault'},
                            }},
                        },
                    },
                    ['OSB_Child_LandAssault_HeavyTanks'] =  {
                        PlatoonTemplate = 'OST_LandAssault_HeavyTanks',
                        Priority = 595,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LandAssault'},
                            }},
                        },
                    },
                    ['OSB_Child_LandAssault_LightAssaultBots'] =  {
                        PlatoonTemplate = 'OST_LandAssault_LightAssaultBots',
                        Priority = 590,
                        InstanceCount = 5,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LandAssault'},
                            }},
                        },
                    },
                    ['OSB_Child_LandAssault_HeavyAssaultBots'] =  {
                        PlatoonTemplate = 'OST_LandAssault_HeavyAssaultBots',
                        Priority = 593,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultChildCountDifficulty',
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
                            {'/lua/editor/platooncountbuildconditions.lua', 'NumBuildersLessThanOSCounter',
                                {'default_brain','default_builder_name', 1 },
                                {'default_brain','default_builder_name','1'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LandAssault'},
                            }},
                        },
                    },
                    ['OSB_Child_LandAssault_Shields'] =  {
                        PlatoonTemplate = 'OST_LandAssault_Shields',
                        Priority = 597,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultChildCountDifficulty',
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
                            {'/lua/editor/platooncountbuildconditions.lua', 'NumBuildersLessThanOSCounter',
                                {'default_brain','default_builder_name', 1 },
                                {'default_brain','default_builder_name','1'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'DifficultyGreaterOrEqual',
                                {'default_brain', 2 },
                                {'default_brain','2'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LandAssault'},
                            }},
                        },
                    },
                    ['OSB_Master_LandAssault'] =  {
                        PlatoonTemplate = 'OST_BLANK_TEMPLATE',
                        Priority = 600,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Any',
                        RequiresConstruction = false,
                        PlatoonAIFunction = {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultAttack',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultMasterCountDifficulty',
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
                    ['OSB_Child_LandAssault_MobileAntiAir'] =  {
                        PlatoonTemplate = 'OST_LandAssault_MobileAntiAir',
                        Priority = 591,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LandAssault'},
                            }},
                        },
                    },
                    ['OSB_Child_LandAssault_AmphibiousTanks'] =  {
                        PlatoonTemplate = 'OST_LandAssault_AmphibiousTanks',
                        Priority = 594,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultChildCountDifficulty',
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
                                {'default_brain', 1 , 3 },
                                {'default_brain','1','3'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LandAssault'},
                            }},
                        },
                    },
                    ['OSB_Child_LandAssault_HeavyArtillery'] =  {
                        PlatoonTemplate = 'OST_LandAssault_HeavyArtillery',
                        Priority = 598,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LandAssault'},
                            }},
                        },
                    },
                    ['OSB_Child_LandAssault_SiegeBots'] =  {
                        PlatoonTemplate = 'OST_LandAssault_SiegeBots',
                        Priority = 599,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LandAssault'},
                            }},
                        },
                    },
                    ['OSB_Child_LandAssault_MobileFlak'] =  {
                        PlatoonTemplate = 'OST_LandAssault_MobileFlak',
                        Priority = 596,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LandAssault'},
                            }},
                        },
                    },
                    ['OSB_Child_LandAssault_T2Transports'] =  {
                        PlatoonTemplate = 'OST_LandAssault_T2Transports',
                        Priority = 999,
                        InstanceCount = 5,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultTransportThread',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultTransport',
                                {'default_brain','default_transport_count'},
                                {'default_brain','default_transport_count'}
                            },
                        },
                        PlatoonData = {
                        },
                    },
                    ['OSB_Child_LandAssault_MobileMissile'] =  {
                        PlatoonTemplate = 'OST_LandAssault_MobileMissile',
                        Priority = 594,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LandAssault'},
                            }},
                        },
                    },
                    ['OSB_Child_LandAssault_MobileStealth'] =  {
                        PlatoonTemplate = 'OST_LandAssault_MobileStealth',
                        Priority = 597,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultChildCountDifficulty',
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
                            {'/lua/editor/platooncountbuildconditions.lua', 'NumBuildersLessThanOSCounter',
                                {'default_brain','default_builder_name', 1 },
                                {'default_brain','default_builder_name','1'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'DifficultyGreaterOrEqual',
                                {'default_brain', 2 },
                                {'default_brain','2'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LandAssault'},
                            }},
                        },
                    },
                    ['OSB_Child_LandAssault_MediumTanks'] =  {
                        PlatoonTemplate = 'OST_LandAssault_MediumTanks',
                        Priority = 593,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultChildCountDifficulty',
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
                            {'/lua/editor/platooncountbuildconditions.lua', 'NumBuildersLessThanOSCounter',
                                {'default_brain','default_builder_name', 1 },
                                {'default_brain','default_builder_name','1'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_LandAssault'},
                            }},
                        },
                    },
                    ['OSB_Child_LandAssault_T1Transports'] =  {
                        PlatoonTemplate = 'OST_LandAssault_T1Transports',
                        Priority = 950,
                        InstanceCount = 5,
                        LocationType = 'MAIN',
                        BuildTimeOut = 500,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultTransportThread',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/landassault_editorfunctions.lua', 'LandAssaultTransport',
                                {'default_brain','default_transport_count'},
                                {'default_brain','default_transport_count'}
                            },
                        },
                        PlatoonData = {
                        },
                    },
                },
            },
        },
    },
}
