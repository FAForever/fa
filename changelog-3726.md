Patch 3726 (26th November, 2021)
============================

### Features
 - (#3484, #3500, #3535) Allow more structures to be cap-able using a similar mechanic to storages for extractors:
    Extractors
    - 2 clicks + shift to mass storage an upgrading t1 extractor
    - 2 clicks + shift to mass storage a t2 / t3 extractor
    - 3 clicks + shift to mass fab an upgrading t2 extractor
    - 3 clicks + shift to mass fab cap a t3 extractor

    Other structures
    - 2 clicks + shift to t1 power gen cap an upgrading t1 radar
    - 2 clicks + shift to t1 power gen cap a t2 / t3 radar
    - 2 clicks + shift to t1 power gen cap a t2 artillery
    - 2 clicks + shift to wall cap a t1 point defense
    - 2 clicks + shift to mass storage cap a t3 fabricator
    
    Assisting behavior
    - When all engineers are of the same faction, they can all build the same storage. No assisting happening.
    - When you have engineers of two or more factions, one must assist the other as they can't build the same storages.
    - When you have engineers of one faction and units that can't build the storage (kennel drones, ACU) then they must assist an engineer as they can't build the storages themselves.

### Stability
 - (#3477) Prevent clearing critical state in AI functions
 - (#3490, #3551) Refactor the init files of the game
    This is an involved change but one that was due. 
    
    The init files can no longer load in content that clash between
    the base game files or between older versions of the same mod.
    This could also occur when the mod was not activated for sound
    and / or movie files.

    The client supports loading content from a separate vault
    location, the init files need to support this functionality
    accordingly. The init files of the game types FAF, FAF Beta
    and FAF Develop support this functionality. Other game types 
    need to be updated accordingly.

    The vault location determined by the client is used to load in
    content (maps / mods). Any other location is no longer read and
    therefore any map / mod in the other locations are not found
    by the game. If after this patch you 'lost' a few of your
    maps and / or mods it means that they were in an old vault 
    location - you'd need to move those manually.

    Adds icon support to FAF Beta.

    Adds the ability to more easily block content that is integrated.
 - (#3527) Integrate the Nvidia Fix mod and block the mod from loading
 - (#3543) Prevent applying bugs to insignificant units, like the Cybran build drone
 - (#3550) Attempt to fix Rhino from missing its target 

### Bug
 - (#3522) Fix upvalue issue of patch 3721
 - (#3486) Fix (mod) units being unbuildable due to error in UI
 - (#3432) Fix overcharge occasionally basing its damage on the previous unit it hit
 - (#3316) Fix experimentals doing death damage upon death during construction
    Monkeylord: only when fully complete as it sits
    Megalith: only when fully complete as it sits
    Colossus: when complete 50% or more
    Ythotha: when complete 50% or more
 - (#3440) Removes the dummy drone from the unit restriction list
    This drone was often misintepreted as an easy way to unrate a game. In
    contrast to what the name suggests it does have a function: to help gift
    units when a player dies and full share is on. The drone can no longer be
    restricted and instead there is a dedicated lobby option to unrate the
    game.
 - (#3525) Fix the unpathable skirts of the Seraphim Quantum Gateway
    
### Other
 - (#3523) Switch off debug utilities by default
    This is only useful for developers, but it did cause
    a (slight) drain on resources when it was turned on
    even though you're not looking at the logs. It turns it
    off by default during each startup, you can prevent 
    this as a developer by adding
    `debug = { enable_debug_facilities = true }`
    to your preference file
 - (#3417) Add unit tests for generic utility functions
 - (#3420) Fix small issues for units of the Cybran faction.
 - (#3492) Remove greyness when deviation is high
    In combination with other work, such as combining the number of
    games people played across the board (ladder / tmm / globals)
    it should become easier for people to 'get into' custom games
    without being called a noob beforehand or a smurf afterwards (never
     played custom games, but played a lot of ladder).
 - (#3475) Fix capitalisation consistency
 - (#3443) Allow trashbag to be re-used for effects
 - (#3489) Fix UI description of teleport
 - (#3491) Fix the attack animation of the Monkey Lord
 - (#3349) Updates the readme with the most recent dependencies
 - (#3461) Remove game quality computations for games with more than two teams
    The Trueskill system is not designed to compute the quality of a game 
    when more than (or less than) two teams are involved. Hence, the 
    computation is gibberish anyhow.
 - (#3526) Remove the curated maps button until an alternative is available
 - (#3528) Fix T2 seraphim sonar being restricted when t3 base spam is
 - (#3531) Add an option to scale down the UI (to 80%) for low resolution monitors
    This doesn't appear to be an issue at first due to the infinite 
    zoom but when the score board takes up 50% of your screen due to a
    1024x720 resolution then it suddenly is.

    Not all of the UI can manage this - please report issues in #game-general
    in the FAF discord when you find them.
 - (#3533) Change default settings of auto lobby to 1.5K unit cap and full share (used by ladder / team match making)
 - (#3441) Introduction of insignificant or dummy units
    This introduces a new unit class that can be used to fix
    various bugs and glitches with the game. One such issues
    is the long standing bug with the Aeon build animation where
    the aim bones are underground at the start of construction.
    
    Sadly - this change is quite involved because a lot of the
    functionality expects a full-fledged unit. We've tried to
    catch some of these but there will be more issues that will
    show up, especially with scripted maps.
 - (#3552) Update regular expression of mod version removal
 - (#3554) Add quick-swap feature to lobby
    As a host you can quickly swap two players by
    left-clicking on the slot numbers of two players. It
    highlights to teal (light / bright blue color) when
    in swap modus. Click the highlighted slot number to
    cancel.

### Performance
 - (#3417) Add minor performance improvements for generic utility functions
 - (#3447) Remove old AI related code that was being run regardless of whether AIs were in-game
    This change is involved performance-wise but does not impact gameplay.

    As a practical example: chain ten engineers assisting one another and make the
    first engineer assist a factory. With these changes they'll start assisting the
    factory one by one as it takes one tick (simulation tick) to detect the unit
    it is assisting has started working on something.

    The previous behavior would be that all engineers get updated immediately. This
    required it to search for engineers in its surrounding and all those it found
    would need to look up its surroundings too. This can quickly get out of hand.
 - (#3502) Optimize the import function that is used by all files.
 - (#3512) Removes AI threat computations and fixes AI detection
    AI code was being run during every game even when no AI was present in
    said game. After discussing it with the AI devs this pull requests
    completely removes the threat computations.
 - (#3419) Reduce impact on sim of common hover emitter effects
    Effects have an impact on the sim, in particular when they create a 
    particle. Once the particles exist they appear to be free of charge. 
    With this PR we reduced the number of particles created for various 
    units such as the Aeon T1 engineer to bring them into the same cost
    range (sim wise) as the other engineers, without impacting their
    visual appearance too much. Disables the hover effects of these units
    all together when playing on low fidelity.

### Contributors
 - Askaholic (#3417, #3440)
 - Madmax (#3420, #3419)
 - Uveso (#3477)
 - Rowey (#3475, #3528, #3533)
 - Jip (#3443, #3316, #3491, #3447, #3484, #3492, #3500, 
        #3522, #3512, #3440, #3419, #3525, #3526, #3490,
        #3527, #3531, #3543, #3411, #3551, #3550)
 - KionX (#3486, #3489, #3523, #3349)
 - Crotalus (#3432)
 - Benzi-Junior (#3461)
 - Balthazar (#3552)
 - 4z0t (#3554)

### Reviewers
 - Balthazar (#3484)
 - Relent0r (#3512)

### Translators
 - Lenkin (#3440)