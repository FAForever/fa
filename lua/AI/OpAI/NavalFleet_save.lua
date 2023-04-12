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
    next_platoon_id = '17',
    Platoons =
    {
        ['OST_BLANK_TEMPLATE'] = {
            'OST_BLANK_TEMPLATE',
            '',
        },
        ['OST_Battleship_Group_Template'] = {
            'OST_Battleship_Group_Template',
            '',
            { 'ues0302', 0, 1, 'attack', 'attackFormation' },
            { 'ues0201', 0, 2, 'attack', 'attackFormation' },
            { 'ues0202', 0, 2, 'attack', 'attackFormation' },
            { 'ues0103', 0, 2, 'guard', 'attackFormation' },
        },
        ['OST_Cruiser_Group_Template'] = {
            'OST_Cruiser_Group_Template',
            '',
            { 'ues0202', 0, 1, 'attack', 'attackFormation' },
            { 'ues0201', 0, 2, 'attack', 'AttackFormation' },
            { 'ues0103', 0, 4, 'attack', 'attackFormation' },
        },
        ['OST_Destroyer_Group_Template'] = {
            'OST_Destroyer_Group_Template',
            '',
            { 'ues0201', 0, 1, 'attack', 'attackFormation' },
            { 'ues0103', 0, 6, 'attack', 'attackFormation' },
        },
        ['OST_Frigate_Group_Template'] = {
            'OST_Frigate_Group_Template',
            '',
            { 'ues0103', 0, 7, 'attack', 'attackFormation' },
        },
        ['OST_Subs_Template'] = {
            'OST_Subs_Template',
            '',
            { 'ues0203', -1, 6, 'attack', 'attackFormation' },
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
                    ['OSB_Child_NavalFleet_Battleship_Group'] =  {
                        PlatoonTemplate = 'OST_Battleship_Group_Template',
                        Priority = 299,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = -1,
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/ai/opai/navalfleet_editorfunctions.lua', 'NavalFleetChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalFleet'},
                                {type = 2, name = 'APPEND_FleetChildren',  value = 'OSB_Master_NavalFleet'},
                            }},
                        },
                        ChildrenType = { 'Battleship', 'Destroyer', 'Cruiser', 'Frigate' },
                    },
                    ['OSB_Child_NavalFleet_Destroyer_Group'] =  {
                        PlatoonTemplate = 'OST_Destroyer_Group_Template',
                        Priority = 297,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = -1,
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/ai/opai/navalfleet_editorfunctions.lua', 'NavalFleetChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalFleet'},
                                {type = 2, name = 'APPEND_FleetChildren',  value = 'OSB_Master_NavalFleet'},
                            }},
                        },
                        ChildrenType = { 'Battleship', 'Destroyer', 'Frigate' },
                    },
                    ['OSB_Child_NavalFleet_Frigate_Group'] =  {
                        PlatoonTemplate = 'OST_Frigate_Group_Template',
                        Priority = 296,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = -1,
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/ai/opai/navalfleet_editorfunctions.lua', 'NavalFleetChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalFleet'},
                                {type = 2, name = 'APPEND_FleetChildren',  value = 'OSB_Master_NavalFleet'},
                            }},
                        },
                        ChildrenType = { 'Frigate' },
                    },
                    ['OSB_Master_NavalFleet'] =  {
                        PlatoonTemplate = 'OST_BLANK_TEMPLATE',
                        Priority = 300,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = -1,
                        PlatoonType = 'Any',
                        RequiresConstruction = false,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'PlatoonAttackClosestUnit',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/ai/opai/navalfleet_editorfunctions.lua', 'NavalFleetMasterCountDifficulty',
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
                    ['OSB_Child_NavalFleet_Cruiser_Group'] =  {
                        PlatoonTemplate = 'OST_Cruiser_Group_Template',
                        Priority = 298,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = -1,
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/ai/opai/navalfleet_editorfunctions.lua', 'NavalFleetChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalFleet'},
                                {type = 2, name = 'APPEND_FleetChildren',  value = 'OSB_Master_NavalFleet'},
                            }},
                        },
                        ChildrenType = { 'Destroyer', 'Cruiser', 'Frigate' },
                    },
                    ['OSB_Child_NavalFleet_Subs_Group'] =  {
                        PlatoonTemplate = 'OST_Subs_Template',
                        Priority = 295,
                        InstanceCount = 3,
                        LocationType = 'MAIN',
                        BuildTimeOut = -1,
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        BuildConditions = {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/ai/opai/navalfleet_editorfunctions.lua', 'NavalSubChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalFleet'},
                                {type = 2, name = 'APPEND_SubsChildren',  value = 'OSB_Master_NavalFleet'},
                            }},
                        },
                        ChildrenType = { 'Submarine' },
                    },
                },
            },
        },
    },
}
