- Make SACUs easier to access with reduced infrastructure costs and make them more powerful with a general cost reduction for SACUs and targeted adjustments for weaker upgrades (engineering upgrades, UEF bubble shield, Seraphim Overcharge) (#7141, #7164).

Seraphim Shield is moved to the right arm to nerf Seraphim teleport SACUs and enable a more useful Rambo preset. 

Seraphim receives a RAS upgrade instead of its higher base cost and base production.

Since they're easier to rush and are more powerful, SACUs have their ACU target priority ability removed to allow overcharge to counter early SACUs again.

Due to costing less, the buildpower of non-UEF SACUs is reduced (engi presets keep their buildpower). UEF keeps their buildpower because they have a weaker engineer preset, the most expensive base SACU, a T4 that struggles with pushing, and unique ravagers.

Combatant and Rambo presets are separated by a high energy cost difference and Rambos get a mass cost reduction. This allows combatants to help with a faction's early issues, while Rambos play a role in the late game by being efficient but high infrastructure cost combat units, and highly versatile engineering units that can mitigate the dominance of air and the risk of reclaim donations.

{% unit UAB0304 %}
Quantum Gateways
{% endunit %}
- Mass cost: 3000 -> 2550
- Energy cost: 30000 -> 25500
- Build rate: 120 -> 160
- Health: 10000 -> 7500
- Adjacency:
  - Energy discount from T1 and T3 pgens: 0.25% and 5% -> 1.563% and 15.62%
  - Mass discount from T2 and T3 mass fabs: 0.75% and 3.75% -> 1.25% and 20%

{% unit UAL0301 %}
Aeon Support Armored Command Unit
{% endunit %}
- Mass cost: 1950 -> 1550
- Energy cost: 27100 -> 21500
- Build time: 14400 -> 8250
- Buildpower: 56 -> 42
- Removed ability to prioritize ACUs
- Rapid Fabricator:
  - Mass cost: 800 -> 500
  - Energy cost: 50500 -> 10100
  - Build time: 4200 -> 1350
  - Added buildpower: +42 -> +56
- Resource Allocation System:
  
  Cost increased to keep requirements for sacrifice the same and to slightly counteract the base cost and quantum gateway buildpower/adjacency buffs.

  - Mass cost: 4500 -> 4600
  - Energy cost: 90000 -> 94400 
  - Build time: 8400 -> 20550
- Personal Shield Generator:
  - Energy cost: 64950 -> 49000
  - Build time: 5040 -> 4950
  - Energy maintenance cost: 300 -> 210
- Heavy Personal Shield Generator:
  - Mass cost: 1800 -> 900
  - Energy cost: 100000 -> 200975
  - Build time: 7000 -> 3660
  - Energy maintenance cost: 600 -> 420
- Reacton Refractor (Range and AoE upgrade):
  - Energy cost: 46200 -> 45600
  - Build time: 6048 -> 6200
- Nano-Repair System:
  - Energy cost: 74000 -> 57500

{% unit UEL0301 %}
UEF Support Armored Command Unit
{% endunit %}
- Mass: 2100 -> 1700
- Energy: 25200 -> 20400
- Build time: 14400 -> 9060
- Removed ability to prioritize ACUs
- Shield Generator Field:

  The UEF bubble shield is heavily reduced in cost by removing its prerequisite, and its stats are adjusted to be closer to mobile shields.

  - Prerequisite: Personal Shield Generator -> None
  - Mass cost: 3500 -> 3300
  - Energy cost: 360800 -> 244700
  - Build time: 10800 -> 14500
  - Energy maintenance cost: 1000 -> 700
  - Shield stats:
    - Health: 52000 -> 22000
    - Recharge Time: 215 -> 100 seconds
    - Regen Rate: 150 -> 160 hp/s
    - Regen Delay: 1 -> 3 seconds
    - Spillover mult: 0.2 -> 0.3
- C-D3 Engineering Drone:
  - Energy cost: 8700 -> 7700
  - Build time: 2500 -> 1000
- Resource Allocation System:
  - Mass cost: 4500 -> 4600
  - Energy cost: 90000 -> 94400 
  - Build time: 8400 -> 20550
- Personal Shield Generator:
  - Mass cost: 2000 -> 1700
  - Energy cost: 100200 -> 289000
  - Build time: 7200 -> 6950
  - Energy maintenance cost: 500 -> 350
- Energy Accelerator (Fire Rate upgrade):
  - Energy cost: 44700 -> 43900
  - Build time: 5040 -> 5060
- Heavy Plasma Refractor (Range and AoE upgrade):
  - Energy cost: 30000 -> 28600
  - Build time: 3360 -> 3370
- Radar Jammer:
  - Build time: 2500 -> 1000
- Enhanced Sensor System:
  - Build time: 3000 -> 2520

{% unit URL0301 %}
Cybran Support Armored Command Unit
{% endunit %}
- Mass: 2000 -> 1600
- Energy: 26400 -> 21100
- Build time: 14400 -> 8530
- Buildpower: 56 -> 42
- Removed ability to prioritize ACUs
- Rapid Fabricator:
  - Mass cost: 800 -> 500
  - Energy cost: 51100 -> 10100
  - Build time: 4200 -> 1350
  - Added buildpower: +42 -> +56
- Resource Allocation System:
  - Mass cost: 4500 -> 4600
  - Energy cost: 90000 -> 94400 
  - Build time: 8400 -> 20550
- Disintegrator Amplifier (Damage and Range upgrade):

  Due to the SACU cost reduction making SACUs upgraded with only this gun upgrade overpowered, mass costs from EMP, Nano, and Cloaking are moved to this upgrade.

  - Mass cost: 800 -> 1400
  - Energy cost: 24000 -> 50100
  - Build time: 3000 -> 6950
- Personal Cloaking Generator:
  - Mass cost: 5000 -> 2000
  - Energy cost: 382200 -> 312700 
  - Build time: 13800 -> 8300
  - Health bonus: 15000 -> 17000
  - Energy maintenance cost: 3500 -> 2500
- EMP Burst:
  - Mass cost: 1000 -> 700
  - Energy cost: 60000 -> 32500 
  - Build time: 3600 -> 3000
- Nanite Missile System:
  - Build time: 3000 -> 2750
- Nano-Repair System:
  - Mass cost: 2200 -> 1900
  - Energy cost: 103500 -> 92300 
  - Build time: 6000 -> 7850
- Personal Stealth Generator:
  - Energy cost: 7400 -> 13000
  - Build time: 1800 -> 1620
  - Energy maintenance cost: 100 -> 70

{% unit XSL0301 %}
Seraphim Support Armored Command Unit
{% endunit %}
- Mass: 2400 -> 1650
- Energy: 30200 -> 20800
- Build time: 14400 -> 8800
- Buildpower: 56 -> 42
- Removed ability to prioritize ACUs
- Mass production: 3 -> 1
- Energy production: 300 -> 20
- Added Resource Allocation System:

    Seraphim players have continued to struggle with the ability to build a mobile economy because the stats were balanced around the high buildpower of Seraphim SACU spam compared to other factions' RAS SACUs. Since players aren't using this, the RAS upgrade is replacing the SACU's increased base production and base cost.

  - Slot: Right arm (teleport and overcharge arm)
  - Mass cost: 4600
  - Energy cost: 94400 
  - Build time: 20550
  - Mass production: 10
  - Energy production: 1000
- Rapid Fabricator:
  - Mass cost: 450 -> 500
  - Energy cost: 47400 -> 10100
  - Build time: 4200 -> 1350
  - Added buildpower: +42 -> +56
- Nano-Repair System:
  - Mass cost: 2300 -> 2500
  - Energy cost: 74300 -> 141200 
  - Build time: 5900 -> 11650
- Tactical Missile Launcher:
  - Mass cost: 1500 -> 1800
  - Energy cost: 46000 -> 68000 
  - Build time: 4200 -> 8450
- Overcharge:
  - Mass cost: 4500 -> 3000
  - Energy cost: 283500 -> 155000 
  - Build time: 12600 -> 13800
- Personal Shield Generator:

  The shield generator is being moved to the right arm to nerf teleport and enable a more useful Rambo preset.

  Seraphim Teleport SACUs were extremely strong for their 20k mass cost (with ~18k energy infrastructure cost): they were harder to stop from killing an SMD than a telemazer (in terms of DPS/PD amount), their infrastructure is reusable, and the only way to stop multiple teleports on a far more expensive 75k mass artillery or 225k mass game ender is by spamming shields and hoping they got in between the SACU's gun and the target.

  The Rambo preset is changed from Nano + Shield + Overcharge to Nano + Shield + Sensors/Gun Range. It can act as a lategame HP tank that doesn't rely on energy for DPS like the Advanced Combatant preset or regen for survivability like the Nano Combatant preset.


  - Slot: Back (TML and sensors/gun range) -> Right arm (teleport and overcharge)
  - Mass cost: 1050 -> 1000
  - Energy cost: 107500 -> 190000
  - Build time: 6720 -> 4000
  - Energy maintenance cost: 300 -> 210
