# Performance

Read the root [AGENTS.md](AGENTS.md) first. Large games run thousands of units, and UI code often runs every frame. Standard Lua advice applies (locals over globals, no allocations or closures in hot loops, no string building per tick). The points below are specific to this engine and dialect. Most are measured in [lua/benchmarks/](lua/benchmarks/), where header comments record the results. Some of those results differ from what standard Lua would predict, so check the benchmark rather than assuming.

## Upvalue globals and methods

Cache engine globals, library functions, class methods and `moho.*_methods` entries as file-level locals. Do this in sim and UI hot paths alike. Reading an upvalue (GETUPVAL) is cheaper than a global or table lookup (GETTABLE), which is cheaper than a `:` call (SELF). [function-scope.lua](lua/benchmarks/function-scope.lua) measures this.

```lua
-- Upvalued for performance
local TrashBag = TrashBag
local TrashAdd = TrashBag.Add
local IsAlly = IsAlly
local TableGetn = table.getn
local EntityGetPosition = moho.entity_methods.GetPosition

-- in the hot path
local pos = EntityGetPosition(unit)   -- instead of unit:GetPosition()
TrashAdd(self.Trash, thread)          -- instead of self.Trash:Add(thread)
```

- Upvalue at file scope, not inside the loop. Fetching into a local on each iteration is slower than using the global ([math-generic.lua](lua/benchmarks/math-generic.lua)).
- [lua/sim/Unit.lua](lua/sim/Unit.lua) and [lua/system/trashbag.lua](lua/system/trashbag.lua) show the pattern. `trashbag.lua` has a copy-paste block of the `Trash*` upvalues.

## Cached values instead of engine calls

Crossing into C (a "CFunction" or a `moho` method) costs more than reading a Lua field. Sim objects cache common values such as `self.Blueprint` and `self.Army` as fields: read those instead of calling the getters ([lua/sim/AGENTS.md](lua/sim/AGENTS.md#cached-fields)). `ArmyBrains[i]` is 50–100x faster than `GetArmyBrain(i)` ([value-access.lua](lua/benchmarks/value-access.lua)). `unit.Dead`, `unit:BeenDestroyed()` and `IsDestroyed(unit)` look like a field-for-getter swap but aren't interchangeable ([Destroyed checks](lua/sim/AGENTS.md#destroyed-checks)).

## Other engine calls

- **Distances.** `VDist3` is fast thanks to an [engine patch](https://github.com/FAForever/FA-Binary-Patches/pull/54), so upvalue and use it ([VDist3.lua](lua/benchmarks/VDist3.lua)). `VDist2` is not patched: inline Lua math beats it. When you only compare distances, compare squared distances and skip the square root ([VDist2.lua](lua/benchmarks/VDist2.lua)).
- `ForkThread` costs far more than a function call ([function-threads.lua](lua/benchmarks/function-threads.lua)). Check the conditions that would end the thread at once *before* forking it.

## Iterate the fast way

From [table-loops.lua](lua/benchmarks/table-loops.lua), for a 20-element array:

| Loop | Relative cost |
|---|---|
| `for i = 1, TableGetn(t) do local v = t[i] ... end` | 1x |
| `for _, v in ipairs(t)` | ~16x |
| `for k, v in t` / `next` / `pairs` | ~26x |

- For arrays, use a numeric `for` with an upvalued `table.getn`. `ipairs` is much slower here than in standard Lua.
- For hash tables, `for k, v in t` is at least as fast as `pairs(t)`. LuaPlus compiles it by inserting a `getglobal next` as the iterator function, making it equivalent to `for k, v in next, t`. Upvaluing `next` gives no measurable gain.
- Don't call `table.getn` on every insert. Keep a counter and assign `t[n] = v` ([table-insert.lua](lua/benchmarks/table-insert.lua)). Upvalue `table.insert` when you do use it.
- `table.getsize` and `table.empty` come from the engine (with Lua fallbacks in [lua/system/utils.lua](lua/system/utils.lua)). Use `table.empty(t)` instead of `table.getsize(t) == 0`.

## Cache table reads

Reading a table field costs a GETTABLE each time. When a function reads the same fields more than once, read them into locals first. The benchmarks show a large speedup even for a single use ([table-array.lua](lua/benchmarks/table-array.lua), [table-hash.lua](lua/benchmarks/table-hash.lua), [table-sub.lua](lua/benchmarks/table-sub.lua)).

```lua
local x1, y1, z1 = a[1], a[2], a[3]
local Defense = bp.Defense   -- instead of repeating bp.Defense.X
```

## Classes and metatables

- Method lookups walk the class `__index` chain. A table `__index` is much cheaper than a function `__index` ([metatables.lua](lua/benchmarks/metatables.lua)). For values read in hot paths, copy them onto the instance in `OnCreate` rather than resolving them through the chain each time. Measure first: in that benchmark, copying `ForkThread` onto the instance made it slower.

## Allocations

- Reuse vectors and tables in hot paths. Allocating a `Vector` per call is about 6x slower than filling a cached one, and puts pressure on the garbage collector ([memory.lua](lua/benchmarks/memory.lua)). `unit:GetPositionXYZ()` returns the components without allocating a vector, although it was barely faster than `GetPosition()` in that benchmark.
- Pre-allocate tables whose size you know with `{&h &a}`. Examples: [lua/lazyvar.lua](lua/lazyvar.lua) (`{&1 &8}`), [lua/system/categories.lua](lua/system/categories.lua) (`{&4 &0}`). Files using this syntax must be added to the skip list in `tests/run-syntax-test.sh`.
- Avoid creating closures per call when one can be defined once and reused ([function-closures.lua](lua/benchmarks/function-closures.lua)).

## Categories

Category expressions like `categories.AIR * categories.TECH3` create new category objects. Compute them once at file scope (or once per outer loop), not inside an `EntityCategoryContains` call in a hot path ([categories.lua](lua/benchmarks/categories.lua): 21 ms vs 130 ms). [lua/system/categories.lua](lua/system/categories.lua) now caches the results of `+`, `-` and `*` (99% hit rate in a recorded 1-hour game), so repeated inline expressions cost less than the benchmark shows. Upvaluing is still cheaper and clearer.

## Measuring

Benchmarks live in [lua/benchmarks/](lua/benchmarks/). Each file sets `ModuleName`, a `BenchmarkData` table mapping function names to display names, and benchmark functions that take a loop count and return elapsed seconds (`GetSystemTimeSecondsOnlyForProfileUse`). Run them in-game from the **Benchmarks** tab of the profiler window ([lua/ui/game/Profiler.lua](lua/ui/game/Profiler.lua), sim side in [lua/sim/Profiler.lua](lua/sim/Profiler.lua)). The runner subtracts the cost of an empty loop ([control.lua](lua/benchmarks/control.lua)). When you make a performance claim in a PR, add or extend a benchmark and record its results in the file's header comment.
