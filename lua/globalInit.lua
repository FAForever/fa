-- Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- This is the top-level lua initialization file. It is run at initialization time
-- to set up all lua state.

-- Uncomment this to turn on allocation tracking, so that memreport() in /lua/system/profile.lua
-- does something useful.
-- debug.trackallocations(true)

-- Set up global diskwatch table (you can add callbacks to it to be notified of disk changes)
__diskwatch = {}

-- Set up custom Lua weirdness
doscript '/lua/system/config.lua'

-- Load system modules
doscript '/lua/system/import.lua'
doscript '/lua/system/utils.lua'
doscript '/lua/system/repr.lua'
doscript '/lua/system/class.lua'
doscript '/lua/system/trashbag.lua'
doscript '/lua/system/Localization.lua'
doscript '/lua/system/MultiEvent.lua'
doscript '/lua/system/collapse.lua'

--
-- Classes exported from the engine are in the 'moho' table. But they aren't full
-- classes yet, just lists of exported methods and base classes. Turn them into
-- real classes.
--
for name,cclass in moho do
    --SPEW('C->lua ',name)
    ConvertCClassToLuaClass(cclass)
end

-- Flag initial loading of blueprints
InitialRegistration = true

-- Load blueprint systems
doscript '/lua/system/BuffBlueprints.lua'

-- Load buff definitions
import('/lua/sim/BuffDefinitions.lua')

-- Load Platoon Template systems
doscript '/lua/system/GlobalPlatoonTemplate.lua'

-- Load Builder system
doscript '/lua/system/GlobalBuilderTemplate.lua'

-- Load Builder Group systems
doscript '/lua/system/GlobalBuilderGroup.lua'

-- Load Global Base Templates
doscript '/lua/system/GlobalBaseTemplate.lua'

InitialRegistration = false

