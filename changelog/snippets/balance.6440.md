- (#6440) The Infinity Class Cruiser is equipped with two copies of Zealot AA Missile launchers. These two weapons function identically except for the `MuzzleVelocity` stat, where one weapon has a higher value than the other. This is misleading because the models look the same, and the unit databases imply that both AA batteries have a `MuzzleVelocity` of `40`. This PR equalizes the stats of both launchers to resolve this issue. In terms of gameplay, there is virtually no difference.

    - Infinity Class: T2 Cruiser (UAS0202):
        - Zealot AA Missile (right battery):
            - MuzzleVelocity: 40 --> 35
        - Zealot AA Missile (left battery):
            - MuzzleVelocity: 30 --> 35
