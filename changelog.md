Patch 3652 (pending)
============================

**Lobby**
- Name filter when selecting map
- Prevent host from changing player teams while he is ready
- Game quality in lobby now visible again
- Reduced autobalance random variation to get team setups with better overall quality
- Default to score off
- Stopped the map filter preventing the map selected in prefs from prior games from showing
- Tiny fix to flag layout

**UI**
- Introduced Russian translations of many FAF additions to the game (Exotic_Retard)
- Translate some FAF additions to Italian
- New keybindable action: 'soft_stop'
- Soft-stop will cancel all orders of a factory except their current one, if you soft-stop a factory with only one order it will get cleared
- Hold down Alt when giving a factory order to soft stop factory before issuing next order
- Multi-upgrade: Added UI support to upgrade structures several levels at once (i.e: cybran shields, hives, mexes, factories etc)
- Auto-overcharge: It's now possible to let overcharge fire automatically whenever you have the required power
- Order repair on a wreck to rebuild it if possible by some of the selected engineers. Those not able to rebuild the wreck will assist after the build starts.
- Units explicity repairing (not assisting) a structure that dies will automatically try to rebuild it
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
- In Units Manager, added option to restrict units using preset restrictions and/or custom restrictions
- In Units Manager, added grouping of units based on faction, type, purpose
- In Units Manager, added detailed tooltips with stats for weapons, defense, and eco for all units 
- In Units Manager, improved description of preset restrictions
- In Mods Manager, added filters for UI/Game/Disabled mods 
- In Mods Manager, improved sorting mods by their activation status and names  

**Gameplay**
- Teamkill is now detected and a player can make an explicit report
- Air units are now able to fire at water-landed transports
- Hoplite now calculate their aim correctly when firing at a fleeing target
- Slight increase of unit size(not hitbox) of T3 sniper bots, Othuum and Rhino to alleviate their weapon's ground-hitting ability
- Seraphim Experimental Nuke now deals damage to itself
- Cybran drones no longer leave wreckage when killed
- Defense structures now start rotated at their nearest enemy when built, if no enemies found they default at middle of map 
- Remove friendly fire on Atlantis AA
- Location of enemy civilian structures are now revealed at start of the game (lobby option)
- Navy units now should respect their max-range better when having move-attack order
- Set GuardReturnRadius to 3 as default, will make guarding / patrolling / move-attacking units less prone to move off their designated mission while hunting something
- Units moving on seabottom now leave treadmarks - they disappear faster though
- Re-enabled death animation on non-naval units
- Seraphim GW now uses all its 3 exits
- Spread attack: Targets are now spread more uniformly across all units during the initial attack orders, further ones are random.
- Diplomacy now allowed in Coop mode
- Allow Fatboy, Atlantis, Tempest and Czar to fire while building units
- Beam weapons now kill missiles they impact instead of wasting DPS for several ticks
- Aeon ACU upgrade "Chrono Dampener" won't stun allied units any more. Additionally, it will fire at predetermined ticks so the effects of multiple acu's do not stack.
- Increased TMD range by 1 and ROF by 0.2s to prevent a single TML killing a single TMD by using ground-fire to impact before the second TMD shot fires.
- Fixed Cybran T3 MAA doing friendly damage on 1 of its 2 AA weapons
- Fixed Cybran T3 MAA hitbox/bones making lots of units miss
- Fixed Sera T1 sub not being hit by torpedoes 80% of the time while surfaced.
- Enemy civilians are now colored in a unique red color
- Fix bomb drop code and enable it for Janus, and UEF/Cybran T1 Bombers to attempt improvement to bomb drop characteristics

**Bugs**
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
- Fixed Underwater Vision not being initialised on unit completion
- Fixed Engineers not properly reclaiming the target of an assisted, then stopped, Engineer
- Fixed UEF Drones being untargetable by Interceptors
- Fixed UEF Drone collision detection, making it much easier for ground-based AA to hit them
- Fixed UEF AI unit templates in coop mode
- Fixed an exploit with being able to upgrade restricted enhancements
- Fixed a rare bug with builders getting near zero HP after a naval building gets destroyed the same tick as it finishes.
- Fixed shields sometimes not turning off due to lack of Energy
- Fixed buffs from enhancements being applied too often after unit transfer
- Fixed subermsible naval units leaving full reclaim mass
- Nuclear explosions now behave predictably, always bypassing/ignoring bubble shielding

