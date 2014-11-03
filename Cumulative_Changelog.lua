-- Changelog from Steam V3603 to current V3634
-- Formatting works best when viewed as a .lua file

-----------------------------
-- Engine
-----------------------------
Video, CPU, and sound performance optimizations.
Fixed a rare game crash caused by ACU death
FreeImage warnings are now ignored. They were causing the annoying but harmless “Application has stop incorrectly, ….., check faforever.exe.log” errors when lobby was closing.
Incorrectly downloaded images are correctly replaced with the usual placeholder.
Proxy server available and used automatically to reduce connection issues
Multithreaded connection attempts
Improved late game pathfinding
Caching interface files to remove UI-lag, especially when selecting Engineers

-----------------------------
-- Lobby
-----------------------------
Support for additional sounds for custom maps.
12 Players lobby support
Infinite observer support
Added marge map preview
Added random map selection
Added share condition: Shared units disappear when you die
Added automatic formation of teams (Top/Bottom, Right/Left, Odd/Even slot)
Added more unit limits
Added more colors, including custom colours
Added auto-kick label
Reorganized sections for AI settings
'No Game ender' restriction changed to restrict T3 & T4 Artillery, Paragon, Novax and Yolona Oss
'No Nuke' Build restriction now correctly also restricts nuke carrying naval vessels
Title screen and replay files are displaying the correct patch version
Removing the reset of unit cap on each hosted game to 500
Changed the ranked unit cap to 1000
Improved random faction function
If Share is enabled, all units are gifted automatically 20 seconds after death
Added Sorian's AI configuration options
Lobby now shows each player's game count
Games display if they will affect rating or not. Mods and unit restrictions disable rating.
Fixed custom map options not loading
Chat window can now be zoomed with CTRL + Mouse Wheel
Chat window can now be scrolled faster with SHIFT + Mouse Wheel
Introduced mod and unit restriction presets
Added a new option for sharing unit cap.
Introduced Game Presets
 
-----------------------------
-- Campaign
-----------------------------
Cooperative mode enabled up to 4 players
Difficulty scales with the number of players
Campaign AI improved
Additional secondary objectives introduced
FAF's graphical improvements are active during campaign as well
FAF's unit balance is active during the campaign
Work started on systems to allow players to make their own custom campaigns and missions.
Cooperative leader board based on completion time 
 
-----------------------------
-- Bug Fixes
-----------------------------
Fixed numerous bugs with the Seraphim Restoration Field upgrades
Fixed numerous bugs related to gifting units to another player
Fixed many amphibious units being able to fire while not being able to be fired at (Shorelining)
Fixed units stunning Walls
Fixed an enormous number of targeting, aim, and collision issues
Massively improved Bomber mechanics on every level
Improved Targeting Priorities on many units
Fixed many issues with Stealth, Intel and weapon ranges being incorrectly displayed

Fixed Mass Extractor pause not affecting consumption while mass stalled
Fixed Novax centre not launching Satellite at unit cap limit
Fixed Cybran Strategic Missiles detonating too high
Fixed Seraphim Nano Regeneration upgrade granting too much Health
Fixed Seraphim Battleship nuke altitude
Fixed Cybran TML missile and sub-missile Health
Fixed Naval yards being immune to Torpedoes
Fixed T3 Torpedo Bomber Torpedo not catching targets properly
Fixed UEF ACU dealing friendly damage
Fixed Janus not slowing down with no fuel
Fixed Corsair fuel conditions
Fixed Tactical Missile Defences being immune to Torpedoes
Fixed Cybran T2 Amphibious tank not displaying amphibious status
Fixed Cybran T2 Cruiser projectile lifetime
Fixed adjacency bugs for Salvation and Eye of Rhianne
Fixed Ravager AI threat level
Fixed Soothsayer wreck not granting rebuild bonus
Fixed Megalith projectile lifetime
Fixed Seraphim Naval Factory rolloff points
Fixed Seraphim Mass Extractors granting incorrect rebuild bonuses
Fixed Seraphim blast attack stacking
Fixed Selen transport animation
Fixed Seraphim T1 Artillery not firing at units within range
Fixed Seraphim T2 Assault Bot icon
Fixed Othuum not conforming to terrain
Fixed Seraphim T3 Mobile Artillery transport drop animation
Fixed Seraphim build completion being seen through fog of war
Fixed Seraphim Engineers micro-pausing while building
Fixed Seraphim T3 Anti-Air not leading targets
Fixed repairing ACUs instantly draining your economy
Fixed Seraphim Air Factory Engineer offload speed
Fixed Energy-dependant structures turning off when Mass stalled but not Energy
Fixed Seraphim Torpedo launcher torpedoes dying if a Frigate shot collides nearby
Fixed Torpedo Launchers being unable to shoot targets directly below themselves
Fixed UEF Nano Regeneration upgrade values being overwritten on veterancy level up
Fixed UEF ACU Drone upgrade cancelling orders when a drone is killed
Fixed Seraphim T1 Mobile AA walking animation
Fixed Seraphim T2 Torpedo Launcher projectiles causing damage through islands
Fixed Transports sometimes killing units during loading
Fixed Firebeetles blowing each other up
Fixed Strategic Missile Submarine Energy cost typo
Fixed Sparky ceasing to build when Energy is depleted
Fixed warning message "Warning: Error running sim lua callback function 'AddTarget'"
Fixed Sparky being unable to fire while building or reclaiming
Fixed some errors popping up in the logs with transports
Fixed individual trees giving additional Mass
Fixed missing tree blueprint line
Fixed SAM homing missiles not reaching their target
Fixed Megalith not attacking a Naval target because it stays in range of the primary weapon
Fixed Aeon Absolver icon
Fixed Cybran SMD Build time
Fixed a bug where units weren’t damaged when their personal shield was in the recharge state
Fixed Bombers targeting a wreck or tree being permanently prevented from firing
Fixed Janus bombs impacting with a Shield spawning scorch marks on the ground below
Fixed Seraphim T2 Artillery not being able to fire at targets in range
Fixed UEF TMD Projectile Lifetime
Fixed UEF Drones not finishing buildings they started
Fixed Continental shield to avoid units inside it receiving damage
Improved Aurora movement physics to be more responsive
Improved walking animations for improved Mongoose, Titan, Brick, Aeon Sniperbot and Percival
Added Seraphim ACU Kill and Capture sounds
Added new Energy Storage icon
Added SPECIALHIGHPRI target priority status to the CZAR so that ASF's will automatically target it
Added destruction sound to Cybran t3 gunship
Added launch sound to UEF Depth Charges
Cerberus and Rhino Lasers are now visible even if you don’t see the “source”
Seraphim Battleship now plays 'Nuclear Launch' warning
Seraphim sACU no longer reclaimable
Hoplite now uses the correct number of transport clamps
UEF T2 Cruiser can now use all weapons simultaneously
Absolver now uses the correct number of transport clamps
UEF ACU now rebuilds drones automatically when they are shot down
Anti-Nuke construction can now be paused
Firebeetles can now be detonated manually
Improved Sparky's jamming signal
Reclaim time of a group of trees now match individual trees
UEF Battleship now has a reload bar for the front cannons
Reduced ASF projectile count to reduce lag in large ASF battles
Seraphim T2 artillery Pitch Range changed to 90 (From 80) to fix it not being able to fire to maximum range

