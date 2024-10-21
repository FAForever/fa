- (#6428) Implement a Dual Yaw turret controller so that Loyalist can fully aim its secondary.

    Previously, the Loyalist was unable to aim its secondary weapon in all directions because the secondary weapon could not rotate the torso independently.
    With this change, a weapon can have a secondary yaw bone to aim with by defining `TurretBoneDualYaw` in its blueprint. The secondary yaw's angle, range, and speed can be set with `TurretDualYaw`, `TurretDualYawRange`, and `TurretDualYawSpeed`, but they also default to the primary yaw's angle, range, and speed if not specified.
