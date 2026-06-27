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
-- writes it** (there are no write helpers) — to change what it holds, change the source field it
-- derives from. That keeps the launch model the single source of truth and this a cache/projection.
-- ============================================================================================
--
-- The **derived unit restrictions**: the launch model stores restrictions in their most compact form —
-- a list of preset *keys* (e.g. `"T3"`, `"AIR"`). On its own that's just an identifier; what it
-- means (its display name, icon and tooltip) lives in the restriction-preset table in
-- `/lua/ui/lobby/unitsrestrictions.lua`. This model joins the two: it maps each active key to its
-- preset and exposes the enriched item — so consumers (the Restrictions panel, the tab badge) just
-- read `Name` / `Icon` / `Tooltip` instead of looking the preset up themselves.
--
-- NOTE: a restriction key can also be a **specific unit blueprint id** (not just a preset). Enriching
-- those with a real name + icon is **parked** — `__blueprints` isn't available in the lobby front-end,
-- so it needs the heavier `UnitsAnalyzer` path. See /lua/ui/lobby/customlobby/TODO.md. For now a
-- non-preset key falls through and shows as its raw id.

local Create = import("/lua/lazyvar.lua").Create
local Derive = import("/lua/lazyvar.lua").Derive
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/models/customlobbylaunchmodel.lua")
local UnitsRestrictions = import("/lua/ui/lobby/unitsrestrictions.lua")

-------------------------------------------------------------------------------
--#region Shape

--- One enriched restriction: a preset key joined with its preset definition.
---@class UICustomLobbyRestriction
---@field Key     string
---@field Name    string          # LOC'd display name (falls back to the key)
---@field Icon    string | false  # preset icon texture path, or false when the preset has none
---@field Tooltip string | false  # LOC'd tooltip body, or false when none

--- The fully-derived restrictions view.
---@class UICustomLobbyRestrictions
---@field Items UICustomLobbyRestriction[]   # one per active preset key, in the launch model's order
---@field Count number

--#endregion

-------------------------------------------------------------------------------
--#region Derived model

--- Reactive derived-restrictions singleton. **Read-only** — no write helpers; the controller never
--- touches it. It re-derives from the launch model's `Restrictions`.
---@class UICustomLobbyRestrictionsDerivedModel
---@field Restrictions LazyVar<UICustomLobbyRestrictions>
---@field Observer LazyVar

---@type UICustomLobbyRestrictionsDerivedModel | nil
local ModelInstance = nil

--- Signature of the preset-key set the bundle was last built from — the de-dup baseline, or false
--- before the first build. Restrictions are a *set*, so this is an order-independent signature (the
--- keys sorted + joined); a pure reorder of the same restrictions doesn't count as a change.
---@type string | false
local LoadedSignature = false

--- Resolves one restriction key into an enriched item — a preset (the common case), else a specific
--- unit blueprint, else an unknown key shown as-is.
---@param key string
---@param presets table<string, table>   # UnitsRestrictions.GetPresetsData()
---@return UICustomLobbyRestriction
local function EnrichKey(key, presets)
    local preset = presets[key]
    if preset then
        return {
            Key = key,
            Name = (preset.name and LOC(preset.name)) or key,
            Icon = preset.Icon or false,
            Tooltip = (preset.tooltip and LOC(preset.tooltip)) or false,
        }
    end

    -- a non-preset key is a specific unit blueprint id; enriching it with a real name + icon is
    -- parked (needs blueprints, which aren't loaded in the lobby front-end — see TODO.md), so for
    -- now it shows as its raw id
    return { Key = key, Name = key, Icon = false, Tooltip = false }
end

--- Builds the enriched, counted restrictions bundle from the active keys (presets and/or unit ids).
---@param keys string[]
---@return UICustomLobbyRestrictions
local function BuildRestrictions(keys)
    local presets = UnitsRestrictions.GetPresetsData()
    local items = {}
    for _, key in keys do
        table.insert(items, EnrichKey(key, presets))
    end
    return { Items = items, Count = table.getn(keys) }
end

--- Re-derives the restrictions bundle and publishes it — unless the active set is unchanged, in which
--- case it's a no-op (the de-dup): `LazyVar:Set` always re-fires, and the host re-sets `Restrictions`
--- to the same list on every launch-info rebroadcast, so without this the panel would rebuild its icon
--- rows on every unrelated option change.
---@param model UICustomLobbyRestrictionsDerivedModel
local function Recompute(model)
    local keys = CustomLobbyLaunchModel.GetSingleton().Restrictions()
    -- order-independent signature of the active keys (sorted, joined) — a reorder isn't a change
    local signature = table.concat(table.sorted(keys), "\1")
    if signature == LoadedSignature then
        return
    end
    LoadedSignature = signature
    model.Restrictions:Set(BuildRestrictions(keys))
end

--- Allocates a fresh restrictions-model singleton and wires its observer to the launch model's
--- `Restrictions`. The observer is pinned on the model so it isn't GC'd, and (because `Derive` fires
--- synchronously on creation) it resolves the current restrictions immediately.
---@return UICustomLobbyRestrictionsDerivedModel
function SetupSingleton()
    LoadedSignature = false

    ---@type UICustomLobbyRestrictionsDerivedModel
    local model = {
        Restrictions = Create({ Items = {}, Count = 0 }),
    }
    ModelInstance = model

    local launch = CustomLobbyLaunchModel.GetSingleton()
    model.Observer = Derive(launch.Restrictions, function(lazy)
        lazy()
        Recompute(model)
    end)

    return model
end

--- Returns the restrictions-model singleton, creating (and deriving the current restrictions) on
--- first access.
---@return UICustomLobbyRestrictionsDerivedModel
function GetSingleton()
    if not ModelInstance then
        SetupSingleton()
    end
    return ModelInstance --[[@as UICustomLobbyRestrictionsDerivedModel]]
end

--#endregion

-------------------------------------------------------------------------------
--#region Accessors

--- The reactive restrictions var — subscribe to it (via `Derive`) to react when restrictions change.
---@return LazyVar<UICustomLobbyRestrictions>
function GetRestrictionsVar()
    return GetSingleton().Restrictions
end

--- The current enriched restrictions bundle.
---@return UICustomLobbyRestrictions
function GetRestrictions()
    return GetSingleton().Restrictions()
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: rebuild the singleton so its observer re-subscribes and re-derives. The bundle is
--- fully derived from the launch model, so there is no state to copy across.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if ModelInstance then
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
