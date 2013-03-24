--*****************************************************************************
--* File: lua/modules/ui/lobby/lobbyOptions.lua
--* Summary: Lobby options
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

-- options that show up in the team options panel
teamOptions =
{
    {
        default = 1,
        label = "<LOC lobui_0088>Spawn",
        help = "<LOC lobui_0089>Determine what positions players spawn on the map",
        key = 'TeamSpawn',
        pref = 'Lobby_Team_Spawn',
        values = {
            {
                text = "<LOC lobui_0090>Random",
                help = "<LOC lobui_0091>Spawn everyone in random locations",
                key = 'random',
            },
            {
                text = "<LOC lobui_0092>Fixed",
                help = "<LOC lobui_0093>Spawn everyone in fixed locations (determined by slot)",
                key = 'fixed',
            },
        },
    },
    {
        default = 1,
        label = "<LOC lobui_0096>Team",
        help = "<LOC lobui_0097>Determines if players may switch teams while in game",
        key = 'TeamLock',
        pref = 'Lobby_Team_Lock',
        values = {
            {
                text = "<LOC lobui_0098>Locked",
                help = "<LOC lobui_0099>Teams are locked once play begins",
                key = 'locked',
            },
            {
                text = "<LOC lobui_0100>Unlocked",
                help = "<LOC lobui_0101>Players may switch teams during play",
                key = 'unlocked',
            },
        },
    },
    {
        default = 1,
        label = "<LOC lobui_0532>Auto Teams",
        help = "<LOC lobui_0533>Auto ally the players before the game starts",
        key = 'AutoTeams',
        pref = 'Lobby_Auto_Teams',
        values = {
            {
                text = "<LOC lobui_0244>None",
                help = "<LOC lobui_0534>No automatic teams",
                key = 'none',
            },
            {
                text = "<LOC lobui_0530>Top vs Bottom",
                help = "<LOC lobui_0535>The game will be Top vs Bottom",
                key = 'tvsb',
            },
            {
                text = "<LOC lobui_0529>Left vs Right",
                help = "<LOC lobui_0536>The game will be Left vs Right",
                key = 'lvsr',
            },
            {
                text = "<LOC lobui_0571>Even Slots vs Odd Slots",
                help = "<LOC lobui_0572>The game will be Even Slots vs Odd Slots",
                key = 'pvsi',
            },
            {
                text = "<LOC lobui_0585>Manual Select",
                help = "<LOC lobui_0586>You can select the teams clicking on the icons in the map preview, it only works with random spawn",
                key = 'manual',
            },
        },
    },
}

