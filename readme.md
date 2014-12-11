FAF LUA Code
------------
master|develop
 ------------ | -------------
[![Build Status](https://travis-ci.org/FAForever/fa.svg?branch=master)](https://travis-ci.org/FAForever/fa) | [![Build Status](https://travis-ci.org/FAForever/fa.svg?branch=develop)](https://travis-ci.org/FAForever/fa)

Current patch is: 3636

Changelog for patch 3637
------------------------
This is the changelog to be posted on the forums for patch 3637. It is in active, ongoing development
and subject to change in every aspect. Please search the forum for a discussion about the relevant
change, or make a thread if it isn't there already.

*Exploit Fixes*

*Bug Fixes*
- [X] All Factories of a given tech level now roll out Engineers at an even pace with each other

*Game Improvements*
- [X] Hitbox Fixes: Adjusted collision boxes and target bones on dozens of units to allow weapons to target and impact them properly.
    - [X] Dynamically changing hitbox for Salem
    - [X] ACUs and sACUs now hit properly by Lasers
    - [X] Hovertanks now hit properly by Lasers
    - [X] Torpedo launchers and Sonar now targeted properly by all surface fire naval weapons
    - [X] Colossus, Spiderbot, Ythotha and Megalith fixed
    - [X] Brick, Percival, Harbinger, Titan, Loyalist and Othuum fixed
    - [X] LABs, Mantis, Aurora, Striker, Pillar, Hoplite, Mongoose, Firebeetle, Seraphim T3 Mobile Artillery, Cybran T2 Mobile Flack, HARMS, Zthuee all fixed
- [X] Spread attack now works for move, build and overcharge
- [X] Ability to reclaim ground
- [X] Chrono now syncs with allies, and no longer stuns allied units
- [X] Hover / air units now sink with physics instead of slider

Contributors:
 - Sheeo
 - Crotalus
 - IceDreamer
 
Special Thanks:
 - Sir-Prize
 
Changes under consideration for future patches
----------------------------------------------

- Tempest being able to build hovering land units
- Mongoose muzzle velocity buff 

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
