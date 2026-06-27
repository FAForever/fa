# Session teardown via `Destroyable` singletons + a main trash bag

Status: **in progress** — the map catalog is converted as the worked example; the rest of the
rollout is pending. This doc captures the pattern, the recipe, and the open decisions so we can
resume later.

## Problem

The custom lobby runs in the **persistent front-end Lua state**. That state is *not* reset when a
game launches in its own state. So anything we leave reachable after launch (or after leaving the
lobby) — a running `ForkThread`, a cached table, a model singleton — leaks for the **whole match**.
We need exactly one call that frees everything lobby-scoped.

A previous attempt used a strong list of teardown callbacks because `TrashBag` is **weak-valued**
(`__mode = 'v'`, see [`/lua/system/trashbag.lua`](/lua/system/trashbag.lua)) and so cannot hold a
bare `{ Destroy = fn }` disposable (it would be GC'd before teardown). That work was never committed.

## The pattern

Make each lobby-scoped resource a **real object** — a `ClassSimple` that implements `Destroy`
(the `Destroyable` interface) — and register it in **one session-lifetime `TrashBag`**. Then a
single `bag:Destroy()` frees the lot.

The weak-bag objection disappears: a weak bag only fails to hold things that nothing else
references. Each singleton is **pinned by its own module-level `Instance` local**, so the bag can
still reach it at teardown but is never the reason it survives GC. Make resources real objects,
pin them in their module local, drop them in the bag.

### The owner: `CustomLobbySession.lua`

A tiny module owning one session-lifetime bag:

- `GetTrash()` — hands every owner the same bag (lazily created).
- `Teardown()` — `bag:Destroy()` then start a fresh bag; idempotent.

`Teardown()` is called at three lifecycle points (all wired):

- top of `CreateLobby` (clean slate before building a new session),
- the leave path (escape handler in [`/lua/ui/lobby/lobby.lua`](/lua/ui/lobby/lobby.lua)),
- `OnGameLaunched` in [`CustomLobbyController.lua`](../CustomLobbyController.lua).

### The recipe (per resource)

1. Wrap the module state in a `ClassSimple` with an `__init` and a `Destroy`.
2. Forward-declare `local Instance` **above** the class so the class methods capture it as an
   upvalue (not a global — this trips `undefined-global` otherwise).
3. `Destroy`: idempotent (guard with a `Destroyed` flag), release real resources (kill threads,
   destroy the instance's own `Trash`), then `if Instance == self then Instance = nil end` so the
   next session rebuilds fresh.
4. `GetSingleton()` creates on first use and `CustomLobbySession.GetTrash():Add(Instance)`
   (self-registration), so it re-registers in each new session's bag.
5. Keep the public module functions as **thin facades** over the singleton so callers don't change
   (decision below).

### Worked example: the map catalog

[`mapselect/CustomLobbyMapCatalog.lua`](../mapselect/CustomLobbyMapCatalog.lua) is the reference
implementation. `UICustomLobbyMapCatalog : Destroyable`:

- `Destroy()` kills the in-flight load thread, drops the caches, destroys its own `Trash` (which
  frees the `Scenarios` LazyVar), and nils the module singleton.
- The load thread is tracked on `self.Worker` (**not** in the trash) so `Refresh()` can kill it
  while keeping the **same** `Scenarios` LazyVar — replacing the LazyVar would orphan the dialog's
  `Derive` subscribers.
- The module functions (`LoadInfo`, `LoadSave`, `GetScenarios`, …) are thin facades; the five call
  sites are untouched.

## Open decisions (settle before converting the interface)

1. **Teardown ordering — the main risk.** A flat `TrashBag` destroys in arbitrary order
   (`for k, trash in self`). Fine while resources are independent (today). But once the
   **interface** and the **models** are both in the bag, the UI's `Derive` observers point at the
   models' LazyVars. If a model is destroyed before the UI, an observer could fire into freed
   state. *Probably* safe — destroying a control empties its own trash, severing its observers, so
   the dependency edge is cut from whichever side dies first — but the old design used LIFO
   deliberately. **Decide:** either prove edge-severing makes order irrelevant, or keep the
   interface out of the shared bag and have it own its teardown (registering only a "nil my
   singleton" disposable).

2. **Facade: permanent or migration shim?** The catalog now has two surfaces — `Catalog:LoadInfo()`
   (object) and module `LoadInfo()` (delegating). Keeping it stabilises call sites; dropping it
   (`GetSingleton():LoadInfo()`) removes a layer but touches callers. Current lean: **keep** for
   query-style services like the catalog.

3. **Models stay free-function-style.** The three models are intentionally plain data tables with
   free-function writers (`SetPlayer(model, …)`) — the documented autolobby idiom. For them,
   `Destroy` should be **thin**: nil `ModelInstance`, let the LazyVars GC. Do **not** convert their
   write helpers to methods. Accept that "service" singletons (catalog: real methods) and "data"
   singletons (models: free functions + minimal `Destroy`) legitimately differ in shape.

### Minor wrinkles (non-blocking)

- Self-registration gives `GetSingleton()` a first-access side effect (mutates the session bag).
  Harmless given `Teardown()` is the clean-slate; a singleton touched before `CreateLobby` just gets
  rebuilt.
- Hot-reload: if the load thread is mid-stream when the file is saved, the old instance lives on
  (the thread is a GC root) streaming into a dead LazyVar until it finishes. Dev-only; the explicit
  `Destroy` gives us a hook if it ever matters.

## Rollout order (proposed)

1. ✅ Map catalog (done — reference implementation).
2. ✅ **All five derived models** ([`models/derived/`](../models/derived/CLAUDE.md)) — done. Each is a
   `ClassSimple : Destroyable` whose own `Trash` owns its published LazyVar(s) + its observer(s),
   registered in the session bag on first access, with an idempotent `Destroy` that severs the
   subscriptions and nils the module singleton; `OnReload` destroys-then-rebuilds. Per-session state
   that used to be module-locals moved onto the instance: scenario `self.LoadedFile`; restrictions
   `self.LoadedSignature`; mods `self.LoadedSignature` (it gained the dedup it lacked, via
   `table.concatkeys`); slots `self.LoadedSignature` + `self.LoadedTeamsSignature` + `self.Observers`;
   options `self.Schema` + `self.SchemaKey` (the cached schema). The set-based dedup uses stock
   `utils.lua` (`table.concatkeys` / `table.sorted` + `table.concat`) — no bespoke helper.
3. The three authoritative models (low-risk; per open decision #3 their write helpers stay free
   functions — the `ClassSimple` just adds an own `Trash` + a `Destroy` that frees the LazyVars and
   nils the singleton).
4. The mod catalog (mirror the map catalog).
5. ~~`CustomLobbyRules` map-dimension cache.~~ — N/A: `CustomLobbyRules` is now a **pure, stateless** kernel (all inputs passed in; the cached map-dimension lookup is gone), so it holds nothing to tear down.
6. The interface + performance popover — **after** the ordering decision (#1 above).
7. Track the lobby instance in the session bag (drop the manual `Instance:Destroy()` in lobby.lua).
