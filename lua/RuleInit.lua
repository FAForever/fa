---@declare-global

-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--
-- This is the minimal setup required to load the game rules.

-- Do global init
__blueprints = {}

doscript '/lua/system/config.lua'
doscript '/lua/system/repr.lua'
doscript '/lua/system/utils.lua'

LOG('Active game mods for blueprint loading: ',repr(__active_mods))

doscript '/lua/footprints.lua'
doscript '/lua/system/Blueprints.lua'
LoadBlueprints()
