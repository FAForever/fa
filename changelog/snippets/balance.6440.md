- (#6440) Unify the MuzzleVelocity stat of the Aeon Cruiser's missile launchers. The Infinity Class is equipped with two copies of Zealot AA Missile launchers. These two weapons function identically except for their `MuzzleVelocity` stat, where one weapon has a higher value than the other. This is misleading because the models look the same, and the unit databases imply that both have a `MuzzleVelocity` of `40`. In terms of gameplay, there is virtually no difference.

    - Infinity Class: T2 Cruiser (UAS0202):
        - Zealot AA Missile (right battery):
            - MuzzleVelocity: 40 --> 35
        - Zealot AA Missile (left battery):
            - MuzzleVelocity: 30 --> 35
