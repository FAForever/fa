- (#6691) Reduce delay of automatically pausing upgrades after assisting to 1 tick

This was initially 5 ticks. By waiting 5 ticks _some_ resources would be spent on the upgrade. After careful testing the feature appears to work fine when waiting just a single tick. And if we only wait a single tick then no resources are spent on the upgrade.
