- (#6398) Fix a possible cause for a simulation freeze

It was possible to pass invalid numbers (NaN or infinite) as a ballistic acceleration for a projectile. This would cause the engine to freeze up. With these changes we introduce Lua guards to catch the invalid numbers and throw an error instead of passing the invalid number to the engine.
