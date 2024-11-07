- (#6481) Balance cost and DPS stats of T3 static artillery:
  1. Aeon Emissary set to 79k mass in proportion to old UEF artillery DPS/M.
  2. Artillery costs spread evenly across 70-79k mass. Artillery costs are not reduced below their current costs because that would make them come out earlier.
  3. Damage adjusted for more per-artillery variety in shots to kill T3 shields, while also evening out STK vs different faction T3 shields.
  4. Reload adjusted so that avg DPS vs T3 shields (this accounts for regen) per mass is equal to Aeon artillery.
  - Aeon Emissary: 
    - Mass cost: 79000 -> 73200 (+7.9%)
    - Energy cost: 1372500 -> 1481000 (+7.9%)
    - Build time: 120000 -> 129500 (+7.9%)
    - DPS with 4 T3 pgens: 1000
  - UEF Duke:
    - Mass cost: 72000 -> 76000 (+5.6%)
    - Energy cost: 1350000 -> 1424000 (+5.5%)
    - Build time: 115000 -> 121400 (+5.6%)
    - DPS with 4 T3 pgens: 917 -> 980 (+6.9%)
      - Damage: 5500 -> 7840
      - Base Reload: 10s -> 13.3s
  - Seraphim Hovatham:
    - Mass cost: 70800 -> 73000 (+3.1%)
    - Energy cost: 1327500 -> 1369000 (+3.1%)
    - Build time: 110000 -> 113400 (+3.1%)
    - DPS with 4 T3 pgens: 833 -> 935 (+12.3%)
      - Damage: 5000 -> 5800
      - Base Reload: 10s -> 10.4s
  - Cybran Disruptor:
    - Mass cost: 69600 -> 70000 (+0.6%)
    - Energy cost: 1305000 -> 1313000 (+0.6%)
    - Build time: 105000 -> 105600 (+0.6%)
    - DPS with 4 T3 pgens: 804 -> 844 (+5.0%)
      - Damage: 3700 -> 3800
      - Base Reload: 7.7s -> 7.5s
      - As it has a lot of splash radius and there is a significant accuracy buff for the Disruptor in this patch, the DPS isn't increased as much as calculated vs T3 shields.

- (#6482) Balance accuracy of T3 static artillery:
  The accuracy is balanced for DPS dealt to multiple Seraphim T3 shields (accounts for splash damage), a scenario similar to how a high value target would be protected late-game where T3 artillery plays a role.
  - Aeon Emissary:
    - Firing Randomness: 0.35
  - UEF Duke:
    - Firing Randomness: 0.525 -> 0.467
  - Seraphim Hovatham:
    - Firing Randomness: 0.675 -> 0.560
  - Cybran Disruptor:
    - Firing Randomness: 0.75 -> 0.646
