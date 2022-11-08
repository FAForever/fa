
doscript "/lua/shared/RecallParams.lua"

---@alias CannotRecallReason "active" | "ai" | "gate" | "request" | "scenario" | "vote" | false

function init()
    for _, brain in ArmyBrains do
        brain.LastRecallRequestTime = PlayerGateCooldown - PlayerRequestCooldown
        brain.LastRecallVoteTime = PlayerGateCooldown - TeamVoteCooldown
    end
    ForkThread(function()
        if ScenarioInfo.RecallDisabled then
            Sync.RecallRequest = {CannotRequest = "scenario"}
        else
            Sync.RecallRequest = {CannotRequest = "gate"}
            WaitTicks(PlayerGateCooldown + 1)

            local focus = GetFocusArmy()
            local brain = GetArmyBrain(focus)
            for index, brainWith in ArmyBrains do
                if brain ~= brainWith then
                    if  not brain:IsDefeated() and
                        IsAlly(focus, index) and
                        brainWith.BrainType ~= "Human" and
                        not ArmyIsCivilian(index)
                    then
                        Sync.RecallRequest = {CannotRequest = "ai"}
                        return
                    end
                end
            end
            Sync.RecallRequest = {CannotRequest = false}
        end
    end)
end

---@param lastTeamVote number
---@param lastPlayerRequest number
---@param playerGatein? number
---@return number cooldown
---@return CannotRecallReason reason
function RecallRequestCooldown(lastTeamVote, lastPlayerRequest, playerGatein)
    playerGatein = playerGatein or 0
    local gametime = GetGameTick()
    local reqCooldown = lastPlayerRequest + PlayerRequestCooldown - gametime
    local voteCooldown = lastTeamVote + TeamVoteCooldown - gametime
    local gateCooldown = playerGatein + PlayerGateCooldown - gametime

    local largest, reason = reqCooldown, "request"
    if largest < voteCooldown then
        largest, reason = voteCooldown, "vote"
    end
    if largest < gateCooldown then
        largest, reason = gateCooldown, "gate"
    end
    if largest < 0 then
        return 0, false
    end
    return largest, reason
end

--- Returns the recall request cooldown for an army
---@param army Army
---@return number cooldown
---@return string reason
function ArmyRecallRequestCooldown(army)
    local brain = GetArmyBrain(army)
    if ScenarioInfo.RecallDisabled then
        return 36000, "scenario"
    end
    if brain.RecallVote ~= nil then
        return 36000, "active"
    end
    local lastPlayerRequest = brain.LastRecallRequestTime
    local lastTeamVote
    army = brain.Army
    lastTeamVote = lastPlayerRequest
    for index, ally in ArmyBrains do
        if not ally:IsDefeated() and IsAlly(army, index) and not ArmyIsCivilian(index) then
            local allyTeamVote = ally.LastRecallVoteTime
            if allyTeamVote < lastTeamVote then
                lastTeamVote = allyTeamVote
            end
        end
    end
    return RecallRequestCooldown(lastTeamVote, lastPlayerRequest)
end

---@param reason CannotRecallReason
local function SetCannotRequestRecall(reason)
    local recallSync = Sync.RecallRequest
    if not recallSync then
        Sync.RecallRequest = {CannotRequest = reason}
    else
        recallSync.CannotRequest = reason
    end
end

