function EngineerAttackChildCount(aiBrain, master, number)
    local ScenarioFramework = import("/lua/scenarioframework.lua")
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master)

    if counter < 1 then
        return true
    else
        return false
    end
end

function EngineerAttackMasterCount(aiBrain, master, number)
    local ScenarioFramework = import("/lua/scenarioframework.lua")
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master)

    if counter >= 1 then
        return true
    else
        return false
    end
end

function NeedEngineerTransports(aiBrain, masterName, locationName)
    local transportPool = aiBrain:GetPlatoonUniquelyNamed('TransportPool')

    return not (transportPool and table.getn(transportPool:GetPlatoonUnits()) > 2)
end



Scenario = {
    Platoons = {
        ['OST_BLANK_TEMPLATE'] = {
            'OST_BLANK_TEMPLATE',
            '',
        },

        ['OST_EngineerAttack_T2Engineers'] = {
            'OST_EngineerAttack_T2Engineers',
            '',
            { 'uel0208', 0, 4, 'attack', 'None' },
            { 'uel0307', 0, 2, 'attack', 'None' },
        },
        ['OST_EngineerAttack_T2Transport'] = {
            'OST_EngineerAttack_T2Transport',
            '',
            { 'uea0104', 0, 1, 'support', 'None' },
        },

        ['OST_EngineerAttack_T2EngineersShieldsSeraphim'] = {
            'OST_EngineerAttack_T2EngineersShieldsSeraphim',
            '',
            { 'uel0208', 0, 6, 'attack', 'None' },
            { 'uel0307', 0, 2, 'attack', 'None' },
        },
        ['OST_EngineerAttack_T2EngineersSeraphim'] = {
            'OST_EngineerAttack_T2EngineersSeraphim',
            '',
            { 'uel0208', 0, 8, 'attack', 'None' },
        },
        ['OST_EngineerAttack_T1EngineersSeraphim'] = {
            'OST_EngineerAttack_T1EngineersSeraphim',
            '',
            { 'uel0105', 0, 2, 'attack', 'None' },
        },
        ['OST_EngineerAttack_T2TransportSeraphim'] = {
            'OST_EngineerAttack_T2TransportSeraphim',
            '',
            { 'uea0104', 0, 1, 'support', 'None' },
        },
        ['OST_EngineerAttack_T1TransportSeraphim'] = {
            'OST_EngineerAttack_T1TransportSeraphim',
            '',
            { 'uea0107', 0, 1, 'support', 'None' },
        },


        ['OST_EngineerAttack_T3Engineers'] = {
            'OST_EngineerAttack_T3Engineers',
            '',
            { 'uel0309', 0, 4, 'attack', 'None' },
            { 'uel0307', 0, 4, 'attack', 'None' },
        },
        ['OST_EngineerAttack_T3Transport'] = {
            'OST_EngineerAttack_T3Transport',
            '',
            { 'xea0306', 0, 1, 'support', 'None' },
        },
        ['OST_EngineerAttack_T2CombatEngineers'] = {
            'OST_EngineerAttack_T2CombatEngineers',
            '',
            { 'xel0209', 0, 1, 'attack', 'None'},
        },
    },

    Armies = {
        ARMY_1 = {
            PlatoonBuilders = {
                Builders = {
                    ['OSB_Child_EngineerAttack_T3Transport'] ={
                        PlatoonTemplate = 'OST_EngineerAttack_T3Transport',
                        Priority = 550,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = -1,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction =
                        {
                            '/lua/ScenarioPlatoonAI.lua', 'TransportPool',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions =
                        {
                            {'/lua/ai/opai/EngineerAttack_save.lua', 'NeedEngineerTransports',
                                {'default_brain','default_master','default_location_type'},
                                {'default_brain','default_master','default_location_type'}
                            },
                            {
                                '/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1 },
                                {'default_brain','1'}
                            },
                        },
                        PlatoonData =
                        {
                        },
                        ChildrenType = {'T3Transports'},
                    },

                    ['OSB_Child_EngineerAttack_T2Transport'] = {
                        PlatoonTemplate = 'OST_EngineerAttack_T2Transport',
                        Priority = 545,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = -1,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction =
                        {
                            '/lua/ScenarioPlatoonAI.lua', 'TransportPool',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions =
                        {
                            {'/lua/ai/opai/EngineerAttack_save.lua', 'NeedEngineerTransports',
                                {'default_brain','default_master','default_location_type'},
                                {'default_brain','default_master','default_location_type'}
                            },
                            {
                                '/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 2, 3 },
                                {'default_brain', '1', '2', '3'}
                            },
                        },
                        PlatoonData =
                        {
                        },
                        ChildrenType = {'T2Transports'},
                    },

                    ['OSB_Child_EngineerAttack_T2TransportSeraphim'] = {
                        PlatoonTemplate = 'OST_EngineerAttack_T2TransportSeraphim',
                        Priority = 546,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = -1,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction =
                        {
                            '/lua/ScenarioPlatoonAI.lua', 'TransportPool',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions =
                        {
                            {'/lua/ai/opai/EngineerAttack_save.lua', 'NeedEngineerTransports',
                                {'default_brain','default_master','default_location_type'},
                                {'default_brain','default_master','default_location_type'}
                            },
                            {
                                '/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 4 },
                                {'default_brain','4'}
                            },
                        },
                        PlatoonData =
                        {
                        },
                        ChildrenType = {'T2Transports'},
                    },

                    ['OSB_Child_EngineerAttack_T1TransportSeraphim'] = {
                        PlatoonTemplate = 'OST_EngineerAttack_T1TransportSeraphim',
                        Priority = 546,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = -1,
                        PlatoonType = 'Air',
                        RequiresConstruction = true,
                        PlatoonAIFunction =
                        {
                            '/lua/ScenarioPlatoonAI.lua', 'TransportPool',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions =
                        {
                            {'/lua/ai/opai/EngineerAttack_save.lua', 'NeedEngineerTransports',
                                {'default_brain','default_master','default_location_type'},
                                {'default_brain','default_master','default_location_type'}
                            },
                        },
                        PlatoonData =
                        {
                        },
                        ChildrenType = {'T1Transports'},
                    },

                    ------------------------------------------------------------------------------------------------
                    ------------------------------------------------------------------------------------------------

                    ['OSB_Child_EngineerAttack_T3Engineers'] = {
                        PlatoonTemplate = 'OST_EngineerAttack_T3Engineers',
                        Priority = 525,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = -1,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction =
                        {
                            '/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions =
                        {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/ai/opai/EngineerAttack_save.lua', 'EngineerAttackChildCount',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {
                                '/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1 },
                                {'default_brain','1'}
                            },
                        },
                        PlatoonData =
                        {
                            {
                                type = 5,
                                name = 'AMPlatoons',
                                value =
                                {
                                    {
                                        type = 2,
                                        name = 'String_0',
                                        value = 'OSB_Master_EngineerAttack'
                                    },
                                }
                            },
                        },
                        ChildrenType = {'T3Engineers'},
                    },

                    ['OSB_Child_EngineerAttack_T2Engineers'] = {
                        PlatoonTemplate = 'OST_EngineerAttack_T2Engineers',
                        Priority = 520,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = -1,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction =
                        {
                            '/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions =
                        {
                            {
                                '/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/ai/opai/EngineerAttack_save.lua', 'EngineerAttackChildCount',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {
                                '/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 2, 3 },
                                {'default_brain', '1', '2', '3'}
                            },
                        },
                        PlatoonData =
                        {
                            {
                                type = 5,
                                name = 'AMPlatoons',
                                value =
                                {
                                    {
                                        type = 2,
                                        name = 'String_0',
                                        value = 'OSB_Master_EngineerAttack'
                                    },
                                }
                            },
                        },
                        ChildrenType = {'T2Engineers'},
                    },

                    ['OSB_Child_EngineerAttack_T2CombatEngineers'] ={
                        PlatoonTemplate = 'OST_EngineerAttack_T2CombatEngineers',
                        Priority = 520,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = -1,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction =
                        {
                            '/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions =
                        {
                            {
                                '/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/ai/opai/EngineerAttack_save.lua', 'EngineerAttackChildCount',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {
                                '/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1 },
                                {'default_brain', '1'}
                            },
                        },
                        PlatoonData =
                        {
                            {
                                type = 5,
                                name = 'AMPlatoons',
                                value =
                                {
                                    {
                                        type = 2,
                                        name = 'String_0',
                                        value = 'OSB_Master_EngineerAttack'
                                    },
                                }
                            },
                        },
                        ChildrenType = {'CombatEngineers'},
                    },

                    ['OSB_Child_EngineerAttack_T2EngineersSeraphim'] = {
                        PlatoonTemplate = 'OST_EngineerAttack_T2EngineersSeraphim',
                        Priority = 516,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = -1,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction =
                        {
                            '/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions =
                        {
                            {
                                '/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/ai/opai/EngineerAttack_save.lua', 'EngineerAttackChildCount',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {
                                '/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 4 },
                                {'default_brain','4'}
                            },
                        },
                        PlatoonData =
                        {
                            {
                                type = 5,
                                name = 'AMPlatoons',
                                value =
                                {
                                    {
                                        type = 2,
                                        name = 'String_0',
                                        value = 'OSB_Master_EngineerAttack'
                                    },
                                }
                            },
                        },
                        ChildrenType = {'T2Engineers'},
                    },

                    ['OSB_Child_EngineerAttack_T1EngineersSeraphim'] = {
                        PlatoonTemplate = 'OST_EngineerAttack_T1EngineersSeraphim',
                        Priority = 516,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = -1,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction =
                        {
                            '/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions =
                        {
                            {
                                '/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/ai/opai/EngineerAttack_save.lua', 'EngineerAttackChildCount',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonData =
                        {
                            {
                                type = 5,
                                name = 'AMPlatoons',
                                value =
                                {
                                    {
                                        type = 2,
                                        name = 'String_0',
                                        value = 'OSB_Master_EngineerAttack'
                                    },
                                }
                            },
                        },
                        ChildrenType = {'T1Engineers'},
                    },

                    ['OSB_Child_EngineerAttack_T2EngineersShieldsSeraphim'] = {
                        PlatoonTemplate = 'OST_EngineerAttack_T2EngineersShieldsSeraphim',
                        Priority = 516,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = -1,
                        PlatoonType = 'Land',
                        RequiresConstruction = true,
                        PlatoonAIFunction =
                        {
                            '/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions =
                        {
                            {
                                '/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/ai/opai/EngineerAttack_save.lua', 'EngineerAttackChildCount',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {
                                '/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 4 },
                                {'default_brain','4'}
                            },
                        },
                        PlatoonData =
                        {
                            {
                                type = 5,
                                name = 'AMPlatoons',
                                value =
                                {
                                    {
                                        type = 2,
                                        name = 'String_0',
                                        value = 'OSB_Master_EngineerAttack'
                                    },
                                }
                            },
                        },
                        ChildrenType = {'MobileShields', 'T2Engineers'},
                    },

                    ------------------------------------------------------------------------------------------------
                    ------------------------------------------------------------------------------------------------

                    ['OSB_Master_EngineerAttack'] = {
                        PlatoonTemplate = 'OST_BLANK_TEMPLATE',
                        Priority = 500,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        BuildTimeOut = -1,
                        PlatoonType = 'Any',
                        RequiresConstruction = true,
                        PlatoonAIFunction =
                        {
                            '/lua/ScenarioPlatoonAI.lua', 'PlatoonAttackHighestThreat',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions =
                        {
                            {
                                '/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/ai/opai/EngineerAttack_save.lua', 'EngineerAttackMasterCount',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                        },
                        PlatoonBuildCallbacks =
                        {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMUnlockPlatoon',
                            {'default_brain','default_platoon'},
                            {'default_brain','default_platoon'}},
                        },
                        PlatoonAddFunctions =
                        {
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMLockPlatoon',
                            {'default_platoon'},
                            {'default_platoon'}},
                        },
                        PlatoonData =
                        {
                            {type = 3, name = 'AMMasterPlatoon',  value = true},
                            {type = 3, name = 'UsePool', value = false},
                        },
                    },-- OSB_Master_EngineerAttack
                }, --Builders
            }, --Platoon Builders
        }, --ARMY_1
    }, --Armies
} --Scenario
