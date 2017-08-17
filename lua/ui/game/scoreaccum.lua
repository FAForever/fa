--*****************************************************************************
--* File: lua/modules/ui/game/scoreaccum.lua
--* Author: Chris Blackwell
--* Summary: Accumulates score info during the game
--*
--* Copyright © :005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

-- this table collects score info from the sync table and stores it for later use
-- it keeps both historical data (controled by the interval) and current tick data
-- typically it's used for the post game score screen, but could be used during the game as well

--[[
TABLE FORMAT

scoreData {
    current {
        playerIndex {
            general {
                score,
                mass,
                energy,
                kills {
                    count,
                    mass,
                    energy,
                }
                built {
                    count,
                    mass,
                    energy,
                }
                lost {
                    count,
                    mass,
                    energy,
                }
            },
            units {
                cdr {
                    kills,
                    built,
                    lost,
                },
                land {
                    kills,
                    built,
                    lost,
                },
                air {
                    kills,
                    built,
                    lost,
                },
                naval {
                    kills,
                    built,
                    lost,
                },
                structures {
                    kills,
                    built,
                    lost,
                },
                experimental {
                    kills,
                    built,
                    lost,
                },
                ... and more for specific units
            },
            resources {
                massin {
                    total,
                    rate,
                },
                massout {
                    total,
                    rate,
                },
                massover {
                    total,
                    rate,
                },
                energyin {
                    total,
                    rate,
                },
                energyout {
                    total,
                    rate,
                },
                energyover {
                    total,
                    rate,
                },
            },
        }
        ... for each player
    },
    historical {
        [interval1] {
            same data as in current
        },
        [interval2] {
        },
        ... for each time interval
    },
}

--]]

-- global score data can be read from directly
scoreData = {}
scoreData.current = {}
scoreData.historical = {}

fullSyncOccured = false

-- score interval determines how often the historical data gets updated, this is in seconds
scoreInterval = 10 -- FIXME: this should be synced from sim side

function UpdateScoreData(newData)
    if fullSyncOccured == false then
        scoreData.current = table.deepcopy(newData)
    end
end

function OnFullSync(accumData)
    scoreData = accumData
    fullSyncOccured = true
end