-----------------------------
-- Exploit Fixes
-----------------------------
Fixed being able to get ACU upgrades for a low cost via cancelling
Fixed being able to get ACU upgrades for free
Fixed transport exploit
Fixed being able to stack multiple ACU upgrades
Fixed being able to build half of any building for free
Fixed Cybrans being able to instantly capture neutral units
Fixed T2 mass Fabricators being able to be upgraded to T3
Fixed ACU upgrade exploit
Fixed ACU assist exploit
Fixed an exploit where ACUs were able to overcharge without the necessary Energy in storage
Fixed an exploit where the Hive was able to generate mass from thin air
Fixed an exploit that allowed the player to duplicate an infinite amount of buildings for free
Fixed an exploit with the Cybran build drone
Fixed an exploit where carriers were able to transport other carrier units
Offmapped Air units are now sent back to the map after a brief time
Removed dbg_ShowAiPathSpline console command from game

-----------------------------
-- Balance Changes
-----------------------------
Starting Energy = 4000
Factories and Engineers no longer grant Energy storage
Engineers will reclaim Mass Extractor wrecks instead of getting the half-built bonus when building a lower tech Mass Extractor than the wreckage
Bubble shields now transfer damage to interlocking shields
Shields now start recharging after 3 seconds, not 1
Prevented ASFs targeting UEF Drones to stop the huge DPS from ASFs being used to obliterate base shielding and structures
Out of Fuel speed penalty reduced to 65% from 75%
Added Sparky to Air and Naval factory build menus
Teleportation now deals 100 damage to nearby units and structures in a small radius
 
-----------------------------
-- Structures
-----------------------------
Energy Storages
    - Mass cost = 250 (From 120)
    - Energy cost = 1200 (From 2400)
    - Storage = 5000 (From 2000)
    - Health = 500 (From 1200)
    - Death explosion Damage = 1000 Damage (From 500)
    - Death explosion Radius = 5 (From 3)
    - Death explosion damage no longer triggers if energy storage is self-destroyed.
 
Stationary Shields
    - Overlapping shields now pass 15% of the damage instead of 50%
   
T1 Mass Extractors
    - Health = 600 (From 800)
   
T1 Anti Air Turrets
    - Reduced mass cost by 25%
    - Reduced Energy cost by 25%
    - Reduced Build time by 25%
    - Health = 800 (From 1200)
   
T2 Artillery Installations
    - Reduced Mass cost by 25%
    - Reduced Energy cost by 25%
    - Reduced Build time by 25%
 
T2 Static Flacks
    - Reduced Mass cost by 30%
    - Reduced Energy cost by 30%
    - Reduced Health by 30%
   
T3 Naval Factories
    - Mass cost = 5150
 
T3 Air Factory cost increased to 72000
    - Energy cost = 72000
    - Mass cost = 2750 (From 3150)
   
T3 SAMs
    - Mass cost = 800 (From 400)
    - Energy cost = 8000 (From 12000)
    - HP = 7000 (From 10500)
    - Damage Radius = 1.5 (From 0)
    - Muzzle Velocity = 45 (From 30, except Seraphim, which remains at 100)
    - Increased veterancy level to 24/48/72/96/120 (From 12/24/36/48/60)
    - DamageFriendly = false
   
Adjacency Changes
    - T1 Mass Extractor gives 7.5% discount to Factories and Quantum Gateways
    - T2 Mass Extractor gives 15% discount to Factories and Quantum Gateways
    - T3 Mass Extractor gives 25% discount to Factories and 20% to Quantum Gateways
    - T2 Mass Fabricator gives 2% discout to Factories and Quantum Gateways
    - T3 Mass Fabricator gives 20% discount to Factories and 15% to Quantum Gateways
   
