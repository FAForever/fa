Patch 3676 (Upcoming)
============================
### Gameplay
- New feature: Dead air unit wrecks now bounce off shields. The amount of bounce depends on the unit's momentum and angle of approach. Some of the crash damage is transferred to the shield. Unit wrecks can only bounce once. Doesn't affect Experimentals.
- Allow units in a transport which is shot down to leave wrecks at the crash site
- Allow the Novax to build a new Satellite if the old one dies. This can only happen if it is impacted by a Nuke or ctrl-k'ed
- Introduced code to slightly improve the way Tempest and Atlantis behave, particularly in being able to fire, in shallow waters

### Bugs
- Fixed ACU reclaiming while shooting
- Fixed ACU building while shooting
- Fixed Auto-Overcharge stopping working randomly until toggled
- Fixed Auto-Overcharge firing while building
- Fixed SML hitboxes so some are no longer immune to T2 PGen explosions
- Increased Beetle hitbox size and declared new targetbones to stop everything missing it if it strafes

### Lobby
- Fixed 'Random' faction using 'Random - Unbalanced' tooltip
- Allow filtering of 13-16 player maps in map selection
- Fixed 'Autoteams: Manual' resulting in all players being allied
- Fixed autobalance functions crashing when used with uneven team numbers
- Improved the ping/cpu display column, splitting it into two. The ping column only shows when it matters.
- Observers are now kicked before checking connection issues when Allow Observers is false. This means they will no longer stall game launch if one or more have a connection issue.

### UI
- Added new option to change the minimum reclaim label size shown in the overlay

### Balance
- Increased Auto-Overcharge rate of fire from 3.3s to 5s

### Other
- Added some mods to blacklist
- Allowed hooking of schook files to help future patch mechanism
- Allow hot-reloading of UI files with EnableDiskWatch
- Uncapped max framerate for people with monitor refresh rates >100
- Fixed desync in COOP
- Allow Salem death sound on land in COOP

### Contributors
- Exotic-Retard
- IceDreamer
- Speed2
- TheKeyBlue


Patch 3675 (5th February, 2017)
============================
- Fixed a small bug that led to the game not ending properly when a player died with Share Unit Cap turned on


Patch 3674 (5th February, 2017)
============================
http://content.faforever.com/patchnotes/3674.html

### Lobby
- Use default map from file. This allows coop, tutorials, and other mods to have an easier time
- Allow factions to be restricted per slot

### Other
- Updated maps blacklist
- Introduced wider support for the addition of new factions into the game
- Fixed Ythotha spawning energy storm on give in coop
- Updated unit cap code so it can be changed by coop
- Fixed score data not being synced on coop game end
- Added new buildrate icon in the unit detail view

### Balance
- Stun mechanics no longer affect flying Air Units
- Stun mechanics now apply in a sphere rather than a cylinder
- Ythotha
    - Changed various aspects of the unit to make it easier to micro
    - UniformScale decreased 0.05 -> 0.042
    - TurnRate increased 40 -> 60
    - SizeX decreased 3.5 -> 3.2
    - SizeY decreased 8.5 -> 7.5
    - Eye weapon MaxRadius increased 45 -> 47
    - Gatling arm weapon MaxRadius increased 45 -> 47
    - Medium cannon weapon MaxRadius increased 45 -> 47
    - AA
        - MaxRadius increased 45 -> 47
        - AOE increased 1.5 -> 4
        - Can shoot at a slightly greater angle to eliminate blindspots',
        - Added UseFiringSolutionInsteadOfAimBone = true for better AA performance',
    - Added ACU as higher priority target on the DeathBall
    - Various changes to weapon arcs and targeting angles
- T1 Factories
    - Land
        - Aeon
            - Health decreased 3700 -> 3100
        - UEF
            - Health decreased 4100 -> 4000
        - Cybran
            - Health decreased 3500 -> 2500
            - Regen increased 0 -> 3
        - Seraphim
            - Health decreased 3700 -> 3100
    - Air
        - Aeon
            - Health decreased 3700 -> 3100
        - UEF
            - Health decreased 4100 -> 4000
        - Cybran
            - Health decreased 3500 -> 2500
            - Regen increased 0 -> 3
        - Seraphim
            - Health decreased 3700 -> 3100
    - Naval
        - Aeon
            - Health decreased 4400 -> 3100
        - UEF
            - Health decreased 4800 -> 4000
        - Cybran
            - Health decreased 4200 -> 2500
            - Regen increased 0 -> 3
        - Seraphim
            - Health decreased 4600 -> 3100
- T2 HQs
    - Land
        - Aeon
            - Health decreased 8200 -> 6200
        - UEF
            - Health decreased 9000 -> 8000
        - Cybran
            - Health decreased 7800 -> 5000
            - Regen increased 0 -> 10
        - Seraphim
            - Health decreased 8200 -> 6200
    - Air
        - Aeon
            - Health decreased 8200 -> 6200
        - UEF
            - Health decreased 9000 -> 8000
        - Cybran
            - Health decreased 7800 -> 5000
            - Regen increased 0 -> 10
        - Seraphim
            - Health decreased 8600 -> 6200
    - Naval
        - Aeon
            - Health decreased 16000 -> 10000
        - UEF
            - Health decreased 18000 -> 13000
        - Cybran
            - Health decreased 15000 -> 8000
            - Regen increased 0 -> 15
        - Seraphim
            - Health decreased 17000 -> 10000
- T3 HQs
    - Land
        - Aeon
            - Health decreased 20000 -> 12400
        - UEF
            - Health decreased 22000 -> 16000
        - Cybran
            - Health decreased 19000 -> 10000
            - Regen increased 0 -> 20
        - Seraphim
            - Health decreased 21000 -> 12400
    - Air
        - Aeon
            - Health decreased 20000 -> 12400
        - UEF
            - Health decreased 22000 -> 16000
        - Cybran
            - Health decreased 19000 -> 10000
            - Regen increased 0 -> 20
        - Seraphim
            - Health decreased 21000 -> 12400
    - Naval
        - Aeon
            - Health decreased 37500 -> 20000
        - UEF
            - Health decreased 40000 -> 26000
        - Cybran
            - Health decreased 34000 -> 16000
            - Regen increased 0 -> 30
        - Seraphim
            - Health decreased 38000 -> 20000
- T2 Support
    - Land
        - Aeon
            - Health decreased 4100 -> 3100
        - UEF
            - Health decreased 4500 -> 4000
        - Cybran
            - Health decreased 3900 -> 2500
            - Regen increased 0 -> 3
        - Seraphim
            - Health decreased 4100 -> 3100
    - Air
        - Aeon
            - Health decreased 4100 -> 3100
        - UEF
            - Health decreased 4500 -> 4000
        - Cybran
            - Health decreased 3900 -> 2500
            - Regen increased 0 -> 3
        - Seraphim
            - Health decreased 4300 -> 3100
    - Naval
        - Aeon
            - Health decreased 8000 -> 5000
        - UEF
            - Health decreased 9000 -> 6000
        - Cybran
            - Health decreased 7500 -> 4000
            - Regen increased 0 -> 6
        - Seraphim
            - Health decreased 8500 -> 5000
- T3 Support
    - Land
        - Aeon
            - Health decreased 10000 -> 6200
        - UEF
            - Health decreased 11000 -> 8000
        - Cybran
            - Health decreased 9500 -> 5000
            - Regen increased 0 -> 10
        - Seraphim
            - Health decreased 10500 -> 6200
    - Air
        - Aeon
            - Health decreased 10000 -> 6200
        - UEF
            - Health decreased 11000 -> 8000
        - Cybran
            - Health decreased 9500 -> 5000
            - Regen increased 0 -> 10
        - Seraphim
            - Health decreased 10500 -> 6200
    - Naval
        - Aeon
            - Health decreased 18750 -> 10000
        - UEF
            - Health decreased 20000 -> 13000
        - Cybran
            - Health decreased 17000 -> 8000
            - Regen increased 0 -> 15
        - Seraphim
            - Health decreased 19000 -> 10000
