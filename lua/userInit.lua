-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- This is the user-specific top-level lua initialization file. It is run at initialization time
-- to set up all lua state for the user layer.

-- Init our language from prefs. This applies to both front-end and session init; for
-- the Sim init, the engine sets __language for us.
__language = GetPreference('options_overrides.language', '')

-- Do global init
doscript '/lua/globalInit.lua'

AvgFPS = 60
WaitFrames = coroutine.yield

function WaitSeconds(n)
    local goal = CurrentTime() + n
    local wait_frames
    repeat
        wait_frames = math.ceil(math.max(1, AvgFPS*0.1, n * AvgFPS))
        WaitFrames(wait_frames)
        n = goal - CurrentTime()
    until n < 0.01
end


-- a table designed to allow communication from different user states to the front end lua state
FrontEndData = {}

-- Prefetch user side data
Prefetcher = CreatePrefetchSet()
