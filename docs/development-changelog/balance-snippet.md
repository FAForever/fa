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
<Formatted Unit Name>
{% endunit %}
<Description> (#<PR Number>)
- <Category>:
  - <Parameter Name>: <value before> -> <value after>
```

- PR Number: The number of the pull request on GitHub.
- Description: A 1-sentence summary of the changes and then a short explanation behind the reasoning for the changes.
- Formatted Unit Name: `<UnitName>: <Tech> <Unit Role>` For example: `Exodus: T2 Destroyer`. This is similar to the format visible in unit dbs and the in-game UI when hovering over a unit.
- Blueprint ID: Blueprint ID of the unit. If the change is an enhancement, the Blueprint ID is enhancements/faction/name. You can find out the correct name by looking into the [enhancements icon folder](https://github.com/FAForever/fa/tree/develop/docs/assets/icons/enhancements).
- Category: A subheader to categorize parameters. Usually a blueprint subtable name (ex: Physics) or a weapon name.
- Parameter Name: The name for the value that was changed. It doesn't need to be the exact blueprint field name; it should be a name that players can understand.
- Value before/after: The value before/after the change. If relevant, derived values like DPS can be put in parentheses after the value as such: `<damage> (<dps>) -> <damage> (<dps>)`.

When the same change has been applied to multiple units, you can just write the group in the title. The unitID still loads the unit icon, so choose a unit that is most representative. (UEF when all factions are affected).
Alternatively, or when a balance change affects multiple units in different ways, you can also put the description text first and then list the affected units with their changed stats.

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