- T3 Power Generator
    - Death damage decreased 8000 -> 5500
    - Aeon
        - Health decreased 9720 -> 6200
    - UEF
        - Health decreased 9720 -> 9000
    - Cybran
        - Health decreased 9720 -> 6000
        - Regen increased 0 -> 10
    - Seraphim
        - Health decreased 9720 -> 6200
- T2 Power Generator
    - Aeon
        - Health decreased 2160 -> 1900
    - UEF
        - Health increased 2160 -> 2500
    - Cybran
        - Health decreased 2160 -> 1800
        - Regen increased 0 -> 3
    - Seraphim
        - Health decreased 2160 -> 1900
- T1 Power Generator
    - UEF Health increased 600 -> 760
    - Cybran
        - Health decreased 600 -> 500
        - Regen increased 0 -> 1
- Hydrocarbon
    - UEF Health increased 1600 -> 1800
    - Cybran
        - Health decreased 1600 -> 1400
        - Regen increased 0 -> 1
- T3 Mex
    - Aeon
        - Health decreased 8400 -> 6200
    - UEF
        - Health increased 8400 -> 9000
    - Cybran
        - Health decreased 8400 -> 6000
        - Regen increased 0 -> 10
    - Seraphim
        - Health decreased 8400 -> 6200
- T2 Mex
    - Aeon
        - Health decreased 3000 -> 1900
    - UEF
        - Health decreased 3000 -> 2500
    - Cybran
        - Health decreased 3000 -> 1800
        - Regen increased 0 -> 3
    - Seraphim
        - Health decreased 3000 -> 1900
- T1 Mex
    - UEF Health increased 600 -> 760
    - Cybran
        - Health decreased 600 -> 500
        - Regen increased 0 -> 1
- Mass Storage
    - Aeon Health decreased 1600 -> 600
    - UEF Health decreased 1600 -> 760
    - Cybran
        - Health decreased 1600 -> 500
        - Regen increased 0 -> 1
    - Seraphim Health decreased 1600 -> 600
- Walls
    - Aeon/Seraphim Health decreased 4000 -> 2000
    - UEF Health decreased 4000 -> 3000
    - Cybran
        - Health decreased 4000 -> 1500
        - Regen increased 0 -> 3
    - BuildTime increased 10 -> 20
- Janus
    - Fire lifetime increased 4.2 -> 6
    - Initial damage per bomblet decreased 30 -> 15 (Overall impact 600 -> 300)

### Contributors
- CookieNoob
- Exotic-Retard
- IceDreamer
- JaggedAppliance
- Speed2
- TheKeyBlue
- ZockyZock


Patch 3672 (January 24th, 2017)
============================
- Fixed non-default team balance option breaking the anti-rating-bug code


Patch 3671 (January 19th, 2017)
============================
- Fixed an unintentional bug with hosting games with an AI introduced with the rating bug fixes below


Patch 3670 (January 17th, 2017)
============================
- Fixed the game reporting incorrect army indexes to the server on game start, leading to incorrect rating calculations on game end


Patch 3669 (January 17th, 2017)
============================
- Reverted that last one for a bit to fix an idiot bug


Patch 3668 (January 17th, 2017)
============================
- Fixed the game reporting incorrect army indexes to the server on game start, leading to incorrect rating calculations on game end


Hotfix Patch 3667 (December 22nd, 2016)
============================
- Fixed a typo which was setting the default labels to show onscreen to 10 rather than 1000


Hotfix Patch 3666 (December 21st, 2016)
============================
- The negative reaction of the community to the new Hotbuild bindings as defaults was severely underestimated. Attempting to reverse the change.


Hotfix Patch 3665 (December 21st, 2016)
============================
- Fixed a small error that cause the Unit Manager to hard crash


Patch 3664 (December 21st, 2016)
============================
### Bugs
- Removed deploy ability tooltip from Aeon T3 Mobile Artillery
- Fixed typos in two keybind descriptions
- Fixed Selen cloak being enabled out of the factory while moving, and further improved usability.
- Fixed civilians not always revealing for all players on map start
- Fixed beam weapons sometimes colliding incorrectly with projectiles
- Fixed sim slowdown when ordering mex cap with hundreds of engineers
- Fixed reclaim beam not penetrating water
- Fixed some remaining issues with the Reclaim overlay: Shifting while zooming/panning, and 'ghost' labels for props that are gone, as well as large performance improvement
- Fixed invalid preferences entries invalidating the game's share condition

### Gameplay
- Changed the ground weapon to be primary on Cybran switch-tech mobile AA units (T1, T3, Cruiser). This has no effect other than to allow attack-moving to work properly, stopping at the right range better.
- Ground fire is now set as the default firing state for all units
- Added a dummy weapon to units such as T2 Flak and Mobile Shields. This allows them to not run blindly in when a group of units is told to attack-move.

### UI
- New feature: Options setting is now available which will allow you to select your language from those available in FAF. Prompts for game restart.
- New feature: Options setting is now available that lets you choose the maximum number of reclaim labels allowed on-screen. Higher values cause significant FPS slowdown while the overlay is active.
- Removed Options toggle for reclaim overlay enable/disable. Simply unbinding it achieves the same thing.
- Redefined the default key bindings for Hotbuild to match a widely used community standard. This won't affect people who have non-default bindings set. Details found here: http://wiki.faforever.com/index.php?title=File:Hotbuild-layout-en.png
- New feature: Icons in the build and command menus for units will now show the keyboard shortcut assigned to them. Thanks to Brainwashed (AKA Washy/Myxir)!
- New feature: Icons in the selection menu are now sorted according to tech level and unit type. More thanks to Brainwashed!

### Coop
- Fixed a whole bunch of videos
- Fixed score screen so it works with coop
- Added a Feedback button for easier reporting of issues
- Giving units to an ally no longer breaks objectives
- Allowed armies to participate properly in objective requirements
- Fixed all AIs being set as UEF in coop
- Fixed Aeon Palace Shield breaking when given to an ally, and rebalanced it a little
- Fixed players other than the primary being unable to complete certain objectives

### Lobby
- New feature: Ability to click on the game title to update it, both in the lobby, and in the client's Find Games tab
- New feature: Closed slot - Spawn Mex. This option is used for the adaptive maps, letting a slot be turned on for mexes but not a player spawn
- Improved lobby setting persistence interaction with maps that introduce their own options
- Corrected "to observers" tooltip occurring twice
- Display mean rating in the rating tooltip, rather than minimum. Also use player name in that tooltip.
- Fixed closed spots showing an empty box for newly joined players, breaking the lobby
- Renamed 'Random' spawn option to 'Random - Unbalanced' for the sake of clarity
- Added ability for certain maps to modify the reclaim value of props
- Private messages now show 'From' and 'To' to make communication clearer

### Other
- Added Tamazight translation to FAF
- Improved a large number of Spanish translations
- Updated maps blacklist
- Fixed a shader error which cause water to render with jagged edges on some maps

### Contributors
- Arifi
- Brainwashed
- CookieNoob
- Crotalus
- Downlord
- Exotic-Retard
- IceDreamer
- Speed2
- TheKeyBlue
- Uveso


Patch 3663 (November 12th, 2016)
============================

### Bugs
- Fixed a small oversight which led to non-cloaked units getting the cloak FX in a power stall
- Added cloak FX support for cloak fields (Mods only, FAF itself has no unit with this ability)


Patch 3662 (November 9th, 2016)
============================

### Bugs
- Fixed units dropping from a transport from teleporting closer to a pre-assigned target
- Extend improved Aeon TMD code to all forms, such as on ships (To catch high-flying missiles)
- Fixed steam effect not playing for units after teleport

### Gameplay
- Reworked Selen yet again to improve user interaction. Manual toggle shifts selection priority and toggles weapon off. Motion toggles stealth.
- Integrated visual cloaking effect from BlackOps mod to show clearly when one of your units is in a cloaked state

### Balance
- T2 HQs
    - Energy cost decreased 13300 -> 11200
    - Mass cost decreased 1520 -> 1410
