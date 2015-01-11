-- The global sync table is copied to the user layer every time the main and sim threads are
-- synchronized on the sim beat (which is like a tick but happens even when the game is paused)
Sync = {}

-- UnitData that has been synced. We keep a separate copy of this so when we change
-- focus army we can resync the data.
UnitData = {}

function ResetSyncTable()
    Sync = {
        -- A list of camera control operations that we'd like the user layer to perform.
        CameraRequests = {},
        Sounds = {},
        Voice = {},
        AIChat = {},

        -- Table of army indices set to "victory" or "defeat".
        -- It's the user layer's job to determine if any UI needs to be shown
        -- for the focus army.
        GameResult = {},

        -- Player to player queries that can affect the Sim
        PlayerQueries = {},
        QueryResults = {},

        -- Contain operation data when op is complete
        OperationComplete = nil,

        UnitData = {},
        ReleaseIds = {},
    }
end
