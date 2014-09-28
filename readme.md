FAF LUA Code
------------

Current patch is: 3634


Changelog for next patch (3636)
-------------------------------

This is the changelog posted on the forums for patch 3635.

Subject to change and investigation of correctness.

- Mongoose Buff (Slight increase in Gatling gun MuzzleVelocity to take it closer to Ravager's)
- Fixed UEF T3 Mobile AA being able to fire from Continental, and reduced projectile number
- Continental Fixes:
    - Fixed units firing from transport
    - Fixed Continental not dying to Nukes with the shield up
    - Improved fix for units being transported taking no damage while the shield is up
- T3 Seraphim Mobile Artillery given proper 'ARTILLERY' designation
- Satellite Base now self-destructs leaving full wreckage when the Satellite is killed by a Nuke
- Attempt to fix bomblet spread on bombers such as UEF and Cybran T1 Bombers
- Attempt to fix Seraphim T1 Mobile AA's aim
- Attempt to fix Aeon T1 Frigate, T2 Destroyer, and Seraphim T3 Subhunter weapon bones to improve fire reliability
- Fixed free ACU upgrade exploit
- Fixed Cybran ACU with Laser upgrade being unable to ever fire the weapon after being transported, and improve targeting further
- Shield Fixes:
    - Personal Shields now protect units also under bubble shields
    - Personal Shields now protect units properly from splash weaponry
    - Personal Shields now have correct impact size (They use the base unit hitbox)
    - Bubble Shields now correctly ricochet damage among themselves
    - Bubble Shields now interact with splash weaponry properly
- Fixed infinite economy exploit
- Hitbox Fixes: Adjusted collision boxes and target bones on dozens of units to allow weapons to target and impact them properly. 
    - Dynamically changing hitbox for Salem
    - ACUs and sACUs now hit properly by Lasers
    - Hovertanks now hit properly by Lasers
    - Torpedo launchers and Sonar now targeted properly by all surface fire naval weapons
    - Colossus, Spiderbot, Ythotha and Megalith fixed
    - Brick, Percival, Harbinger, Titan, Loyalist and Othuum fixed
    - LABs, Mantis, Aurora, Striker, Pillar, Hoplite, Mongoose, Firebeetle, Seraphim T3 Mobile Artillery, Cybran T2 Mobile Flack, HARMS, Zthuee all fixed
- New icon name for Mass Storage
- Tempest can now build hovering Aeon Land units

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
