---@declare-global

-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--
-- This is the minimal setup required to load the game rules.

-- Do global init
__blueprints = {}

doscript '/lua/system/config.lua'
doscript '/lua/system/utils.lua'
-- repr depends on utils creating string.match
doscript '/lua/system/repr.lua'
doscript '/lua/system/debug.lua'

LOG('Active game mods for blueprint loading:')
for _, mod in __active_mods do
    LOG(string.format('\t"%-30s v%02d (%-37s by %s', tostring(mod.name) .. '"', tostring(mod.version), tostring(mod.uid) .. ')', tostring(mod.author)))
end

doscript '/lua/footprints.lua'
doscript '/lua/system/Blueprints.lua'
LoadBlueprints()
