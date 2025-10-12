- (#6937) Implement the ability to adjust shield assist costs using the following blueprint values:

  - `RegenPerBuildRate`: How much HP/s is restored per unit of buildpower assisting the shield. Overrides `RegenAssistMult`.
  - `AssistCostEnergyPerBuildRate` and `AssistCostMassPerBuildRate`: The resource cost per second per unit of buildpower assisting the shield.

    Both values must be present to have an effect, otherwise it defaults to the repair cost of the shield structure (75% of its build cost).
  
    If both the HP and the shield of a unit are damaged, the assist cost and effects are split equally between the HP repair cost and shield assist costs.

  These values should be assigned in either the `Defense.Shield` or `Enhancements.<EnhancementName>` tables of the unit blueprint. 
  
  Please keep in mind that shield assist only works for units with the `SHIELD` category, and only if they're not upgrading themselves/building something.
