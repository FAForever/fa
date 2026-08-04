---
layout: page
title: Balance snippet
parent: Development - Changelog
permalink: development/changelog/balance-snippet
published: true
---


The snippet file should be named `balance.<PR Number>.md`.

```md
{% unit <BlueprintID> %}
<Title>
{% endunit %}
<Description> (#<PR Number>).
- <Category>:
  - <Parameter Name>: <value before> -> <value after>
```

- Description: A summary of the changes and/or an explanation behind the reasoning for the changes.
- PR Number: The number of the pull request on GitHub. Make sure that the dot of the last sentence comes after this.
- Title: Usually `<UnitName>: <Tech> <Unit Role>` For example: `Exodus: T2 Destroyer`. This is similar to the format visible in unit dbs and the in-game UI when hovering over a unit. When the same change has been applied to multiple units, you can just write the group in the title. The BlueprintID loads the unit icon, so choose a unit that is most representative. (UEF when all factions are affected).
- BlueprintID: Blueprint ID of the unit. If the change is an enhancement, the Blueprint ID is enhancements/faction/name. You can find out the correct name by looking into the [enhancements icon folder](https://github.com/FAForever/fa/tree/develop/docs/assets/icons/enhancements).
- Category: A subheader to categorize parameters. Usually a blueprint subtable name (ex: Physics) or a weapon name.
- Parameter Name: The name for the value that was changed. It doesn't need to be the exact blueprint field name; it should be a name that players can understand.
- Value before/after: The value before/after the change. If relevant, derived values like DPS can be put in parentheses after the value as such: `<damage> (<dps>) -> <damage> (<dps>)`.

This formatting allows automatic styling of the changes on the website, but it actually consists of independent parts. You can insert additional description text after the parameter change lines, just make sure to leave a blank line. When a balance change affects multiple units in different ways, you can also put the description text first and then insert the affected units with their changed stats.

### Example snippets

```md
{% unit URS0201 %}
Salem Class: T2 Destroyer
{% endunit %}
Reduced Salem’s anti-torpedo flare target check interval from 1.0s to 0.4s—the standard for anti-projectile weapons. This improves torpedo detection and flare response, especially against torpedo bombers. In turn the movement speed has been tuned down (#6339).
- Anti Torpedo:
    - Target Check Interval: 1s -> 0.4s
- Movement:
    - Max speed : 5 -> 4
```
```md
{% unit UEA0102 %}
All T1 Interceptors
{% endunit %} 
Reduce the distance at which T1 Interceptors hover instead of turning when given a move order (#6342).
- Air Movement:
    - Start Turn Distance: 10 -> 5
```
```md
{% unit enhancements/cybran/torp %}
Nanite Torpedo Launcher
{% endunit %}
Further increase the MuzzleSalvoSize of the Cybran ACU's Nanite Torpedo upgrade to 4, as it still had difficulties penetrating torpedo defenses after (#6476) increased it to 3. Its DPS remains unchanged (#6542).
- Torpedo weapon:
    - Damage (DPS): 60 (225) -> 45 (225)
    - Muzzle Salvo Size: 3 -> 4
```
```md
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

Remove Omni from the Novax as it unnecessarily counters cloak which is already more than sufficiently countered by T3 Omni radars. Since Omni can detect underwater units, sonar is added to partially keep that interaction. (#7123)
- Defense Satellite:
  - Omni radius: 60 -> 0
  - Sonar radius: 0 -> 60
```