-- UEF
Engineering Station
    - Rover rebuild Mass cost = 250 (From 50)
    - Rover rebuild Energy cost = 2500 (From 500)
    - Rover rebuild time = 750 (From 150)
    - Station Build Rate = 15
 
T2 Flak AA
    - Damage = 125 (From 102)
    - AOE = 3.5 (From 4)
    - Muzzle Velocity = 25 (From 20)
    - Rate of Fire = 1.25 (From 1.5)
    - Range = 50 (From 44).
    - Firing Randomness = 2 (From 2.5)
 
Novax
    - Mass cost = 28000
    - Energy cost = 400000
    - Build time = 25000
    - EnergyConsumption = 1000
    - Satellite Radar radius = 65 (From 0)
    - Satellite Optical radius = 32 (From 10)
    - Satellite Damage = 100 (From 75)
    - Satellite will now be destroyed when hit by a nuke.
 
Mavor
    - Mass cost = 224775 (From 299700)
    - Increased Damage so that 2 Dukes are no longer superior to Mavor
 
T3 Stationary Artillery
    - Damage Radius = 6 (From 5)
    - Firing Randomness = 0.525 (From 0.5)
    - Mass cost = 72000 (From 90000)
   
-- Cybran
Shield Generator ED5
    - Mass cost decreased to 1800
    - Energy cost decreased to 26666
    - Build time decreased to 1400
    - Shield Health increased to 15000
   
Engineering Stations
    - Stage 1 Mass cost = 500 (From 450)
    - Stage 1 Energy cost = 2500 (From 2250)
    - Stage 2 Build Rate = 25 (From 30)
    - Stage 3 Build Rate = 35 (From 40)
 
T2 AA
    - Muzzle Velocity = 20
    - AOE = 5 (From 4)
    - Firing Randomness = 4 (From 2.5)
 
T2 Point Defense - Cerberus
    - Damage = 10 (unknown previous value)
 
T3 Stationary Artillery
    - Damage Radius = 9 (From 8)
    - Firing Randomness = 0.75
    - Mass cost = 69600 (From 87000)
 
Scathis Experimental Artillery
    - Energy cost = 1500000 (From 93000)
    - Mass cost = 85000 (From 63000)
    - Scathis is now amphibious (Non-floating)
    - Speed = 1.5 (From 1)
 
Tactical Missile Launcher
    - Split missile projectile speed = 15 (From 25)
    - Split missile projectile acceleration = 6 (From 25)
   
-- Aeon
T2 AA
    - AOE = 3
    - Muzzle Velocity = 30
    - Firing Randomness = 1.5 (From 2.5)
    - Range = 50 (From 44)

Eye of Rhianne
    - Optical radius = 25 (From 45)
 
T3 Stationary Artillery
    - Damage Radius = 5 (From 4)
    - Firing Randomness = 0.35 (From 0.375)
    - Mass cost = 73200 (From 91500)
 
Salvation Rapid-fire Artillery
    - Mass cost = 202500 (From 270000)

-- Seraphim
T2 Point Defense
    - Damage = 550 (From 660)
 
T2 AA
    - Fires 2 projectiles at once
    - AOE = 3
    - Muzzle Velocity = 25 (From 20)
    - Damage = 50 (From 53)
    - Rate of Fire = 1.5 (From 1.25)
 
T3 Anti Air
    - MuzzleVelocity increased
 
T3 Stationary Artillery
    - Damage Radius = 7 (From 6)
    - Firing Randomness = 0.675 (From 0.625)
    - Mass cost = 70800 (From 88500)
 
Yolona Oss – Experimental Missile Launcher
    - Mass cost = 187650 (From 250200)
 
-----------------------------
-- ACU
-----------------------------
Energy production = 20 (From 10)
T3 Engineering Upgrade
    - Health regeneration = 35 (From 15)
 
Overcharge
    - cost = 5000 Energy (From 3000)
    - Damage vs ACU = 400 (From 100)
    - Damage vs Buildings = 800 (From 500)
    - AOE = 2.5 (From 2)
    - Reload time = 3.3 (From 5)
   
Death Nuke
    - Inner ring damage = 2500
    - Outer ring damage = 500
   
Veterancy set to 20/40/60/90/120
   
-- UEF
Billy Advanced Tac Missile Launcher
    - Billy missile given reload time to avoid rapid-fire due to assisting
    - Energy cost = 315000 (From 630000)
    - Mass cost =  5400 (From 10800)
    - Build Time = 4000 (From 10800)
    - Missile health increased by 2.
 
Nano Upgrade: (patch 3626, previous values unknown)
    - Mass cost = 1200
    - Energy cost = 44800
    - Build Time = 1400
    - Regen = 60
 
-- Seraphim
T3 Engineering Upgrade
    - Health bonus increased
 
Restoration Field
    - Radius = 22 (From 15)
    - Health bonus = 1000
    - 2% HP Regeneration (From 0.5), but capped at 15 (From 75)
 
Rapid Restoration Field/Advanced Restoration Field
    - Radius = 30 (From 25)
    - Name changed to Advanced Restoration Field
    - Adds 1500 more HP to ACU
    - Adds 10% HP to units nearby
 
Refracting Chronoton Amplifier:
    - Damage = 400 (From 300)
    - Mass cost = 3500 (From 4500)
 
-- Aeon
Chrono Dampener
    - Mass cost = 1750 (From 2500)
    - Energy cost = 52500 (From 125000)
    - Build Time = 875 (From 1250)
    - Max Range = 35 (From 22)
 
