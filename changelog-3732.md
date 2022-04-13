
Game version 3732 (22nd of April, 2022)
===================================



### Features
 - Dynamic AI threat calculations (#3660) 
    The AI threat values have not been updated over the years - they are now 
    computed based on unit statistics during the blueprint loading phase. 
    Introduces a utilities window that allows you to inspect AI-related blueprint 
    values of a unit. You need to set a hotkey for that window. You can find it 
    in the hotkeys dialogue (F1) by searching for 'information'. Cheats need to 
    be enabled in order for the window to show.

 - Allow Hives to start upgrading immediately (#3675)
    Part of the Small Suggestions topic on the forum - suggested by Tagada.


### Bug fixes

 - Remove new lines when you set a lobby title (#3644) 
    Prevents having lobbies in the client that occupy multiple lines, 
    allowing them to overlap with other lobbies.

 - Preserve weapon bone orientation upon destruction (#3668)
    There was a bug introduced last patch that causes weapons to reset
    their orientation right before the unit was destroyed. 

 - Fix trampling damage (#3669)
    There was a bug introduced last patch that reduced all trampling
    damage to zero. Surprising how little people reported about it :)
 
 - Fix inconsistencies with cheat menu (#3656)
    The mouse click is now always registered. Prevents selected units from 
    interfering with the cheat progress by deselecting them while spawning 
    units and reselecting them when you are finished. Fixes veterancy issues: 
    both for the spawn menu and all campaign missions.

### Other
 - Improve readme of repository (#3647, #3663, #3670)
    Introduces a modern readme and accurate installation instructions of the 
    development environment. With thanks to everyone involved, including but not 
    limited to BlackYps, Sheikah, Balthazar, Emperor, Ftx. And thanks to 4z0t there is 
    a complete Russian translation of the readme and the installation instructions.

 - Adjust map preview button (#3646)
    The button to show the map preview is enlarged and remains enabled when 
    you are ready as a player.

    Part of the Small Suggestions topic on the forum - suggested by Scout_More_Often.

 - Add enabled mods to tooltip (#3649) 
    Adds the enabled ui or sim mods to the tooltip in the lobby, allowing you to preview 
    the enabled mods without entering the mod manager. A small quality of life feature.

    Part of the Small Suggestions topic on the forum - suggested by Emperor_Penguin.

 - Chat ally option (#3651)
    Adds a chat option to send to allies by default instead of to all. Chat options 
    can be found by clicking the wrench icon on the chat dialogue when you are in-game.

    Part of the Small Suggestions topic on the forum - suggested by CheeseBerry.

 - Add map version to tooltip in scoreboard (#3648) 
    Improves the default scoreboard by introducing the map description and version
    when hovering over the map.

    Part of the Small Suggestions topic on the forum - suggested by Emperor_Penguin.

 - Change default army color order of lobby (#3642)
    Changes the default army colors to be more intuitive, as an example: when the game is 
    2 vs 2 then it is two shades of red versus two shades of blue.

### Performance
 - Dynamic LOD settings (#3662) 
    Computes the LOD cut off values of props based on its blueprint properties. A 
    prop that occupies less screen space will have a lower cut off value - allowing 
    it to be culled sooner. This improves the framerate of the game in general, 
    while having a minor impact on visual fidelity. 
    
    Technical detail: The LOD values of props in the blueprint are now ignored.

 - Improve performance of markers (#3387) 
    Allows AI developers / map scripters to work with markers without having to worry 
    about underlying performance issues. As an example, retrieving the mass markers
    on a map is a common operation for AIs. If done through the base game code it would 
    re-allocate a new table of markers each time an AI condition manager starts 
    checking the state of the game. That is quite wasteful. This file keeps
    track of previous calls, caching the result. Supports adaptive and crazy rush-like maps.

    Introduces a UI that allows you to inspect the cached markers. The window is toggled with 
    'K' by default and can be adjusted as usual. Requires cheats to be enabled.

    Technical detail: this has no impact on regular games, only on games with AI once they've
    implemented these new routines.

 - Improve performance of various UI-related functions (#3659) 
    Replaces the global function to use a cached result. A call to `GetSessionClients` or 
    `GetArmiesTable` created a unique table that the garbage collector can pick up two 
    lines later. These functions are called each frame or each tick. With this caching 
    behavior they get replenished every two seconds, or every 0.025 seconds if a fast
    interval is set.

 - Improve performance of reclaim effects (#3672)
    Reduces the amount of garbage generated when an engineer is reclaiming a prop, such
    as a tree or a wreck.


### Contributors

 - Sheikah (#3647)
 - FtxCommando (#3647)
 - BlackYps (#3647, #3642)
 - Emperor_Penguin (#3647)
 - Askaholic (#3647)
 - Sheeo (#3647)
 - Balthazar (#3660, #3647)
 - 4z0t (#3651, #3647)
 - Jip (#3660, #3647, #3663, #3656, #3387, 
        #3659, #3648, #3646, #3649, #3672,
        #3668, #3669, #3670, #3675)
 - Tagada (#3675)
