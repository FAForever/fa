--*****************************************************************************
--* File: lua/ui/lobby/autobalance.lua
--* Summary: Autobalance, team assignment, spawn randomisation, AI name assignment.
--*          Extracted from lobby.lua for maintainability.
--*****************************************************************************

-- Upvalues injected by lobby.lua via Autobalance.Init()
local gameInfo
local GUI
local LobbyComm
local SetPlayerOption
local SetSlotInfo
local GetNumAvailStartSpots
local HostUtils
local Trueskill
local Player
local Rating
local Teams
local FactionData

function Init(deps)
    gameInfo      = deps.gameInfo
    GUI           = deps.GUI
    LobbyComm     = deps.LobbyComm
    SetPlayerOption = deps.SetPlayerOption
    SetSlotInfo   = deps.SetSlotInfo
    GetNumAvailStartSpots = deps.GetNumAvailStartSpots
    HostUtils     = deps.HostUtils
    Trueskill     = deps.Trueskill
    Player        = deps.Player
    Rating        = deps.Rating
    Teams         = deps.Teams
    FactionData   = deps.FactionData
end

------------------------------------------------------------
-- Internal helpers
------------------------------------------------------------

local function team_sort_by_sum(t1, t2)
    return t1['sum'] < t2['sum']
end

local function autobalance_bestworst(players, teams_arg)
    local players = table.deepcopy(players)
    local result = {}
    local best = true
    local teams = {}

    for t, slots in teams_arg do
        table.insert(teams, {team=t, slots=table.deepcopy(slots), sum=0})
    end

    while not table.empty(players) do
        for i, t in teams do
            local team = t['team']
            local slots = t['slots']
            local slot = table.remove(slots, 1)
            if not slot then continue end
            local player

            if best then
                player = table.remove(players, 1)
            else
                player = table.remove(players)
            end

            if not player then break end

            teams[i]['sum'] = teams[i]['sum'] + player['rating']
            table.insert(result, {player=player['pos'], rating=player['rating'], team=team, slot=slot})
        end

        best = not best
        if best then
            table.sort(teams, team_sort_by_sum)
        end
    end

    return result
end

local function autobalance_avg(players, teams_arg)
    local players = table.deepcopy(players)
    local result = {}
    local teams = {}
    local max_sum = 0

    for t, slots in teams_arg do
        table.insert(teams, {team=t, slots=table.deepcopy(slots), sum=0})
    end

    while not table.empty(players) do
        local first_team = true
        for i, t in teams do
            local team = t['team']
            local slots = t['slots']
            local slot = table.remove(slots, 1)
            if not slot then continue end
            local player
            local player_key

            for j, p in players do
                player_key = j
                if first_team or t['sum'] + p['rating'] <= max_sum then
                    break
                end
            end

            player = table.remove(players, player_key)
            if not player then break end

            teams[i]['sum'] = teams[i]['sum'] + player['rating']
            max_sum = math.max(max_sum, teams[i]['sum'])
            table.insert(result, {player=player['pos'], rating=player['rating'], team=team, slot=slot})
            first_team = false
        end

        table.sort(teams, team_sort_by_sum)
    end

    return result
end

local function autobalance_rr(players, teams)
    local players = table.deepcopy(players)
    local teams = table.deepcopy(teams)
    local result = {}

    local team_picks = {}
    local i = 1
    for team, slots in teams do
        table.insert(team_picks, {team=team, sum=i})
        i = i + 1
    end

    while not table.empty(players) do
        for i, pick in team_picks do
            local slot = table.remove(teams[pick.team], 1)
            if not slot then continue end
            local player = table.remove(players, 1)
            if not player then break end
            pick.sum = pick.sum + i

            table.insert(result, {player=player.pos, rating=player.rating, team=pick.team, slot=slot})
        end

        table.sort(team_picks, function(a, b) return a.sum > b.sum end)
    end

    return result
end

local function autobalance_random(players, teams_arg)
    local players = table.deepcopy(players)
    local result = {}
    local teams = {}

    players = table.shuffle(players)

    for t, slots in teams_arg do
        table.insert(teams, {team=t, slots=table.deepcopy(slots)})
    end

    while not table.empty(players) do
        for _, t in teams do
            local team = t['team']
            local slot = table.remove(t['slots'], 1)
            if not slot then continue end
            local player = table.remove(players, 1)

            if not player then break end

            table.insert(result, {player=player['pos'], rating=player['rating'], team=team, slot=slot})
        end
    end

    return result
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------