Enhanced Sensor System:
    - Build cost Energy = 10000 (From 12500)
    - Build cost Mass = 400 (From 750)
    - Build Time = 500 (From 625)
 
-- Cybran
ACU base regeneration rate = 17 (From 15)
4 Heath Regeneration per veterancy level instead of 3.
 
-----------------------------
-- Air
-----------------------------
T1 Bombers
    - Mass cost = 80 (From 100)
    - Build time = 400 (From 500)
    - Reload time = 4 (From 2)
 
T1 Scouts
    - Energy cost = 420 (From 1600)
    - Build time = 145 (From 340)
    - Radar radius = 65
    - Sonar radius = 30
   
T2 Gunships
    - Mass cost decreased by 20%
    - Energy cost decreased by 20%
    - Health reduced by 20%
   
T3 Air Energy costs reduced by 50% with the exception of ASFs and the Solace
 
Air Superiority Fighters
    - Energy cost increased by 100%
   
T3 Strategic Bombers
    - Maximum speed = 17 (From 18)
 
-- UEF
T1 Scout
    - Improved turn speed
   
T1 Bomber – Scorcher
    - Bomb count = 4 (From 5)
    - DamageRadius = 3 (From 2.5)
    - Instant Damage = 47.5 (From 0)
    - Total Damage = 350 (From 300)
 
Janus T2 Bomber
    - Ground Weapon Range = 60 (From 45)
    - Deals half its damage instantly and the rest over time
 
T3 Transport
    - Mass cost decreased by 30%
    - Energy cost = 52500
    - Shield Energy Consumption = 400 (From 250)
    - Veterancy = 12/24/36/48/60 (From 3/6/9/12/15)
   
T3 Strategic Bomber
    - Energy cost set equal to that of the other factions
 
Broadsword T3 Gunship
    - Max Air Speed = 10 (From 8)
    - Mass cost = 1260
    - Build time = 6000
    - Energy cost = 42000 (From 52500)
    - Damage = 90 (From 100)
    - RateOfFire = 2.5 (From 3)
    - Anti-Air Damage = 8 (From 2)
 
T3 Air Superiority Fighter
    - HP = 1800 (From 2600)
    - Mass cost = 350 (From 400)
    - Wreck Value = 45% (From 90%)
    - Veterancy Levels = 12/24/36/54/72/90 (From 6/12/18/24/30)
 
-- Cybran
Jester T1 Gunship
    - Range = 20 (From 16)
    - Increased stage 1 Veterancy to 5 (From 3)
 
Corsair T2 Bomber
    - Anti-Ground Weapon Range = 40 (From 45)
 
Wailer T3 Gunship
    - Max Air Speed = 10 (From 8)
    - Mass cost = 1260
    - Build time = 6400
    - Energy cost = 42000 (From 52500)
    - Damage = 140  (From 150)
    - Rate of Fire = 1.6 (From 2)
 
Soulripper
    - Mass cost = 34000
    - Energy cost = 480000
    - Build time = 20000
    - Veterancy = 80/160/240/320/400 (was 40/80/120/160/200)
 
T3 Air Superiority Fighter
    - HP = 1725 (From 2450)
    - Mass cost = 350 (From 400)
    - Wreck value = 45% (From 90%)
    - Veterancy Levels = 12/24/36/54/72/90 (From 6/12/18/24/30)
 
-- Aeon
Mercy
    - Fuel increased from 70 to 110
    - FiringTolerance = 6 (From 2)
 
Solace
    - Energy cost increased by 100%
   
Restorer
    - Max airspeed = 10 (From 10)
    - Health = 6000 (From 7200)
    - Anti-Ground Damage = 24 (From 32)
    - Anti-Air Damage = 71 (From 65)
    - Energy cost set to ((ASF * 0.5) + 400)
    - Veterancy = 18/36/54/72/90 (From 12/24/36/48/60)
    - Build Time = 6000 (From 4800)
    - Reduced stage 1 Veterancy to 15 (From 18)
 
T3 Air Superiority Fighter
    - HP = 1750 (From 2500)
    - Mass cost = 350 (From 400)
    - Wreck Value = 45% (From 90%)
    - Veterancy Levels = 12/24/36/54/72/90 (From 6/12/18/24/30)
   
CZAR
    - Health = 58000 (From 48000)
    - Crash damage = 10000 (From 15000)
    - Added 75% Damage penalty VS ASFs to stop them being roasted thanks to the stupid Air Pathfinding AI
   
-- Seraphim
 
T2 Fighter/Bomber
    - Ground Weapon Range = 60 (From 45)
    - Lift Factor = 10 (From 7)
 
Ahwassa
    - FiringTolerance increased
    - RenderFireClock = true (From false)
 
T3 Air Superiority Fighter
    - HP = 1775 (From 2550)
    - Mass cost = 350 (From 400)
    - Wreck Value = 45% (From 90%)
    - Veterancy Levels = 12/24/36/54/72/90 (From 6/12/18/24/30)
    - Target Check Interval = 0.5 (From 0.3)
   
-----------------------------
-- Land
-----------------------------
T1 Tanks
    - Increased speed by 0.1
 
T1 Mobile AA
    - Vision Radius = 20 (From 18)
 
T2 Mobile Missile Launchers
    - Damage increased by 50%
   
T3 Mobile Missile Launchers
    - Damage increased by 100%
   
T2 Tanks
    - Speed decreased to 2.5 - 2.7
    - Health increased 20% - 25%
 
T3 Mobile Anti-Air
    - Added to the game for all factions.   
 
Land Experimentals
    - costs increased by ~20%
 
