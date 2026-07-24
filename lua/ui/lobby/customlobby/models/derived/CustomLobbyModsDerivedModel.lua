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

-- ============================================================================================
-- DERIVED MODEL — read-only. See /lua/ui/lobby/customlobby/models/derived/CLAUDE.md.
--
-- A derived model is a pure function of the authoritative models: it resolves a compact synced field
-- into a rich, ready-to-read bundle and exposes it reactively. Views read it; the **controller never
-- writes it** (there are no write helpers) — to change what it holds, change the source it derives
-- from. That keeps the launch model the single source of truth and this a cache/projection.
-- ============================================================================================
--
-- The **derived mods**: the lobby's enabled mods come in two flavours, each stored as a uid set —
--   * **game** (sim) mods — the launch model's `GameMods`, host-dictated + synced;
--   * **UI** mods — this peer's own choice, in prefs (`ModUtilities.GetSelectedUIMods`), never synced.
-- A uid on its own says nothing about the mod, so this model joins each uid to its `ModInfo` (from
-- `/lua/mods.lua`) and **enriches** it with display name / icon / author / version — so the Mods panel
-- (and the tab badge) just read those fields instead of resolving uids and formatting them itself.
--
-- Unlike scenario / restriction data this needs no disk load or `__blueprints` — `Mods.AllMods()` is
-- already available synchronously in the lobby — which is why it's the simplest of the derived models.
--
-- NOTE on icons: the mod-select *dialog* keeps its list text-only because one distinct texture per row
-- over a big vault leaks (see modselect/CLAUDE.md). Here we only ever show the **enabled** mods (a
-- handful), and re-rendering reuses the engine's by-name texture cache, so the icon count is bounded —
-- the same bounded trickle the single map preview accepts.
--
-- LIFETIME. It is a `ClassSimple` singleton implementing `Destroyable`, registered in the session
-- trash bag (see CustomLobbySession) on first access, so one `CustomLobbySession.Teardown()` frees its
-- `Mods` LazyVar and severs its launch-model subscription instead of leaking them for the whole match.
-- The module functions are thin facades. See the scenario derived model + the map catalog for the
-- pattern.

local Create = import("/lua/lazyvar.lua").Create
local Derive = import("/lua/lazyvar.lua").Derive
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/models/customlobbylaunchmodel.lua")
local CustomLobbySession = import("/lua/ui/lobby/customlobby/customlobbysession.lua")
local ModUtilities = import("/lua/ui/modutilities.lua")
local Mods = import("/lua/mods.lua")

-- shown when a mod declares no icon (or its icon file is missing) — matches the mod-select catalog
local FallbackIcon = '/textures/ui/common/dialogs/mod-manager/generic-icon_bmp.dds'

-------------------------------------------------------------------------------
--#region Shape

--- One enriched enabled mod.
---@class UICustomLobbyMod
---@field Uid     string
---@field Name    string          # formatted display name (version suffix stripped, capitalised)
---@field Icon    string          # icon texture path — always set (FallbackIcon when the mod has none)
---@field Author  string          # formatted author ("UNKNOWN" when none)
---@field Version string          # formatted version ("vN", or "" when none)
---@field UiOnly  boolean

--- A group of enabled mods (game / ui).
---@class UICustomLobbyModGroup
---@field Key   'game' | 'ui'
---@field Title string
---@field Mods  UICustomLobbyMod[]   # sorted by name

--- The fully-derived mods view.
---@class UICustomLobbyMods
---@field Groups    UICustomLobbyModGroup[]   # always two, in order: game, ui
---@field GameCount number
---@field UiCount   number

--#endregion

-------------------------------------------------------------------------------
--#region Derived model

-- The singleton, forward-declared above the class so the class methods (`Destroy`) capture it as an
-- upvalue. Assigned in `SetupSingleton`, cleared in `Destroy`.
---@type UICustomLobbyModsDerivedModel | nil
local Instance = nil

--- Enriches one mod uid against the all-mods table; returns a minimal entry for an unknown uid.
---@param uid string
---@param allMods table<string, ModInfo>
---@return UICustomLobbyMod
local function EnrichMod(uid, allMods)
    local mod = allMods[uid]
    if not mod then
        return { Uid = uid, Name = uid, Icon = FallbackIcon, Author = "", Version = "", UiOnly = false }
    end

    local icon = mod.icon
    if not icon or icon == "" or not DiskGetFileInfo(icon) then
        icon = FallbackIcon
    end
    return {
        Uid = uid,
        Name = ModUtilities.FormatName(mod),
        Icon = icon,
        Author = ModUtilities.FormatAuthor(mod),
        Version = ModUtilities.FormatVersion(mod),
        UiOnly = mod.ui_only and true or false,
    }
end

--- Builds the enriched, name-sorted mod list for one uid set.
---@param uidSet table<string, true>
---@param allMods table<string, ModInfo>
---@return UICustomLobbyMod[]
local function BuildGroup(uidSet, allMods)
    local mods = {}
    for uid in uidSet do
        table.insert(mods, EnrichMod(uid, allMods))
    end
    table.sort(mods, function(a, b) return string.upper(a.Name) < string.upper(b.Name) end)
    return mods
end

