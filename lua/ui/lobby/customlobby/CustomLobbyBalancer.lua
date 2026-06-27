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

-- The auto-balance **kernel**: a pure function that builds a balance *plan* from the lobby snapshot.
-- It reads no models — the caller passes the slots derived model's already-resolved state — so it can
-- be reasoned about and tested in isolation, like CustomLobbyRules.
--
-- **Positional only.** Auto-balance is offered only for binary AutoTeams modes (top/bottom,
-- left/right, odd/even), which guarantees exactly two sides. Under AutoTeams the **position decides
-- the team**, so this kernel never touches `Team`: it decides the two balanced teams + the pairing
-- and expresses the result as a **player -> slot arrangement**. The lobby applies the arrangement by
-- re-seating, and position -> team is resolved at launch (BuildGameConfiguration).
--
-- The plan is built in three phases (USER_STORIES § R):
--   1. TEAMS — split the free players into two even sides minimising a cheap rating-imbalance
--      heuristic (|Σdev−goal|·1.2 + |Σmean−goal|, as the legacy did — trueskill is too costly per
--      combination). Locked players are held on their position's side; an odd roster leaves the
--      lowest-rated unlocked player in place (never ejected).
--   2. PAIRS — rank-match across the teams: the strongest of side A faces the strongest of side B,
--      etc. Who faces whom is decided by rating, never at random.
--   3. POSITIONS — `ShufflePairsIntoSeats` scatters the pairs across the free mirror rows, so each
--      pair's *position* is random while the *pairing* stays fixed. Locked players keep their seat.
-- Then the chosen split is scored once with trueskill `computeQuality` for the preview.
--
-- Ratings: the search + quality use MEAN / DEV; the per-side display totals use PL (matching the
-- team-score strip).

local Trueskill = import("/lua/ui/lobby/trueskill.lua")

-- safety cap on the combination search (C(16,8) = 12870 worst case, comfortably under this)
local MaxBalanceEvaluations = 20000

--- A player reduced to just what balancing needs (projected from a slots-derived-model entry).
---@class UICustomLobbyBalancePlayer
---@field ownerId UILobbyPeerId
---@field name    string
---@field pl      number          # display rating (per-side totals + rank sort)
---@field mean    number          # trueskill mean (search + quality)
---@field dev     number          # trueskill deviation
---@field locked  boolean         # the host pinned this seat
---@field side    1 | 2           # the seat's resolved auto-team side (current)
---@field slot    number          # current seat
---@field moved   boolean         # this player's proposed seat differs from its current seat (preview highlight)

--- One mirror row of the layout: the k-th seat on side A faces the k-th seat on side B. The preview
--- renders the plan as an ordered list of these (a player may be absent on an uneven split), and a
--- pair drag-and-drop swaps two positions' occupants.
---@class UICustomLobbyBalancePosition
---@field slotA number | nil
---@field slotB number | nil
---@field a     UICustomLobbyBalancePlayer | nil
---@field b     UICustomLobbyBalancePlayer | nil

--- A proposed balance.
---@class UICustomLobbyBalancePlan
---@field labels       string[]                              # the two side labels, for the preview
---@field sides        UICustomLobbyBalancePlayer[][]        # the two teams, rank-sorted (totals / quality)
---@field positions    UICustomLobbyBalancePosition[]        # ordered mirror rows (k-th seat each side), for the preview
---@field totals       number[]                              # per-side PL totals
---@field lockedOwners table<UILobbyPeerId, boolean>         # user-locked players (the preview marks them)
---@field unassigned   UICustomLobbyBalancePlayer | false    # the odd one left in place, if any
---@field feasible     boolean                               # false = nothing to apply (Apply disabled)
---@field reason       string | nil                          # why it can't / didn't balance, for the preview
---@field quality      number | false                        # trueskill match quality % of the proposal, or false
---@field currentQuality number | false                      # trueskill match quality % of the CURRENT seating, for "before -> after"
---@field winChance    number[] | false                      # predicted win % per side {a, b} for the proposal, or false
---@field arrangement  table<number, UILobbyPeerId>          # the lobby update: slot -> ownerId (no team)

--- Sorts players strongest-first by display rating, so two rating-sorted sides line up rank for rank.
---@param a UICustomLobbyBalancePlayer
---@param b UICustomLobbyBalancePlayer
---@return boolean
local function ByRatingDesc(a, b)
    return a.pl > b.pl
