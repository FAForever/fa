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
-- The **derived scenario** state: the launch model stores the map in its most compact form — a single
-- `ScenarioFile` path. Turning that into something a view can use (name, size, player count, start
-- spots, resource/wreck markers, the map texture) means loading the scenario off disk. This model does
-- that fishing **once** and exposes the result, so every consumer (the map preview, the facts line, the
-- rules) just reads the field it needs instead of re-resolving the file itself.
--
-- It is reactive (a `Scenario` LazyVar) like the lobby models, but it is **derived, not authoritative**
-- — it holds no host-dictated state and never goes on the wire. It is purely a function of the launch
-- model's `ScenarioFile`.
--
-- **De-duplication.** `LazyVar:Set` always re-fires its observers, even when the value is unchanged —
-- and the host rebroadcasts the whole launch info (re-setting `ScenarioFile` to the *same* path) on any
-- option tweak. So an internal observer dedups by file: the same scenario arriving twice is a no-op,
-- and the `Scenario` var only re-fires (→ the preview reloads, the facts re-render) on an actual change.
--
-- Scenario is the first derived model. Mods (compact UUIDs → full mod info), restrictions and the slot
-- info are the planned siblings; they follow this same shape (see the folder's CLAUDE.md).
--
-- LIFETIME. It is a `ClassSimple` singleton implementing `Destroyable`, registered in the session
-- trash bag (see CustomLobbySession) on first access. So one `CustomLobbySession.Teardown()` frees its
-- `Scenario` LazyVar and severs its launch-model subscription, instead of leaking them into the
-- persistent front-end Lua state for the whole match. The module functions are thin facades over the
-- singleton. This is the first derived model converted to the singleton-teardown pattern; the catalog
-- (mapselect/CustomLobbyMapCatalog) is the original worked example.

local Create = import("/lua/lazyvar.lua").Create
local Derive = import("/lua/lazyvar.lua").Derive
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/models/customlobbylaunchmodel.lua")
local CustomLobbyMapCatalog = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapcatalog.lua")
local CustomLobbySession = import("/lua/ui/lobby/customlobby/customlobbysession.lua")

-------------------------------------------------------------------------------
--#region Shape

--- The fully-resolved current scenario. Holds the lightweight `_scenario.lua` info (the surface needs
--- it for the map texture + size) and the *extracted* save markers — never the raw save itself.
---@class UICustomLobbyScenario
---@field File         FileName                     # the file this was resolved from
---@field Info         UILobbyScenarioInfo          # _scenario.lua: preview, map, size, Configurations
---@field Markers      UICustomLobbyScenarioMarkers # extracted save bits (spawns + mass/hydro/wreck points)
---@field MaxDimension number                       # largest map dimension in ogrids (0 if unknown)
---@field ArmyCount    number                       # number of start spots the scenario declares
---@field Name         string                       # LOC'd display name
---@field Size         table | false                # {x, z} in ogrids, or false
---@field Version      number | false               # map_version, or false

--#endregion

-------------------------------------------------------------------------------
--#region Derived model

-- The singleton, forward-declared above the class so the class methods (`Destroy`) capture it as an
-- upvalue rather than resolving it as a global. Assigned in `SetupSingleton`, cleared in `Destroy`.
---@type UICustomLobbyScenarioDerivedModel | nil
local Instance = nil

--- Number of start spots a scenario declares, from its standard configuration (0 if none).
---@param info UILobbyScenarioInfo
---@return number
local function ArmyCount(info)
    local armies = info.Configurations
        and info.Configurations.standard
        and info.Configurations.standard.teams
        and info.Configurations.standard.teams[1]
        and info.Configurations.standard.teams[1].armies
    return armies and table.getsize(armies) or 0
end

--- Resolves a scenario file into the rich bundle (the one place the disk work happens), or false if
--- the file can't be read. Reuses the catalog's loaders — no new disk code here.
---@param file FileName
---@return UICustomLobbyScenario | false
local function Resolve(file)
    local info = CustomLobbyMapCatalog.LoadInfo(file)
    if type(info) ~= "table" then
        return false
    end

    local size = info.size or false
    local maxDimension = 0
    if size then
        maxDimension = math.max(size[1] or 0, size[2] or 0)
    end

    return {
        File = file,
        Info = info,
        Markers = CustomLobbyMapCatalog.LoadMarkers(info),
        MaxDimension = maxDimension,
        ArmyCount = ArmyCount(info),
        Name = LOC(info.name) or "?",
        Size = size,
        Version = info.map_version or false,
    }
end

--- Reactive derived-scenario singleton — a `ClassSimple` implementing `Destroyable`, registered in
--- the session trash so one `CustomLobbySession.Teardown()` frees it. **Read-only** — no write
--- helpers; the controller never touches it. It re-derives from the launch model's `ScenarioFile`.
---@class UICustomLobbyScenarioDerivedModel : Destroyable
---@field Trash      TrashBag                                  # owns the Scenario var + the observer (freed on Destroy)
---@field Scenario   LazyVar<UICustomLobbyScenario | false>    # the resolved scenario, or false when none / unreadable
---@field Observer   LazyVar                                   # internal: resolves ScenarioFile (deduped)
---@field LoadedFile string | false                            # the file currently resolved (lowercased) — the de-dup key
---@field Destroyed  boolean
local ScenarioModel = ClassSimple {

    ---@param self UICustomLobbyScenarioDerivedModel
    __init = function(self)
        self.Trash = TrashBag()
        self.Scenario = self.Trash:Add(Create(false))
        self.LoadedFile = false
        self.Destroyed = false

        -- resolve the current scenario now and on every change (`Derive` fires synchronously on
        -- creation). Pinned on `self.Observer` AND in the trash, so it isn't GC'd and Destroy frees it.
        local launch = CustomLobbyLaunchModel.GetSingleton()
        self.Observer = self.Trash:Add(Derive(launch.ScenarioFile, function(scenarioFileLazy)
            self:OnScenarioFileChanged(scenarioFileLazy())
        end))
    end,

    --- Resolves `file` into the bundle, but skips the work (and the re-fire) when it is the same
    --- scenario we already hold — that is the de-dup.
    ---@param self UICustomLobbyScenarioDerivedModel
    ---@param file FileName | false
    OnScenarioFileChanged = function(self, file)
        local key = (type(file) == "string") and string.lower(file) or false
        if key == self.LoadedFile then
            return
        end
        self.LoadedFile = key

        if not file then
            self.Scenario:Set(false)
            return
        end
        self.Scenario:Set(Resolve(file) or false)
    end,

    --- `Destroyable`: frees the `Scenario` var + the observer subscription (so it stops firing) and
    --- clears the module singleton, so the next access rebuilds a fresh model and re-registers it in
    --- the next session's trash. Idempotent. Called by the session trash on `Teardown()`.
    ---@param self UICustomLobbyScenarioDerivedModel
    Destroy = function(self)
        if self.Destroyed then
            return
        end
        self.Destroyed = true
        self.Trash:Destroy()       -- frees the Scenario LazyVar + the launch-model subscription
        if Instance == self then
            Instance = nil
        end
    end,
}

--- Allocates a fresh scenario-model singleton and registers it in the session trash. (Because `Derive`
--- fires synchronously on creation, the current scenario resolves immediately.)
---@return UICustomLobbyScenarioDerivedModel
function SetupSingleton()
    Instance = ScenarioModel()
    CustomLobbySession.GetTrash():Add(Instance)
    return Instance
end

--- Returns the scenario-model singleton, creating (and registering) it on first access — including
--- after a teardown, so it is reusable across lobby sessions.
---@return UICustomLobbyScenarioDerivedModel
function GetSingleton()
    if not Instance then
        SetupSingleton()
    end
    return Instance --[[@as UICustomLobbyScenarioDerivedModel]]
end

--#endregion

-------------------------------------------------------------------------------
--#region Accessors

--- The reactive scenario var — subscribe to it (via `Derive`) to react when the map actually changes.
---@return LazyVar<UICustomLobbyScenario | false>
function GetScenarioVar()
    return GetSingleton().Scenario
end

--- The current resolved scenario (or false when no map / unreadable). For pull-based callers (rules).
---@return UICustomLobbyScenario | false
function GetScenario()
    return GetSingleton().Scenario()
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: destroy the old singleton (severing its subscription) and rebuild via the new
--- module so its observer re-subscribes and re-resolves the current scenario. The bundle is fully
--- derived from `ScenarioFile`, so there is no state to copy across.
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
