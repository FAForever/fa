FAF LUA Code
------------
master|develop
 ------------ | -------------
[![Build Status](https://travis-ci.org/FAForever/fa.svg?branch=master)](https://travis-ci.org/FAForever/fa) | [![Build Status](https://travis-ci.org/FAForever/fa.svg?branch=develop)](https://travis-ci.org/FAForever/fa)

Current patch is: 3634

Changelog for patch 3636
------------------------
This is the changelog to be posted on the forums for patch 3636. It is subject 
to change, but nearing release status. Please search the forum for a discussion
about the relevant change, or make a thread if it isn't there already.


*Exploit Fixes*
- [X] Fixed infinite economy exploit
- [X] Fixed free ACU upgrade exploit
- [X] Security exploits with simcallbacks
- [X] Fixed UEF Drone upgrade exploits

*Bug Fixes*
- [X] Continental Fixes:
    - [X] Fixed units firing from transport
    - [X] Fixed Continental not dying to Nukes with the shield up
    - [X] Improved fix for units being transported taking no damage while the shield is up
- [X] Fixed UEF T3 Mobile AA being able to fire from Continental, and reduced projectile number
- [X] T3 Seraphim Mobile Artillery given proper 'ARTILLERY' designation
- [X] Fix adjacency buffs working when unit is turned off
- [X] Fixed Cybran ACU with Laser upgrade being unable to ever fire the weapon after being transported, and improve targeting further
- [X] Fixed Cybran ACU with Torpedo upgrade firing at the floor after being transported
- [X] Fixed Cybran ACU Torpedo upgrade firing while the ACU's feet are only just underwater
- [X] Fixed Cybran ACU being unable to be shot by Torpedoes with only its feet in the water
- [X] Fixed Seraphim ACU dying when dropped from Transport after being picked up while firing
- [X] Fixed Seraphim ACU shot being visible through FoW
- [X] Fixed invalid preview range of SMDs
- [X] Fixed Aeon T1 Bomber targeting subsurface units
- [X] All Factories of a given tech level now roll out Engineers at an even pace with each other
- [X] Given units now get correct experience points 
- [X] Given units are returned to their original owner in share until death 
- [X] UI-mods are now refreshed before launch


*Game Improvements*
- [X] Shield Fixes:
    - [X] Personal Shields now protect units also under bubble shields
    - [X] Personal Shields now protect units properly from splash weaponry
    - [X] Bubble Shields now interact with splash weaponry properly
- [X] Hitbox Fixes: Adjusted collision boxes and target bones on dozens of units to allow weapons to target and impact them properly.
    - [X] Dynamically changing hitbox for Salem
    - [X] ACUs and sACUs now hit properly by Lasers
    - [X] Hovertanks now hit properly by Lasers
    - [X] Torpedo launchers and Sonar now targeted properly by all surface fire naval weapons
    - [X] Colossus, Spiderbot, Ythotha and Megalith fixed
    - [X] Brick, Percival, Harbinger, Titan, Loyalist and Othuum fixed
    - [X] LABs, Mantis, Aurora, Striker, Pillar, Hoplite, Mongoose, Firebeetle, Seraphim T3 Mobile Artillery, Cybran T2 Mobile Flack, HARMS, Zthuee all fixed
- [X] Replay sync support
- [X] Hotbuild 'upgrade' key now takes engy-mod into account
- [X] Spread attack now works for move, build and overcharge
- [X] Ability to reclaim ground
- [X] Attempt to fix bomblet spread on bombers such as UEF and Cybran T1 Bombers
- [X] Attempt to fix Seraphim T1 Mobile AA's aim
- [X] Improved autobalance with random spawns in lobby
- [X] SMD can be paused
- [X] New "No Walls" Unit Restriction
- [X] Improved the Unit Restrictions menu descriptions, including localisation
- [X] Made factory queue templates more accessible, the save button was hidden when the factory wasn't paused
- [X] Show replay-ID in score 
- [X] Less UI-lag
- [X] Some sim-speed improvements 

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
 
Changes under consideration for future patches
----------------------------------------------

- Tempest being able to build hovering land units
- Mongoose muzzle velocity buff 


Special Thanks:
 - Navax
 - Alex1911
 - Preytor
 
Contributing
------------

To contribute, please fork this repository and make pull requests to the
develop branch.

Code convention
---------------

Please follow the [Lua Style Guide](http://lua-users.org/wiki/LuaStyleGuide) as
much as possible.

For file encoding, use UTF-8 and unix-style file endings in the repo (Set
core.autocrlf).
