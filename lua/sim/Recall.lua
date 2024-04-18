--**************************************************************************************************
--** Shared under the MIT license
--**************************************************************************************************

-- collect recall parameters (note it is not imported)
doscript "/lua/shared/RecallParams.lua"

-- TODO: generalize to abstract voting system, decoupled from recall

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
    local yes, no = 0, 0
    local votingThreadBrain
    for index, brain in ArmyBrains do
        if IsAlly(focus, index) and not ArmyIsCivilian(index) then
            -- Found a voting thread. We really do need a better way to handle team data...
            teamSize = teamSize + 1
            if brain.Vote ~= nil then
                if brain.Vote then
                    yes = yes + 1
                else
                    no = no + 1
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
            Yes = yes,
            No = no,
            CanVote = GetArmyBrain(focus).Vote ~= nil,
        }
    end
    SyncRecallStatus()
end

---@param data {From: number, To: number}
function OnAllianceChange(data)
    local armyFrom, armyTo = data.From, data.To
    local oldTeamSize = 0
    local oldTeam = {}
    local votingThreadBrain
    for index, ally in ArmyBrains do
        if (IsAlly(armyFrom, index) or IsAlly(armyTo, index))
            and not ally:IsDefeated()
            and not ArmyIsCivilian(index)
        then
            oldTeamSize = oldTeamSize + 1
            oldTeam[oldTeamSize] = ally.Nickname
            -- Found a voting thread. We really do need a better way to handle team data...
            if ally.recallVotingThread then
                votingThreadBrain = ally
            end
        end
    end
    if votingThreadBrain then
        SPEW("Canceling recall voting for team " .. table.concat(oldTeam, ", ") .. " due to alliance break")
        votingThreadBrain.VoteCancelled = true
        ResumeThread(votingThreadBrain.recallVotingThread)
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
    -- this is more useful in reporting the reason, and isn't a problem as the reason checker is a loop
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
    -- note that this logic doesn't currently take into account the gate-in times of other teammates
    return RecallRequestCooldown(lastTeamVote, lastPlayerRequest)
end

---@param requestingArmy number
local function RecallVotingThread(requestingArmy)
    local requestingBrain = GetArmyBrain(requestingArmy)
    requestingBrain.RecallVoteStartTime = GetGameTick()
    WaitTicks(VoteTime) -- may be interrupted if the vote closes or is canceled by an alliance break

    local focus = GetFocusArmy()
    if requestingBrain.VoteCancelled then
        if focus ~= -1 and IsAlly(requestingArmy, focus) then
            SyncCancelRecallVote()
            SyncRecallStatus()
        end
        requestingBrain.VoteCancelled = nil
        requestingBrain.RecallVoteStartTime = nil
        requestingBrain.recallVotingThread = nil
        return
    end

    local gametick = GetGameTick()
    local yesVotes = 0
    local teamSize = 0
    local team = {}
    for index, brain in ArmyBrains do
        if not brain:IsDefeated() and IsAlly(requestingArmy, brain.Army) and not ArmyIsCivilian(index) then
            teamSize = teamSize + 1
            team[teamSize] = brain
            if brain.RecallVote then
                yesVotes = yesVotes + 1
            end
            brain.RecallVote = nil
            brain.LastRecallVoteTime = gametick
        end
    end
    -- this function is found in the recall params file, for those looking
    local recallPassed = RecallRequestAccepted(yesVotes, teamSize)
    if focus ~= -1 and IsAlly(focus, requestingArmy) then
        SyncCloseRecallVote(recallPassed)
        -- the recall UI will handle the announcement in this case
    elseif recallPassed then
        -- in this case though, we need to handle the announcement
        SyncAnnouncement {
            Action = "recall",
            Team = requestingBrain.Nickname,
        }
    end
    local listTeam = team[1].Nickname
    for i = 2, teamSize do
        listTeam = listTeam .. ", " .. team[i].Nickname
    end
    if recallPassed then
        SPEW("Recalling team " .. listTeam .. " at the request of " .. requestingBrain.Nickname .. " (vote passed " .. yesVotes .. " to " .. (teamSize - yesVotes ) .. ")")
        for _, brain in team do
            brain:RecallAllCommanders()
        end
    else
        SPEW("Not recalling team " .. listTeam .. " (vote failed " .. yesVotes .. " to " .. (teamSize - yesVotes ) .. ")")
        requestingBrain.LastRecallRequestTime = gametick
    end
    if focus ~= -1 and IsAlly(requestingArmy, focus) then
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
                    ResumeThread(thread) -- end voting period
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
    local brain = GetArmyBrain(army)
    if brain:IsDefeated() then
        SyncCannotRequestRecall("observer")
        SPEW("Defeated army " .. tostring(army) .. " (" .. GetArmyBrain(army).Nickname .. ") trying to vote for recall!")
        return
    end
    local vote = data.Vote and true or false

    -- determine team voting status
    local isRequest = true
    local lastVote = true
    local likeVotes = 0
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
            if ally.RecallVote == vote then
                likeVotes = likeVotes + 1
            end

            local allyHasVoted = ally.RecallVote ~= nil
            lastVote = lastVote and allyHasVoted -- only the last vote if all allies have also voted
            isRequest = isRequest and not allyHasVoted -- only a request if no allies have voted yet
            teammates = teammates + 1
            team[teammates] = ally.Nickname
        end
    end

    if isRequest then
        -- the player is making a recall request; this will reset their recall request cooldown
        local reason = ArmyRecallRequestCooldown(army)
        if reason then
            if army == focus then
                SyncCannotRequestRecall(reason)
            end
            return
        end
        if teammates > 0 then
            SPEW("Recall request from " .. brain.Nickname .. " for " .. table.concat(team, ','))
        else
            SPEW("Recalling " .. brain.Nickname)
        end
        brain.RecallVote = vote
        ArmyRequestRecall(army, teammates)
    else
        -- the player is responding to a recall request; we don't count this against their
        -- individual recall request cooldown
        SPEW("Recall vote for " .. brain.Nickname .. ": " .. (vote and "yes" or "no"))
        brain.RecallVote = vote

        -- if the vote will already be decided with this vote, close the voting session
        if not lastVote and (
            vote and RecallRequestAccepted(likeVotes + 1, teammates) or -- will succeed with our vote
            not vote and not RecallRequestAccepted(teammates - (likeVotes + 1), teammates) -- won't ever be able to succeed
        ) then
            lastVote = true
        end
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
        recallSync.Yes = (recallSync.Yes or 0) + 1
    else
        recallSync.No = (recallSync.No or 0) + 1
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
        if cooldown < 1 then
            WaitTicks(1)
        else
            WaitTicks(cooldown)
        end

        reason, cooldown = ArmyRecallRequestCooldown(GetFocusArmy())
    end
    SyncCannotRequestRecall(false)
    UserRecallStatusThread = nil
end

function SyncRecallStatus()
    if UserRecallStatusThread then
        ResumeThread(UserRecallStatusThread) -- force update the existing thread
    else
        UserRecallStatusThread = ForkThread(SyncRecallStatusThread)
    end
end
