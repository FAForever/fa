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

--- A proposed balance.
---@class UICustomLobbyBalancePlan
---@field labels       string[]                              # the two side labels, for the preview
---@field sides        UICustomLobbyBalancePlayer[][]        # the two teams, rank-sorted (row k = a pair)
---@field totals       number[]                              # per-side PL totals
---@field lockedOwners table<UILobbyPeerId, boolean>         # user-locked players (the preview marks them)
---@field unassigned   UICustomLobbyBalancePlayer | false    # the odd one left in place, if any
---@field feasible     boolean                               # false = nothing to apply (Apply disabled)
---@field reason       string | nil                          # why it can't / didn't balance, for the preview
---@field quality      number | false                        # trueskill match quality %, or false
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

--- Builds a balance plan from the slots derived model's resolved snapshot: `slots` is its `Slots`
--- table (per-seat Player / Side / Locked / Closed), `teams` its `Teams` aggregate (Mode / Labels /
--- Resolved). Pure — reads no models. Always returns a plan; `feasible` is false (with a `reason`)
--- when there is nothing to apply.
---@param slots UICustomLobbySlot[]
---@param teams UICustomLobbyTeams
---@return UICustomLobbyBalancePlan
function BuildPlan(slots, teams)
    ---@type UICustomLobbyBalancePlan
    local plan = {
        labels = (teams and teams.Labels) or { "Team 1", "Team 2" },
        sides = { {}, {} },
        totals = { 0, 0 },
        lockedOwners = {},
        unassigned = false,
        feasible = false,
        reason = nil,
        quality = false,
        arrangement = {},
    }

    -- the feature is gated to a binary AutoTeams mode with a resolved split; bail defensively otherwise
    if not (teams and teams.Mode) or not teams.Resolved then
        plan.reason = "Auto-balance needs an AutoTeams mode with a loaded map."
        return plan
    end

    -- project each seat into the minimal info balancing needs, and collect the free seats per side
    -- (open, non-locked-occupied — empty open seats count, so players can move into vacant positions)
    local players = {}
    local freeSeats = { {}, {} }
    for _, entry in ipairs(slots) do
        local side = entry.Side
        if side == 1 or side == 2 then
            if entry.Player then
                table.insert(players, {
                    ownerId = entry.Player.OwnerID,
                    name = entry.Player.PlayerName or "?",
                    pl = entry.Player.PL or 0,
                    mean = entry.Player.MEAN or 1500,
                    dev = entry.Player.DEV or 500,
                    locked = entry.Locked and true or false,
                    side = side,
                    slot = entry.Slot,
                })
            end
            if not entry.Closed and not (entry.Locked and entry.Player) then
                table.insert(freeSeats[side], entry.Slot)
            end
        end
    end

    local occupiedCount = table.getn(players)
    if occupiedCount < 2 then
        plan.reason = "Need at least two players to balance."
        return plan
    end

    -- pinned = the host-locked players + (odd roster) the lowest-rated unlocked player, left in place
    -- so the rest pair up (never ejected). Pinned players hold their exact seat and side.
    local pinned = {}
    for _, bp in ipairs(players) do
        if bp.locked then
            pinned[bp.ownerId] = true
            plan.lockedOwners[bp.ownerId] = true
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
            plan.unassigned = odd
        end
    end

    -- partition into pinned (held on their position's side) and the free pool the search splits
    local lockedRecords = { {}, {} }
    local freePool = {}
    local totalMean, totalDev = 0, 0
    for _, bp in ipairs(players) do
        totalMean = totalMean + bp.mean
        totalDev = totalDev + bp.dev
        if pinned[bp.ownerId] then
            table.insert(lockedRecords[bp.side], bp)
            plan.arrangement[bp.slot] = bp.ownerId       -- stays exactly where it is
        else
            table.insert(freePool, bp)
        end
    end
    local freeCount = table.getn(freePool)

    -- shuffle the free pool so re-running varies which equally-good split / seating is picked
    for i = freeCount, 2, -1 do
        local j = Random(1, i)
        freePool[i], freePool[j] = freePool[j], freePool[i]
    end

    -- how many free players go to side A: aim for equal final sizes, clamped to each side's free seats
    local lockedCountA = table.getn(lockedRecords[1])
    local lockedCountB = table.getn(lockedRecords[2])
    local capA, capB = table.getn(freeSeats[1]), table.getn(freeSeats[2])
    local placedA = math.floor((freeCount + lockedCountB - lockedCountA) / 2 + 0.5)
    local minA = math.max(0, freeCount - capB)
    local maxA = math.min(freeCount, capA)
    if minA > maxA then
        plan.reason = "The locked players don't fit the team layout."
        return plan
    end
    if placedA < minA then placedA = minA end
    if placedA > maxA then placedA = maxA end

    -- search: choose placedA free players for side A, minimising the cheap rating-imbalance heuristic
    local goalMean, goalDev = totalMean / 2, totalDev / 2
    local lockedMeanA, lockedDevA = 0, 0
    for _, bp in ipairs(lockedRecords[1]) do
        lockedMeanA = lockedMeanA + bp.mean
        lockedDevA = lockedDevA + bp.dev
    end

    local best = { value = nil, chosen = nil }
    local evaluations = 0
    local current = {}
    local function evaluate()
        local meanA, devA = lockedMeanA, lockedDevA
        for i = 1, table.getn(current) do
            local bp = freePool[current[i]]
            meanA = meanA + bp.mean
            devA = devA + bp.dev
        end
        local value = math.abs(devA - goalDev) * 1.2 + math.abs(meanA - goalMean)
        if not best.value or value < best.value then
            best.value = value
            best.chosen = table.copy(current)
        end
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

    -- split the free pool into the two sides per the best result
    local chosen = {}
    if best.chosen then
        for _, index in ipairs(best.chosen) do
            chosen[index] = true
        end
    end
    local freeA, freeB = {}, {}
    for i = 1, freeCount do
        table.insert(chosen[i] and freeA or freeB, freePool[i])
    end

    -- phase 2 + 3: rank-match the free players, scatter the pairs across the free mirror rows
    table.sort(freeA, ByRatingDesc)
    table.sort(freeB, ByRatingDesc)
    ShufflePairsIntoSeats(freeA, freeB, freeSeats[1], freeSeats[2],
        function(slot, bp) plan.arrangement[slot] = bp.ownerId end)

    -- the two teams, rank-sorted for display (row k = the k-th strongest of each side — who face off)
    for _, bp in ipairs(lockedRecords[1]) do table.insert(plan.sides[1], bp) end
    for _, bp in ipairs(freeA) do table.insert(plan.sides[1], bp) end
    for _, bp in ipairs(lockedRecords[2]) do table.insert(plan.sides[2], bp) end
    for _, bp in ipairs(freeB) do table.insert(plan.sides[2], bp) end
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
    plan.feasible = freeCount > 0
    if freeCount == 0 then
        plan.reason = "Every player is locked in place — nothing to rearrange."
    end
    return plan
end

--- The lobby update for a plan: the player -> slot arrangement to apply. `Team` is intentionally
--- absent — under AutoTeams the position decides the team (resolved at launch).
---@param plan UICustomLobbyBalancePlan
---@return table<number, UILobbyPeerId>
function ToArrangement(plan)
    return plan.arrangement
end
