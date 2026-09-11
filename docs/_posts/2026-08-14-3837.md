---
layout: post
title: 3837 - Game Patch
permalink: changelog/3837
---

# Game version 3837 (August 14, 2026)

This patch is mostly a small balance patch. But we also completely reworked the chat window under the hood. Please let us know if you encounter any issues. Other than that we have included a bunch of bugfixes again.

With gratitude to all those who contributed to this patch and/or took the time to report issues,

BlackYps

## Balance

{% unit URL0303 %}
Loyalist: T3 Siege Assault Bot
{% endunit %}
Reduce stun duration of Loyalist's Disintegrator Pulse Laser since it was extremely powerful against T2 units, Ilshavohs in particular (#7121).
- Disintegrator Pulse Laser:
  - Stun Duration against T1/T2 mobile units: 1.5s per shot (2.3s per volley) (70% stun uptime) -> 0.4s per shot (1.2s per volley) (36% stun uptime)

{% unit XEB2402 %}
Novax Center: Experimental Satellite System
{% endunit %}
Reduce Novax's ability to kill many shields, T2 fabs, and engineers in a single volley, and rebalance its costs to make it more vulnerable to artillery fire, especially when built in large numbers (#7123).
- Defense Satellite's Orbital Death Laser:
  - Beam Lifetime: 8.1s -> 5.4s
  - Damage: 60 (4860 per volley) -> 90 (4860 per volley)
  - Damage Radius: 1 -> 0.5
  - Aim Speed: 360 deg/s -> 8 deg/s
  - Charge cost: 0 E -> 72000 E (3750 E/s average)
  - Charge drain rate: 0 E -> 5000 E/s
- Base Station:
  - Mass cost: 36000 -> 32000
  - Energy cost: 512000 -> 800000
  - Build time: 44800 -> 43600

The build cost is reduced by the cost of power generators (with storage adjacency) required to power the satellite's firing cost. The energy cost is increased to guide players towards building the power required for firing before building the Novax.

Remove Omni from the Novax as it unnecessarily counters cloak which is already more than sufficiently countered by T3 Omni radars. Since Omni can detect underwater units, sonar is added to partially keep that interaction.
- Defense Satellite:
  - Omni radius: 60 -> 0
  - Sonar radius: 0 -> 60

- Give an on-impact water vision radius of 4 to Aeon depth charges and the Solace's cluster torpedoes to be consistent with their normal on-impact vision (#7139).

