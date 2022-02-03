
-- This file appears to be redundant but for performance reasons it is not :)

-- The call to GetSessionClients() returns a new table each time. This table 
-- can be quite large - for a single player it looks like:

-- {
--   {
--     authorizedCommandSources={ 1 },
--     connected=true,
--     ejectedBy={ },
--     local=true,
--     name="Jip",
--     ping=0,
--     quiet=0,
--     uid="0"
--   }
-- }

-- The number of entries increase as the number of players does. Each call
-- returns a unique table. For example, the results when doing the following
-- snippet without waiting:

-- LOG(GetSessionClients())
-- LOG(GetSessionClients())
-- LOG(GetSessionClients())

-- is this:

-- table: 11E9C488
-- table: 11E9C370
-- table: 11E9C870

-- That shows us that, even when we're on the same frame, it returns a new
-- table because the memory address of the tables are unique. Therefore
-- we cache it and provide an interface for the UI to be updated when the 
-- clients are updated.

local Observable = import('/lua/shared/observable.lua')

--- Allows UI elements to be updated when the list of clients are by adding a callback via ClientsLazy:AddObserver()
ObsClient = Observable.Create()
ObsClient:Set(GetSessionClients())

--- Interval for when we update the list of clients
local TickInterval = 0.5

--- A counter that keeps track of how often the interval was increased,
-- allows us to keep track of when we really want to reset it. As an example,
-- when two dialogues open on top of one another.
local TickIntervalResetCounter = 0

--- Handle to the tick thread that updates the clients
local HandleToTickThread = false 

--- A simple tick thread that updates the client list
local function TickThread()
    while true do 
        WaitSeconds(TickInterval)
        ObsClient:Set(GetSessionClients())
    end
end

--- Starts the tick thread to update the clients, should be called only once
function Setup()
    if not HandleToTickThread then 
        HandleToTickThread = ForkThread(TickThread)
    else 
        WARN("Tried to start a second tick thread for updating the session clients:")
        LOG(repr(debug.getinfo(2)))
    end
end

function 

--- A getter to return the check interval
function GetInterval()
    return TickInterval
end

--- Increases the check interval to every 0.025 seconds or a framerate of 40.
function FastInterval()
    TickIntervalResetCounter = TickIntervalResetCounter + 1
    TickInterval = 0.025
end

--- Resets the interval to every 0.5 seconds or a framerate of 2.
function ResetInterval()
    TickIntervalResetCounter = TickIntervalResetCounter - 1
    if TickIntervalResetCounter == 0 then 
        TickInterval = 0.5
    end
end