--**************************************************************************************************
--** Shared under the MIT license
--**************************************************************************************************

--- ticks before a player can start the first recall vote (5 minutes)
PlayerGateCooldown = 5 * 60 * 10

--- ticks before a player can request another recall (3 minutes)
PlayerRequestCooldown = 3 * 60 * 10

--- ticks before a team can have another recall vote (1 minute)
TeamVoteCooldown = 1 * 60 * 10

--- ticks that the recall vote is open (30 seconds)
VoteTime = 30 * 10

function RecallRequestAccepted(acceptanceVotes, totalVotes)
    if totalVotes <= 3 then
        return acceptanceVotes >= totalVotes
    else
        return acceptanceVotes >= (totalVotes - 1)
    end
end
