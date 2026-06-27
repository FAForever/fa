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
-- A derived model is a pure function of the authoritative models: it resolves compact synced fields
-- into a rich, ready-to-read bundle and exposes it reactively. Views read it; the **controller never
-- writes it** (there are no write helpers) — to change what it holds, change the source it derives
-- from. That keeps the launch / session / local models the single source of truth and this a projection.
-- ============================================================================================
--
-- The **derived slots**: a single lookup table, one entry per slot, that merges *every* model that has
-- something to say about a seat into one place so a slot view reads one field instead of joining four
-- models itself. Each entry combines —
--   * the seated **player** (launch model, synced) — name / colour / faction / team / ready;
--   * the scenario **placement** (the derived scenario model) — the start spot's map position, i.e.
--     *where* on the map this seat sits, plus the per-player unit cap the map size implies;
--   * the **closed** flag (session model, synced lobby-room state, not launched);
--   * the **CPU benchmark** (local model, per-peer, never synced and *not part of the game*) — the
--     sim-performance projection the slot shows as a unit count + green→red headroom indicator;
--   * the **binary auto-team side** (1/2/false) the seat resolves to, applied once from the rule in
--     `CustomLobbyRules` so the two-column layout reads `entry.Side` instead of re-resolving it.
-- The slot/faction/CPU formatting that used to live in each slot control now lives here, once, so the
-- presentations (the thin row + the fat card) are pure arrangement over a resolved view.
--
-- **Two read faces.** Per-seat `Slots` (the rows/cards) and the board's binary auto-team aggregate
-- `Teams` (the team-score strip — side labels + per-side rating totals). Each is deduped by its own
-- signature, so a player's *rating* change re-fires only `Teams` (a total moved) without re-rendering
-- the rows, and a mode/map change that moves the split re-fires both. The side rule itself stays in
-- `CustomLobbyRules` (the controller will reuse it at launch); this model only *applies* it once.
--
-- **Why one table, not a var per slot.** The CPU indicator's colour depends on the recommended unit
-- cap, which depends on the *total seated count* — so a seat filling anywhere restyles every other
-- seat's CPU bar. A per-slot var would leave those stale (only the changed slot's var fires); a single
-- table rebuilt whole keeps the whole board consistent. The user-facing model is literally "the slots,
-- looked up by index".
--
-- **De-duplication.** `LazyVar:Set` always re-fires, and the host rebroadcasts the whole launch info
-- (re-setting every `Players[slot]` to an equal value) on any option tweak. So the rebuild compares a
-- signature of the rendered fields and only re-publishes `Slots` when something visible actually
-- changed — a rebroadcast of an unchanged board is a no-op, not 16 needless re-renders per seat.

local Create = import("/lua/lazyvar.lua").Create
local Derive = import("/lua/lazyvar.lua").Derive
local GameColors = import("/lua/gamecolors.lua").GameColors
local Color = import("/lua/shared/color.lua")
local Factions = import("/lua/factions.lua").Factions

local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/models/customlobbylaunchmodel.lua")
local CustomLobbySessionModel = import("/lua/ui/lobby/customlobby/models/customlobbysessionmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/models/customlobbylocalmodel.lua")
local CustomLobbyScenarioDerivedModel = import("/lua/ui/lobby/customlobby/models/derived/customlobbyscenarioderivedmodel.lua")
local CustomLobbyRules = import("/lua/ui/lobby/customlobby/customlobbyrules.lua")

local MaxSlots = CustomLobbyLaunchModel.MaxSlots

-------------------------------------------------------------------------------
--#region Shape

--- The seated player's resolved presentation (false on an empty seat — the view paints "- open -").
---@class UICustomLobbySlotPlayerView
---@field colorHex   string
---@field name       string
---@field nameColor  string
---@field faction    string
---@field team       string
---@field ready      string
---@field readyColor string

--- The CPU column's resolved presentation (false when there is no player / no benchmark to show).
---@class UICustomLobbySlotCpuView
---@field text           string
---@field textColor      string
---@field indicatorColor Color | nil
---@field showIndicator  boolean