globalOpts = {
    {
        default = 4,
        label = "<LOC lobui_0102>Unit Cap",
        help = "<LOC lobui_0103>Set the maximum number of units that can be in play",
        key = 'UnitCap',
        pref = 'Lobby_Gen_Cap',
        values = {
          {
                text = "<LOC lobui_0719>125",
                help = "<LOC lobui_0720>125 units per player may be in play",
                key = '125',
            },
            {
                text = "<LOC lobui_0170>250",
                help = "<LOC lobui_0171>250 units per player may be in play",
                key = '250',
            },
            {
                text = "<LOC lobui_0721>375",
                help = "<LOC lobui_0722>375 units per player may be in play",
                key = '375',
            },
            {
                text = "<LOC lobui_0172>500",
                help = "<LOC lobui_0173>500 units per player may be in play",
                key = '500',
            },
            {
                text = "<LOC lobui_0723>625",
                help = "<LOC lobui_0724>625 units per player may be in play",
                key = '625',
            },
            {
                text = "<LOC lobui_0174>750",
                help = "<LOC lobui_0175>750 units per player may be in play",
                key = '750',
            },
            {
                text = "<LOC lobui_0725>875",
                help = "<LOC lobui_0726>875 units per player may be in play",
                key = '875',
            },
            {
                text = "<LOC lobui_0235>1000",
                help = "<LOC lobui_0236>1000 units per player may be in play",
                key = '1000',
            },
        },
    },
    {
        default = 1,
        label = "<LOC lobui_0112>Fog of War",
        help = "<LOC lobui_0113>Set up how fog of war will be visualized",
        key = 'FogOfWar',
        pref = 'Lobby_Gen_Fog',
        values = {
            {
                text = "<LOC lobui_0114>Explored",
                help = "<LOC lobui_0115>Terrain revealed, but units still need recon data",
                key = 'explored',
            },
            {
                text = "<LOC lobui_0118>None",
                help = "<LOC lobui_0119>All terrain and units visible",
                key = 'none',
            },
        },
    },
    {
        default = 1,
        label = "<LOC lobui_0120>Victory Condition",
        help = "<LOC lobui_0121>Determines how a victory can be achieved",
        key = 'Victory',
        pref = 'Lobby_Gen_Victory',
        values = {
            {
                text = "<LOC lobui_0122>Assassination",
                help = "<LOC lobui_0123>Game ends when commander is destroyed",
                key = 'demoralization',
            },
            {
                text = "<LOC lobui_0124>Supremacy",
                help = "<LOC lobui_0125>Game ends when all structures, commanders and engineers are destroyed",
                key = 'domination',
            },
            {
                text = "<LOC lobui_0126>Annihilation",
                help = "<LOC lobui_0127>Game ends when all units are destroyed",
                key = 'eradication',
            },
            {
                text = "<LOC lobui_0128>Sandbox",
                help = "<LOC lobui_0129>Game never ends",
                key = 'sandbox',
            },
        },
    },
    {
        default = 2,
        label = "<LOC lobui_0242>Timeouts",
        help = "<LOC lobui_0243>Sets the number of timeouts each player can request",
        key = 'Timeouts',
        pref = 'Lobby_Gen_Timeouts',
        mponly = true,
        values = {
            {
                text = "<LOC lobui_0244>None",
                help = "<LOC lobui_0245>No timeouts are allowed",
                key = '0',
            },
            {
                text = "<LOC lobui_0246>Three",
                help = "<LOC lobui_0247>Each player has three timeouts",
                key = '3',
            },
            {
                text = "<LOC lobui_0248>Infinite",
                help = "<LOC lobui_0249>There is no limit on timeouts",
                key = '-1',
            },
        },
    },
    {
        default = 1,
        label = "<LOC lobui_0258>Game Speed",
        help = "<LOC lobui_0259>Set the game speed",
        key = 'GameSpeed',
        pref = 'Lobby_Gen_GameSpeed',
        values = {
            {
                text = "<LOC lobui_0260>Normal",
                help = "<LOC lobui_0261>Fixed at the normal game speed (+0)",
                key = 'normal',
            },
            {
                text = "<LOC lobui_0262>Fast",
                help = "<LOC lobui_0263>Fixed at a fast game speed (+4)",
                key = 'fast',
            },
            {
                text = "<LOC lobui_0264>Adjustable",
                help = "<LOC lobui_0265>Adjustable in-game",
                key = 'adjustable',
            },
        },
    },
    {
        default = 1,
        label = "<LOC lobui_0208>Cheating",
        help = "<LOC lobui_0209>Enable cheat codes",
        key = 'CheatsEnabled',
        pref = 'Lobby_Gen_CheatsEnabled',
        values = {
            {
                text = "<LOC _Off>Off",
                help = "<LOC lobui_0210>Cheats disabled",
                key = 'false',
            },
            {
                text = "<LOC _On>On",
                help = "<LOC lobui_0211>Cheats enabled",
                key = 'true',
            },
        },
    },
    {
        default = 1,
        label = "<LOC lobui_0291>Civilians",
        help = "<LOC lobui_0292>Set how civilian units are used",
        key = 'CivilianAlliance',
        pref = 'Lobby_Gen_Civilians',
        values = {
            {
                text = "<LOC lobui_0293>Enemy",
                help = "<LOC lobui_0294>Civilians are enemies of players",
                key = 'enemy',
            },
            {
                text = "<LOC lobui_0295>Neutral",
                help = "<LOC lobui_0296>Civilians are neutral to players",
                key = 'neutral',
            },
            {
                text = "<LOC lobui_0297>None",
                help = "<LOC lobui_0298>No Civilians on the battlefield",
                key = 'removed',
            },
        },
    },
    {
        default = 1,
        label = "<LOC lobui_0310>Prebuilt Units",
        help = "<LOC lobui_0311>Set whether the game starts with prebuilt units or not",
        key = 'PrebuiltUnits',
        pref = 'Lobby_Prebuilt_Units',
        values = {
            {
                text = "<LOC lobui_0312>Off",
                help = "<LOC lobui_0313>No prebuilt units",
                key = 'Off',
            },
            {
                text = "<LOC lobui_0314>On",
                help = "<LOC lobui_0315>Prebuilt units set",
                key = 'On',
            },
        },
    },
    {
        default = 1,
        label = "<LOC lobui_0316>No Rush Option",
        help = "<LOC lobui_0317>Enforce No Rush rules for a certain period of time",
        key = 'NoRushOption',
        pref = 'Lobby_NoRushOption',
        values = {
            {
                text = "<LOC lobui_0318>Off",
                help = "<LOC lobui_0319>Rules not enforced",
                key = 'Off',
            },
            {
                text = "<LOC lobui_0320>5",
                help = "<LOC lobui_0321>Rules enforced for 5 mins",
                key = '5',
            },
            {
                text = "<LOC lobui_0322>10",
                help = "<LOC lobui_0323>Rules enforced for 10 mins",
                key = '10',
            },
            {
                text = "<LOC lobui_0324>20",
                help = "<LOC lobui_0325>Rules enforced for 20 mins",
                key = '20',
            },
        },
    },
    {
        default = 1,
        label = "<LOC lobui_0545>Random Map",
        help = "<LOC lobui_0546>If enabled, the game will selected a random map just before the game launch",
        key = 'RandomMap',
        pref = 'Lobby_Random_Map',
        values = {
            {
                text = "<LOC lobui_0312>Off",
                help = "<LOC lobui_0556>No random map",
                key = 'Off',
            },
         {
                text = "<LOC lobui_0553>Official Maps Only",
                help = "<LOC lobui_0555>Random map set",
                key = 'Official',
            },
            {
                text = "<LOC lobui_0554>All Maps",
                help = "<LOC lobui_0555>Random map set",
                key = 'All',
            },
        },
    },
   {
        default = 1,
        label = "<LOC lobui_0727>Score",
        help = "<LOC lobui_0728>Set score on or off during the game",
        key = 'Score',
        pref = 'Lobby_Score',
        values = {
            {
                text = "<LOC _On>On",
                help = "<LOC lobui_0729>Score is enabled",
                key = 'yes',
            },
            {
                text = "<LOC _Off>Off",
                help = "<LOC lobui_0730>Score is disabled",
                key = 'no',
            },
        },
    },
   {
        default = 1,
        label = "<LOC lobui_0740>Share Conditions",
        help = "<LOC lobui_0741>Kill all the units you shared to your allies and send back the units your allies shared with you when you die",
        key = 'Share',
        pref = 'Lobby_Share',
        values = {
            {
                text = "<LOC lobui_0742>Full Share",
                help = "<LOC lobui_0743>You can give units to your allies and they will not be destroyed when you die",
                key = 'no',
            },
            {
                text = "<LOC lobui_0744>Share Until Death",
                help = "<LOC lobui_0745>All the units you gave to your allies will be destroyed when you die",
                key = 'yes',
            },
        },
    },
}

