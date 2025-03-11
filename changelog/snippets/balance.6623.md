- (#6623) While the introduction of variable teleport speeds and costs was an overall positive change for the balance of the game, it has become evident that shorter-ranged jumps are too powerful. The current 15-second delay is quite short and does not allow much leeway for counterplay. This PR aims to remedy this issue without nerfing the mechanic excessively.

  - **All ACUs, as well as Aeon and Seraphim SACUs**
    - Personal Teleporter
      - TeleportDelay: 15 --> 20
      - TeleportFlatEnergyCost: 75000 --> 100000
      - Introduce a new formula for teleport time and energy usage
