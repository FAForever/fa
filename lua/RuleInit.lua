---@declare-global

-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--
-- This is the minimal setup required to load the game rules.

-- Do global init

--[[`number` is `BlueprintOrdinal` from the entity creation dialog, used by all types of blueprints  
`BlueprintId` for units  
`FileName` for projectiles and meshes (meshes have the file extension stripped)]]
---@type table<number | BlueprintId | FileName, UnitBlueprint | ProjectileBlueprint | MeshBlueprint>
---@diagnostic disable-next-line: lowercase-global
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
