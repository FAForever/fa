{% unit UEB4301 %}
Stationary Shields
{% endunit %}
Make shield assist consistent across stationary shields. Assisting a shield used to cost 75% of the shield's build cost rate, so the cost of restoring shield HP came from unrelated buildtime and cost values, ranging from 0.165 to 0.304 mass per HP. Shield HP restored per build power also varied a lot, from 0.75 for ED1 to 2.8 for the Seraphim T3 shield.

Stationary shields now have dedicated assist costs per HP restored, with separate values for T2 and T3 shields. Within each tier, costs are within 10% of each other: Aeon and Seraphim shields are the cheapest to assist and Cybran shields are the most expensive, as before. ED1-ED3 use T2 values, ED5 uses T3 values, and ED4 sits between them, closer to T3. Shield HP restored per build power is now between 2.5 and 2.8: Seraphim 2.8, Aeon 2.7, UEF 2.6, Cybran 2.5 (#7365).
- Aeon T2 Shield:
  - Shield HP restored per build power: 2.3 -> 2.7
  - Assist cost per HP: 0.165 M, 1.98 E -> 0.165 M, 1.80 E
- Seraphim T2 Shield:
  - Shield HP restored per build power: 2.55 -> 2.8
  - Assist cost per HP: 0.165 M, 1.65 E -> 0.165 M, 1.80 E
- UEF T2 Shield:
  - Shield HP restored per build power: 2.0 -> 2.6
  - Assist cost per HP: 0.196 M, 1.96 E -> 0.173 M, 1.89 E
- ED1:
  - Shield HP restored per build power: 0.75 -> 2.5
  - Assist cost per HP: 0.229 M, 2.86 E -> 0.180 M, 1.96 E
- ED2:
  - Shield HP restored per build power: 1.47 -> 2.5
  - Assist cost per HP: 0.304 M, 3.30 E -> 0.180 M, 1.96 E
- ED3:
  - Shield HP restored per build power: 1.87 -> 2.5
  - Assist cost per HP: 0.230 M, 3.10 E -> 0.180 M, 1.96 E
- ED4:
  - Shield HP restored per build power: 2.17 -> 2.5
  - Assist cost per HP: 0.242 M, 4.04 E -> 0.184 M, 2.94 E
- Aeon T3 Shield:
  - Shield HP restored per build power: 2.5 -> 2.7
  - Assist cost per HP: 0.176 M, 3.22 E -> 0.170 M, 3.00 E
- Seraphim T3 Shield:
  - Assist cost per HP: 0.166 M, 2.77 E -> 0.170 M, 3.00 E
- UEF T3 Shield:
  - Shield HP restored per build power: 2.18 -> 2.6
  - Assist cost per HP: 0.227 M, 3.78 E -> 0.178 M, 3.15 E
- ED5:
  - Shield HP restored per build power: 2.33 -> 2.5
  - Assist cost per HP: 0.193 M, 3.06 E -> 0.185 M, 3.27 E

{% unit URB4207 %}
ED1-ED5: T2/T3 Shield Generators
{% endunit %}
Revert the Cybran shield buildtime and buildrate changes from #2703, which only existed to reduce their assist costs. Upgrade times stay the same. ED5 can only be made by upgrading, so it gets back a low buildtime. ED4 shares its buildtime between engineers and upgrades, so engineers build it slightly slower (#7365).
- ED1:
  - Build rate: 19.2 -> 15.53
- ED2:
  - Build time: 775 -> 627
  - Build rate: 21 -> 13.34
- ED3:
  - Build time: 2200 -> 1397
  - Build rate: 29.3 -> 30.575
- ED4:
  - Build time: 3515 -> 3667
  - Build rate: 50.7 -> 11.81
- ED5:
  - Build time: 7100 -> 1654
