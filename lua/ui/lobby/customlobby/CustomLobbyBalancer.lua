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

-- The auto-balance **kernel**: a pure function that proposes a balanced re-seating of the lobby. It
-- reads no models — the caller passes a snapshot in — so it can be reasoned about and tested in
-- isolation, like CustomLobbyRules (the side rule it reuses lives there). The controller applies the
-- result host-authoritatively (CustomLobbyController.RequestApplyBalance); the preview renders it
-- before the host commits (CustomLobbySlotsInterface / CustomLobbyBalancePreview).
--
-- What it does (a port of the legacy PenguinAutoBalance, lobby-old.lua, onto the MVC models):
--   1. Split the players into two sides. Positional modes assign players to the side's seats (from
--      the passed `sideResolver`, built from CustomLobbyRules.BuildSideResolver) — side sizes are
--      fixed by the map. Manual / none modes reassign Team freely toward EVEN sizes (the current team
--      split doesn't constrain the result), keeping each player in its seat.
--   2. Hold LOCKED players in their exact seat (they still count toward their side's totals); only
--      the unlocked players are redistributed. An odd roster leaves the lowest-rated unlocked player
--      in place (never ejected) so the rest pair up.
--   3. Search player→side combinations minimising a cheap rating-imbalance heuristic
--      (|Σdev−goal|·1.2 + |Σmean−goal|, as the legacy did — trueskill is too costly per combination).
--   4. (Positional only) shuffle the seat assignment as mirrored pairs so equivalent positions across
--      the two sides move together. (Manual mode doesn't move seats, so it doesn't shuffle.)
--   5. Score the chosen split ONCE with trueskill `computeQuality` for the preview (— if AI/unrated).
--
-- Ratings: the search + quality use MEAN / DEV; the per-side display totals use PL (matching the
-- team-score strip). Team numbering is the model's backend form throughout (1 = no team, 2 = team 1,
-- 3 = team 2); only the display translates.

local Trueskill = import("/lua/ui/lobby/trueskill.lua")

-- safety cap on the combination search (C(16,8) = 12870 worst case, comfortably under this)
local MaxBalanceEvaluations = 20000

-- side index (1/2) -> model backend Team number
local TeamForSide = { [1] = 2, [2] = 3 }

---@param player UICustomLobbyPlayer
---@return number
local function MeanOf(player)
    return player.MEAN or 1500
end

---@param player UICustomLobbyPlayer
---@return number
local function DevOf(player)
    return player.DEV or 500
end

--- The input snapshot for a balance computation. All data is passed in — the kernel reads no models.
---@class UICustomLobbyBalanceInput
---@field players      table<number, UICustomLobbyPlayer>   # occupied slots only (slot -> player)
---@field lockedSlots  table<number, boolean>               # seats whose player is pinned in place
---@field slotCount    number                               # active slots on the current map
---@field closedSlots  table<number, boolean>
---@field sideResolver (fun(startSpot: number): number | nil) | nil  # positional split; nil = manual
---@field resolved     boolean                              # positional map loaded (false hides positional)
---@field labels       string[] | nil                       # the two side labels, for the preview

--- One seat in a proposed arrangement.
---@class UICustomLobbyBalanceSeat
---@field OwnerId UILobbyPeerId
---@field Team    number | nil   # set only in manual mode (positional teams resolve from position at launch)

--- The proposed balance.
---@class UICustomLobbyBalanceResult
---@field feasible    boolean                                   # false = nothing to apply (Apply disabled)
---@field reason      string | nil                              # why it can't / didn't balance, for the preview
---@field arrangement table<number, UICustomLobbyBalanceSeat>   # the full target board (slot -> seat)
---@field sides        UICustomLobbyPlayer[][]                   # the two proposed sides, for the preview
---@field totals       number[]                                 # per-side PL totals, for the preview
---@field labels       string[] | nil
---@field unassigned   UICustomLobbyPlayer | false              # the odd one left in place, if any
---@field quality      number | false                           # trueskill match quality %, or false

--- Scores a proposed two-side split with trueskill match quality. Returns false for AI / unrated
--- players (MEAN 0) or a degenerate matrix — the preview then shows "—".
---@param sides UICustomLobbyPlayer[][]
---@return number | false
local function ComputeQuality(sides)
    local teams = Trueskill.Teams.create()
    for side = 1, 2 do
        for _, player in ipairs(sides[side]) do
            if not player.MEAN or player.MEAN == 0 then
                return false
            end
            teams:addPlayer(side, Trueskill.Player.create(
                player.PlayerName or "?", Trueskill.Rating.create(player.MEAN, player.DEV or 0)))
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

--- Computes a proposed balanced re-seating. Pure — see UICustomLobbyBalanceInput. Always returns a
--- result; `feasible` is false (with a `reason`) when there is nothing to apply.
---@param input UICustomLobbyBalanceInput
---@return UICustomLobbyBalanceResult
function ComputeBalance(input)
    ---@type UICustomLobbyBalanceResult
    local result = {
        feasible = false,
        reason = nil,
        arrangement = {},
        sides = { {}, {} },
        totals = { 0, 0 },
        labels = input.labels,
        unassigned = false,
        quality = false,
    }

    -- a positional split needs a loaded map; without it there are no sides to balance into
    if input.sideResolver and not input.resolved then
        result.reason = "Pick a map first — the team sides aren't determined yet."
        return result
    end

    -- total roster (locked + free) drives the balance goal and the odd-one-out rule
    local totalMean, totalDev, occupiedCount = 0, 0, 0
    for slot = 1, input.slotCount do
        local player = input.players[slot]
        if player then
            totalMean = totalMean + MeanOf(player)
            totalDev = totalDev + DevOf(player)
            occupiedCount = occupiedCount + 1
        end
    end
    if occupiedCount < 2 then
        result.reason = "Need at least two players to balance."
        return result
    end

    -- odd roster: leave the lowest-rated UNLOCKED player in place (never ejected) so the rest pair
    -- up. Treat its seat as pinned for the rest of the computation.
    local effectiveLocked = table.copy(input.lockedSlots)
    if math.mod(occupiedCount, 2) == 1 then
        local oddSlot, oddRating
        for slot = 1, input.slotCount do
            local player = input.players[slot]
            if player and not input.lockedSlots[slot] then
                local rating = MeanOf(player) - DevOf(player) * 2.2
                if not oddRating or rating < oddRating then
                    oddRating = rating
                    oddSlot = slot
                end
            end
        end
        if oddSlot then
            effectiveLocked[oddSlot] = true
            result.unassigned = input.players[oddSlot]
        end
    end

    local manual = input.sideResolver == nil

    -- A locked (or odd-one-out) player's side. Positional: its seat's resolved side. Manual: its
    -- current Team (2 -> side 1, 3 -> side 2); nil when on no team.
    local function lockedNaturalSide(slot)
        if manual then
            local team = input.players[slot].Team
            if team == 2 then return 1 elseif team == 3 then return 2 end
            return nil
        end
        return input.sideResolver(slot)
    end

    -- Pin the locked / odd-one-out players to a side (never moved); the rest are the free pool the
    -- search splits. A locked manual player with no team is dropped onto the lighter side.
    local lockedRecords = { {}, {} }     -- pinned player records per side
    local lockedSeats = { {}, {} }       -- their seats (kept as-is)
    local freeUnits = {}                 -- { player =, slot = } for the movable players
    for slot = 1, input.slotCount do
        local player = input.players[slot]
        if player then
            if effectiveLocked[slot] then
                local side = lockedNaturalSide(slot)
                    or ((table.getn(lockedRecords[1]) <= table.getn(lockedRecords[2])) and 1 or 2)
                table.insert(lockedRecords[side], player)
                table.insert(lockedSeats[side], slot)
            else
                table.insert(freeUnits, { player = player, slot = slot })
            end
        end
    end
    local freeCount = table.getn(freeUnits)

    -- Free seats available per side. Manual reassigns teams (not seats), so capacity is flexible and
    -- the target is simply even sizes. Positional places players into the side's open, non-locked
    -- seats (including empty ones), so capacity is that seat count — a real map property.
    local freeSeats = { {}, {} }
    local capA, capB
    if manual then
        capA, capB = freeCount, freeCount
    else
        for slot = 1, input.slotCount do
            if not input.closedSlots[slot] and not (effectiveLocked[slot] and input.players[slot]) then
                local side = input.sideResolver(slot)
                if side == 1 or side == 2 then
                    table.insert(freeSeats[side], slot)
                end
            end
        end
        capA, capB = table.getn(freeSeats[1]), table.getn(freeSeats[2])
    end

    -- locked ratings still count toward each side's balance target
    local lockedMean, lockedDev = { 0, 0 }, { 0, 0 }
    for side = 1, 2 do
        for _, player in ipairs(lockedRecords[side]) do
            lockedMean[side] = lockedMean[side] + MeanOf(player)
            lockedDev[side] = lockedDev[side] + DevOf(player)
        end
    end

    -- how many free players go to side A: aim for equal final side sizes, clamped to capacity. An
    -- empty feasible range means the locks can't fit the team layout.
    local lockedCountA = table.getn(lockedRecords[1])
    local lockedCountB = table.getn(lockedRecords[2])
    local placedA = math.floor((freeCount + lockedCountB - lockedCountA) / 2 + 0.5)
    local minA = math.max(0, freeCount - capB)
    local maxA = math.min(freeCount, capA)
    if minA > maxA then
        result.reason = "The locked players don't fit the team layout."
        return result
    end
    if placedA < minA then placedA = minA end
    if placedA > maxA then placedA = maxA end

    -- search: choose `placedA` of the free players for side A, minimising rating imbalance against
    -- the half-totals (the cheap heuristic the legacy used — never trueskill, which is too costly here)
    local goalMean = totalMean / 2
    local goalDev = totalDev / 2
    local best = { value = nil, chosen = nil }
    local evaluations = 0
    local current = {}

    local function evaluate()
        local meanA, devA = lockedMean[1], lockedDev[1]
        for i = 1, table.getn(current) do
            local player = freeUnits[current[i]].player
            meanA = meanA + MeanOf(player)
            devA = devA + DevOf(player)
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

    -- partition the free units into the two sides per the best split
    local chosen = {}
    if best.chosen then
        for _, index in ipairs(best.chosen) do
            chosen[index] = true
        end
    end
    local freeA, freeB = {}, {}
    for i = 1, freeCount do
        table.insert(chosen[i] and freeA or freeB, freeUnits[i])
    end

    -- record one seat into the arrangement + the preview list
    local function record(slot, player, side, team)
        result.arrangement[slot] = { OwnerId = player.OwnerID, Team = team }
        table.insert(result.sides[side], player)
    end

    -- locked players keep their seat; in manual mode their Team is (re)stamped to their side
    for side = 1, 2 do
        for i = 1, table.getn(lockedRecords[side]) do
            record(lockedSeats[side][i], lockedRecords[side][i], side, manual and TeamForSide[side] or nil)
        end
    end

    if manual then
        -- teams are reassigned in place: each free player keeps its seat, its Team set to its side.
        -- No positional shuffle — seats don't determine team here.
        for _, unit in ipairs(freeA) do record(unit.slot, unit.player, 1, TeamForSide[1]) end
        for _, unit in ipairs(freeB) do record(unit.slot, unit.player, 2, TeamForSide[2]) end
    else
        -- positional: place players into the side's free seats, with a mirrored-pair shuffle so
        -- equivalent positions across the two sides move together; team follows the seat at launch
        local playersA, playersB = {}, {}
        for _, unit in ipairs(freeA) do table.insert(playersA, unit.player) end
        for _, unit in ipairs(freeB) do table.insert(playersB, unit.player) end
        local pairCount = math.min(table.getn(playersA), table.getn(playersB))
        for i = 1, pairCount do
            local r = Random(i, pairCount)
            playersA[i], playersA[r] = playersA[r], playersA[i]
            playersB[i], playersB[r] = playersB[r], playersB[i]
        end
        for i = 1, table.getn(playersA) do record(freeSeats[1][i], playersA[i], 1, nil) end
        for i = 1, table.getn(playersB) do record(freeSeats[2][i], playersB[i], 2, nil) end
    end

    for side = 1, 2 do
        local total = 0
        for _, player in ipairs(result.sides[side]) do
            total = total + (player.PL or 0)
        end
        result.totals[side] = total
    end

    result.quality = ComputeQuality(result.sides)
    result.feasible = freeCount > 0
    if freeCount == 0 then
        result.reason = "Every player is locked in place — nothing to rearrange."
    end
    return result
end
