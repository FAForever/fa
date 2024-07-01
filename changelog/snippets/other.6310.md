- (#6310) Enhance the periodic logging of the session time.

The logging now differentiates between the session time and the game time. It also prints information about the allocated memory on the heap. This is useful for debugging memory issues.

As an example: `DEBUG: Session time: 00:35:01 Game time: 00:09:33 Heap: 288.0M / 253.2M`
