- (#6499) Apply new binary patch to Salem

Salem destroyer has special ability to move from water onto land. However in vanilla game this feature sometimes may cause problems with positioning of the unit and it's pathfinding. FAF introduced solution with a binary patch which makes it toggable ability to walk on land. 
But this solution had flows:
1. works only for salem: you can't make it work for other unit (mod one for example);
2. solution is unsafe: you can't restart game or replay because if any salem walks it just causes a crash;
3. solution uses weird way to do that toggle: it confuses doing this way;
4. this breaks filtering based on blueprint id.

With new assembly patch these flows are no more. This PR is about applying new assmbly fix.

## Description of the proposed changes
Applies patch changes and removes old ones.

## Testing done on the proposed changes
1. This patch can be applied to any other unit to achive same behavior (no example provided)
2. Start skirmish match. Spawn salem and make it walk. Restart match (not closing game). Spawn salem again and make it walk. Game works with no problems.
3. Function description isn't great since it relies on internal work of the game, but still it isn't done with `GetStat`.
4. Spawn 2 salems, make one of them go to land. Select one of them, press *ctrl-z* (select similar units) or with cltr-left-click, second one is selected too.


## Additional context
This change requires an asm [patch](https://github.com/FAForever/FA-Binary-Patches/pull/94).