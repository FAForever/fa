FAF LUA Code
------------

Current patch is: 3634


Changelog for next patch (3636)
-------------------------------

This is the changelog posted on the forums for patch 3635.


*Merged changes*
- [X] Fixed infinite economy exploit
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
- [X] Tempest can now build hovering Aeon Land units
- [X] Fixed free ACU upgrade exploit

*Changes to be verified*

- [ ] Mongoose Buff (Slight increase in Gatling gun MuzzleVelocity to take it closer to Ravager's)
- [ ] Fixed UEF T3 Mobile AA being able to fire from Continental, and reduced projectile number
- [ ] Continental Fixes:
    - [ ] Fixed units firing from transport
    - [ ] Fixed Continental not dying to Nukes with the shield up
    - [ ] Improved fix for units being transported taking no damage while the shield is up
- [ ] T3 Seraphim Mobile Artillery given proper 'ARTILLERY' designation
- [ ] Attempt to fix bomblet spread on bombers such as UEF and Cybran T1 Bombers
- [ ] Attempt to fix Seraphim T1 Mobile AA's aim
- [ ] Attempt to fix Aeon T1 Frigate, T2 Destroyer, and Seraphim T3 Subhunter weapon bones to improve fire reliability
- [ ] Fixed Cybran ACU with Laser upgrade being unable to ever fire the weapon after being transported, and improve targeting further
- [ ] New icon name for Mass Storage

*Changes to be made*
- Satellite base now builds the satelite, when satelite dies, base can rebuild

Contributors:
 - Sheeo
 - a_vehicle
 - Crotalus
 - Pip
 - IceDreamer


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
