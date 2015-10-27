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
        default = 2,
        label = "<LOC lobui_0088>Spawn",
        help = "<LOC lobui_0089>Determine what positions players spawn on the map",
        key = 'TeamSpawn',
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
                text = "<LOC lobui_0604>Manual Select",
                help = "<LOC lobui_0605>You can select the teams clicking on the icons in the map preview, it only works with random spawn",
                key = 'manual',
            },
        },
    },
}

globalOpts = {
    {
        default = 8,
        label = "<LOC lobui_0102>Unit Cap",
        help = "<LOC lobui_0103>Set the maximum number of units that can be in play",
        key = 'UnitCap',
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
			{
                text = "<LOC lobui_0430>1250",
                help = "<LOC lobui_0431>1250 units per player may be in play",
                key = '1250',
            },
			{
                text = "<LOC lobui_0432>1500",
                help = "<LOC lobui_0433>1500 units per player may be in play",
                key = '1500',
            },
        },
    },
    {
        default = 1,
        label = "<LOC lobui_0434>Share Unit Cap at Death",
        help = "<LOC lobui_0435>Enable this to share unitcap when a player dies",
        key = 'ShareUnitCap',
        values = {
          {
                text = "<LOC lobui_0436>None",
                help = "<LOC lobui_0437>Do not share unitcap",
                key = 'none',
            },
            {
                text = "<LOC lobui_0438>Allies",
                help = "<LOC lobui_0439>Share unitcap with allies only",
                key = 'allies',
            },
            {
                text = "<LOC lobui_0440>All",
                help = "<LOC lobui_0441>Share unitcap with all players",
                key = 'all',
            },
        },
    },
    {
        default = 1,
        label = "<LOC lobui_0112>Fog of War",
        help = "<LOC lobui_0113>Set up how fog of war will be visualized",
        key = 'FogOfWar',
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
        default = 2,
        label = "<LOC lobui_0592>Allow Observers",
        help = "<LOC lobui_0593>Are observers permitted after the game has started?",
        key = 'AllowObservers',
        values = {
            {
                text = "<LOC _Yes>Yes",
                help = "<LOC lobui_0594>Observers are allowed",
                key = true,
            },
            {
                text = "<LOC _No>No",
                help = "<LOC lobui_0595>Observers are not allowed",
                key = false,
            },
        },
    },
    {
        default = 1,
        label = "<LOC lobui_0208>Cheating",
        help = "<LOC lobui_0209>Enable cheat codes",
        key = 'CheatsEnabled',
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
        default = 2,
        label = "<LOC lobui_0740>Share Conditions",
        help = "<LOC lobui_0741>Kill all the units you shared to your allies and send back the units your allies shared with you when you die",
        key = 'Share',
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
        label = "<LOC aisettings_0001>>AIx Cheat Multiplier",
        help = "<LOC aisettings_0002>Set the cheat multiplier for the cheating AIs.",
        key = 'CheatMult',
        values = {
            {
                text = "1.0",
                help = "<LOC aisettings_0003>Cheat multiplier of 1.0",
                key = '1.0',
            },
            {
                text = "1.1",
                help = "<LOC aisettings_0004>Cheat multiplier of 1.1",
                key = '1.1',
            },
            {
                text = "1.2",
                help = "<LOC aisettings_0005>Cheat multiplier of 1.2",
                key = '1.2',
            },
            {
                text = "1.3",
                help = "<LOC aisettings_0006>Cheat multiplier of 1.3",
                key = '1.3',
            },
            {
                text = "1.4",
                help = "<LOC aisettings_0007>Cheat multiplier of 1.4",
                key = '1.4',
            },
            {
                text = "1.5",
                help = "<LOC aisettings_0008>Cheat multiplier of 1.5",
                key = '1.5',
            },
            {
                text = "1.6",
                help = "<LOC aisettings_0009>Cheat multiplier of 1.6",
                key = '1.6',
            },
            {
                text = "1.7",
                help = "<LOC aisettings_0010>Cheat multiplier of 1.7",
                key = '1.7',
            },
            {
                text = "1.8",
                help = "<LOC aisettings_0011>Cheat multiplier of 1.8",
                key = '1.8',
            },
            {
                text = "1.9",
                help = "<LOC aisettings_0012>Cheat multiplier of 1.9",
                key = '1.9',
            },
            {
                text = "2.0",
                help = "<LOC aisettings_0013>Cheat multiplier of 2.0",
                key = '2.0',
            },
            {
                text = "2.1",
                help = "<LOC aisettings_0014>Cheat multiplier of 2.1",
                key = '2.1',
            },
            {
                text = "2.2",
                help = "<LOC aisettings_0015>Cheat multiplier of 2.2",
                key = '2.2',
            },
            {
                text = "2.3",
                help = "<LOC aisettings_0016>Cheat multiplier of 2.3",
                key = '2.3',
            },
            {
                text = "2.4",
                help = "<LOC aisettings_0017>Cheat multiplier of 2.4",
                key = '2.4',
            },
            {
                text = "2.5",
                help = "<LOC aisettings_0018>Cheat multiplier of 2.5",
                key = '2.5',
            },
            {
                text = "2.6",
                help = "<LOC aisettings_0019>Cheat multiplier of 2.6",
                key = '2.6',
            },
            {
                text = "2.7",
                help = "<LOC aisettings_0020>Cheat multiplier of 2.7",
                key = '2.7',
            },
            {
                text = "2.8",
                help = "<LOC aisettings_0021>Cheat multiplier of 2.8",
                key = '2.8',
            },
            {
                text = "2.9",
                help = "<LOC aisettings_0022>Cheat multiplier of 2.9",
                key = '2.9',
            },
            {
                text = "3.0",
                help = "<LOC aisettings_0023>Cheat multiplier of 3.0",
                key = '3.0',
            },
            {
                text = "3.1",
                help = "<LOC aisettings_0024>Cheat multiplier of 3.1",
                key = '3.1',
            },
            {
                text = "3.2",
                help = "<LOC aisettings_0025>Cheat multiplier of 3.2",
                key = '3.2',
            },
            {
                text = "3.3",
                help = "<LOC aisettings_0026>Cheat multiplier of 3.3",
                key = '3.3',
            },
            {
                text = "3.4",
                help = "<LOC aisettings_0027>Cheat multiplier of 3.4",
                key = '3.4',
            },
            {
                text = "3.5",
                help = "<LOC aisettings_0028>Cheat multiplier of 3.5",
                key = '3.5',
            },
            {
                text = "3.6",
                help = "<LOC aisettings_0029>Cheat multiplier of 3.6",
                key = '3.6',
            },
            {
                text = "3.7",
                help = "<LOC aisettings_0030>Cheat multiplier of 3.7",
                key = '3.7',
            },
            {
                text = "3.8",
                help = "<LOC aisettings_0031>Cheat multiplier of 3.8",
                key = '3.8',
            },
            {
                text = "3.9",
                help = "<LOC aisettings_0032>Cheat multiplier of 3.9",
                key = '3.9',
            },
            {
                text = "4.0",
                help = "<LOC aisettings_0033>Cheat multiplier of 4.0",
                key = '4.0',
            },
            {
                text = "4.1",
                help = "<LOC aisettings_0034>Cheat multiplier of 4.1",
                key = '4.1',
            },
            {
                text = "4.2",
                help = "<LOC aisettings_0035>Cheat multiplier of 4.2",
                key = '4.2',
            },
            {
                text = "4.3",
                help = "<LOC aisettings_0036>Cheat multiplier of 4.3",
                key = '4.3',
            },
            {
                text = "4.4",
                help = "<LOC aisettings_0037>Cheat multiplier of 4.4",
                key = '4.4',
            },
            {
                text = "4.5",
                help = "<LOC aisettings_0038>Cheat multiplier of 4.5",
                key = '4.5',
            },
            {
                text = "4.6",
                help = "<LOC aisettings_0039>Cheat multiplier of 4.6",
                key = '4.6',
            },
            {
                text = "4.7",
                help = "<LOC aisettings_0040>Cheat multiplier of 4.7",
                key = '4.7',
            },
            {
                text = "4.8",
                help = "<LOC aisettings_0041>Cheat multiplier of 4.8",
                key = '4.8',
            },
            {
                text = "4.9",
                help = "<LOC aisettings_0042>Cheat multiplier of 4.9",
                key = '4.9',
            },
            {
                text = "5.0",
                help = "<LOC aisettings_0043>Cheat multiplier of 5.0",
                key = '5.0',
            },
            {
                text = "5.1",
                help = "<LOC aisettings_0044>Cheat multiplier of 5.1",
                key = '5.1',
            },
            {
                text = "5.2",
                help = "<LOC aisettings_0045>Cheat multiplier of 5.2",
                key = '5.2',
            },
            {
                text = "5.3",
                help = "<LOC aisettings_0046>Cheat multiplier of 5.3",
                key = '5.3',
            },
            {
                text = "5.4",
                help = "<LOC aisettings_0047>Cheat multiplier of 5.4",
                key = '5.4',
            },
            {
                text = "5.5",
                help = "<LOC aisettings_0048>Cheat multiplier of 5.5",
                key = '5.5',
            },
            {
                text = "5.6",
                help = "<LOC aisettings_0049>Cheat multiplier of 5.6",
                key = '5.6',
            },
            {
                text = "5.7",
                help = "<LOC aisettings_0050>Cheat multiplier of 5.7",
                key = '5.7',
            },
            {
                text = "5.8",
                help = "<LOC aisettings_0051>Cheat multiplier of 5.8",
                key = '5.8',
            },
            {
                text = "5.9",
                help = "<LOC aisettings_0052>Cheat multiplier of 5.9",
                key = '5.9',
            },
            {
                text = "6.0",
                help = "<LOC aisettings_0053>Cheat multiplier of 6.0",
                key = '6.0',
            },
        },
   },
   {   default = 11,
        label = "<LOC aisettings_0054>AIx Build Multiplier",
        help = "<LOC aisettings_0055>Set the build rate multiplier for the cheating AIs.",
        key = 'BuildMult',
        values = {
            {
                text = "1.0",
                help = "<LOC aisettings_0056>Build multiplier of 1.0",
                key = '1.0',
            },
            {
                text = "1.1",
                help = "<LOC aisettings_0057>Build multiplier of 1.1",
                key = '1.1',
            },
            {
                text = "1.2",
                help = "<LOC aisettings_0058>Build multiplier of 1.2",
                key = '1.2',
            },
            {
                text = "1.3",
                help = "<LOC aisettings_0059>Build multiplier of 1.3",
                key = '1.3',
            },
            {
                text = "1.4",
                help = "<LOC aisettings_0060>Build multiplier of 1.4",
                key = '1.4',
            },
            {
                text = "1.5",
                help = "<LOC aisettings_0061>Build multiplier of 1.5",
                key = '1.5',
            },
            {
                text = "1.6",
                help = "<LOC aisettings_0062>Build multiplier of 1.6",
                key = '1.6',
            },
            {
                text = "1.7",
                help = "<LOC aisettings_0063>Build multiplier of 1.7",
                key = '1.7',
            },
            {
                text = "1.8",
                help = "<LOC aisettings_0064>Build multiplier of 1.8",
                key = '1.8',
            },
            {
                text = "1.9",
                help = "<LOC aisettings_0065>Build multiplier of 1.9",
                key = '1.9',
            },
            {
                text = "2.0",
                help = "<LOC aisettings_0066>Build multiplier of 2.0",
                key = '2.0',
            },
            {
                text = "2.1",
                help = "<LOC aisettings_0067>Build multiplier of 2.1",
                key = '2.1',
            },
            {
                text = "2.2",
                help = "<LOC aisettings_0068>Build multiplier of 2.2",
                key = '2.2',
            },
            {
                text = "2.3",
                help = "<LOC aisettings_0069>Build multiplier of 2.3",
                key = '2.3',
            },
            {
                text = "2.4",
                help = "<LOC aisettings_0070>Build multiplier of 2.4",
                key = '2.4',
            },
            {
                text = "2.5",
                help = "<LOC aisettings_0071>Build multiplier of 2.5",
                key = '2.5',
            },
            {
                text = "2.6",
                help = "<LOC aisettings_0072>Build multiplier of 2.6",
                key = '2.6',
            },
            {
                text = "2.7",
                help = "<LOC aisettings_0073>Build multiplier of 2.7",
                key = '2.7',
            },
            {
                text = "2.8",
                help = "<LOC aisettings_0074>Build multiplier of 2.8",
                key = '2.8',
            },
            {
                text = "2.9",
                help = "<LOC aisettings_0075>Build multiplier of 2.9",
                key = '2.9',
            },
            {
                text = "3.0",
                help = "<LOC aisettings_0076>Build multiplier of 3.0",
                key = '3.0',
            },
            {
                text = "3.1",
                help = "<LOC aisettings_0077>Build multiplier of 3.1",
                key = '3.1',
            },
            {
                text = "3.2",
                help = "<LOC aisettings_0078>Build multiplier of 3.2",
                key = '3.2',
            },
            {
                text = "3.3",
                help = "<LOC aisettings_0079>Build multiplier of 3.3",
                key = '3.3',
            },
            {
                text = "3.4",
                help = "<LOC aisettings_0080>Build multiplier of 3.4",
                key = '3.4',
            },
            {
                text = "3.5",
                help = "<LOC aisettings_0081>Build multiplier of 3.5",
                key = '3.5',
            },
            {
                text = "3.6",
                help = "<LOC aisettings_0082>Build multiplier of 3.6",
                key = '3.6',
            },
            {
                text = "3.7",
                help = "<LOC aisettings_0083>Build multiplier of 3.7",
                key = '3.7',
            },
            {
                text = "3.8",
                help = "<LOC aisettings_0084>Build multiplier of 3.8",
                key = '3.8',
            },
            {
                text = "3.9",
                help = "<LOC aisettings_0085>Build multiplier of 3.9",
                key = '3.9',
            },
            {
                text = "4.0",
                help = "<LOC aisettings_0086>Build multiplier of 4.0",
                key = '4.0',
            },
            {
                text = "4.1",
                help = "<LOC aisettings_0087>Build multiplier of 4.1",
                key = '4.1',
            },
            {
                text = "4.2",
                help = "<LOC aisettings_0088>Build multiplier of 4.2",
                key = '4.2',
            },
            {
                text = "4.3",
                help = "<LOC aisettings_0089>Build multiplier of 4.3",
                key = '4.3',
            },
            {
                text = "4.4",
                help = "<LOC aisettings_0090>Build multiplier of 4.4",
                key = '4.4',
            },
            {
                text = "4.5",
                help = "<LOC aisettings_0091>Build multiplier of 4.5",
                key = '4.5',
            },
            {
                text = "4.6",
                help = "<LOC aisettings_0092>Build multiplier of 4.6",
                key = '4.6',
            },
            {
                text = "4.7",
                help = "<LOC aisettings_0093>Build multiplier of 4.7",
                key = '4.7',
            },
            {
                text = "4.8",
                help = "<LOC aisettings_0094>Build multiplier of 4.8",
                key = '4.8',
            },
            {
                text = "4.9",
                help = "<LOC aisettings_0095>Build multiplier of 4.9",
                key = '4.9',
            },
            {
                text = "5.0",
                help = "<LOC aisettings_0096>Build multiplier of 5.0",
                key = '5.0',
            },
            {
                text = "5.1",
                help = "<LOC aisettings_0097>Build multiplier of 5.1",
                key = '5.1',
            },
            {
                text = "5.2",
                help = "<LOC aisettings_0098>Build multiplier of 5.2",
                key = '5.2',
            },
            {
                text = "5.3",
                help = "<LOC aisettings_0099>Build multiplier of 5.3",
                key = '5.3',
            },
            {
                text = "5.4",
                help = "<LOC aisettings_0100>Build multiplier of 5.4",
                key = '5.4',
            },
            {
                text = "5.5",
                help = "<LOC aisettings_0101>Build multiplier of 5.5",
                key = '5.5',
            },
            {
                text = "5.6",
                help = "<LOC aisettings_0102>Build multiplier of 5.6",
                key = '5.6',
            },
            {
                text = "5.7",
                help = "<LOC aisettings_0103>Build multiplier of 5.7",
                key = '5.7',
            },
            {
                text = "5.8",
                help = "<LOC aisettings_0104>Build multiplier of 5.8",
                key = '5.8',
            },
            {
                text = "5.9",
                help = "<LOC aisettings_0105>Build multiplier of 5.9",
                key = '5.9',
            },
            {
                text = "6.0",
                help = "<LOC aisettings_0106>Build multiplier of 6.0",
                key = '6.0',
            },
        },
   },
   {   default = 1,
        label = "<LOC aisettings_0107>AI TML Randomization",
        help = "<LOC aisettings_0108>Sets the randomization for the AI\'s TMLs making them miss more. Higher means less accurate.",
        key = 'TMLRandom',
        values = {
            {
                text = "<LOC aisettings_0109>None",
                help = "<LOC aisettings_0110>No Randomization",
                key = '0',
            },
            {
                text = "2.5%",
                help = "<LOC aisettings_0111>2.5% Randomization",
                key = '2.5',
            },
            {
                text = "5%",
                help = "<LOC aisettings_0112>5% Randomization",
                key = '5',
            },
            {
                text = "7.5%",
                help = "<LOC aisettings_0113>7.5% Randomization",
                key = '7.5',
            },
            {
                text = "10%",
                help = "<LOC aisettings_0114>10% Randomization",
                key = '10',
            },
            {
                text = "12.5%",
                help = "<LOC aisettings_0115>12.5% Randomization",
                key = '12.5',
            },
            {
                text = "15%",
                help = "<LOC aisettings_0116>15% Randomization",
                key = '15',
            },
            {
                text = "17.5%",
                help = "<LOC aisettings_0117>17.5% Randomization",
                key = '17.5',
            },
            {
                text = "20%",
                help = "<LOC aisettings_0118>20% Randomization",
                key = '20',
            },
        },
   },
   {   default = 6,
        label = "<LOC aisettings_0119>AI Land Expansion Limit",
        help = "<LOC aisettings_0120>Set the limit for the number of land expansions that each AI can have (will still be modified by the number of AIs).",
        key = 'LandExpansionsAllowed',
        values = {
            {
                text = "<LOC aisettings_0121>None",
                help = "<LOC aisettings_0122>No Land Expansions Allowed",
                key = '0',
            },
            {
                text = "1",
                help = "<LOC aisettings_0123>1 Land Expansion Allowed",
                key = '1',
            },
         {
                text = "2",
                help = "<LOC aisettings_0124>2 Land Expansions Allowed",
                key = '2',
            },
            {
                text = "3",
                help = "<LOC aisettings_0125>3 Land Expansions Allowed",
                key = '3',
            },
            {
                text = "4",
                help = "<LOC aisettings_0126>4 Land Expansions Allowed",
                key = '4',
            },
            {
                text = "5",
                help = "<LOC aisettings_0127>5 Land Expansions Allowed",
                key = '5',
            },
            {
                text = "6",
                help = "<LOC aisettings_0128>6 Land Expansions Allowed",
                key = '6',
            },
            {
                text = "7",
                help = "<LOC aisettings_0129>7 Land Expansions Allowed",
                key = '7',
            },
            {
                text = "8",
                help = "<LOC aisettings_0130>8 Land Expansions Allowed",
                key = '8',
            },
            {
                text = "<LOC aisettings_0131>Unlimited",
                help = "<LOC aisettings_0132>Unlimited Land Expansions Allowed",
                key = '99999',
            },
        },
   },
   {   default = 5,
        label = "<LOC aisettings_0133>AI Naval Expansion Limit",
        help = "<LOC aisettings_0134>Set the limit for the number of naval expansions that each AI can have.",
        key = 'NavalExpansionsAllowed',
        values = {
            {
                text = "<LOC aisettings_0135>None",
                help = "<LOC aisettings_0136>No Naval Expansions Allowed",
                key = '0',
            },
            {
                text = "1",
                help = "<LOC aisettings_0137>1 Naval Expansion Allowed",
                key = '1',
            },
         {
                text = "2",
                help = "<LOC aisettings_0138>2 Naval Expansions Allowed",
                key = '2',
            },
            {
                text = "3",
                help = "<LOC aisettings_0139>3 Naval Expansions Allowed",
                key = '3',
            },
            {
                text = "4",
                help = "<LOC aisettings_0140>4 Naval Expansions Allowed",
                key = '4',
            },
            {
                text = "5",
                help = "<LOC aisettings_0141>5 Naval Expansions Allowed",
                key = '5',
            },
            {
                text = "6",
                help = "<LOC aisettings_0142>6 Naval Expansions Allowed",
                key = '6',
            },
            {
                text = "7",
                help = "<LOC aisettings_0143>7 Naval Expansions Allowed",
                key = '7',
            },
            {
                text = "8",
                help = "<LOC aisettings_0144>8 Naval Expansions Allowed",
                key = '8',
            },
            {
                text = "<LOC aisettings_0145>Unlimited",
                help = "<LOC aisettings_0146>Unlimited Naval Expansions Allowed",
                key = '99999',
            },
        },
   },
   {   default = 1,
        label = "<LOC aisettings_0147>AIx Omni Setting",
        help = "<LOC aisettings_0148>Set the build rate multiplier for the cheating AIs.",
        key = 'OmniCheat',
        values = {
            {
                text = "<LOC aisettings_0149>On",
                help = "<LOC aisettings_0150>Full map omni on",
                key = 'on',
            },
            {
                text = "<LOC aisettings_0151>Off",
                help = "<LOC aisettings_0152>Full map omni off",
                key = 'off',
            },
        },
   },
}
