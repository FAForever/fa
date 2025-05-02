- (#6522) In #5725 the number of child projectiles for the Solace was accidentally increased from 2 to 3 resulting in increased total damage (6k rather than 4k). This change is reversed, and the damage is now properly split between child projectiles instead of being a multiplier of the main projectile's damage.

  **Solace: T3 Torpedo Bomber (XAA0306):**
  - Number of child projectiles per torpedo: 3 -> 2 (Total damage 6000 -> 4000)
  - Main projectiles now deal full damage if they fall directly onto an enemy (Damage 400 -> 800).
