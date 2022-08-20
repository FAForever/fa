
# Game version xyzw (day of month, 2022)

## Bug fixes

- (#4002) Fix issue with single-item combo list

- (#4016) Re-implement game results
    A complete re-implementation of how the game results are tracked. This should fix the famous
    draw bug (where one player wins and the other loses) and in general there should be less 
    unknown game results.

## Features

## Performance

- (#3932, #4011) Remove unused unit blueprint tabels related to veterancy
    Reduces total amount of allocated memory

- (#4003) Remove collision shape of the Cybran Build Bots

- Refactor effect utilities pt. 1, 3 and 4 (#3995, #4000, #3995)

## Annotation

- (#3936) Annotate and refactor layouthelpers.lua
    Improves performance of UI functions that are used by almost every UI element

- (#4009) Annotate campaign related functions pt. 2

- (#4021) Cleanup annotation of engine documentation

- (#3975, #4023)) Add annotation support for blueprints

## Other changes

- (#3952) Update AI-related categories for the Cybran experimentals

- (#3851) Reduce amount of unfinished buildings for the AI
    This is a difficult one to tackle, but what happens is that buildings remain unfinished because there
    is a nearby threat to the ACU. The ACU attempts to defend, but then doesn't always continue what he
    started previously

- (#3971) Cleaning up of files

- (7ff888) Fix name of operational AI (related to campaign)

## Contributors

Hdt80bro: #3936, #3995, #4000, #3995
Rowey: #3932, #3971
Maudlin: #3952
Uveso: #3851
speed2: 7ff888
Jip: #4011, #4003, #4016, #4009, #4021, #4023
Ejsstiil: #4002
hahn-kev: #3975
