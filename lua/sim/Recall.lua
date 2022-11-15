
-- import recall parameters
doscript "/lua/shared/RecallParams.lua"

local SyncAnnouncement = import("/lua/simdiplomacy.lua").SyncAnnouncement


---@alias CannotRecallReason false
---| "active"
---| "ai"
---| "gate"
---| "request"
---| "scenario"
---| "vote"
---| "observer"


function init()
    -- setup sim recall state in the brains
    local playerCooldown = PlayerGateCooldown - PlayerRequestCooldown
    local teamCooldown = PlayerGateCooldown - TeamVoteCooldown
    for _, brain in ArmyBrains do
        brain.LastRecallRequestTime = playerCooldown
        brain.LastRecallVoteTime = teamCooldown
    end

    -- setup user recall state notifier in this thread
    SyncRecallStatus()
end

function OnArmyChange()
    local focus = GetFocusArmy()
    if focus == -1 then
        SyncCancelRecallVote()
        SyncRecallStatus()
        return
    end
    local teamSize = 0
    local accept, veto = 0, 0
    local votingThreadBrain
    for index, brain in ArmyBrains do
        if IsAlly(focus, index) and not ArmyIsCivilian(index) then
            -- Found a voting thread. We really do need a better way to handle team data...
            teamSize = teamSize + 1
            if brain.Vote ~= nil then
                if brain.Vote then
                    accept = accept + 1
                else
                    veto = veto + 1
                end
            end
            if brain.recallVotingThread then
                votingThreadBrain = brain
            end
        end
    end
    if votingThreadBrain then
        Sync.RecallRequest = {
            StartTime = votingThreadBrain.RecallVoteStartTime,
            Open = VoteTime * 0.1,
            Blocks = teamSize,
            Accept = accept,
            Veto = veto,
            CanVote = GetArmyBrain(focus).Vote ~= nil,
        }
    end
    SyncRecallStatus()
end

---@param data {From: number, To: number}
function OnAllianceChange(data)
    local armyFrom, armyTo = data.From, data.To
    local oldTeammates = 0
    local oldTeam = {}
    local votingThreadBrain
    for index, ally in ArmyBrains do
        if (IsAlly(armyFrom, index) or IsAlly(armyTo, index))
            and not ally:IsDefeated()
            and not ArmyIsCivilian(index)
        then
            oldTeammates = oldTeammates + 1
            oldTeam[oldTeammates] = ally.Nickname
            -- Found a voting thread. We really do need a better way to handle team data...
            if ally.recallVotingThread then
                votingThreadBrain = ally
            end
        end
    end
    if votingThreadBrain then
        SPEW("Canceling recall voting for team " .. table.concat(oldTeam, ", ") .. " due to alliance break")
        votingThreadBrain.VoteCancelled = true
        coroutine.resume(votingThreadBrain.recallVotingThread)
        if IsAlly(votingThreadBrain, GetFocusArmy()) then
            SyncCancelRecallVote()
            SyncRecallStatus()
        end
    end
end


---@param lastTeamVote number
---@param lastPlayerRequest number
---@param playerGatein? number
---@return CannotRecallReason CannotRecallReason
---@return number? cooldown
function RecallRequestCooldown(lastTeamVote, lastPlayerRequest, playerGatein)
    -- note that this doesn't always return the reason that currently has the longest cooldown, it
    -- returns the more "fundamental" one (i.e. the reason whose base cooldown is longest)
    -- this is more useful in reporting the reason, and isn't a problem when put in a loop
    local gametime = GetGameTick()
    local gateCooldown = (playerGatein or 0) + PlayerGateCooldown - gametime
    if gateCooldown > 0 then
        return "gate", gateCooldown
    end
    local reqCooldown = lastPlayerRequest + PlayerRequestCooldown - gametime
    if reqCooldown > 0 then
        return "request", reqCooldown
    end
    local voteCooldown = lastTeamVote + TeamVoteCooldown - gametime
    if voteCooldown > 0 then
        return "vote", voteCooldown
    end
    return false
end

