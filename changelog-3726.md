Patch 3726 (26th November, 2021)
============================

### Features
 - (#3484, #3500) Allow more structures to be cap-able using a similar mechanic to storages for extractors:
    Extractors
    - 1 click + shift to mass storage an upgrading t1 extractor
    - 1 click to mass storage a t2 / t3 extractor
    - 3 clicks + shift to mass fab an upgrading t2 extractor
    - 3 clicks to mass fab cap a t3 extractor

    Other structures
    - 1 click to mass storage cap a t3 fabricator
    - 1 click to t1 power gen cap a radar
    - 1 click to t1 power gen cap a t2 artillery
    - 1 click to wall cap a t1 point defense
    
    Assisting behavior
    - When all engineers are of the same faction, they can all build the same storage. No assisting happening.
    - When you have engineers of two or more factions, one must assist the other as they can't build the same storages.
    - When you have engineers of one faction and units that can't build the storage (kennel drones, ACU) then they must assist an engineer as they can't build the storages themselves.

### Stability
 - (#3477) Prevent clearing critical state in AI functions

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

### Performance
 - (#3417) Add minor performance improvements for generic utility functions
 - (#3447) Remove old AI related code that was being run regardless of whether AIs were in-game
    This also changes the behavior of assisting engineers: just make a chain of 10
    engineers assisting each other where the first engineer is assisting a 
    factory - the old behavior would cause all engineers to start helping the
    same tick where as this 'new' (the real old behavior) updates the same way
    the base game does. It prevents a lot of searching for units when a lot of
    engineers are assisting various factories - typically engineers assist 
    directly and therefore I suspect the gameplay consequence is minimal.
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
 - Rowey (#3475)
 - Jip (#3443, #3316, #3491, #3447, #3484, #3492, #3500, 
        #3522, #3512, #3440, #3419, #3525, #3526)
 - KionX (#3486, #3489, #3523, #3349)
 - Crotalus (#3432)
 - Benzi-Junior (#3461)

### Reviewers
 - Balthazar (#3484)
 - Relent0r (#3512)

### Translators
 - Lenkin (#3440)