sACUs
    - Veterancy = 25/50/75/100/125 (From 20/50/90/140/200)
    
sACU Engineering Upgrades
    - Mass cost = 800 (From 1000)
    - Build Time = 4200 (From 5040)
 
   
-- UEF
T1 Scout
    - Damage = 4 (From 2)
   
T1 Artillery - Lobo
    - Health = 200 (From 205)
    - Damage = 400 (From 480)
    - RateOfFire = 0.12 (From 0.1)
   
Mongoose
    - Health = 650 (From 900)
    - Turn Speed = 90 (From 150)
    - Turret Turn Speed = 80 (From 50)
    - Firing Tolerance = 1 (From 0.1)
    - Grenade weapon Damage = 50 (From 65)
    - Grenade weapon RateOfFire = 0.15 (From 0.1)
    - Firing Randomness = 2.5 (From 2)
    - Pitch Range = 55
 
Pillar
    - Speed = 3 (From 2.7)
    - Rate of Fire = 0.8 (From 0.75)
 
T2 Mobile Shield
    - Build time = 660 (From 600)
    - Size = 17 (From 16)
 
Percival
    - Veterancy = 20/40/60/80/100 (From 9/18/27/36/45)
    - Build time = 6000 (From 4800)
    - Uses new strategic icon (x) to distinguish it from Titan (+)
 
Titan
    - Shield and Armor HP inverted
 
Fatboy
    - Veterancy = 40/80/120/160/200 (From 75/150/225/300/375)   
 
Support Armored Command Unit
    - Health = 25200 (From 32000)
    - Mass cost = 2100 (From 9600)
    - Energy cost = 38000 (From 114000)
    - Build time = 14400 (From 36000)
    - BuildPower = 40 (From 60)
    - Mass production = 1 (From 2)
    - Energy production = 20 (From 200)
    - Energy Storage = 500 (From 5000)
    - MaxBuildDistance = 10
    - Damage = 300 (From 100)
 
  SCU Drone
    - Mass cost = 380 (From 480)
    - Build Rate = 35 (From 20)
      
   Advanced Cooling
    - Build time = 2400
 
   Heavy Plasma Refractor
    - Mass cost = 800 (From 1000)
    - Energy cost = 30000 (From 45000)
    - Build time = 2400
    - Range = 35 (From 25)
   
   Engineering Drone
    - Mass cost = 480 (From 120)
    - Energy cost = 9600 (From 2400)
    - BuildRate = 20 (From 5)
    - Drones now have the T3 Engineer's build menu
   
   Radar Jammer
    - Mass cost = 600 (From 1000)
    - Energy cost = 18000 (From 31250)
    - Build time = 1600 (From 7500)
   
   RAS
    - Mass cost = 4500 (From 2500)
    - Energy cost = 60000 (From 30000)
    - Build time = 1600 (From 7500)
    - Energy Production = 1000 (From 900)
   
   Sensor System
    - Build time = 2400
    - Omni radius = 80 (From 72)
    - Optical radius = 45 (From 40)
 
Personal Shield Generator
    - Build Time = 5000 (From 6000)
 
Shield Generator Field
    - Mass cost = 3500 (From 4500)
    - Energy cost = 400000 (From 500000)
    - Build Time = 8000 (From 10000)
    - Now considered a mobile shield and will suffer from overlapping
   
-- Cybran
T1 Scout
    - Cloak energy drain = -5
   
T1 Mobile Artillery - Medusa
    - Mass cost = 36
    - Energy cost = 180
    - Build time = 180
    - Firing Randomness = 1.35 (From 1.5)
    - Stun duration for T2 units = 2 seconds (From 3)
    - Reload time = 6 seconds (From 5)
    - Damage = 230 (From 195)
   
Mantis
    - Turret yaw speed = 100
   
Hoplite
    - Health = 550 (From 650)
 
Rhino
    - Speed = 2.7 (From 2.7)
    - Health = 1900 (From 1150)
    - Damage = 25 (From 16)
    - Rate of Fire = 1.8 (From 2)
    - DPS = 90 (From 64)
    - Mass cost = 297 (From 198)
    - Energy cost = 1500 (From 990)
    - Build time = 1320 (From 880)
    - Surface Threat Level = 5 (From 3)
    - Veterancy = 8/16/24/32/40 (From 7/14/21/28/35)
 
Deceiver
    - Speed characteristics changed to match other factions' T2 Mobile Shields
   
Firebeetle
    - Damage = 3000 (From 4500)
    - Health = 300
    - Firing Tolerance increased to 100
    - Max Radius = 4.4 (From 4.5)
    - Damage Radius = 4.5 (From 3.5)
    - Turn Rate = 160 (From 120)
    - Turn Radius = 4 (From 3)
    - Firing Tolerance = 180 (From 4)
 
Brick
    - Build time = 6000 (From 4800)
    - Uses a new strategic icon (x) to distinguish it from the Loyalist (+)
 
Support Armored Command Unit
    - Health = 19000 (From 38000)
    - Mass cost = 2000 (From 9000)
    - Energy cost = 26400 (From 120000)
    - Build time = 21600 (From 36000)
    - Build Power = 40 (From 60)
    - Mass production = 1 (From 2)
    - Energy production = 20 (From 175)
    - Max Build Distance = 10
    - Damage = 300 (From 100)
    - Energy Storage = 500 (From 5000)
    - AOE Radius = 3 (From 2.5)
    - AOE duration = 4 (From 3)
    - ProjectileLifetimeUsesMultiplier = 1.3 (From 1.15)
 