**Performance**
- Optimization of score accumulation
- Tweaks to hive build effects to reduce performance impact
- Cleanup of enhancement sync code to make it faster and more secure
- Entities now re-use repeated sound FX instead of creating new ones every time
- Reduce load on render thread
- No net_lag in single-player to increase UI response speed

**Other**
- Added game-side support for future achievement system
- Tech-level filter in debug window now works as intended
- Log-spam from various known events heavily reduced
- Lots of work adapting and improving AI behavior for coop gameplay (speed2)
- Scale aeon build effects according to build progress 
- Show wreckage debris in reclaim beam

**Contributors**
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


Patch 3650 (August 19, 2015)
===========================

HTML-version of this balance oriented changelog available at: http://content.faforever.com/patchnotes/

**Seraphim and UEF ACU TML**

- Missle hitpoints: 3 hp → 2 hp
- Flying height: now similar to normal TML
- Mass cost: 1000 → 1500
- Minimal range: 5 → 15
- Muzzle velocity to 7
- Only for Seraphim:
- Area of effect: 3 → 2
- The flying arc at close range will now be similar to the UEF ACU TML

**Cybran TML**

- TMDs (except Aeon) will now survive a single cybran tactical missile if they have full HP

**TML friendly Fire**

- TML missiles no longer deal friendly fire

**sACU changes**

- Hitbox: lasers can now hit SCUs more reliably
- SCUs now leave a normal wreckage with 81% of their mass value when destroyed
- A RAS preset for UEF, Cybran and Aeon is now available for production from the Quantum Gateways.
 
 **Aeon SCU**

- Reacton Cannon (Gun upgrade) energy cost: 36000 → 46200, build time: 5040 → 6048
- Heavy Personal Shield hitpoints: 35000 → 40000, mass cost = 1500 → 1800

 **UEF SCU**

- Personal Shield Generator HP: 32000 → 26000 HP
- Heavy Plasma Cannon (Gun Upgrade) rate of fire x2.5 → x1.82 (DPS 750 → 546), AOE: 2.5 → 2
- Radar Jammer mass cost: 600 → 300, energy cost = 18000 → 8000
- Bubble shield energy cost: 400000 → 360800

 **Cybran SCU**

- Nano-Repair System regeneration rate: 400 hp/s → 375 hp/s, mass cost: 2000 → 2200
- Focus Convertor (Gun upgrade) adds damage: 250 → 200
- Nanite Missile System (SAM Upgrade) DPS: 272 → 400
- EMP duration for Tech1/Tech2/Tech3/SCU: 4/4/4/0 → 4/3.5/3/0.3
- Stealth upgrade mass cost: 600 → 400, energy cost: 18000 → 7400
- Cloak upgrade energy cost: 500000 → 382200

 **Seraphim SCU**

- Overcharge: now tracks (like ACU overcharge)
- Overcharge reload time: 5 seconds → 7.5 seconds
- Overcharge damage: 12000 → 10000
- Overcharge DPS: 2400 → 1333
- Shield mass cost: 1500 → 1200, shield hitpoints: 25000 → 20000

**Seraphim (Yenzyne)**

- Build time: 880 → 1050
- Speed on water: 4.3 → 3
 
 **Aeon (Blaze)**

- Build time: 880 → 1050
- Speed on water: 4.3 → 3

 **UEF (Riptide)**

- Build time: 1320 → 1600
- Speed on water: 3.7 → 3
- Mass cost: 362 → 360
- Energy cost: 1980 → 2000

 **Hover flak (Seraphim and Aeon)**

- Speed: 3.6 → 3

**Seraphim Tech 2 bot and Tech 3 Tank Changes**

 - We are carefully toning down both areas while keeping the idea behind it intact. Ilshavoh becomes weaker, and Othuum becomes stronger.
 - 
 **Ilshavoh**

- Turret turn rate: 180°/s → 70°/s

 **Othuum**

- Speed: 2.5 → 2.6

 **Harbinger**

- Will now take longer to make, making it harder to spam them so fast and allowing opponents slightly more time to bring counters into play.
- Veterancy: 15/30/45/60/75 → 18/36/54/72/90
- Build time: 3600 → 4500
- Can no longer fire while reclaiming

 **Sniper bots (Seraphim and Aeon)**

- It is annoying when sniper bots lose all their damage while moving and trying to shoot. They will hit more often now, even - though using them stationary will still lead to the best results.
- Firing randomness when moving: 0.8 → 0.5

 **UEF T3MAA**

