FAF LUA Code
------------

Current patch is: 3634


Changelog for patch 3636
------------------------

This is the changelog to be posted on the forums for patch 3636.

*Exploit Fixes*
- [X] Fixed infinite economy exploit
- [X] Fixed free ACU upgrade exploit
- [X] Security exploits with simcallbacks

*Bug Fixes*
- [X] Continental Fixes:
    - [X] Fixed units firing from transport
    - [X] Fixed Continental not dying to Nukes with the shield up
    - [X] Improved fix for units being transported taking no damage while the shield is up
- [X] Fixed UEF T3 Mobile AA being able to fire from Continental, and reduced projectile number
- [X] T3 Seraphim Mobile Artillery given proper 'ARTILLERY' designation
- [X] Fix adjacency buffs working when unit is turned off
- [X] Fixed Cybran ACU with Laser upgrade being unable to ever fire the weapon after being transported, and improve targeting further
- [X] Fixed Seraphim ACU dying when dropped from Transport after being picked up while firing
- [X] Fixed Seraphim ACU shot being visible through FoW

*Game Improvements*
- [X] Shield Fixes:
    - [X] Personal Shields now protect units also under bubble shields
    - [X] Personal Shields now protect units properly from splash weaponry
    - [X] Bubble Shields now correctly ricochet damage among themselves
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

*Balance Changes*
- [X] Shield and Hitbox fixes above will have balance implications of varying size
- [X] Tempest can now build hovering Aeon Land units
- [X] Mongoose Buff (Slight increase in Gatling gun MuzzleVelocity to equal Ravager's)
- [X] All Factories of a given tech level now roll out Engineers at an even pace with each other

----------------------------------
*Changes to be verified*
- [ ] Attempt to fix Aeon T1 Frigate, T2 Destroyer, and Seraphim T3 Subhunter weapon bones to improve fire reliability
- [ ] New icon name for Mass Storage

----------------------------------
*Changes to be made*
- Satellite base now builds the satellite, when satellite dies, base can rebuild
- Fix cyclic factory assist crash exploit
- Fix engineer repair on upgrade exploit
- Fix HQ Factory visual bug
- Implement proper Stealth
- Fix replays desyncing
- Fix Support factories being built prior to HQ with UI exploit

Contributors:
 - Sheeo
 - a_vehicle
 - Crotalus
 - Pip
 - IceDreamer
 - thygrrr
 - PattogoTehen
 - RK4000


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