end

--- Scores a proposed two-side split with trueskill match quality. Returns false for AI / unrated
--- players (mean 0) or a degenerate matrix — the preview then shows "—".
---@param sides UICustomLobbyBalancePlayer[][]
---@return number | false
local function ComputeQuality(sides)
    local teams = Trueskill.Teams.create()
    for side = 1, 2 do
        for _, bp in ipairs(sides[side]) do
            if not bp.mean or bp.mean == 0 then
                return false
            end
            teams:addPlayer(side, Trueskill.Player.create(bp.name, Trueskill.Rating.create(bp.mean, bp.dev)))
        end
    end
    if table.getn(teams:getTeams()) ~= 2 then
        return false
    end

    local quality = Trueskill.computeQuality(teams)
    if not quality or quality <= 0 then
        return false
    end
    return quality
end

-- trueskill's per-player performance variance (beta); matches the 250 baked into computeQuality.
local Beta = 250

--- Gauss error function (Abramowitz & Stegun 7.1.26) — max abs error ~1.5e-7, plenty for a display %.
---@param x number
---@return number
local function Erf(x)
    local sign = x < 0 and -1 or 1
    x = math.abs(x)
    local t = 1 / (1 + 0.3275911 * x)
    local y = 1 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592)
        * t * math.exp(-x * x)
    return sign * y
end

--- Predicted win split for a two-side proposal, as integer percentages {winA, winB} summing to 100.
--- This is the probabilistic counterpart to the symmetric match quality: quality says "how close",
--- this says "which way". P(A beats B) = Phi(Δμ / sqrt(N·β² + Σσ²)) over both sides' players. Returns
--- false for AI / unrated players (mean 0) or an empty side — the preview then shows "—".
---@param sides UICustomLobbyBalancePlayer[][]
---@return number[] | false
local function ComputeWinChance(sides)
    if table.getn(sides[1]) == 0 or table.getn(sides[2]) == 0 then
        return false
    end
    local sumMean = { 0, 0 }
    local sumVar = { 0, 0 }
    local count = 0
    for side = 1, 2 do
        for _, bp in ipairs(sides[side]) do
            if not bp.mean or bp.mean == 0 then
                return false
            end
            sumMean[side] = sumMean[side] + bp.mean
            sumVar[side] = sumVar[side] + bp.dev * bp.dev
            count = count + 1
        end
    end
    local denom = math.sqrt(count * Beta * Beta + sumVar[1] + sumVar[2])
    if denom <= 0 then
        return false
    end
    local pA = 0.5 * (1 + Erf((sumMean[1] - sumMean[2]) / (denom * math.sqrt(2))))
    local a = math.floor(pA * 100 + 0.5)
    return { a, 100 - a }
end