--- Returns the current reason an army cannot request recall and the cooldown of that reason, or
--- false
---@param army Army
---@return CannotRecallReason
---@return number? cooldown no timeout/cooldown if absent
function ArmyRecallRequestCooldown(army)
    if army == -1 then
        return "observer"
    end
    local brain = GetArmyBrain(army)
    if ScenarioInfo.RecallDisabled then
        return "scenario"
    end
    if brain.RecallVote ~= nil then
        return "active", VoteTime
    end
    local lastPlayerRequest = brain.LastRecallRequestTime
    local lastTeamVote
    army = brain.Army
    lastTeamVote = lastPlayerRequest
    for index, ally in ArmyBrains do
        if IsAlly(army, index) and not ally:IsDefeated() and not ArmyIsCivilian(index) then
            if ally.BrainType ~= "Human" then
                return "ai"
            end
            local allyTeamVote = ally.LastRecallVoteTime
            if allyTeamVote < lastTeamVote then
                lastTeamVote = allyTeamVote
            end
        end
    end
    -- if someone adds a feature that gates in commanders at different times, that time should be
    -- added as an argument to this method call
    return RecallRequestCooldown(lastTeamVote, lastPlayerRequest)
end

---@param requestingArmy number
local function RecallVotingThread(requestingArmy)
    local requestingBrain = GetArmyBrain(requestingArmy)
    requestingBrain.RecallVoteStartTime = GetGameTick()
    WaitTicks(VoteTime) -- may be interrupted if the vote closes or is canceled by an alliance break

    local focus = GetFocusArmy()
    if requestingBrain.VoteCancelled then
        if IsAlly(requestingArmy, focus) then
            SyncCancelRecallVote()
            SyncRecallStatus()
        end
        requestingBrain.VoteCancelled = nil
        requestingBrain.RecallVoteStartTime = nil
        requestingBrain.recallVotingThread = nil
        return
    end

    local gametick = GetGameTick()
    local recallAcceptance = 0
    local teammates = 0
    local team = {}
    for index, brain in ArmyBrains do
        if not brain:IsDefeated() and IsAlly(requestingArmy, brain.Army) and not ArmyIsCivilian(index) then
            teammates = teammates + 1
            team[teammates] = brain
            if brain.RecallVote then
                recallAcceptance = recallAcceptance + 1
            end
            brain.RecallVote = nil
            brain.LastRecallVoteTime = gametick
        end
    end
    -- this function is found in the recall params file, for those looking
    local recallAccepted = RecallRequestAccepted(recallAcceptance, teammates)
    if IsAlly(focus, requestingArmy) then
        SyncCloseRecallVote(recallAccepted)
        -- the recall UI will handle the announcement in this case
    elseif recallAccepted then
        -- in this case though, we need to handle the announcement
        SyncAnnouncement {
            Action = "recall",
            Team = requestingBrain.Nickname,
        }
    end
    local listTeam = team[1].Nickname
    for i = 2, table.getn(team) do
        listTeam = listTeam .. ", " .. team[i].Nickname
    end
    if recallAccepted then
        SPEW("Recalling team " .. listTeam .. " at the request of " .. requestingBrain.Nickname .. " (vote passed " .. recallAcceptance .. " to " .. (teammates - recallAcceptance ) .. ")")
        for _, brain in team do
            brain:RecallAllCommanders()
        end
    else
        SPEW("Not recalling team " .. listTeam .. " (vote failed " .. recallAcceptance .. " to " .. (teammates - recallAcceptance ) .. ")")
        requestingBrain.LastRecallRequestTime = gametick
    end
    if IsAlly(requestingArmy, focus) then
        -- update UI once the cooldown dissipates
        SyncRecallStatus()
    end
    requestingBrain.RecallVoteStartTime = nil
    requestingBrain.recallVotingThread = nil
end

---@param army number
---@param vote boolean
---@param lastVote boolean
---@return boolean # if further user sync should happen
local function ArmyVoteRecall(army, vote, lastVote)
    if lastVote then
        for index, ally in ArmyBrains do
            if army ~= index and IsAlly(army, index) and not ally:IsDefeated() then
                local thread = ally.recallVotingThread
                if thread then
                    -- end voting period
                    coroutine.resume(thread)
                    break
                end
            end
        end
    end

    local focus = GetFocusArmy()
    if focus == -1 or not IsAlly(focus, army) then
        return false -- don't update the recall panel for votes we aren't a part of or for observers
    end
    SyncRecallVote(vote)
    if army == focus then
        SyncCannotRequestRecall("active")
    end
    return true
end

---@param army number
---@param teammates number
local function ArmyRequestRecall(army, teammates)
    local brain = GetArmyBrain(army)
    if teammates > 0 then
        brain.recallVotingThread = ForkThread(RecallVotingThread, army)
        if ArmyVoteRecall(army, true, false) then
            SyncOpenRecallVote(teammates + 1, army)
        end
    else
        -- it's just us; recall our army
        SPEW("Recalling " .. brain.Nickname)
        brain:RecallAllCommanders()

    end
