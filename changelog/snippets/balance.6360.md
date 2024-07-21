- (#6360) Increase the hitboxes of a wide range of units to fix them being able to evade torpedoes due to their hitbox being too shallow. Lots of units, such as ships or Cybran/UEF engineers, have part of their hitboxes below ground level to enable torpedo weapons to damage them when on water. Prior to this PR however, the hitboxes of many units were not submerged deep enough into the water, which caused torpedoes to not be able to hit them reliably. This was the case for almost 30 units, most notably the Cooper, but also all movable and immovable Sonars.

    - Change the `CollisionOffsetY` of all affected units from `-0.25` to `-0.375`
    - Increase the `SizeY` of the affected units accordingly, to prevent their hitbox from becoming too short.

   This change does have balance implications, especially in the case of the Cooper, since the bug caused this unit to receive damage from torpedoes both later and less often.
