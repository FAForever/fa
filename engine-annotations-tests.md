# In-game tests for docs/engine-annotations

Untracked notes, not part of the PR. Run each block with the paste-buffer hotkey, mouse over open ground, on a map that has `ARMY_17`. None of these were run.

## 1. OnStartTracking is edge-triggered, not continuous

```lua
local p = GetMouseWorldPos()
ConExecute(string.format('SimLua local x, y, z = %f, %f, %f\n', p[1], p[2], p[3]) .. [[
local turret = CreateUnitHPR('ueb2101', GetFocusArmy(), x, y, z, 0, 0, 0)
local target = CreateUnitHPR('uel0101', 'ARMY_17', x - 15, y, z + 15, 0, 0, 0)
local units = { turret, target }
target:SetCanTakeDamage(false)
IssuePatrol({ target }, { x + 15, y, z + 15 })
IssuePatrol({ target }, { x - 15, y, z + 15 })
local weapon = turret:GetWeapon(1)
local onStart, onStop = weapon.OnStartTracking, weapon.OnStopTracking
local starts, stops = 0, 0
weapon.OnStartTracking = function(self, label)
    starts = starts + 1
    LOG('OnStartTracking tick ', GetGameTick(), ' label ', label, ' heading ', self.AimControl:GetHeadingPitch())
    onStart(self, label)
end
weapon.OnStopTracking = function(self, label)
    stops = stops + 1
    LOG('OnStopTracking tick ', GetGameTick(), ' label ', label, ' heading ', self.AimControl:GetHeadingPitch())
    onStop(self, label)
end
ForkThread(function()
    WaitSeconds(30)
    LOG('Tracking test: ', starts, ' starts, ', stops, ' stops')
    for _, u in units do
        if not IsDestroyed(u) then
            u:Destroy()
        end
    end
end
)]]) -- intentionally on a new line
```

- [ ] One `OnStartTracking` when the PD first turns toward the scout, and no further start until an `OnStopTracking`. The final count is a few per pass, not dozens.
- [ ] Start/stop pairs fall near the patrol ends, where the scout reverses.

## 2. OnStatsTrigger fires once

```lua
ConExecute[[SimLua local b = ArmyBrains[GetFocusArmy()] local f = b.OnStatsTrigger b.OnStatsTrigger = function(self, n) if n == 'TestOnce' then LOG('OnStatsTrigger TestOnce tick ', GetGameTick()) end f(self, n) end b:SetArmyStatsTrigger('Economy_Stored_Mass', 'TestOnce', 'GreaterThanOrEqual', 0)]]
```

- [ ] Exactly one `OnStatsTrigger TestOnce` line, although the condition stays true. More than one means the "removes the trigger when it fires" sentence is wrong.

## 3. Scroll callbacks: IsScrollable and ScrollPages are never called by the engine

```lua
local UIUtil = import("/lua/ui/uiutil.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local parent = GetFrame(0)
local box = Bitmap(parent)
box:SetSolidColor('80202020')
LayoutHelpers.AtCenterIn(box, parent)
box.Width:Set(200) box.Height:Set(300) box.Depth:Set(10000)
local top = 0
box.IsScrollable = function(self, axis) LOG("IsScrollable ", axis) return true end
box.GetScrollValues = function(self, axis) return 0, 100, top, top + 10 end
box.ScrollLines = function(self, axis, delta) LOG("ScrollLines ", tostring(axis), " ", delta) top = math.max(0, math.min(90, top + delta)) end
box.ScrollPages = function(self, axis, delta) LOG("ScrollPages ", tostring(axis), " ", delta) end
box.ScrollSetTop = function(self, axis, newTop) LOG("ScrollSetTop ", tostring(axis), " ", newTop) top = math.max(0, math.min(90, newTop)) end
UIUtil.CreateVertScrollbarFor(box)
_G.ScrollTestBox = box
```

Scroll the wheel over the scrollbar, click the track above and below the thumb, drag the thumb.

- [ ] The log never shows `IsScrollable` or `ScrollPages`.
- [ ] The wheel and track clicks both log `ScrollLines Vert ±1`.
- [ ] Dragging the thumb logs `ScrollSetTop`.

Clean up with `ScrollTestBox:Destroy()`.

## 4. OnIconsVisible: Space rotation and free camera only

```lua
local wv = import("/lua/ui/game/worldview.lua").viewLeft
wv.OnIconsVisible = function(self, visible) LOG("OnIconsVisible ", tostring(visible)) end
```