Disintegrator Amplifier
    - Mass cost = 800 (From 1000)
    - Energy cost = 24000 (From 45000)
    - Range = 35 (From 25)
 
   Rapid Fabricator
    - Mass cost = 1000 (From 2100)
    - Energy cost = 60000 (From 75000)
    - Build time = 3600
    - BuildRate = 70
   
   RAS
    - Mass cost = 4500 (From 2500)
    - Energy cost = 60000 (From 30000)
    - Energy Generation = +1000 (From +900)
   
   EMP
    - Build time = 2400
    - Mass cost = 1000 (From 2250)
    - Energy cost = 60000 (From 90000)
    - AOE = 2.5 (From 3)
    - Stun duration = 3 (From 6)
    - Stun no longer stuns other sACUs
   
   Focus Convertor
    - Build time = 2400
   
   Cloak
    - Mass cost = 5000 (From 9000)
    - Energy cost = 500000 (From 1200000)
    - Built time = 10000 (From 18000)
    - Energy maintenance cost = 3500 (From 6000)
   
   Stealth
    - Mass cost = 600 (From 3000)
    - Energy cost = 18000 (From 112500)
    - Build time = 1600 (From 9000)
    - Energy maintenance cost = 100 (From 500)
 
   Nano-Repair System
    - Build time = 4800
    - Mass cost = 4500 (From 3500)
    - Energy cost = 105000 (From 135000)
   
   Nanite Missile System
    - Build time = 2400
    - Mass cost = 800 (From 1000)
    - Damage = 300 (From 200)
    - RateOfFire = 0.3 (From 0.28)
    - FiringTolerance = 50 (From 2)
    - TurretPitchRange = 60 (From 40)
   
Scathis
    - Turret pitch range = 90
    - Mass cost = 63000
    - Energy cost = 780000
    - Build time = 31500
   
Monkeylord
    - Veterancy set to 45/90/135/180/225 (From 75/150/225/300/375)
    - Mass cost = 19000 (From 21000)
    - Changed Personal Stealth to a 30 Radius Stealth Field
    - Stealth Energy Consumption = -400 (From -250)
   
Megalith
    - Veterancy set to 90/180/270/360/450 (From 100/200/300/400/500)
    - T3 mobile AA added to Megalith build options
   
-- Aeon
T1 Scout
    - Radar range increased by 5
    - Health = 20 (From 23)
 
Aurora
    - Muzzle Charge Delay = 0.1
    - Speed = 2.9 (From  3.1)
    - Firing Randomness While Moving = 0.1 (From 0)
   
T2 Mobile Shield
    - Health = 3800
    - Regeneration = 58
    - Energy cost = 105
    - Build time = 792 (From 720)
    - Energy Consumption = 75 (From 125)
    - Size = 15 (From 16)

Blaze
    - Speed = 4.3 (From 3.7)
    - Muzzle Velocity = 45 (From 40)
    - Firing tolerance = 0 (From 2)
 
Obsidian
    - Speed = 2.6 (From 2.6)
    - Health = 1250 (From 1000)
    - Shield Health = 1500 (From 1750)
    - Shield Recharge Start Time = 3 (From 1)
    - Muzzle Charge Delay = 0.1 (Patch 3626)
    - Turret Yaw Speed = 75 (From 90)
 
T3 Engineer
    - Build Rate = 20 (From 15)
   
Harbinger
    - 2600 Health transferred from Shield to Health
    - Veterancy = 15/30/45/60/75 (From 9/18/27/36/45)
    - Will now reclaim when on patrol
   
Aeon Sniper
    - Mass cost = 640 (From 800)
    - Build Time = 3600 (From 4800)
    - No longer has to deploy to fire, but is inaccurate while moving
    - Damage = 950 (From 1300)
    - New strategic icon
    - Reload = 7 seconds (From 10)
    - FiringRandomnessWhileMoving = 0.75 (From 0.8)
    - Firing Tolerance = 0 (From 2)
 
Absolver
    - Increased MaxRadiusby 15
 
Support Armored Command Unit
    - Health = 15000 (From 30000)
    - Mass cost = 1950 (From 8700)
    - Energy cost = 27100 (From 123000)
    - Build time = 21600 (From 36000)
    - BuildPower = 40 (From 60)
    - Mass production = 1 (From 3)
    - Energy production = 20 (From 300)
    - Energy Storage = 500 (From 5000)
    - MaxBuildDistance = 10
    - Sacrificial multipliers set to 0.9
    - Damage = 400 (From 100)
 
Reacton Refractor
    - Range = 40 (From 30)   
 
   Rapid Fabricator
    - Mass cost = 1000 (From 2100)
    - Energy cost = 50000 (From 75000)
    - Build time = 3600
    - BuildRate = 70
   
   RAS
    - Mass cost = 4500 (From 2500)
    - Energy cost = 60000 (From 30000)
    - Build time = 6000
    - Energy production = 1000 (From 900)
   
   Sacrifice
    - Build time = 500
   
   Shield
    - Mass cost = 1200 (From 1500)
    - Energy cost = 60000 (From 93750)
    - Build time = 3600
   
   Heavy Shield
    - Mass cost = 1500 (From 2250)
    - Energy cost = 100000 (From 135000)
    - Build time = 5000
   
   Stability Suppressant
    - Mass cost = 800 (From 1000)
    - Energy cost = 30000 (From 93750)
    - Build time = 2400
    - AOE = 3.5 (From 4)
   
   System Integrity Compensator
    - Mass cost = 1500 (From 1800)
    - Energy cost = 75000 (From 90000)
    - Build time = 4800
   
   Teleporter
    - Build time = 15000
    - Added a teleport beacon on SCU teleport
    - Added blast radius visual effect after a sACU teleport.
 
 