- ACUs
    - T2 upgrade
        - Energy cost increased 18000 -> 21000
        - Mass cost increased 720 -> 800
        - Buildtime increased 900 -> 1000
        - HP increased 1500 -> 2000
        - Regen increased 0 -> 10
    - T3 upgrade regen increased 0 -> 20
    - Aeon
        - RAS upgrade
            - Energy cost increased 150000 -> 175000
            - Buildtime increased 1400 -> 2800
            - Energy production decreased 2700 -> 1700
        - ARAS upgrade
            - Energy cost increased 150000 -> 175000
            - Buildtime increased 1400 -> 2800
            - Energy production decreased 5400 -> 3400
        - Shield upgrade
            - Energy cost decreased 93750 -> 35000
            - Mass cost decreased 1500 -> 1000
            - Buildtime decreased 1750 -> 1000
            - Energy maintenance cost decreased 250/s -> 150/s
            - Shield HP decreased 29000 -> 8000
            - Shield recharge time decreased 160 -> 65
            - Shield regen rate (Only while not under fire) decreased 37 -> 30
        - Advanced Shield upgrade
            - Energy cost decreased 1000000 -> 93750
            - Mass cost decreased 4500 -> 1500
            - Buildtime decreased 3500 -> 1750
            - Energy maintenance cost decreased 500/s -> 250/s
            - Shield HP decreased 44000 -> 29000
            - Shield recharge time decreased 200 -> 160
            - Shield regen rate (Only while not under fire) decreased 44 -> 37
    - UEF
        - RAS upgrade
            - Energy cost increased 150000 -> 175000
            - Buildtime increased 1400 -> 2800
            - Energy production decreased 3300 -> 2500
        - Nano upgrade
            - Add HP bonus of 2000
            - Regen decreased 60 -> 40
            - Energy cost decreased 44800 -> 24000
            - Mass cost decreased 1200 -> 800
            - Buildtime decreased 1400 -> 800
    - Cybran
        - RAS upgrade
            - Energy cost increased 150000 -> 175000
            - Buildtime increased 1400 -> 2800
            - Energy production decreased 3500 -> 2700
    - Seraphim
        - RAS upgrade
            - Energy cost increased 150000 -> 175000
            - Buildtime increased 1400 -> 2800
            - Energy production decreased 3000 -> 2000
        - ARAS upgrade
            - Energy cost increased 150000 -> 175000
            - Buildtime increased 1400 -> 2800
            - Energy production decreased 6000 -> 4000
        - Nano upgrade
            - Energy cost decreased 90000 -> 42000
            - Mass cost decreased 2000 -> 1200
            - Buildtime decreased 2800 -> 1200
            - HP decreased 6000 -> 3000
            - Regen decreased 75 -> 60
- sACUs
    - RAS upgrade energy cost increased 68000 -> 90000
- Aeon T1 MAA
    - HP decreased 360 -> 250
    - Radius increased 32 -> 35
- Janus
    - Damage increased 5 -> 6
    - Initial damage decreased 75 -> 30
    - Bomb count increased 8 -> 20
    - Damage time increased 2.5 -> 4.2
    - Significantly re-worked weapon fire sequence to increase ground cover and decrease focus damage
- UEF T2 MML
    - Turned on friendly fire to match all the others
- Air Staging
    - Decreased the staging 'Size' of most aircraft to make docking a much easier, much quicker process, with each building able to service more planes at once
- T1 Bombers
    - Energy cost increased 2400 -> 2450
    - Mass cost decreased 120 -> 105
    - Buildtime decreased 800 -> 700
- Mercy
    - Allow Mercy to land the same as other aircraft. Air maneuverability increased to allow it.
    
### Other
- Updated map blacklist
        
### Contributors
- CookieNoob
- Crotalus
- IceDreamer
- JaggedAppliance


Hotfix Patch 3661 (October 24th, 2016)
======================================
- Reverted ping-related changes which caused desyncs. We will approach this again in future, but it will require some changes to a certain popular mod as well. Stay tuned.
- Reverted 'Fixed upgraded structures not being targetable via radar blip'. This is the second time this code approach has ended up being reverted. It appears to interact with the engine in an unstable fashion, causing hard core crashes.


Patch 3660 (October 24th, 2016)
============================
### Lobby
- Fixed team number switching slots alongside a player
- Added new feature: Kick Reasons. When kicking a player from your lobby, you get a new dialog. You may type in a reason for the kick to notify the player. If you blank it, or leave the message as presented, it will play the old message.
- Fixed Cheat and Build multipliers for AIs showing 1.0 - 1.9 two times
- Fixed rating labels being shown on the minimap when teams are not set to 'Fixed'
- Made it clearer that there's a search filter in the map selection
- Added new unit share conditions for interesting new gameplay. "Full Share" and "Share Until Death" have been joined by "Traitors", which gifts all your units to the player who killed you (Very interesting for FFA games), "Defectors", which is the opposite of Full Share, gifting your units to the highest scoring enemy, and "Civilian Desertion", which gifts your units to a neutral civilian AI, if there is one.
- Improved the tooltip when hovering over your score in the lobby. It will now show a more detailed explanation including your rating deviation
- Fixed the position of the load button in Skirmish mode when launching offline
- Fixed 'Odd vs Even' autoteam button for random faction being the same as the 'Top vs Bottom' 
- Fixed new players joining a lobby being unable to see closed slots as being closed
- Fixed auto team settings not working for games with >8 players
- Changed 'Remove Player' to 'Kick Player' for clarity
- Removed nonfunctional 15 and 30 minute no-rush options
- Fixed the game crashing if you attempted to save a new preset

### Coop
- Fixed cinematics playing in coop games
- Improved AI sACU usage
- Fixed objective protection timer
- Fixed information sent to the server for leaderboard purposes

### Gameplay
- Improved Selen toggle. It now behaves with no abilities by default, then when toggled on it hides and shows based on motion as before
- Added dummy weapon to Aeon T2 Transport to allow LABs to be targeted to specific enemies
- Allowed UEF T2 Transport to be given targets while landed on water
- Enabled templates to be created with modded units as the primary unit
- New feature: Delayed Unit Transfer. Hold shift while giving a unit to another player to have it transfer once it finishes the command queue. Particularly useful when used with transports
- New feature: You can now cap mass extractors with storage by right-clicking a T2 or T3 mex, or double-shift-right-clicking an upgrading T1 or T2 mex, with an Engineer
- New feature: All ACUs now begin the game pointed towards the centre of the map, making things fairer between north and south on most maps
- Greatly improved teleport visuals for all ACUs and sACUs. Some of these effects are only used in coop
- T2 Artillery should more rarely shoot the floor in front of themselves in odd terrain situations
- Fixed Mermaid being unable to be hit by Neptune and Seraphim Destroyer fire
- Share Until Death now kills your walls as well. All other modes leave them intact

### Bugs
- Fixed units carried by UEF T2 Gunship from firing from inside a carrier
- Fixed Salvation fire rate slowing at max adjacency instead of speeding up
- Fixed units being able to fire at aircraft docked inside carriers, damaging the carrier
- Fixed games not ending properly with AIs
- Fixed Continental not dying to nukes (Again)
- Fixed upgraded structures not being targetable via radar blip
- Fixed shared unit cap taking civilian armies into account when sharing on player death
- Fixed UEF sACU AOE upgrade removal reducing the AOE too far
- Fixed the Spiderbot's laser beam getting stuck on temporarily while the unit executed the death animation
- Fixed the Cybran ACU wandering off long distance when told to assist various buildings with an enemy in the rough vicinity. It will still happen if the unit is much closer, but we should no longer have ACUs walking across the map to go kill themselves on enemy PD
- Fixed Seraphim ACU weapon trail showing when zoomed out
- Fixed Neptune Class weapon getting stuck on during death sequence
- Fixed a large number of projectiles showing the trails through fog of war
- Fixed T3 Mobile Artillery not quite being able to fire to the edge of their radius in some circumstances
- Fixed Siren ground toggle weapon using air weapon target priorities
- Fixed an error in timer resolution in coop mode

### UI
- Fixed UEF Engineering station strategic icon not matching the tech level
- Added missing strategic build icons used in "Bigger" mode
- Fixed displayed abilities on several units
- Fixed unit descriptions on support factories displaying for the wrong ones
- Fixed game quality displaying a corrupted string
- Fixed the scroll button in ACU enhancements freezing the tooltip popup action
- Added mod icon support for various UI elements
- Added build mode support for SCU presets
- Fixed a large number of tooltips not having proper localization
- Added some tooltips to features previously missing them
- Added ability to toggle reclaim labels. Set to Alt-R by default. You may have to bind this manually in the F1 menu.
- Massively improved reclaim label implementation to remove lag when zooming or panning
- Fixed a bug which caused the menu to block the top-left of the screen in ladder games