local function RecallVotingThread(requestingArmy)
    WaitTicks(VoteTime + 1)

    local gametick = GetGameTick()
    local recallAcceptance = 0
    local team = {}
    local teammates = 0
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
    local recallAccepted = RecallRequestAccepted(recallAcceptance, teammates)
    local focus = GetFocusArmy()
    local brain = GetArmyBrain(requestingArmy)
    if IsAlly(focus, requestingArmy) then
        Sync.RecallRequest = {
            Close = recallAccepted,
        }
    elseif recallAccepted then
        local dip = Sync.DiplomacyAnnouncement
        if not dip then
            dip = {}
            Sync.DiplomacyAnnouncement = dip
        end
        table.insert(dip, {
            Action = "recall",
            Team = brain.Nickname,
        })
    end
    if recallAccepted then
        SPEW("Vote passed; recalling!")
        for army, brain in team do
            brain:RecallAllCommanders()
        end
    else
        brain.LastRecallRequestTime = gametick

        -- update UI once the cooldown dissipates
        local cooldown, reason = ArmyRecallRequestCooldown(focus)
        repeat
            SetCannotRequestRecall(reason)
            WaitTicks(cooldown + 1)

            cooldown, reason = ArmyRecallRequestCooldown(focus)
        until cooldown <= 0
        SetCannotRequestRecall(false)
    end
    brain.recallVotingThread = nil
end

local function ArmyVoteRecall(army, vote, lastVote)
    if lastVote then
        for index, ally in ArmyBrains do
            if army ~= index and not ally:IsDefeated() and IsAlly(army, index) then
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
    -- don't update the recall panel for votes we aren't a part of
    if not IsAlly(focus, army) then
        return false
    end
    local recallSync = Sync.RecallRequest
    if not recallSync then
        recallSync = {}
        Sync.RecallRequest = recallSync
    end
    if vote then
        local accept = recallSync.Accept or 0
        recallSync.Accept = accept + 1
    else
        local veto = recallSync.Veto or 0
        recallSync.Veto = veto + 1
    end
    if army == focus then
        recallSync.CannotRequest = "active"
    end
    return true
end

local function ArmyRequestRecall(army, teammates, lastVote)
    if teammates > 0 then
        GetArmyBrain(army).recallVotingThread = ForkThread(RecallVotingThread, army)
        if ArmyVoteRecall(army, true, lastVote) then
            local recallSync = Sync.RecallRequest
            recallSync.Open = VoteTime * 0.1
            recallSync.CanVote = army ~= GetFocusArmy()
            recallSync.Blocks = teammates + 1
        end
    elseif lastVote then
        -- if we're the first and last vote, it's just us; recall our army
        SPEW("Immediately recalling")
        GetArmyBrain(army):RecallAllCommanders()
    end
end

---@param data {From: number, Vote: boolean}
function SetRecallVote(data)
    local focus = GetFocusArmy()
    local army = data.From
    if not ScenarioInfo.TeamGame then
        if army == focus then
            SetCannotRequestRecall("scenario")
        end
        return
    end
    local vote = data.Vote and true or false

    local isRequest = true
    local lastVote = true
    local teammates = 0
    for index, ally in ArmyBrains do
        if army ~= index and not ally:IsDefeated() and IsAlly(army, index) and not ArmyIsCivilian(index) then
            if ally.BrainType ~= "Human" then
                if army == focus then
                    SetCannotRequestRecall("ai")
                end
                return
            end
            local allyHasVoted = ally.RecallVote ~= nil
            lastVote = lastVote and allyHasVoted
            isRequest = isRequest and not allyHasVoted
            teammates = teammates + 1
        end
    end

    local brain = GetArmyBrain(army)
    if isRequest then
        -- the player is making a recall request; this will reset their recall request cooldown
        local cooldown, reason = ArmyRecallRequestCooldown(army)
        if cooldown > 0 then
            if army == focus then
                SetCannotRequestRecall(reason)
            end
            return
        end
        SPEW("Army " .. tostring(army) .. " is requesting recall")
        brain.RecallVote = vote
        ArmyRequestRecall(army, teammates, lastVote)
    else
        -- the player is responding to a recall request; we don't count this against their
        -- individual recall request cooldown
        SPEW("Army " .. tostring(army) .. " recall vote: " .. (vote and "accept" or "veto"))
        brain.RecallVote = vote
        ArmyVoteRecall(army, vote, lastVote)
    end
end