Galactic Colossus
    - Veterancy set to 90/180/270/360/450 (From 100/200/300/400/500)
   
-- Seraphim
Combat Scout
    - Radar range increased by 5
   
T1 Mobile Artillery
    - Minimum range = 8 (From 6)
    - TurretYawSpeed = 60 (From 70)
   
T2 Mobile Flack
    - Increased pitch range
 
T2 Hover Tank – Yenzyne
    - Speed = 4.3 (From 3.7)
    - Damage = 200 (From 175)
    - Range = 20 (From 18)
    - Firing Tolerance = 1 (From 2)
    - Turret Yaw Speed = 110 (From 90)
 
Ilshavoh
    - Speed = 2.5 (From 2.6)
    - Increased stage 1 Veterancy to 10 (From 9)
   
T3 Engineer
    - Build Rate = 20 (From 15)
 
Othuum
    - Veterancy = 15/30/45/60/75 (From 9/18/27/36/45)
    - Thau Cannon Range = 32 (From 25)
 
T3 Mobile Shield
    - Mass cost = 540 (From 640)
 
Sniperbot
    - Mass cost = 640 (From 800)
    - Build Time = 3600 (From 4800)
    - Now has a turret system for aiming while on the move
    - Damage = 580 (From 750)
    - Reload Time = 5 seconds (From 6.7)
    - FiringRandomnessWhileMoving = 0.75 (From 0.8)
    - Firing Tolerance = 0 (From 2)
    - Sniper Mode Damage = 2000 (From 2800)
    - Sniper Mode Reload Time = 14.5 seconds (From 20)
    - SniperModeRandomnessWhileMoving = 0.6 (From 0.8)
    - Strategic icon changed to a straight horizontal line.
   
Support Armored Command Unit
    - Health = 15500 (From 31000)
    - Mass cost = 2050 (From 9300)
    - Energy cost = 25800 (From 117000)
    - Build time = 14400 (From 36000)
    - BuildPower = 40 (From 60)
    - Mass production = 2 (From 5)
    - Energy production = 200 (From 500)
    - Energy Storage = 500 (From 5000)
    - MaxBuildDistance = 10
    - Damage = 400 (From 100)
   
Damage Stabilization
    - Build time = 4800
 
Nano-Repair System
 - Mass cost = 2500 (From 1750)
 - Build Time = 4800
 
Rapid Fabrication
    - Mass cost = 1000 (From 2100)
    - Energy cost = 50000 (From 75000)
    - Build Time = 3600 (From 6000)
 
Engineering Throughput
    - Build time = 6000
    - BuildRate = 70

   Enhanced Sensors
    - Build time = 2400
    - Omni radius = 60 (From 72)
    - Optical radius = 36 (From 40)
    - Mass cost = 800 (From 1000)
    - Energy cost = 36000 (From 2000)
    - Non-Overcharge weapon range increased by 10
   
   Tactical Missile Launcher
    - Build time = 3000
   
   Overcharge
    - Build time = 10000 (From 12000)
    - Rate of Fire = 0.2 (From 0.3)
    - Mass cost = 4500 (From 3500)
    - Energy cost = 300000 (From 270000)
   
   Personal Shield Generator
    - Build time = 4800
    - Energy cost = 105000 (From 140625)
   
   Personal Teleporter
    - Build time = 15000
    - Added a teleport beacon on SCU teleport
    - Added blast radius visual effect after a sACU teleport.
   
Ythotha
    - Veterancy set to 70/140/210/280/350 (From 75/150/225/300/375)
 
-----------------------------
-- Navy
-----------------------------
T1 Frigates
    - Mass cost decreased by 10%
    - Energy cost decreased by 10%
    - Anti-Air DPS = 15
    - Reduced stage 1 Veterancy to 6 XP (From 8)
   
T1 Submarines
    - Mass cost decreased by 10%
    - Energy cost decreased by 10%
   
T2 Cruisers
    - Anti-Air Damage increased by 25%
   
T3 Navy
    - Mass cost decreased by ~15%
    - Energy cost decreased by ~15%
    - Build time decreased by ~50%
   
Battleships
    - Anti-Air DPS increased to 60
    - Build time = 28800
   
Aircraft Carriers
    - BuildRate = 180
    - Can now build gunships and regular bombers.
 
T3 Strat Subs
    - Nuke Launcher Speed = 3.3 (From 2.5)
    - Nuke Launcher Range = 410 (From 1024)
    - Nuke Build Energy cost = 1350000 (From 1764000)
    - Nuke Build Mass cost = 12000 (From 16800)
    - Nuke Build Time = 324000 (From 453600)
    - Range = 410 (From 1024)
    - Tactical Missile Range = 256 (From 175)
    - Mass cost = 9000 (From 10000)
    - Nuke Outer Ring Damage = 3000 (From 500)
    - Nuke Inner Ring Damage = 22000 (From 25000)
 
-- UEF
T1 Frigate
    - Damage = 85 (From 140)
    - Rate of Fire = 0.588 (From 0.35)
 
Shield Boat
    - Mass cost = 1040 (From 1300)
    - Energy cost = 10400 (From 13000)
   
Battlecruiser
    - Mass cost = 7000 (From 6000)
    - Energy cost = 60000 (From 52000)
    - Build time = 25200 (From 12000)
   