### Other
- Removed obsolete strategic icons and corrected file paths inside Hotstats module
- Fixed custom FAF player colours conflicting with Steam launcher
- Added German translation to FAF

### Contributors
- Crotalus
- Exotic-Retard
- IceDreamer
- Ithilis
- Justify87
- SlinkingAnt
- Speed2
- Uveso


Hotfix Patch 3659 (September 12th, 2016)
============================
- Fixed UEF T2 Naval Support Factory HP typo 900 -> 9000


Patch 3658 (August 29th, 2016)
============================
### Exploits
- Fixed an exploit where Factories and QGates could be made to build units at half-price

### UI
- UEF T2 Gunship will now display the transport icon when selected and hovering the mouse over one of your units
- Fixed typo in Seraphim ACU description
- Hydrocarbon Plants now use the amphibious background in the build menu
- Added rehost functionality to allow easy rehosting with the same game settings
- Enabled tooltips on queuestack, unitstack, and attachedunit entities (Shows tooltip when hovering over just about any unit build queue icon now)

### Lobby
- Fixed observer messages not showing in chat
- AI can now be swapped with real players
- The map previews now show the rating for each player slot currently assigned, and AI Names
- You can now set up your games via the map previews. Click on two players to swap them. Click an empty spot to occupy it.
- Fixed map preview highlights not going away when you exit the player switch drop-down menu in certain ways
- The colour of your rating text now changes colour, getting darker with higher deviation. This should make identifying smurf accounts easier.
- Added new spawn options: Fixed, Random, Optimal Balance, Flexible Balance
- Added message "Player kicked by host" to chat

### Bugs
- Fixed death animations for Cybran T1 mobile artillery and Seraphim T3 mobile artillery
- Fixed soundbank errors in several units
- Fixed torpedoes colliding with missiles and destroying them
- Paragon no longer does low damage to buildings and ACUs
- Fixed Size 4 buildings such as T2 PD and Flak getting a Rate-Of-Fire adjacency buff from PGens
- Fixed bug in AI Engineer behaviour which let to an engine crash
- Fixed templates not working if a unit added by a mod was the first built in the selection used to form the template
- Fixed Selen radar not enabling on build
- Fixed possible desync trigger in AI games

### Gameplay
- The Ythotha now spawns the energy being no matter the method used to kill it
- The Ythotha energy being only spawns for a completed unit
- Added pause button for Nuke Subs and Seraphim Battleship
- Nuke Launched warning now plays for Observers
- Overhauled bomb-drop aim calculation code. It now takes the Y axis into account, and spaces multi-projectile drops properly. In theory, this should be the last word in bombers missing stupidly.
- Improved AI base management in campaign scenarios
- Sub dive toggle now prioritizes dive in mixed groups
- ACUs start rotated at middle of map as default

### Balance
- Light Assault Bots
    - Build time reduced 140 -> 120
- Cybran T2 Mobile Stealth
    - Energy drain increased 25 -> 75
- Fire Beetle
    - Now takes two transport slots the same as all other T2 units
- UEF T1 Mobile Artillery
    - Health increased 200 -> 205
- Scathis
    - Mass cost increased 85,000 -> 110,000
    - Energy cost increased 1,500,000 -> 2,000,000
    - Build time cost increased 31,500 -> 50,000
    - Weapon range decreased 330 -> 300
- Selen
    - Reworked hiding ability into a button toggle:
        - When pressed, puts the unit in hide mode. The weapon is disabled, all commands are removed from the unit, and it comes to a halt. Counter-intel Stealth and Cloak come online once it's stopped.
        - Selens in hide mode have lowered selection priority: They cannot be selected alongside other units.
    - Introduced power drain in hide mode - 5 energy/second
- Mobile T1 AA
    - Mass cost increased 28 -> 55
    - Energy cost increased 140 -> 275
    - Build time increased 140 -> 220
    - UEF
        - Health increased 200 -> 360
        - Speed increased 2.8 -> 3.3
        - Damage increased 8 -> 16
    - Cybran
        - Health increased 130 -> 260
        - Damage increased 8 -> 16
        - Removed AA/AG toggle. The weapon will now auto-toggle between modes
            depending on what is in range, prioritising AA.
    - Aeon
        - Health increased 200 -> 360
        - Speed decreased 3 -> 2.8
        - Damage increased 5 -> 10
    - Seraphim
        - Health increased 200 -> 360
        - Speed increased 2.5 -> 3.4
        - Damage increased 4 -> 8
- T2 Hover Tanks
   - UEF
        - Increased speed on water 3 -> 3.3
   - Aeon
        - Increased speed on water 3 -> 3.5
   - Seraphim
        - Increased speed on water 3 -> 3.5
- T2 Flak
   - UEF
        - Increased speed 2.8 -> 3
   - Cybran
        - Decreased speed 2.9 -> 2.7
   - Aeon
        - Increased speed on water 3 -> 3.5
        - Decreased speed on land 3 -> 2.6
   - Seraphim
        - Increased speed on water 3 -> 3.5
        - Decreased speed on land 3 -> 2.5
- Engineers
   - T2 Engineers
        - Decreased energy cost 700 -> 650
        - Decreased mass cost 140 -> 130
        - Decreased build time 700 -> 650
       - UEF
            - Increased health 300 -> 400
       - Cybran
            - Increased health 290 -> 390
       - Aeon
            - Increased health 240 -> 340
       - Seraphim
            - Increased health 250 -> 350
   - T3 Engineers
        - Decreased energy cost 2200 -> 1560
        - Decreased mass cost 440 -> 312
        - Decreased build time 2200 -> 1560
       - UEF
            - Increased health 600 -> 800
       - Cybran
            - Increased health 540 -> 740
       - Aeon
            - Increased health 480 -> 680
            - Decreased build rate 40 -> 30
       - Seraphim
            - Increased health 500 -> 700
            - Decreased build rate 40 -> 30
- T1 Bombers
    - Increased energy cost 2250- 2400
    - Increased mass cost 80 -> 120
    - Increased build time 500 -> 800
    - Removed Radar ability
    - Increased RateOfFire 0.25 -> 0.2
    - Cybran and UEF
        - Decreased FiringRandomness 3 -> 0
    - Flight Parameters
        - Decreased BreakOffDistance 30 -> 24
        - Increased CombatTurnSpeed 0.75 -> 1.5
        - Increased KTurn 0.7 -> 0.8
        - Decreased StartTurnDistance 5 -> 1.4
        - Increased TurnSpeed 0.75 -> 1.5
        - Decreased RandomBreakOffDistanceMult 1.5 -> 1
- Ahwasssa
    - Decreased StartTurnDistance 15 -> 1
    - Increased TurnSpeed 0.65 -> 0.9
- Cybran T1 Frigate
    - Decreased AA MuzzleVelocity 60 -> 45
    - Removed AA projectile tracking
    - Removed AA projectile TurnRate
- Cybran T2 Destroyer
    - Decreased AA damage 10 -> 5
- Cybran T1 Static AA
    - Fixed bug preventing it from shooting scouts on certain approaches
- Tactical Missile Launchers
   - UEF
        - Decreased clip size 12 -> 6
   - Cybran
        - Decreased clip size 10 -> 4
   - Aeon
        - Decreased clip size 16 -> 6
   - Seraphim
        - Decreased clip size 20 -> 8
- T2 Static Artillery
    - Decreased build time 1608 -> 1200
- Aeon TMD
    - Adapted weapon collision to prevent flare failing to intercept missiles flying near
        the top of the range sphere
