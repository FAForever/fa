Patch 3641 (Unreleased)
=======================

Exploits
--------

- Instant crash exploit partially fixed
- No longer possible to give away units in progress of being captured


Bugs
----

Hitboxes
- Seraphim sniperbot is able to hit Cybran MML again
- Fixed SCUs not being hit properly by laser weapons
- Fixed units aiming too high on the UEF and Aeon SCUs

Visual
- Fixed shield structure glows and rotations not playing
- Fixed bug with capture progress bar not being synced if using multiple engineers
- Optimised the range-rings shader to reduce the way FPS falls off a cliff
- Fixed bug with insta-disappearing wrecks due to garbage collect
- Fixed wrong regen values being reported on UI-side
- Disable build effect beams on sinking engineers

Physics
- Projectiles no longer collide with sinking units
- UEF T3 Transport now leaves wreck in water
- Cybran ACU can now fire the laser when standing in water
- Fixed Seraphim T1 Mobile Artillery not firing at fast targets properly
- Yolonna Oss now deals damage to itself
- Flares and depth-chages no longer draw in friendly projectiles
- Fix shots sometimes going right through Walled PD

Other
- T3 Torpedo Bomber can use Attack-Move properly again
- Units with weapon range upgrades now stop at maximum range when using attack-move
- Shield disruptor now works on personal shields
- Fixed wrong consumption when repairing ACU after an upgrade finished
- Support factories no longer lose progress if they are damaged during upgrade
- Aeon SCUs with nano + vet now get correct regen rate
- Fixed share until death bug with dual-given units
- Minimap now remembers whether to show resource icons or not
- Current commandmode no longer reset if an engineer dies in the current selection

Enhancements
------------

Visual
- Scathis now has Amphibious build icon
- Attack and Nuke reticles now scale with impact radius
- TMLs now show the splash damage radius in targeting mode
- Cybran Engineers now display a build beam to clearly show what they're tasked to
- Cybran factories now have red build beams
- Number of Cybran build bots scale with buildpower of the engineer
- Ping values under "Connectivity" (F11) now update during game stop/stall
- Added Yolona Oss to Mavor/Salvation/Scathis build restriction and renamed it
  Super-Game-Enders
- ASF effects tweaked for performance (less effects on low fidelty)
- Cybran engineering build bots now crash when their owner dies rather than just vanishing


UI
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

Other
- Engineering Station units now pause on transfer from one player to another
- Cybran build bots now can assist next build project without respawning
- The least valuable units are destroyed at unit transfer if unitcap is hit
- Absolver shield disrupter now hovers higher, so it's less likely to hit the
  floor with the very low mounted gun
- UEF SCU Drone can now capture, the same as the ACU ones
- Tiny changes to make Fatboy/Megalith/Spiderbot weapons symmetrical in
  behaviour where they should be

Contributors
------------

- Crotalus
- Eximius
- IceDreamer
- ResinSmoker
- Sheeo
- Speed2
- anihilnine
- ckitching
- shalkya

Special Thanks To
- Softly
- Exotic Retard

Patch 3640 (Jan 6, 2015)
==========

- Adress an issue that causes the game to crash with core dumps in long games


Patch 3639 (Jan 5, 2015)
========================

*General changes*
- Christmas presents for reclaim have been removed
- Score viewing:
    - Score button no longer exits the game forcefully
    - Viewing of score screen when scores were set to off is re-enabled, but the
      statistics are not particularly useful

*Exploit fixes*
- Fixed a regression of the free ACU upgrade exploit

*Game improvements*
- Cartographic map previews are now being generated even for maps that do not contain colour information for them.

*Bug fixes*
- Fixed air wrecks floating mid air on certain maps
- Fixed air wrecks sinking to bottom of water, then jumping back up to surface
- Fixed continental not dying to nukes
- Improved GuardScanRadius:
  - Scouts no longer engage at long range, value was set to 10
  - Harbinger will automatically engage at range again
  - Range tuned down a bit so units will not run off too much
- Fixed Seraphim T3MAA targetbones (Units will no longer aim above it)
- More mod compatibility
- Give Eye of Rihanne restriction a new description
- Fixed hoplite not firing at landed air units
- Added BOMBER category to Ahwassa, Notha
- Added FACTORY category to Megalith, allows queuing of units while being built
- Improve new unit share code (Units dying after being transferred multiple times)
- Fixed sinking wrecks blocking projectiles where the unit used to be

*Lobby changes (Version 2.6.0, also shown in game)*
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


Thanks to pip, briang and Alex1911 for translations

Contributors:

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


Big thanks to ozonex for this contribution!

Patch 3637 (Dec 12, 2014)
=========================

*Bug fixes*
- Selection Range Overlay works for multiple units again
- Score no longer flickers when watching replays
- Targeting issues, especially related to the seraphim ACU have been adressed
- Compatibility with certain mods restored
- Lobby 2.5b included (Changelog shown in game)

Notes:
- On some maps air wrecks may still appear in midair
- It's still likely that there are incompatibilities with mods. Please let us know your exact setup of the game when reporting issues


Patch 3636 (Dec 12, 2014)
=========================

*Exploit Fixes*
-  Fixed infinite economy exploit
-  Fixed free ACU upgrade exploit
-  Security exploits with simcallbacks
-  Fixed UEF Drone upgrade exploits

*Bug Fixes*
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

*Game Improvements*
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
-  Improved the Unit Restrictions menu descriptions, including localisation
-  Improved the Attack-Move feature (Factory Attack-Move Engineer behaviour left alone)
-  Made factory queue templates more accessible, the save button was hidden when the factory wasn't paused
-  Show replay-ID in score
-  Less UI-lag
-  Some sim-speed improvements
-  Remove ACU score bump, ACU kills now score 5000

Contributors:
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

Special Thanks:
 - Navax
 - Alex1911
 - Preytor
