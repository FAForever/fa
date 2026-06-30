- (#7123) Reduce Novax's ability to kill many shields, T2 fabs, and engineers in a single volley, and rebalance its costs to make it more vulnerable to artillery fire, especially when built in large numbers.

  **Novax Center: Experimental Satellite System (XEB2402, XEA0002)**
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

- (#7123) Remove Omni from the Novax as it unnecessarily counters cloak which is already more than sufficiently countered by T3 Omni radars. Since Omni can detect underwater units, sonar is added to partially keep that interaction.

  **Novax Center: Experimental Satellite System (XEB2402, XEA0002)**
  - Defense Satellite:
    - Omni radius: 60 -> 0
    - Sonar radius: 0 -> 60