end

---@param data {From: number, Vote: boolean}
function SetRecallVote(data)
    local army = data.From
    if not OkayToMessWithArmy(army) then
        return
    end
    local focus = GetFocusArmy()
    if not ScenarioInfo.TeamGame then
        if army == focus then
            SyncCannotRequestRecall("scenario")
        end
        return
    end
    local vote = data.Vote and true or false

    -- determine team voting status
    local isRequest = true
    local lastVote = true
    local teammates = 0
    local team = {}
    for index, ally in ArmyBrains do
        if army ~= index and not ally:IsDefeated() and IsAlly(army, index) and not ArmyIsCivilian(index) then
            if ally.BrainType ~= "Human" then
                if army == focus then
                    SyncCannotRequestRecall("ai")
                end
                return
            end
            local allyHasVoted = ally.RecallVote ~= nil
            lastVote = lastVote and allyHasVoted -- only the last vote if all allies have also voted
            isRequest = isRequest and not allyHasVoted -- only the last vote if no allies have voted
            teammates = teammates + 1
            team[teammates] = ally.Nickname
        end
    end

    local brain = GetArmyBrain(army)
    if isRequest then
        -- the player is making a recall request; this will reset their recall request cooldown
        local reason = ArmyRecallRequestCooldown(army)
        if reason then
            if army == focus then
                SyncCannotRequestRecall(reason)
            end
            return
        end
        SPEW("Army " .. tostring(army) .. " is requesting recall for " .. table.concat(team, ','))
        brain.RecallVote = vote
        ArmyRequestRecall(army, teammates)
    else
        -- the player is responding to a recall request; we don't count this against their
        -- individual recall request cooldown
        SPEW("Army " .. tostring(army) .. " recall vote: " .. (vote and "accept" or "veto"))
        brain.RecallVote = vote
        ArmyVoteRecall(army, vote, lastVote)
    end
end


---@param reason CannotRecallReason
function SyncCannotRequestRecall(reason)
    local recallSync = Sync.RecallRequest
    if not recallSync then
        Sync.RecallRequest = {CannotRequest = reason}
    else
        recallSync.CannotRequest = reason
    end
end

---@param result boolean
function SyncCloseRecallVote(result)
    local recallSync = Sync.RecallRequest
    if not recallSync then
        Sync.RecallRequest = {Close = result}
    else
        recallSync.Close = result
    end
end

function SyncCancelRecallVote()
    local recallSync = Sync.RecallRequest
    if not recallSync then
        Sync.RecallRequest = {Cancel = true}
    else
        recallSync.Cancel = true
    end
end

---@param vote boolean
function SyncRecallVote(vote)
    local recallSync = Sync.RecallRequest
    if not recallSync then
        recallSync = {}
        Sync.RecallRequest = recallSync
    end
    if vote then
        recallSync.Accept = (recallSync.Accept or 0) + 1
    else
        recallSync.Veto = (recallSync.Veto or 0) + 1
    end
end

---@param teamSize number
---@param army number
function SyncOpenRecallVote(teamSize, army)
    local recallSync = Sync.RecallRequest
    if not recallSync then
        recallSync = {}
        Sync.RecallRequest = recallSync
    end
    local focus = GetFocusArmy()
    recallSync.Open = VoteTime * 0.1
    recallSync.CanVote = focus ~= -1 and army ~= focus
    recallSync.Blocks = teamSize
end

local UserRecallStatusThread

local function SyncRecallStatusThread()
    local reason, cooldown = ArmyRecallRequestCooldown(GetFocusArmy())
    while reason do
        SyncCannotRequestRecall(reason)
        if not cooldown then
            UserRecallStatusThread = nil
            return
        end
        -- may be interrupted for various reasons, such as the focus army changing
        -- this will be fine, we'll pick up the proper cooldown reason anyway and loop again
        WaitTicks(cooldown)

        reason, cooldown = ArmyRecallRequestCooldown(GetFocusArmy())
    end
    SyncCannotRequestRecall(false)
    UserRecallStatusThread = nil
end

function SyncRecallStatus()
    if UserRecallStatusThread then
        coroutine.resume(UserRecallStatusThread) -- force update the existing thread
    else
        UserRecallStatusThread = ForkThread(SyncRecallStatusThread)
    end
end
