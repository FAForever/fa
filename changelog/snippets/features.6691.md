- (#6691) Reduce delay of automatically pausing upgrades after assisting to 1 tick

This was initially 5 ticks, but apparently it also works after waiting just 1 tick. No resources are 'leaked' to the upgrade by waiting only 1 tick.
