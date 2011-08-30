extraOpts = {
	{
        default = 1,
        label = "<LOC lobui_0708>- Ladder Game -",
        help = "<LOC lobui_0706>If enabled, the game will count as Ranked Game for www.fa-ladder.com website",
        key = 'LadderGame',
        pref = 'Lobby_Ladder_Game',
        values = {
            {
                text = "<LOC _No>No",
                help = "<LOC lobui_0604>No Ranked Mode",
                key = 'Off',
            },
			{
                text = "<LOC _Yes>Yes",
                help = "<LOC lobui_0605>Ranked Mode set",
                key = 'On',
            },            
        },
    },
    {
        default = 1,
        label = "<LOC lobui_0714>Share Conditions",
        help = "<LOC lobui_0715>Kill all the units you shared to your allies and send back the units your allies shared with you when you die",
        key = 'Share',
        pref = 'Lobby_Share',
        values = {
            {
                text = "<LOC lobui_0716>Full Share",
                help = "<LOC lobui_0717>You can give units to your allies and they will not be destroyed when you die",
                key = 'no',
            },
            {
                text = "<LOC lobui_0718>Share Until Death",
                help = "<LOC lobui_0719>All the units you gave to your allies will be destroyed when you die",
                key = 'yes',
            },
        },
    },
	{
        default = 1,
        label = "<LOC lobui_0720>Score",
        help = "<LOC lobui_0721>Set score on or off during the game",
        key = 'Score',
        pref = 'Lobby_Score',
        values = {
            {
                text = "<LOC _On>On",
                help = "<LOC lobui_0722>Score is enabled",
                key = 'yes',
            },
            {
                text = "<LOC _Off>Off",
                help = "<LOC lobui_0723>Score is disabled",
                key = 'no',
            },			
        },
    },
}