1. Zoom fully in and out.
2. Run `ui_RenderIcons false`, then `true`.
3. Hold Space and move the mouse, then release Space.
4. Run `cam_Free true`, then `cam_Free false`.

- [ ] Steps 1 and 2 log nothing.
- [ ] Steps 3 and 4 each log `false` then `true`. If step 3 logs nothing, the "holding Space" wording is wrong.

## 5. POD orders while docked

```lua
local p = GetMouseWorldPos()
ConExecute(string.format('SimLua local x, y, z = %f, %f, %f\n', p[1], p[2], p[3]) .. [[
local army = GetFocusArmy()
local acu = CreateUnitHPR('uel0001', army, x, y, z, 0, 0, 0)
local transport = CreateUnitHPR('uea0107', army, x + 15, y, z, 0, 0, 0)
local engineer = CreateUnitHPR('uel0105', army, x + 20, y, z, 0, 0, 0)
local target = CreateUnitHPR('ueb1101', 'ARMY_17', x, y, z + 25, 0, 0, 0)
acu:SetHealth(acu, acu:GetMaxHealth() * 0.5)
acu:CreateEnhancement('LeftPod')
IssueTransportLoad({ engineer }, transport)
ForkThread(function()
    local pod = acu.LeftPod
    for i = 1, 600 do
        if pod:IsUnitState('Attached') and engineer:IsUnitState('Attached') then break end
        WaitTicks(1)
    end
    LOG('pod attached: ', tostring(pod:IsUnitState('Attached')), ', engineer attached: ', tostring(engineer:IsUnitState('Attached')))
    for _, u in { pod, engineer } do
        local function Try(name, issue)
            local before = table.getn(u:GetCommandQueue())
            issue({ u })
            LOG(u.UnitId, ' ', name, ': queue ', before, ' -> ', table.getn(u:GetCommandQueue()))
        end
        Try('move', function(us) IssueMove(us, { x, y, z - 30 }) end)
        Try('guard', function(us) IssueGuard(us, acu) end)
        Try('reclaim', function(us) IssueReclaim(us, target) end)
        Try('capture', function(us) IssueCapture(us, target) end)
        Try('repair', function(us) IssueRepair(us, acu) end)
    end
end
)]]) -- intentionally on a new line
```

- [ ] Both units attached (the drone docks by itself once idle).
- [ ] Every order on the drone (`uea0001`) grows its queue by 1.
- [ ] Every order on the engineer (`uel0105`) leaves its queue unchanged.
- [ ] Drag-selecting over the docked drone selects it; drag-selecting over the loaded transport doesn't select the engineer.

If every count stays the same, `Issue*` isn't synchronous: add `WaitTicks(2)` before each "after" read.

## 6. OnNukeArmed fires for tactical missiles too

```lua
local p = GetMouseWorldPos()
ConExecute(string.format('SimLua local x, y, z = %f, %f, %f\n', p[1], p[2], p[3]) .. [[
local u = CreateUnitHPR('ueb2108', GetFocusArmy(), x, y, z, 0, 0, 0)
u:GetAIBrain():GiveResource('Energy', 100000) u:GetAIBrain():GiveResource('Mass', 10000)
local baseEnd = u.OnSiloBuildEnd
u.OnSiloBuildEnd = function(self, w) LOG('OnSiloBuildEnd tick ', GetGameTick()) baseEnd(self, w) end
u.OnNukeArmed = function(self, w) LOG('OnNukeArmed tick ', GetGameTick(), ' ', self.UnitId) end
u.GetEconomyBuildRate = function(self) LOG('GetEconomyBuildRate tick ', GetGameTick()) return self:GetBuildRate() end
IssueSiloBuildTactical({u})
SimConExecute('wld_RunWithTheWind 1')
ForkThread(function()
    while u:GetTacticalSiloAmmoCount() < 1 do WaitTicks(1) end
    SimConExecute('wld_RunWithTheWind 0')
end
)]]) -- intentionally on a new line
```

- [ ] `GetEconomyBuildRate` once when the missile starts.
- [ ] `OnSiloBuildEnd` then `OnNukeArmed` on the same tick for `ueb2108`.

## 7. OnAnimCollision is a footfall

```lua
local p = GetMouseWorldPos()
ConExecute(string.format('SimLua local x, y, z = %f, %f, %f\n', p[1], p[2], p[3]) .. [[
local u = CreateUnitHPR('ual0401', GetFocusArmy(), x, y, z, 0, 0, 0)
local base = u.OnAnimCollision
u.OnAnimCollision = function(self, bone, bx, by, bz) LOG('footfall ', bone, ' local y ', by, ' tick ', GetGameTick()) base(self, bone, bx, by, bz) end
IssuePatrol({u}, {x + 40, y, z}) IssuePatrol({u}, {x, y, z})
]]) -- intentionally on a new line
```