{% unit XRL0302 %}
Fire Beetle: T2 Mobile Bomb
{% endunit %}
Rebalance Fire Beetle with removed cloak to make it interactable outside of later T3 stage or in ACU fights (#7143).
- Remove cloak and its associated upkeep and visual effects.
- Health: 500 -> 1340
- Regen rate: 0 -> 10
- Speed: 5 -> 3.8

{% unit UAL0401 %}
Galactic Colossus: Experimental Assault Bot
{% endunit %}
Rebalance Galactic Colossus's tractor claws so that the GC is weaker against T3 units by itself or when skirmishing but stronger with an army (#7146).
- Tractor Claws (x2)
  - DPS: 729 -> 240
  - Range: 41 -> 30
  - Enemy units attached to the claw can be targeted by allied units.

{% unit URL0401 %}
Scathis: Experimental Mobile Rapid-Fire Artillery
{% endunit %}
Increase Scathis accuracy and survivability so it can better compete against other enders (#7147).
- Health: 9000 -> 17000
- Regen: 0 -> 134
- Add stealth field with 24 radius and 400 e/s maintenance.
- Proton Artillery:
  - Fixed spread radius: 70 -> 63 (approximately +23% dmg/area)

{% unit UAA0310 %}
CZAR: Experimental Aircraft Carrier
{% endunit %}
Buff CZAR's cost since it underperforms against spread out surface AA. (#7152, #7172)
- Mass cost: 45000 -> 42750
- Energy cost: 1530000 -> 1453500
- Build time: 50625 -> 48094
{% unit xal0305 %}
All T3 Sniper Bots
{% endunit %}
Remove snipers' ability to prioritize ACUs. (#7165)

{% unit xal0305 %}
T3 Sniper Bots
{% endunit %}
Reduce the speed of sniper bots so that they cannot infinitely kite GC and Ythotha, and increase range as compensation. (#7167)

- Sprite Striker: T3 Sniper Bot
- Max speed: 2.5 -> 2.3
- Heavy Disruptor Cannon:
  - Range: 60 -> 65
- Usha-Ah: T3 Sniper Bot
- Max speed: 2.3 -> 2.2
- Snipe mode speed: 1.74 -> 1.7
- Sih Energy Rifle:
  - Range: 55 -> 60
- Sih Energy Rifle Sniper Mode:
  - Range: 65 -> 70

{% unit DAA0206 %}
Mercy: T2 Guided Missile
{% endunit %}
Rebalance the Mercy with higher damage and lower damage radius to increase its versatility and move it in the direction of its old identity while keeping it fair at higher levels. (#7175)
- HP: 90 -> 10
- Mass cost: 230 -> 270
- Energy cost: 4600 -> 8850
- Build time: 1200 -> 1600
- Kamikaze:
  - Damage: 1000 over 9.5 seconds -> 2100 over 4 seconds
  - Damage radius: 7.5 -> 3.5

{% unit UAB2104 %}
Seeker: T1 Anti-Air Turret
{% endunit %}
The Aeon T1 AA turret was weaker than the equivalent units of the other factions, which made it struggle more against T1 bombers and T2 gunships than expected. For comparison, the UEF and Seraphim turrets have 65.71 and 66.67 DPS, respectively. (#7182)
- Sonic Pulse Battery:
  - Damage (DPS): 14 (60) -> 15 (64.29)

{% unit UEA0304 %}
T3 Strategic Bombers
{% endunit %}
Revert the lift factor change from the last strat bomber buff (#6535) to try to increase the reliability of bomb drops when the bomber flies over hills. A reduced lift factor makes aircraft move slower up and down. (#7196)
- T3 Strategic Bombers:
  - Lift Factor: 10 -> 7


## Features

- Add a quick load hotkey that loads the game from the special quick save file (#7066).

- Rework the chat window (#7098, #7148, #7157, #7214).

  The chat window is re-implemented from scratch. It is rebuilt using the MVC-principle, creating a clear separation between state, viewing the state and interacting with the state. This rework fixes a few bugs:

  - The chat window fully supports UI scaling.
  - The chat will always snap to the frame when you open it, making it impossible for the chat to be off-screen after a resolution change.

  Adds a few features:

  - You can now issue various chat commands, use `/help` to learn more.
  - UI mods can add chat commands with ease.
  - Autocomplete on names when you start with `@`.
  - Convenient for the simulation (campaign, AIs, events) to send chat messages.
  - Click on a chat message to copy it to clipboard.

  And finally there are a few quirks:

  - The chat now starts bottom-up, instead of top-down.


## Bug fixes

- Fix the `ModWeapons` blueprint field adding weapons after dummy weapons, causing the unit weapon to incorrectly get the dummy weapon's blueprint for the new weapon (#6882).

- Fixed campaign attack manager not tracking platoons correctly (#6984)
- Fixed objective arrow not bouncing (#6984)
- Fixed a bug that could cause platoons to not be built exactly as defined in their templates (#6984)
- Changed default formation of combined campaign platoons to wide formation (#6984)
- Increased number of scouts the campaign AIs send (#6984)
- Added camera move to area function for cinematics (#6984)
- Increased UEF civilian truck turn rate (#6984)
- Fixed error when selected unit died during cinematics (#6984)
- Improved campaign-related code and annotations (#6984)

- Fix a unit-transfer exploit that adds silo progress to nuke subs and the Seraphim battleship for free (#7051).

- Remove game options of unused mods from game launch info to try to get live replays to work (#7057).

- Fix computing the wrong area in the navigational mesh. The new values may differ from the old values by +/- 15% (#7104).

- Fix French locale for Selen's toggle incorrectly saying that it toggles the Selen's cloak, when it actually only toggles selection priority, and the cloak always activates when stationary (#7127).

- Fix typo in unlocalised version of the descriptive name of the UEF T3 Support Land Factory (#7129).

- Change description of Seraphim AA units to match the other three factions' equivalent units (#7136).

  **Ialla: T1 Anti-Air Defense**
    - Description: Anti-Air Defense -> Anti-Air Turret
  **Iathu-Ioz: T3 Anti-Air Defense**
	  - Description: Anti-Air Defense -> Anti-Air SAM Launcher
  **Iashavoh: T2 Mobile Anti-Air Cannon**
	  - Description: Mobile Anti-Air Cannon -> Mobile AA Flak Artillery


- Fix default target priorities that use parentheses to enable richer category parsing using normal category parsing instead (#7138).

- Align the on-impact vision radius of the Lobo's (UEL0103) fragmentation shell, Aeon depth charges, and the Solace's cluster torpedoes to the engine's vision grid (5 -> 4) (#7139).

- Fix missing share condition default causing a score board UI loading error when the game was launched using the single player command line launch option (#7149).

- Add a delay before ACUs explode when their player disconnects. This should fix replays cutting off at the first disconnected player (#7153).

- Fix mods that allow building units on water causing those units to not be buildable on land due to how the expected default of a missing `BuildOnLayerCaps` table interacts with blueprint merge (#7159).

- Fix transfer of units with manually built enhancements (#7162).

- Fix non-number mod version numbers erroring in rule and session init (encountered with the AutoTML mod) (#7177).

- Fix projectiles passing destroyed units as damage instigators instead of themselves (#7178).

- Re-add missing `DummyUnit` import to `defaultunits.lua` needed for mod compatibility (specifically BrewLAN Research & Daiquiris) (#7180)

- Fix salem wiggling and locking up when issued lots of move orders. This is done by changing the 5x5 floating/hover footprint spec to 4x4, which only affects Salem in FAF but may affect large floating/hover units in mods by making them occupy slightly less space. (#7200)


## Graphics

- Fix the icon of the Aeon T1 power generator (#7095).
- Fix Seraphim T2 land factory's LOD1 model not matching the LOD0 model. (#7130)

- Add an additional indicator to the Cybran T2 Naval HQ differentiating it from the support factory. (#7130)

- Fix minor issues in the upgrade animations of Cybran land factories related to movement of the construction arms. (#7130)

- Fix build effects not appearing for 2 arms on the Cybran T2 land factories. (#7130)


## Performance

- Segment formations logic into different files and simplify category filters (#6847).


## Other changes

- Give a warning when non-dummy weapons are assigned dummy weapon blueprints because they are positioned after a dummy weapon blueprint in the `Weapon` table of the unit blueprint (#6882).

- Annotate states and fix annotation warnings in `DefaultProjectileWeapon.lua` (#7012).

- Game repository: Update the setup instructions for the development environment (#7036).

- Document engine-side details of `UnitWeapon:CanFire()` (#7045).

- Clean up code style and add annotations in `SelectedInfo.lua` (#7052).

- Generate BaseTemplate tables at import time instead of parsing them from lua source files (#7106).
- Add missing annotation for `CommonArmy` game option (#7137).

- Annotate `SetNavigatorPersonalPosMaxDistance` and check it exists before calling it (#7155).

- Rename `CLAUDE.md` to `AGENTS.md` for cross-agent compatibility (#7166).

- Update the FA Lua plugin used alongside our vscode intellisense extension to exclude diagnostics coming from the base file when writing a mod's hook file (#7176).

- Annotate some engine behavior and miscellaneous lua functions (#7179).

- Fix unit icons not loading on the changelog website (#7202).


## Contributors

With thanks to the following contributors:
- PreciseBump38
- niuniu319
- Jip
- Nomander
- Nory
- ostrovaya
- AzarAI
- BlackYps
- Lightningbulb2
- HotCheese
- speed2
- Saver27
- 4z0t