- Factory Cost Changes
    - T2 Land HQs
        - Increased mass cost 800 -> 1520
        - Increased energy cost 7200 -> 13300
        - Increased build time 1600 -> 2600
    - T3 Land HQs (Price increase due to the T2 cost increase)
        - Increased mass cost 4540 -> 4920
        - Increased energy cost 41100 -> 43900
    - T2 Land Support Factories
        - Increased mass cost 300 -> 340
        - Increased build time 1300 -> 1600
    - T3 Land Support Factories
        - Increased mass cost 750 -> 860
        - Increased build time 3000 -> 4000
    - T2 Navy HQs
        - Increased mass cost 1370 -> 1700
        - Increased energy cost 6600 -> 8500
        - Increased build time 2400 -> 3600
        - Increased build power 60 -> 90
    - T3 Navy HQs
        - Increased mass cost 5450 -> 7500
        - Increased energy cost 24472 -> 35000
        - Increased build time 8200 -> 11250
        - Increased build power 120 -> 150
    - T2 Navy Support Factories
        - Increased mass cost 500 -> 800
        - Increased energy cost 2500 -> 4000
        - Increased build time 2000 -> 3000
        - Increased build power 60 -> 90
    - T3 Navy Support Factories
        - Increased mass cost 800 -> 1100
        - Increased energy cost 3429 -> 5500
        - Decreased build time 4000 -> 3500
        - Increased build power 120 -> 150
- Cybran T3 MAA
    - Removed AA/AG toggle. The weapon will now auto-toggle between modes
            depending on what is in range, prioritising AA
- Cybran T2 Cruiser
    - Removed AA/AG toggle. The weapon will now auto-toggle between modes
            depending on what is in range, prioritising AA
    - Decreased AG toggle weapon damage 60 -> 40
    - Increased AG toggle weapon rate of fire 0.5 -> 1
    - Decreased AG toggle weapon rockets per salvo 6 -> 3
    - Increased AG toggle weapon FiringRandomness 0.3 -> 0.9
- All ACUs
    - T2 Upgrade
        - Removed health regen bonus
        - Decreased health increase 3000 -> 1500 (UEF, Aeon, Seraphim) 3500 -> 2000 (Cybran)
    - T3 Upgrade
        - Removed health regen bonus
        - Decreased health increase to respect the T2 adjustment
        - Decreased buildpower 126 -> 100
    - Aeon ACU
       - Enhanced Sensor System Upgrade
            - Decreased mass cost 400 -> 350
            - Decreased energy cost 10000 -> 5000
            - Decreased omni radius 100 -> 80
            - Increased visual radius 50 -> 80
    - Cybran ACU
        - Decreased health regen 17 -> 15
        - Changed regen per veterancy level 21/24/27/30/33 -> 19/23/27/31/35
        - Personal Stealth System Upgrade
            - Decreased energy cost 5250 -> 5000
            - Increased build time 350 -> 500

### Contributors
- Brutus5000
- ckitching
- Crotalus
- Downlord
- Exotic_Retard
- IceDreamer
- JaggedAppliance
- JJ173
- Justify87
- Shalkya
- Sheeo
- Speed2
- Uveso
- ZockyZock


Hotfix Patch 3656 (August 8, 2016)
============================
### Server Compatibility
- Made teamkill reporting work alongside the server update V0.3
- Change the format of unit statistics to enable server harvesting for achievements

### Contributors
- Crotalus
- Downlord


Patch 3654 (May 30, 2016)
============================
### Reverted
- The change in 3652 which refreshed intel for a blip on upgrade had unintentional free intel side effects we have been unable to solve. As such, that change has been reversed

### UI
- Fixed reductions in MaxHealth resulting in UI displaying 10000/9000 HP
- Added slot numbers in the lobby
- Toggling the shield on a selection of units with a mix of active and inactive shields now toggles them ON instead of OFF
- The tooltip now shows for ACU and sACU upgrades that are not yet buildable

### Bugs
- Reclaiming something under construction won't stall out any more
- Drones no longer display build-range rings
- UEF Drones no longer leave wrecks
- Fixed Seraphim Regen Aura level two not applying to newly built units
- Fixed Billy using the full 'Ignore shields' nuke code
- Fixed a typo in the Seraphim ACU which prevented the Gun upgrade from being completed
- Fixed Chrono Dampener getting jammed by Overcharge
- Fixed FX bug on Deceiver

### Other
- Removed unused code

### Contributors
- ckitching
- Crotalus
- Downlord
- duk3luk3
- IceDreamer
- Justify87
- Sheeo
- Softly
- Speed2
- Uveso


Patch 3652 (May 2, 2016)
============================
### Lobby
- Name filter when selecting map
- Prevent host from changing player teams while he is ready
- Game quality in lobby now visible again
- Reduced autobalance random variation to get team setups with better overall quality
- Default to score off
- Stopped the map filter preventing the map selected in preferences from prior games from showing
- Tiny fix to flag layout
- Fixed descriptions for the AIx Omni option and Lobby Preset button

### UI
- Introduced Russian translations of many FAF additions to the game (Exotic_Retard and PerfectWay)
- Translate some FAF additions to Italian
- New keybindable action: 'soft_stop'
- Soft-stop will cancel all orders of a factory except their current one, if you soft-stop a factory with only one order it will get cleared
- Hold down Alt when giving a factory order to soft stop factory before issuing next order
- Multi-upgrade: Added UI support to upgrade structures several levels at once (i.e: cybran shields, hives, mexes, factories etc)
- Auto-overcharge: It's now possible to let overcharge fire automatically whenever you have the required power
- Order repair on a wreck to rebuild it if possible by some of the selected engineers. Those not able to rebuild the wreck will assist after the build starts.
- Units explicitly repairing (not assisting) a structure that dies will automatically try to rebuild it
- Refactor the income economy overlay not to show reclaim values appearing in the generated income column and do correct rounding of the numbers.
- Fixed bug with unit regen debuff not being visible in UI
- Fixed bug with buildpower not visible in unitview
- Score display in the top-right no longer counts reclaim into the Mass/Energy income shown in observer mode
- Allow Hotbuild to find Support Factories
- Allow the UI code to search active mods for unit icons. Mods will have to have the icons in the right place (/modname/icons/units/xxx_icon.dds). Confirmed working for Total Mayhem at least, and probably many more.
- Show ren_networkstats in Connectivity Screen (F11)
- Show name of the one resuming a paused game
- Reverted the change to T1 PD icons from 3641, so now they don't give free intel on mouse-over when trying to fake PD-wall with all-wall radar ghosts.
- Render build range of engineers using native overlay system instead of decal hack
- Enabled Pause button in replays
- In Units Manager, added more preset restrictions (e.g. No T1 spam, No Snipes, No TMLs)
- In Units Manager, separated some existing preset restrictions (e.g. game-enders, nukes) for better selection
- In Units Manager, added custom restrictions for all FA units
- In Units Manager, added custom restrictions for modded units when mods are activated
- In Units Manager, added mechanism for restricting units using preset restrictions and/or custom restrictions
- In Units Manager, added grouping of units based on faction, type, purpose, and tech level
- In Units Manager, added detailed tooltips with stats for weapons, defense, and eco for all units
- In Units Manager, added visualization of modded units using small purple icon with letter M
- In Units Manager, improved description of preset restrictions
- In Mods Manager, added filters for UI/Game/Disabled mods
- In Mods Manager, improved sorting mods by their activation status and names
- In Mods Manager, added cleanup of mod names with mismatching mod versions
- In Mods Manager, added mod versions next to mod names
- Added pre-loading and caching of blueprints for usage in the Units Manager

