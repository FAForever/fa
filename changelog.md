Changelog for patch 3641
------------------------

*Exploits*
- Instant crash exploit partially fixed

*Bug fixes*
- Seraphim sniperbot is able to hit Cybran MML again
- T3 Torpedo Bomber can use Attack-Move properly again
- Shield disruptor now works on personal shields
- Fixed wrong consumption when repairing ACU after an upgrade finished
- Support factories no longer lose progress if they are damaged during upgrade
- Units with weapon range upgrades now stop at maximum range when using attack-move 
- Aeon SCUs with nano + vet now get correct regen rate 
- Disable build effect beams on sinking engineers
- Projectiles no longer collide with sinking units
- Fixed share until death bug with dual-given units
- Fixed bug with insta-disappearing wrecks due to garbage collect
- Fixed Seraphim T1 Mobile Artillery not firing at fast targets properly

*Enhancements*
- Scathis now has Amphibious build icon
- Attack and Nuke reticles now scale with impact radius
- TMLs now show the splash damage radius in targeting mode
- Engineering Station units now pause on transfer from one player to another
- Cybran Engineers now display a build beam to clearly show what they're tasked to
- Cybran factories now have red build beams
- Number of Cybran build bots scale with buildpower of the engineer
- Cybran build bots now can assist next build project without respawning
- Reclaim/second now shown
- 34 new taunts
- The least valueable units are destroyed at unit transfer if unitcap is hit
- "Commander under attack" now works on shielded ACUs
- Remove owner-check on text pings so anyone can delete them
- Disable assist command on upgrading factories to prevent accidental cancelling
- Ping values under "Connectivity" (F11) now update during game stop/stall
- Added Yolona Oss to Mavor/Salvation/Scathis build restriction and renamed it Super-Game-Enders
- New option: Show reclaim value of wreckage on map
- ASF effects tweaked for performance (less effects on low fidelty)

*Lobby*
- Huge texture, layout, aesthetics and speed improvements all over the lobby
- Map previews now display unit wreck reclaim as well as Mass points and Hydrocarbons
- Unit manager can be seen again by non-host players
- Preset system now saves active mods
- Observers can now open the chat menu by pushing ENTER
- CPU Benchmark results now cached, so running it once with nothing in the background is a good idea.
  Dramatically reduces lobby lag
- Maps are now sorted alphabetically ignoring case

Changelog for patch 3640
------------------------

- Adress an issue that causes the game to crash with core dumps in long games

Changelog for patch 3639
------------------------

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

Changelog for patch 3638
------------------------

- Added christmas presents for reclaim

Big thanks to ozonex for this contribution!

Changelog for hotfix-patch 3637
-------------------------------

*Bug fixes*
- Selection Range Overlay works for multiple units again
- Score no longer flickers when watching replays
- Targeting issues, especially related to the seraphim ACU have been adressed
- Compatibility with certain mods restored
- Lobby 2.5b included (Changelog shown in game)

Notes:
- On some maps air wrecks may still appear in midair
- It's still likely that there are incompatibilities with mods. Please let us know your exact setup of the game when reporting issues


Changelog for patch 3636
------------------------

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