--- Builds the full mods bundle (game + ui groups + counts) from the current uid sets.
---@param gameMods table<string, true>
---@param uiMods table<string, true>
---@return UICustomLobbyMods
local function BuildMods(gameMods, uiMods)
    local allMods = Mods.AllMods()
    local game = BuildGroup(gameMods, allMods)
    local ui = BuildGroup(uiMods, allMods)
    return {
        Groups = {
            { Key = 'game', Title = "Game mods", Mods = game },
            { Key = 'ui',   Title = "UI mods",   Mods = ui },
        },
        GameCount = table.getn(game),
        UiCount = table.getn(ui),
    }
end

--- Reactive derived-mods singleton — a `ClassSimple` implementing `Destroyable`, registered in the
--- session trash so one `CustomLobbySession.Teardown()` frees it. **Read-only** — no write helpers;
--- the controller never touches it. It re-derives from the launch model's `GameMods` (+ UI-mod prefs).
---@class UICustomLobbyModsDerivedModel : Destroyable
---@field Trash          TrashBag                # owns the Mods var + the observer (freed on Destroy)
---@field Mods           LazyVar<UICustomLobbyMods>
---@field Observer       LazyVar                  # internal: re-derives on GameMods change
---@field LoadedSignature string | false          # signature of the last-published game+ui sets — the de-dup key
---@field Destroyed      boolean
local ModsModel = ClassSimple {

    ---@param self UICustomLobbyModsDerivedModel
    __init = function(self)
        self.Trash = TrashBag()
        self.Mods = self.Trash:Add(Create({ Groups = {}, GameCount = 0, UiCount = 0 }))
        self.LoadedSignature = false
        self.Destroyed = false

        -- re-derive now and whenever the (reactive) sim mods change (`Derive` fires synchronously on
        -- creation). Pinned on `self.Observer` AND in the trash, so it isn't GC'd and Destroy frees it.
        local launch = CustomLobbyLaunchModel.GetSingleton()
        self.Observer = self.Trash:Add(Derive(launch.GameMods, function(lazy)
            lazy()
            self:Recompute()
        end))
    end,

    --- Re-derives the mods bundle from the current launch state + UI-mod prefs and publishes it —
    --- unless the enabled game+ui sets are unchanged, in which case it's a no-op (the de-dup): the host
    --- re-sets `GameMods` to an equal value on every launch-info rebroadcast, so without this the Mods
    --- panel would rebuild its icon rows on every unrelated option change.
    --- NOTE: UI mods are prefs, not a reactive field, so they're re-read here whenever the (reactive)
    --- sim mods change — the "good enough until the mod dialog is rewired" caveat the panel/badge had.
    ---@param self UICustomLobbyModsDerivedModel
    Recompute = function(self)
        local gameMods = CustomLobbyLaunchModel.GetSingleton().GameMods()
        local uiMods = ModUtilities.GetSelectedUIMods()
        -- order-independent signature of the enabled game + ui sets (sorted uids joined); "\1" between
        -- uids and "\2" between the two sets so {game={A}} and {ui={A}} can't share a signature
        local signature = table.concatkeys(gameMods, "\1") .. "\2" .. table.concatkeys(uiMods, "\1")
        if signature == self.LoadedSignature then
            return
        end
        self.LoadedSignature = signature
        self.Mods:Set(BuildMods(gameMods, uiMods))
    end,

    --- `Destroyable`: frees the `Mods` var + the observer subscription and clears the module singleton,
    --- so the next access rebuilds and re-registers in the next session's trash. Idempotent.
    ---@param self UICustomLobbyModsDerivedModel
    Destroy = function(self)
        if self.Destroyed then
            return
        end
        self.Destroyed = true
        self.Trash:Destroy()       -- frees the Mods LazyVar + the launch-model subscription
        if Instance == self then
            Instance = nil
        end
    end,
}

--- Allocates a fresh mods-model singleton and registers it in the session trash. (Because `Derive`
--- fires synchronously on creation, the current mods resolve immediately.)
---@return UICustomLobbyModsDerivedModel
function SetupSingleton()
    Instance = ModsModel()
    CustomLobbySession.GetTrash():Add(Instance)
    return Instance
end

--- Returns the mods-model singleton, creating (and registering) it on first access — including after
--- a teardown, so it is reusable across lobby sessions.
---@return UICustomLobbyModsDerivedModel
function GetSingleton()
    if not Instance then
        SetupSingleton()
    end
    return Instance --[[@as UICustomLobbyModsDerivedModel]]
end

--#endregion

-------------------------------------------------------------------------------
--#region Accessors

--- The reactive mods var — subscribe to it (via `Derive`) to react when the sim mods change.
---@return LazyVar<UICustomLobbyMods>
function GetModsVar()
    return GetSingleton().Mods
end

--- The current enriched mods bundle.
---@return UICustomLobbyMods
function GetMods()
    return GetSingleton().Mods()
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: destroy the old singleton (severing its subscription) and rebuild via the new
--- module so its observer re-subscribes and re-derives. The bundle is fully derived from the launch
--- model + prefs, so there is no state to copy across.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if Instance then
        Instance:Destroy()
        newModule.SetupSingleton()
    end
end

--- Hot-reload hook: re-imports this module after a couple of frames.
function __moduleinfo.OnDirty()
    ForkThread(
        function()
            WaitFrames(2)
            import(__moduleinfo.name)
        end
    )
end

--#endregion