--- One fully-resolved slot: the merge of player (launch) + placement (scenario) + closed (session) +
--- CPU benchmark (local). Carries both the ready-to-paint views and the raw refs interaction needs.
---@class UICustomLobbySlot
---@field Slot       number                            # slot index 1..MaxSlots
---@field Player     UICustomLobbyPlayer | false       # the seated player (raw), false when empty — for intents/drag
---@field Closed     boolean                           # session: seat closed (no army at launch)
---@field StartSpot  number | false                    # the player's chosen start spot
---@field Position   table | false                     # {x, z} of that start spot on the map, or false
---@field Side       1 | 2 | false                     # binary auto-team side (keyed on start spot, else slot), false when none/unresolved
---@field PlayerView UICustomLobbySlotPlayerView | false
---@field CpuView    UICustomLobbySlotCpuView | false
---@field Benchmark  UIPerformanceMetrics | false      # raw metrics for the owner (the hover popover reads this)
---@field UnitCap    number | false                    # recommended cap used for the indicator (popover reads this)

--- The board's binary auto-team aggregate (the team-score strip reads this). Derived once from
--- `CustomLobbyRules` (the rule's home) over the resolved per-seat `Side`. `Labels` is false unless the
--- mode forms two well-defined sides; `Resolved` is false for a positional mode whose map isn't loaded.
---@class UICustomLobbyTeams
---@field Mode     string | false             # the binary AutoTeams mode (tvsb/lvsr/pvsi), or false
---@field Labels   table | false              # the two side labels {a, b}, or false for a non-binary mode
---@field Resolved boolean                     # whether the split is determined (false: positional mode, no map yet)
---@field Totals   table                       # accumulated rating per side {a, b}

--#endregion

-------------------------------------------------------------------------------
--#region Formatting (single-sourced here; the slot presentations are pure arrangement)

--- Short faction label for a faction index (5 = Random has no factions.lua entry).
---@param faction number
---@return string
local function FactionLabel(faction)
    local data = Factions[faction]
    if data then
        return data.DisplayName or data.Key or tostring(faction)
    end
    return "Random"
end

--- The sim-rate categories tracked in PerformanceTrackingV2, ordered for the "most-played" pick.
local PerformanceCategories = { 'Skirmish', 'SkirmishWithAI', 'Campaign' }

--- The bucket index for a sim rate (index k holds rate k - 11, so +0 -> 11, -4 -> 7).
---@param rate number
---@return number
local function BucketForRate(rate)
    return rate + 11
end

--- The most-played category in a benchmark, by sample count, or nil if none.
---@param metrics UIPerformanceMetrics | nil
---@return table | nil
local function PickCategory(metrics)
    if not metrics then
        return nil
    end
    local best, bestSamples = nil, -1
    for _, key in PerformanceCategories do
        local c = metrics[key]
        if c and (c.Samples or 0) > bestSamples then
            bestSamples = c.Samples or 0
            best = c
        end
    end
    if not best or bestSamples <= 0 then
        return nil
    end
    return best
end

--- Compact unit count for the slot label (e.g. 1421 -> "1.4k").
---@param value number
---@return string
local function FormatUnits(value)
    if value >= 1000 then
        return string.format("%.1fk", value / 1000)
    end
    return tostring(math.floor(value + 0.5))
end

--- Indicator colour for how far the sim has to slow down to sustain the cap: green when +0 already
--- suffices (step 0), fading to red at -4 or worse (step 4).
---@param step number   # sim-rate steps below +0 needed to reach the cap (0..4)
---@return Color
local function StepColor(step)
    local t = math.clamp(step / 4, 0.0, 1.0)
    local hue = (1.0 - t) * 0.333   -- 0.333 turns = green, 0 = red
    return Color.ColorHSV(hue, 1.0, 0.85, 1.0)
end

--- The player presentation for a seated player.
---@param player UICustomLobbyPlayer
---@return UICustomLobbySlotPlayerView
local function BuildPlayerView(player)
    return {
        colorHex = GameColors.PlayerColors[player.PlayerColor] or 'ffffffff',
        name = player.PlayerName or "?",
        nameColor = player.Human and 'ffffffff' or 'ffd9c97a',
        faction = FactionLabel(player.Faction),
        team = (player.Team and player.Team > 1) and ("T" .. (player.Team - 1)) or "-",
        ready = player.Ready and "ready" or "",
        readyColor = player.Ready and 'ff7ad97a' or 'ff888888',
    }
end

--- The CPU presentation for a seated player from its shared sim-performance benchmark: the label is the
--- max units the machine handled at full speed (+0), and the indicator is green if that already covers
--- the recommended cap, fading to red the further the sim must slow (down to -4). Returns false when
--- there is no benchmark to show.
---@param metrics UIPerformanceMetrics | nil
---@param cap number | nil
---@return UICustomLobbySlotCpuView | false
local function BuildCpuView(metrics, cap)
    local category = PickCategory(metrics)
    local atZero = category and category[BucketForRate(0)]
    if not (atZero and atZero.UnitCount) then
        return { text = "—", textColor = 'ff9aa0a8', showIndicator = false }
    end

    local maxAtZero = atZero.UnitCount.Max or 0
    local view = { text = FormatUnits(maxAtZero), textColor = 'ff9aa0a8', showIndicator = false }

    if cap and cap > 0 then
        -- how many sim-rate steps below +0 are needed before the machine sustains the cap (0 = fine at
        -- +0); worst case (red) if even -4 falls short
        local step = 0
        if maxAtZero < cap then
            step = 4
            for s = 1, 4 do
                local bucket = category[BucketForRate(-s)]
                if bucket and bucket.UnitCount and (bucket.UnitCount.Max or 0) >= cap then
                    step = s
                    break
                end
            end
        end
        view.indicatorColor = StepColor(step)
        view.showIndicator = true
    end

    return view
end

--#endregion

-------------------------------------------------------------------------------
--#region Derived model

--- Reactive derived-slots singleton. **Read-only** — no write helpers; the controller never touches it.
--- Two read faces over the same board: per-seat `Slots` (the row/card paint these) and the binary
--- auto-team aggregate `Teams` (the team-score strip), each deduped independently so a rating-only
--- change re-fires `Teams` but not `Slots`.
---@class UICustomLobbySlotsDerivedModel
---@field Slots LazyVar<UICustomLobbySlot[]>   # the lookup table, indexed 1..MaxSlots
---@field Teams LazyVar<UICustomLobbyTeams>    # the binary auto-team aggregate (side labels + per-side rating totals)
---@field Observers LazyVar[]                  # internal: the source subscriptions; pinned so they aren't GC'd

---@type UICustomLobbySlotsDerivedModel | nil
local ModelInstance = nil

--- A signature of the currently-published table's rendered fields — the de-dup key. Re-set only when
--- the signature changes, so a rebroadcast of an unchanged board re-fires nothing.
---@type string | false
local LoadedSignature = false

--- A signature of the currently-published `Teams` aggregate — its own de-dup key, so a rating change
--- re-fires `Teams` (totals moved) without re-rendering the rows, and an option tweak that doesn't move
--- the split re-fires neither face.
---@type string | false
local LoadedTeamsSignature = false

--- Builds one slot entry by joining every model for that seat.
---@param slot number
---@param player UICustomLobbyPlayer | false
---@param closed boolean
---@param benchmarks table<UILobbyPeerId, UIPerformanceMetrics>
---@param spawns table | nil       # scenario start-spot -> {x, z}
---@param cap number | nil         # recommended unit cap (seated-count × per-player tier)
---@param side 1 | 2 | false       # resolved binary auto-team side for this seat
---@return UICustomLobbySlot
local function BuildSlot(slot, player, closed, benchmarks, spawns, cap, side)
    if not player then
        return {
            Slot = slot, Player = false, Closed = closed,
            StartSpot = false, Position = false, Side = side,
            PlayerView = false, CpuView = false, Benchmark = false, UnitCap = false,
        }
    end

    local startSpot = player.StartSpot or false
    local benchmark = benchmarks[player.OwnerID] or false
    return {
        Slot = slot,
        Player = player,
        Closed = closed,
        StartSpot = startSpot,
        Position = (spawns and startSpot and spawns[startSpot]) or false,
        Side = side,
        PlayerView = BuildPlayerView(player),
        CpuView = BuildCpuView(benchmark or nil, cap),
        Benchmark = benchmark,
        UnitCap = cap or false,
    }
end

--- A compact signature of the table's rendered fields (everything that affects what a slot paints), so
--- the rebuild can skip re-publishing when nothing visible changed.
---@param slots UICustomLobbySlot[]
---@return string
local function Signature(slots)
    local parts = {}
    for slot = 1, MaxSlots do
        local entry = slots[slot]
        local pv = entry.PlayerView
        local cv = entry.CpuView
        local pos = entry.Position
        -- built with `..` (not table.concat) so numbers coerce to strings — Lua 5.0's table.concat
        -- rejects non-string elements
        parts[slot] = tostring(slot)
            .. "|" .. (entry.Closed and "C" or "_")
            .. "|" .. (pv and (pv.colorHex .. pv.name .. pv.nameColor .. pv.faction .. pv.team .. pv.ready .. pv.readyColor) or "-")
            .. "|" .. (cv and (cv.text .. cv.textColor .. (cv.showIndicator and tostring(cv.indicatorColor) or "0")) or "-")
            .. "|" .. tostring(entry.StartSpot)
            .. "|" .. (pos and (tostring(pos[1]) .. ":" .. tostring(pos[2])) or "-")
            .. "|" .. tostring(entry.Side)
    end
    return table.concat(parts, "/")
end

--- A compact signature of the `Teams` aggregate (mode + labels + resolved + the two totals), so the
--- rebuild only re-publishes `Teams` when the split or a side total actually moved.
---@param teams UICustomLobbyTeams
---@return string
local function TeamsSignature(teams)
    return tostring(teams.Mode)
        .. "|" .. (teams.Labels and (teams.Labels[1] .. "/" .. teams.Labels[2]) or "-")
        .. "|" .. tostring(teams.Resolved)
        .. "|" .. tostring(teams.Totals[1]) .. "/" .. tostring(teams.Totals[2])
end

--- Rebuilds the whole lookup table from the current launch / session / local / scenario state and
--- publishes it — but only when its signature changed (the de-dup).
---@param model UICustomLobbySlotsDerivedModel
local function Recompute(model)
    local launch = CustomLobbyLaunchModel.GetSingleton()
    local closedSlots = CustomLobbySessionModel.GetSingleton().ClosedSlots()
    local benchmarks = CustomLobbyLocalModel.GetSingleton().CpuBenchmarks()

    local scenario = CustomLobbyScenarioDerivedModel.GetScenario()
    local spawns = scenario and scenario.Markers and scenario.Markers.Spawns or nil
    local maxDimension = scenario and scenario.MaxDimension or 0

    -- the recommended cap scales by seated count (same for every seat), so count once up front; we feed
    -- the inputs to the pure rule (CustomLobbyRules reads no models itself)
    local seatedCount = 0
    for slot = 1, MaxSlots do
        if launch.Players[slot]() then
            seatedCount = seatedCount + 1
        end
    end
    local cap = CustomLobbyRules.RecommendedUnitCap(seatedCount, maxDimension)

    -- the binary auto-team split, applied once here (the rule lives in CustomLobbyRules). A seat's side
    -- is keyed on its start spot, falling back to the slot index when empty so empty cards still place;
    -- `resolved` is false for a positional mode whose map/start spots aren't loaded yet.
    local mode = CustomLobbyRules.AutoTeamMode(launch.GameOptions())
    local labels = CustomLobbyRules.SideLabels(mode)
    local resolver, resolved = CustomLobbyRules.BuildSideResolver(mode, scenario)

    local slots = {}
    local totalA, totalB = 0, 0
    for slot = 1, MaxSlots do
        local player = launch.Players[slot]()
        local spot = (player and player.StartSpot) or slot
        local side = (resolved and resolver and resolver(spot)) or false
        slots[slot] = BuildSlot(slot, player, closedSlots[slot] and true or false, benchmarks, spawns, cap, side)
        if player then
            if side == 1 then
                totalA = totalA + (player.PL or 0)
            elseif side == 2 then
                totalB = totalB + (player.PL or 0)
            end
        end
    end

    -- per-seat face (rows/cards): re-publish only when a rendered field or a seat's side changed
    local signature = Signature(slots)
    if signature ~= LoadedSignature then
        LoadedSignature = signature
        model.Slots:Set(slots)
    end

    -- aggregate face (team-score strip): re-publish only when the split or a total moved
    local teams = {
        Mode = mode or false,
        Labels = labels or false,
        Resolved = resolved,
        Totals = { math.floor(totalA), math.floor(totalB) },
    }
    local teamsSignature = TeamsSignature(teams)
    if teamsSignature ~= LoadedTeamsSignature then
        LoadedTeamsSignature = teamsSignature
        model.Teams:Set(teams)
    end
end

--- Allocates a fresh slots-model singleton and subscribes its internal observers to every source that
--- feeds a seat: each slot's player, the closed slots, the CPU benchmarks and the derived scenario
--- (placement + the size-driven unit cap). The observers are pinned on the model so they aren't GC'd,
--- and (because `Derive` fires synchronously on creation) the table resolves immediately.
---@return UICustomLobbySlotsDerivedModel
function SetupSingleton()
    ---@type UICustomLobbySlotsDerivedModel
    local model = {
        Slots = Create({}),
        Teams = Create({ Mode = false, Labels = false, Resolved = false, Totals = { 0, 0 } }),
        Observers = {},
    }
    ModelInstance = model
    LoadedSignature = false
    LoadedTeamsSignature = false

    local function subscribe(source)
        table.insert(model.Observers, Derive(source, function(lazy)
            lazy()
            Recompute(model)
        end))
    end

    local launch = CustomLobbyLaunchModel.GetSingleton()
    for slot = 1, MaxSlots do
        subscribe(launch.Players[slot])
    end
    subscribe(CustomLobbySessionModel.GetSingleton().ClosedSlots)
    subscribe(CustomLobbyLocalModel.GetSingleton().CpuBenchmarks)
    subscribe(CustomLobbyScenarioDerivedModel.GetScenarioVar())
    -- GameOptions feeds the AutoTeams mode (the side split); the per-face dedup keeps an unrelated
    -- option tweak from re-firing either var
    subscribe(launch.GameOptions)

    return model
end

--- Returns the slots-model singleton, creating (and resolving the current table) on first access.
---@return UICustomLobbySlotsDerivedModel
function GetSingleton()
    if not ModelInstance then
        SetupSingleton()
    end
    return ModelInstance --[[@as UICustomLobbySlotsDerivedModel]]
end

--#endregion

-------------------------------------------------------------------------------
--#region Accessors

--- The reactive slots var — subscribe to it (via `Derive`) to react when any seat changes.
---@return LazyVar<UICustomLobbySlot[]>
function GetSlotsVar()
    return GetSingleton().Slots
end

--- The current lookup table (indexed 1..MaxSlots).
---@return UICustomLobbySlot[]
function GetSlots()
    return GetSingleton().Slots()
end

--- The resolved entry for a single slot (always present, 1..MaxSlots).
---@param slot number
---@return UICustomLobbySlot
function GetSlot(slot)
    return GetSingleton().Slots()[slot]
end

--- The reactive team aggregate var — subscribe to it (via `Derive`) to react when the side split or a
--- side's rating total changes (the team-score strip's single source).
---@return LazyVar<UICustomLobbyTeams>
function GetTeamsVar()
    return GetSingleton().Teams
end

--- The current binary auto-team aggregate (mode / labels / resolved / per-side totals).
---@return UICustomLobbyTeams
function GetTeams()
    return GetSingleton().Teams()
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: rebuild the singleton so its observers re-subscribe and re-derive. The table is
--- fully derived from the source models, so there is no state to copy across.
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
