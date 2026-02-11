- (#6962) The Exodus's `FiringRandomness` and `FiringTolerance` are lowered to prevent excessive misses when microing, and its `MaxRadius` is increased to buff Aeon's lacking ability to bombard shores effectively at the Tech 2 stage. Additionally, this PR reverts the nerfs to the Exodus's `TurretYawRange` and `TurretYawSpeed` introduced in [commit 3177522](https://github.com/FAForever/fa/commit/3177522abd84fede5bb841885d35b1ffd1c8c63a#diff-0c06583a0f25a70aeb6f740ffe7c8689f3e775164f98c38704969aa9b7aadd96L305-R306), which were a significant nerf to the unit's microability.

  **Exodus Class: T2 Destroyer (UAS0201):**
  - Oblivion Cannon
    - FiringRandomness: 0.25 --> 0.2
    - FiringTolerance: 2 --> 1
    - MaxRadius: 70 --> 75
    - TurretYawRange: 150 --> 160
    - TurretYawSpeed: 90 --> 100
