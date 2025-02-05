- (#6606) Buff the power of sniper bots as they have become too expensive and micro-intensive to use compared to saving for a T4 to counter Bricks and Percivals. In general the buffs focus on ranged effectiveness while keeping the same high cost and low speed.

  - Seraphim Sniper (XSL0305):

    - Sniper mode speed: 1.65 -> 1.8

      Since the sniper mode speed is coded as a multiplier, it was unintentionally nerfed by the recent speed changes from 1.8 to 1.65. 1.65 is slower than ACU (1.7), so it was clearly excessive, and made sniper mode even more difficult to use against fast mainline units.

    The Seraphim sniper gets a mini rework to make it more favorable to use the sniper mode regularly, instead of reserving it for alpha-striking experimentals and ACUs:

    - Normal mode and sniper mode DPS swapped: 153/132 -> 132/152 respectively

    - Sniper mode damage reduced, reload sped up: 2000 dmg/15.2s (132 DPS) -> 1570 dmg/10.3s (152 DPS)
    
      This reduces for how long the sniper slows down after firing and makes it overkill Harbingers and Othuums much less (30%/28% overkill -> 2%/0%).

    - Turret Yaw speed: 90 -> 70 (normal mode) / 50 (sniper mode)

      This is due to a bug fix. It further emphasizes a steady, long range sniping style for Seraphim in contrast to Aeon's quick turning and more mobile firing.

  - Aeon and Seraphim snipers (XAL0305 & XSL0305):
    - Firing Tolerance: 2 (Aeon)/3 (Seraphim)/0.5 (Seraphim sniper mode) -> 0 (all)

      This fixes them consistently missing on the first shot after turning/retargeting, especially for the Seraphim sniper which now has lower yaw speed than turn speed.
      
    - Range: Seraphim: 55/65 -> 60/70; Aeon: 60 -> 65

      This partially reverts the range nerf from the most recent changes to snipers. The cost changes solved most of the issues, while the range nerf introduced too much of a micro requirement and gave too little range to deal damage to enemy units before they catch up. The range is only partially reverted so that Seraphim sniper mode does not outrange Ravagers (70 range).

    - Seraphim sniper speed in normal mode swapped with Aeon sniper: Aeon: 2.4 -> 2.2; Seraphim: 2.2 -> 2.4
  
      This creates a more interesting interaction between Aeon and Seraphim snipers as they swap who outranges or outspeeds who, instead of Aeon always outspeeding Seraphim. Aeon has the very fast Absolver to counter Seraphim's alpha strike capability as well.