### Gameplay
- Teamkill is now detected and a player can make an explicit report
- Air units are now able to fire at water-landed transports
- Hoplite now calculate their aim correctly when firing at a fleeing target
- Slightly increased unit size(not hitbox) of T3 sniper bots, Othuum and Rhino to alleviate their weapon's ground-hitting ability
- Seraphim Experimental Nuke now deals damage to itself
- Cybran drones no longer leave wreckage when killed
- Defense structures now start rotated at their nearest enemy when built, if no enemies found they default at middle of map
- Removed friendly fire on Atlantis AA
- Locations of enemy civilian structures are now revealed at start of the game (lobby option)
- Navy units now should respect their max-range better when having move-attack order
- Set GuardReturnRadius to 3 as default, will make guarding / patrolling / move-attacking units less prone to move off their designated mission while hunting something
- Units moving on sea bottom now leave tread marks - they disappear faster though
- Re-enabled death animation on non-naval units
- Seraphim GW now uses all its 3 exits
- Spread attack targets are now spread more uniformly among all units during the initial attack orders, further ones are random.
- Diplomacy now allowed in Coop mode
- Allow Fatboy, Atlantis, Tempest and Czar to fire while building units
- Beam weapons now kill missiles they impact instead of wasting DPS for several ticks
- Aeon ACU upgrade "Chrono Dampener" won't stun allied units any more. Additionally, it will fire at predetermined ticks so the effects of multiple acu's do not stack.
- Increased TMD range by 1 and ROF by 0.2s to prevent a single TML killing a single TMD by using ground-fire to impact before the second TMD shot fires.
- Fixed Cybran T3 MAA doing friendly damage on 1 of its 2 AA weapons
- Fixed Cybran T3 MAA hitbox/bones making lots of units miss
- Fixed Seraphim T1 sub not being hit by torpedoes 80% of the time while surfaced.
- Enemy civilians are now colored in a unique red color
- Fixed bomb drop code and enabled it for Janus, and UEF/Cybran T1 Bombers to attempt improvement to bomb drop characteristics
- Allowed Aeon Aircraft Carrier to build Bombers and Gunships, same as the others.
- Fixed restriction system on Sim side such that it cannot be compromised by UI mods
- Fixed restriction system that prevented removing restrictions on already restricted units in scenario scripts

### Bugs
- Fixed free mass exploit with Megalith eggs
- Fixed bug with Cybran SCUs getting EMP for free
- Fixed bug with units getting invincible after a visit to their nearest carrier
- Fixed bug with not able to target a blip of a given / upgraded structure
- Fixed bug which caused silo missiles to disappear at launch stage
- Fixed bug with water sounds not playing while a unit was submerged
- Fixed bug with omni buff instead getting radius of radar
- Fatboy and Cybran cruisers shouldn't engage enemies way outside their range anymore
- Fixed bug with commander not always being selected at start
- Fixed wrecks not giving resources in Coop mode
- Fixed Coop missions getting stuck at completion
- Added missing Seraphim objective icons
- Shields now overkill damage correctly based on their type
- Fixed nukes overkilling bubble shield base structure when out of range and shield up
- Fixed Continental taking damage from AOE when it has the shield up
- Fixed regen buffs from different sources not stacking properly. This should mean every possible interaction between veterancy, upgrades, and the Seraphim Regen Aura field all play nice
- Fixed Underwater Vision not being initialized on unit completion
- Fixed Engineers not properly reclaiming the target of an assisted, then stopped, Engineer
- Fixed UEF Drones being untargetable by Interceptors
- Fixed UEF Drone collision detection, making it much easier for ground-based AA to hit them
- Fixed UEF AI unit templates in coop mode
- Fixed an exploit with being able to upgrade restricted enhancements
- Fixed a rare bug with builders getting near zero HP after a naval building gets destroyed the same tick as it finishes.
- Fixed shields sometimes not turning off due to lack of Energy
- Fixed buffs from enhancements being applied too often after unit transfer
- Fixed submersible naval units leaving full reclaim mass
- Nuclear explosions now behave predictably, always bypassing/ignoring bubble shielding

### Performance
- Optimization of score accumulation
- Tweaks to hive build effects to reduce performance impact
- Cleanup of enhancement sync code to make it faster and more secure
- Entities now re-use repeated sound FX instead of creating new ones every time
- Reduce load on render thread
- No net_lag in single-player to increase UI response speed

### Other
- Added game-side support for future achievement system
- Tech-level filter in debug window now works as intended
- Log-spam from various known events heavily reduced
- Lots of work adapting and improving AI behavior for coop gameplay (speed2)
- Scale aeon build effects according to build progress
- Show wreckage debris in reclaim beam

### Contributors
- Sheeo
- IceDreamer
- Crotalus
- speed2
- Exotic_Retard
- duk3luk3
- HUSSAR
- Downlord
- madformuse
- quark036
- CodingSquirrel
- PerfectWay


Patch 3650 (August 19, 2015)
===========================
HTML-version of this balance oriented changelog available at: http://content.faforever.com/patchnotes/

### Seraphim and UEF ACU TML
- Missile hitpoints: 3 hp → 2 hp
- Flying height: now similar to normal TML
- Mass cost: 1000 → 1500
- Minimal range: 5 → 15
- Muzzle velocity to 7
- Only for Seraphim:
- Area of effect: 3 → 2
- The flying arc at close range will now be similar to the UEF ACU TML

### Cybran TML
- TMDs (except Aeon) will now survive a single cybran tactical missile if they have full HP

### TML friendly Fire
- TML missiles no longer deal friendly fire

### sACU changes
- Hitbox: lasers can now hit SCUs more reliably
- SCUs now leave a normal wreckage with 81% of their mass value when destroyed
- A RAS preset for UEF, Cybran and Aeon is now available for production from the Quantum Gateways.
- Aeon SCU
    - Reacton Cannon (Gun upgrade) energy cost: 36000 → 46200, build time: 5040 → 6048
    - Heavy Personal Shield hitpoints: 35000 → 40000, mass cost = 1500 → 1800
- UEF SCU
    - Personal Shield Generator HP: 32000 → 26000 HP
    - Heavy Plasma Cannon (Gun Upgrade) rate of fire x2.5 → x1.82 (DPS 750 → 546), AOE: 2.5 → 2
    - Radar Jammer mass cost: 600 → 300, energy cost = 18000 → 8000
    - Bubble shield energy cost: 400000 → 360800
- Cybran SCU
    - Nano-Repair System regeneration rate: 400 hp/s → 375 hp/s, mass cost: 2000 → 2200
    - Focus Converter (Gun upgrade) adds damage: 250 → 200
    - Nanite Missile System (SAM Upgrade) DPS: 272 → 400
    - EMP duration for Tech1/Tech2/Tech3/SCU: 4/4/4/0 → 4/3.5/3/0.3
    - Stealth upgrade mass cost: 600 → 400, energy cost: 18000 → 7400
    - Cloak upgrade energy cost: 500000 → 382200
- Seraphim SCU
    - Overcharge: now tracks (like ACU overcharge)
    - Overcharge reload time: 5 seconds → 7.5 seconds
    - Overcharge damage: 12000 → 10000
    - Overcharge DPS: 2400 → 1333
    - Shield mass cost: 1500 → 1200, shield hitpoints: 25000 → 20000
### Hover Tanks
- Seraphim (Yenzyne)
    - Build time: 880 → 1050
    - Speed on water: 4.3 → 3
- Aeon (Blaze)
    - Build time: 880 → 1050
    - Speed on water: 4.3 → 3
- UEF (Riptide)
    - Build time: 1320 → 1600
    - Speed on water: 3.7 → 3
    - Mass cost: 362 → 360
    - Energy cost: 1980 → 2000
### Hover flak (Seraphim and Aeon)
- Speed: 3.6 → 3
### Seraphim Tech 2 bot and Tech 3 Tank Changes
- We are carefully toning down both areas while keeping the idea behind it intact. Ilshavoh becomes weaker, and Othuum becomes stronger.
### Ilshavoh
- Turret turn rate: 180°/s → 70°/s
### Othuum
- Speed: 2.5 → 2.6
### Harbinger
- Will now take longer to make, making it harder to spam them so fast and allowing opponents slightly more time to bring counters into play.
- Veterancy: 15/30/45/60/75 → 18/36/54/72/90
- Build time: 3600 → 4500
- Can no longer fire while reclaiming
### Sniper bots (Seraphim and Aeon)
- It is annoying when sniper bots lose all their damage while moving and trying to shoot. They will hit more often now, even - though using them stationary will still lead to the best results.
- Firing randomness when moving: 0.8 → 0.5
### UEF T3MAA
- Other faction’s T3 MAA were hitting much better than the UEF one. This change is improving its accuracy to similar levels.
- Slight tracking added with small turn rate (20)
- Muzzle velocity: 100 → 110
### Navy
- Summit
    - Is now more expensive, giving other factions more time to beat them before they are able to gather a critical mass.
    - Mass cost: 9000 → 10500
    - Energy cost: 54000 → 62000
    - Build time: 28800 → 33000
    - Area of effect: 3 → 2
