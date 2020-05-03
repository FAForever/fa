--*****************************************************************************
--* File: lua/modules/ui/game/scoreaccum.lua
--* Author: Chris Blackwell
--* Summary: Accumulates score info during the game
--*
--* Copyright © :005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************
scoreData = {}
scoreData.current = {}
scoreData.historical = {}

fullSyncOccured = false

-- score interval determines how often the historical data gets updated, this is in seconds
scoreInterval = 10 -- FIXME: this should be synced from sim side

function UpdateScoreData(score)
    if fullSyncOccured == false then
        scoreData.current = score
    end
end

function OnFullSync(score)
    scoreData.current = score
    fullSyncOccured = true
end

function UpdateScoreHistory(history) 
    scoreData.historical = history
end