Atlantis
    - Build time = 14400
    - Max Radius = 100 (From 60)
    - Max Speed = 2.8 (From 2.5)
    - AA AOE = 1.5 (From 0)
 
-- Cybran
T1 Frigate
    - AA Weapon Damage = 4 (From 3)
    - AA Weapon Muzzle Velocity = 60 (From 45)
    - Turn rate of projectiles increased to 25 (From 12)
    - Damage = 45 (From 40)
    - Rate of Fire = 1.36 (From 1.53)
 
T2 Destroyer
    - AA Weapon Damage = 10 (From 2)
 
T2 Cruiser
    - Anti-Land weapon Damage = 92
   
Battleship
    - Mass cost = 8000 (From 9000)
    - Build time = 25200 (From 18000)
   
Aircraft Carrier
    - Damage = 20 (From 10)
    - Turn rate of projectiles = 25 (From 12)
   
-- Aeon
T1 Attack Boat
    - DPS increased to 35
 
Torrent Missile Ship
    - AOE = 2 (From 5)
    - Damage = 800 (From 1000)
 
T2 Destroyer – Exodus
    - Muzzle Charge Delay = 0.1 (From 0.5)
    - Turret Yaw Speed = 100 (From 160)
 
Omen Battleship
    - Muzzle Charge Delay = 0.1 (From 0.5)
    - Charge = 0.1 (From 0.5)
   
Aircraft Carrier
    - Damage = 300 (From 120)
 
Strat Sub
    - Tac Missile Range = 175 (From 128)
    - DamageRadius = 3 (From 2)
 
Tempest
    - Health = 60000
    - Mass cost = 24000
    - Build time = 14400
    - Damage = 8000
    - MuzzleVelocity = 28 (From 30)
    - FiringRandomness = 0.2 (From 0.3)
    - Torpedoes changed to Depth Charges to ignore most anti-torpedo sysems
	- Depth Charge Damage = 350 (From 235)
	- Depth Charge Rate of Fire = 0.2 (From 0.25)
   
-- Seraphim
T2 Cruiser
    - MuzzleVelocity increased
 
T2 Destroyer
    - Improved torpedo defenses
    - Front Gun DPS = 125 (From 105)
    - Rear Gun DPS = 65 (From 95)
    - Turret Yaw Range = 120 (From 140)
    - Turret Yaw Speed = 60 (From 90)
    - Attack Angle = 70 (From 60)
   
T3 Submarine Hunter
    - Speed = 5 (From 6)
    - Build time = 14400
    - Range = 65 (From 70)
    - AA DPS = 200 (From 240)
    - Health = 4000 (From 4500)
   
Aircraft Carrier
    - Damage = 60 (From 25)
 
Battleship
    - Nuke cost Energy = 1764000 (From 1920000)
    - Nuke cost Mass = 16800 (From 19200)
    - Build Time = 453600 (From 518400)
    - Nuke Damage = 25000 (From 70000)
 
-----------------------------
-- New Features
-----------------------------
Integrated Sorian AI
New Veterancy System
    - T1 = 1 xp
    - T2 - 3 xp
    - T3 = 6 xp
    - Experimental/ACU/sACU = 50 xp
    - Interface shows current xp and the xp necessary to gain the next level
Introduced new shaders, active only on high graphics settings
Introduced an announcement bar to notify you that someone close to your skill level is seeking a ranked ladder game

Galactic War game mode added
    - New players start with 0 credits
    - Attacks are free at rank 0
    - Attacks cost more as you rank up (rank * 100)
    - Credits can be used to buy reinforcements, which are delivered in-game on command
    - Reinforcements can be gifted to someone of your faction
    - Attacks can be transferred from one player to another for free
    - Attacks work on a charge basis, with each charge increasing faction influence by 5%, which takes 10 minutes
    - A successful defense will stop the charge
    - Death is permanent. Be careful out there, Commander
 
New factory models (Thanks to Armageddon and Bokker)
New shaders for terrain (Thanks to KarottenRambo)
New particle effects and textures (Thanks to Luxor144 and Resin Smoker)
New strategic icons to differentiate some units (Thanks to Errorblankfield)
Better handling of debris during explosions
Aeon Battleship and Destroyer visual effects improved.
Attack orders can now be split using SHIFT + G (Thanks to BlackOps team and johnie102)

Implemented Hotbuild and GazUI
    - Press F1 to rebind keys
    - New Options Menu settings available
    - Implemented sACU Manager to allow automatic, sequential sACU upgrades
    - Note: Hotbuild and GazUI mods must be removed to avoid conflicts with the implemented versions
    
Units which die over water now leave a wreck which sinks to the bottom and can be reclaimed at 50% the normal value
Introduced brand new Unit Descriptions to aid player knowledge
Added brand new Teleport visual and audio effects

Implemented Support Factory Model (EngieMod)
    - Factories can be upgraded to Support Factories if there is an appropriate Factory HQ in play under your control
    - Support Factories are identical to HQs, but the upgrade is significantly cheaper
    - If you lose your all your HQs, you cannot build that tech level of units until it is replaced
    - T2 and T3 Engineer and Factory BuildRates improved to be mass efficient relative to stacking T1 Engineers, reducing T1 Engineer spam

-----------------------------
-- AI
-----------------------------
AI will now build firebases
AI will now build Percivals, Rhinos, and the Megalith
AI can now consistently transport all valid units
AI unit groups that are assigned to guard bases will no longer attack all over the map
AI now fires Yolona Oss more than once
AI now sends out more than one land scout
Cheating AIs now actually use their Experimental units
Fixed Sorian AI not building mod units