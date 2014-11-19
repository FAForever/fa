FAF LUA Code
------------
master|develop
 ------------ | -------------
[![Build Status](https://travis-ci.org/FAForever/fa.svg?branch=master)](https://travis-ci.org/FAForever/fa) | [![Build Status](https://travis-ci.org/FAForever/fa.svg?branch=develop)](https://travis-ci.org/FAForever/fa)

Current patch is: 3634


**Tentative** changelog for patch 3636
--------------------------------------

This is the **tentative** changelog to be posted on the forums for patch
3636.

It is temporary and subject to change. Anything on this list is fully open for
debate.  Please search the forum for a discussion about the relevant change, or
make a thread if it isn't there already.


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

*Game Improvements*
- [X] Shield Fixes:
    - [X] Personal Shields now protect units also under bubble shields
    - [X] Personal Shields now protect units properly from splash weaponry
    - [X] Bubble Shields now interact with splash weaponry properly
- [X] Replay sync support
- [X] Hotbuild 'upgrade' key now takes engy-mod into account
- [X] Attempt to fix bomblet spread on bombers such as UEF and Cybran T1 Bombers
- [X] Attempt to fix Seraphim T1 Mobile AA's aim
- [X] Improved autobalance with random spawns in lobby
- [X] SMD can be paused
- [X] New "No Walls" Unit Restriction
- [X] Improved the Unit Restrictions menu descriptions
- [X] Improved the Attack-Move feature (Factory Attack-Move Engineer behaviour left alone)

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
