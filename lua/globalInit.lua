---@declare-global
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
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

-- flag used to detect duplicates
InitialRegistration = true

-- load buff blueprints
doscript '/lua/system/BuffBlueprints.lua'
import("/lua/sim/buffdefinitions.lua")

EmptyTable = {}
setmetatable(EmptyTable, {__newindex = function()
    WARN("Attempt to set field of the empty table")
end})

InitialRegistration = false

-- Classes exported from the engine are in the 'moho' table. But they aren't full
-- classes yet, just lists of exported methods and base classes. Turn them into
-- real classes.
for name,cclass in moho do
    ConvertCClassToLuaSimplifiedClass(cclass, name)
end
