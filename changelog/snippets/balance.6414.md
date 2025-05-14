- (#6414) Adjust the Cooper's stats to compensate for previous changes to its hitbox, which allowed torpedoes to hit it more reliably. This also serves an additional buff to the Cooper, as it was one of the primary reasons UEF navy underperformed. UEF naval gameplay now relies less on building as few Coopers as you can get away with, and overbuilding them is less punishing.
  
  - **Cooper: T2 Torpedo Boat (XES0102):**

    - Angler Torpedo
      - RateOfFire (DPS): 10/33 (97) --> 10/32 (100)
    
    - Economy
      - BuildCostEnergy: 6480 --> 6000
      - BuildCostMass: 810 --> 750
      - BuildTime: 3240 --> 3000
    
        Building Coopers is now less punishing, and they can defend themselves more effectively against Destroyers.

    - Intel
      - SonarRadius: 36 --> 72

        Previously, its `SonarRadius` was smaller than its `WaterVisionRadius`, rendering this stat pointless. With the increased sonar radius, the Cooper can now spot other naval units more effectively.

    - SizeX: 0.75 --> 0.8
    - SizeY: 0.925 --> 1.0
    - SizeZ: 2.0 --> 2.2
    - UniformScale: 0.065 --> 0.07
    - LifeBarOffset: 0.7 --> 0.8
    - LifeBarSize: 0.5 --> 0.7
    - SelectionSizeX: 0.36 --> 0.4
    - SelectionSizeZ: 1.3 --> 1.4

      The unit is made slightly larger to prevent it from becoming too effective against Exodus in the early Tech 2 naval stage.
