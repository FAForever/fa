# In-game test procedures

How to write a procedure for testing a PR in-game. The procedure goes in the PR's "Testing done on the proposed changes" section. A tester runs it in one sitting and ticks the boxes as they go, so it must read as a script, not a list of ideas.

## Outline

~~~markdown
## Testing done on the proposed changes

Setup: <map/lobby settings that matter>. Spawn:
```lua
<one CreateUnitAtMouse block>
```

1. <UI checks: option default, tooltip, labels>
   - [ ] <expected result>
2. <exhaustive check of the new behavior, e.g. every option state>
   - [ ] <expected result>
3. <one test per user-facing case the PR is for, reusing the setup>
   - [ ] <expected result>
4. <regression checks for paths the change touches>
   - [ ] <expected result>
~~~

Write each checkbox as an observable result ("the health bar drops", "the order line follows the unit"), not as an action.

## Setup

- Leave out what every test needs: checking out the branch, launching the game, starting a skirmish with cheats on. Only list settings that change the result.
- Don't add an AI to get an enemy. Maps made with the modern map editor have a hostile civilian army (`ARMY_17`) and a neutral one (`NEUTRAL_CIVILIAN`). Civilians are enemies by default (lobby option "Civilians"), and their brains don't give orders, so spawned units stay where they are. Only some of the original maps lack these armies.
- Spawn every unit the procedure needs, your own and hostile, in a single copyable block of `CreateUnitAtMouse(blueprintId, army, offsetX, offsetZ, rotation)` calls:

  ```lua
  CreateUnitAtMouse('ueb2108', GetFocusArmy() - 1,  -5.00,   0.00, 0)
  CreateUnitAtMouse('ueb2305', GetFocusArmy() - 1,   5.00,   0.00, 0)
  CreateUnitAtMouse('xrl0403', 1,                     0.00, 120.00, 0)
  ```

  - `CreateUnitAtMouse` takes a 0-indexed army. `GetFocusArmy()` and sim functions such as `CreateUnitHPR` are 1-indexed. Use `GetFocusArmy() - 1` for your own units. In a solo skirmish, army `1` is the hostile civilian army.
  - Space units with the offsets: about 15 apart for experimentals. Place units far away when distance matters to the test (projectile arcs, ranges).
- Console snippets are run with the "Execute Paste Buffer" debug hotkey, which runs the clipboard as UI Lua. Give plain UI Lua without a `UI_Lua` prefix. Wrap sim code as `ConExecute[[SimLua <code>]]`, with a literal space after `SimLua`.
- When a test needs a moving unit, make it reusable: issue a patrol in the sim instead of a single move that the tester has to race. The snippet below spawns a hostile unit at the mouse that patrols 40 units east and back:

  ```lua
  local p = GetMouseWorldPos()
  ConExecute(string.format('SimLua IssuePatrol({CreateUnitHPR("xrl0305", 2, %.1f, %.1f, %.1f, 0, 0, 0)}, {%.1f, %.1f, %.1f})', p[1], p[2], p[3], p[1] + 40, p[2], p[3]))
  ```

## Order and scope

- Follow reading order. Every step only depends on steps above it: spawn a unit before the step that uses it, and explain how to observe a result before the first step that needs it.
- Start with the UI checks (option default on a fresh profile, tooltip, labels). They come before anything that changes the options.
- Test the full matrix of a new behavior once, e.g. every option state with and without its modifier key. Later tests then say "target the unit" or "target the ground" instead of changing options again. When an option has modifier-key states, use them to switch behavior instead of reopening the options menu.
- Merge tests that share setup. One spawn block and one moving target can serve several cases.
- Skip paths the change doesn't touch, and don't repeat a test for callers that share the changed function. Name the shared function in the PR so reviewers can see why.
- Check the mechanics in the blueprints and scripts before writing timings or expected results. For example, tactical missile launchers reload between launches even with a full silo, so a test of queued launches can start with full ammo.
- When the outcome has randomness (missile scatter, damage spread), describe the expected result as a comparison ("more consistent than ground-fire"), not an exact count.
- Use the game's real controls: right-click leaves a command mode, Shift shows the command queue.

## After testing

Tick the boxes in the PR and note any result that differed from the expectation. If a test turned out to be unnecessary, remove it rather than leaving it unticked.

## Example

From [#7331](https://github.com/FAForever/fa/pull/7331), which adds an option for launch commands to ignore units under the cursor:

~~~markdown
Setup: any map with a hostile civilian army. Spawn:
```lua
CreateUnitAtMouse('ueb2108', GetFocusArmy() - 1,   0.00,   0.00, 0)
CreateUnitAtMouse('xrl0403', 1,                     0.00, 150.00, 0)
CreateUnitAtMouse('ueb1202', 1,                    40.00,  60.00, 0)
CreateUnitAtMouse('ueb1106', 1,                    38.00,  60.00, 0)
CreateUnitAtMouse('ueb1106', 1,                    42.00,  60.00, 0)
```
Select the launcher and give it missiles:
```lua
ConExecute[[SimLua for _, u in ipairs(DebugGetSelection()) do if EntityCategoryContains(categories.TACTICALMISSILEPLATFORM, u) then u:GiveTacticalSiloAmmo(5) end end]]
```

1. UI
   - [ ] "Launch commands ignore units" defaults to Always on a fresh profile
   - [ ] Its tooltip shows the title and description
2. With the mouse over open ground, spawn a hostile Brick that patrols east and back:
   ```lua
   local p = GetMouseWorldPos()
   ConExecute(string.format('SimLua IssuePatrol({CreateUnitHPR("xrl0305", 2, %.1f, %.1f, %.1f, 0, 0, 0)}, {%.1f, %.1f, %.1f})', p[1], p[2], p[3], p[1] + 40, p[2], p[3]))
   ```
   Holding Shift shows whether a launch order's line follows the unit or stays on the ground.
   For each option state, launch at the Brick with and without Ctrl. Nukes share the code path (`WorldView.UpdateLaunchIgnoreMode`), so the TML covers both:
   - [ ] Always: ground / ground. Unless Ctrl: unit / ground. Only with Ctrl: ground / unit. Never: unit / unit
   - [ ] Pressing Ctrl in launch mode toggles the hover highlight immediately
   - [ ] Shift+Ctrl queues launches with the Ctrl behavior
3. Megalith (far away, so the missile arc is shallow)
   - [ ] Ground-fire flies under it. Targeting the unit hits its hitbox center
4. T2 mex with storages
   - [ ] Targeting the mex gives more consistent storage kills than ground-fire (some scatter remains)
5. Shift-queue several launches at the patrolling Brick
   - [ ] Each missile fires at the Brick's position at launch time
6. Regressions
   - [ ] After right-clicking out of launch mode, selection works normally
   - [ ] Switching from launch to reclaim mode restores normal hover
~~~
