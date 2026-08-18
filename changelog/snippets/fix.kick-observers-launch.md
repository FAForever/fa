- Fix UI lifetime crash and launch re-entrancy when host launches with observers disabled.

  Prevents double-destroy crash when the confirmation dialog callback destroys the parent lobby GUI and prevents rapid double-clicking from triggering multiple launches.
