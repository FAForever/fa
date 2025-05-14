--**************************************************************************************************
--** Shared under the MIT license
--**************************************************************************************************

-- collect recall parameters (note it is not imported)
doscript "/lua/shared/recallparams.lua"

-- TODO: generalize to abstract voting system, decoupled from recall

local SyncAnnouncement = import("/lua/simdiplomacy.lua").SyncAnnouncement

---@alias CannotRecallReason 
---| false
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
    if GetFocusArmy() == -1 then
        SyncCancelRecallVote()
        SyncRecallStatus()
    else
        ResyncRecallVoting()
    end
end

---@param army integer
function OnArmyDefeat(army)
    local focus = GetFocusArmy()
    if focus ~= -1 and IsAlly(army, focus) then
        -- the rest of the code knows to ignore defeated players, just resync so the
        -- UI can update the number of blocks
        ResyncRecallVoting()
    end
end

---@param data {From: number, To: number}
function OnAllianceChange(data)
    local armyFrom, armyTo = data.From, data.To
    local oldTeamSize = 0
    local oldTeam = {}
    local votingThreadBrain
    for index, ally in ArmyBrains do
        if (IsAlly(armyFrom, index) or IsAlly(armyTo, index)) and not ArmyIsCivilian(index) then
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
        votingThreadBrain.RecallVoteCancelled = true
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
local function RecallRequestCooldown(lastTeamVote, lastPlayerRequest, playerGatein)
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

    if brain:IsDefeated() then
        return "observer"
    end
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
    if requestingBrain.RecallVoteCancelled then
        if focus ~= -1 and IsAlly(requestingArmy, focus) then
            SyncCancelRecallVote()
            SyncRecallStatus()
        end
        requestingBrain.RecallVoteCancelled = nil
        requestingBrain.RecallVoteStartTime = nil
        requestingBrain.recallVotingThread = nil
        return
    end

    local gametick = GetGameTick()
    local yesVotes = 0
    local noVotes = 0
    local teamSize = 0
    local team = {}
    for index, brain in ArmyBrains do
        if not IsAlly(requestingArmy, brain.Army) or ArmyIsCivilian(index) then
            continue
        end

        if not brain:IsDefeated() then
            teamSize = teamSize + 1
            team[teamSize] = brain
            if brain.RecallVote ~= nil then
                if brain.RecallVote then
                    yesVotes = yesVotes + 1
                else
                    noVotes = noVotes + 1
                end
            end
            brain.LastRecallVoteTime = gametick
        end
        brain.RecallVote = nil -- make sure defeated players get reset too
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
    local msgEnding = yesVotes .. " to " .. noVotes .. " [" .. (teamSize - yesVotes - noVotes) .. " abstained] )"
    if recallPassed then
        SPEW("Recalling team " .. listTeam .. " at the request of " .. requestingBrain.Nickname .. " (vote passed " .. msgEnding)
        for _, brain in team do
            brain:RecallAllCommanders()
        end
    else
        SPEW("Not recalling team " .. listTeam .. " (vote failed " .. msgEnding)
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
        local foundThread = false
        for index, ally in ArmyBrains do
            if army ~= index and IsAlly(army, index) then
                local thread = ally.recallVotingThread
                if thread then
                    ResumeThread(thread) -- end voting period
                    foundThread = true
                    break
                end
            end
        end
        if not foundThread then
            SPEW("Unable to find recall voting thread for " .. GetArmyBrain(army).Nickname .. '!')
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
        if army ~= index and IsAlly(army, index) and not ArmyIsCivilian(index) then
            if not ally:IsDefeated() then
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
            elseif ally.recallVotingThread then
                isRequest = false
            end
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
            SPEW("Recall request from " .. brain.Nickname .. " for " .. table.concat(team, ", "))
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
        if not lastVote then
            if vote then
                -- will succeed with our vote
                lastVote = RecallRequestAccepted(likeVotes + 1, teammates + 1)
            else
                -- won't ever be able to succeed
                -- teammates - votes against = teammates that could vote for recall
                lastVote = not RecallRequestAccepted(teammates + 1 - (likeVotes + 1), teammates + 1)
            end
        end
        ArmyVoteRecall(army, vote, lastVote)
    end