AIOpts = {
   {
        default = 11,
        label = "AIx Cheat Multiplier",
        help = "Set the cheat multiplier for the cheating AIs.",
        key = 'CheatMult',
        pref = 'Lobby_Cheat_Mult',
        values = {
            {
                text = "1.0",
                help = "Cheat multiplier of 1.0",
                key = '1.0',
            },
            {
                text = "1.1",
                help = "Cheat multiplier of 1.1",
                key = '1.1',
            },
            {
                text = "1.2",
                help = "Cheat multiplier of 1.2",
                key = '1.2',
            },
            {
                text = "1.3",
                help = "Cheat multiplier of 1.3",
                key = '1.3',
            },
            {
                text = "1.4",
                help = "Cheat multiplier of 1.4",
                key = '1.4',
            },
            {
                text = "1.5",
                help = "Cheat multiplier of 1.5",
                key = '1.5',
            },
            {
                text = "1.6",
                help = "Cheat multiplier of 1.6",
                key = '1.6',
            },
            {
                text = "1.7",
                help = "Cheat multiplier of 1.7",
                key = '1.7',
            },
            {
                text = "1.8",
                help = "Cheat multiplier of 1.8",
                key = '1.8',
            },
            {
                text = "1.9",
                help = "Cheat multiplier of 1.9",
                key = '1.9',
            },
            {
                text = "2.0",
                help = "Cheat multiplier of 2.0",
                key = '2.0',
            },
            {
                text = "2.1",
                help = "Cheat multiplier of 2.1",
                key = '2.1',
            },
            {
                text = "2.2",
                help = "Cheat multiplier of 2.2",
                key = '2.2',
            },
            {
                text = "2.3",
                help = "Cheat multiplier of 2.3",
                key = '2.3',
            },
            {
                text = "2.4",
                help = "Cheat multiplier of 2.4",
                key = '2.4',
            },
            {
                text = "2.5",
                help = "Cheat multiplier of 2.5",
                key = '2.5',
            },
            {
                text = "2.6",
                help = "Cheat multiplier of 2.6",
                key = '2.6',
            },
            {
                text = "2.7",
                help = "Cheat multiplier of 2.7",
                key = '2.7',
            },
            {
                text = "2.8",
                help = "Cheat multiplier of 2.8",
                key = '2.8',
            },
            {
                text = "2.9",
                help = "Cheat multiplier of 2.9",
                key = '2.9',
            },
            {
                text = "3.0",
                help = "Cheat multiplier of 3.0",
                key = '3.0',
            },
            {
                text = "3.1",
                help = "Cheat multiplier of 3.1",
                key = '3.1',
            },
            {
                text = "3.2",
                help = "Cheat multiplier of 3.2",
                key = '3.2',
            },
            {
                text = "3.3",
                help = "Cheat multiplier of 3.3",
                key = '3.3',
            },
            {
                text = "3.4",
                help = "Cheat multiplier of 3.4",
                key = '3.4',
            },
            {
                text = "3.5",
                help = "Cheat multiplier of 3.5",
                key = '3.5',
            },
            {
                text = "3.6",
                help = "Cheat multiplier of 3.6",
                key = '3.6',
            },
            {
                text = "3.7",
                help = "Cheat multiplier of 3.7",
                key = '3.7',
            },
            {
                text = "3.8",
                help = "Cheat multiplier of 3.8",
                key = '3.8',
            },
            {
                text = "3.9",
                help = "Cheat multiplier of 3.9",
                key = '3.9',
            },
            {
                text = "4.0",
                help = "Cheat multiplier of 4.0",
                key = '4.0',
            },
            {
                text = "4.1",
                help = "Cheat multiplier of 4.1",
                key = '4.1',
            },
            {
                text = "4.2",
                help = "Cheat multiplier of 4.2",
                key = '4.2',
            },
            {
                text = "4.3",
                help = "Cheat multiplier of 4.3",
                key = '4.3',
            },
            {
                text = "4.4",
                help = "Cheat multiplier of 4.4",
                key = '4.4',
            },
            {
                text = "4.5",
                help = "Cheat multiplier of 4.5",
                key = '4.5',
            },
            {
                text = "4.6",
                help = "Cheat multiplier of 4.6",
                key = '4.6',
            },
            {
                text = "4.7",
                help = "Cheat multiplier of 4.7",
                key = '4.7',
            },
            {
                text = "4.8",
                help = "Cheat multiplier of 4.8",
                key = '4.8',
            },
            {
                text = "4.9",
                help = "Cheat multiplier of 4.9",
                key = '4.9',
            },
            {
                text = "5.0",
                help = "Cheat multiplier of 5.0",
                key = '5.0',
            },
            {
                text = "5.1",
                help = "Cheat multiplier of 5.1",
                key = '5.1',
            },
            {
                text = "5.2",
                help = "Cheat multiplier of 5.2",
                key = '5.2',
            },
            {
                text = "5.3",
                help = "Cheat multiplier of 5.3",
                key = '5.3',
            },
            {
                text = "5.4",
                help = "Cheat multiplier of 5.4",
                key = '5.4',
            },
            {
                text = "5.5",
                help = "Cheat multiplier of 5.5",
                key = '5.5',
            },
            {
                text = "5.6",
                help = "Cheat multiplier of 5.6",
                key = '5.6',
            },
            {
                text = "5.7",
                help = "Cheat multiplier of 5.7",
                key = '5.7',
            },
            {
                text = "5.8",
                help = "Cheat multiplier of 5.8",
                key = '5.8',
            },
            {
                text = "5.9",
                help = "Cheat multiplier of 5.9",
                key = '5.9',
            },
            {
                text = "6.0",
                help = "Cheat multiplier of 6.0",
                key = '6.0',
            },
        },
   },
   {   default = 11,
        label = "AIx Build Multiplier",
        help = "Set the build rate multiplier for the cheating AIs.",
        key = 'BuildMult',
        pref = 'Lobby_Build_Mult',
        values = {
            {
                text = "1.0",
                help = "Build multiplier of 1.0",
                key = '1.0',
            },
            {
                text = "1.1",
                help = "Build multiplier of 1.1",
                key = '1.1',
            },
            {
                text = "1.2",
                help = "Build multiplier of 1.2",
                key = '1.2',
            },
            {
                text = "1.3",
                help = "Build multiplier of 1.3",
                key = '1.3',
            },
            {
                text = "1.4",
                help = "Build multiplier of 1.4",
                key = '1.4',
            },
            {
                text = "1.5",
                help = "Build multiplier of 1.5",
                key = '1.5',
            },
            {
                text = "1.6",
                help = "Build multiplier of 1.6",
                key = '1.6',
            },
            {
                text = "1.7",
                help = "Build multiplier of 1.7",
                key = '1.7',
            },
            {
                text = "1.8",
                help = "Build multiplier of 1.8",
                key = '1.8',
            },
            {
                text = "1.9",
                help = "Build multiplier of 1.9",
                key = '1.9',
            },
            {
                text = "2.0",
                help = "Build multiplier of 2.0",
                key = '2.0',
            },
            {
                text = "2.1",
                help = "Build multiplier of 2.1",
                key = '2.1',
            },
            {
                text = "2.2",
                help = "Build multiplier of 2.2",
                key = '2.2',
            },
            {
                text = "2.3",
                help = "Build multiplier of 2.3",
                key = '2.3',
            },
            {
                text = "2.4",
                help = "Build multiplier of 2.4",
                key = '2.4',
            },
            {
                text = "2.5",
                help = "Build multiplier of 2.5",
                key = '2.5',
            },
            {
                text = "2.6",
                help = "Build multiplier of 2.6",
                key = '2.6',
            },
            {
                text = "2.7",
                help = "Build multiplier of 2.7",
                key = '2.7',
            },
            {
                text = "2.8",
                help = "Build multiplier of 2.8",
                key = '2.8',
            },
            {
                text = "2.9",
                help = "Build multiplier of 2.9",
                key = '2.9',
            },
            {
                text = "3.0",
                help = "Build multiplier of 3.0",
                key = '3.0',
            },
            {
                text = "3.1",
                help = "Build multiplier of 3.1",
                key = '3.1',
            },
            {
                text = "3.2",
                help = "Build multiplier of 3.2",
                key = '3.2',
            },
            {
                text = "3.3",
                help = "Build multiplier of 3.3",
                key = '3.3',
            },
            {
                text = "3.4",
                help = "Build multiplier of 3.4",
                key = '3.4',
            },
            {
                text = "3.5",
                help = "Build multiplier of 3.5",
                key = '3.5',
            },
            {
                text = "3.6",
                help = "Build multiplier of 3.6",
                key = '3.6',
            },
            {
                text = "3.7",
                help = "Build multiplier of 3.7",
                key = '3.7',
            },
            {
                text = "3.8",
                help = "Build multiplier of 3.8",
                key = '3.8',
            },
            {
                text = "3.9",
                help = "Build multiplier of 3.9",
                key = '3.9',
            },
            {
                text = "4.0",
                help = "Build multiplier of 4.0",
                key = '4.0',
            },
            {
                text = "4.1",
                help = "Build multiplier of 4.1",
                key = '4.1',
            },
            {
                text = "4.2",
                help = "Build multiplier of 4.2",
                key = '4.2',
            },
            {
                text = "4.3",
                help = "Build multiplier of 4.3",
                key = '4.3',
            },
            {
                text = "4.4",
                help = "Build multiplier of 4.4",
                key = '4.4',
            },
            {
                text = "4.5",
                help = "Build multiplier of 4.5",
                key = '4.5',
            },
            {
                text = "4.6",
                help = "Build multiplier of 4.6",
                key = '4.6',
            },
            {
                text = "4.7",
                help = "Build multiplier of 4.7",
                key = '4.7',
            },
            {
                text = "4.8",
                help = "Build multiplier of 4.8",
                key = '4.8',
            },
            {
                text = "4.9",
                help = "Build multiplier of 4.9",
                key = '4.9',
            },
            {
                text = "5.0",
                help = "Build multiplier of 5.0",
                key = '5.0',
            },
            {
                text = "5.1",
                help = "Build multiplier of 5.1",
                key = '5.1',
            },
            {
                text = "5.2",
                help = "Build multiplier of 5.2",
                key = '5.2',
            },
            {
                text = "5.3",
                help = "Build multiplier of 5.3",
                key = '5.3',
            },
            {
                text = "5.4",
                help = "Build multiplier of 5.4",
                key = '5.4',
            },
            {
                text = "5.5",
                help = "Build multiplier of 5.5",
                key = '5.5',
            },
            {
                text = "5.6",
                help = "Build multiplier of 5.6",
                key = '5.6',
            },
            {
                text = "5.7",
                help = "Build multiplier of 5.7",
                key = '5.7',
            },
            {
                text = "5.8",
                help = "Build multiplier of 5.8",
                key = '5.8',
            },
            {
                text = "5.9",
                help = "Build multiplier of 5.9",
                key = '5.9',
            },
            {
                text = "6.0",
                help = "Build multiplier of 6.0",
                key = '6.0',
            },
        },
   },
   {   default = 1,
        label = "AI TML Randomization",
        help = "Sets the randomization for the AI\'s TMLs making them miss more. Higher means less accurate.",
        key = 'TMLRandom',
        pref = 'Lobby_TML_Randomization',
        values = {
            {
                text = "None",
                help = "No Randomization",
                key = '0',
            },
            {
                text = "2.5%",
                help = "2.5% Randomization",
                key = '2.5',
            },
            {
                text = "5%",
                help = "5% Randomization",
                key = '5',
            },
            {
                text = "7.5%",
                help = "7.5% Randomization",
                key = '7.5',
            },
            {
                text = "10%",
                help = "10% Randomization",
                key = '10',
            },
            {
                text = "12.5%",
                help = "12.5% Randomization",
                key = '12.5',
            },
            {
                text = "15%",
                help = "15% Randomization",
                key = '15',
            },
            {
                text = "17.5%",
                help = "17.5% Randomization",
                key = '17.5',
            },
            {
                text = "20%",
                help = "20% Randomization",
                key = '20',
            },
        },
   },
   {   default = 6,
        label = "AI Land Expansion Limit",
        help = "Set the limit for the number of land expansions that each AI can have (will still be modified by the number of AIs).",
        key = 'LandExpansionsAllowed',
        pref = 'Lobby_Land_Expansions_Allowed',
        values = {
            {
                text = "None",
                help = "No Land Expansions Allowed",
                key = '0',
            },
            {
                text = "1",
                help = "1 Land Expansion Allowed",
                key = '1',
            },
         {
                text = "2",
                help = "2 Land Expansions Allowed",
                key = '2',
            },
            {
                text = "3",
                help = "3 Land Expansions Allowed",
                key = '3',
            },
            {
                text = "4",
                help = "4 Land Expansions Allowed",
                key = '4',
            },
            {
                text = "5",
                help = "5 Land Expansions Allowed",
                key = '5',
            },
            {
                text = "6",
                help = "6 Land Expansions Allowed",
                key = '6',
            },
            {
                text = "7",
                help = "7 Land Expansions Allowed",
                key = '7',
            },
            {
                text = "8",
                help = "8 Land Expansions Allowed",
                key = '8',
            },
            {
                text = "Unlimited",
                help = "Unlimited Land Expansions Allowed",
                key = '99999',
            },
        },
   },
   {   default = 5,
        label = "AI Naval Expansion Limit",
        help = "Set the limit for the number of naval expansions that each AI can have.",
        key = 'NavalExpansionsAllowed',
        pref = 'Lobby_Naval_Expansions_Allowed',
        values = {
            {
                text = "None",
                help = "No Naval Expansions Allowed",
                key = '0',
            },
            {
                text = "1",
                help = "1 Naval Expansion Allowed",
                key = '1',
            },
         {
                text = "2",
                help = "2 Naval Expansions Allowed",
                key = '2',
            },
            {
                text = "3",
                help = "3 Naval Expansions Allowed",
                key = '3',
            },
            {
                text = "4",
                help = "4 Naval Expansions Allowed",
                key = '4',
            },
            {
                text = "5",
                help = "5 Naval Expansions Allowed",
                key = '5',
            },
            {
                text = "6",
                help = "6 Naval Expansions Allowed",
                key = '6',
            },
            {
                text = "7",
                help = "7 Naval Expansions Allowed",
                key = '7',
            },
            {
                text = "8",
                help = "8 Naval Expansions Allowed",
                key = '8',
            },
            {
                text = "Unlimited",
                help = "Unlimited Naval Expansions Allowed",
                key = '99999',
            },
        },
   },
   {   default = 1,
        label = "AIx Omni Setting",
        help = "Set the build rate multiplier for the cheating AIs.",
        key = 'OmniCheat',
        pref = 'Lobby_Omni_Cheat',
        values = {
            {
                text = "On",
                help = "Full map omni on",
                key = 'on',
            },
            {
                text = "Off",
                help = "Full map omni off",
                key = 'off',
            },
        },
   },
}