--- Phase 3 — seats already-formed rank-matched pairs at randomly-chosen mirror rows: `pairsA[i]` vs
--- `pairsB[i]` is the i-th pair (formed by rating in phase 2), and it lands at the same free row on
--- both sides, so WHO faces whom stays fixed while the POSITION is random. `seatsA`/`seatsB` are the
--- free seats per side, paired by order into mirror rows (locked seats are excluded by the caller, so
--- locked players don't move). Invokes `place(slot, player)` for each seated player; any leftover
--- players — when the two sides have unequal free counts (asymmetric locks) — fill the remaining
--- seats so none are dropped.
---@param pairsA UICustomLobbyBalancePlayer[]
---@param pairsB UICustomLobbyBalancePlayer[]
---@param seatsA number[]
---@param seatsB number[]
---@param place fun(slot: number, player: UICustomLobbyBalancePlayer)
function ShufflePairsIntoSeats(pairsA, pairsB, seatsA, seatsB, place)
    local rowCount = math.min(table.getn(seatsA), table.getn(seatsB))
    local rowOrder = {}
    for k = 1, rowCount do
        rowOrder[k] = k
    end
    for k = rowCount, 2, -1 do
        local j = Random(1, k)
        rowOrder[k], rowOrder[j] = rowOrder[j], rowOrder[k]
    end

    local usedA, usedB = {}, {}
    local pairCount = math.min(table.getn(pairsA), table.getn(pairsB), rowCount)
    for i = 1, pairCount do
        local row = rowOrder[i]
        place(seatsA[row], pairsA[i])
        place(seatsB[row], pairsB[i])
        usedA[row], usedB[row] = true, true
    end

    local function seatRest(players, seats, used, fromIndex)
        local free = {}
        for k = 1, table.getn(seats) do
            if not used[k] then
                table.insert(free, k)
            end
        end
        local r = 1
        for i = fromIndex, table.getn(players) do
            if not free[r] then
                break
            end
            place(seats[free[r]], players[i])
            r = r + 1
        end
    end
    seatRest(pairsA, seatsA, usedA, pairCount + 1)
    seatRest(pairsB, seatsB, usedB, pairCount + 1)
end

--- Projects the slots snapshot into the minimal records balancing needs. `locks` (ownerId -> true),
--- when given, OVERRIDES each seat's own Locked flag — the preview passes its working lock set so a
--- lock toggled in the dialog is honoured without touching the synced lobby; nil falls back to
--- `entry.Locked`.
---@param slots UICustomLobbySlot[]
---@param locks table<UILobbyPeerId, boolean> | nil
---@return UICustomLobbyBalancePlayer[] players       # one per occupied side-1/2 seat (bp.locked from `locks`)
---@return table<number, 1 | 2> seatSide             # slot -> side, for every side-1/2 seat
---@return table<number, boolean> seatClosed         # slot -> closed, for every side-1/2 seat
local function Project(slots, locks)
    local players = {}
    local seatSide = {}
    local seatClosed = {}
    for _, entry in ipairs(slots) do
        local side = entry.Side
        if side == 1 or side == 2 then
            seatSide[entry.Slot] = side
            seatClosed[entry.Slot] = entry.Closed and true or false
            if entry.Player then
                local locked
                if locks then
                    locked = locks[entry.Player.OwnerID] and true or false
                else
                    locked = entry.Locked and true or false
                end
                table.insert(players, {
                    ownerId = entry.Player.OwnerID,
                    name = entry.Player.PlayerName or "?",
                    pl = entry.Player.PL or 0,
                    mean = entry.Player.MEAN or 1500,
                    dev = entry.Player.DEV or 500,
                    locked = locked,
                    side = side,
                    slot = entry.Slot,
                })
            end
        end
    end
    return players, seatSide, seatClosed
end

--- The identity arrangement (every seated player on its current seat) — the starting point for a fresh
--- solve from the lobby's current seating.
---@param slots UICustomLobbySlot[]
---@return table<number, UILobbyPeerId>
local function IdentityArrangement(slots)
    local arrangement = {}
    for _, entry in ipairs(slots) do
        if (entry.Side == 1 or entry.Side == 2) and entry.Player then
            arrangement[entry.Slot] = entry.Player.OwnerID
        end
    end
    return arrangement
end

--- A fresh, empty plan; the gated fields are filled in by the scorer / solver.
---@param teams UICustomLobbyTeams
---@return UICustomLobbyBalancePlan
local function NewPlan(teams)
    ---@type UICustomLobbyBalancePlan
    return {
        labels = (teams and teams.Labels) or { "Team 1", "Team 2" },
        sides = { {}, {} },
        positions = {},
        totals = { 0, 0 },
        lockedOwners = {},
        unassigned = false,
        feasible = false,
        reason = nil,
        quality = false,
        currentQuality = false,
        winChance = false,
        arrangement = {},
    }
end

--- Scores a concrete `arrangement` (slot -> ownerId) into `plan`: the two rank-sorted sides, the
--- per-side PL totals, the moved flags (vs. each player's current lobby seat), the current-seating
--- quality, and the proposed quality + win split. Pure display computation — it moves no one.
--- `players` / `seatSide` come from Project.
---@param plan UICustomLobbyBalancePlan
---@param players UICustomLobbyBalancePlayer[]
---@param seatSide table<number, 1 | 2>
---@param arrangement table<number, UILobbyPeerId>
local function ScorePlan(plan, players, seatSide, arrangement)
    local byId = {}
    for _, bp in ipairs(players) do
        byId[bp.ownerId] = bp
        if bp.locked then
            plan.lockedOwners[bp.ownerId] = true
        end
    end

    -- the current seating's quality, for the "before -> after" readout
    local currentSides = { {}, {} }
    for _, bp in ipairs(players) do
        table.insert(currentSides[bp.side], bp)
    end
    plan.currentQuality = ComputeQuality(currentSides)

    -- the proposed sides, from the arrangement; a player's side is its seat's side
    plan.arrangement = arrangement
    for slot, ownerId in arrangement do
        local bp = byId[ownerId]
        local side = seatSide[slot]
        if bp and side then
            bp.moved = slot ~= bp.slot
            table.insert(plan.sides[side], bp)
        end
    end
    table.sort(plan.sides[1], ByRatingDesc)
    table.sort(plan.sides[2], ByRatingDesc)
    for side = 1, 2 do
        local total = 0
        for _, bp in ipairs(plan.sides[side]) do
            total = total + bp.pl
        end
        plan.totals[side] = total
    end

    plan.quality = ComputeQuality(plan.sides)
    plan.winChance = ComputeWinChance(plan.sides)

    -- ordered mirror positions for the preview: the k-th side-1 seat faces the k-th side-2 seat (both
    -- sorted by slot, so the list is stable across re-scores — a position swap moves the players
    -- between seats, not the row order)
    local slotsA, slotsB = {}, {}
    for slot, _ in arrangement do
        local side = seatSide[slot]
        if side == 1 then
            table.insert(slotsA, slot)
        elseif side == 2 then
            table.insert(slotsB, slot)
        end
    end
    table.sort(slotsA)
    table.sort(slotsB)
    local posCount = math.max(table.getn(slotsA), table.getn(slotsB))
    for k = 1, posCount do
        local slotA, slotB = slotsA[k], slotsB[k]
        plan.positions[k] = {
            slotA = slotA,
            slotB = slotB,
            a = slotA and byId[arrangement[slotA]] or nil,
            b = slotB and byId[arrangement[slotB]] or nil,
        }
    end
end

--- Scores an arrangement the host hand-edited (a manual swap, or after a lock toggle) WITHOUT
--- re-solving — everyone stays exactly where `arrangement` puts them, only the metrics refresh. `locks`
--- is the preview's working lock set (see Project). Apply is enabled whenever both sides are non-empty.
---@param slots UICustomLobbySlot[]
---@param teams UICustomLobbyTeams
---@param arrangement table<number, UILobbyPeerId>
---@param locks table<UILobbyPeerId, boolean> | nil
---@return UICustomLobbyBalancePlan
function ScoreArrangement(slots, teams, arrangement, locks)
    local plan = NewPlan(teams)
    if not (teams and teams.Mode) or not teams.Resolved then
        plan.reason = "Auto-balance needs an AutoTeams mode with a loaded map."
        return plan
    end
    local players, seatSide = Project(slots, locks)
    if table.getn(players) < 2 then
        plan.reason = "Need at least two players to balance."
        return plan
    end
    ScorePlan(plan, players, seatSide, arrangement)
    plan.feasible = table.getn(plan.sides[1]) > 0 and table.getn(plan.sides[2]) > 0
    return plan
end

-- how many candidate splits the search keeps (caller asks for `count`; we collect a wider pool so that
-- after discarding mirror-equivalent splits there are still enough genuinely-different ones)
local DefaultCandidateCount = 5

--- Builds up to `count` candidate balance plans — the best distinct team splits, each a complete,
--- scored plan — best-first by match quality. The host browses them in the preview. Re-solves the
--- UNLOCKED players, keeping locked players (and, for an odd roster, the lowest-rated unlocked player)
--- pinned at their seat in `arrangement` — so a balance honours where the host has already locked
--- people, even when those seats differ from the lobby. Each candidate gets its own random position
--- shuffle. Always returns a non-empty list; an infeasible case is a single plan carrying the reason.
---@param slots UICustomLobbySlot[]
---@param teams UICustomLobbyTeams
---@param arrangement table<number, UILobbyPeerId>     # current seats (pinned players are read from here)
---@param locks table<UILobbyPeerId, boolean> | nil
---@param count? number                                # how many candidates to return (default 5)
---@return UICustomLobbyBalancePlan[]
function BuildCandidates(slots, teams, arrangement, locks, count)
    count = count or DefaultCandidateCount

    -- the feature is gated to a binary AutoTeams mode with a resolved split; bail defensively otherwise
    if not (teams and teams.Mode) or not teams.Resolved then
        local plan = NewPlan(teams)
        plan.reason = "Auto-balance needs an AutoTeams mode with a loaded map."
        return { plan }
    end

    local players, seatSide, seatClosed = Project(slots, locks)
    local occupiedCount = table.getn(players)
    if occupiedCount < 2 then
        local plan = NewPlan(teams)
        plan.reason = "Need at least two players to balance."
        return { plan }
    end

    -- where each player currently sits (its seat in the working arrangement, or its lobby seat if it
    -- isn't in one). Pinned players are held here rather than at their lobby seat, so locking a player
    -- the balance already moved keeps them where the host sees them.
    local slotOf = {}
    for slot, ownerId in arrangement do
        slotOf[ownerId] = slot
    end

    -- pinned = locked players + (odd roster) the lowest-rated unlocked player, left in place so the rest
    -- pair up (never ejected)
    local pinned = {}
    ---@type UICustomLobbyBalancePlayer | false
    local unassigned = false
    for _, bp in ipairs(players) do
        if bp.locked then
            pinned[bp.ownerId] = true
        end
    end
    if math.mod(occupiedCount, 2) == 1 then
        local odd
        for _, bp in ipairs(players) do
            if not pinned[bp.ownerId] and (not odd or (bp.mean - bp.dev * 2.2) < (odd.mean - odd.dev * 2.2)) then
                odd = bp
            end
        end
        if odd then
            pinned[odd.ownerId] = true
            unassigned = odd
        end
    end

    -- pinned players hold their current seat (off-limits to the search); everyone else is the free pool
    local solvedBase = {}
    local pinnedSlots = {}
    local lockedMean = { 0, 0 }
    local lockedDev = { 0, 0 }
    local lockedCount = { 0, 0 }
    local freePool = {}
    local totalMean, totalDev = 0, 0
    for _, bp in ipairs(players) do
        totalMean = totalMean + bp.mean
        totalDev = totalDev + bp.dev
        if pinned[bp.ownerId] then
            local seat = slotOf[bp.ownerId] or bp.slot
            local side = seatSide[seat] or bp.side
            solvedBase[seat] = bp.ownerId
            pinnedSlots[seat] = true
            lockedMean[side] = lockedMean[side] + bp.mean
            lockedDev[side] = lockedDev[side] + bp.dev
            lockedCount[side] = lockedCount[side] + 1
        else
            table.insert(freePool, bp)
        end
    end

    -- the seats the search can fill: every side-1/2 seat that isn't closed or pinned (the seats freed by
    -- the unlocked players + any open seats)
    local freeSeats = { {}, {} }
    for slot, side in seatSide do
        if not seatClosed[slot] and not pinnedSlots[slot] then
            table.insert(freeSeats[side], slot)
        end
    end
    table.sort(freeSeats[1])
    table.sort(freeSeats[2])

    local freeCount = table.getn(freePool)

    -- shuffle the free pool so re-running varies which equally-good split / seating is picked
    for i = freeCount, 2, -1 do
        local j = Random(1, i)
        freePool[i], freePool[j] = freePool[j], freePool[i]
    end

    --- Builds + scores one plan from a chosen side-A index set (a position shuffle per call).
    ---@param chosenList number[]
    ---@return UICustomLobbyBalancePlan
    local function PlanFor(chosenList)
        local chosen = {}
        for _, index in ipairs(chosenList) do
            chosen[index] = true
        end
        local freeA, freeB = {}, {}
        for i = 1, freeCount do
            table.insert(chosen[i] and freeA or freeB, freePool[i])
        end
        table.sort(freeA, ByRatingDesc)
        table.sort(freeB, ByRatingDesc)
        local arr = table.copy(solvedBase)
        ShufflePairsIntoSeats(freeA, freeB, freeSeats[1], freeSeats[2],
            function(slot, bp) arr[slot] = bp.ownerId end)
        local plan = NewPlan(teams)
        plan.unassigned = unassigned
        ScorePlan(plan, players, seatSide, arr)
        plan.feasible = freeCount > 0
        return plan
    end

    -- nothing to rearrange (everyone pinned): one plan showing the pinned board
    if freeCount == 0 then
        local plan = PlanFor({})
        plan.feasible = false
        plan.reason = "Every player is locked in place — nothing to rearrange."
        return { plan }
    end

    -- how many free players go to side A: aim for equal final sizes, clamped to each side's free seats
    local capA, capB = table.getn(freeSeats[1]), table.getn(freeSeats[2])
    local placedA = math.floor((freeCount + lockedCount[2] - lockedCount[1]) / 2 + 0.5)
    local minA = math.max(0, freeCount - capB)
    local maxA = math.min(freeCount, capA)
    if minA > maxA then
        local plan = NewPlan(teams)
        plan.reason = "The locked players don't fit the team layout."
        ScorePlan(plan, players, seatSide, solvedBase)   -- still show the pinned players
        return { plan }
    end
    if placedA < minA then placedA = minA end
    if placedA > maxA then placedA = maxA end

    -- search: enumerate side-A choices, keeping the top `poolSize` by the cheap rating-imbalance
    -- heuristic (a wider pool than `count`, so mirror-equivalent splits can be dropped below)
    local goalMean, goalDev = totalMean / 2, totalDev / 2
    local poolSize = math.max(count * 4, 12)
    local kept = {}                                       -- {value, chosen}, sorted ascending by value
    local evaluations = 0
    local current = {}
    local function consider(value)
        local n = table.getn(kept)
        if n >= poolSize and value >= kept[n].value then
            return
        end
        local pos = n + 1
        for i = 1, n do
            if value < kept[i].value then
                pos = i
                break
            end
        end
        table.insert(kept, pos, { value = value, chosen = table.copy(current) })
        if table.getn(kept) > poolSize then
            table.remove(kept)
        end
    end
    local function evaluate()
        local meanA, devA = lockedMean[1], lockedDev[1]
        for i = 1, table.getn(current) do
            local bp = freePool[current[i]]
            meanA = meanA + bp.mean
            devA = devA + bp.dev
        end
        consider(math.abs(devA - goalDev) * 1.2 + math.abs(meanA - goalMean))
        evaluations = evaluations + 1
    end
    local function choose(startIndex, remaining)
        if evaluations >= MaxBalanceEvaluations then
            return
        end
        if remaining == 0 then
            evaluate()
            return
        end
        for i = startIndex, freeCount - remaining + 1 do
            table.insert(current, i)
            choose(i + 1, remaining - 1)
            table.remove(current)
            if evaluations >= MaxBalanceEvaluations then
                return
            end
        end
    end
    choose(1, placedA)

    -- build the best distinct splits, skipping mirror-equivalent ones (side A = the complement of an
    -- already-taken split is the same matchup with the teams flipped)
    local plans = {}
    local seen = {}
    for _, entry in ipairs(kept) do
        if table.getn(plans) >= count then
            break
        end
        local inA = {}
        for _, index in ipairs(entry.chosen) do
            inA[index] = true
        end
        local sigA, sigB = "", ""
        for i = 1, freeCount do
            if inA[i] then
                sigA = sigA .. tostring(i) .. ","
            else
                sigB = sigB .. tostring(i) .. ","
            end
        end
        local signature = (sigA < sigB) and (sigA .. "|" .. sigB) or (sigB .. "|" .. sigA)
        if not seen[signature] then
            seen[signature] = true
            table.insert(plans, PlanFor(entry.chosen))
        end
    end

    -- present the most balanced first (by the displayed metric — match quality)
    table.sort(plans, function(p, q)
        return (p.quality or 0) > (q.quality or 0)
    end)
    return plans
end

--- Re-solves into a single best balance plan — the first of BuildCandidates. Used where one plan is
--- enough (Retry's re-roll picks among the candidate set in the preview).
---@param slots UICustomLobbySlot[]
---@param teams UICustomLobbyTeams
---@param arrangement table<number, UILobbyPeerId>
---@param locks table<UILobbyPeerId, boolean> | nil
---@return UICustomLobbyBalancePlan
function Rebalance(slots, teams, arrangement, locks)
    return BuildCandidates(slots, teams, arrangement, locks, 1)[1]
end

--- Builds the candidate balance plans from the lobby's current seating — a fresh solve honouring
--- `locks` (the preview's working lock set; nil = the seats' own Locked flags).
---@param slots UICustomLobbySlot[]
---@param teams UICustomLobbyTeams
---@param locks? table<UILobbyPeerId, boolean>
---@param count? number
---@return UICustomLobbyBalancePlan[]
function BuildPlan(slots, teams, locks, count)
    return BuildCandidates(slots, teams, IdentityArrangement(slots), locks, count)
end

--- The lobby update for a plan: the player -> slot arrangement to apply. `Team` is intentionally
--- absent — under AutoTeams the position decides the team (resolved at launch).
---@param plan UICustomLobbyBalancePlan
---@return table<number, UILobbyPeerId>
function ToArrangement(plan)
    return plan.arrangement
end