- Aeon Frigates
    - Will now be more effective vs hover, but not vs ships.
    - Hit points: 1800 → 1850
    - Damage per shot: 140 → 50
    - Reload time: 5 seconds → 1.7 seconds (DPS: 56 → 58)
    - MuzzleChargeDelay: 0.5 → 0
    - Anti-torpedo weapon reload time: 10 → 12.5
### Air
- Strategic bombers (all factions)
    - Increasing the energy cost of strategic bombers to avoid the ability to rush them so easily.
    - Energy cost: 105000 → 144000
    - Build time: 8400 → 9600
- Corsair
    - Reducing the speed of their projectiles to make them as easy (or hard) to dodge as they were before the range decrease.
    - muzzle velocity: 35 → 30
- Torpedo bombers
    - We made several adjustments to allow torpedo bombers to actually deliver their torpedoes more often.
    - Reload time for all torpedo bombers: 12.5 → 10
- Uosioz (Seraphim Torpedo Bomber)
    - Torpedoes get now dropped in front of the bomber (like all other bombers)
    - Range: 42 → 35
    - Amount of volleys: 2 → 3
    - Now ignores torpedo defense (like all other torpedo bombers)
    - Multiple adjustments to torpedoes make them less likely to crash on the ground in shallow water
- Skimmer (Aeon T2 Torpedo Bomber)
    - Depth charges get now dropped in front of the bomber (like all other bombers)
    - Range: 42 → 35
    - Amount of volleys: 2 → 3
    - Multiple adjustments to depth charges make them less likely to crash on the ground in shallow water
- Solace (Aeon T3 Torpedo Bomber)
    - Range: 42 → 32
    - Projectile turn rate increased
- Awhassa
    - Added armour to ASF to guard them from the bomb, reducing their damage taken to 10%
    - Veterancy: 50/100/150/200/250 → 100/200/300/400/500
    - Reload time: 10 → 12
### Other
- Quantum Gateway
    - We are reducing the adjacency bonus for mass fabricators next to Quantum Gates to a more normal level.
    - Tech 2 mass fabricator: 2.5% → 0.75%
    - Tech 3 mass fabricator: 15% → 2.25%
    - Tech 3 power generator: 18.75% → 5%
    - Preset names improved
- T3 Land HQ
    - Build time: 9400 → 11000
- Sonars
    - T2 sonar
        - Mass cost: 120 → 150 (Seraphim stays 180)
        - Energy drain: 100 → 150

    - UEF/Aeon T3 sonar
        - Mass cost: 400 → 1000
        - Energy drain: 100 → 250

    - Cybran T3 sonar
        - Mass cost: 480 → 1200
        - Energy drain: 250 → 400
- Energy/Mass overflow
    - The bug that caused resources to disappear when they got shared to several teammates and one of them had full storage does not exist and is a FAF urban legend. If a teammate has full storage, the resources get properly shared to a different teammate instead. It is not needed to use any mods to prevent resources from getting lost or to inform others about this "bug".
    - No change required


Patch 3648 (August 13, 2015)
===========================
### Bugs
- ASF no longer have issues gaining targets when just given move orders
- Satellite works with 'no-air' restriction again

### Enhancements
- Remove 'no sc1 units' restriction that would make the game unplayable


Patch 3646 (August 11, 2015)
===========================
### Bugs
- UEF buildbots no longer explode after being built with 'no-air' restriction enabled
- Commanders no longer explode immediately with the 'no-land' restriction enabled
- Upgraded hives are no longer invincible
- Beam weapons will no longer keep firing their lasers after designated targets have died
- Nukes will always generate personal shields again
- Paused units which start work on a building will no longer consume resources

### Enhancements
- Units with sonar no longer have it enabled while on land
- Added 'no T3 air' restriction


Patch 3644.1 (August 5, 2015)
==========================
### Enhancements
- "More unit info" mod integrated and improved
- Incompatible mods and old maps are now blacklisted


Patch 3644 (July 27, 2015)
==========================
### Bugs
- AI now works again
- Unpausing engineers works again
- Units currently being built no longer hang around when transferring or reclaiming the factory the were being built in.
- Seraphim units render correctly on medium fidelity

### Enhancements
- Jammer field from crystal now stops working when the crystal is reclaimed
- Jammer crystal reclaim increased to (5000e, 50bt)


Patch 3643 (July 24, 2015)
==========================
### Bugs
- Fixed issue with half built units from naval factories
- Fixed issue with sometimes being unable to quit the game
- Cybran and UEF buildbots / drones no longer explode with the no air restriction
- Fixed issue with being unable to reclaim mexes that are being upgraded
- Seraphim ACU minimum range for normal gun and OC adjusted to be the same as other ACUs
- Seraphim destroyer surfaces itself after building again
- Seraphim T2 transport no longer allows active shields on board
- Seraphim ACU restoration field now works for allied units
- Aeon T3 battleship TMD is no longer completely unable to stop TMLs

### Enhancements
- Added ability to see unit data (xp/regen rate) as observer
- Firebeetles can no longer detonate in the air
- Upgrade hotkey now works for T2 naval and air support factories

### Contributors
- CodingSquirrel
- Crotalus
- Gorton
- Sheeo
- ckitching
- ggwpez


Patch 3642 (July 13, 2015)
==========================
### Bugs
- Obsidians and titans die to overcharge again


Patch 3641 (July 12, 2015)
==========================
### Exploits
- Instant crash exploit partially fixed
- No longer possible to give away units in progress of being captured
- No longer possible to bypass unit restrictions with sneaky UI mods
- Fixed being able to remotely destroy wreckage anywhere on the battlefield

### Bugs
#### Hitboxes
- Seraphim sniper bot is able to hit Cybran MML again
- Fixed SCUs not being hit properly by laser weapons
- Fixed units aiming too high on the UEF and Aeon SCUs
- Torpedo/sonar platforms no longer confuse surface weaponry

#### Visual
- Fixed shield structure glows and rotations not playing
- Fixed bug with capture progress bar not being synced if using multiple engineers
- Optimized the range-rings shader to reduce the way FPS falls off a cliff
- Fixed bug with instantly disappearing wrecks due to garbage collection
- Fixed wrong regen values being reported on UI-side
- Disable build effect beams on sinking engineers
- Reload bar refill rate now scales with RateOfFire buffs
- Legacy checkbox UI code working again
- Fixed Engineers spawning the wrong tarmacs when building Seraphim buildings
- Engineering stations no longer exhibit a model bug when rebuilt by an assisting SCU
- Fuel indicator no longer falls off the unit detail window
- Seraphim ACU and SCU no longer show the tactical missile counter if they don't have the upgrade

#### Physics
- Projectiles no longer collide with sinking units
- UEF T3 Transport now leaves wreck in water
- Cybran ACU can now fire the laser when standing in water
- Fixed Seraphim T1 Mobile Artillery not firing at fast targets properly
- Yolona Oss now deals damage to itself
- Flares and depth charges no longer draw in friendly projectiles
- Fix shots sometimes going right through Walled PD
- Increased Aeon T3 Artillery MuzzleVelocity to allow it to fire at its maximum range

#### Other
- T3 Torpedo Bomber can use Attack-Move properly again
- Units with weapon range upgrades now stop at maximum range when using attack-move
- Shield disruptor now works on personal shields
- Fixed wrong consumption when repairing ACU after an upgrade finished
- Support factories no longer lose progress if they are damaged during upgrade
- Aeon SCUs with nano + vet now get correct regen rate
- Fixed share until death bug with dual-given units
- Mini map now remembers whether to show resource icons or not
- Current command mode no longer reset if an engineer dies in the current selection
- Fixed bug with chat messages having wrong recipients in replay
- Seraphim shields can now pause while upgrading to T3
- Fixed RateOfFire buffs not being applied correctly
- SCUs will no longer rebuild buildings they lack to ability to build
- Upgraded buildings rebuilt by assisting SCUs will now cost the correct amount
- FAF no longer blows up if the game hasn't first been launched to create a profile