end


--------------------
--#region Sync
--------------------

local function GetRecallSyncTable()
    local sync = Sync.RecallRequest
    if not sync then
        sync = {}
        Sync.RecallRequest = sync
    end
    return sync
end

function ResyncRecallVoting()
    local focus = GetFocusArmy()
    local teamSize = 0
    local yes, no = 0, 0
    local votingThreadBrain
    local retainBlocks = false
    for index, brain in ArmyBrains do
        if IsAlly(focus, index) and not ArmyIsCivilian(index) then
            -- Found a voting thread. We really do need a better way to handle team data...
            if brain.recallVotingThread then
                votingThreadBrain = brain
                if brain:IsDefeated() then
                    retainBlocks = true
                end
            end
            -- it's possible a defeated player could have been the one to initiate the vote but 
            -- they don't count for votes
            if brain:IsDefeated() then
                continue
            end
            teamSize = teamSize + 1
            if brain.RecallVote ~= nil then
                if brain.RecallVote then
                    yes = yes + 1
                else
                    no = no + 1
                end
            end
        end
    end
    if votingThreadBrain then
        -- keep the block layout in the edge-case that there are 3 (or more) players
        -- and the original requester is defeated so there are only 2 players - both
        -- could still need to vote so the confirmation layout is inappropriate
        if teamSize <= 2 and not retainBlocks then
            teamSize = nil
        end

        local focusBrain = GetArmyBrain(focus)

        -- no need to add changes from `GetRecallSyncTable`, we need to reset everything anyway
        Sync.RecallRequest = {
            StartTime = votingThreadBrain.RecallVoteStartTime * 0.1, -- convert ticks to seconds
            Open = VoteTime * 0.1, -- convert ticks to seconds
            Blocks = teamSize,
            Yes = yes,
            No = no,
            CanVote = focusBrain.RecallVote == nil and not focusBrain:IsDefeated(),
        }
    end
    SyncRecallStatus()
end

---@param reason CannotRecallReason
function SyncCannotRequestRecall(reason)
    GetRecallSyncTable().CannotRequest = reason
end

---@param result boolean
function SyncCloseRecallVote(result)
    GetRecallSyncTable().Close = result
end

function SyncCancelRecallVote()
    GetRecallSyncTable().Cancel = true
end

---@param vote boolean
function SyncRecallVote(vote)
    local sync = GetRecallSyncTable()
    if vote then
        sync.Yes = (sync.Yes or 0) + 1
    else
        sync.No = (sync.No or 0) + 1
    end
end

---@param teamSize number
---@param army number
function SyncOpenRecallVote(teamSize, army)
    local sync = GetRecallSyncTable()
    local focus = GetFocusArmy()
    sync.Open = VoteTime * 0.1 -- convert ticks to seconds
    sync.CanVote = focus ~= -1 and army ~= focus and not GetArmyBrain(focus):IsDefeated()
    if teamSize > 2 then
        sync.Blocks = teamSize
    end
end

local UserRecallStatusThread

local function SyncRecallStatusThread()
    local reason, cooldown = ArmyRecallRequestCooldown(GetFocusArmy())
    while cooldown do
        SyncCannotRequestRecall(reason)

        -- may be interrupted for various reasons, such as the focus army changing
        -- this will be fine, we'll pick up the proper cooldown reason anyway and loop again
        WaitTicks(math.max(1, cooldown))

        reason, cooldown = ArmyRecallRequestCooldown(GetFocusArmy())
    end
    SyncCannotRequestRecall(reason)
    UserRecallStatusThread = nil
end

function SyncRecallStatus()
    if UserRecallStatusThread then
        ResumeThread(UserRecallStatusThread) -- force update the existing thread
    else
        UserRecallStatusThread = ForkThread(SyncRecallStatusThread)
    end
end

--#endregion
