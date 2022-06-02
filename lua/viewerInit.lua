-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- This is the viewer-specific top-level lua initialization file. It is run at initialization time
-- to set up all lua state for the viewer.
__language = 'us'

function AudioSetLanguage(l)
end

-- Do global init
doscript '/lua/globalInit.lua'
