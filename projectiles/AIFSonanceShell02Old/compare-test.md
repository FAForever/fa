# DEBUG: Emissary effects, new vs old

`uab2302` fires the shell with its effects in blueprints. `uab2302old` fires a copy of the shell as it was at 16ac0beeb, with the effects set up by the script. Each pair below should look the same.

Spawn at a flat spot. Leave room in front if the map has water, for step 5. New is on the left, old on the right, and each has the same hostile targets 300 ahead:

```lua
CreateUnitAtMouse('uab2302',    GetFocusArmy() - 1, -60.00,   0.00, 0)
CreateUnitAtMouse('uab1301',    GetFocusArmy() - 1, -75.00,   0.00, 0)
CreateUnitAtMouse('uab2302old', GetFocusArmy() - 1,  60.00,   0.00, 0)
CreateUnitAtMouse('uab1301',    GetFocusArmy() - 1,  75.00,   0.00, 0)
CreateUnitAtMouse('uab4301', 1,                     -85.00, 300.00, 0)
CreateUnitAtMouse('uab4301', 1,                      35.00, 300.00, 0)
CreateUnitAtMouse('ual0401', 1,                     -35.00, 300.00, 0)
CreateUnitAtMouse('ual0401', 1,                      85.00, 300.00, 0)
CreateUnitAtMouse('ual0201', 1,                     -60.00, 260.00, 0)
CreateUnitAtMouse('ual0201', 1,                      60.00, 260.00, 0)
```

Select both Emissaries and run this, so they only fire on attack orders, straight at the target:

```lua
ConExecute[[SimLua for _, u in DebugGetSelection() do if u.UnitId == 'uab2302' or u.UnitId == 'uab2302old' then local w = u:GetWeapon(1) w:SetTargetingPriorities({}) w:SetFiringRandomness(0) end end]]
```

In each step, attack-order each Emissary at its own target: the left Emissary at the left target, the right Emissary at the right one.

- [ ] 1. Attack the ground about 30 in front of each tank, toward the Emissary. Both hits should match: the explosion, dirt, motes, dust curling in, debris and the final rings.
- [ ] 2. Attack each shield (`uab4301`). The drill should match: streak, spark pulses, the shield flaring, the release flash and the final distortion.
- [ ] 3. Attack each GC (`ual0401`). The vortex on a unit should match.
- [ ] 4. Attack each tank (`ual0201`). The first hit kills it, and the shell lodges in the ground behind it. The lodge dirt and air ripple should match, then the second hit.
- [ ] 5. If the map has water in range, attack the water. The splash, waves and the final splash should match.
