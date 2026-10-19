# In-game test procedures

How to write a procedure for testing a PR in-game. The procedure goes in the PR's "Testing done on the proposed changes" section. A tester runs it in one sitting and ticks the boxes as they go, so it must read as a script, not a list of ideas.

The outline below fits a new feature or option. Other kinds of change replace or add steps, as listed under [Variants by change type](#variants-by-change-type).

## Outline

~~~markdown
## Testing done on the proposed changes

Tested on <commit SHA>.

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

Write each checkbox as an observable result ("the health bar drops", "the order line follows the unit"), not as an action. When the expected result isn't obvious, give the reason it should happen: the mechanic, code path or value it follows from. The tester can then tell a real failure from a wrong expectation.

Leave out who tested; the PR comment already shows that.

## Setup

- Leave out what every test needs: checking out the branch, launching the game, starting a skirmish with cheats on. Only list settings that change the result.
- Don't add an AI to get an enemy. Maps made with the modern map editor have a hostile civilian army (`ARMY_17`) and a neutral one (`NEUTRAL_CIVILIAN`). Civilians are enemies by default (lobby option "Civilians"), and their brains don't give orders, so spawned units stay where they are. Only some of the original maps lack these armies.
- Spawn every unit the procedure needs, your own and hostile, in a single copyable block of `CreateUnitAtMouse(blueprintId, army, offsetX, offsetZ, rotation)` calls. Automated tests spawn in the sim instead (see [Console commands and data](#console-commands-and-data)):

  ```lua
  CreateUnitAtMouse('ueb2108', GetFocusArmy() - 1,  -5.00,   0.00, 0)
  CreateUnitAtMouse('ueb2305', GetFocusArmy() - 1,   5.00,   0.00, 0)
  CreateUnitAtMouse('xrl0403', 1,                     0.00, 120.00, 0)
  ```

  - `CreateUnitAtMouse` takes a 0-indexed army. `GetFocusArmy()` and sim functions such as `CreateUnitHPR` are 1-indexed. Use `GetFocusArmy() - 1` for your own units. In a solo skirmish without AIs, army `1` is the hostile civilian army.
  - Space units with the offsets: about 15 apart for experimentals. Place units far away when distance matters to the test (projectile arcs, ranges).
- Console snippets are run with the "[Debug] Execute Paste Buffer" hotkey, which runs the clipboard as UI Lua. It has no default key, so testers bind it in the key bindings menu. Give plain UI Lua without a `UI_Lua` prefix. Wrap sim code as `ConExecute[[SimLua <code>]]`, with a literal space after `SimLua`.
- When a test needs a moving unit, make it reusable: give it a patrol loop in the sim instead of a single move that the tester has to race. A patrol loop needs two `IssuePatrol` orders, and the unit then walks the loop indefinitely. Step 2 of the [Example](#example) has a snippet.

## Order and scope

- Follow reading order. Every step only depends on steps above it: spawn a unit before the step that uses it, and explain how to observe a result before the first step that needs it.
- Start with the UI checks (option default on a fresh profile, tooltip, labels). They come before anything that changes the options.
- Test the full matrix of a new behavior once, e.g. every option state with and without its modifier key. Later tests then say "target the unit" or "target the ground" instead of changing options again. When an option has modifier-key states, use them to switch behavior instead of reopening the options menu.
- Merge tests that share setup. One spawn block and one moving target can serve several cases.
- Skip paths the change doesn't touch, and don't repeat a test for callers that share the changed function. Name the shared function in the PR so reviewers can see why.
- Check the mechanics in the blueprints and scripts before writing timings or expected results. For example, tactical missile launchers reload between launches even with a full silo, so a test of queued launches can start with full ammo.
- When the outcome has randomness (missile scatter, damage spread), describe the expected result as a comparison ("more consistent than ground-fire"), not an exact count.
- Use the game's real controls, such as right-click to leave a command mode or Shift to show the command queue.
- Pick edge cases that the code can actually reach and that differ from cases already tested. Read how the changed code keeps state first. For example, the launch ignore mode is recomputed from the option and modifier keys on every cursor update, so releasing Ctrl partway through is the same case as not holding it.
- For Lua changes, the last step checks the log (launch with `/showlog`) for new errors and warnings. This catches failures that are silent on screen.

## Console commands and data

Snippets can do more than spawn units. Use them to set up state, run the test and log the result, so the tester compares numbers instead of judging by eye:

- Console commands from [lua/keymap/debugKeyActions.lua](lua/keymap/debugKeyActions.lua) can go in a snippet with `ConExecute`, e.g. `dbg Collision` to draw hitboxes, `dbg weapons` for weapon ranges and `Nodamage`. `wld_RunWithTheWind 1` runs the sim as fast as possible for long tests, and `0` turns it off.
- A test that waits for an outcome runs entirely in the sim: spawn the units, set them up, speed up the sim, and fork a thread that waits for the outcome, logs it and cleans up. Template, with the test-specific parts as comments:

  ```lua
  local p = GetMouseWorldPos()
  local x, y, z, focusArmy = p[1], p[2], p[3], GetFocusArmy()
  ConExecute(string.format('SimLua local x, y, z, focusArmy = %f, %f, %f, %d\n', x, y, z, focusArmy) .. [[
  -- every entity created for the test, so they can be cleaned up
  local units = {
      -- CreateUnitHPR(bpId, army, x, y, z, 0, 0, 0),
      -- army: focusArmy for yours, 'ARMY_17' for hostile ones. Space units with offsets on x and z
  }
  -- set up state for the test, e.g. SetMaxHealth/SetHealth. For cross-army tests, SetAlliance and say in the step which army each unit is in
  SimConExecute('wld_RunWithTheWind 1')
  ForkThread(function()
      -- wait until the outcome, e.g. while not units[1].Dead do WaitTicks(1) end
      for _, u in units do
          if not IsDestroyed(u) then
              -- LOG the measured values, e.g. LOG(u.UnitId, ' health: ', u:GetHealth())
              u:Destroy()
          end
      end
      SimConExecute('wld_RunWithTheWind 0')
  end)
  ]]) -- intentionally on a new line
  ```

  - `CreateUnitHPR` also takes an army name. Use `'ARMY_17'` on any map that has it, because its index depends on the players and AIs in the lobby.
  - `focusArmy` is the tester's army, read in the UI. `GetFocusArmy()` in the sim returns each player's own army, so calling it there desyncs a local multiplayer test. Call it in the sim only when that is intended.
  - Only the mouse position and focus army go through `string.format`. The rest is a plain string, so commenting out the `ConExecute` line and the last line leaves normal Lua to edit with LuaLS, with the UI locals declaring the same names.
- When the data can only come from inside the changed code (timings, intermediate values, unit stats), put the logging in a test commit on a separate branch on top of the PR branch, and link it from the procedure. The PR branch stays clean, and the tester gets objective data points instead of impressions.

## Testing in live games

FAForever organization members can deploy a branch to the `FAF Beta Balance` or `FAF Develop` game types without merging it. They force-push it to `staging/fafbeta` or `staging/fafdevelop`, then run the matching deploy workflow ([deploy-fafbeta.yaml](.github/workflows/deploy-fafbeta.yaml), [deploy-fafdevelop.yaml](.github/workflows/deploy-fafdevelop.yaml)). The staging branches are reset from `develop` on a schedule, so the deploy is temporary. Force-pushing shared branches is outward-facing: only do it when the user explicitly asks. See [docs/deployment.md](docs/deployment.md).

## Variants by change type

Most PRs fit one of these. A PR that spans several uses the steps of each.

- **Feature or option:** the [outline](#outline) as written.
- **Bug fix:** the first step reproduces the bug on `develop` with exact steps, and the next step runs the same steps on the branch. Then regression checks. Leave out UI checks unless the fix changes the UI.
- **Balance and blueprint values:** expected results are numbers worked out from the change (damage per second, time to kill, range, build time). Measure them with a snippet that logs them, and compare them with `develop`. Skip the log check for value-only changes.
- **Performance:** only test performance when the changed code does many table operations or engine calls relative to how often it runs (every frame, every tick, for every unit). Judge that from how much similar code nearby avoids those operations (cached upvalues, preallocated tables). Time the code in a test commit, on `develop` and on the branch, and give both numbers.
- **Lobby and menus:** there are no units and no sim, so spawns and `SimLua` snippets don't apply; the steps are UI actions. Behavior between players needs several instances from [scripts/LaunchFAInstances.ps1](scripts/LaunchFAInstances.ps1).
- **UI that feeds the sim:** when UI code decides what gets sent to the sim (sim callbacks, orders built from local UI state), test with a host and a client from [scripts/LaunchFAInstances.ps1](scripts/LaunchFAInstances.ps1): do the action on one instance and check that the game doesn't desync. Other changes don't need this.

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
   ConExecute(string.format('SimLua local u = {CreateUnitHPR("xrl0305", 2, %.1f, %.1f, %.1f, 0, 0, 0)} IssuePatrol(u, {%.1f, %.1f, %.1f}) IssuePatrol(u, {%.1f, %.1f, %.1f})', p[1], p[2], p[3], p[1] + 40, p[2], p[3], p[1], p[2], p[3]))
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
