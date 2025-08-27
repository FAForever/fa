- (#6855) Fix issues with `Unit.GiveNukeSiloBlocks` (function that sets missile build progress for a unit, used in unit transfer):
  
  - Crash if used on a unit whose first weapon does not have a `ProjectileId` in its blueprint.
  - Setting incorrect progress for units whose first weapon is not the desired silo weapon (ex: missile SACU).
  - Setting incorrect progress for units with buildrate different from their blueprint spec (ex: missile SACU).
  - Yellow work progress bar not being updated after progress is set.
