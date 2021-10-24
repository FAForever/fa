Patch 3724 (04th October, 2021)
============================

### Stability
 - (#3477) Prevent clearing critical state in AI functions

### Bug
 - (#3486) Fix (mod) units being unbuildable due to error in UI
 - (#3432) Fix overcharge occasionally basing its damage on the previous unit it hit
 - (#3316) Fix experimentals doing death damage upon death
    Monkeylord: only when fully complete as it sits
    Megalith: only when fully complete as it sits
    Colossus: when complete 50% or more
    Ythotha: when complete 50% or more
    
### Other
 - (#3475) Fix capitalisation consistency
 - (#3443) Allow trashbag to be re-used for effects
 - (#3489) Fix UI description of teleport
 - (#3491) Fix the attack animation of the Monkey Lord

### Performance
 - (#3447) Remove old AI related code that was being run regardless of whether AIs were in-game
    This also changes the behavior of assisting engineers: just make a chain of 10
    engineers assisting each other where the first engineer is assisting a 
    factory - the old behavior would cause all engineers to start helping the
    same tick where as this 'new' (the real old behavior) updates the same way
    the base game does. It prevents a lot of searching for units when a lot of
    engineers are assisting various factories - typically engineers assist 
    directly and therefore I suspect the gameplay consequence is minimal.

### Contributors
 - Uveso (#3477)
 - Rowey (#3475)
 - Jip (#3443, #3316, #3491, #3447)
 - KionX (#3486, #3489)
 - Crotalus (#3432)