--******************************************************************************************************
--** Copyright (c) 2026 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

-- The lobby session's "main trash bag".
--
-- The custom lobby runs in the persistent *front-end* Lua state. That state is NOT reset when a
-- game launches in its own state, so anything we leave reachable after launch (or after leaving) —
-- a running thread, a cached table, a model singleton — leaks for the whole match. We need exactly
-- one call that frees *everything* lobby-scoped.
--
-- This module owns a single session-lifetime `TrashBag`. Every lobby-scoped singleton that owns
-- resources (models, catalogs, the interface, the lobby instance) is a `Destroyable` added to it,
-- so `Teardown()` frees the lot at once and `GetTrash()` hands every owner the same bag.
--
-- Why a TrashBag works here even though it is **weak-valued** (`__mode = 'v'`, see
-- /lua/system/trashbag.lua): a weak bag only holds things kept alive by a strong reference
-- elsewhere. That is precisely our singletons — each is pinned by its own module-level `Instance`
-- local, so the bag can still reach it at teardown but is never the reason it survives GC. A bare
-- `{ Destroy = fn }` disposable with no other owner would be collected before teardown; a real
-- singleton object will not. So: make resources real `ClassSimple` objects that implement
-- `Destroy`, pin them in their module local, and drop them in this bag.

---@type TrashBag | false
local SessionTrash = false

--- The session-lifetime trash bag. Lazily created; lives until `Teardown()`. Add any lobby-scoped
--- `Destroyable` (a model, a catalog, the interface, the lobby instance) to it.
---@return TrashBag
function GetTrash()
    if not SessionTrash then
        SessionTrash = TrashBag()
    end
    return SessionTrash
end

--- Frees everything added to the session trash (models, catalogs, threads, UI, the lobby instance)
--- and starts a fresh bag for the next session. Idempotent — safe to call as a clean-slate guard at
--- the top of `CreateLobby`, and on both teardown paths (leave to menu, launch into the game).
function Teardown()
    if SessionTrash then
        SessionTrash:Destroy()
        SessionTrash = false
    end
end
