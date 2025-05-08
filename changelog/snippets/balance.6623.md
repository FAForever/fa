- (#6623) While the introduction of variable teleport speeds and costs was an overall positive change for the balance of the game, it has become evident that shorter-ranged jumps have become too powerful as a result. The previous minimum teleport time was set at 15 seconds, which was quite short and did not allow much leeway for counterplay. This PR aims to remedy this issue without nerfing the mechanic excessively. To accomplish this, the minimum teleport time and energy usage stats are increased, alongside the introduction of a new formula for the distance-based variable teleport time and energy usage calculations.

  **All ACUs, as well as Aeon and Seraphim SACUs**
    - Personal Teleporter
      - TeleportDelay: 15 --> 20
      - TeleportFlatEnergyCost: 75000 --> 100000

  - Introduce a new formula for teleport time and energy usage.