function ComputeQuality(players)
    local teams = nil
    local quality = 0

    for _, p in players do
        local i = p['player']
        local team = p['team']
        local playerInfo = gameInfo.PlayerOptions[i]
        local player = Player.create(playerInfo.PlayerName,
                                     Rating.create(playerInfo.MEAN or 1500, playerInfo.DEV or 500))

        if not teams then
            teams = Teams.create()
        end

        teams:addPlayer(team, player)
    end

    if teams and table.getn(teams:getTeams()) > 1 then
        quality = Trueskill.computeQuality(teams)
    end

    return quality
end

-- Keep old global name as alias so existing callers in lobby.lua still work.
autobalance_quality = ComputeQuality

function AssignRandomStartSpots()
    local teamSpawn = gameInfo.GameOptions['TeamSpawn']

    if teamSpawn == 'fixed' or teamSpawn == 'penguin_autobalance' then
        return
    end

    local function teamsAddSpot(teams, team, spot)
        if not teams[team] then
            teams[team] = {}
        end
        table.insert(teams[team], spot)
    end

    local function rearrangePlayers(data)
        gameInfo.GameOptions['Quality'] = data.quality

        local orgPlayerOptions = {}
        for k, p in gameInfo.PlayerOptions do
            orgPlayerOptions[k] = p
        end

        local mirrored = string.find(teamSpawn, 'mirrored')
        if mirrored then
            local rating_cmp = function(a,b) return a.rating > b.rating end
            local slot_cmp = function(a,b) return a.slot < b.slot end

            local function getMasterOrder(sortedSlots)
                local masterOrder = {}
                local slot2nr = {}
                for k, p in sortedSlots.byNr do
                    slot2nr[p.slot] = k
                end
                for k, p in sortedSlots.byRating do
                    table.insert(masterOrder, slot2nr[p.slot])
                end
                return masterOrder
            end

            local function teamsSameSize(slots)
                local size
                for t, sorted in slots do
                    local s = table.getn(sorted.byNr)
                    if not size then size = s end
                    if size ~= s then return false end
                end
                return true
            end

            local function reorderSlots(sortedSlots, masterOrder)
                local newSlots = {}
                for i, j in masterOrder do
                    table.insert(newSlots, sortedSlots.byNr[j].slot)
                end
                for i, s in newSlots do
                    sortedSlots.byRating[i].slot = s
                end
            end

            local slots = {}
            local masterTeam

            for _, p in data.setup do
                if not slots[p.team] then slots[p.team] = {} end
                if not slots[p.team].byNr then slots[p.team].byNr = {} end
                if not slots[p.team].byRating then slots[p.team].byRating = {} end
                if not masterTeam then masterTeam = p.team end

                table.binsert(slots[p.team].byNr, p, slot_cmp)
                table.binsert(slots[p.team].byRating, p, rating_cmp)
            end

            if not teamsSameSize(slots) then
                WARN("Mirroring disabled due to teams not having the same number of players")
            else
                local masterOrder = getMasterOrder(slots[masterTeam])
                for t, sorted in slots do
                    reorderSlots(sorted, masterOrder)
                end
            end
        end

        gameInfo.PlayerOptions = {}
        for _, r in data.setup do
            local playerOptions = orgPlayerOptions[r.player]
            playerOptions.Team = r.team + 1
            playerOptions.StartSpot = r.slot
            gameInfo.PlayerOptions[r.slot] = playerOptions

            local playerInfo = gameInfo.PlayerOptions[r.slot]
            HostUtils.SendPlayerSettingsToServer(r.slot)
        end
    end

    local numAvailStartSpots = GetNumAvailStartSpots()

    local AutoTeams = gameInfo.GameOptions.AutoTeams
    local positionGroups = {}
    local teams = {}

    local synthesizedTeamCounter = 9
    for i = 1, numAvailStartSpots do
        if not gameInfo.ClosedSlots[i] then
            local team = nil
            local group = nil

            if AutoTeams == 'lvsr' then
                local midLine = GUI.mapView.Left() + (GUI.mapView.Width() / 2)
                local markerPos = GUI.mapView.startPositions[i].Left()
                if markerPos < midLine then team = 2 else team = 3 end
            elseif AutoTeams == 'tvsb' then
                local midLine = GUI.mapView.Top() + (GUI.mapView.Height() / 2)
                local markerPos = GUI.mapView.startPositions[i].Top()
                if markerPos < midLine then team = 2 else team = 3 end
            elseif AutoTeams == 'pvsi' then
                if math.mod(i, 2) ~= 0 then team = 2 else team = 3 end
            elseif AutoTeams == 'manual' then
                team = gameInfo.AutoTeams[i]
            else -- none
                team = gameInfo.PlayerOptions[i].Team
                group = 1
            end

            group = group or team
            if not positionGroups[group] then
                positionGroups[group] = {}
            end
            table.insert(positionGroups[group], i)

            if team ~= nil then
                if team == 1 then
                    team = synthesizedTeamCounter
                    synthesizedTeamCounter = synthesizedTeamCounter + 1
                end
                teamsAddSpot(teams, team, i)
            end
        end
    end
    gameInfo.GameOptions.RandomPositionGroups = positionGroups

    for i, team in teams do
        teams[i] = table.shuffle(team)
    end
    teams = table.shuffle(teams)

    local ratingTable = {}
    for i = 1, numAvailStartSpots do
        local playerInfo = gameInfo.PlayerOptions[i]
        if playerInfo then
            table.insert(ratingTable, { pos=i, rating = playerInfo.MEAN - playerInfo.DEV * 3 })
        end
    end

    if teamSpawn == 'random' or teamSpawn == 'random_reveal' then
        local s = autobalance_random(ratingTable, teams)
        local q = ComputeQuality(s)
        rearrangePlayers{setup=s, quality=q}
        return
    end

    ratingTable = table.shuffle(ratingTable)
    table.sort(ratingTable, function(a, b) return a['rating'] > b['rating'] end)

    local setups = {}
    local functions = {
        rr=autobalance_rr,
        bestworst=autobalance_bestworst,
        avg=autobalance_avg,
    }

    local cmp = function(a, b) return a.quality > b.quality end
    local s, q
    for fname, f in functions do
        s = f(ratingTable, teams)
        if s then
            q = ComputeQuality(s)
            table.binsert(setups, {setup=s, quality=q}, cmp)
        end
    end

    local n_random = 0
    local frac = (teamSpawn == 'balanced_flex' or teamSpawn == 'balanced_flex_reveal') and 0.95 or 1
    for i=1, 100 do
        s = autobalance_random(ratingTable, teams)
        q = ComputeQuality(s)

        if q > setups[1].quality * frac then
            table.binsert(setups, {setup=s, quality=q}, cmp)
            n_random = n_random + 1
            if n_random > 2 then break end
        end
    end

    if teamSpawn == 'balanced_flex' or teamSpawn == 'balanced_flex_reveal' then
        setups = table.shuffle(setups)
    end

    local best = table.remove(setups, 1)
    rearrangePlayers(best)
