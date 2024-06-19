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
    next_platoon_id = '13',
    Platoons = 
    {
        ['OST_AirScout_ScoutPlane'] = {
            'OST_AirScout_ScoutPlane',
            '',
            { 'uea0101', 1, 1, 'scout', 'GrowthFormation' },
        },
        ['OST_AirScout_SpyPlane'] = {
            'OST_AirScout_SpyPlane',
            '',
            { 'uea0302', 1, 1, 'scout', 'GrowthFormation' },
        },
        ['OST_BLANK_TEMPLATE'] = {
            'OST_BLANK_TEMPLATE',
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
                next_platoon_builder_id = '11',
                Builders = {
                    ['OSB_Master_AirScout'] =  {
                        PlatoonTemplate = 'OST_BLANK_TEMPLATE',
                        Priority = 300,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = 600,
                        PlatoonType = 'Any',
                        RequiresConstruction = false,
                        PlatoonAIFunction = {'/lua/ai/opai/airscout_editorfunctions.lua', 'AirScoutPatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','OSB_Master_AirScout'},
                                {'default_brain','OSB_Master_AirScout'}
                            },
                        },
                        PlatoonBuildCallbacks = {
                            {'/lua/ai/opai/airscout_editorfunctions.lua', 'AirScoutDeath',
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
                    ['OSB_Child_AirScout_SpyPlane'] =  {
                        PlatoonTemplate = 'OST_AirScout_SpyPlane',
                        Priority = 299,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = 240,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_AirScout'},
                            }},
                        },
                    },
                    ['OSB_Child_AirScout_ScoutPlane'] =  {
                        PlatoonTemplate = 'OST_AirScout_ScoutPlane',
                        Priority = 298,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = 240,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_AirScout'},
                            }},
                        },
                    },
                },
            },
        },
    },
}
