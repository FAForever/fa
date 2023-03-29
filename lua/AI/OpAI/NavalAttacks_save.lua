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
    next_platoon_id = '14',
    Platoons =
    {
        ['OST_BLANK_TEMPLATE'] = {
            'OST_BLANK_TEMPLATE',
            '',
        },
        -- Common
        ['OST_NavalAttacks_FrigatePlatoon'] = {
            'OST_NavalAttacks_FrigatePlatoon',
            '',
            { 'ues0103', -1, 1, 'attack', 'AttackFormation' }, -- Frigates
        },
        ['OST_NavalAttacks_T1SubmarinePlatoon'] = {
            'OST_NavalAttacks_T1SubmarinePlatoon',
            '',
            { 'ues0203', -1, 1, 'attack', 'AttackFormation' }, -- Submarines
        },
        ['OST_NavalAttacks_T1Platoon1'] = {
            'OST_NavalAttacks_T1Platoon1',
            '',
            { 'ues0103', -1, 1, 'attack', 'AttackFormation' }, -- Frigates
            { 'ues0203', -1, 1, 'attack', 'AttackFormation' }, -- Submarines
        },
        ['OST_NavalAttacks_DestroyerPlatoon'] = {
            'OST_NavalAttacks_DestroyerPlatoon',
            '',
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
        },
        ['OST_NavalAttacks_CruiserPlatoon'] = {
            'OST_NavalAttacks_CruiserPlatoon',
            '',
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
        },
        ['OST_NavalAttacks_T2Platoon1'] = {
            'OST_NavalAttacks_T2Platoon1',
            '',
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
        },
        ['OST_NavalAttacks_T2Platoon2'] = {
            'OST_NavalAttacks_T2Platoon2',
            '',
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0203', -1, 1, 'attack', 'AttackFormation' }, -- Submarines
        },
        ['OST_NavalAttacks_T2Platoon3'] = {
            'OST_NavalAttacks_T2Platoon3',
            '',
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'ues0203', -1, 1, 'attack', 'AttackFormation' }, -- Submarines
        },
        ['OST_NavalAttacks_T2Platoon4'] = {
            'OST_NavalAttacks_T2Platoon4',
            '',
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0103', -1, 1, 'attack', 'AttackFormation' }, -- Frigates
        },
        ['OST_NavalAttacks_T2Platoon5'] = {
            'OST_NavalAttacks_T2Platoon5',
            '',
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0103', -1, 1, 'attack', 'AttackFormation' }, -- Frigates
            { 'ues0203', -1, 1, 'attack', 'AttackFormation' }, -- Submarines
        },
        ['OST_NavalAttacks_T2Platoon6'] = {
            'OST_NavalAttacks_T2Platoon6',
            '',
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'ues0203', -1, 1, 'attack', 'AttackFormation' }, -- Submarines
        },
        ['OST_NavalAttacks_T2Platoon7'] = {
            'OST_NavalAttacks_T2Platoon7',
            '',
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'ues0103', -1, 1, 'attack', 'AttackFormation' }, -- Frigates
        },
        ['OST_NavalAttacks_T2Platoon8'] = {
            'OST_NavalAttacks_T2Platoon8',
            '',
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'ues0103', -1, 1, 'attack', 'AttackFormation' }, -- Frigates
            { 'ues0203', -1, 1, 'attack', 'AttackFormation' }, -- Submarines
        },
        ['OST_NavalAttacks_BattleshipPlatoon'] = {
            'OST_NavalAttacks_BattleshipPlatoon',
            '',
            { 'ues0302', -1, 1, 'attack', 'AttackFormation' }, -- Battleships
        },
        ['OST_NavalAttacks_T3Platoon1'] = {
            'OST_NavalAttacks_T3Platoon1',
            '',
            { 'ues0302', -1, 1, 'attack', 'AttackFormation' }, -- Battleships
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
        },
        ['OST_NavalAttacks_T3Platoon2'] = {
            'OST_NavalAttacks_T3Platoon2',
            '',
            { 'ues0302', -1, 1, 'attack', 'AttackFormation' }, -- Battleships
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
        },
        ['OST_NavalAttacks_T3Platoon3'] = {
            'OST_NavalAttacks_T3Platoon3',
            '',
            { 'ues0302', -1, 1, 'attack', 'AttackFormation' }, -- Battleships
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
        },
        ['OST_NavalAttacks_T3Platoon4'] = {
            'OST_NavalAttacks_T3Platoon4',
            '',
            { 'ues0302', -1, 1, 'attack', 'AttackFormation' }, -- Battleships
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0103', -1, 1, 'attack', 'AttackFormation' }, -- Frigates
        },
        ['OST_NavalAttacks_T3Platoon5'] = {
            'OST_NavalAttacks_T3Platoon5',
            '',
            { 'ues0302', -1, 1, 'attack', 'AttackFormation' }, -- Battleships
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0203', -1, 1, 'attack', 'AttackFormation' }, -- Submarines
        },
        ['OST_NavalAttacks_T3Platoon6'] = {
            'OST_NavalAttacks_T3Platoon6',
            '',
            { 'ues0302', -1, 1, 'attack', 'AttackFormation' }, -- Battleships
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'ues0103', -1, 1, 'attack', 'AttackFormation' }, -- Frigates
        },
        ['OST_NavalAttacks_T3Platoon7'] = {
            'OST_NavalAttacks_T3Platoon7',
            '',
            { 'ues0302', -1, 1, 'attack', 'AttackFormation' }, -- Battleships
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'ues0203', -1, 1, 'attack', 'AttackFormation' }, -- Submarines
        },
        ['OST_NavalAttacks_T3Platoon8'] = {
            'OST_NavalAttacks_T3Platoon8',
            '',
            { 'ues0302', -1, 1, 'attack', 'AttackFormation' }, -- Battleships
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'ues0103', -1, 1, 'attack', 'AttackFormation' }, -- Frigates
        },
        ['OST_NavalAttacks_T3Platoon9'] = {
            'OST_NavalAttacks_T3Platoon9',
            '',
            { 'ues0302', -1, 1, 'attack', 'AttackFormation' }, -- Battleships
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'ues0203', -1, 1, 'attack', 'AttackFormation' }, -- Submarines
        },
        ['OST_NavalAttacks_T3Platoon10'] = {
            'OST_NavalAttacks_T3Platoon10',
            '',
            { 'ues0302', -1, 1, 'attack', 'AttackFormation' }, -- Battleships
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0103', -1, 1, 'attack', 'AttackFormation' }, -- Frigates
            { 'ues0203', -1, 1, 'attack', 'AttackFormation' }, -- Submarines
        },
        ['OST_NavalAttacks_T3Platoon11'] = {
            'OST_NavalAttacks_T3Platoon11',
            '',
            { 'ues0302', -1, 1, 'attack', 'AttackFormation' }, -- Battleships
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'ues0103', -1, 1, 'attack', 'AttackFormation' }, -- Frigates
            { 'ues0203', -1, 1, 'attack', 'AttackFormation' }, -- Submarines
        },
        ['OST_NavalAttacks_T3Platoon12'] = {
            'OST_NavalAttacks_T3Platoon12',
            '',
            { 'ues0302', -1, 1, 'attack', 'AttackFormation' }, -- Battleships
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'ues0103', -1, 1, 'attack', 'AttackFormation' }, -- Frigates
            { 'ues0203', -1, 1, 'attack', 'AttackFormation' }, -- Submarines
        },



        -- Mixed
        ['OST_NavalAttacks_T2SubmarinePlatoon1'] = {
            'OST_NavalAttacks_T2SubmarinePlatoon1',
            '',
            { 'xes0204', -1, 1, 'attack', 'AttackFormation' }, -- T2Submarines
        },
        ['OST_NavalAttacks_T2SubmarinePlatoon2'] = {
            'OST_NavalAttacks_T2SubmarinePlatoon2',
            '',
            { 'xes0204', -1, 1, 'attack', 'AttackFormation' }, -- T2Submarines
            { 'ues0203', -1, 1, 'attack', 'AttackFormation' }, -- Submarines
        },
        ['OST_NavalAttacks_UtilityPlatoon'] = {
            'OST_NavalAttacks_UtilityPlatoon',
            '',
            { 'xes0205', -1, 1, 'attack', 'AttackFormation' }, -- UtilityBoats
        },
        ['OST_NavalAttacks_CarrierPlatoon'] = {
            'OST_NavalAttacks_CarrierPlatoon',
            '',
            { 'ues0303', -1, 1, 'attack', 'AttackFormation' }, -- Carriers
        },
        ['OST_NavalAttacks_NukeSubmarinePlatoon'] = {
            'OST_NavalAttacks_NukeSubmarinePlatoon',
            '',
            { 'ues0304', -1, 1, 'attack', 'AttackFormation' }, -- NukeSubmarines
        },
        ['OST_NavalAttacks_T2MixedPlatoon1'] = {
            'OST_NavalAttacks_T2MixedPlatoon1',
            '',
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'xes0204', -1, 1, 'attack', 'AttackFormation' }, -- T2Submarines
        },
        ['OST_NavalAttacks_T2MixedPlatoon2'] = {
            'OST_NavalAttacks_T2MixedPlatoon2',
            '',
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'xes0204', -1, 1, 'attack', 'AttackFormation' }, -- T2Submarines
        },
        ['OST_NavalAttacks_T2MixedPlatoon3'] = {
            'OST_NavalAttacks_T2MixedPlatoon3',
            '',
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'xes0204', -1, 1, 'attack', 'AttackFormation' }, -- T2Submarines
        },
        ['OST_NavalAttacks_T2MixedPlatoon4'] = {
            'OST_NavalAttacks_T2MixedPlatoon4',
            '',
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'xes0205', -1, 1, 'attack', 'AttackFormation' }, -- UtilityBoats
        },
        ['OST_NavalAttacks_T2MixedPlatoon5'] = {
            'OST_NavalAttacks_T2MixedPlatoon5',
            '',
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'xes0205', -1, 1, 'attack', 'AttackFormation' }, -- UtilityBoats
        },
        ['OST_NavalAttacks_T2MixedPlatoon6'] = {
            'OST_NavalAttacks_T2MixedPlatoon6',
            '',
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'xes0205', -1, 1, 'attack', 'AttackFormation' }, -- UtilityBoats
        },
        ['OST_NavalAttacks_T3MixedPlatoon1'] = {
            'OST_NavalAttacks_T3MixedPlatoon1',
            '',
            { 'ues0302', -1, 1, 'attack', 'AttackFormation' }, -- Battleships
            { 'ues0303', -1, 1, 'attack', 'AttackFormation' }, -- Carriers
        },
        ['OST_NavalAttacks_T3MixedPlatoon2'] = {
            'OST_NavalAttacks_T3MixedPlatoon2',
            '',
            { 'ues0303', -1, 1, 'attack', 'AttackFormation' }, -- Carriers
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
        },



        -- Aeon Specific
        ['OST_NavalAttacks_AABoatPlatoon'] = {
            'OST_NavalAttacks_AABoatPlatoon',
            '',
            { 'uas0102', -1, 1, 'attack', 'AttackFormation' }, -- AABoats
        },
        ['OST_NavalAttacks_T1AeonPlatoon1'] = {
            'OST_NavalAttacks_T1AeonPlatoon1',
            '',
            { 'uas0103', -1, 1, 'attack', 'AttackFormation' }, -- Frigates
            { 'uas0102', -1, 1, 'attack', 'AttackFormation' }, -- AABoats
        },
        ['OST_NavalAttacks_T1AeonPlatoon2'] = {
            'OST_NavalAttacks_T1AeonPlatoon2',
            '',
            { 'uas0203', -1, 1, 'attack', 'AttackFormation' }, -- Submarines
            { 'uas0102', -1, 1, 'attack', 'AttackFormation' }, -- AABoats
        },
        ['OST_NavalAttacks_T1AeonPlatoon3'] = {
            'OST_NavalAttacks_T1AeonPlatoon3',
            '',
            { 'uas0103', -1, 1, 'attack', 'AttackFormation' }, -- Frigates
            { 'uas0203', -1, 1, 'attack', 'AttackFormation' }, -- Submarines
            { 'uas0102', -1, 1, 'attack', 'AttackFormation' }, -- AABoats
        },
        ['OST_NavalAttacks_MissileShipPlatoon'] = {
            'OST_NavalAttacks_MissileShipPlatoon',
            '',
            { 'xas0306', -1, 1, 'attack', 'AttackFormation' }, -- MissleShips
        },
        ['OST_NavalAttacks_AAPlatoon'] = {
            'OST_NavalAttacks_AAPlatoon',
            '',
            { 'uas0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'uas0102', -1, 1, 'attack', 'AttackFormation' }, -- AABoats
        },
        ['OST_NavalAttacks_T2AeonPlatoon1'] = {
            'OST_NavalAttacks_T2AeonPlatoon1',
            '',
            { 'uas0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'uas0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'uas0103', -1, 1, 'attack', 'AttackFormation' }, -- Frigates
            { 'uas0102', -1, 1, 'attack', 'AttackFormation' }, -- AABoats
        },
        ['OST_NavalAttacks_T3AeonPlatoon1'] = {
            'OST_NavalAttacks_T3AeonPlatoon1',
            '',
            { 'uas0302', -1, 1, 'attack', 'AttackFormation' }, -- Battleships
            { 'xas0306', -1, 1, 'attack', 'AttackFormation' }, -- MissleShips
        },
        ['OST_NavalAttacks_T3AeonPlatoon2'] = {
            'OST_NavalAttacks_T3AeonPlatoon2',
            '',
            { 'uas0303', -1, 1, 'attack', 'AttackFormation' }, -- Carriers
            { 'xas0306', -1, 1, 'attack', 'AttackFormation' }, -- MissleShips
        },
        ['OST_NavalAttacks_T3AeonPlatoon3'] = {
            'OST_NavalAttacks_T3AeonPlatoon3',
            '',
            { 'xas0306', -1, 1, 'attack', 'AttackFormation' }, -- MissleShips
            { 'uas0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
        },



        -- Cybran Specific
        ['OST_NavalAttacks_T2CybranPlatoon1'] = {
            'OST_NavalAttacks_T2CybranPlatoon1',
            '',
            { 'urs0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'urs0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'xrs0204', -1, 1, 'attack', 'AttackFormation' }, -- T2Submarines
            { 'xrs0205', -1, 1, 'attack', 'AttackFormation' }, -- UtilityBoats
        },



        -- Seraphim Specific
        ['OST_NavalAttacks_T3SubmarinePlatoon'] = {
            'OST_NavalAttacks_T3SubmarinePlatoon',
            '',
            { 'xss0304', -1, 1, 'attack', 'AttackFormation' }, -- T3Submarine
        },
        ['OST_NavalAttacks_T3SeraphimPlatoon1'] = {
            'OST_NavalAttacks_T3SeraphimPlatoon1',
            '',
            { 'xss0302', -1, 1, 'attack', 'AttackFormation' }, -- Battleships
            { 'xss0304', -1, 1, 'attack', 'AttackFormation' }, -- T3Submarine
        },
        ['OST_NavalAttacks_T3SeraphimPlatoon2'] = {
            'OST_NavalAttacks_T3SeraphimPlatoon2',
            '',
            { 'xss0303', -1, 1, 'attack', 'AttackFormation' }, -- Carriers
            { 'xss0304', -1, 1, 'attack', 'AttackFormation' }, -- T3Submarine
        },
        ['OST_NavalAttacks_T3SeraphimPlatoon3'] = {
            'OST_NavalAttacks_T3SeraphimPlatoon3',
            '',
            { 'xss0304', -1, 1, 'attack', 'AttackFormation' }, -- T3Submarine
            { 'xss0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
        },



        -- UEF Specific
        ['OST_NavalAttacks_TropBoatPlatoon'] = {
            'OST_NavalAttacks_TropBoatPlatoon',
            '',
            { 'xes0102', -1, 1, 'attack', 'AttackFormation' }, -- TorpedoBoats
        },
        ['OST_NavalAttacks_T2UEFPlatoon1'] = {
            'OST_NavalAttacks_T2UEFPlatoon1',
            '',
            { 'xes0102', -1, 1, 'attack', 'AttackFormation' }, -- TorpedoBoats
            { 'ues0203', -1, 1, 'attack', 'AttackFormation' }, -- Submarines
        },
        ['OST_NavalAttacks_T2UEFPlatoon2'] = {
            'OST_NavalAttacks_T2UEFPlatoon2',
            '',
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'xes0102', -1, 1, 'attack', 'AttackFormation' }, -- TorpedoBoats
        },
        ['OST_NavalAttacks_T2UEFPlatoon3'] = {
            'OST_NavalAttacks_T2UEFPlatoon3',
            '',
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'xes0102', -1, 1, 'attack', 'AttackFormation' }, -- TorpedoBoats
        },
        ['OST_NavalAttacks_T2UEFPlatoon4'] = {
            'OST_NavalAttacks_T2UEFPlatoon4',
            '',
            { 'xes0102', -1, 1, 'attack', 'AttackFormation' }, -- TorpedoBoats
            { 'xes0205', -1, 1, 'attack', 'AttackFormation' }, -- UtilityBoats
        },
        ['OST_NavalAttacks_T2UEFPlatoon5'] = {
            'OST_NavalAttacks_T2UEFPlatoon5',
            '',
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'xes0102', -1, 1, 'attack', 'AttackFormation' }, -- TorpedoBoats
            { 'xes0205', -1, 1, 'attack', 'AttackFormation' }, -- UtilityBoats
        },
        ['OST_NavalAttacks_T2UEFPlatoon6'] = {
            'OST_NavalAttacks_T2UEFPlatoon6',
            '',
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'xes0102', -1, 1, 'attack', 'AttackFormation' }, -- TorpedoBoats
            { 'xes0205', -1, 1, 'attack', 'AttackFormation' }, -- UtilityBoats
        },
        ['OST_NavalAttacks_T2UEFPlatoon7'] = {
            'OST_NavalAttacks_T2UEFPlatoon7',
            '',
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'xes0102', -1, 1, 'attack', 'AttackFormation' }, -- TorpedoBoats
        },
        ['OST_NavalAttacks_T2UEFPlatoon8'] = {
            'OST_NavalAttacks_T2UEFPlatoon8',
            '',
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
            { 'ues0202', -1, 1, 'attack', 'AttackFormation' }, -- Cruisers
            { 'xes0102', -1, 1, 'attack', 'AttackFormation' }, -- TorpedoBoats
            { 'xes0205', -1, 1, 'attack', 'AttackFormation' }, -- UtilityBoats
        },
        ['OST_NavalAttacks_BattleCruiserPlatoon'] = {
            'OST_NavalAttacks_BattleCruiserPlatoon',
            '',
            { 'xes0307', -1, 1, 'attack', 'AttackFormation' }, -- BattleCruisers
        },
        ['OST_NavalAttacks_T3UEFPlatoon1'] = {
            'OST_NavalAttacks_T3UEFPlatoon1',
            '',
            { 'xes0307', -1, 1, 'attack', 'AttackFormation' }, -- BattleCruisers
            { 'ues0302', -1, 1, 'attack', 'AttackFormation' }, -- Battleships
        },
        ['OST_NavalAttacks_T3UEFPlatoon2'] = {
            'OST_NavalAttacks_T3UEFPlatoon2',
            '',
            { 'xes0307', -1, 1, 'attack', 'AttackFormation' }, -- BattleCruisers
            { 'ues0201', -1, 1, 'attack', 'AttackFormation' }, -- Destroyers
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
                next_platoon_builder_id = '14',
                Builders = {
                    -- Common
                    ['OSB_Child_NavalAttacks_FrigatePlatoon'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_FrigatePlatoon',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Frigates'},
                    },
                    ['OSB_Child_NavalAttacks_T1SubmarinePlatoon'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T1SubmarinePlatoon',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T1Platoon1'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T1Platoon1',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Frigates', 'Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_DestroyerPlatoon'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_DestroyerPlatoon',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers'},
                    },
                    ['OSB_Child_NavalAttacks_CruiserPlatoon'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_CruiserPlatoon',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Cruisers'},
                    },
                    ['OSB_Child_NavalAttacks_T2Platoon1'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2Platoon1',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers', 'Cruisers'},
                    },
                    ['OSB_Child_NavalAttacks_T2Platoon2'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2Platoon2',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers', 'Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T2Platoon3'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2Platoon3',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Cruisers', 'Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T2Platoon4'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2Platoon4',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers', 'Frigates'},
                    },
                    ['OSB_Child_NavalAttacks_T2Platoon5'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2Platoon5',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers', 'Frigates', 'Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T2Platoon6'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2Platoon6',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers', 'Cruisers', 'Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T2Platoon7'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2Platoon7',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers', 'Cruisers', 'Frigates'},
                    },
                    ['OSB_Child_NavalAttacks_T2Platoon8'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2Platoon8',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers', 'Cruisers', 'Frigates', 'Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_BattleshipPlatoon'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_BattleshipPlatoon',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Battleships'},
                    },
                    ['OSB_Child_NavalAttacks_T3Platoon1'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3Platoon1',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Battleships', 'Destroyers'},
                    },
                    ['OSB_Child_NavalAttacks_T3Platoon2'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3Platoon2',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Battleships', 'Cruisers'},
                    },
                    ['OSB_Child_NavalAttacks_T3Platoon3'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3Platoon3',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Battleships', 'Destroyers', 'Cruisers'},
                    },
                    ['OSB_Child_NavalAttacks_T3Platoon4'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3Platoon4',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Battleships', 'Destroyers', 'Frigates'},
                    },
                    ['OSB_Child_NavalAttacks_T3Platoon5'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3Platoon5',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Battleships', 'Destroyers', 'Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T3Platoon6'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3Platoon6',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Battleships', 'Cruisers', 'Frigates'},
                    },
                    ['OSB_Child_NavalAttacks_T3Platoon7'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3Platoon7',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Battleships', 'Cruisers', 'Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T3Platoon8'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3Platoon8',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Battleships', 'Destroyers', 'Cruisers', 'Frigates'},
                    },
                    ['OSB_Child_NavalAttacks_T3Platoon9'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3Platoon9',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Battleships', 'Destroyers', 'Cruisers', 'Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T3Platoon10'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3Platoon10',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Battleships', 'Destroyers', 'Frigates', 'Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T3Platoon11'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3Platoon11',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Battleships', 'Cruisers', 'Frigates', 'Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T3Platoon12'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3Platoon12',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
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
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Battleships', 'Destroyers', 'Cruisers', 'Frigates', 'Submarines'},
                    },



                    -- Mixed
                    ['OSB_Child_NavalAttacks_T2SubmarinePlatoon1'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2SubmarinePlatoon1',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 3, 0 },
                                {'default_brain', '2','3', 0 }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'T2Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T2SubmarinePlatoon2'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2SubmarinePlatoon2',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 3, 0 },
                                {'default_brain', '2','3', 0 }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'T2Submarines', 'Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_UtilityPlatoon'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_UtilityPlatoon',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 3, 0 },
                                {'default_brain', '1','3', 0 }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'UtilityBoats'},
                    },
                    ['OSB_Child_NavalAttacks_CarrierPlatoon'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_CarrierPlatoon',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 3, 4 },
                                {'default_brain', '2','3','4' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Carriers'},
                    },
                    ['OSB_Child_NavalAttacks_NukeSubmarinePlatoon'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_NukeSubmarinePlatoon',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 2, 3 },
                                {'default_brain', '1','2','3' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'NukeSubmarines'},
                    },
                    ['OSB_Child_NavalAttacks_T2MixedPlatoon1'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2MixedPlatoon1',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 3, 0 },
                                {'default_brain', '2','3', 0 }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers', 'T2Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T2MixedPlatoon2'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2MixedPlatoon2',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 3, 0 },
                                {'default_brain', '2','3', 0 }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Cruisers', 'T2Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T2MixedPlatoon3'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2MixedPlatoon3',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 3, 0 },
                                {'default_brain', '2','3', 0 }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers', 'Cruisers', 'T2Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T2MixedPlatoon4'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2MixedPlatoon4',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 3, 0 },
                                {'default_brain', '1','3', 0 }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers', 'UtilityBoats'},
                    },
                    ['OSB_Child_NavalAttacks_T2MixedPlatoon5'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2MixedPlatoon5',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 3, 0 },
                                {'default_brain', '1','3', 0 }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Cruisers', 'UtilityBoats'},
                    },
                    ['OSB_Child_NavalAttacks_T2MixedPlatoon6'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2MixedPlatoon6',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 3, 0 },
                                {'default_brain', '1','3', 0 }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers', 'Cruisers', 'UtilityBoats'},
                    },
                    ['OSB_Child_NavalAttacks_T3MixedPlatoon1'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3MixedPlatoon1',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 3, 4, 0 },
                                {'default_brain', '2','3','4','0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Battleships', 'Carriers'},
                    },
                    ['OSB_Child_NavalAttacks_T3MixedPlatoon2'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3MixedPlatoon2',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 3, 4, 0 },
                                {'default_brain', '2','3','4','0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Carriers', 'Cruisers'},
                    },



                    -- Aeon Specific
                    ['OSB_Child_NavalAttacks_AABoatPlatoon'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_AABoatPlatoon',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 0 },
                                {'default_brain', '2', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'AABoats'},
                    },
                    ['OSB_Child_NavalAttacks_T1AeonPlatoon1'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T1AeonPlatoon1',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 0 },
                                {'default_brain', '2', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Frigates', 'AABoats'},
                    },
                    ['OSB_Child_NavalAttacks_T1AeonPlatoon2'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T1AeonPlatoon2',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 0 },
                                {'default_brain', '2', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Submarines', 'AABoats'},
                    },
                    ['OSB_Child_NavalAttacks_T1AeonPlatoon3'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T1AeonPlatoon3',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 0 },
                                {'default_brain', '2', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Frigates', 'Submarines', 'AABoats'},
                    },
                    ['OSB_Child_NavalAttacks_MissileShipPlatoon'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_MissileShipPlatoon',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 0 },
                                {'default_brain', '2', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'MissileShips'},
                    },
                    ['OSB_Child_NavalAttacks_AAPlatoon'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_AAPlatoon',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 0 },
                                {'default_brain', '2', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Cruisers', 'AABoats'},
                    },
                    ['OSB_Child_NavalAttacks_T2AeonPlatoon1'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2AeonPlatoon1',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 0 },
                                {'default_brain', '2', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers', 'Cruisers', 'Frigates', 'AABoats'},
                    },
                    ['OSB_Child_NavalAttacks_T3AeonPlatoon1'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3AeonPlatoon1',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 0 },
                                {'default_brain', '2', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Battleships', 'MissleShips'},
                    },
                    ['OSB_Child_NavalAttacks_T3AeonPlatoon2'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3AeonPlatoon2',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 0 },
                                {'default_brain', '2', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Carriers', 'MissleShips'},
                    },
                    ['OSB_Child_NavalAttacks_T3AeonPlatoon3'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3AeonPlatoon3',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 2, 0 },
                                {'default_brain', '2', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'MissleShips', 'Cruisers'},
                    },



                    -- Cybran Specific
                    ['OSB_Child_NavalAttacks_T2CybranPlatoon1'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2CybranPlatoon1',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 3, 0 },
                                {'default_brain', '3', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers', 'Cruisers', 'T2Submarines', 'UtilityBoats'},
                    },


                    -- Seraphim Specific
                    ['OSB_Child_NavalAttacks_T3SubmarinePlatoon'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3SubmarinePlatoon',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 4, 0 },
                                {'default_brain', '4', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'T3Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T3SeraphimPlatoon1'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3SeraphimPlatoon1',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 4, 0 },
                                {'default_brain', '4', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Battleships', 'T3Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T3SeraphimPlatoon2'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3SeraphimPlatoon2',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 4, 0 },
                                {'default_brain', '4', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Carriers', 'T3Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T3SeraphimPlatoon3'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3SeraphimPlatoon3',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 4, 0 },
                                {'default_brain', '4', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'T3Submarines', 'Destroyers'},
                    },



                    -- UEF Specific
                    ['OSB_Child_NavalAttacks_TropBoatPlatoon'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_TropBoatPlatoon',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 0 },
                                {'default_brain', '1', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'TorpedoBoats'},
                    },
                    ['OSB_Child_NavalAttacks_T2UEFPlatoon1'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2UEFPlatoon1',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 0 },
                                {'default_brain', '1', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'TorpedoBoats', 'Submarines'},
                    },
                    ['OSB_Child_NavalAttacks_T2UEFPlatoon2'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2UEFPlatoon2',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 0 },
                                {'default_brain', '1', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers', 'TorpedoBoats'},
                    },
                    ['OSB_Child_NavalAttacks_T2UEFPlatoon3'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2UEFPlatoon3',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 0 },
                                {'default_brain', '1', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Cruisers', 'TorpedoBoats'},
                    },
                    ['OSB_Child_NavalAttacks_T2UEFPlatoon4'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2UEFPlatoon4',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 0 },
                                {'default_brain', '1', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'TorpedoBoats', 'UtilityBoats'},
                    },
                    ['OSB_Child_NavalAttacks_T2UEFPlatoon5'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2UEFPlatoon5',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 0 },
                                {'default_brain', '1', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers', 'TorpedoBoats', 'UtilityBoats'},
                    },
                    ['OSB_Child_NavalAttacks_T2UEFPlatoon6'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2UEFPlatoon6',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 0 },
                                {'default_brain', '1', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Cruisers', 'TorpedoBoats', 'UtilityBoats'},
                    },
                    ['OSB_Child_NavalAttacks_T2UEFPlatoon7'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2UEFPlatoon7',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 0 },
                                {'default_brain', '1', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers', 'Cruisers', 'TorpedoBoats'},
                    },
                    ['OSB_Child_NavalAttacks_T2UEFPlatoon8'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T2UEFPlatoon8',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 0 },
                                {'default_brain', '1', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'Destroyers', 'Cruisers', 'TorpedoBoats', 'UtilityBoats'},
                    },
                    ['OSB_Child_NavalAttacks_BattleCruiserPlatoon'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_BattleCruiserPlatoon',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 0 },
                                {'default_brain', '1', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'BattleCruisers'},
                    },
                    ['OSB_Child_NavalAttacks_T3UEFPlatoon1'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3UEFPlatoon1',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 0 },
                                {'default_brain', '1', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'BattleCruisers', 'Battleships'},
                    },
                    ['OSB_Child_NavalAttacks_T3UEFPlatoon2'] =  {
                        PlatoonTemplate = 'OST_NavalAttacks_T3UEFPlatoon2',
                        Priority = 696,
                        InstanceCount = 1,
                        LocationType = 'MAIN',
                        PlatoonType = 'Sea',
                        RequiresConstruction = true,
                        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'DefaultOSBasePatrol',
                            {'default_platoon'},
                            {'default_platoon'}
                        },
                        BuildConditions = {
                            {'/lua/ai/opai/navalattacks_editorfunctions.lua', 'NavalAttacksChildCountDifficulty',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                                {'default_brain','default_master'},
                                {'default_brain','default_master'}
                            },
                            {'/lua/editor/miscbuildconditions.lua', 'FactionIndex',
                                {'default_brain', 1, 0 },
                                {'default_brain', '1', '0' }
                            },
                        },
                        PlatoonData = {
                            {type = 5, name = 'AMPlatoons', value = {
                                {type = 2, name = 'String_0',  value = 'OSB_Master_NavalAttacks'},
                            }},
                        },
                        ChildrenType = {'BattleCruisers', 'Destroyers'},
                    },



                    ['OSB_Master_NavalAttacks'] =  {
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
                            {'/lua/ai/opai/NavalAttacks_editorfunctions.lua', 'NavalAttacksMasterCountDifficulty',
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
                },
            },
        },
    },
}