- Other faction’s T3 MAA were hitting much better than the UEF one. This change is improving its accuracy to similar levels.
- Slight tracking added with small turn rate (20)
- Muzzle velocity: 100 → 110

**Navy**

 **Summit**

- Is now more expensive, giving other factions more time to beat them before they are able to gather a critical mass.
- Mass cost: 9000 → 10500
- Energy cost: 54000 → 62000
- Build time: 28800 → 33000
- Area of effect: 3 → 2

 **Aeon Frigates**

 - Will now be more effective vs hover, but not vs ships. 

- Hit points: 1800 → 1850
- Damage per shot: 140 → 50
- Reload time: 5 seconds → 1.7 seconds (DPS: 56 → 58)
- MuzzleChargeDelay: 0.5 → 0
- Anti-torpedo weapon reload time: 10 → 12.5

**Air**

 **Strategic bombers (all factions)**

Increasing the energy cost of strat bombers to avoid the ability to rush a strat them so easily.
- Energy cost: 105000 → 144000
- Build time: 8400 → 9600

 **Corsair**

- Reducing the speed of their projectiles to make them as easy (or hard) to dodge as they were before the range decrease.
- muzzle velocity: 35 → 30

**Torpedo bombers**

- We made several adjustments to allow torpedo bombers to actually deliever their torpedoes more often.
- Reload time for all torpedo bombers: 12.5 → 10

 **Uosioz (Seraphim Torpedo Bomber)**

- Torpedos get now dropped in front of the bomber (like all other bombers)
- Range: 42 → 35
- Amount of volleys: 2 → 3
- Now ignores torpedo defence (like all other torpedo bombers)
- Multiple adjustments to torpedos make them less likely to crash on the ground in shallow water

 **Skimmer (Aeon T2 Torpedo Bomber)**

- Depth charges get now dropped in front of the bomber (like all other bombers)
- Range: 42 → 35
- Amount of volleys: 2 → 3
- Multiple adjustments to depth charges make them less likely to crash on the ground in shallow water

 **Solace (Aeon T3 Torpedo Bomber)**

- Range: 42 → 32
- Projectile turn rate increased

 **Awhassa**


- Added armour to ASF to guard them from the bomb, reducing their damage taken to 10%
- Veterancy: 50/100/150/200/250 → 100/200/300/400/500
- Reload time: 10 → 12

**Other**

 **Quantum Gateway**
 
- We are reducing the adjacency bonus for massfabs next to Quantum Gates to a more normal level.
- Tech 2 mass fabricator: 2.5% → 0.75%
- Tech 3 mass fabricator: 15% → 2.25%
- Tech 3 power generator: 18.75% → 5%
- Preset names improved

 **T3 Land HQ**


Build time: 9400 → 11000

**Sonars**

 **T2 sonar**

- Mass cost: 120 → 150 (sera stays 180)
- Energy drain: 100 → 150

 **UEF/Aeon T3 sonar**

- Mass cost: 400 → 1000
- Energy drain: 100 → 250

 **Cybran T3 sonar**

- Mass cost: 480 → 1200
- Energy drain: 250 → 400

 **Energy/Mass overflow**

The bug, that caused resources to disappear when they got shared to several teammates and one of them had full storage does not exist and is a FAF urban legend. If a teammate has full storage, the resources get properly shared to a different teammate instead. It is not needed to use any mods to prevent resources from getting lost or to inform others about this "bug".
- No change required


Patch 3648 (August 13, 2015)
===========================

Bugs
----

- ASF no longer have issues gaining targets when just given move orders
- Satellite works with 'no-air' restriction again

Enhancements
------------

- Remove 'no sc1 units' restriction that would make the game unplayable

Patch 3646 (August 11, 2015)
===========================

Bugs
----

- UEF buildbots no longer explode after being built with 'no-air' restriction enabled
- Commanders no longer explode immediately with the 'no-land' restriction enabled
- Upgraded hives are no longer invincible
- Beam weapons will no longer keep firing their lasers after designated targets have died
- Nukes will always penerate personal shields again
- Paused units which start work on a building will no longer consume resources

Enhancements
------------

- Units with sonar no longer have it enabled while on land
- Added 'no T3 air' restriction


Patch 3644.1 (August 5, 2015)
==========================

Enhancements
------------

