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
        values = {
            {
                text = "<LOC lobui_0092>Fixed",
                help = "<LOC lobui_0093>Spawn everyone in fixed locations (determined by slot)",
                key = 'fixed',
            },
            {
                text = "<LOC lobui_0094>Random - Unbalanced",
                help = "<LOC lobui_0091>Spawn everyone in random locations",
                key = 'random',
            },
            {
                text = "<LOC lobui_0079>Optimal balance",
                help = "<LOC lobui_0080>Teams will be optimally balanced, random start locations",
                key = 'balanced',
            },
            {
                text = "<LOC lobui_0081>Flexible balance",
                help = "<LOC lobui_0082>Teams will be balanced with up to 5%% tolerance of best setup to make it a bit unpredictable",
                key = 'balanced_flex',
            },
            {
                text = "<LOC lobui_0776>Random (Revealed)",
                help = "<LOC lobui_0777>Spawn everyone in random locations which are labeled",
                key = 'random_reveal',
            },
            {
                text = "<LOC lobui_0778>Optimal balance (Revealed)",
                help = "<LOC lobui_0779>Teams will be optimally balanced, labeled random start locations",
                key = 'balanced_reveal',
            },
            {
                text = "<LOC lobui_0780>Flexible balance (Revealed)",
                help = "<LOC lobui_0781>Teams will be balanced with up to 5%% tolerance of best setup to make it a bit unpredictable, labeled random start locations",
                key = 'balanced_flex_reveal',
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
        label = "<LOC lobui_0609>Auto Teams",
        help = "<LOC lobui_0610>Auto ally the players before the game starts",
        key = 'AutoTeams',
        values = {
            {
                text = "<LOC lobui_0244>None",
                help = "<LOC lobui_0603>No automatic teams",
                key = 'none',
            },
            {
                text = "<LOC lobui_0597>Top vs Bottom",
                help = "<LOC lobui_0598>Slots in the upper half of the map against those in the lower half",
                key = 'tvsb',
            },
            {
                text = "<LOC lobui_0606>Left vs Right",
                help = "<LOC lobui_0599>Slots in the left half of the map against those in the right half",
                key = 'lvsr',
            },
            {
                text = "<LOC lobui_0600>Odd vs Even",
                help = "<LOC lobui_0601>Odd numbered slots vs even numbered slots. Subject to map design, your mileage may vary",
                key = 'pvsi',
            },
            {
                text = "<LOC lobui_0604>Manual Select",
                help = "<LOC lobui_0605>Start positions are bound to teams in a way defined by the host by clicking on the positions on the map. This only works when random spawns are enabled.",
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
        value_text = "<LOC lobui_0719>%s",
        value_help = "<LOC lobui_0171>%s units per player may be in play",
        values = {
            '125','250', '375', '500', '625', '750', '875', '1000', '1250', '1500'
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
        label = "<LOC lobui_0300>Reveal Civilians",
        help = "<LOC lobui_0301>Show civilian prebuilt structures on map",
        key = 'RevealCivilians',
        values = {
            {
                text = "<LOC _Yes>Yes",
                help = "<LOC lobui_0302>Civilian structures are revealed",
                key = 'Yes',
            },
            {
                text = "<LOC _No>No",
                help = "<LOC lobui_0303>Civilian structures are hidden",
                key = 'No',
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
        value_text = "<LOC lobui_0320>%s",
        value_help = "<LOC lobui_0321>Rules enforced for %s mins",
        values = {
            {
                text = "<LOC lobui_0318>Off",
                help = "<LOC lobui_0319>Rules not enforced",
                key = 'Off',
            },
            '5', '10', '20'
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
                help = "<LOC lobui_0555>Select only official maps",
                key = 'Official',
            },
            {
                text = "<LOC lobui_0554>All Maps",
                help = "<LOC lobui_0557>Select from all maps",
                key = 'All',
            },
        },
    },
   {
        default = 2,
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
        help = "<LOC lobui_0741>Set what happens to a player's units when they are defeated",
        key = 'Share',
        values = {
            {
                text = "<LOC lobui_0742>Full Share",
                help = "<LOC lobui_0743>Your units will be transferred to your highest scoring ally when you die. Previously transferred units will stay where they are.",
                key = 'FullShare',
            },
            {
                text = "<LOC lobui_0744>Share Until Death",
                help = "<LOC lobui_0745>All units you have built this game will be destroyed when you die, except those captured by the enemy.",
                key = 'ShareUntilDeath',
            },
            {
                text = "<LOC lobui_0762>Traitors",
                help = "<LOC lobui_0763>Your units will be transferred to the control of your killer.",
                key = 'TransferToKiller',
            },
            {
                text = "<LOC lobui_0766>Defectors",
                help = "<LOC lobui_0767>Your units will be transferred to the enemy with the highest score when you die.",
                key = 'Defectors',
            },
            {
                text = "<LOC lobui_0764>Civilian Desertion",
                help = "<LOC lobui_0765>Your units will be transferred to the Civilian AI, if there is one, when you die.",
                key = 'CivilianDeserter',
            },
        },
    },
    {
    	default = 2,
        label = "AI Replacement",
        help = "Toggle AI Replacement if a player disconnects.",
        key = 'AIReplacement',
        values = {
            {
                text = "<LOC _On>On",
                help = "If a player disconnects and the ACU is still active, an AI will be created to take control of units that belonged to the player who disconnected.",
                key = 'AIReplacementOn',
            },
            {
                text = "<LOC _Off>Off",
                help = "A disconnected player will cause the destruction of their units based on share conditions.",
                key = 'AIReplacementOff',
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
        value_text = "%s",
        value_help = "<LOC aisettings_0003>Cheat multiplier of %s",
        values = {
            '1.0', '1.1', '1.2', '1.3', '1.4', '1.5', '1.6', '1.7', '1.8', '1.9',
            '2.0', '2.1', '2.2', '2.3', '2.4', '2.5', '2.6', '2.7', '2.8', '2.9', '3.0', '3.1', '3.2', '3.3', '3.4', '3.5', '3.6', '3.7', '3.8', '3.9',
            '4.0', '4.1', '4.2', '4.3', '4.4', '4.5', '4.6', '4.7', '4.8', '4.9', '5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9',
        },
   },
   {
        default = 11,
        label = "<LOC aisettings_0054>AIx Build Multiplier",
        help = "<LOC aisettings_0055>Set the build rate multiplier for the cheating AIs.",
        key = 'BuildMult',
        value_text = "%s",
        value_help = "<LOC aisettings_0056>Build multiplier of %s",
        values = {
            '1.0', '1.1', '1.2', '1.3', '1.4', '1.5', '1.6', '1.7', '1.8', '1.9',
            '2.0', '2.1', '2.2', '2.3', '2.4', '2.5', '2.6', '2.7', '2.8', '2.9', '3.0', '3.1', '3.2', '3.3', '3.4', '3.5', '3.6', '3.7', '3.8', '3.9',
            '4.0', '4.1', '4.2', '4.3', '4.4', '4.5', '4.6', '4.7', '4.8', '4.9', '5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9',
        },
   },
   {
        default = 1,
        label = "<LOC aisettings_0107>AI TML Randomization",
        help = "<LOC aisettings_0108>Sets the randomization for the AI\'s TMLs making them miss more. Higher means less accurate.",
        key = 'TMLRandom',
        value_text = "%s%%",
        value_help = "<LOC aisettings_0111>%s Randomization",
        values = {
            {
                text = "<LOC aisettings_0109>None",
                help = "<LOC aisettings_0110>No Randomization",
                key = '0',
            },
            '2.5', '5', '7.5', '10', '12.5', '15', '17.5', '20'
        },
   },
   {
        default = 6,
        label = "<LOC aisettings_0119>AI Land Expansion Limit",
        help = "<LOC aisettings_0120>Set the limit for the number of land expansions that each AI can have (will still be modified by the number of AIs).",
        key = 'LandExpansionsAllowed',
        value_text = "%s",
        value_help = "<LOC aisettings_0123>%s Land Expansions Allowed",
        values = {
            {
                text = "<LOC aisettings_0121>None",
                help = "<LOC aisettings_0122>No Land Expansions Allowed",
                key = '0',
            },
            '1', '2', '3', '4', '5', '6', '7', '8',
            {
                text = "<LOC aisettings_0131>Unlimited",
                help = "<LOC aisettings_0132>Unlimited Land Expansions Allowed",
                key = '99999',
            },
        },
   },
   {
        default = 5,
        label = "<LOC aisettings_0133>AI Naval Expansion Limit",
        help = "<LOC aisettings_0134>Set the limit for the number of naval expansions that each AI can have.",
        key = 'NavalExpansionsAllowed',
        value_text = "%s",
        value_help = "<LOC aisettings_0137>%s Naval Expansions Allowed",
        values = {
            {
                text = "<LOC aisettings_0135>None",
                help = "<LOC aisettings_0136>No Naval Expansions Allowed",
                key = '0',
            },
            '1', '2', '3', '4', '5', '6', '7', '8',
            {
                text = "<LOC aisettings_0145>Unlimited",
                help = "<LOC aisettings_0146>Unlimited Naval Expansions Allowed",
                key = '99999',
            },
        },
   },
   {
        default = 1,
        label = "<LOC aisettings_0147>AIx Omni Setting",
        help = "<LOC aisettings_0148>Set the AIx global intel toggle",
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
