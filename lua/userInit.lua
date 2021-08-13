-- Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- This is the user-specific top-level lua initialization file. It is run at initialization time
-- to set up all lua state for the user layer.

-- Init our language from prefs. This applies to both front-end and session init; for
-- the Sim init, the engine sets __language for us.
__language = GetPreference('options_overrides.language', '')

-- Do global init
doscript '/lua/globalInit.lua'

WaitFrames = coroutine.yield

function WaitSeconds(n)
    local later = CurrentTime() + n
    WaitFrames(1)
    while CurrentTime() < later do
        WaitFrames(1)
    end
end

-- a table designed to allow communication from different user states to the front end lua state
FrontEndData = {}

-- Prefetch user side data
Prefetcher = CreatePrefetchSet()

function PrintText(textData)
    if textData then
        local data = textData
        if type(textData) == 'string' then
            data = {text = textData, size = 14, color = 'ffffffff', duration = 5, location = 'center'}
        end
        import('/lua/ui/game/textdisplay.lua').PrintToScreen(data)
    end
end

local replayID = import('/lua/ui/uiutil.lua').GetReplayId()
if replayID then
    LOG("REPLAY ID: " .. replayID)
end