- [ ] One line per step, alternating foot bones, `local y` just under 0.1, in time with the footfall dust.

## 8. GetRebuildBonus runs on the builder

```lua
local p = GetMouseWorldPos()
ConExecute(string.format('SimLua local x, y, z = %f, %f, %f\n', p[1], p[2], p[3]) .. [[
local e = CreateUnitHPR('uel0105', GetFocusArmy(), x + 6, y, z, 0, 0, 0)
local base = e.GetRebuildBonus
e.GetRebuildBonus = function(self, bp) LOG('GetRebuildBonus on ', self.UnitId, ' for ', bp.BlueprintId) return base(self, bp) end
local g = CreateUnitHPR('ueb1101', GetFocusArmy(), x, y, z, 0, 0, 0)
g:Kill()
]]) -- intentionally on a new line
```

Select the engineer and build a T1 power generator exactly on the wreck.

- [ ] `GetRebuildBonus on uel0105 for ueb1101` (the engineer, not the wreck).
- [ ] The wreck disappears when construction starts.

## 9. A structure's attack order ends when the target leaves its range

```lua
local p = GetMouseWorldPos()
ConExecute(string.format('SimLua local x, y, z = %f, %f, %f\n', p[1], p[2], p[3]) .. [[
local pd = CreateUnitHPR('ueb2101', GetFocusArmy(), x, y, z, 0, 0, 0)
local tank = CreateUnitHPR('uel0201', 'ARMY_17', x + 15, GetSurfaceHeight(x + 15, z), z, 0, 0, 0)
pd:SetCanTakeDamage(false) tank:SetCanTakeDamage(false)
IssueAttack({pd}, tank)
ForkThread(function()
    for i = 1, 12 do
        WaitSeconds(1)
        if i == 4 then Warp(tank, Vector(x + 40, GetSurfaceHeight(x + 40, z), z)) end
        if i == 8 then Warp(tank, Vector(x + 15, GetSurfaceHeight(x + 15, z), z)) end
        LOG(string.format('DFTEST t=%d queue=%d', i, table.getn(pd:GetCommandQueue())))
    end
    pd:Destroy() tank:Destroy()
end)
]]) -- intentionally on a new line
```

- [ ] `queue=1` for t=1 to 4.
- [ ] `queue=0` from about t=5, after the tank moves beyond the PD's range.
- [ ] `queue` stays 0 after t=8, when the tank is back in range.

## 10. Slide manipulator BeenDestroyed vs IsDestroyed

The stub says `CSlideManipulator:BeenDestroyed` matches `IsDestroyed`. This logs both after destroying a slider directly, and after destroying its unit. `pcall` catches a method call on a deleted manipulator.

```lua
local p = GetMouseWorldPos()
local x, y, z, focusArmy = p[1], p[2], p[3], GetFocusArmy()
ConExecute(string.format('SimLua local x, y, z, focusArmy = %f, %f, %f, %d\n', x, y, z, focusArmy) .. [[
local units = {
    CreateUnitHPR('uel0101', focusArmy, x, y, z, 0, 0, 0),
    CreateUnitHPR('uel0101', focusArmy, x + 5, y, z, 0, 0, 0),
}
local direct = CreateSlider(units[1], 0, 0, 1, 0, 1)
local withUnit = CreateSlider(units[2], 0, 0, 1, 0, 1)
local function Report(name, slider)
    local ok, been = pcall(slider.BeenDestroyed, slider)
    LOG(name, ' tick ', GetGameTick(), ': BeenDestroyed ', (ok and tostring(been) or 'error: ' .. tostring(been)), ', IsDestroyed ', tostring(IsDestroyed(slider)))
end
direct:Destroy()
units[2]:Destroy()
Report('direct', direct)
Report('with unit', withUnit)
ForkThread(function()
    WaitTicks(1)
    Report('direct', direct)
    Report('with unit', withUnit)
    for _, u in units do
        if not IsDestroyed(u) then
            u:Destroy()
        end
    end
end)
]]) -- intentionally on a new line
```

- [ ] Note the four lines. If `BeenDestroyed` and `IsDestroyed` differ on the first tick, the stub's "like `IsDestroyed`" is wrong.
- [ ] On the second tick, both read true for both sliders, or `BeenDestroyed` errors on a deleted slider.

Last: check the log for new Lua errors.