### Enhancements
#### Visual
- Scathis now has Amphibious build icon
- Attack and Nuke reticles now scale with impact radius
- TMLs now show the splash damage radius in targeting mode
- Cybran Engineers now display a build beam to clearly show what they're tasked to
- Cybran factories now have red build beams
- Number of Cybran build bots scale with buildpower of the engineer, to a maximum of 10
- Ping values under "Connectivity" (F11) now update during game stop/stall
- Added Yolona Oss to Mavor/Salvation/Scathis build restriction and renamed it
  Super-Game-Enders
- ASF effects tweaked for performance (less effects on low fidelity)
- Cybran engineering build bots now crash when their owner dies rather than just vanishing
- Quantum Gateways now can assist each other
- Enhanced Seraphim tarmacs
- Beams originating inside Fog of War will no longer be invisible
- Cybran buildbots are no longer invisible to other players
- MEx, T1 PD, and Radar strategic icons will appear above other building icons when zoomed out


#### UI
- New option: Show reclaim value of wreckage on map by pressing Ctrl-Shift
  (need to enable it in Options / Interface and restart game)
- Smart selection feature allowing hotkeys to select units by category
- Remove owner-check on text pings so anyone can delete them
- Reclaim/second now shown
- Reclaimed mass now counts towards the score table
- UEF ACU and SCU drones now have an on-drone button to toggle if they are rebuilt at death
- Now possible to pause units to make them pause execution of queued up orders
- Debug window: Searching for units now supports unit name and substrings
- Cybran engineering build bots no longer display the heads-up consumption overlay
- "Commander under attack" now plays for shielded ACUs
- 34 new taunts
- Added a button to unbind key mappings
- Drop shadow for chat messages
- Chat Option: Add background to chat messages when chat window is closed
- Chat Option: Allow chat to timeout normally in the feed after closing window
- Reclaim window merged with main resources UI

#### Other
- Engineering Station units now pause on transfer from one player to another
- Cybran build bots now can assist next build project without re-spawning
- The least valuable units are destroyed at unit transfer if unit cap is hit
- Absolver shield disruptor now hovers higher, so it's less likely to hit the
  floor with the very low mounted gun
- UEF SCU Drone can now capture, the same as the ACU ones
- Tiny changes to make Fatboy/Megalith/Spiderbot weapons symmetrical in
  behaviour where they should be
- Added templates for all support factories. AI in coop missions is now able to
  rebuild support factories
- Assist now prioritize building over repair
- Share Until Death is now default
- Mod size reduced by about 30 MB

### Contributors
- CodingSquirrel
- Crotalus
- DukeOfEarl
- Eximius
- IceDreamer
- ResinSmoker
- Sheeo
- Speed2
- anihilnine
- bamboofats
- ckitching
- quark036
- shalkya
- pip
- zock

### Special Thanks To
- Softly
- Exotic Retard
- Nyx


Patch 3640 (Jan 6, 2015)
========================
- Addressed an issue that causes the game to crash with core dumps in long games


Patch 3639 (Jan 5, 2015)
========================

### General changes
- Christmas presents for reclaim have been removed
- Score viewing:
    - Score button no longer exits the game forcefully
    - Viewing of score screen when scores were set to off is re-enabled, but the
      statistics are not particularly useful

### Exploit fixes
- Fixed a regression of the free ACU upgrade exploit

### Game improvements
- Cartographic map previews are now being generated even for maps that do not contain colour information for them.

### Bug fixes
- Fixed air wrecks floating mid air on certain maps
- Fixed air wrecks sinking to bottom of water, then jumping back up to surface
- Fixed continental not dying to nukes
- Improved GuardScanRadius:
  - Scouts no longer engage at long range, value was set to 10
  - Harbinger will automatically engage at range again
  - Range tuned down a bit so units will not run off too much
- Fixed Seraphim T3MAA targetbones (Units will no longer aim above it)
- More mod compatibility
- Give Eye of Rhianne restriction a new description
- Fixed hoplite not firing at landed air units
- Added BOMBER category to Ahwassa, Notha
- Added FACTORY category to Megalith, allows queuing of units while being built
- Improve new unit share code (Units dying after being transferred multiple times)
- Fixed sinking wrecks blocking projectiles where the unit used to be

### Lobby changes (Version 2.6.0, also shown in game)
- Fix the rating not showing up for observers
- Font-size for observers reduced
- Chat font-size adjustable from options
- Remove debug messages
- Connection dialog no longer appears below lobby slots
- Fixed issue with players not being removed from slots on disconnect
- Fix integrated replaysync
- Clan tags are shown in game
- 'Set ranked options' button works again
- Tooltips for various buttons fixed and text revised
- More detailed large map preview
- Seraphim icons normalized
- Both players get ready flag cleared on swap
- Removed extra space around Rerun CPU benchmark button
- Made 'Random faction' skin load the chosen faction skin (Before it would always be UEF)
- Fixed a problem preventing player colours from being updated correctly
- Prevented CPU benchmark from running once the game starts
- General performance improvements


### Special Thanks
- Thanks to pip, briang and Alex1911 for translations

### Contributors:
- ChrisKitching
- Crotalus
- IceDreamer
- Partytime
- Santa Claus
- Sheeo
- Xinnony


Patch 3638 (Dec 24, 2014)
=========================
- Added christmas presents for reclaim
- Big thanks to ozonex for this contribution!


Patch 3637 (Dec 12, 2014)
=========================
### Bug fixes
- Selection Range Overlay works for multiple units again
- Score no longer flickers when watching replays
- Targeting issues, especially related to the seraphim ACU have been addressed
- Compatibility with certain mods restored
- Lobby 2.5b included (Changelog shown in game)

### Notes:
- On some maps air wrecks may still appear in midair
- It's still likely that there are incompatibilities with mods. Please let us know your exact setup of the game when reporting issues


Patch 3636 (Dec 12, 2014)
=========================
### Exploit Fixes*
-  Fixed infinite economy exploit
-  Fixed free ACU upgrade exploit
-  Security exploits with simcallbacks
-  Fixed UEF Drone upgrade exploits

### Bug Fixes
-  Continental Fixes:
    -  Fixed units firing from transport
    -  Fixed Continental not dying to Nukes with the shield up
    -  Improved fix for units being transported taking no damage while the shield is up
-  Fixed UEF T3 Mobile AA being able to fire from Continental, and reduced projectile number
-  T3 Seraphim Mobile Artillery given proper 'ARTILLERY' designation
-  Fix adjacency buffs working when unit is turned off
-  Fixed Cybran ACU with Laser upgrade being unable to ever fire the weapon after being transported, and improve targeting further
-  Fixed Cybran ACU with Torpedo upgrade firing at the floor after being transported
-  Fixed Cybran ACU Torpedo upgrade firing while the ACU's feet are only just underwater
-  Fixed Cybran ACU being unable to be shot by Torpedoes with only its feet in the water
-  Fixed Seraphim ACU dying when dropped from Transport after being picked up while firing
-  Fixed Seraphim ACU shot being visible through FoW
-  Fixed invalid preview range of SMDs
-  Fixed Aeon T1 Bomber targeting subsurface units
-  Given units now get correct experience points
-  Given units are returned to their original owner in share until death
-  UI-mods are now refreshed before launch

### Game Improvements
-  Shield Fixes:
    -  Personal Shields now protect units also under bubble shields
    -  Personal Shields now protect units properly from splash weaponry
    -  Bubble Shields now interact with splash weaponry properly
-  Replay sync support
-  Hotbuild 'upgrade' key now takes engy-mod into account
-  Attempt to fix bomblet spread on bombers such as UEF and Cybran T1 Bombers
-  Attempt to fix Seraphim T1 Mobile AA's aim
-  Improved autobalance with random spawns in lobby
-  SMD can be paused
-  New "No Walls" Unit Restriction
-  Improved the Unit Restrictions menu descriptions, including localization
-  Improved the Attack-Move feature (Factory Attack-Move Engineer behaviour left alone)
-  Made factory queue templates more accessible, the save button was hidden when the factory wasn't paused
-  Show replay-ID in score
-  Less UI-lag
-  Some sim-speed improvements
-  Remove ACU score bump, ACU kills now score 5000

### Contributors:
- Sheeo
- a_vehicle
- Crotalus
- Pip
- IceDreamer
- thygrrr
- PattogoTehen
- RK4000
- Eximius
- Xinonny

### Special Thanks:
- Navax
- Alex1911
- Preytor
