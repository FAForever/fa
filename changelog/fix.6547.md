- (#6547) Fix an issue with the navigational mesh on unexplored maps

The navigational mesh is used by AIs to understand the map. On unexplored maps the playable area is temporarily reduced to a very small fraction at the start of the map. This confuses the navigational mesh. We now introduce a check that if the current playable area is too small to be playable then we simply ignore it.

This should only trigger on unexplored maps.
