{% unit UAL0205 %}
T2 Hover Flak and T2 Aeon Hover Shield
{% endunit %}
Adjust the water speeds of Aeon and Seraphim hover flak and the Asylum to match hover tanks, keeping them from falling behind during naval pushes and making ASF stacking over navy slightly more punishing. (#7243)
- Water speed:
  - Ascendant: 2.7 -> 3.24
  - Iashavoh: 2.6 -> ~3.24
  - Asylum: 4.0 -> 3.24

Additionally, the Athanah and Zthuee scripts now support the `WaterSpeedMultiplier` blueprint field. The Zthuee's previously non-functional `WaterSpeedMultiplier` of `0.9` is removed.
