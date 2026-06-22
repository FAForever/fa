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

-- The mod catalog: the custom lobby's list of selectable mods, the mod-side counterpart to
-- CustomLobbyMapCatalog.
--
-- Like the map catalog, this is *reference data*, NOT a model — it's identical on every peer
-- (each enumerates its own disk) and never goes on the wire. Only the host's *choice* of sim
-- mods (the launch model's `GameMods`) and each peer's UI-mod choice (prefs) sync/persist; the
-- catalog is just the menu they pick from. See the `customlobby-model-choice` skill.
--
-- It builds normalized, display-ready `UILobbyModInfo` entries (classified type, formatted
-- name / version / author, resolved dependency sets) from `ModUtilities`, the UI mod helper that
-- fronts `/lua/mods.lua`. Classification runs `GetDependencies` per mod, so we stream the build
-- across frames in batches and re-fire the `Mods` LazyVar as each batch lands — the dialog shows
-- a live "N mods loaded" count and fills in progressively, exactly like the map list.

local Create = import("/lua/lazyvar.lua").Create

-- the single point of contact with the mod domain layer (which in turn fronts /lua/mods.lua)
local ModUtilities = import("/lua/ui/modutilities.lua")

local FallbackIcon = '/textures/ui/common/dialogs/mod-manager/generic-icon_bmp.dds'

-- mods classified per frame-slice before yielding — keeps the open responsive
local BatchSize = 5

--- The growing list of selectable mods. Re-fired (new table ref) as batches land.
---@type LazyVar<UILobbyModInfo[]>
local ModList = Create({})

local Loading = false   -- a load thread is currently running
local Loaded = false    -- the disk has been fully enumerated + classified

-------------------------------------------------------------------------------
--#region Enumeration

--- Builds the normalized, display-ready entry for one raw `ModInfo`.
---@param mod ModInfo
---@return UILobbyModInfo
local function BuildEntry(mod)
    local dependencies = ModUtilities.GetDependencies(mod.uid)
    local icon = mod.icon
    if not icon or icon == "" or not DiskGetFileInfo(icon) then
        icon = FallbackIcon
    end

    ---@type UILobbyModInfo
    return {
        uid = mod.uid,
        name = mod.name or mod.uid,
        title = ModUtilities.FormatName(mod),
        versionText = ModUtilities.FormatVersion(mod),
        author = ModUtilities.FormatAuthor(mod),
        description = mod.description or "",
        copyright = mod.copyright,
        icon = icon,
        location = mod.location,
        ui_only = mod.ui_only and true or false,
        type = ModUtilities.Classify(mod),
        blacklistReason = ModUtilities.GetBlacklistReason(mod.uid),
        url = mod.url,
        github = mod.github,
        requires = dependencies.requires,
        missing = dependencies.missing,
        conflicts = dependencies.conflicts,
    }
end

---@param a UILobbyModInfo
---@param b UILobbyModInfo
---@return boolean
local function SortByTitle(a, b)
    return string.upper(a.title or "") < string.upper(b.title or "")
end

--- Publishes a fresh (sorted) copy of the accumulator so dependents go dirty.
---@param accumulator UILobbyModInfo[]
local function Publish(accumulator)
    local snapshot = table.copy(accumulator)
    table.sort(snapshot, SortByTitle)
    ModList:Set(snapshot)
end

--- Classifies every selectable mod across frames, streaming the entries into `ModList`.
local function LoadThread()
    local selectable = ModUtilities.GetSelectableMods()

    local accumulator = {}
    local seen = 0
    for _, mod in selectable do
        table.insert(accumulator, BuildEntry(mod))

        seen = seen + 1
        if math.mod(seen, BatchSize) == 0 then
            Publish(accumulator)
            WaitFrames(1)
        end
    end

    Loaded = true
    Loading = false
    Publish(accumulator)
end

--#endregion

-------------------------------------------------------------------------------
--#region Public API

--- Kicks off the enumeration if it hasn't run yet. Idempotent — safe to call on every open;
--- once loaded it's a no-op and the cached list stays.
function EnsureLoaded()
    if Loading or Loaded then
        return
    end
    Loading = true
    ModList:Set({})
    ForkThread(LoadThread)
end

--- The mods LazyVar — subscribe to it (via `Derive`) to react as the list streams in.
---@return LazyVar<UILobbyModInfo[]>
function GetModsVar()
    return ModList
end

--- The current (possibly partial) list of mods.
---@return UILobbyModInfo[]
function GetMods()
    return ModList()
end

--- How many mods are currently loaded.
---@return number
function GetCount()
    return table.getn(ModList())
end

--- Whether the disk has been fully enumerated (vs. still streaming).
---@return boolean
function IsLoaded()
    return Loaded
end

--- Finds the loaded mod with the given uid, or nil.
---@param uid string | false
---@return UILobbyModInfo | nil
function FindByUid(uid)
    if not uid then
        return nil
    end
    for _, mod in ModList() do
        if mod.uid == uid then
            return mod
        end
    end
    return nil
end

--- Drops everything so the next `EnsureLoaded` re-reads from disk (e.g. mods changed on disk).
function Refresh()
    Loaded = false
    Loading = false
    ModUtilities.Refresh()
    ModList:Set({})
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: re-imports this module after a couple of frames. The list rebuilds on the
--- next access, so dropping the cache is harmless.
function __moduleinfo.OnDirty()
    ForkThread(
        function()
            WaitFrames(2)
            import(__moduleinfo.name)
        end
    )
end

--#endregion