- "More unit info" mod integrated and improved
- Incompatible mods and old maps are now blacklisted


Patch 3644 (July 27, 2015)
==========================

Bugs
----

- AI now works again
- Unpausing engineers works again
- Units currently being built no longer hang around when transferring or reclaiming the factory the were being built in.
- Seraphim units render correctly on medium fidelity

Enhancements
------------

- Jammer field from crystal now stops working when the crystal is reclaimed
- Jammer crystal reclaim increased to (5000e, 50bt)

Patch 3643 (July 24, 2015)
==========================

Bugs
----

- Fixed issue with half built units from naval factories
- Fixed issue with sometimes being unable to quit the game
- Cybran and UEF buildbots / drones no longer explode with the no air restriction
- Fixed issue with being unable to reclaim mexes that are being upgraded
- Seraphim ACU minimum range for normal gun and OC adjusted to be the same as other ACU's
- Seraphim destroyer surfaces itself after building again
- Seraphim T2 transport no longer allows active shields on board
- Seraphim ACU restoration field now works for allied units
- Aeon T3 battleship TMD is no longer completely unable to stop TML's

Enhancements
------------

- Added ability to see unit data (xp/regen rate) as observer
- Firebeetles can no longer detonate in the air
- Upgrade hotkey now works for T2 naval and air support factories

Contributors
------------

- CodingSquirrel
- Crotalus
- Gorton
- Sheeo
- ckitching
- ggwpez


=======

Patch 3642 (July 13, 2015)
==========================

Bugs
----

- Obsidians and titans die to overcharge again

Patch 3641 (July 12, 2015)
==========================

Exploits
--------

- Instant crash exploit partially fixed
- No longer possible to give away units in progress of being captured
- No longer possible to bypass unit restrictions with sneaky UI mods
- Fixed being able to remotely destroy wreckage anywhere on the battlefield


Bugs
----

Hitboxes
- Seraphim sniper bot is able to hit Cybran MML again
- Fixed SCUs not being hit properly by laser weapons
- Fixed units aiming too high on the UEF and Aeon SCUs
- Torpedo/sonar platforms no longer confuse surface weaponry

Visual
- Fixed shield structure glows and rotations not playing
- Fixed bug with capture progress bar not being synced if using multiple engineers
- Optimised the range-rings shader to reduce the way FPS falls off a cliff
- Fixed bug with instantly disappearing wrecks due to garbage collection
- Fixed wrong regen values being reported on UI-side
- Disable build effect beams on sinking engineers
- Reload bar refill rate now scales with RateOfFire buffs
- Legacy checkbox UI code working again
- Fixed Engineers spawning the wrong tarmacs when building Seraphim buildings
- Engineering stations no longer exhibit a model bug when rebuilt by an assisting SCU
- Fuel indicator no longer falls off the unit detail window
- Seraphim ACU and SCU no longer show the tac missile counter if they don't have the upgrade

Physics
- Projectiles no longer collide with sinking units
- UEF T3 Transport now leaves wreck in water
- Cybran ACU can now fire the laser when standing in water
- Fixed Seraphim T1 Mobile Artillery not firing at fast targets properly
- Yolona Oss now deals damage to itself
- Flares and depth charges no longer draw in friendly projectiles
- Fix shots sometimes going right through Walled PD
- Increased Aeon T3 Artillery MuzzleVelocity to allow it to fire at its maximum range

Other
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

Enhancements
------------

Visual
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
- Added a button to unbind key mappings
- Drop shadow for chat messages
- Chat Option: Add background to chat messages when chat window is closed
- Chat Option: Allow chat to timeout normally in the feed after closing window
- Reclaim window merged with main resources UI

Other
- Engineering Station units now pause on transfer from one player to another
- Cybran build bots now can assist next build project without respawning
- The least valuable units are destroyed at unit transfer if unitcap is hit
- Absolver shield disrupter now hovers higher, so it's less likely to hit the
  floor with the very low mounted gun
- UEF SCU Drone can now capture, the same as the ACU ones
- Tiny changes to make Fatboy/Megalith/Spiderbot weapons symmetrical in
  behaviour where they should be
- Added templates for all support factories. AI in coop missions is now able to
  rebuild support factories
- Assist now prioritize building over repair
- Share Until Death is now default
- Mod size reduced by about 30 MB

Contributors
------------

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

Special Thanks To
- Softly
- Exotic Retard
- Nyx

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