end

function AssignAutoTeams()
    local getTeam
    if gameInfo.GameOptions.AutoTeams == 'lvsr' then
        local midLine = GUI.mapView.Left() + (GUI.mapView.Width() / 2)
        local startPositions = GUI.mapView.startPositions
        getTeam = function(playerIndex)
            local markerPos = startPositions[playerIndex].Left()
            if markerPos < midLine then return 2 else return 3 end
        end
    elseif gameInfo.GameOptions.AutoTeams == 'tvsb' then
        local midLine = GUI.mapView.Top() + (GUI.mapView.Height() / 2)
        local startPositions = GUI.mapView.startPositions
        getTeam = function(playerIndex)
            local markerPos = startPositions[playerIndex].Top()
            if markerPos < midLine then return 2 else return 3 end
        end
    elseif gameInfo.GameOptions.AutoTeams == 'pvsi' or gameInfo.GameOptions['RandomMap'] ~= 'Off' then
        getTeam = function(playerIndex)
            if math.mod(playerIndex, 2) ~= 0 then return 2 else return 3 end
        end
    elseif gameInfo.GameOptions.AutoTeams == 'manual' then
        getTeam = function(playerIndex)
            return gameInfo.AutoTeams[playerIndex] or 1
        end
    else
        return
    end

    for i = 1, LobbyComm.maxPlayerSlots do
        if not gameInfo.ClosedSlots[i] and gameInfo.PlayerOptions[i] then
            local correctTeam = getTeam(i)
            if gameInfo.PlayerOptions[i].Team ~= correctTeam then
                SetPlayerOption(i, "Team", correctTeam, true)
                SetSlotInfo(i, gameInfo.PlayerOptions[i])
            end
        end
    end
end

function AssignAINames()
    local aiNames = import("/lua/ui/lobby/ainames.lua").ainames
    local nameSlotsTaken = {}
    for index, faction in FactionData.Factions do
        nameSlotsTaken[index] = {}
    end
    for index, player in gameInfo.PlayerOptions do
        if not player.Human then
            local playerFaction = player.Faction
            local factionNames = aiNames[FactionData.Factions[playerFaction].Key]
            local ranNum
            repeat
                ranNum = math.random(1, table.getn(factionNames))
            until nameSlotsTaken[playerFaction][ranNum] == nil
            nameSlotsTaken[playerFaction][ranNum] = true
            player.PlayerName = factionNames[ranNum] .. " (" .. player.PlayerName .. ")"
        end
    end
end
